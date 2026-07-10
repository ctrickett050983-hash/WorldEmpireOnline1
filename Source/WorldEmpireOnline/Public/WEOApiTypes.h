#pragma once

#include "CoreMinimal.h"
#include "WEOApiTypes.generated.h"

USTRUCT(BlueprintType)
struct FWEOUser
{
    GENERATED_BODY()

    UPROPERTY(BlueprintReadOnly) FString Id;
    UPROPERTY(BlueprintReadOnly) FString Email;
    UPROPERTY(BlueprintReadOnly) FString DisplayName;
    UPROPERTY(BlueprintReadOnly) FString Role;
    UPROPERTY(BlueprintReadOnly) float Cash = 0.f;
};

USTRUCT(BlueprintType)
struct FWEOCity
{
    GENERATED_BODY()

    UPROPERTY(BlueprintReadOnly) FString Id;
    UPROPERTY(BlueprintReadOnly) FString Name;
    UPROPERTY(BlueprintReadOnly) FString Country;
    UPROPERTY(BlueprintReadOnly) FString OwnerUserId;
    UPROPERTY(BlueprintReadOnly) FString OwnerName;
    UPROPERTY(BlueprintReadOnly) int32 Population = 0;
    UPROPERTY(BlueprintReadOnly) float Happiness = 0.f;
    UPROPERTY(BlueprintReadOnly) float Safety = 0.f;
    UPROPERTY(BlueprintReadOnly) float Treasury = 0.f;
};

USTRUCT(BlueprintType)
struct FWEOProperty
{
    GENERATED_BODY()

    UPROPERTY(BlueprintReadOnly) FString Id;
    UPROPERTY(BlueprintReadOnly) FString CityId;
    UPROPERTY(BlueprintReadOnly) FString OwnerUserId;
    UPROPERTY(BlueprintReadOnly) FString Kind;
    UPROPERTY(BlueprintReadOnly) FString Name;
    UPROPERTY(BlueprintReadOnly) float Value = 0.f;
    UPROPERTY(BlueprintReadOnly) float Rent = 0.f;
    UPROPERTY(BlueprintReadOnly) bool bForSale = false;
};

USTRUCT(BlueprintType)
struct FWEOCharacter
{
    GENERATED_BODY()

    UPROPERTY(BlueprintReadOnly) FString Id;
    UPROPERTY(BlueprintReadOnly) FString UserId;
    UPROPERTY(BlueprintReadOnly) FString FirstName;
    UPROPERTY(BlueprintReadOnly) FString LastName;
    UPROPERTY(BlueprintReadOnly) FString StartingCityId;
    UPROPERTY(BlueprintReadOnly) FString Gender;
    UPROPERTY(BlueprintReadOnly) FString Nationality;
};
