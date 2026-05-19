# Super Merged — Basic Instructions

---

## Project Overview

**Name:** Super Merged (Doom RPG MOD)
**Stack:** ZScript (primary), ACS, GZDoom/UZDoom mod format (pk3 archives)
**Entry point:** `Super_merged_91B_src/zscript.zs` — includes all subfiles via `#include`
**Purpose:** A UZDoom/GZDoom gameplay mod that merges five independent mods into one package, with optional VUAS achievement integration and Typist mod bridge. Developed and extended by Alex C (Bitterman).

**Engine:** UZDoom 4.14.3 (GZDoom fork). ZScript virtual overrides must exist in this version — check before using newer API additions.

---

## Project Structure

```
Doom RPG MOD/
├── Super_merged_91B_src/          Main mod source — packed as Super_merged_91B.pk3
│   ├── zscript.zs                 Entry point (#includes everything)
│   ├── CVARINFO.txt               All console variables (large unified file)
│   ├── BONSAIRC.txt               Gun Bonsai upgrade registry (all class names go here)
│   ├── MENUDEF.txt                Menu definitions
│   ├── LANGUAGE_en-*.txt          Localisation strings (upgrades, HUD, options, messages)
│   ├── UPGRADES.md                Player-facing upgrade reference
│   ├── MODDING.md                 Modding guide for Gun Bonsai upgrades
│   ├── zscript/bonsai/            Gun Bonsai upgrade system (ToxicFrog base, extended)
│   │   ├── upgrades/              Individual upgrade classes (one file per element/upgrade)
│   │   └── menu/                  Upgrade selection UI
│   ├── zscript/hyperv/            Hyper-V gameplay systems (iAmErmac base, extended)
│   │   ├── HyperV_GunBonsai.zsc   9 Hyper-V upgrade bridges (gate CVars behind XP levels)
│   │   └── unified_hud.txt        Per-frame HUD renderer (slomo, regen, dash bars)
│   ├── zscript/companions/        Friendly monster companion system
│   ├── zscript/scoring/           Doom Points score tracking / kill streaks
│   └── zscript/indestructible/    Extra lives system (ToxicFrog)
│
├── Vortex_Universal_Achievement_System-patched15D/   VUAS — patched for UZDoom 4.14.3
│   └── ZSCRIPT/Achievements/
│       ├── AchievementHandler.zs  Main VUAS StaticEventHandler (god class — 53 members)
│       └── AchievementSetup.zs    Achievement definitions + WorldLoaded init
│
├── Supermerged_VUAS_Bridge-14/    Bridge pk3: VUAS ↔ Super Merged
│   └── zscript/SupermergedAchievements.zs   25 achievement definitions for VUAS
│
├── typist_supermerge_bridge/      Bridge pk3: Typist ↔ Super Merged
│
├── Typist(Bitterman Modification)/ Typist mod — typing-based gameplay (modified fork)
│   ├── zscript/                   Typist ZScript (tt_PlayerSupervisor, etc.)
│   └── cvarinfo.txt / keyconf.txt / language.txt / menudef.txt
│
├── libtooltipmenu-6/              Tooltip library (third-party, load first)
│   ├── README.md                  API reference
│   └── MODDING.md                 Integration guide
│
├── CLAUDE.md                      Claude Code instructions (loads baseline + this file)
├── BASIC_INSTRUCTIONS.md          This file — full project reference
└── CHANGELOG.md                   Change history
```

---

## Load Order

```
libtooltipmenu.pk3
Vortex_Universal_Achievement_System-patched.zip   (optional)
Super_merged.pk3
Supermerged_VUAS_Bridge.pk3                       (optional, requires VUAS)
typist_supermerge_bridge.pk3                      (optional, requires Typist)
Typist.pk3                                        (optional)
```

VUAS must load before Super Merged. Both bridge pk3s must load after their respective dependencies.

---

## Documentation Files

| File | Purpose |
|---|---|
| `Super_merged_91B_src/README.md` | User-facing description, setup, load order, controls |
| `Super_merged_91B_src/UPGRADES.md` | Full upgrade reference — all upgrade trees |
| `Super_merged_91B_src/MODDING.md` | Modding guide for adding Gun Bonsai upgrades |
| `Vortex_Universal_Achievement_System-patched15D/README.md` | VUAS readme |
| `libtooltipmenu-6/README.md` | Tooltip library API |
| `libtooltipmenu-6/MODDING.md` | Tooltip integration guide |
| `CHANGELOG.md` | Change history for this project's custom work |

---

## Architecture

### Event Handler Chain

GZDoom routes game events through registered `StaticEventHandler` and `EventHandler` subclasses. Key handlers:

- **`TFLV_EventHandler`** (`EventHandler.zsc`) — Gun Bonsai core; 53 members (god class by necessity). Dispatches `WorldThingDied`, `WorldThingDamaged`, `WorldTick` to weapon upgrade instances. Holds per-player `TFLV_WeaponInfo` cache.
- **`TFLV_HyperV_IntegrationHandler`** (`HyperV_GunBonsai.zsc`) — reads Gun Bonsai upgrade levels, writes Hyper-V CVars. Called from `EnforceForPlayer` / `OnActivate` / `OnDeactivate` per weapon switch.
- **`UnifiedHudHandler`** (`unified_hud.txt`) — `RenderOverlay` per-frame; draws slomo, regen, and dash bars. Slomo bar shows points remaining; a "CD" pip appears above it during cooldown.
- **`VUAS_AchievementHandler`** (`AchievementHandler.zs`) — tracks and unlocks achievements; uses `SyncTrackerAt` to keep `VUAS_PersistentTracker` current on every progress change (mid-map save safe).
- **`VUAS_PersistentTracker`** (`EventHandler` not `StaticEventHandler`) — serializes achievement state with the save file.

### Upgrade System

```
TFLV_Upgrade_BaseUpgrade
  └── TFLV_Upgrade_ElementalUpgrade   (element identity, IsSuitableForWeapon)
        ├── TFLV_Upgrade_SanguineShots  (Blood — opener/lifesteal)
        ├── TFLV_Upgrade_IncendiaryShots (Fire)
        ├── TFLV_Upgrade_ShockingInscription (Lightning)
        └── TFLV_Upgrade_DotModifier    (modifies an existing DoT on the target)
              ├── TFLV_Upgrade_VitalDrain (Blood journeyman)
              └── ...

TFLV_Upgrade_Dot : Inventory   (given to the enemy actor as an inventory item)
  └── TFLV_Upgrade_BloodDot    (current-HP% drain + lifesteal + armor trickle)
  └── TFLV_Upgrade_AcidDot     (threshold-based finisher)
  └── TFLV_Upgrade_PoisonDot   etc.
```

DoT items live on the enemy. `TickDot()` fires every game tic via `States { Dot: TNT1 A 0 TickDot(); ... LOOP; }`. `self.target` on the DoT item is the **player** who applied it — use this for lifesteal back to the shooter.

### Hyper-V CVar Pattern

All Hyper-V upgrade tuning uses a uniform `base + (level - 1) * per_level` formula. CVar naming:

```
bonsai_hyperv_<system>_<stat>_base      -- value at level 1
bonsai_hyperv_<system>_<stat>_per_level -- added per level above 1
bonsai_hyperv_<system>_<stat>_min       -- floor (for decaying stats like cooldown)
```

Never add `_lv1` / `_lv2` / `_lv3` CVars — always use the base+per_level pattern.

---

## Key Files

| File | Role |
|---|---|
| `Super_merged_91B_src/zscript.zs` | ZScript entry point — all `#include` directives |
| `Super_merged_91B_src/CVARINFO.txt` | All CVars — Hyper-V tuning, Blood/elemental stats, HUD options |
| `Super_merged_91B_src/BONSAIRC.txt` | Upgrade class registry — every new upgrade class goes here |
| `Super_merged_91B_src/LANGUAGE_en-upgrades.txt` | Upgrade display names and tooltip strings |
| `Super_merged_91B_src/LANGUAGE_en-hyperv.txt` | Hyper-V option/tooltip strings |
| `Super_merged_91B_src/zscript/bonsai/upgrades/ElementalUpgrade.zsc` | `UpgradeElement` enum, `ElementalUpgrade` and `DotModifier` base classes |
| `Super_merged_91B_src/zscript/bonsai/upgrades/Blood.zsc` | Blood element: `SanguineShots`, `VitalDrain`, `Exsanguinate`, `BloodDot` |
| `Super_merged_91B_src/zscript/bonsai/upgrades/Overdrive.zsc` | Kill-streak charge upgrade; `GetMaxStacks()` uses `min(1 + level*2, max_stacks)` |
| `Super_merged_91B_src/zscript/hyperv/HyperV_GunBonsai.zsc` | 9 Hyper-V upgrade bridge classes; all use base+per_level formula |
| `Super_merged_91B_src/zscript/hyperv/unified_hud.txt` | HUD renderer; slomo bar with CD pip overlay |
| `Vortex_Universal_Achievement_System-patched15D/ZSCRIPT/Achievements/AchievementHandler.zs` | VUAS main handler — patched: `WorldPreSave` removed, `SyncTrackerAt` used instead |
| `Vortex_Universal_Achievement_System-patched15D/ZSCRIPT/Achievements/AchievementSetup.zs` | Achievement definitions + `WorldLoaded` init (calls `SaveToTracker` on first load) |
| `Supermerged_VUAS_Bridge-14/zscript/SupermergedAchievements.zs` | 25 achievement definitions (kill streaks, upgrade milestones, companions, etc.) |

---

## Project-Specific Rules

### ZScript / UZDoom Constraints

- **Target engine is UZDoom 4.14.3.** Before using a virtual override, confirm it exists in this version. `WorldPreSave` does not — it was removed from `StaticEventHandler`. Check GZDoom/UZDoom changelogs when in doubt.
- **Null checks are mandatory** on `target`, `master`, `tracer`, `owner`, and all `Let` casts. Play-scope actors can be destroyed at any time.
- **`self.target` on a DoT item is the shooter** (the player), not the enemy. `self.owner` is the enemy carrying the item.

### Adding a New Upgrade

1. Create `Super_merged_91B_src/zscript/bonsai/upgrades/MyUpgrade.zsc`
2. Add the class name to `BONSAIRC.txt`
3. Add display name + tooltip strings to the appropriate `LANGUAGE_en-*.txt`
4. Add tuning CVars to `CVARINFO.txt` (use `_base` + `_per_level` pattern for leveled stats)
5. If it's an elemental upgrade, add its `ELEM_` entry to the enum in `ElementalUpgrade.zsc`
6. Create the NTFS shadow hardlink: `New-Item -ItemType HardLink -Path "MyUpgrade.zsc.cpp" -Target "MyUpgrade.zsc"`, then run `tokensave sync`

### Shadow Extension Hardlinks

ZScript and ACS files have NTFS hardlinks with `.cpp`/`.c` suffixes so tokensave can index them. See `CLAUDE.md` for the full rule. Never edit the `.zsc.cpp` / `.zs.cpp` / `.acs.c` files — always edit the base source.

### Packing / Distribution

The working directory contains unpacked source folders. Each folder is packed into a `.pk3` (zip) for distribution. Edit the source files directly; repack when ready to test in-engine.
