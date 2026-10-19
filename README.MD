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

### Reading a Vampire's Hunger

A vampire's current hunger is its rank in the blood faction, which other mods can read at any time (for example right after a save loads, when no event has fired yet):

- **Faction:** `SHS_BloodFaction`, form `0x002F9B` in `SkyrimNet_Hunger.esp`
- **Rank:** the hunger level, 0-100. A vampire not in the faction isn't tracked yet.
- **States:** 0-25 Satiated, 26-75 Thirsty, 76-90 Starving, 91-100 Feral

The faction, its form ID and the meaning of its rank are kept stable for other mods.

### SkyrimNet Events

Every hunger state change is a short-lived `vampire_hunger` event, shown for the **Event Duration** set in the MCM, as before.

While **Keep in SkyrimNet's History** is on (the default), the mod also stores two events in SkyrimNet's history. Every SkyrimNet mod can read them (for example with `PublicGetRecentEvents` from C++), and SkyrimNet turns them into the NPCs' memories like any stored event. The vampire is both originator and target.

- **`vampire_hunger_state`**: a hunger state change, with the same fields as `vampire_hunger`: `npc_name`, `hunger_level` (0-100), `hunger_state` (0=Satiated, 1=Thirsty, 2=Starving, 3=Feral), `state_name` and `previous_state`. A vampire tracked for the first time gets one too, with `previous_state` "Unknown", so a tracked vampire's newest `vampire_hunger_state` event always gives its current state.
- **`vampire_hunger_fed`**: a feeding, with `npc_name`, `in_combat` (true or false), `source` ("own" when this mod saw the feeding, "NpcVampireFeed" when another mod reported it), `hunger_before`, `hunger_after` and `state_name` (after feeding).

The stored change has a type of its own because SkyrimNet keeps the first schema registered for an event type: `vampire_hunger` has been short-lived since its first release, so it is never switched to a stored event. Both stored types are registered once at start-up; the option only decides whether they are sent.

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

This mod registers vampire hunger events with SkyrimNet, enabling AI characters to be aware of and respond to vampire hunger states in conversations and behaviors. By default, hunger changes and feedings are kept in SkyrimNet's history, so the NPCs remember them (see [SkyrimNet Events](#skyrimnet-events)).

The AI prompt ships as a SkyrimNet plugin, `potoftea.vampire-hunger`, in `SKSE/Plugins/SkyrimNet/external/`. It appears on SkyrimNet's Installed Plugins page with an External badge.

**Upgrading from 1.3 or earlier:** SkyrimNet Beta 25 no longer reads the old prompt location (`SKSE/Plugins/SkyrimNet/prompts/`). If you copied `8999_vampire_hunger.prompt` with Plugins > Import Old Content, remove that imported copy from your overlay, or it will hide this mod's prompt updates.

## Requirements

- SKSE64
- SkyUI (for MCM)
- [PapyrusUtil SE](https://www.nexusmods.com/skyrimspecialedition/mods/13048)
- [MCM Helper](https://www.nexusmods.com/skyrimspecialedition/mods/53000)
- [Vampire Animations](https://www.nexusmods.com/skyrimspecialedition/mods/100349)
- SkyrimNet Beta 25 (0.25.0) or newer, for the AI prompt. Older betas won't load it.
- Dawnguard DLC

## Installation

Install with your mod manager of choice or manually extract to your Data folder.

## Configuration

Configure settings through the MCM menu:
- Enable/disable development mode for debug logging
- Adjust hunger rates
- Configure feeding mechanics
- Also keep hunger changes and feedings in SkyrimNet's history
- Set event TTL for SkyrimNet integration

## Credits

Created for SkyrimNet integration and enhanced vampire gameplay experience.
