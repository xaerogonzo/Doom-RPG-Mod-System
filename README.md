# Doom RPG Mod System

A collection of GZDoom/UZDoom gameplay mods, merged and extended into a unified package by Alex C (Bitterman).

**Engine:** UZDoom 4.14.3 (GZDoom-compatible)

---

## Packages

### 🌿 Super Merged *(main mod)*
> `Super_merged_91B_src/` → packed as `Super_merged_91B.pk3`

The core package. Merges five independent mods into one seamless system, all independently toggleable:

| Component | What it does |
|---|---|
| **Gun Bonsai** | Weapon XP and upgrade system — kill enemies, level your weapons, pick from a pool of upgrades each level. Elemental DoTs, lifesteal, ricochet, homing, and more. |
| **Hyper-V** | Movement and combat overhaul — dash, double jump, ledge grab, grappling hook, teleporter, auto-melee, parry, bullet time, player/world stat overrides, permanent powerups, and regeneration. |
| **Indestructible** | Extra lives — cheat death with a burst of invincibility and 50 HP. Lives earned from boss kills, map completion, or as a Gun Bonsai player upgrade. |
| **Doom Points** | Score tracking — points for kills, chains, secrets, pickups, and map completion. Optionally feeds score back into Gun Bonsai weapon XP. |
| **Companions** | Friendly monster allies — spawn at map start, follow you, attack enemies, teleport back if left behind, and can be resurrected. |

All settings live under **Options → Full Options Menu → Gun Bonsai Suite** with in-game tooltips on every slider.

---

### 🏆 Vortex Universal Achievement System *(optional)*
> `Vortex_Universal_Achievement_System-patched15D/` → packed as `Vortex_Universal_Achievement_System-patched.zip`

The VUAS achievement engine by Vortex, patched for UZDoom 4.14.3 compatibility:
- Removed `WorldPreSave` override (not available in UZDoom 4.14.3)
- Replaced with per-slot `SyncTrackerAt` sync so mid-map saves preserve achievement progress correctly

Load this **before** Super Merged.

---

### 🔗 Supermerged VUAS Bridge *(optional, requires VUAS)*
> `Supermerged_VUAS_Bridge-14/` → packed as `Supermerged_VUAS_Bridge.pk3`

Wires 25 achievements into VUAS, covering every major system in Super Merged:

<details>
<summary>Achievement list (click to expand)</summary>

**Leveling:** Baptism of Fire, Sharpshooter, Master Armourer, Growing Pains, Seasoned Veteran, Legendary

**Upgrades:** Enhancement Protocol, Perfection, Grand Synthesis, Elemental Master, Overdrive, Arsenal *(hidden)*

**Combat:** Century, Exterminatus, Billiards, On a Roll, Unstoppable, Untouchable *(hidden)*

**Companions:** Faithful Companion, Back from the Dead

**Survival:** Deathless, Safety Net, Baptism by Fire *(hidden)*

**Exploration:** Secret Finder, No Stone Unturned

</details>

Load this **after** Super Merged.

---

### ⌨️ Typist *(optional)*
> `Typist(Bitterman Modification)/` → packed as `Typist.pk3`

A modified fork of the Typist mod — typing-based combat where enemies are defeated by typing their name. This build is adjusted to work alongside Super Merged's scoring system.

---

### 🔗 Typist Bridge *(optional, requires Typist)*
> `typist_supermerge_bridge/` → packed as `typist_supermerge_bridge.pk3`

Gates Doom Points scoring to Typist's Combat mode when both are loaded — prevents score from accumulating outside of active typing sequences.

Load this **after** both Super Merged and Typist.

---

### 📦 libtooltipmenu *(required)*
> `libtooltipmenu-6/` → packed as `libtooltipmenu.pk3`

Third-party tooltip library by its author. Provides the tooltip widget used throughout the options menus. Must load **first**.

---

## How the Packages Connect

```
libtooltipmenu.pk3          ← tooltip system, must be first
       │
       ▼
VUAS.zip                    ← achievement engine (optional)
       │
       ▼
Super_merged.pk3            ← core mod (Gun Bonsai + Hyper-V + Indestructible
       │                         + Doom Points + Companions)
       ├──▶ Supermerged_VUAS_Bridge.pk3   ← wires achievements into VUAS
       │
Typist.pk3                  ← optional typing combat mod
       │
       └──▶ typist_supermerge_bridge.pk3  ← gates Doom Points to Combat mode
```

**Minimum load order:**
```
libtooltipmenu.pk3
Super_merged.pk3
```

**Full load order (all optional packages):**
```
libtooltipmenu.pk3
Vortex_Universal_Achievement_System-patched.zip
Super_merged.pk3
Supermerged_VUAS_Bridge.pk3
Typist.pk3
typist_supermerge_bridge.pk3
```

---

## Controls

| Key | Action |
|---|---|
| `I` | Gun Bonsai info / upgrade menu |
| `O` | Score board |
| `P` | Cycle Legendoom weapon effect *(requires Legendoom)* |
| Dash Modifier + movement | Dash in any of 8 directions |
| Throw Hook | Launch grappling hook |
| Toggle Slomo | Activate bullet time |
| Teleport Move | Fire / confirm teleport marker |

All Hyper-V bindings are rebindable under **Options → Customize Controls → Other Keybindings [Hyper-V]**.

---

## Documentation

| File | Contents |
|---|---|
| `Super_merged_91B_src/README.md` | Full in-depth guide to every system, CVar reference, options table, compatibility notes |
| `Super_merged_91B_src/UPGRADES.md` | Complete upgrade tree reference |
| `Super_merged_91B_src/MODDING.md` | Guide for adding Gun Bonsai upgrades |
| `CHANGELOG.md` | Change history for this repository's custom work |

---

## Credits

**Gun Bonsai / Indestructible** — Rebecca "ToxicFrog" Kelly  
**Doom Points** — mmaulwurff  
**Hyper-V** — Ermac (iAmErmac), with contributions from Apeirogon, dodopod, Agent_Ash, Spaceman333, Alexander Kromm, and others  
**VUAS** — Vortex  
**Unified merge, Hyper-V integration, Blood element, VUAS patch, balance tuning, profile system** — Alex C (Bitterman)
