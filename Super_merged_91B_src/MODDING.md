# Super Merged — Modding Documentation

This document covers everything relevant to modders working with Super Merged: BONSAIRC compatibility tweaks, writing new Gun Bonsai upgrades, service APIs, netevents, XP curve internals, Doom Points extension points, Hyper-V public API, and the internal architecture of all five systems.

---

## Quick Reference: What Each System Exposes

| System | Service Name | Key Netevents | Public CVars |
|---|---|---|---|
| Gun Bonsai | `TFLV_GunBonsaiService` | `bonsai-level-up`, `bonsai-choose-level-up-option` | `bonsai_enabled` |
| Indestructible | `TFIS_IndestructibleService` | `indestructible-report-lives` | `indestructible_enabled` |
| Doom Points | *(no service; use CVars)* | *(none emitted externally)* | `dp_enabled` |
| Companions | *(no service; use CVars)* | *(none emitted externally)* | `companions_enabled` |
| Hyper-V | *(no service; use CVars/netevents)* | See Hyper-V Public API below | `hyperv_enabled` |

---

## The BONSAIRC Lump

The easiest way to make your mod work with Gun Bonsai is to include a `BONSAIRC` lump. Gun Bonsai loads all BONSAIRC lumps on startup, regardless of load order.

### Directives

#### `ifdef <classes> { ... }`
Executes the block only if at least one of the listed classes is defined.

```
ifdef MyMod_SpecialWeapon {
  type MyMod_SpecialWeapon : HITSCAN;
}
```

#### `register <upgrades> ;`
Adds upgrade class names to the upgrade pool. Must subclass `TFLV_Upgrade_BaseUpgrade`.

```
register MyMod_Upgrade_ExplodingChainsaw ;
```

#### `unregister <upgrades> ;`
Removes upgrades from the pool. Always takes precedence over `register`.

```
unregister TFLV_Upgrade_Juggler ;
```

#### `disable <classes> : <upgrades> ;`
Disables specific upgrades only for the listed weapon classes.

```
disable MyMod_Railgun : TFLV_Upgrade_BouncyShots TFLV_Upgrade_HomingShots ;
```

#### `merge <classes> ;`
Treats all listed weapon classes as the same weapon for upgrade-binding purposes.

```
merge MyMod_Pistol MyMod_Pistol_Upgraded ;
```

#### `type <classes> : <type> ;`
Overrides weapon type inference. Type is one or more of: `MELEE`, `HITSCAN`, `PROJECTILE`, `WIMPY`, `IGNORE`, `AUTO`.

```
type MyMod_Fists : MELEE WIMPY ;
type MyMod_WeaponTool : IGNORE ;
```

#### Class name matching
All `<classes>` lists accept a wildcard suffix (`*`) to match all classes with a given prefix.

```
type MyMod_* : HITSCAN ;
```

---

## Writing New Gun Bonsai Upgrades

### Overview

1. Subclass `TFLV_Upgrade_BaseUpgrade`
2. Override `IsSuitableForPlayer` and/or `IsSuitableForWeapon`
3. Override event handler methods for the effect
4. Add LANGUAGE entries (name, description, tooltip)
5. Register via BONSAIRC

### IsSuitableFor* methods

```zscript
// Weapon upgrade: appears only for hitscan weapons
override bool IsSuitableForWeapon(TFLV_WeaponInfo info) const {
    return info.IsHitscan() && !info.IsMelee();
}

// Player upgrade: appears in the player pool
override bool IsSuitableForPlayer(TFLV_PerPlayerStats stats) const {
    return true;
}
```

Both must be `const`. Available type queries: `IsHitscan()`, `IsProjectile()`, `IsMelee()`, `IsWimpy()`, `IsFastProjectile()`, `IsSlowProjectile()`, `IsRipper()`, `IsSeeker()`, `IsBouncer()`, `IsIgnored()`.

### Event handler methods

| Method | When called |
|---|---|
| `Tick(Actor owner)` | Every tic the upgrade is active |
| `OnMapEntry(string mapname, int mapnum)` | On map load |
| `OnActivate(stats, info)` | On equip / upgrade learned / re-enabled. **Must be idempotent.** |
| `OnDeactivate(stats, info)` | On weapon swap / upgrade disabled |
| `OnProjectileCreated(Actor pawn, Actor shot)` | When a projectile is fired |
| `ModifyDamageDealt(pawn, shot, target, damage, type)` | Before damage is applied |
| `ModifyDamageReceived(pawn, shot, attacker, damage, type)` | Before incoming damage is applied |
| `OnDamageDealt(pawn, shot, target, int damage)` | After damage lands |
| `OnDamageReceived(pawn, shot, target, int damage)` | After player takes damage |
| `OnKill(PlayerPawn pawn, Actor shot, Actor target)` | On confirmed player kill |
| `OnPickup(PlayerPawn pawn, Inventory item)` | When player picks up an item |

`OnActivate` **must be idempotent** — it can be called multiple times without an intervening `OnDeactivate`. `shot` may be null for DoT effects.

### The priority system

Upgrade effects can trigger each other, but only if the triggering effect has a higher priority. This prevents cascades like poison DoT triggering explosions triggering more poison.

```
PRI_ELEMENTAL < PRI_THORNS < PRI_EXPLOSIVE < PRI_FRAGMENTATION
```

Override `Priority()` to set your upgrade's priority. Use `PRI_NULL` to prevent triggering by other upgrades entirely.

### LANGUAGE entries

```
MyMod_Upgrade_ThingName  = "Thing";
MyMod_Upgrade_ThingDesc  = "Brief description shown in level-up menu.";
MyMod_Upgrade_ThingTT    = "Full description with @field markers.";
```

Dynamic fields via `GetTooltipFields`:

```zscript
override void GetTooltipFields(Dictionary fields, uint level) {
    fields.insert("damage", string.format("%d", level * 50));
    fields.insert("radius", AsMeters(level * 64));
}
```

---

## Gun Bonsai Service API

Access from any EventHandler or play-context class:

```zscript
let svc = TFLV_GunBonsaiService(ServiceIterator.Find("TFLV_GunBonsaiService").Next());
```

### Methods

```zscript
// Award XP to the player's current weapon
svc.AwardXP(PlayerPawn pawn, double xp);

// Award a player-level XP point
svc.AwardPlayerXP(PlayerPawn pawn, uint xp);

// Get the WeaponInfo for a weapon (null if not yet equipped)
TFLV_WeaponInfo svc.GetWeaponInfo(Weapon wpn);
```

---

## Indestructible Service API

```zscript
let svc = TFIS_IndestructibleService(ServiceIterator.Find("TFIS_IndestructibleService").Next());
```

Or send netevents:

```
netevent indestructible-adjust-lives <delta> <clamp>
netevent indestructible-clamp-lives <min> <max>
indestructible-set-lives <val>
```

---

## Doom Points Integration

No service API. Integrate via CVars and `player.mo.score`.

To award points, increment `player.mo.score` directly or spawn a `ScoreItem`. Check `dp_enabled` before doing Doom-Points-specific things.

### Extending the scoring system

The scoring chain exposes three virtual factory methods for clean subclassing:

```zscript
// In dp_ScoringSystem — override to inject a dp_PlayerScore subclass.
virtual dp_PlayerScore makePlayerScore(int playerNumber)

// In dp_PlayerScore — override to inject a dp_Counter subclass.
virtual dp_Counter makeCounter(int playerNumber, dp_TimerBonus tb, dp_HealthBonus hb)

// In dp_Counter — override to gate all scoring to a specific condition.
// Return false to suppress all scoring.
virtual bool isScoringAllowed() const
```

`dp_ScoringSystem.makePlayerScore()` performs a soft dependency check via string-to-class cast — if `tt_TypistPlayerScore` exists at runtime, it is used automatically. Use the same pattern to write your own scoring bridge:

```zscript
class MyMod_Counter : dp_Counter
{
  override bool isScoringAllowed() const
  {
    return true; // your condition here
  }
}

class MyMod_PlayerScore : dp_PlayerScore
{
  override dp_Counter makeCounter(int playerNumber,
                                  dp_TimerBonus timerBonus,
                                  dp_HealthBonus healthBonus)
  {
    return new("MyMod_Counter").init(playerNumber, timerBonus, healthBonus);
  }
}
```

---

## Companions Integration

No service API. Key CVars and integration points:

- `companions_enabled` (server bool) — master switch
- `companions_gun_bonsai_mode` (server bool) — if true, ally count scales from the Companions upgrade level
- `companions_compat` (server int) — monster roster: `0`=Ultimate Doom, `1`=Doom 2, `2`=Heretic, `3`=Hexen, `4`=Chex Quest 3, `5`=Strife
- `companions_strife_rebels` / `companions_strife_order` (server bool) — Strife faction toggles
- `TFCO_FriendEnhancer` — inventory item given to every friendly monster; handles AI, healing, resurrection, and stat modifications. Query for this item to detect Gun Bonsai companions.
- `TFCO_CompanionsSystem.GetAllyCount(playerNumber)` — returns how many allies should spawn for the given player

To spawn your own companion monsters and have them recognized by the system, set `bFRIENDLY = true` on them. `WorldThingSpawned` will automatically give them a `TFCO_FriendEnhancer`.

---

## Hyper-V Public API

### Detection

```zscript
// Check if Hyper-V is enabled
CVar.FindCVar("hyperv_enabled")  // server bool
CVar.FindCVar("hyperv_loaded")   // user bool, always true when Super Merged is loaded
```

### Slomo state

```zscript
// Read whether slomo is currently active
CVar.FindCVar("hyperv_slomo_active")  // server bool, set by SlomoHandler each tic

// Enable external slomo triggering
CVar.FindCVar("m8f_sm_externaltoggle")  // server bool — set true to allow external toggle
```

### Firing network events

Any mod can fire these network events to trigger Hyper-V actions:

```zscript
SendNetworkEvent("vmm_dash_fwd")        // forward dash
SendNetworkEvent("vmm_dash_left")       // left roll
SendNetworkEvent("vmm_dash_right")      // right roll
SendNetworkEvent("vmm_dash_back")       // back roll
SendNetworkEvent("vmm_dash_fwdleft")    // diagonal forward-left
SendNetworkEvent("vmm_dash_fwdrght")    // diagonal forward-right
SendNetworkEvent("vmm_dash_bckleft")    // diagonal back-left
SendNetworkEvent("vmm_dash_bckrght")    // diagonal back-right
SendNetworkEvent("vmm_throwhook")       // throw hook
SendNetworkEvent("vmm_teleport")        // teleport key press
SendNetworkEvent("vmm_teleport_cancel") // cancel teleport marker
SendNetworkEvent("vmm_melee_attack")    // melee key press
SendNetworkEvent("vmm_melee_toggle")    // toggle melee on/off
SendNetworkEvent("vmm_jump")            // double jump
```

### Stun system

Give `vrMeleeComboStunner` to any monster to stun it for a random duration:

```zscript
monster.GiveInventory("vrMeleeComboStunner", 1);
let st = vrMeleeComboStunner(monster.FindInventory("vrMeleeComboStunner"));
if(st) { st.stunMin = 0.5; st.stunMax = 2.0; }
```

### Parry shield

Give `ParryShieldCrit` to the player to manually trigger a parry:

```zscript
owner.GiveInventory("ParryShieldCrit", 1);
let sc = ParryShieldCrit(owner.FindInventory("ParryShieldCrit"));
if(sc)
{
    sc.resistPercent    = 50;   // % damage reduction
    sc.immunityDuration = 20;   // ticks of immunity after first hit
    sc.stunMin          = 0.5;  // attacker stun min (seconds)
    sc.stunMax          = 2.0;  // attacker stun max (seconds)
}
```

### Adding a new Hyper-V ability

1. Add CVar(s) to `CVARINFO.txt`
2. Add accessor(s) to `zscript/hyperv/vmm_settings.txt`
3. Load the setting into `V_Moves` in `UpdateVMoves` in `zscript/hyperv/v_moves.txt`
4. Add the field to `V_Moves` field declarations
5. Implement logic in `V_Moves.DoEffect()` or a helper called from it
6. If input is needed, add a network event in `NetworkProcess` and a keybind in `KEYCONF.txt`
7. Add menu entries to `MENUDEF_hyperv.txt`
8. Add a reset alias to `KEYCONF.txt` and include it in `vmm_reset_all`
9. Add tooltip strings to `LANGUAGE_en-hyperv.txt`

### Adding a new player property modifier

Add your logic to `CustomPlayerProperties.update()` in `vmm_attributes.txt` following the pattern of `updateDamageMultiply`. The `update()` function runs throttled (~3×/sec).

---

## XP Curve System

| Index | Name | Formula | Key CVars |
|---|---|---|---|
| 0 | Custom Power | `base_cost × level^x` | `bonsai_power_curve_exponent` |
| 1 | Custom Exponential | `base_cost × base^(level-1)` | `bonsai_exp_curve_base` |
| 2 | Hybrid | Blends component A → B | See below |

### Hybrid curve CVars

| CVar | Type | Default | Purpose |
|---|---|---|---|
| `bonsai_hybrid_component_a` | int | 1 (Exp) | Component at low levels (0=Power, 1=Exponential) |
| `bonsai_hybrid_component_b` | int | 0 (Power) | Component at high levels |
| `bonsai_hybrid_exp_base_a` | float | 1.5 | Exp base for component A |
| `bonsai_hybrid_exp_base_b` | float | 2.0 | Exp base for component B |
| `bonsai_hybrid_power_a` | float | 1.5 | Power exponent for component A |
| `bonsai_hybrid_power_b` | float | 2.0 | Power exponent for component B |
| `bonsai_hybrid_transition_start` | int | 3 | Level where blending begins |
| `bonsai_hybrid_transition_end` | int | 10 | Level where blending completes |
| `bonsai_hybrid_bias` | float | 0.0 | Smoothstep bias (-2..2) |
| `bonsai_hybrid_smooth` | int | 0 | Window half-size for transition smoothing (0=off, 1–15) |

`WeaponInfo.GetXPForLevel()` is the authoritative cost function.

### Level-up rejection

`bonsai_rejection_mode`: `0` = Lock (menu cannot be dismissed), `1` = Reject (second back-press deducts the per-level XP cost; surplus XP preserved).

### Death XP penalty

`bonsai_death_xp_penalty` (float, 0.0–1.0): on death, each known weapon loses `progress × penalty` XP. Weapons cannot lose a full level.

---

## Netevents Emitted by Super Merged

### `bonsai-level-up`
Fired when the player or weapon gains a level.
```
evt.args[0]: 0 = player level, 1 = weapon level
evt.args[1]: new level number
```

### `bonsai-choose-level-up-option`
Fired when the player picks an upgrade or dismisses the menu.
```
evt.args[0]: -1 = dismissed, >=0 = index of chosen upgrade
```

### `indestructible-report-lives`
Fired ~15 tics after a life count change.
```
evt.args[0]: absolute life count (-1 = unlimited)
evt.args[1]: delta since last report
```

---

## Accessing Gun Bonsai Internal State

### Getting PerPlayerStats

```zscript
let stats = TFLV_PerPlayerStats.GetStatsFor(pawn);
```

### Getting WeaponInfo

```zscript
let info = stats.GetInfoForCurrentWeapon(); // UI-safe, current weapon only
let info = stats.GetInfoFor(wpn);           // any weapon, no create
let info = stats.CreateInfoForCurrentWeapon(); // play context, creates if needed
```

### TFLV_CurrentStats (UI-safe snapshot)

```zscript
TFLV_CurrentStats cs;
if (!pps.GetCurrentStats(cs)) return;

// cs.plvl, cs.pxp, cs.pmax    — player level and XP
// cs.pupgrades                 — player upgrade bag
// cs.wlvl, cs.wxp, cs.wmax    — weapon level and XP
// cs.wname                     — weapon display name
// cs.winfo                     — WeaponInfo reference
// cs.wupgrades                 — weapon upgrade bag
// cs.wtypeflags                — pre-computed weapon type flags (uint)
// cs.score_mode                — true when bonsai_score_to_xp_factor > 0
// cs.ld_effect                 — active Legendoom effect name ("" if none)
```

`wtypeflags` bits: `MELEE=2`, `HITSCAN=4`, `PROJECTILE=8`, `FASTPROJECTILE=16`, `WIMPY=256`, `IGNORE=512`.

---

## Debug Commands

### Gun Bonsai

```
netevent bonsai-debug,w-up,::HomingShots 3   # add weapon upgrade levels
netevent bonsai-debug,p-up,::ToughAsNails 2  # add player upgrade levels
netevent bonsai-debug,w-xp 5000              # add weapon XP
netevent bonsai-debug,p-xp 1000              # add player XP
netevent bonsai-debug,info                   # dump weapon info to console
netevent bonsai-debug,allupgrades            # give all upgrades
netevent bonsai-debug,reset                  # full reset
```

### Indestructible

```
netevent indestructible-adjust-lives 5 0   # add 5 lives, ignore max
netevent indestructible-adjust-lives -1 0  # remove 1 life
netevent indestructible-clamp-lives 0 3    # cap at 3 lives
indestructible-set-lives 10               # set directly
indestructible-set-lives -1               # unlimited
```

---

## Architecture Notes

### Event handlers registered

```
TFLV_EventHandler       — Gun Bonsai + Doom Points + Companions (StaticEventHandler)
dp_StaticView           — Doom Points intermission hint (StaticEventHandler)
VPlayerPropModifier     — Hyper-V player properties, regen, enemy scaling, powerup prolonging (EventHandler)
VMovesHandler           — Hyper-V input detection, dash direction, network event dispatch (EventHandler)
SlomoHandler            — Hyper-V bullet time logic (EventHandler)
UnifiedHudHandler       — Hyper-V HUD rendering (UI scope, EventHandler)
```

### Gun Bonsai event flow

`TFLV_EventHandler` routes:
- `WorldTick` → Doom Points timer/streak update
- `WorldThingSpawned` → Bonsai projectile inference + Doom Points item scoring + Companions enhancer assignment
- `WorldThingRevived` → Companions re-enhancer on archvile resurrection
- `WorldThingDamaged` → Bonsai damage/XP + Doom Points real-time scoring
- `WorldThingDied` → Bonsai kill handling + Doom Points kill scoring
- `PlayerEntered` → per-player state init + Companions ally spawn
- `PlayerDisconnected` → Doom Points teardown
- `WorldLoaded/Unloaded` → map transition handling
- `NetworkProcess` → all UI→playsim communication (upgrades, profiles, companions)
- `ConsoleProcess` → balance profile save/apply/reset (works from menus without active game)
- `RenderOverlay` → Bonsai HUD + Doom Points HUD

### Hyper-V architecture

`V_Moves : CustomInventory` is given to the player on spawn and runs `DoEffect()` every tic. It holds all ability state fields and executes dash, melee, parry, teleporter, and hook logic. `VMovesHandler` handles input events and forwards them via network events or direct field writes. Settings are re-loaded in `UpdateVMoves` every 10 tics via `vmm_Settings.of()` which returns a cached instance — direct `CVar.FindCVar()` calls are avoided in hot paths.

`VPlayerPropModifier` runs `CustomPlayerProperties.update()` throttled to once per second (~35 tics), updating damage multipliers, speed, jump height, self-damage, taken-damage, and max health on the player pawn. Regen timers (`healticks`, `armorticks`, `ammoticks`) and enemy/friend scaling also run from this handler's `WorldTick`. Permanent powerup prolonging tops up active powerups once per second.

`SlomoHandler` manages the bullet time point pool, drain/recharge timers, depth scaling, and the ACS audio relay (`slomo_audio`). Berserk and Invulnerability bonuses are applied when those powerups are detected on the player.

`UnifiedHudHandler` renders the stacked ability bars (Stamina, Slomo, Dash, Hook) and the parry/teleport state indicators in UI scope. All bar positions and sizes are CVar-driven.

### Per-player state (Gun Bonsai)

`TFLV_PerPlayerStats` lives on `TFLV_PerPlayerStatsProxy` in player inventory. The event handler holds a direct reference for fast lookup. The proxy's `Poll` state calls `TickStats()` once per tic.

### Balance Profiles

`TFLV_Profiles` manages six saveable balance profiles stored as single `server string` CVars (`bonsai_profile_0` through `bonsai_profile_5`), serialized as `Dictionary.toString()` — self-describing `key=value` pairs. Every key is the CVar name, so the format is forward and backward compatible. Adding new CVars requires only appending to `GetFloatCVarNames` or `GetIntCVarNames` in `Profiles.zsc`.

### Companions architecture

`TFCO_CompanionsSystem` is a `play` class instantiated by the event handler. `TFCO_FriendEnhancer` is a per-monster inventory item that runs the full AI loop in `DoEffect()` every tic. CVar lookups in `DoEffect()` use direct CVar references (server scope). Expensive operations (sight checks, distance checks) are gated by `level.time % N` conditions. The Chex Quest 3 roster uses runtime `FindClass` resolution; Doom/Heretic/Hexen rosters use compile-time `Class<Actor>[]` arrays. The Strife roster builds a dynamic array at spawn time from the enabled faction pools.

### Legendoom integration

All LD code is gated by `TFLV_Settings.have_legendoom()`, which checks for `LDPistol` class existence at runtime. No compile-time dependency on Legendoom. The effect-giver retry loop only runs at level-up events, not per-tic.

### Sprite and sound requirements

The pk3 must contain:
- `bnfxa0/b0/c0` — HE Shots explosion sprites (renamed from `lfbx*` to avoid Final Doomer conflicts)
- `AL_PA0` — companion pointer arrow
- `RS_RA0`, `RS_SA0` — resurrection shock sprites
- `AL_DOW`, `AL_PUL`, `AL_RES`, `AL_TRYR` — companion sound lumps
- `bonsai/gunlevelup` — level-up sound
- `HookWall`, `HookMeat`, `HookFailed`, `HookLaunch` — Hyper-V hook sounds
- `FISTPUN1-3`, `FISTSTR1-3`, `DSRIP1-2` — Hyper-V melee sounds (from Beautiful Doom)
- `hbeat1-3` — Hyper-V heartbeat sounds
- `SLOWENTR`, `SLOWEXIT`, `SLOWLOOP` — Hyper-V slomo sounds
- `chord.ogg`, `Windows XP Ding.ogg` — Hyper-V parry sounds

---

## Typist Bridge

`typist_bridge.pk3` gates Doom Points scoring to Typist's Combat mode. Contains `tt_TypistCounter` and `tt_TypistPlayerScore` only — no changes to Super Merged required. Load order: `SuperMerged → Typist → typist_bridge.pk3`. Super Merged auto-detects it via the class registry check in `makePlayerScore()`.

Both Typist's built-in LazyPoints module and Doom Points write to `player.mo.score`. Gun Bonsai reads this for score-to-XP conversion, so the full XP pipeline works without additional wiring.

**Note on `dp_OptionMenuScoreItem`:** Typist ships a baked-in LazyPoints module that originally defined a class also named `OptionMenuScoreItem`. Doom Points renames its version to `dp_OptionMenuScoreItem` to resolve this collision permanently.
