# Super Merged

**Super Merged** combines five mods into one seamless package:

- **Gun Bonsai** — Weapon and player upgrade system. Fight enemies, earn XP, grow your weapons into murder trees.
- **Indestructible** — Extra lives system. Cheat death with a burst of invincibility, then get back in the fight.
- **Doom Points** — Score tracking. Points for kills, secrets, items, and combos — optionally feeding back into Gun Bonsai XP.
- **Companions** — Friendly monster system. Spawn allies that fight at your side, follow you, and can be resurrected.
- **Hyper-V** — Movement and gameplay systems. Dash, double-jump, ledge grab, grappling hook, teleporter, auto-melee, parry, bullet time, and full player/world rule overrides.

All five systems are fully optional and independently toggleable. Mix and match however you like.

**Optional: VUAS integration.** Super Merged has built-in support for Vortex's Universal Achievement System (VUAS). Load the VUAS bridge alongside Super Merged to unlock 25 achievements tied to leveling, upgrades, kill streaks, companions, and more. See the VUAS Integration section below for details.


---

## Setup

### Required Dependencies

**libtooltipmenu** — provides the tooltip system used throughout the options menus. Load it first.

### Load Order

```
libtooltipmenu.pk3
Super_merged.pk3
```

With optional VUAS integration:

```
libtooltipmenu.pk3
Vortex_Universal_Achievement_System-patched.zip
Super_merged.pk3
Supermerged_VUAS_Bridge.pk3
```

VUAS must come before Super Merged. The bridge must come last.

### Controls

Key bindings added:

- **`I`** — Show Gun Bonsai info / open upgrade menu on level-up
- **`O`** — Open Score menu (top scores for current map)
- **`P`** — Cycle Legendoom weapon effect (only relevant when Legendoom is installed)

**Hyper-V bindings** (all rebindable under Options → Customize Controls → Other Keybindings [Hyper-V]):

- **Dash / Roll Modifier** — Hold, then press a movement key to dash in that direction
- **Teleport Move** — Fire / confirm the teleport marker
- **Cancel Teleport Marker** — Clear the active marker
- **Throw Hook** — Launch the grappling hook
- **Melee Attack Key** — Trigger auto-melee manually (key-press mode)
- **Toggle Melee On/Off** — Enable or disable the auto-melee system
- **Toggle Slomo** — Activate / deactivate bullet time
- **Toggle Melee Indicator** — Show or hide the melee range indicator

The unified options page is at **Options → Full Options Menu → Gun Bonsai Suite**. All settings have in-game tooltips.


---

## Gun Bonsai

### How it works

As you damage enemies, your current weapon earns XP. The amount depends on the damage dealt and how dangerous the target is. Once the weapon has enough XP to level up, the HUD starts glowing — press `I` to open the upgrade menu and choose one of the offered upgrades (four by default).

Every time your weapons collectively earn enough levels, you also earn a **player upgrade** — a powerful bonus that applies regardless of which weapon you're holding.

### The HUD

A small overlay shows your weapon's current XP progress and player level. When the frame starts glowing, you have a level-up waiting.

**Colour coding:**
- Default weapon colour — XP coming from direct damage
- **Cyan** — XP is coming from score (Doom Points integration active)
- **Rainbow shimmer** — level-up is ready

### XP Sources

Two independent XP sources can be mixed freely:

- **Damage-to-XP** (`bonsai_damage_to_xp_factor`, default 1.0) — direct XP for each point of damage you deal.
- **Score-to-XP** (`bonsai_score_to_xp_factor`, default 0.0) — XP for every point scored via Doom Points. With real-time scoring on, DoT effects earn score as they tick, which then flows into weapon XP.

### XP Cost Scaling

The `bonsai_xp_curve` setting controls how fast levelling costs grow:

- **Custom Power** — `base_cost × level^x` where x is user-configurable (0.0=flat, 1.0=linear, 2.0=quadratic, 3.0=cubic).
- **Custom Exponential** — `base_cost × base^(level-1)` where base is user-configurable.
- **Hybrid** — Blends two independent components with a smooth biased transition over a configurable level range.

A **live graph** in the XP Pacing & Leveling submenu shows the current curve shape in real time.

### Upgrade Pool and Rarity

Every upgrade has an individual **rarity tier** set in Options → Gun Bonsai Options → Upgrade Pool / Rarity:

| Tier | Default Weight | Relative Likelihood |
|---|---|---|
| Disabled | 0 | Never appears |
| Very Rare | 1 | ~10× less likely than Common |
| Rare | 3 | ~3× less likely than Common |
| Uncommon | 6 | ~1.7× less likely than Common |
| Common | 10 | Baseline |
| Favored | 20 | ~2× more likely than Common |

### Balance & Upgrade Profiles

Six saveable profile slots each capture all balance tuning, XP pacing, rarity tiers, and Indestructible/Companions integration settings in one string.

| Slot | Starting Point |
|---|---|
| Default | Vanilla Gun Bonsai values |
| Balanced | Toned-down weapon damage, elemental mults at 75% |
| Challenging | Weaker upgrades for serious monster packs |
| Punishing | Minimal upgrade power for hardcore play |
| Custom | Vanilla values — blank slate |
| Brutal Mode | Vanilla upgrade power, adjusted XP pacing for overhaul mods |

Save, Apply, and Reset all require an active game session.

**Exporting profiles:** Open the Profiles menu and click **Export All Saved Profiles to Console** to print each saved slot as a ready-to-paste console command. Import by pasting `bonsai_profile_N "their-string-here"` into the console and clicking Apply.

### Weapon Types and Wimpy Weapons

Gun Bonsai infers weapon type (hitscan, projectile, melee) by watching what you fire. **Wimpy weapons** (no ammo type by default) get reduced XP cost and access to Dark Harvest and Swiftness. Override inference via BONSAIRC or the Manual Level Setting menu.

### Legendoom Integration

If Legendoom is installed, every N weapon levels (default 3), a qualifying weapon earns a random Legendoom effect. Press `P` to cycle learned effects.


---

## Indestructible

When you would otherwise die, a life is consumed: 50 HP restored, brief invincibility, time slowdown, and a damage bonus.

### Standalone Mode

Lives earned through configurable combinations of level completion, boss kills, and cumulative damage absorbed.

### Gun Bonsai Integration Mode

Enable in Indestructible Options. The **Indestructible** upgrade appears in the player pool. Each level increases max life count. Integration tuning sliders are available in both Indestructible Options and Balance Tuning → Indestructible Integration, and are saved to your active balance profile.


---

## Doom Points

Points awarded for:

| Action | Default Points |
|---|---|
| Damage dealt | Equal to damage amount (real-time mode) |
| Kill (kill-only mode) | 10% of enemy spawn health |
| Chain kill (within 3s) | Timer bonus up to +500, stacks per kill |
| Secret found | 250 |
| Item picked up | 5 |
| Key picked up | 250 |
| Powerup picked up | 100 |
| Health/armour bonus pickup | 1 each |
| 100% kills bonus | 1000 |
| 100% secrets bonus | 1000 |
| 100% items bonus | 500 |

Player health acts as a score multiplier: 50%+ health gives 1.5×, 100%+ gives 2×.

### Integration with Gun Bonsai

Set `bonsai_score_to_xp_factor` above 0. Every point scored flows into XP for your current weapon. The HUD bar turns cyan as confirmation.


---

## Companions

Friendly monsters spawn at map start and fight at your side. They follow you, attack enemies, teleport back if they fall behind, and can be resurrected.

### Monster Roster

| Setting | Pool |
|---|---|
| Ultimate Doom | Doom 1 monsters |
| Doom 2 | All Doom 2 monsters including Arch-Vile |
| Heretic | Gargoyles, Golems, Undead Warriors, Weredragons, Ophidians, Disciples, Iron Lich, Maulotaur, D'Sparil |
| Hexen | Ettins, Centaurs, Afrits, Wendigos, Wraiths, Dark Bishop, Heresiarch |
| Chex Quest 3 | All Flemoid variants; requires `chex.wad` as IWAD |
| Strife | Configurable mix of Order enemies and/or Rebels |

### Gun Bonsai Integration Mode

Enable in Companions Options. The **Companions** upgrade appears in the player pool. Each level increases ally count. Boss and dangerous-tier companions unlock at configurable level thresholds.

### Resurrection

Stand near a dead companion's corpse. A blue particle pulse shows the corpse is revivable. Moving close enough starts active progress (red particles). Stepping away stalls it. High-HP companions take longer.


---

## Hyper-V

Movement, melee, and gameplay customization. All systems are independently toggleable in **Options → Gun Bonsai Suite → Hyper-V Options** or via the master `hyperv_enabled` switch.

### Dash / Roll

Hold the Dash Modifier key and press a movement direction to dash. Supports **8 directions** including diagonals. A **Distance Preset** (Cautious / Balanced / Aggressive / Blink) sets all distances at once, or use Custom sliders. **Double Dash** chains a second dash. Each dash can optionally cost stamina.

### Auto-Melee

Automatic close-range melee attack. Configurable damage presets, range, multiplier, and knockback. **Combo & Crits** system: crits multiply damage, apply knockback, and can stun enemies. Berserk pack buffs all melee stats. **Weapon Slot 1 Mode** adds crit bonuses on top of slot-1 weapons without replacing their fire logic.

### Parry

Proactively detects enemy attacks in melee range and reduces incoming damage before it lands. On success, stuns the attacker. Passive or key-press activation. Configurable damage shield, attacker stun, parry probability, and crit resistance.

### Teleporter

Lob a marker beam that arcs with gravity. Tap to fire, tap again to teleport, use the cancel key to clear. Beam bounces off walls and ceilings. Configurable beam speed, max range, and cooldown.

### Grappling Hook

Throw a hook to pull yourself to a surface, or drag enemies toward you. Hooked enemies are **frozen while dragged** and briefly stunned after release. Configurable pull toggle, range, cooldown, and stun duration.

### Double Jump & Ledge Grab

Optional double jump and automatic ledge climbing. Both off by default. Configurable per-jump independently.

### Slomo Bullet Time

Slows enemies and projectiles while the player moves freely. Point pool, cooldown, depth, and drain all configurable. Berserk and Invulnerability sphere grant bonuses.

### Player Rules

Per-player stat overrides: weapon damage multiplier, taken damage multiplier, self-damage multiplier, speed, jump height, friction, max health, start health, and start armor on level entry.

### World Rules

Enemy and friendly monster health and speed multipliers applied on spawn. Health cap prevents multipliers from creating unkillable enemies.

### Permanent Powerups

Keeps any of 24 GZDoom powerups active indefinitely by topping them up each second. Includes Buddha, Flight, Infinite Ammo, Invulnerability, Strength, and more.

### Regeneration

- **Health regen** — periodic HP restore or drain. Configurable amount, interval, min/max range, and screen flash.
- **Armor regen** — same system for armor.
- **Ammo regen** — periodically tops up all carried ammo types within their caps.

### Ability HUD

Stacked bars showing Stamina, Slomo points, Dash cooldown, and Hook cooldown. Each bar individually toggleable. Position, size, and color all configurable. Parry and teleport state shown as center-screen indicators.

### Hyper-V CVars Quick Reference

All Hyper-V CVars use the `vmm_` prefix (movement/abilities) or `sm_` prefix (slomo). Key ones:

| CVar | Default | Purpose |
|---|---|---|
| `hyperv_enabled` | true | Master switch — disables all Hyper-V systems |
| `vmm_dash` | true | Enable dash |
| `vmm_dash_preset` | 2 | Distance preset (0=Custom, 1=Cautious, 2=Balanced, 3=Aggressive, 4=Blink) |
| `vmm_dash_cooldown` | 1.0 | Dash cooldown in seconds |
| `vmm_double_dash` | false | Enable double dash |
| `vmm_double_jump` | false | Enable double jump |
| `vmm_ledge_climb` | false | Enable ledge grab |
| `vmm_melee` | true | Enable auto-melee |
| `vmm_melee_parry` | true | Enable parry |
| `vmm_hook` | true | Enable grappling hook |
| `vmm_teleport` | true | Enable teleporter |
| `sm_enabled` | true | Enable slomo bullet time |
| `sm_totalslomopoints` | 200 | Slomo point pool |
| `sm_slowdown_depth` | 100 | Slowdown depth % |
| `vmm_health_regen` | false | Enable health regeneration |
| `vmm_armor_regen` | false | Enable armor regeneration |
| `vmm_ammo_regen` | false | Enable ammo regeneration |
| `vmm_damage_mult` | 1.0 | Weapon damage multiplier |
| `vmm_speed_mult` | 1.0 | Movement speed multiplier |
| `vmm_jump_mult` | 1.0 | Jump height multiplier |
| `vmm_enemy_health_mult` | 1.0 | Enemy spawn health multiplier |
| `vmm_enemy_speed_mult` | 1.0 | Enemy spawn speed multiplier |

Full CVar reference is available in the Hyper-V submenus and in MODDING.md.

### Reset Commands

| Alias | Resets |
|---|---|
| `vmm_reset_dash` | All dash settings |
| `vmm_reset_parry` | All parry settings |
| `vmm_reset_hook` | All hook settings |
| `vmm_reset_teleport` | All teleporter settings |
| `vmm_reset_hud` | All HUD settings |
| `vmm_reset_player_rules` | All player rule multipliers |
| `vmm_reset_world_rules` | All world rule multipliers |
| `vmm_reset_powerups` | Disables all permanent powerups |
| `vmm_reset_health_regen` | Health regen settings |
| `vmm_reset_armor_regen` | Armor regen settings |
| `vmm_reset_ammo_regen` | Ammo regen settings |
| `vmm_reset_all` | Everything above |


---

## VUAS Integration

Super Merged includes built-in support for [Vortex's Universal Achievement System (VUAS)](https://github.com/vortexdesign). Load the patched VUAS zip and the Supermerged VUAS Bridge to unlock achievements tied to every major system.

### Load Order

```
libtooltipmenu.pk3
Vortex_Universal_Achievement_System-patched.zip
Super_merged.pk3
Supermerged_VUAS_Bridge.pk3
```

### Achievement List

**Leveling**
- *Baptism of Fire* — Level up any weapon for the first time
- *Sharpshooter* — Reach weapon level 5
- *Master Armourer* — Reach weapon level 10
- *Growing Pains* — Earn your first player level
- *Seasoned Veteran* — Reach player level 5
- *Legendary* — Reach player level 10

**Upgrades**
- *Enhancement Protocol* — Select your first weapon upgrade
- *Perfection* — Reach level 3 on any single upgrade
- *Grand Synthesis* — Unlock any elemental synthesis upgrade
- *Elemental Master* — Have all four elemental types active on a single weapon
- *Overdrive* — Reach maximum Overdrive charge stacks on a weapon
- *Arsenal* *(hidden)* — Have 5 or more different upgrades on a single weapon

**Combat**
- *Century* — Kill 100 enemies
- *Exterminatus* — Kill 1000 enemies
- *Billiards* — Land a Ricochet shot that bounces to 3 or more enemies
- *On a Roll* — Kill 5 enemies in quick succession
- *Unstoppable* — Kill 10 enemies in quick succession
- *Untouchable* *(hidden)* — Kill 25 enemies in quick succession

**Companions**
- *Faithful Companion* — Complete a map with your companion still alive
- *Back from the Dead* — Watch your companion resurrect

**Survival**
- *Deathless* — Complete a map without dying
- *Safety Net* — Spend an Indestructible extra life
- *Baptism by Fire* *(hidden)* — Lose XP from dying and earn it back to the same weapon level

**Exploration**
- *Secret Finder* — Find your first secret area
- *No Stone Unturned* — Complete a map with 100% kills, items, and secrets

Kill streak achievements are driven by Doom Points' streak system — thresholds are configurable in Doom Points Options → Kill Scoring → Streak Kill Count Milestones.


---

## Mod Compatibility

Gun Bonsai Unified uses only event handlers and inventory items — no actor replacements. Compatible with almost any IWAD and weapon/monster mod.

**Hyper-V** is a universal mod designed to work alongside anything. It uses `V_Moves : CustomInventory` given to the player at spawn, and four event handlers that hook into standard GZDoom interfaces. No actor replacements.

**Typist:** Full compatibility via the standalone `typist_bridge.pk3`. Load order: `SuperMerged → Typist → typist_bridge.pk3`. Doom Points scoring is automatically gated to Typist's Combat mode when the bridge is loaded.

**Brutal Pack:** Fully compatible. Requires VUAS patched15+ (included) for achievement tracking — earlier versions had a skill-filter bug triggered by BP's custom ACSReturn value.

**Hideous Destructor:** Set `treat weapons that don't use ammo as wimpy` to off. Use score-to-XP instead of damage-to-XP.

**Pandemonia:** Turn `Use Builtin Actors` off.

**DoomRL Arsenal:** Building an assembly resets weapon upgrades (treated as a new weapon).

**Corruption Cards:** Thorns Totem + Thorns upgrade can crash the game.

**Companions + Monster Mods:** Companions uses vanilla Doom monster class names. In monster replacement mods (Colourful Hell, Champions, etc.), `ALLOW_REPLACE` is used so replacements spawn as companions too.


---

## Known Issues

- XP is assigned to the weapon wielded at the moment damage is dealt. Projectile-in-flight weapon switches can misattribute XP.
- Weapon type inference may be wrong for some modded weapons. Use BONSAIRC overrides or the wimpy toggle to correct this.
- HE Rounds will not detonate against walls.
- Piercing Shots may interfere with exploding projectile detonation.
- Some scripted/instant damage sources (crushers, telefrags) bypass Indestructible.
- Balance profiles (Save/Apply/Reset) require an active game session.
- Legendoom integration menu is always present but has no effect without Legendoom loaded.
- XP death penalty (`bonsai_death_xp_penalty`) applies a proportional reduction to within-level progress. Weapons cannot lose an earned level.
- Level-up rejection (Reject mode) deducts exactly the per-level XP cost. Surplus XP is preserved. Negative XP can result if surplus is zero.
- Strife Reaver and Crusader companions explode on death, which can damage the player. Excluded from the default Strife roster.
- Parry system balance is still being tuned — default values may feel inconsistent against some enemy types.
- Hyper-V dash cooldown defaults to a very short value. If dash feels too powerful or trivial, raise `vmm_dash_cooldown` or switch to a more restrictive distance preset.


---

## Options Reference

| Section | What's there |
|---|---|
| **Gun Bonsai** | |
| UI Settings | HUD position, size, opacity, colours, mirror mode, level-up flash and sound |
| Compatibility Settings | Autosave, weapon binding, builtin actors, ammoless=wimpy, level-up rejection mode |
| XP Sources | Damage-to-XP factor, score-to-XP factor |
| XP Pacing & Leveling | Base cost, XP curve, upgrade choices, gun/player level ratio, melee/wimpy multipliers, live graph |
| Alternate Leveling Modes | Respec interval, forced upgrades |
| Progression Controls | Freeze progression, keep upgrades on death, keep on death exit |
| Upgrade Pool / Rarity | Per-upgrade rarity tier, elemental master switches, tier weight sliders, reset all to Common |
| Balance & Upgrade Profiles | Six saveable profile slots |
| Balance Tuning | Upgrade power sliders |
| LegenDoom Integration | LD effect frequency, rarity caps, effect slots |
| **Indestructible** | |
| Indestructible Options | Standalone vs Gun Bonsai mode, life sources, trigger effect config |
| **Doom Points** | |
| Doom Points | Enable/disable, HUD config, kill/pickup/secret/completion scoring |
| **Companions** | |
| Companions Options | Mode toggle, ally count, monster roster, boss/dangerous-tier thresholds, behavior settings |
| **Hyper-V** | |
| Movement & Mobility | Dash (direction, distance, cooldown, stamina), double jump, ledge grab |
| Melee Combat | Auto-melee enable, range, damage preset, combo/crit system, berserk integration, slot-1 mode |
| Stamina | Stamina pool size and drain rates |
| Teleporter | Enable, beam speed, range, cooldown, restriction toggle |
| Grappling & Meat Hook | Enable, pull mode, range, cooldown, stun duration |
| Slomo Bullet Time | Enable, point pool, depth, drain, recharge, berserk/invuln bonuses |
| Player Rules | Damage/taken damage/self-damage/speed/jump/friction multipliers, max health, start health/armor |
| World Rules | Enemy/friendly health and speed multipliers, health caps |
| Permanent Powerups | 24 permanent powerup toggles |
| Health/Armor/Ammo Regen | Regen enable, amount, interval, min/max, sound, screen flash |
| Ability HUD | Bar enable, position, size, color, parry/teleport indicators |
| Reset | Per-system and global reset aliases |


---

## Credits

**Gun Bonsai** by Rebecca "ToxicFrog" Kelly.
**Indestructible** by ToxicFrog.
**Doom Points / Lazy Points** originally by mmaulwurff.
**Universal Friend Enhancer** originally by its author; Companions system based on this work.
**Hyper-V** by Ermac (iAmErmac). Incorporates:
- Dash script by Apeirogon
- Ledge grab script by dodopod
- Grappling / Meat-Hook by Agent_Ash (Jekyll Grim Payne)
- Double jump, teleport, VR melee by Ermac
- Slomo Bullet Time original ACS by Spaceman333
- Enemy/friend scaling, powerup system, regen inspired by Final Custom Doom by Alexander Kromm
- CVar loader ZScript by Alexander Kromm (m8f / mmaulwurff)
- Parry system, teleporter redesign, crit/combo overhaul, diagonal dash, hook stun, game rules by Ermac
- Grapple 3D model from Sketchfab, edited by Ermac
**Unified merge, balance tuning, profile system, Companions integration, VUAS integration, and Hyper-V merge** by Alex C (Bitterman).

Graphics and sounds from FreeDoom, Beautiful Doom, ZMovement, and various itch.io asset packs. See CREDITS.txt for per-asset details.
