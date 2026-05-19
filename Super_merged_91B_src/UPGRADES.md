# Upgrade Reference

This lists all upgrades in Gun Bonsai Unified with their effects, prerequisites, and notes. In-game tooltips have exact numbers; this file gives you the full picture of what each upgrade does and why you'd want it.

---

## Upgrade Pool and Rarity

Every upgrade can be assigned a **rarity tier** that controls how likely it is to appear when you level up. This is set in **Options → Gun Bonsai Options → Upgrade Pool / Rarity**.

### Tiers

| Tier | Default Weight |
|---|---|
| Disabled | 0 (never appears) |
| Very Rare | 1 |
| Rare | 3 |
| Uncommon | 6 |
| Common | 10 (default for all upgrades) |
| Favored | 20 |

Upgrades are selected using weighted random — each eligible upgrade's weight is divided by the total weight of all eligible upgrades to get its probability. A Favored upgrade (weight 20) is twice as likely as a Common one (weight 10); a Very Rare upgrade (weight 1) is ten times less likely.

### Elemental Master Switches

At the top of each element's group in the menu is a master switch that gates the entire family. Setting it to **Disabled** removes all upgrades in that element from the pool, regardless of individual tiers. Setting it to any other tier respects individual tier settings. The master switch does not itself add anything to the pool — it only gates access.

### Tier Weights

The **Tier Weights** submenu lets you change the numerical weight assigned to each tier name. Defaults are 0/1/3/6/10/20. Flattening these (e.g. 0/5/7/9/10/12) makes rarity less impactful. Exaggerating them (e.g. 0/1/2/4/10/30) makes Favored dominant and Very Rare nearly invisible.

### Reset All to Common

The **Reset ALL upgrades to Common** button in the menu resets every individual upgrade's tier CVar to 4 (Common). Tier Weights are not affected.

---



Player upgrades apply to you regardless of which weapon you're holding. You earn one every time your weapons collectively reach a configurable number of levels (default: every 7 weapon levels).

---

### Bandoliers
Increases maximum ammo capacity. Stacks with backpacks and other capacity increases. May have odd interactions with mods that implement their own ammo capacity mechanics.

### Blast Shaping
Reduces damage you take from your own AoE attacks (rockets, HE Rounds, Fragmentation, etc). Cannot reduce self-damage below 1.

### Bloodthirsty
Increases all damage you deal, from all weapons. Stacks with the per-weapon Damage upgrade.

### Companions *(Gun Bonsai integration mode only)*

Requires `Gun Bonsai integration mode` to be enabled in the Companions options, or this upgrade will not appear in the pool.

Friendly monsters spawn at map start to fight alongside you. Each level increases the number of companions. The **Monster roster** setting controls which game's monsters are used (Ultimate Doom, Doom 2, Heretic, Hexen, Chex Quest 3, or Strife). Boss companions unlock at a configurable level threshold; the actual boss depends on the active roster (Cyberdemon/Spider Mastermind in Doom, Maulotaur/D'Sparil in Heretic, Heresiarch in Hexen, FlemoidusMaximus in Chex, Inquisitor in Strife). The dangerous-tier companions (Arch-Vile in Doom 2, Iron Lich in Heretic, Dark Bishop in Hexen, StrifeBishop in Strife) unlock at a separate configurable threshold. Resurrection count per companion scales with level.

All companion behavior — color tinting, pointer arrows, teleportation, healing mode, idle and follow range — is independently configurable in the Companions Options menu regardless of upgrade level.

### Hazard Suit
Reduces damage from environmental hazards — acid floors, lava, slime. Does not affect enemy attacks.

### Indestructible *(Gun Bonsai integration mode only; max 4 levels)*

Requires `Gun Bonsai integration mode` in the Indestructible options.

Each level increases your maximum extra life count and reduces the damage required to earn a life through the damage-charging route. Lives are earned through level completion, boss kills, and cumulative damage absorbed — all configurable. When you'd die, a life is consumed: health restored to 50 HP, brief invincibility, time slowdown, and a damage boost.

### Intuition *(max 2 levels)*
**Level 1:** Automap fully revealed at map start.
**Level 2:** Actor positions shown on the automap.

### Juggler *(max 1 level)*
Weapon switching is nearly instantaneous. May not work with mods that have custom weapon switching animations.

### Personal ECM
Hacks incoming seeker missiles, redirecting them toward enemies or back at the launcher. Range and success rate scale with level.

### Scavenge Blood
Killing any enemy drops a health bonus worth 1 HP per upgrade level.

### Scavenge Lead
Enemies drop random ammo items on death. Ammo type is weighted toward what your weapons use.

### Scavenge Steel
Killing any enemy drops an armour bonus worth 2 points per upgrade level.

### Thorns
Enemies that attack you take a portion of their own damage back. Nearby enemies also receive elemental debuffs from your current weapon. You still take full damage.

### Tough as Nails
Reduces all incoming damage. Diminishing returns per level; cannot reduce below 1.

---

## Weapon Upgrades — General

These apply to the specific weapon that earns them. Weapon type is inferred from shot data; see *Notes on Weapon Type* below.

---

### Aggressive Defence *(Hitscan only)*
Damaging an enemy destroys hostile projectiles in the area around it. Good defensive option when fighting heavy projectile enemies.

### Bouncy Shots *(Projectile only; incompatible with Piercing Shots)*
Shots bounce off walls. Higher levels add more bounces and reduce velocity loss. At level 3, shots also bounce off enemies.

### Cleave *(Melee only)*
Killing a melee enemy triggers a free attack on another nearby enemy. Damage scales with overkill and the first enemy's spawn health. Most powerful against tough enemies killed efficiently.

### Dark Harvest *(Melee or Wimpy weapons only)*
Killing any enemy grants health and armour. Amount scales with level; boss kills grant 10× the normal amount.

### Damage
Increases this weapon's damage dealt. Each level adds a configurable percentage of base damage (default +20%/level, adjustable in Balance Tuning). Stacks with Bloodthirsty.

### Decoy Flares *(Projectile only)*
Enemy seeker missiles lock onto your shots instead of you. Higher levels increase redirect range and reliability.

### Explosive Death *(Ranged weapons only)*
Killing an enemy creates an explosion scaled to its max health. Cannot harm you.

### Fragmentation Shots *(Projectile only; incompatible with Piercing Shots)*
Projectiles release a ring of hitscan shrapnel on impact. More fragments and damage per level. Cannot self-damage.

### HE Rounds *(Hitscan only)*
Shots create a small explosion on hit. Higher levels increase damage, blast radius, and reduce self-damage. Uses `BNFX` explosion sprites — included in the pk3 to avoid Final Doomer sprite conflicts.

### High Velocity *(Projectile only)*
Projectiles move 50% faster per level (multiplicative).

### Homing Shots *(Projectile only)*
Projectiles home in on enemies. Range and turning agility scale with level.

### Piercing Shots *(Projectile only; requires High Velocity level 2; incompatible with Bouncy Shots)*
Shots pass through enemies with reduced damage per pierce. May interfere with explosive projectile detonation.

### Rapid Fire *(Max 10 levels; weapons with ammo only)*
Increases attack speed. The speed multiplier is continuous: at the default stat value (1.0), level 1 gives 1.5× speed, level 2 gives 2×, etc. The Balance Tuning slider (`bonsai_stat_rapid_fire`) scales the entire curve — setting it to 0.5 makes level 1 give 1.25×, setting it to 0 disables the upgrade entirely. Very high levels may cause graphical glitches.

### Shield *(Melee only)*
Reduces incoming ranged damage moderately and melee damage significantly — but only while actively attacking or briefly after a melee kill.

### Submunitions *(Ranged weapons only)*
Killing an enemy scatters bouncing explosive clusters. Count and damage scale with overkill and upgrade level. Cannot self-damage.

### Sweep *(Melee only)*
Melee attacks deal a percentage of their damage to other enemies in the hit zone. Higher levels increase proportion and range.

### Swiftness *(Melee or Wimpy weapons only)*
Killing an enemy briefly freezes time. Additional kills before unfreezing stack small duration bonuses.

---

## Elemental Upgrades

Elemental upgrades add debuffs and damage-over-time effects. Each element has four tiers:

- **Basic** → available from the start
- **Intermediate** → requires level 2 of the basic tier
- **Two Masteries** (pick one) → requires level 2 of the intermediate tier; earliest at weapon level 5

Each weapon can have at most **two different elements**. Once you have two elemental masteries, an **Elemental Synthesis** upgrade unlocks. Elemental AoE effects never harm the player.

---

### Fire

Deals more damage the more health the target has, then burns out below 50% HP — but reactivates if they heal. Excellent against regenerating enemies. Cannot kill alone; kills require other damage sources.

**Searing Inscription** *(basic)*
Shots ignite enemies. Higher levels apply stacks faster and raise the softcap.

**Burning Terror** *(intermediate)*
Burning enemies flee and flinch. Terror threshold and flinch chance scale with stacks and level. Also boosts fire damage taken.

**Conflagration** *(mastery — AoE)*
Burning enemies with enough stacks spread fire stacks to nearby enemies.

**Infernal Kiln** *(mastery — single target)*
Attacking a burning enemy builds a stacking offensive/defensive buff on you. Decays when you stop attacking that target.

---

### Poison

Weak but unbounded DoT; stacks add both DPS and duration with diminishing returns. Best with rapid-fire weapons.

**Venomous Inscription** *(basic)*
Shots apply poison stacks. Higher levels apply more stacks per hit.

**Weakness** *(intermediate)*
Poisoned enemies deal reduced damage per stack. Cannot reduce enemy damage below 1.

**Putrefaction** *(mastery — AoE)*
Killing a poisoned enemy spreads stacks to nearby enemies in a gas cloud.

**Hallucinogens** *(mastery — single target)*
Once an enemy has enough stacks to eventually kill it, it turns friendly and fights for you. A **yellow/orange flash** on the enemy indicates the trigger is approaching.

---

### Acid

Stacks convert into damage with acceleration at low health and high stack counts. Best with high-damage-per-shot weapons.

**Corrosive Inscription** *(basic)*
Shots apply acid stacks equal to a percentage of damage dealt (default 50%, +10% per level above 1).

**Concentrated Acid** *(intermediate)*
Raises the health threshold at which acid accelerates and the conversion ratio.

**Acid Spray** *(mastery — AoE)*
Attacks exceeding the acid softcap splash overflow onto nearby enemies.

**Embrittlement** *(mastery — single target)*
Enemies with acid stacks take more damage from all sources per stack. High-stack, low-HP enemies die instantly.

---

### Lightning

Does no bonus damage but slows targets to half speed. Stacks extend duration. Effective with any weapon type.

**Shocking Inscription** *(basic)*
Shots apply lightning stacks that slow the target.

**Thunderbolt** *(intermediate)*
Once stacks exceed the softcap, a bolt stuns the target and arcs stacks to nearby enemies. Arc range and damage scale with stacks and level.

**Revivification** *(mastery — single target)*
Killing an enemy raises it as a ghostly minion. Killing a stronger enemy replaces the existing one.

**Chain Lightning** *(mastery — AoE)*
Slain enemies release chain lightning that arcs between nearby targets. Damage scales with the dead enemy's health, stack count, and chain length.

---

## Elemental Synthesis

Once a weapon has two different elemental masteries, one Elemental Synthesis upgrade becomes available. Each copies all elemental effects from the current target to other enemies — a powerful force multiplier.

**Elemental Beam** *(Hitscan only)*
Copies effects to every enemy along a hitscan line from you through the target.

**Elemental Blast** *(Projectile only)*
Copies effects to all enemies near the impact point.

**Elemental Wave** *(Melee only)*
Copies effects to all enemies near *you*. Triggers on every melee hit.

---

## Notes on Weapon Type and the Wimpy System

### How type inference works

Gun Bonsai accumulates data as you fire. A weapon is hitscan if >33% of attacks produce hitscan hits, projectile if >33% produce projectile hits, melee if it has the `MELEEWEAPON` flag. An unfired weapon is compatible with all non-melee upgrades until it has enough data.

### Wimpy weapons

Wimpy if no ammo type (fist, pistol by default) or `bonsai_ammoless_weapons_are_wimpy` is enabled. Manually toggleable via the Manual Level Setting menu. Wimpy weapons cost 50% less XP per level (configurable) and can access Dark Harvest and Swiftness.

### BONSAIRC overrides

Use a `BONSAIRC` lump to force weapon types for misidentified modded weapons. See `BONSAIRC.txt` for syntax. Some common overrides are already included.

---

## Balance Tuning Reference

All of the following are adjustable in Options → Gun Bonsai Options → Balance Tuning. Changes take effect immediately.

**Profiles** let you snapshot and restore complete sets of tuning values. Five profiles available: Default (read-only), Balanced, Challenging, Punishing, Custom. Save/Apply Saved/Reset require an active game session.

Key tunable values per upgrade category:

| Upgrade | Key Stat | Default |
|---|---|---|
| Bloodthirsty | Damage bonus per level | +10% |
| Damage | Damage bonus per level | +20% |
| Tough as Nails | Damage reduction base per level | 0.90 (10% reduction) |
| Rapid Fire | Speed multiplier (scales entire curve) | 1.0 |
| Explosive (HE/Frags) | Explosion damage multiplier | +10% per level |
| Fragmentation | Fragments per level, damage per fragment | 6 base, 2/level, 20% each |
| Fire | Overall output multiplier | 1.0 |
| Poison | Overall output multiplier | 1.0 |
| Acid | Overall output multiplier + dps_mult (the "nuke" factor) | 1.0 + 6.0 |
| Lightning | Overall output multiplier | 1.0 |
| Elemental Synthesis | AoE radii (blast and wave) | 7× and 10× target radius |

For a full list of every tunable CVar, see the in-game Balance Tuning sliders and their tooltips.