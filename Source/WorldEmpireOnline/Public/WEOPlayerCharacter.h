#pragma once

#include "CoreMinimal.h"
#include "GameFramework/Character.h"
#include "WEOPlayerCharacter.generated.h"

UCLASS()
class WORLDEMPIREONLINE_API AWEOPlayerCharacter : public ACharacter
{
    GENERATED_BODY()

public:
    AWEOPlayerCharacter();

protected:
    virtual void SetupPlayerInputComponent(class UInputComponent* PlayerInputComponent) override;

    void MoveForward(float Value);
    void MoveRight(float Value);
    void Turn(float Value);
    void LookUp(float Value);
    void StartSprint();
    void StopSprint();
    void Interact();
    void TogglePhone();

    UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="Camera") class USpringArmComponent* CameraBoom;
    UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="Camera") class UCameraComponent* FollowCamera;
    UPROPERTY(EditAnywhere, BlueprintReadWrite, Category="Movement") float WalkSpeed = 450.f;
    UPROPERTY(EditAnywhere, BlueprintReadWrite, Category="Movement") float SprintSpeed = 750.f;
};
