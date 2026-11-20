# Changelog

All notable changes to the Super Merged custom work are recorded here.
Third-party components (Gun Bonsai, Hyper-V, VUAS, Indestructible, Doom Points, libtooltipmenu) have their own histories upstream.

---

## [Unreleased]

### Fixed
- **Friendly Master Sentinels no longer heal enemies through their fountains.** A companion Sentinel's `HealthFountainWhitePE` heals every monster in range, so enemies were healed and revived in endless fights. Map-start companions now get `TFCO_FriendEnhancer`, and when a Sentinel turns friendly it destroys the fountains it already spawned (matched by spawner, not proximity). The Colorful Hell fork gate (`claude/sentinel-fountain-gate`, commit `9625c3e`) stops friendly Sentinels from starting fountains, and needs that fork to be loaded. No per-tick cost; hostile Sentinels are unchanged.
  - Test-only hook `companions_test_class` (`Companions.zsc`, roster selection): spawns a named class as the first ally. Default empty, so normal gameplay is unaffected. Added for the Doom Live Tester; remove it before any release.
- **Dash stops responding mid-game until you save and reload.** Dash spends the stamina pool (`melee_stamina_val`), but the per-tic stamina recovery lived inside `V_Moves.Perform_Melee()`, which returns immediately when melee is disabled (`vmm_melee` Off, or Combat Training not yet unlocked with its Gun Bonsai gate on). With melee off the pool never refilled, so after about three dashes (30 each from 100) dash was dead; loading a save re-ran `initEvent`, which resets the pool to 100. Moved the recovery into `V_Moves.DoEffect()` so it runs every tic regardless of melee. Verified in UZDoom 5.0.3: with melee disabled, stamina went 10 to 100 in 100 tics after the fix and stayed at 10 before it.
- **Hyper-V Gun Bonsai gate redesigned: your Hyper-V toggles take precedence, upgrades unlock on top.** With a `hyperv_gb_*` option ON, a feature now runs only if (a) its own Hyper-V toggle is ON **and** (b) the matching upgrade level is reached (dash L1, double dash/ledge climb L2, double jump L3, melee/combo/parry L1/L2/L3, health/armor/ammo regen L1, hook/pull+stun L1/L2, teleporter L1, Bullet Time L1, its berserk/invuln bonuses L2). Turning double jump off in the Hyper-V menu means no Mobility level will ever grant it. Previously `TFLV_HyperV_IntegrationHandler` *overwrote* those toggles (`vmm_dash`, `sm_enabled`, ...) with the upgrade state, so the menu never showed your real choice, and nothing ran when enforcement missed (e.g. `PlayerEntered` not firing on first launch), leaving every feature available with zero upgrades.
  - The gate is now read-only and applied where features are consumed: new `vmm_GbGate` (`vmm_settings.txt`) is checked inside the `vmm_Settings` accessors and in `slomo_handler.txt`. Toggles are never written by the gate.
  - Upgrade levels are cached in new `hyperv_gb_lvl_*` CVars (`CVARINFO.txt`), written only on events: upgrade level-up / weapon switch (`OnActivate`/`OnDeactivate`), map load, (re)spawn. There is **no per-tick polling**; the idle cost is one `Size()` check per tic. Weapon-bound upgrades (Bullet Time, Hook, Teleporter) follow the wielded weapon.
  - MENUDEF notes reworded: the toggles now "set what is allowed; Gun Bonsai upgrades unlock them". Numeric scaling (cooldowns, regen amounts, speed/jump multipliers) is still driven by upgrade level.
  - **Migration:** earlier builds wrote upgrade state into your toggles, so a saved config can have dash/melee/slomo/etc. stuck Off. Re-enable the ones you want once in the Hyper-V menu. `vmm_double_dash`, `vmm_double_jump`, `vmm_ledge_climb` and the three regens default to Off.
  - Not changed: `vmm_ammo_regen_backpack` is still derived from Resupply level (existing behavior).
- **Hyper-V Upgrades balance menu — sliders now actually bind to the CVars the gameplay code reads.** `GunBonsaiStatHyperV` in `MENUDEF.txt` referenced `_lv1/_lv2/_lv3`-suffixed CVars (e.g. `bonsai_hyperv_slomo_pts_lv1`, `bonsai_hyperv_hregen_tick_lv1/lv2/lv3`, `bonsai_hyperv_tp_range_lv1/lv2`) that were never declared in `CVARINFO.txt`; the real integration code in `HyperV_GunBonsai.zsc` reads the `_base` + `_per_level` pair (per the project rule in `CLAUDE.md`). UZDoom 4.14.3 silently created phantom user CVars for the orphan names, letting sliders appear to work while doing nothing; UZDoom 5.0.3 no longer accepts input on them, which is what surfaced the bug. Collapsed each Lv1/Lv2/Lv3 slider group to the actual `_base` CVar and added sliders for the missing `_per_level` / `_min` knobs (armor-regen tick-per-level/min-tick, teleporter range-per-level/cooldown-per-level/cooldown-min). `resetcvar` reset command updated to match.
- Known follow-up: `Profiles.zsc` still lists the same phantom `_lv1/_lv2/_lv3` names in its positional serialization arrays (profile save/load writes to orphan CVars). Does not affect menu adjustability; profile save/restore of those specific values silently no-ops. Not addressed here because fixing it requires preserving the positional contract against existing saved profile strings.

### Added
- **Blood elemental upgrade** — new 5th element with lifesteal/anti-tank fantasy
  - `TFLV_Upgrade_SanguineShots` (apprentice): applies blood stacks; DoT deals % of enemy current HP per tick; heals player proportional to damage dealt
  - `TFLV_Upgrade_VitalDrain` (journeyman): improved heal ratio; restores armor while enemy is below 50% HP; prereq: SanguineShots ≥ 2
  - `TFLV_Upgrade_Exsanguinate` (master): blood burst heals player on enemy death proportional to spawn health; prereq: VitalDrain ≥ 2
  - New CVars: `bonsai_stat_blood_*` (drain pct, softcap, heal ratio, vitaldrain bonus, burst ratio, stacks per damage, stack drain rate, mult)
  - `TFLV_Upgrade_ELEM_BLOOD` added to `UpgradeElement` enum in `ElementalUpgrade.zsc`
  - Registered in `BONSAIRC.txt`; tuning CVars in `CVARINFO.txt`

- **Tokensave integration** — code-graph indexing for the project
  - 117 NTFS hardlinks created (`.zsc`→`.zsc.cpp`, `.zs`→`.zs.cpp`, `.acs`→`.acs.c`) so tree-sitter-cpp can parse ZScript/ACS
  - Index: 129 files, ~1500 nodes, ~1700 edges
  - `.gitignore` created to exclude shadow hardlinks from version control

- **Slomo HUD cooldown indicator** — single bar always shows points remaining; a "CD" pip drawn above the bar while on cooldown (distinct from the double-dash `>>` pattern used by the dash HUD)
  - Optional blink CVar `vmm_hud_slomo_cd_blink` with matching MenuDef option and tooltip string

### Changed
- **Hyper-V CVar refactoring** — replaced per-level `_lv1`/`_lv2`/`_lv3` CVars with uniform `_base` + `_per_level` formula across all 5 Hyper-V upgrade bridges (BulletTime, HealthRegen, ArmorRegen, AmmoRegen, Teleporter); matches the pattern used by the rest of the upgrade system
- **Overdrive level 3 gap fixed** — `GetMaxStacks()` now uses `min(1 + level*2, max_stacks)`; each level gives distinct stack counts (Lv1→3, Lv2→5, Lv3→7); `bonsai_stat_overdrive_max_stacks` ceiling raised from 5 to 10

### Fixed
- **Hyper-V permanent-powerup option stripped normal powerups** — `ProlongOne` (`vmm_attributes.txt`) called `TakeInventory` for every powerup class whose `vmm_perm_*` CVar was off, so any picked-up radsuit, blursphere, invulnerability, infrared etc. vanished within ~1 second (checked on UZDoom 5.0.3 with Simple Inventory Items); the disabled branch now leaves powerups alone
- **VUAS `WorldPreSave` compile error** — `WorldPreSave` does not exist on `StaticEventHandler` in UZDoom 4.14.3; removed the override from `AchievementHandler.zs` and replaced the bulk sync-on-save approach with per-slot `SyncTrackerAt` calls that keep `VUAS_PersistentTracker` current at all times; mid-map saves now preserve achievement progress correctly
- **Slomo HUD bar overwrite** — the cooldown state was overwriting the points bar in the same render row; fixed by using a single bar (points remaining) with a separate pip overlay for cooldown state

---

## Notes

- Development engine: UZDoom 4.14.3
- Load order: `libtooltipmenu.pk3` → `VUAS.zip` → `Super_merged.pk3` → `Supermerged_VUAS_Bridge.pk3`
