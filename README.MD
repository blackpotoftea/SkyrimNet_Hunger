# SkyrimNet Hunger

A Skyrim mod that tracks vampire hunger states and integrates with SkyrimNet for AI-driven character interactions.

## Features

- Dynamic vampire hunger system with 4 distinct states
- Real-time hunger tracking for vampire NPCs (Serana, Harkon, Valerica, and others)
- SkyrimNet integration for AI-aware character behaviors
- ModEvent support for cross-mod compatibility
- MCM configuration support

## Hunger States

The mod tracks vampire hunger on a scale of 0-100 with four distinct states:

- **Satiated (0-25)**: Recently fed, acts normally
- **Thirsty (26-75)**: Beginning to feel the urge, functions normally but may complain
- **Starving (76-90)**: Visibly weak, may seek out sleeping NPCs to feed
- **Feral (91-100)**: Lost control, ignores social norms, may attack on sight

## ModEvent Integration

### For Mod Authors

This mod sends a ModEvent whenever a vampire's hunger state changes, allowing other mods to react to vampire behavior.

#### Outgoing Event: `SHS_VampireHungerChanged`

#### Event Parameters

The event sends the following data:

1. **Form** - The vampire NPC actor
2. **Int** - Hunger level (0-100)
3. **Int** - Hunger state ID (0=Satiated, 1=Thirsty, 2=Starving, 3=Feral)
4. **String** - Human-readable state name ("Satiated", "Thirsty", "Starving", "Feral")

#### Example Usage

```papyrus
Scriptname MyModScript extends ReferenceAlias

Event OnInit()
    ; Register to receive vampire hunger state changes
    RegisterForModEvent("SHS_VampireHungerChanged", "OnVampireHungerChanged")
EndEvent

Event OnVampireHungerChanged(Form npcForm, int hungerLevel, int hungerState, string stateName)
    Actor vampire = npcForm as Actor

    if !vampire
        return
    endif

    ; React to hunger state changes
    if hungerState == 3  ; Feral
        Debug.Notification(vampire.GetDisplayName() + " has become feral!")
        ; Take action - enable aggressive behavior, etc.
    elseif hungerState == 0  ; Satiated
        Debug.Notification(vampire.GetDisplayName() + " has fed and is satiated.")
        ; Calm behavior, disable aggression, etc.
    endif
EndEvent
```

#### Use Cases

- **Dialogue Systems**: Adjust vampire dialogue based on hunger state
- **AI Behavior**: Modify vampire AI packages when they become starving or feral
- **Visual Effects**: Apply visual effects (red eyes, pale skin) based on hunger level
- **Gameplay Mechanics**: Create feeding quests or consequences based on vampire hunger
- **Companion Management**: Alert the player when companion vampires are hungry

### Event Triggering

The event only fires when the hunger **state** changes (crossing thresholds), not on every hunger value change. This prevents spam and ensures you only receive meaningful state transitions.

---

### Incoming Event: `NpcVampireFeed`

This mod listens for the `NpcVampireFeed` ModEvent to automatically adjust vampire hunger when NPCs feed through other mods (e.g., Devour - Sensual Vampire Feeding).

#### Event Parameters Expected

- **sender** (Form): The vampire actor who is feeding
- **strArg** (String): Amount fed (optional, unused - mod uses its own feeding calculation)
- **numArg** (Float): Numeric argument (unused)

#### How It Works

When `NpcVampireFeed` is received:
1. The vampire NPC is extracted from the sender
2. The mod's existing feeding logic is applied (non-combat, partial reduction)
3. Hunger is reduced based on current hunger state and configuration
4. If hunger state changes, a `SHS_VampireHungerChanged` event is sent

#### Sending This Event

```papyrus
; Example: Notify SkyrimNet_Hunger that an NPC has fed
int handle = ModEvent.Create("NpcVampireFeed")
if handle
    ModEvent.PushForm(handle, vampireActor)
    ModEvent.PushString(handle, "20")  ; Optional amount (unused)
    ModEvent.PushFloat(handle, 0.0)    ; Optional numeric arg (unused)
    ModEvent.Send(handle)
endif
```

## SkyrimNet Integration

This mod registers vampire hunger events with SkyrimNet, enabling AI characters to be aware of and respond to vampire hunger states in conversations and behaviors.

## Requirements

- SKSE64
- SkyUI (for MCM)
- PapyrusUtil
- SkyrimNet (for AI integration features)
- Dawnguard DLC

## Installation

Install with your mod manager of choice or manually extract to your Data folder.

## Configuration

Configure settings through the MCM menu:
- Enable/disable development mode for debug logging
- Adjust hunger rates
- Configure feeding mechanics
- Set event TTL for SkyrimNet integration

## Credits

Created for SkyrimNet integration and enhanced vampire gameplay experience.
