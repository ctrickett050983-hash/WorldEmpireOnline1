#include "WEOPlayerCharacter.h"
#include "Camera/CameraComponent.h"
#include "GameFramework/SpringArmComponent.h"
#include "GameFramework/CharacterMovementComponent.h"

AWEOPlayerCharacter::AWEOPlayerCharacter()
{
    PrimaryActorTick.bCanEverTick = false;
    CameraBoom = CreateDefaultSubobject<USpringArmComponent>(TEXT("CameraBoom"));
    CameraBoom->SetupAttachment(RootComponent);
    CameraBoom->TargetArmLength = 450.f;
    CameraBoom->bUsePawnControlRotation = true;

    FollowCamera = CreateDefaultSubobject<UCameraComponent>(TEXT("FollowCamera"));
    FollowCamera->SetupAttachment(CameraBoom, USpringArmComponent::SocketName);
    FollowCamera->bUsePawnControlRotation = false;

    GetCharacterMovement()->MaxWalkSpeed = WalkSpeed;
}

void AWEOPlayerCharacter::SetupPlayerInputComponent(UInputComponent* PlayerInputComponent)
{
    Super::SetupPlayerInputComponent(PlayerInputComponent);
    PlayerInputComponent->BindAxis(TEXT("MoveForward"), this, &AWEOPlayerCharacter::MoveForward);
    PlayerInputComponent->BindAxis(TEXT("MoveRight"), this, &AWEOPlayerCharacter::MoveRight);
    PlayerInputComponent->BindAxis(TEXT("Turn"), this, &AWEOPlayerCharacter::Turn);
    PlayerInputComponent->BindAxis(TEXT("LookUp"), this, &AWEOPlayerCharacter::LookUp);
    PlayerInputComponent->BindAction(TEXT("Jump"), IE_Pressed, this, &ACharacter::Jump);
    PlayerInputComponent->BindAction(TEXT("Jump"), IE_Released, this, &ACharacter::StopJumping);
    PlayerInputComponent->BindAction(TEXT("Sprint"), IE_Pressed, this, &AWEOPlayerCharacter::StartSprint);
    PlayerInputComponent->BindAction(TEXT("Sprint"), IE_Released, this, &AWEOPlayerCharacter::StopSprint);
    PlayerInputComponent->BindAction(TEXT("Interact"), IE_Pressed, this, &AWEOPlayerCharacter::Interact);
    PlayerInputComponent->BindAction(TEXT("Phone"), IE_Pressed, this, &AWEOPlayerCharacter::TogglePhone);
}

void AWEOPlayerCharacter::MoveForward(float Value)
{
    if (Controller && Value != 0.f) AddMovementInput(GetActorForwardVector(), Value);
}

void AWEOPlayerCharacter::MoveRight(float Value)
{
    if (Controller && Value != 0.f) AddMovementInput(GetActorRightVector(), Value);
}

void AWEOPlayerCharacter::Turn(float Value) { AddControllerYawInput(Value); }
void AWEOPlayerCharacter::LookUp(float Value) { AddControllerPitchInput(Value); }
void AWEOPlayerCharacter::StartSprint() { GetCharacterMovement()->MaxWalkSpeed = SprintSpeed; }
void AWEOPlayerCharacter::StopSprint() { GetCharacterMovement()->MaxWalkSpeed = WalkSpeed; }
void AWEOPlayerCharacter::Interact() { /* Blueprint can override with line trace/property interaction. */ }
void AWEOPlayerCharacter::TogglePhone() { /* Blueprint UI hook. */ }
