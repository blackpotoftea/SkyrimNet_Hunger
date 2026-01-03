Scriptname SHS_MCM extends MCM_ConfigBase

SHS_Main Property MainQuest Auto

int Function GetVersion()
    return MainQuest.GetCurrentModVersion()
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

    SetModSettingString("sModVersion:Main", GetVersion() as String)

    Actor Serana = MainQuest.getActorSerana()
    if Serana && Serana.IsInFaction(MainQuest.SHS_BloodFaction)
        int CurrentHunger = Serana.GetFactionRank(MainQuest.SHS_BloodFaction)
        SetModSettingInt("iSeranaHungerLevel:Main", CurrentHunger)
        MainQuest.debugConsole("MCM: Serana hunger displayed: " + CurrentHunger)
    else
        SetModSettingInt("iSeranaHungerLevel:Main", 0)
        MainQuest.debugConsole("MCM: Serana not in faction, displaying 0")
    endif

    RefreshMenu()
EndEvent

Event OnSettingChange(string a_ID)
    parent.OnSettingChange(a_ID)

    If a_ID == "iSeranaHungerLevel:Main"
        UpdateSeranaHunger()
    elseIf a_ID == "bDevelopmentMode:Main"
        bool status = GetModSettingBool("bDevelopmentMode:Main")
        MainQuest.debugConsole("MCM: Setting development mode: "+status)
        MainQuest.SHS_DevelopmentModeEnabled.SetValueInt(status as Int)
    Else
        LoadSettings()
    EndIf
EndEvent

Function LoadSettings()
    MainQuest.debugConsole("MCM: Loading settings")

    MainQuest.SetBaseRate(GetModSettingFloat("fBaseRate:Main"))
    MainQuest.debugConsole("BaseRate: " + MainQuest.GetBaseRate())

    MainQuest.SetLordRate(GetModSettingFloat("fLordRate:Main"))
    MainQuest.debugConsole("LordRate: " + MainQuest.GetLordRate())

    MainQuest.SetTeammateRate(GetModSettingFloat("fTeammateRate:Main"))
    MainQuest.debugConsole("TeammateRate: " + MainQuest.GetTeammateRate())

    MainQuest.SetSimulationThreshold(GetModSettingFloat("fSimulationThreshold:Main"))
    MainQuest.debugConsole("SimulationThreshold: " + MainQuest.GetSimulationThreshold())

    MainQuest.SetFeedingChance(GetModSettingInt("iFeedingChance:Main"))
    MainQuest.debugConsole("FeedingChance: " + MainQuest.GetFeedingChance())

    MainQuest.SetFollowerHuntChance(GetModSettingInt("iFollowerHuntChance:Main"))
    MainQuest.debugConsole("FollowerHuntChance: " + MainQuest.GetFollowerHuntChance())

    MainQuest.SetSleepThreshold(GetModSettingFloat("fSleepThreshold:Main"))
    MainQuest.debugConsole("SleepThreshold: " + MainQuest.GetSleepThreshold())

    MainQuest.SetAmountToReduceFull(GetModSettingInt("iAmountToReduceFull:Main"))
    MainQuest.debugConsole("AmountToReduceFull: " + MainQuest.GetAmountToReduceFull())

    MainQuest.SetAmountToReducePartial(GetModSettingInt("iAmountToReducePartial:Main"))
    MainQuest.debugConsole("AmountToReducePartial: " + MainQuest.GetAmountToReducePartial())

    MainQuest.SetEventTTL(GetModSettingInt("iEventTTL:Main"))
    MainQuest.debugConsole("EventTTL: " + MainQuest.GetEventTTL())

    MainQuest.SetDebugForceHungerState(GetModSettingInt("iDebugForceHungerState:Main"))
    MainQuest.debugConsole("DebugForceHungerState: " + MainQuest.GetDebugForceHungerState())

    MainQuest.SHS_DevelopmentModeEnabled.SetValueInt(GetModSettingBool("bDevelopmentMode:Main") as Int)
    MainQuest.debugConsole("DevelopmentMode: " + MainQuest.SHS_DevelopmentModeEnabled.GetValueInt())
EndFunction

Function UpdateSeranaHunger()
    Actor Serana = MainQuest.getActorSerana()

    if !Serana
        MainQuest.console("MCM: Cannot find Serana - is Dawnguard loaded?")
        return
    endif

    int HungerLevel = GetModSettingInt("iSeranaHungerLevel:Main")

    MainQuest.SetActorHunger(Serana, HungerLevel)

    MainQuest.debugConsole("MCM: Serana hunger set to " + HungerLevel)

    int VerifyRank = Serana.GetFactionRank(MainQuest.SHS_BloodFaction)
    MainQuest.debugConsole("MCM: Verified rank = " + VerifyRank)
EndFunction


