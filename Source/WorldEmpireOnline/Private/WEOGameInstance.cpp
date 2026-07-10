#include "WEOGameInstance.h"

#include "HttpModule.h"
#include "Interfaces/IHttpResponse.h"
#include "Json.h"
#include "JsonObjectConverter.h"

void UWEOGameInstance::Init()
{
    Super::Init();
}

void UWEOGameInstance::Shutdown()
{
    DisconnectRealtime();
    Super::Shutdown();
}

FString UWEOGameInstance::MakeUrl(const FString& Path) const
{
    if (Path.StartsWith(TEXT("http"))) return Path;
    return ApiBaseUrl.TrimEnd() + Path;
}

void UWEOGameInstance::AddAuthHeader(TSharedRef<IHttpRequest, ESPMode::ThreadSafe> Request) const
{
    if (!JwtToken.IsEmpty())
    {
        Request->SetHeader(TEXT("Authorization"), TEXT("Bearer ") + JwtToken);
    }
}

void UWEOGameInstance::PostJson(const FString& Path, const FString& Json, TFunction<void(bool, const FString&)> Callback, bool bAuthed)
{
    TSharedRef<IHttpRequest, ESPMode::ThreadSafe> Request = FHttpModule::Get().CreateRequest();
    Request->SetURL(MakeUrl(Path));
    Request->SetVerb(TEXT("POST"));
    Request->SetHeader(TEXT("Content-Type"), TEXT("application/json"));
    if (bAuthed) AddAuthHeader(Request);
    Request->SetContentAsString(Json);
    Request->OnProcessRequestComplete().BindLambda([Callback](FHttpRequestPtr Req, FHttpResponsePtr Res, bool bWasSuccessful)
    {
        const bool bOk = bWasSuccessful && Res.IsValid() && Res->GetResponseCode() >= 200 && Res->GetResponseCode() < 300;
        Callback(bOk, Res.IsValid() ? Res->GetContentAsString() : TEXT(""));
    });
    Request->ProcessRequest();
}

void UWEOGameInstance::GetJson(const FString& Path, TFunction<void(bool, const FString&)> Callback, bool bAuthed)
{
    TSharedRef<IHttpRequest, ESPMode::ThreadSafe> Request = FHttpModule::Get().CreateRequest();
    Request->SetURL(MakeUrl(Path));
    Request->SetVerb(TEXT("GET"));
    if (bAuthed) AddAuthHeader(Request);
    Request->OnProcessRequestComplete().BindLambda([Callback](FHttpRequestPtr Req, FHttpResponsePtr Res, bool bWasSuccessful)
    {
        const bool bOk = bWasSuccessful && Res.IsValid() && Res->GetResponseCode() >= 200 && Res->GetResponseCode() < 300;
        Callback(bOk, Res.IsValid() ? Res->GetContentAsString() : TEXT(""));
    });
    Request->ProcessRequest();
}

void UWEOGameInstance::Login(const FString& Email, const FString& Password)
{
    const FString Json = FString::Printf(TEXT("{\"email\":\"%s\",\"password\":\"%s\"}"), *Email, *Password);
    PostJson(TEXT("/api/auth/login"), Json, [this](bool bSuccess, const FString& Body) { HandleLoginResponse(bSuccess, Body); });
}

void UWEOGameInstance::Register(const FString& Email, const FString& Password, const FString& DisplayName)
{
    const FString Json = FString::Printf(TEXT("{\"email\":\"%s\",\"password\":\"%s\",\"displayName\":\"%s\"}"), *Email, *Password, *DisplayName);
    PostJson(TEXT("/api/auth/register"), Json, [this](bool bSuccess, const FString& Body) { HandleLoginResponse(bSuccess, Body); });
}

void UWEOGameInstance::HandleLoginResponse(bool bSuccess, const FString& Body)
{
    if (!bSuccess)
    {
        OnApiMessage.Broadcast(false, TEXT("Login/register failed: ") + Body);
        return;
    }

    TSharedPtr<FJsonObject> Root;
    TSharedRef<TJsonReader<>> Reader = TJsonReaderFactory<>::Create(Body);
    if (!FJsonSerializer::Deserialize(Reader, Root) || !Root.IsValid())
    {
        OnApiMessage.Broadcast(false, TEXT("Bad auth response"));
        return;
    }

    JwtToken = Root->GetStringField(TEXT("token"));
    const TSharedPtr<FJsonObject>* UserObj = nullptr;
    if (Root->TryGetObjectField(TEXT("user"), UserObj) && UserObj && UserObj->IsValid())
    {
        CurrentUser.Id = (*UserObj)->GetStringField(TEXT("id"));
        CurrentUser.Email = (*UserObj)->GetStringField(TEXT("email"));
        CurrentUser.DisplayName = (*UserObj)->GetStringField(TEXT("display_name"));
        CurrentUser.Role = (*UserObj)->GetStringField(TEXT("role"));
        CurrentUser.Cash = static_cast<float>((*UserObj)->GetNumberField(TEXT("cash")));
    }
    OnApiMessage.Broadcast(true, TEXT("Authenticated"));
    LoadMyCharacter();
}

void UWEOGameInstance::LoadWorld()
{
    GetJson(TEXT("/api/world"), [this](bool bSuccess, const FString& Body)
    {
        if (!bSuccess) { OnApiMessage.Broadcast(false, TEXT("World load failed: ") + Body); return; }
        ParseWorld(Body);
    });
}

void UWEOGameInstance::ParseWorld(const FString& Body)
{
    Cities.Reset();
    TSharedPtr<FJsonObject> Root;
    TSharedRef<TJsonReader<>> Reader = TJsonReaderFactory<>::Create(Body);
    if (!FJsonSerializer::Deserialize(Reader, Root) || !Root.IsValid()) return;

    const TArray<TSharedPtr<FJsonValue>>* CityArray = nullptr;
    if (Root->TryGetArrayField(TEXT("cities"), CityArray))
    {
        for (const TSharedPtr<FJsonValue>& Value : *CityArray)
        {
            const TSharedPtr<FJsonObject> Obj = Value->AsObject();
            if (!Obj.IsValid()) continue;
            FWEOCity City;
            City.Id = Obj->GetStringField(TEXT("id"));
            City.Name = Obj->GetStringField(TEXT("name"));
            City.Country = Obj->GetStringField(TEXT("country"));
            Obj->TryGetStringField(TEXT("owner_user_id"), City.OwnerUserId);
            Obj->TryGetStringField(TEXT("owner_name"), City.OwnerName);
            City.Population = static_cast<int32>(Obj->GetNumberField(TEXT("population")));
            City.Happiness = static_cast<float>(Obj->GetNumberField(TEXT("happiness")));
            City.Safety = static_cast<float>(Obj->GetNumberField(TEXT("safety")));
            City.Treasury = static_cast<float>(Obj->GetNumberField(TEXT("treasury")));
            Cities.Add(City);
        }
    }
    OnWorldLoaded.Broadcast(Cities);
}

void UWEOGameInstance::LoadCity(const FString& CityId)
{
    GetJson(TEXT("/api/cities/") + CityId, [this](bool bSuccess, const FString& Body)
    {
        if (!bSuccess) { OnApiMessage.Broadcast(false, TEXT("City load failed: ") + Body); return; }
        ParseCity(Body);
    });
}

void UWEOGameInstance::ParseCity(const FString& Body)
{
    CurrentCityProperties.Reset();
    TSharedPtr<FJsonObject> Root;
    TSharedRef<TJsonReader<>> Reader = TJsonReaderFactory<>::Create(Body);
    if (!FJsonSerializer::Deserialize(Reader, Root) || !Root.IsValid()) return;

    const TArray<TSharedPtr<FJsonValue>>* PropArray = nullptr;
    if (Root->TryGetArrayField(TEXT("properties"), PropArray))
    {
        for (const TSharedPtr<FJsonValue>& Value : *PropArray)
        {
            const TSharedPtr<FJsonObject> Obj = Value->AsObject();
            if (!Obj.IsValid()) continue;
            FWEOProperty Prop;
            Prop.Id = Obj->GetStringField(TEXT("id"));
            Prop.CityId = Obj->GetStringField(TEXT("city_id"));
            Obj->TryGetStringField(TEXT("owner_user_id"), Prop.OwnerUserId);
            Prop.Kind = Obj->GetStringField(TEXT("kind"));
            Prop.Name = Obj->GetStringField(TEXT("name"));
            Prop.Value = static_cast<float>(Obj->GetNumberField(TEXT("value")));
            Prop.Rent = static_cast<float>(Obj->GetNumberField(TEXT("rent")));
            Prop.bForSale = Obj->GetBoolField(TEXT("is_for_sale"));
            CurrentCityProperties.Add(Prop);
        }
    }
    OnCityLoaded.Broadcast(CurrentCityProperties);
}

void UWEOGameInstance::LoadMyCharacter()
{
    GetJson(TEXT("/api/characters/me"), [this](bool bSuccess, const FString& Body)
    {
        if (!bSuccess)
        {
            OnApiMessage.Broadcast(false, TEXT("character_required"));
            return;
        }
        ParseCharacter(Body);
        LoadWorld();
    });
}

void UWEOGameInstance::CreateCharacter(const FString& FirstName, const FString& LastName, const FString& StartingCityId)
{
    const FString Json = FString::Printf(TEXT("{\"first_name\":\"%s\",\"last_name\":\"%s\",\"gender\":\"unspecified\",\"nationality\":\"Player\",\"starting_city_id\":\"%s\"}"), *FirstName, *LastName, *StartingCityId);
    PostJson(TEXT("/api/characters/create"), Json, [this](bool bSuccess, const FString& Body)
    {
        if (!bSuccess) { OnApiMessage.Broadcast(false, TEXT("Character create failed: ") + Body); return; }
        ParseCharacter(Body);
        LoadWorld();
    }, true);
}

void UWEOGameInstance::ParseCharacter(const FString& Body)
{
    TSharedPtr<FJsonObject> Root;
    TSharedRef<TJsonReader<>> Reader = TJsonReaderFactory<>::Create(Body);
    if (!FJsonSerializer::Deserialize(Reader, Root) || !Root.IsValid()) return;
    const TSharedPtr<FJsonObject>* CharObj = nullptr;
    if (Root->TryGetObjectField(TEXT("character"), CharObj) && CharObj && CharObj->IsValid())
    {
        CurrentCharacter.Id = (*CharObj)->GetStringField(TEXT("id"));
        CurrentCharacter.UserId = (*CharObj)->GetStringField(TEXT("user_id"));
        CurrentCharacter.FirstName = (*CharObj)->GetStringField(TEXT("first_name"));
        CurrentCharacter.LastName = (*CharObj)->GetStringField(TEXT("last_name"));
        CurrentCharacter.StartingCityId = (*CharObj)->GetStringField(TEXT("starting_city_id"));
        (*CharObj)->TryGetStringField(TEXT("gender"), CurrentCharacter.Gender);
        (*CharObj)->TryGetStringField(TEXT("nationality"), CurrentCharacter.Nationality);
        OnCharacterLoaded.Broadcast(CurrentCharacter);
    }
}

void UWEOGameInstance::BuyProperty(const FString& PropertyId)
{
    PostJson(TEXT("/api/properties/") + PropertyId + TEXT("/buy"), TEXT("{}"), [this](bool bSuccess, const FString& Body)
    {
        OnApiMessage.Broadcast(bSuccess, bSuccess ? TEXT("Property bought") : (TEXT("Buy failed: ") + Body));
    }, true);
}

void UWEOGameInstance::ConnectRealtime()
{
    OnApiMessage.Broadcast(true, TEXT("Realtime chat disabled in no-WebSockets starter. HTTP features are active."));
}

void UWEOGameInstance::SendChat(const FString& CityId, const FString& Message)
{
    OnApiMessage.Broadcast(false, TEXT("Realtime chat disabled in no-WebSockets starter."));
}

void UWEOGameInstance::DisconnectRealtime()
{
    // No WebSocket connection in this compatibility build.
}
