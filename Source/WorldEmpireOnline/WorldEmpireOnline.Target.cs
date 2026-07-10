using UnrealBuildTool;
using System.Collections.Generic;

public class WorldEmpireOnlineTarget : TargetRules
{
    public WorldEmpireOnlineTarget(TargetInfo Target) : base(Target)
    {
        Type = TargetType.Game;
        DefaultBuildSettings = BuildSettingsVersion.V2;
        ExtraModuleNames.Add("WorldEmpireOnline");
    }
}
