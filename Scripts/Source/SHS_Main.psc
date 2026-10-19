Scriptname SHS_Main extends Quest

Faction Property SHS_BloodFaction  Auto

SPELL Property SHS_BoodHungerSpell  Auto

MagicEffect Property SHS_BloodHunger  Auto

GlobalVariable Property SHS_DevelopmentModeEnabled  Auto

; ModEvent for notifying other mods of vampire hunger state changes
String Property EVENT_VAMPIRE_HUNGER = "SHS_VampireHungerChanged" AutoReadOnly  

ActorBase Property DLC1Serana  Auto  
ActorBase Property DLC1Harkon  Auto  
ActorBase Property DLC1Valerica  Auto  

Location Property DLC1SoulCairnLocation  Auto  

Keyword Property LocTypeVampireLair  Auto

; Configuration variables - values stored here, NOT in save files (non-Auto)
; MCM will set these via setters on config load
float _BaseRate = 5.0
float _LordRate = 1.0
float _TeammateRate = 2.0
float _SimulationThreshold = 8.0
int _FeedingChance = 75
int _FollowerHuntChance = 60
float _SleepThreshold = 4.0
int _AmountToReduceFull = 80
int _AmountToReducePartial = 40
int _EventTTL = 120
int _DebugForceHungerState = -1
; Keep hunger changes and feedings in SkyrimNet's history (stored events), so every SkyrimNet reader sees them and
; the NPCs remember them; off, a hunger change is a short-lived event for _EventTTL seconds, as before
bool _StoreHungerEvents = true

; Getters
float Function GetBaseRate()
    return _BaseRate
EndFunction

float Function GetLordRate()
    return _LordRate
EndFunction

float Function GetTeammateRate()
    return _TeammateRate
EndFunction

float Function GetSimulationThreshold()
    return _SimulationThreshold
EndFunction

int Function GetFeedingChance()
    return _FeedingChance
EndFunction

int Function GetFollowerHuntChance()
    return _FollowerHuntChance
EndFunction

float Function GetSleepThreshold()
    return _SleepThreshold
EndFunction

int Function GetAmountToReduceFull()
    return _AmountToReduceFull
EndFunction

int Function GetAmountToReducePartial()
    return _AmountToReducePartial
EndFunction

int Function GetEventTTL()
    return _EventTTL
EndFunction

int Function GetDebugForceHungerState()
    return _DebugForceHungerState
EndFunction

bool Function GetStoreHungerEvents()
    return _StoreHungerEvents
EndFunction

; Setters (called by MCM)
Function SetBaseRate(float value)
    _BaseRate = value
EndFunction

Function SetLordRate(float value)
    _LordRate = value
EndFunction

Function SetTeammateRate(float value)
    _TeammateRate = value
EndFunction

Function SetSimulationThreshold(float value)
    _SimulationThreshold = value
EndFunction

Function SetFeedingChance(int value)
    _FeedingChance = value
EndFunction

Function SetFollowerHuntChance(int value)
    _FollowerHuntChance = value
EndFunction

Function SetSleepThreshold(float value)
    _SleepThreshold = value
EndFunction

Function SetAmountToReduceFull(int value)
    _AmountToReduceFull = value
EndFunction

Function SetAmountToReducePartial(int value)
    _AmountToReducePartial = value
EndFunction

Function SetEventTTL(int value)
    _EventTTL = value
EndFunction

Function SetDebugForceHungerState(int value)
    _DebugForceHungerState = value
EndFunction

Function SetStoreHungerEvents(bool value)
    if value != _StoreHungerEvents
        _StoreHungerEvents = value
        ; the schema says whether vampire_hunger is stored or short-lived
        registerEventSchemaHunger(!value)
    endif
EndFunction

int Function GetCurrentModVersion()
    return 2  ; Hardcoded mod version
EndFunction

Function startup()
    Console("SkyrimNet_Hunger loaded...")
    registerEventSchemaHunger(!GetStoreHungerEvents())
    registerEventSchemaHungerFed()
    RegisterForModEvent("NpcVampireFeed", "OnNpcVampireFeed")
    debugConsole("Registered for NpcVampireFeed mod event")
EndFunction

; Register the vampire_hunger event schema with SkyrimNet
Function registerEventSchemaHunger(bool isEphemeral = true)

    debugConsole("Start Registered vampire_hunger event schema with SkyrimNet")
        String fieldsJson = "[" + \
        "{\"name\":\"npc_name\",\"type\":0,\"required\":true,\"description\":\"Display name of the vampire\"}," + \
        "{\"name\":\"hunger_level\",\"type\":1,\"required\":true,\"description\":\"Current hunger level (0-100)\"}," + \
        "{\"name\":\"hunger_state\",\"type\":1,\"required\":true,\"description\":\"Hunger state ID (0=Satiated, 1=Thirsty, 2=Starving, 3=Feral)\"}," + \
        "{\"name\":\"state_name\",\"type\":0,\"required\":true,\"description\":\"Human-readable state name\"}," + \
        "{\"name\":\"previous_state\",\"type\":0,\"required\":false,\"description\":\"Previous hunger state name\",\"defaultValue\":\"Unknown\"}" + \
        "]"

    String formatTemplatesJson = "{" + \
        "\"recent_events\":\"**{{npc_name}}** becomes {{state_name}}{% if previous_state %} (was {{previous_state}}){% endif %} ({{time_desc}})\"," + \
        "\"raw\":\"{{npc_name}} -> {{state_name}}\"," + \
        "\"compact\":\"{{npc_name}}: {{state_name}} ({{hunger_level}})\"," + \
        "\"verbose\":\"Vampire Hunger: {{npc_name}} transitioned to {{state_name}} - Level: {{hunger_level}}/100, State ID: {{hunger_state}}{% if previous_state %}, Previous: {{previous_state}}{% endif %}\"" + \
        "}"
    


    SkyrimNetApi.RegisterEventSchema("vampire_hunger", "Vampire Hunger State Change", \
                                "A vampire's hunger state has changed (Satiated/Thirsty/Starving/Feral)", \
                                fieldsJson, formatTemplatesJson, isEphemeral, 120000, true, false)
    
    debugConsole("End Registered vampire_hunger event schema with SkyrimNet")
EndFunction

; Register the vampire_hunger_fed event schema with SkyrimNet: a feeding, always a stored event
Function registerEventSchemaHungerFed()
    String fieldsJson = "[" + \
        "{\"name\":\"npc_name\",\"type\":0,\"required\":true,\"description\":\"Display name of the vampire\"}," + \
        "{\"name\":\"in_combat\",\"type\":2,\"required\":true,\"description\":\"Whether the vampire fed during a fight\"}," + \
        "{\"name\":\"source\",\"type\":0,\"required\":true,\"description\":\"own (this mod saw the feeding) or NpcVampireFeed (another mod reported it)\"}," + \
        "{\"name\":\"hunger_before\",\"type\":1,\"required\":true,\"description\":\"Hunger level before feeding (0-100)\"}," + \
        "{\"name\":\"hunger_after\",\"type\":1,\"required\":true,\"description\":\"Hunger level after feeding (0-100)\"}," + \
        "{\"name\":\"state_name\",\"type\":0,\"required\":true,\"description\":\"Hunger state after feeding\"}" + \
        "]"

    String formatTemplatesJson = "{" + \
        "\"recent_events\":\"**{{npc_name}}** fed{% if in_combat %} during a fight{% endif %} and is now {{state_name}} ({{time_desc}})\"," + \
        "\"raw\":\"{{npc_name}} fed\"," + \
        "\"compact\":\"{{npc_name}} fed: {{state_name}} ({{hunger_after}})\"," + \
        "\"verbose\":\"Vampire Feeding: {{npc_name}} fed{% if in_combat %} during a fight{% endif %} - Level: {{hunger_before}} -> {{hunger_after}}/100, now {{state_name}}\"" + \
        "}"

    SkyrimNetApi.RegisterEventSchema("vampire_hunger_fed", "Vampire Fed", \
                                "A vampire fed, lowering its hunger", \
                                fieldsJson, formatTemplatesJson, false, 120000, true, false)

    debugConsole("Registered vampire_hunger_fed event schema with SkyrimNet")
EndFunction


Function ProcessActorUpdate(Actor akTarget)
    if !akTarget || akTarget.IsDead()
        Return
    endif
    float CurrentTime = Utility.GetCurrentGameTime()

    ; ---------------------------------------------------------
    ; 1. RATE CALCULATION & IDENTITY CHECKS
    ; ---------------------------------------------------------
    ActorBase BaseNPC = akTarget.GetBaseObject() as ActorBase
    Float CurrentRate = GetBaseRate()
    Bool IsFollower = akTarget.IsPlayerTeammate()

    ; A) VALERICA
    if BaseNPC == DLC1Valerica
        if akTarget.IsInLocation(DLC1SoulCairnLocation)
            SetActorHunger(akTarget, 0)
            Return
        endif
        CurrentRate = GetLordRate()

    ; B) LORDS
    elseif BaseNPC == DLC1Serana || BaseNPC == DLC1Harkon
        CurrentRate = GetLordRate()

    ; C) FOLLOWERS
    elseif IsFollower
        CurrentRate = GetTeammateRate()
    endif


    ; ---------------------------------------------------------
    ; 2. ENVIRONMENT CHECKS (Vampire Lairs = Safe Zones)
    ; ---------------------------------------------------------
    ; We keep this because it prevents boss fights (Harkon) starting with hunger debuffs.
    Location CurrentLoc = akTarget.GetCurrentLocation()

    if CurrentLoc && CurrentLoc.HasKeyword(LocTypeVampireLair)
        debugConsole(akTarget.GetDisplayName() + " in Vampire Lair - resetting hunger to 0")
        SetActorHunger(akTarget, 0)
        Return ; EXIT
    endif


    ; ---------------------------------------------------------
    ; 3. INITIALIZATION
    ; ---------------------------------------------------------
    if !akTarget.IsInFaction(SHS_BloodFaction)
        SetActorHunger(akTarget, 0)
        Return
    endif


    ; ---------------------------------------------------------
    ; 4. TIME CALCULATION
    ; ---------------------------------------------------------
    float LastSeen = StorageUtil.GetFloatValue(akTarget, "SHS_LastSeen", missing = CurrentTime)
    float HoursPassed = (CurrentTime - LastSeen) * 24.0
    
    if HoursPassed < 1.0
        HoursPassed = 1.0
    endif


    ; ---------------------------------------------------------
    ; 5. LOGIC BRANCH
    ; ---------------------------------------------------------
    int NewHunger = 0
    int CurrentHunger = akTarget.GetFactionRank(SHS_BloodFaction)

    ; --- BRANCH A: FOLLOWER "NIGHT HUNT" (Sleep/Wait) ---
    ; If it's a follower AND enough time passed (Sleep/Wait), they try to hunt.
    if IsFollower && HoursPassed >= GetSleepThreshold()

        debugConsole(akTarget.GetDisplayName() + ": Follower sleep/wait detected (" + HoursPassed + "h) - rolling hunt chance")
        int DiceRoll = Utility.RandomInt(0, 100)

        if DiceRoll <= GetFollowerHuntChance()
            ; SUCCESS: They fed while you slept.
            NewHunger = 0
            debugConsole(akTarget.GetDisplayName() + ": Hunt SUCCESS - hunger reset to 0")
        else
            ; FAIL: They just waited. Add normal hunger.
            int AddedHunger = (HoursPassed * CurrentRate) as Int
            NewHunger = CurrentHunger + AddedHunger
            debugConsole(akTarget.GetDisplayName() + ": Hunt FAILED - adding " + AddedHunger + " hunger")
        endif


    ; --- BRANCH B: GENERIC NPC LONG ABSENCE ---
    ; If not a follower, and player was gone for > 24 hours.
    elseif !IsFollower && HoursPassed >= GetSimulationThreshold()

        debugConsole(akTarget.GetDisplayName() + ": Long absence (" + HoursPassed + "h) - simulating life")
        int DiceRoll = Utility.RandomInt(0, 100)

        if DiceRoll <= GetFeedingChance()
            NewHunger = Utility.RandomInt(0, 30) ; Fed
        else
            NewHunger = Utility.RandomInt(70, 95) ; Starved
        endif


    ; --- BRANCH C: LINEAR UPDATE ---
    ; Standard active gameplay update.
    else
        debugConsole(akTarget.GetDisplayName() + ": Standard update (" + HoursPassed + "h) - adding " + ((HoursPassed * CurrentRate) as Int) + " hunger")
        int AddedHunger = (HoursPassed * CurrentRate) as Int
        NewHunger = CurrentHunger + AddedHunger
    endif


    ; ---------------------------------------------------------
    ; 6. APPLY & CAP
    ; ---------------------------------------------------------
    SetActorHunger(akTarget, NewHunger)

EndFunction

Function FeedActor(Actor akTarget, Actor akVictim = None, bool reported = false)
    if !akTarget
        Return
    endif

    int CurrentHunger = akTarget.GetFactionRank(SHS_BloodFaction)
    int AmountToReduce = 0
    int VictimBonus = 0

    ; --- Calculate base feeding amount based on combat state ---
    if akTarget.IsInCombat()
        ; Combat feeding: full drain with some variance (80-100%)
        AmountToReduce = (GetAmountToReduceFull() * Utility.RandomInt(80, 100)) / 100
        debugConsole(akTarget.GetDisplayName() + ": Combat feeding (desperate drain)")
    else
        ; Non-combat feeding: partial with variance (60-100%)
        AmountToReduce = (GetAmountToReducePartial() * Utility.RandomInt(60, 100)) / 100
        debugConsole(akTarget.GetDisplayName() + ": Controlled feeding (partial)")
    endif

    ; --- Calculate victim quality bonus ---
    if akVictim
        ; Base victim bonus: 10-30 points
        VictimBonus = Utility.RandomInt(10, 30)

        ; Stronger victims provide more sustenance
        int VictimLevel = akVictim.GetLevel()
        if VictimLevel >= 30
            VictimBonus += 20  ; Powerful victim
        elseif VictimLevel >= 15
            VictimBonus += 10  ; Average victim
        endif

        ; Essential/important NPCs provide better sustenance
        if akVictim.IsEssential()
            VictimBonus += 15
        endif

        debugConsole(akTarget.GetDisplayName() + ": Feeding on " + akVictim.GetDisplayName() + " (bonus: +" + VictimBonus + ")")
    endif

    ; --- Hunger modifier: starving vampires feed more desperately ---
    float HungerMultiplier = 1.0
    if CurrentHunger >= 91  ; Feral state
        HungerMultiplier = 1.5
        debugConsole(akTarget.GetDisplayName() + ": Feral state - desperate feeding (+50% effectiveness)")
    elseif CurrentHunger >= 76  ; Starving state
        HungerMultiplier = 1.25
        debugConsole(akTarget.GetDisplayName() + ": Starving - aggressive feeding (+25% effectiveness)")
    elseif CurrentHunger <= 25  ; Satiated state
        HungerMultiplier = 0.7
        debugConsole(akTarget.GetDisplayName() + ": Already satiated - partial feeding only (-30% effectiveness)")
    endif

    ; --- Calculate final reduction ---
    int TotalReduction = ((AmountToReduce + VictimBonus) * HungerMultiplier) as int

    ; Combat vampires trigger bite attacks more often
    if akTarget.IsInCombat()
        ; 75% chance to trigger vampire bite ability on combat feeds
        if Utility.RandomInt(1, 100) <= 75
            debugConsole(akTarget.GetDisplayName() + ": Combat feeding triggered vampire bite attack!")
            ; TODO: Trigger vampire bite spell/ability here if you have one defined
            ; akTarget.Cast(VampireBiteSpell, akVictim)
        endif
    endif

    ; --- Apply the reduction ---
    int NewHunger = CurrentHunger - TotalReduction
    debugConsole(akTarget.GetDisplayName() + " fed: " + CurrentHunger + " -> " + NewHunger + " (-" + TotalReduction + " hunger)")
    bool inCombat = akTarget.IsInCombat()
    SetActorHunger(akTarget, NewHunger)
    generateSkyrimNetFedEvent(akTarget, CurrentHunger, akTarget.GetFactionRank(SHS_BloodFaction), inCombat, reported)

EndFunction

Actor Function getActorSerana()
    Actor Serana = Game.GetFormFromFile(0x00002B74, "Dawnguard.esm") as Actor
    return Serana
Endfunction

int Function GetSeranaFactionRank()
    Actor Serana = getActorSerana()

    if !Serana
        return 0
    endif

    if !Serana.IsInFaction(SHS_BloodFaction)
        return 0
    endif

    int Rank = Serana.GetFactionRank(SHS_BloodFaction)
    if Rank < 0
        return 0
    endif

    return Rank
EndFunction

function console(string in)
    MiscUtil.PrintConsole("SHS: "+in)
    Debug.Trace("SHS: "+in)
EndFunction

function debugConsole(string in)
    if isEnabledDeveloperMode()
        MiscUtil.PrintConsole("SHS: DEBUG: "+in)
        Debug.Trace("SHS: DEBUG: "+in)
    endif
EndFunction

bool function isEnabledDeveloperMode()
    if SHS_DevelopmentModeEnabled.GetValueInt() == 1
        return true
    endif
        return false
Endfunction


bool Function IsActorLoaded(Actor npc)
    return npc.Is3DLoaded() && !npc.IsDead() && !npc.IsDisabled()
Endfunction


Function updatedHungerSpellOnSerana(bool status)    
    Actor Serana = getActorSerana()

    if status
        _testApplyHungerOnNpc(Serana)
    else
       _testRemoveHungerOnNpc(Serana)
    endif
EndFunction

Function _testApplyHungerOnNpc(Actor npc)
    npc.addspell(SHS_BoodHungerSpell, false)
EndFunction

Function _testRemoveHungerOnNpc(Actor npc)
    debugConsole("Removing blood decal to actor: "+npc.getbaseobject().getname())
    npc.removespell(SHS_BoodHungerSpell)
Endfunction

int Function GetHungerState(int hungerRank)
    if hungerRank <= 25
        return 0  ; Satiated
    elseif hungerRank <= 75
        return 1  ; Thirsty
    elseif hungerRank <= 90
        return 2  ; Starving
    else
        return 3  ; Feral
    endif
EndFunction

string Function GetHungerStateName(int hungerRank)
    int hungerState = GetHungerState(hungerRank)

    if hungerState == 0
        return "Satiated"
    elseif hungerState == 1
        return "Thirsty"
    elseif hungerState == 2
        return "Starving"
    else
        return "Feral"
    endif
EndFunction

Function generateSkyrimNetHungerEvent(Actor npc, int oldHungerLevel, int newHungerLevel)
    if !npc
        return
    endif

    string npcName = npc.GetDisplayName()
    int hungerState = GetHungerState(newHungerLevel)
    string stateName = GetHungerStateName(newHungerLevel)
    ; a level below 0 means the vampire wasn't tracked before (its first event)
    string previousStateName = "Unknown"
    if oldHungerLevel >= 0
        previousStateName = GetHungerStateName(oldHungerLevel)
    endif

    ; Create unique event ID using FormID and current time
    String eventId = "vampirehunger_" + npc.GetFormID() + "_" + (Utility.GetCurrentRealTime() as Int)

    ; Create event description
    string eventDescription = npcName + " becomes " + stateName + " (was " + previousStateName + ")"

    ; Build event data JSON matching the schema
    String eventDataJson = "{"
    eventDataJson += "\"npc_name\":\"" + npcName + "\","
    eventDataJson += "\"hunger_level\":" + newHungerLevel + ","
    eventDataJson += "\"hunger_state\":" + hungerState + ","
    eventDataJson += "\"state_name\":\"" + stateName + "\","
    eventDataJson += "\"previous_state\":\"" + previousStateName + "\""
    eventDataJson += "}"

    ; Convert seconds to milliseconds for SkyrimNet API
    int ttlMs = GetEventTTL() * 1000

    debugConsole("HUNGER EVENT: " + eventDescription)

    if !SkyrimNetApi.ValidateEventData("vampire_hunger", eventDataJson)
        console("ERROR: Validation failed for event data!")
        return
    EndIf

    if GetStoreHungerEvents()
        ; a stored event: in the vampire's history, for every SkyrimNet reader and for its memories
        SkyrimNetApi.RegisterEvent("vampire_hunger", eventDataJson, npc, npc)
        debugConsole("SkyrimNet event stored: " + eventDescription)
    else
        ; Register short-lived event with SkyrimNet
        int result = SkyrimNetApi.RegisterShortLivedEvent(eventId, "vampire_hunger", eventDescription, eventDataJson, ttlMs, npc, npc)
        debugConsole("SkyrimNet event registered (TTL: " + GetEventTTL() + "s): " + result)
    endif
EndFunction

; A feeding, as a stored vampire_hunger_fed event, while hunger changes are kept in SkyrimNet's history
Function generateSkyrimNetFedEvent(Actor npc, int hungerBefore, int hungerAfter, bool inCombat, bool reported)
    if !npc || !GetStoreHungerEvents()
        return
    endif

    string source = "own"
    if reported
        source = "NpcVampireFeed"
    endif
    string inCombatJson = "false"
    if inCombat
        inCombatJson = "true"
    endif

    String eventDataJson = "{"
    eventDataJson += "\"npc_name\":\"" + npc.GetDisplayName() + "\","
    eventDataJson += "\"in_combat\":" + inCombatJson + ","
    eventDataJson += "\"source\":\"" + source + "\","
    eventDataJson += "\"hunger_before\":" + hungerBefore + ","
    eventDataJson += "\"hunger_after\":" + hungerAfter + ","
    eventDataJson += "\"state_name\":\"" + GetHungerStateName(hungerAfter) + "\""
    eventDataJson += "}"

    if !SkyrimNetApi.ValidateEventData("vampire_hunger_fed", eventDataJson)
        console("ERROR: Validation failed for feeding event data!")
        return
    EndIf

    SkyrimNetApi.RegisterEvent("vampire_hunger_fed", eventDataJson, npc, npc)
    debugConsole("SkyrimNet feeding event stored for " + npc.GetDisplayName())
EndFunction

bool Function CheckHungerStateChange(Actor npc, int oldHunger, int newHunger)
    if !npc
        return false
    endif

    int oldState = GetHungerState(oldHunger)
    int newState = GetHungerState(newHunger)

    if oldState != newState
        generateSkyrimNetHungerEvent(npc, oldHunger, newHunger)
        SendVampireHungerModEvent(npc, newHunger, newState)
        return true
    endif
    return false
EndFunction

Function SendVampireHungerModEvent(Actor npc, int hungerLevel, int hungerState)
    if !npc
        return
    endif

    int handle = ModEvent.Create(EVENT_VAMPIRE_HUNGER)
    if handle
        ModEvent.PushForm(handle, npc)
        ModEvent.PushInt(handle, hungerLevel)
        ModEvent.PushInt(handle, hungerState)
        ModEvent.PushString(handle, GetHungerStateName(hungerLevel))
        ModEvent.Send(handle)
        debugConsole("Sent ModEvent: " + EVENT_VAMPIRE_HUNGER + " for " + npc.GetDisplayName() + " - State: " + hungerState + " (" + GetHungerStateName(hungerLevel) + ")")
    else
        debugConsole("Failed to create ModEvent: " + EVENT_VAMPIRE_HUNGER)
    endif
EndFunction

Event OnNpcVampireFeed(string eventName, string strArg, float numArg, Form sender)
    debugConsole("NpcVampireFeed Event Received")
    debugConsole("Sender Form ID: " + sender.GetFormID())

    Actor vampire = sender as Actor
    if !vampire
        debugConsole("ERROR: Sender is not an Actor!")
        return
    endif

    debugConsole(vampire.GetDisplayName() + " fed via NpcVampireFeed event - treating as willing feed (non-combat)")

    ; Use the existing FeedActor function with no victim (None)
    ; This will treat it as a non-combat feeding with partial reduction
    FeedActor(vampire, None, true)
EndEvent


Function SetActorHunger(Actor npc, int newHungerLevel)
    if !npc
        return
    endif

    ; Ensure actor is in faction
    bool firstTracked = false
    if !npc.IsInFaction(SHS_BloodFaction)
        npc.AddToFaction(SHS_BloodFaction)
        firstTracked = true
        debugConsole("SetActorHunger: Added " + npc.GetDisplayName() + " to SHS_BloodFaction")
    endif

    ; Get current hunger
    int currentHunger = npc.GetFactionRank(SHS_BloodFaction)

    ; Debug: Force hunger state override
    int debugForce = GetDebugForceHungerState()
    if debugForce >= 0
        if debugForce == 0
            newHungerLevel = 0    ; Force satiated
        elseif debugForce == 1
            newHungerLevel = 50   ; Force thirsty
        elseif debugForce == 2
            newHungerLevel = 100  ; Force feral
        endif
        debugConsole("DEBUG: Forcing " + npc.GetDisplayName() + " hunger to " + newHungerLevel)
    endif

    ; Cap the new value
    if newHungerLevel < 0
        newHungerLevel = 0
    elseif newHungerLevel > 100
        newHungerLevel = 100
    endif

    ; Only update if changed
    bool stateEventSent = false
    if newHungerLevel != currentHunger
        ; Check for state changes and trigger events
        stateEventSent = CheckHungerStateChange(npc, currentHunger, newHungerLevel)

        ; Apply the new hunger level
        npc.SetFactionRank(SHS_BloodFaction, newHungerLevel)

        debugConsole(npc.GetDisplayName() + " hunger updated: " + currentHunger + " -> " + newHungerLevel + " (" + GetHungerStateName(newHungerLevel) + ")")
    endif

    ; A vampire tracked for the first time gets its starting state stored too, so the newest stored vampire_hunger
    ; event always gives a tracked vampire's current state
    if firstTracked && !stateEventSent && GetStoreHungerEvents()
        generateSkyrimNetHungerEvent(npc, -1, newHungerLevel)
    endif

    StorageUtil.SetFloatValue(npc, "SHS_LastSeen", Utility.GetCurrentGameTime())
EndFunction