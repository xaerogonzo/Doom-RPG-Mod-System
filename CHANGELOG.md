# Changelog

All notable changes to the Super Merged custom work are recorded here.
Third-party components (Gun Bonsai, Hyper-V, VUAS, Indestructible, Doom Points, libtooltipmenu) have their own histories upstream.

---

## [Unreleased]

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
- **VUAS `WorldPreSave` compile error** — `WorldPreSave` does not exist on `StaticEventHandler` in UZDoom 4.14.3; removed the override from `AchievementHandler.zs` and replaced the bulk sync-on-save approach with per-slot `SyncTrackerAt` calls that keep `VUAS_PersistentTracker` current at all times; mid-map saves now preserve achievement progress correctly
- **Slomo HUD bar overwrite** — the cooldown state was overwriting the points bar in the same render row; fixed by using a single bar (points remaining) with a separate pip overlay for cooldown state

---

## Notes

- Development engine: UZDoom 4.14.3
- Load order: `libtooltipmenu.pk3` → `VUAS.zip` → `Super_merged.pk3` → `Supermerged_VUAS_Bridge.pk3`
