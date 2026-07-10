#pragma once

#include "CoreMinimal.h"
#include "Engine/GameInstance.h"
#include "Interfaces/IHttpRequest.h"
#include "WEOApiTypes.h"
#include "WEOGameInstance.generated.h"

DECLARE_DYNAMIC_MULTICAST_DELEGATE_TwoParams(FWEOApiMessage, bool, bSuccess, const FString&, Message);
DECLARE_DYNAMIC_MULTICAST_DELEGATE_OneParam(FWEOWorldLoaded, const TArray<FWEOCity>&, Cities);
DECLARE_DYNAMIC_MULTICAST_DELEGATE_OneParam(FWEOCityLoaded, const TArray<FWEOProperty>&, Properties);
DECLARE_DYNAMIC_MULTICAST_DELEGATE_OneParam(FWEOChatMessage, const FString&, Message);
DECLARE_DYNAMIC_MULTICAST_DELEGATE_OneParam(FWEOCharacterLoaded, const FWEOCharacter&, Character);

UCLASS()
class WORLDEMPIREONLINE_API UWEOGameInstance : public UGameInstance
{
    GENERATED_BODY()

public:
    virtual void Init() override;
    virtual void Shutdown() override;

    UPROPERTY(EditAnywhere, BlueprintReadWrite, Category="World Empire|Server") FString ApiBaseUrl = TEXT("http://localhost:3000");

    UPROPERTY(BlueprintReadOnly, Category="World Empire|Session") FString JwtToken;
    UPROPERTY(BlueprintReadOnly, Category="World Empire|Session") FWEOUser CurrentUser;
    UPROPERTY(BlueprintReadOnly, Category="World Empire|Session") FWEOCharacter CurrentCharacter;
    UPROPERTY(BlueprintReadOnly, Category="World Empire|World") TArray<FWEOCity> Cities;
    UPROPERTY(BlueprintReadOnly, Category="World Empire|World") TArray<FWEOProperty> CurrentCityProperties;
    UPROPERTY(BlueprintAssignable) FWEOApiMessage OnApiMessage;
    UPROPERTY(BlueprintAssignable) FWEOWorldLoaded OnWorldLoaded;
    UPROPERTY(BlueprintAssignable) FWEOCityLoaded OnCityLoaded;
    UPROPERTY(BlueprintAssignable) FWEOChatMessage OnChatMessage;
    UPROPERTY(BlueprintAssignable) FWEOCharacterLoaded OnCharacterLoaded;

    UFUNCTION(BlueprintCallable, Category="World Empire|Auth") void Login(const FString& Email, const FString& Password);
    UFUNCTION(BlueprintCallable, Category="World Empire|Auth") void Register(const FString& Email, const FString& Password, const FString& DisplayName);
    UFUNCTION(BlueprintCallable, Category="World Empire|World") void LoadWorld();
    UFUNCTION(BlueprintCallable, Category="World Empire|World") void LoadCity(const FString& CityId);
    UFUNCTION(BlueprintCallable, Category="World Empire|Character") void LoadMyCharacter();
    UFUNCTION(BlueprintCallable, Category="World Empire|Character") void CreateCharacter(const FString& FirstName, const FString& LastName, const FString& StartingCityId);
    UFUNCTION(BlueprintCallable, Category="World Empire|Property") void BuyProperty(const FString& PropertyId);
    UFUNCTION(BlueprintCallable, Category="World Empire|Realtime") void ConnectRealtime();
    UFUNCTION(BlueprintCallable, Category="World Empire|Realtime") void SendChat(const FString& CityId, const FString& Message);
    UFUNCTION(BlueprintCallable, Category="World Empire|Realtime") void DisconnectRealtime();

private:
    void PostJson(const FString& Path, const FString& Json, TFunction<void(bool, const FString&)> Callback, bool bAuthed = false);
    void GetJson(const FString& Path, TFunction<void(bool, const FString&)> Callback, bool bAuthed = true);
    FString MakeUrl(const FString& Path) const;
    void AddAuthHeader(TSharedRef<IHttpRequest, ESPMode::ThreadSafe> Request) const;

    void HandleLoginResponse(bool bSuccess, const FString& Body);
    void ParseWorld(const FString& Body);
    void ParseCity(const FString& Body);
    void ParseCharacter(const FString& Body);
};
