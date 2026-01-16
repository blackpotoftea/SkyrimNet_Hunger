Scriptname SHS_Player_Alias extends ReferenceAlias  


event OnInit()
    startup()
endevent

event OnPlayerLoadGame()
    startup()
endevent


Function startup()
    (GetOwningQuest() as SHS_Main).startup()
EndFunction