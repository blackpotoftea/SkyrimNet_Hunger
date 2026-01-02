Scriptname SHS_Player_Alias extends ReferenceAlias  


event OnInit()
    startup()
endevent

event OnPlayerLoadGame()
    startup()
endevent


Function startup()
    Debug.Notification("==== SKYRIMNET HUNGER ====")
    (GetOwningQuest() as SHS_Main).startup()
EndFunction