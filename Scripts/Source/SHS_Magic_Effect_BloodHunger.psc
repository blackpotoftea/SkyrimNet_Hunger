Scriptname SHS_Magic_Effect_BloodHunger extends ActiveMagicEffect  

Quest Property SHS_Main_Q  Auto  
SHS_Main SHSM
Float Property BaseInterval = 1.0 Auto 
Float Property TimeJitter = 0.25 Auto
bool     keepAnimRegister = true
string EVENT_VAMPIRE_FEED_ANIM     = "VFD_VampireFeedTrigger"
string EVENT_BLOOD_DECAL           = "VFD_BloodDecals_Event"
Actor  selfRef

int usedModVersion = 0

Event OnEffectStart(Actor npc, Actor akCaster)
    SHSM = SHS_Main_Q as SHS_Main
        
    if SHSM
        selfRef = npc

        usedModVersion = SHSM.getCurrentModVersion()
        SHSM.debugConsole("Apply effect to actor: "+npc.getbaseobject().getname())
        SHSM.ProcessActorUpdate(selfRef)
        float delay = Utility.RandomFloat(0.1, BaseInterval + TimeJitter)
        RegisterForSingleUpdateGameTime(delay)
        registerForBloodDecalAnim()
    else
        ; Error handling: If the script is missing, stop.
        Debug.Trace("SHS Error: Could not find SHS_Main quest script!")
    endif
EndEvent

Event OnUpdateGameTime()
    if CheckForUpdate()
        Return
    endif

    SHSM.debugConsole("Periodic update for " + selfRef.GetDisplayName() + " (interval: " + BaseInterval + "h)")
    SHSM.ProcessActorUpdate(selfRef)
    float delay = BaseInterval + Utility.RandomFloat(0.0, TimeJitter)
    RegisterForSingleUpdateGameTime(delay)
EndEvent

Event OnAnimationEvent(ObjectReference akSource, string asEventName)
    if (asEventName == EVENT_VAMPIRE_FEED_ANIM) && (akSource == selfRef)
        SHSM.debugConsole("Vampire Feed Animation detected for " + selfRef.GetDisplayName() + " - triggering FeedActor")
        SHSM.FeedActor(selfRef)
    endif
endEvent

Event OnFeedEvent(Form sender, string eventStatus)
    if ((sender as Actor) == selfRef)
        SHSM.debugConsole("Mod Event '" + EVENT_BLOOD_DECAL + "' received for " + selfRef.GetDisplayName() + " - triggering FeedActor")
        SHSM.FeedActor(selfRef)
    endif
endEvent

Event OnAnimationEventUnregistered(ObjectReference akSource, string asEventName)
	SHSM.debugConsole("Animation event '" + asEventName + "' unregistered for " + selfRef.GetDisplayName())
    if keepAnimRegister && SHSM.IsActorLoaded(selfRef)
        SHSM.debugConsole("Re-registering animation events for " + selfRef.GetDisplayName())
        registerForBloodDecalAnim()
    endif
endEvent

function registerForBloodDecalAnim()
    SHSM.debugConsole("Registering feed events for " + selfRef.GetDisplayName() + ": Animation='" + EVENT_VAMPIRE_FEED_ANIM + "', ModEvent='" + EVENT_BLOOD_DECAL + "'")
    RegisterForModEvent(EVENT_BLOOD_DECAL, "OnFeedEvent")
    RegisterForAnimationEvent(selfRef, EVENT_VAMPIRE_FEED_ANIM)
endfunction


Event OnEffectFinish(Actor npc, Actor akCaster)
    SHSM.debugConsole("Blood Hunger effect ending for " + selfRef.GetDisplayName())
    keepAnimRegister = false
Endevent


bool Function CheckForUpdate()
    if SHSM
        int globalVersion = SHSM.getCurrentModVersion()
        SHSM.debugConsole("Comparing version, current: "+usedModVersion+" global: "+globalVersion)
        if usedModVersion < globalVersion
            SHSM.Console("SHS Update Detected: Removing outdated spell from " + selfRef.GetBaseObject().GetName())
            
            ; Using the spell property located on the Main Script
            selfRef.RemoveSpell(SHSM.SHS_BoodHungerSpell)
            
            return true
        endif
    endif
    return false
EndFunction