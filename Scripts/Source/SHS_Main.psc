Scriptname SHS_Main extends Quest  

Faction Property SHS_BloodFaction  Auto  

SPELL Property SHS_BoodHungerSpell  Auto  

MagicEffect Property SHS_BloodHunger  Auto  

GlobalVariable Property SHS_DevelopmentModeEnabled  Auto  

ActorBase Property DLC1Serana  Auto  
ActorBase Property DLC1Harkon  Auto  
ActorBase Property DLC1Valerica  Auto  

Location Property DLC1SoulCairnLocation  Auto  

Keyword Property LocTypeVampireLair  Auto  

float Property BaseRate = 5.0 Auto          ; Standard hunger/hour
Float Property LordRate = 1.0 Auto          ; Serana/Harkon/Valerica rate
Float Property TeammateRate = 2.0 Auto      ; Active Follower rate

Float Property SimulationThreshold = 8.0 Auto ; Hours passed before "Life Sim" kicks in
Int Property FeedingChance = 75 Auto          ; % Chance they ate while you were gone
Int Property FollowerHuntChance = 60 Auto 
Float Property SleepThreshold = 4.0 Auto
int Property AmountToReduceFull = 100 Auto
int Property AmountToReducePartial = 100 Auto
int Property CURRENT_MOD_VERSION = 1 Auto

Function startup()
    Console("SkyrimNet_Hunger loaded...")
EndFunction


Function ProcessActorUpdate(Actor akTarget)
    if !akTarget || akTarget.IsDead()
        Return
    endif

    debugConsole("ProcessActorUpdate() called for: " + akTarget.GetDisplayName())
    float CurrentTime = Utility.GetCurrentGameTime()

    ; ---------------------------------------------------------
    ; 1. RATE CALCULATION & IDENTITY CHECKS
    ; ---------------------------------------------------------
    ActorBase BaseNPC = akTarget.GetBaseObject() as ActorBase
    Float CurrentRate = BaseRate 
    Bool IsFollower = akTarget.IsPlayerTeammate()

    ; A) VALERICA
    if BaseNPC == DLC1Valerica
        if akTarget.IsInLocation(DLC1SoulCairnLocation)
            akTarget.SetFactionRank(SHS_BloodFaction, 0)
            StorageUtil.SetFloatValue(akTarget, "SHS_LastSeen", CurrentTime)
            Return
        endif
        CurrentRate = LordRate
    
    ; B) LORDS
    elseif BaseNPC == DLC1Serana || BaseNPC == DLC1Harkon
        CurrentRate = LordRate

    ; C) FOLLOWERS
    elseif IsFollower
        CurrentRate = TeammateRate
    endif


    ; ---------------------------------------------------------
    ; 2. ENVIRONMENT CHECKS (Vampire Lairs = Safe Zones)
    ; ---------------------------------------------------------
    ; We keep this because it prevents boss fights (Harkon) starting with hunger debuffs.
    Location CurrentLoc = akTarget.GetCurrentLocation()
    
    if CurrentLoc && CurrentLoc.HasKeyword(LocTypeVampireLair)
        debugConsole("Actor in Vampire Lair. Hunger Reset.")
        akTarget.SetFactionRank(SHS_BloodFaction, 0)
        StorageUtil.SetFloatValue(akTarget, "SHS_LastSeen", CurrentTime)
        Return ; EXIT
    endif


    ; ---------------------------------------------------------
    ; 3. INITIALIZATION
    ; ---------------------------------------------------------
    if !akTarget.IsInFaction(SHS_BloodFaction)
        akTarget.AddToFaction(SHS_BloodFaction)
        akTarget.SetFactionRank(SHS_BloodFaction, 0)
        StorageUtil.SetFloatValue(akTarget, "SHS_LastSeen", CurrentTime)
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
    if IsFollower && HoursPassed >= SleepThreshold
        
        console("Follower Sleep/Wait Detected (" + HoursPassed + "h). Rolling Hunt Chance.")
        int DiceRoll = Utility.RandomInt(0, 100)
        
        if DiceRoll <= FollowerHuntChance
            ; SUCCESS: They fed while you slept.
            NewHunger = 0 
            console("Hunt SUCCESS. Hunger reset to 0.")
        else
            ; FAIL: They just waited. Add normal hunger.
            int AddedHunger = (HoursPassed * CurrentRate) as Int
            NewHunger = CurrentHunger + AddedHunger
            console("Hunt FAILED. Adding " + AddedHunger + " hunger.")
        endif


    ; --- BRANCH B: GENERIC NPC LONG ABSENCE ---
    ; If not a follower, and player was gone for > 24 hours.
    elseif !IsFollower && HoursPassed >= SimulationThreshold
        
        console("Long Absence (>24h). Simulating life.")
        int DiceRoll = Utility.RandomInt(0, 100)
        
        if DiceRoll <= FeedingChance
            NewHunger = Utility.RandomInt(0, 30) ; Fed
        else
            NewHunger = Utility.RandomInt(70, 95) ; Starved
        endif


    ; --- BRANCH C: LINEAR UPDATE ---
    ; Standard active gameplay update.
    else
        console("Standard Linear Update.")
        int AddedHunger = (HoursPassed * CurrentRate) as Int
        NewHunger = CurrentHunger + AddedHunger
    endif


    ; ---------------------------------------------------------
    ; 6. APPLY & CAP
    ; ---------------------------------------------------------
    if NewHunger > 100
        NewHunger = 100
    endif

    if NewHunger != CurrentHunger
        akTarget.SetFactionRank(SHS_BloodFaction, NewHunger)
    endif
    
    StorageUtil.SetFloatValue(akTarget, "SHS_LastSeen", CurrentTime)

EndFunction

Function FeedActor(Actor akTarget)
    if !akTarget
        Return
    endif
    
    int AmountToReduce = 0
    

    if akTarget.IsInCombat()
        AmountToReduce = AmountToReduceFull ; Combat fed target fully drained
        console("FeedActor: " + akTarget.GetDisplayName() + " fed in combat. reducing by -"+AmountToReduceFull)
    else
        AmountToReduce = AmountToReducePartial ; Partial feed (quick bite)
        console("FeedActor: " + akTarget.GetDisplayName() + " fed in combat. reducing by -"+AmountToReducePartial)
    endif
    
    ; --- Apply Reduction ---
    int Current = akTarget.GetFactionRank(SHS_BloodFaction)
    int NewVal = Current - AmountToReduce
    
    if NewVal < 0
        NewVal = 0
    endif
    
    console("setting hunger rank: "+ NewVal)
    if NewVal != Current
        akTarget.SetFactionRank(SHS_BloodFaction, NewVal)
    endif
    
    ; CRITICAL: Reset the "LastSeen" timer.
    StorageUtil.SetFloatValue(akTarget, "SHS_LastSeen", Utility.GetCurrentGameTime())
    
EndFunction

; Bool Function IsThrallNearby(Actor akVampire)
;     ; Uses PO3 Extender for native speed (Zero FPS cost)
;     Actor Food = PO3_SKSEFunctions.FindClosestActor(akVampire, ScanRadius, None, DLC1VampireCattleFaction, false)
;     if Food
;         debugConsole("Live thrall detected nearby: " + Food.GetDisplayName())
;         return true
;     endif
;     return false
; EndFunction

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


int Function getCurrentModVersion()
    return CURRENT_MOD_VERSION
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

; Returns hunger state based on faction rank (0-100)
; 0 = Satiated (0-25): NPC has recently fed, acts normal, no buffs or debuffs
; 1 = Thirsty (26-75): The urge is beginning, functions normally but might complain
; 2 = Starving (76-90): Visibly weak, may start looking for sleeping NPCs to feed on
; 3 = Feral (91-100): Lost control, ignores social norms, might attack on sight
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

; Returns hunger state name as string
string Function GetHungerStateName(int hungerRank)
    int state = GetHungerState(hungerRank)

    if state == 0
        return "Satiated"
    elseif state == 1
        return "Thirsty"
    elseif state == 2
        return "Starving"
    else
        return "Feral"
    endif
EndFunction