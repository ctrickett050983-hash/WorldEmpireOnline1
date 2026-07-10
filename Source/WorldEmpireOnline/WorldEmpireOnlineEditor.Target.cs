using UnrealBuildTool;
using System.Collections.Generic;

public class WorldEmpireOnlineEditorTarget : TargetRules
{
    public WorldEmpireOnlineEditorTarget(TargetInfo Target) : base(Target)
    {
        Type = TargetType.Editor;
        DefaultBuildSettings = BuildSettingsVersion.V2;
        ExtraModuleNames.Add("WorldEmpireOnline");
    }
}
