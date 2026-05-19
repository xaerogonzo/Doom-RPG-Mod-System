version "2.5"

// =============================================================================
// Super Merged — Unified ZScript Root
// Components: Gun Bonsai, Indestructible, Doom Points, Companions, Hyper-V
// =============================================================================

// --- Doom Points scoring system ---
#include "zscript/scoring/DoomPoints.zsc"

// --- Indestructible extra lives system ---
#include "zscript/indestructible/Indestructible.zsc"

// --- Gun Bonsai core ---
#include "zscript/bonsai/util.zsc"
#include "zscript/bonsai/settings.zsc"
#include "zscript/bonsai/RC.zsc"
#include "zscript/bonsai/debug.zsc"
#include "zscript/bonsai/hud.zsc"
#include "zscript/bonsai/Profiles.zsc"
#include "zscript/bonsai/Legendoom.zsc"

// --- Companions system ---
#include "zscript/companions/Companions.zsc"
#include "zscript/companions/UpgradeCompanions.zsc"

// --- Gun Bonsai event handler & player systems ---
#include "zscript/bonsai/EventHandler.zsc"
#include "zscript/bonsai/PerPlayerStats.zsc"
#include "zscript/bonsai/PerPlayerStatsProxy.zsc"
#include "zscript/bonsai/Service.zsc"
#include "zscript/bonsai/UpgradeGiver.zsc"
#include "zscript/bonsai/PlayerUpgradeGiver.zsc"
#include "zscript/bonsai/WeaponUpgradeGiver.zsc"
#include "zscript/bonsai/WeaponInfo.zsc"
#include "zscript/bonsai/WeaponTypeInference.zsc"

// --- Gun Bonsai menus ---
#include "zscript/bonsai/menu/GenericMenu.zsc"
#include "zscript/bonsai/menu/PlayerLevelUpMenu.zsc"
#include "zscript/bonsai/menu/StatusDisplay.zsc"
#include "zscript/bonsai/menu/WeaponLevelUpMenu.zsc"
#include "zscript/bonsai/menu/ManualLevelMenu.zsc"

// --- Gun Bonsai upgrades ---
#include "zscript/bonsai/upgrades/BaseUpgrade.zsc"
#include "zscript/bonsai/upgrades/Dot.zsc"
#include "zscript/bonsai/upgrades/ElementalUpgrade.zsc"
#include "zscript/bonsai/upgrades/Registry.zsc"
#include "zscript/bonsai/upgrades/UpgradeBag.zsc"

#include "zscript/bonsai/upgrades/melee/Cleave.zsc"
#include "zscript/bonsai/upgrades/melee/DarkHarvest.zsc"
#include "zscript/bonsai/upgrades/melee/Shield.zsc"
#include "zscript/bonsai/upgrades/melee/Sweep.zsc"
#include "zscript/bonsai/upgrades/melee/Swiftness.zsc"

#include "zscript/bonsai/upgrades/AggressiveDefence.zsc"
#include "zscript/bonsai/upgrades/RicochetShots.zsc"
#include "zscript/bonsai/upgrades/Overdrive.zsc"
#include "zscript/bonsai/upgrades/Bandoliers.zsc"
#include "zscript/bonsai/upgrades/DecoyFlares.zsc"
#include "zscript/bonsai/upgrades/ECM.zsc"
#include "zscript/bonsai/upgrades/Explosive.zsc"
#include "zscript/bonsai/upgrades/ExplosiveDeath.zsc"
#include "zscript/bonsai/upgrades/Fragmentation.zsc"
#include "zscript/bonsai/upgrades/HazardSuit.zsc"
#include "zscript/bonsai/upgrades/HomingShots.zsc"
#include "zscript/bonsai/upgrades/UpgradeIndestructible.zsc"
#include "zscript/bonsai/upgrades/Intuition.zsc"
#include "zscript/bonsai/upgrades/Juggler.zsc"
#include "zscript/bonsai/upgrades/Leech.zsc"
#include "zscript/bonsai/upgrades/RapidFire.zsc"
#include "zscript/bonsai/upgrades/SimpleUpgrades.zsc"
#include "zscript/bonsai/upgrades/Submunitions.zsc"
#include "zscript/bonsai/upgrades/Thorns.zsc"

#include "zscript/bonsai/upgrades/Fire.zsc"
#include "zscript/bonsai/upgrades/Poison.zsc"
#include "zscript/bonsai/upgrades/Acid.zsc"
#include "zscript/bonsai/upgrades/Beam.zsc"
#include "zscript/bonsai/upgrades/Lightning.zsc"
#include "zscript/bonsai/upgrades/Blood.zsc"
#include "zscript/bonsai/upgrades/ElementalSynthesis.zsc"

// --- Hyper-V movement & gameplay systems ---
#include "zscript/hyperv/vmm_settings.txt"
#include "zscript/hyperv/vmm_attributes.txt"
#include "zscript/hyperv/v_moves.txt"
#include "zscript/hyperv/slomo_handler.txt"
#include "zscript/hyperv/unified_hud.txt"
#include "zscript/hyperv/HyperV_GunBonsai.zsc"
