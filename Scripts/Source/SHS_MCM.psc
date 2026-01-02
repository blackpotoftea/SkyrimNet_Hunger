Scriptname SHS_MCM extends MCM_ConfigBase

SHS_Main Property MainQuest Auto

int Function GetVersion()
    return 1
EndFunction

Event OnConfigInit()
    parent.OnConfigInit()
    LoadSettings()
EndEvent

Event OnGameReload()
    parent.OnGameReload()
    LoadSettings()
EndEvent

Event OnPageSelect(String a_page)
    parent.OnPageSelect(a_page)

    ; Dynamically refresh Serana hunger display when page opens
    Actor Serana = MainQuest.getActorSerana()
    if Serana && Serana.IsInFaction(MainQuest.SHS_BloodFaction)
        int CurrentHunger = Serana.GetFactionRank(MainQuest.SHS_BloodFaction)
        SetModSettingInt("iSeranaHungerLevel:Main", CurrentHunger)
        MainQuest.console("MCM: Serana hunger displayed: " + CurrentHunger)
    else
        SetModSettingInt("iSeranaHungerLevel:Main", 0)
        MainQuest.console("MCM: Serana not in faction, displaying 0")
    endif

    RefreshMenu()
EndEvent

Event OnSettingChange(string a_ID)
    parent.OnSettingChange(a_ID)

    ; Handle Serana hunger live update
    If a_ID == "iSeranaHungerLevel:Main"
        UpdateSeranaHunger()
    Else
        LoadSettings()
    EndIf
EndEvent

Function LoadSettings()
    MainQuest.debugConsole("MCM: Loading settings")

    MainQuest.BaseRate = GetModSettingFloat("fBaseRate:Main")
    MainQuest.debugConsole("BaseRate: " + MainQuest.BaseRate)

    MainQuest.LordRate = GetModSettingFloat("fLordRate:Main")
    MainQuest.debugConsole("LordRate: " + MainQuest.LordRate)

    MainQuest.TeammateRate = GetModSettingFloat("fTeammateRate:Main")
    MainQuest.debugConsole("TeammateRate: " + MainQuest.TeammateRate)

    MainQuest.SimulationThreshold = GetModSettingFloat("fSimulationThreshold:Main")
    MainQuest.debugConsole("SimulationThreshold: " + MainQuest.SimulationThreshold)

    MainQuest.FeedingChance = GetModSettingInt("iFeedingChance:Main")
    MainQuest.debugConsole("FeedingChance: " + MainQuest.FeedingChance)

    MainQuest.FollowerHuntChance = GetModSettingInt("iFollowerHuntChance:Main")
    MainQuest.debugConsole("FollowerHuntChance: " + MainQuest.FollowerHuntChance)

    MainQuest.SleepThreshold = GetModSettingFloat("fSleepThreshold:Main")
    MainQuest.debugConsole("SleepThreshold: " + MainQuest.SleepThreshold)

    MainQuest.AmountToReduceFull = GetModSettingInt("iAmountToReduceFull:Main")
    MainQuest.debugConsole("AmountToReduceFull: " + MainQuest.AmountToReduceFull)

    MainQuest.AmountToReducePartial = GetModSettingInt("iAmountToReducePartial:Main")
    MainQuest.debugConsole("AmountToReducePartial: " + MainQuest.AmountToReducePartial)

    MainQuest.SHS_DevelopmentModeEnabled.SetValueInt(GetModSettingBool("bDevelopmentMode:Main") as Int)
    MainQuest.debugConsole("DevelopmentMode: " + MainQuest.SHS_DevelopmentModeEnabled.GetValueInt())
EndFunction

Function UpdateSeranaHunger()
    ; Called when slider moves - update Serana's hunger live
    Actor Serana = MainQuest.getActorSerana()

    if !Serana
        MainQuest.console("MCM: Cannot find Serana - is Dawnguard loaded?")
        return
    endif

    int HungerLevel = GetModSettingInt("iSeranaHungerLevel:Main")

    ; Ensure Serana is in the faction
    if !Serana.IsInFaction(MainQuest.SHS_BloodFaction)
        Serana.AddToFaction(MainQuest.SHS_BloodFaction)
        MainQuest.console("MCM: Added Serana to SHS_BloodFaction")
    endif

    ; Set hunger level
    Serana.SetFactionRank(MainQuest.SHS_BloodFaction, HungerLevel)

    ; Update LastSeen timer
    StorageUtil.SetFloatValue(Serana, "SHS_LastSeen", Utility.GetCurrentGameTime())

    MainQuest.console("MCM: Serana hunger set to " + HungerLevel)

    ; Verify it was set
    int VerifyRank = Serana.GetFactionRank(MainQuest.SHS_BloodFaction)
    MainQuest.debugConsole("MCM: Verified rank = " + VerifyRank)
EndFunction


