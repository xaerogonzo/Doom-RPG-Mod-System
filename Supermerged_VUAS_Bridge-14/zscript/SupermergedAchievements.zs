// =============================================================================
// Supermerged x VUAS Achievement Bridge
//
// TWO SYSTEMS:
//
// 1. HISTORICAL (VUAS native) — permanent record of first unlock dates stored
//    in ini CVars. Browse menu, unlock dates, all untouched. Reset only via
//    "Clear All Achievements" in VUAS settings.
//
// 2. PER-RUN SCORING (SM_RunProgress inventory item) — tracks which Doom Points
//    bonuses have been paid this run. Lives on the player actor so it persists
//    correctly per save file. Fresh on new game (item doesn't exist yet).
//    Load save A → A's progress. Load save B → B's progress.
//    Per-map achievements (Deathless, No Stone Unturned) are never recorded
//    as paid — they always fire their bonus when earned.
// =============================================================================

// =============================================================================
// SM_RunProgress — inventory item that tracks per-run bonus payout state.
// Stored as a comma-separated string of achievement IDs that have already
// paid their Doom Points bonus this run. String is small (max ~400 chars),
// serializes cleanly with the save file, expandable without array size changes.
// =============================================================================
class SM_RunProgress : Inventory
{
    String paidIDs; // comma-delimited list of IDs already paid this run

    Default
    {
        +Inventory.UNDROPPABLE
        +Inventory.UNTOSSABLE
        +Inventory.PERSISTENTPOWER
        Inventory.MaxAmount 1;
    }

    // Returns true if this achievement ID has already been paid this run.
    bool HasPaid(String id)
    {
        if (paidIDs.Length() == 0) return false;
        // Wrap in commas for exact match: ",century," won't match ",century_hard,"
        String search = "," .. id .. ",";
        String wrapped = "," .. paidIDs .. ",";
        return wrapped.IndexOf(search) >= 0;
    }

    // Record an achievement ID as paid.
    void MarkPaid(String id)
    {
        if (paidIDs.Length() == 0)
            paidIDs = id;
        else
            paidIDs = paidIDs .. "," .. id;
        SyncCVar();
    }

    // Clear all paid records (manual reset from menu).
    void Reset()
    {
        paidIDs = "";
        SyncCVar();
    }

    // Mirror paidIDs into sm_run_paid_ids CVar so the VUAS browse menu
    // can display the [THIS RUN] indicator without a direct class reference.
    void SyncCVar()
    {
        CVar cv = CVar.FindCVar("sm_run_paid_ids");
        if (cv) cv.SetString(paidIDs);
    }

    override bool ShouldStay() { return true; }
}

// =============================================================================
// SM_Achievements — VUAS setup subclass defining all 25 achievements.
// OnAchievementUnlocked handles both historical toast and per-run scoring.
// =============================================================================
class SM_Achievements : VUAS_AchievementSetup
{
    override void DefineAchievements()
    {
        // Leveling
        VUAS_AchievementHandler.AddAchievement("wpn_first_level","Baptism of Fire","Level up any weapon for the first time.","leveling",1,TRACK_CUSTOM_EVENT);
        VUAS_AchievementHandler.AddAchievement("wpn_level_5","Sharpshooter","Reach level 5 on any weapon.","leveling",1,TRACK_CUSTOM_EVENT);
        VUAS_AchievementHandler.AddAchievement("wpn_level_10","Master Armourer","Reach level 10 on any weapon.","leveling",1,TRACK_CUSTOM_EVENT);
        VUAS_AchievementHandler.AddAchievement("player_first_level","Growing Pains","Earn your first player level.","leveling",1,TRACK_CUSTOM_EVENT);
        VUAS_AchievementHandler.AddAchievement("player_level_5","Seasoned Veteran","Reach player level 5.","leveling",1,TRACK_CUSTOM_EVENT);
        VUAS_AchievementHandler.AddAchievement("player_level_10","Legendary","Reach player level 10.","leveling",1,TRACK_CUSTOM_EVENT);

        // Upgrades
        VUAS_AchievementHandler.AddAchievement("first_upgrade","Enhancement Protocol","Select your first weapon upgrade.","upgrades",1,TRACK_CUSTOM_EVENT);
        VUAS_AchievementHandler.AddAchievement("upgrade_level_3","Perfection","Reach level 3 on any single upgrade.","upgrades",1,TRACK_CUSTOM_EVENT);
        VUAS_AchievementHandler.AddAchievement("elemental_synthesis","Grand Synthesis","Unlock any elemental synthesis upgrade.","upgrades",1,TRACK_CUSTOM_EVENT);
        VUAS_AchievementHandler.AddAchievement("all_elements","Elemental Master","Have four or more elemental damage types active on a single weapon.","upgrades",1,TRACK_CUSTOM_EVENT);
        VUAS_AchievementHandler.AddAchievement("overdrive_maxed","Overdrive","Reach maximum Overdrive charge stacks on a weapon.","upgrades",1,TRACK_CUSTOM_EVENT);
        VUAS_AchievementHandler.AddAchievement("all_upgrades_one_weapon","Arsenal","Have 5 or more different upgrades on a single weapon.","upgrades",1,TRACK_CUSTOM_EVENT,'',"ACHVMT00",true);

        // Combat
        VUAS_AchievementHandler.AddAchievement("total_kills_100","Century","Kill 100 enemies.","combat",100,TRACK_KILLS);
        VUAS_AchievementHandler.AddAchievement("total_kills_1000","Exterminatus","Kill 1000 enemies.","combat",1000,TRACK_KILLS);
        VUAS_AchievementHandler.AddAchievement("ricochet_chain","Billiards","Land a Ricochet shot that bounces to 3 or more enemies.","combat",1,TRACK_CUSTOM_EVENT);
        VUAS_AchievementHandler.AddAchievement("kill_streak_5","On a Roll","Kill 5 enemies in quick succession.","combat",1,TRACK_CUSTOM_EVENT);
        VUAS_AchievementHandler.AddAchievement("kill_streak_10","Unstoppable","Kill 10 enemies in quick succession.","combat",1,TRACK_CUSTOM_EVENT);
        VUAS_AchievementHandler.AddAchievement("kill_streak_25","Untouchable","Kill 25 enemies in quick succession. How?!","combat",1,TRACK_CUSTOM_EVENT,'',"ACHVMT00",true);

        // Companions
        VUAS_AchievementHandler.AddAchievement("companion_survives","Faithful Companion","Complete a map with your companion still alive.","companions",1,TRACK_CUSTOM_EVENT);
        VUAS_AchievementHandler.AddAchievement("companion_resurrect","Back from the Dead","Watch your companion resurrect after dying.","companions",1,TRACK_CUSTOM_EVENT);

        // Survival
        VUAS_AchievementHandler.AddAchievement("no_death_map","Deathless","Complete a map without dying.","survival",1,TRACK_CUSTOM_EVENT,'',''/*no icon*/,false,false);
        VUAS_AchievementHandler.AddAchievement("indestructible_used","Safety Net","Spend an Indestructible extra life.","survival",1,TRACK_CUSTOM_EVENT);
        VUAS_AchievementHandler.AddAchievement("xp_comeback","Baptism by Fire","Lose XP from dying and earn it back to the same weapon level.","survival",1,TRACK_CUSTOM_EVENT,'',''/*no icon*/,true);

        // Exploration
        // Note: "secret_finder" is defined by VUAS_AchievementSetup base class.
        // We map its ID in GetBonusCVarName so it gets bonus points too.
        VUAS_AchievementHandler.AddAchievement("perfect_map","No Stone Unturned","Complete a map with 100% kills, items, and secrets.","exploration",1,TRACK_CUSTOM_EVENT,'',''/*no icon*/,false,false);
    }

    override void OnAchievementUnlocked(VUAS_AchievementData ach)
    {
        // Historical toast for hidden achievements
        if (ach.isHidden)
            Console.Printf("\c[Gold]*** SECRET ACHIEVEMENT UNLOCKED: %s ***\c-", ach.title);

        // Per-run Doom Points bonus
        AwardRunBonus(ach);
    }

    // Return true if this achievement's run bonus has already been paid,
    // so VUAS skips the retrigger call entirely (avoids netevent spam on
    // every kill/damage event after the achievement is already unlocked).
    override bool IsRetriggerSuppressed(VUAS_AchievementData ach)
    {
        // Per-map achievements (isCumulative=false) always retrigger —
        // their bonuses are never recorded in SM_RunProgress.
        if (!ach.isCumulative) return false;

        CVar paidCV = CVar.FindCVar("sm_run_paid_ids");
        String paidList = paidCV ? paidCV.GetString() : "";
        String search = "," .. ach.achievementID .. ",";
        return ("," .. paidList .. ",").IndexOf(search) >= 0;
    }

    // Fire the per-run Doom Points bonus for an already-unlocked achievement.
    override void OnAchievementRetriggered(VUAS_AchievementData ach)
    {
        AwardRunBonus(ach);
    }

    // Award Doom Points bonus for this achievement.
    // Fires a netevent with the achievement ID and point value.
    // The "already paid this run" check happens in Supermerged's NetworkProcess
    // handler where we have full play context and reliable player access.
    // Per-map achievements always fire (they reset each map naturally).
    static void AwardRunBonus(VUAS_AchievementData ach)
    {
        String cvarName = GetBonusCVarName(ach.achievementID);
        if (cvarName.Length() == 0) return;
        CVar cv = CVar.FindCVar(cvarName);
        if (!cv) return;
        int points = cv.GetInt();
        if (points <= 0) return;

        // Fire repeat toast when bonus awards on an already-unlocked achievement.
        // First-ever unlocks show a toast via VUAS's own unlock path automatically.
        // This extra toast fires on repeat runs so the player sees what gave them rewards.
        CVar repeatToast = CVar.FindCVar("dp_ach_repeat_toast");
        if (repeatToast && repeatToast.GetBool() && ach.isUnlocked)
        {
            let handler = VUAS_AchievementHandler.GetHandler();
            if (handler)
            {
                // Find achievement index by ID manually
                for (int i = 0; i < handler.achievements.Size(); i++)
                {
                    if (handler.achievements[i].achievementID ~== ach.achievementID)
                    {
                        EventHandler.SendNetworkEvent("vuas_achievement_unlocked", i);
                        break;
                    }
                }
            }
        }

        // Send achievement ID in netevent name for run-tracking lookup.
        // Per-map achievements (isCumulative=false) get prefix "dp_achievement_bonus_map:"
        // so EventHandler knows not to record them in SM_RunProgress.
        if (!ach.isCumulative)
            EventHandler.SendNetworkEvent("dp_achievement_bonus_map:" .. ach.achievementID, points);
        else
            EventHandler.SendNetworkEvent("dp_achievement_bonus:" .. ach.achievementID, points);
    }

    // Returns the dp_ach_* CVar name for a given achievement ID.
    static String GetBonusCVarName(String id)
    {
        if (id == "wpn_first_level")         return "dp_ach_wpn_first_level";
        if (id == "wpn_level_5")             return "dp_ach_wpn_level_5";
        if (id == "wpn_level_10")            return "dp_ach_wpn_level_10";
        if (id == "player_first_level")      return "dp_ach_player_first_level";
        if (id == "player_level_5")          return "dp_ach_player_level_5";
        if (id == "player_level_10")         return "dp_ach_player_level_10";
        if (id == "first_upgrade")           return "dp_ach_first_upgrade";
        if (id == "upgrade_level_3")         return "dp_ach_upgrade_level_3";
        if (id == "elemental_synthesis")     return "dp_ach_elemental_synthesis";
        if (id == "all_elements")            return "dp_ach_all_elements";
        if (id == "overdrive_maxed")         return "dp_ach_overdrive_maxed";
        if (id == "all_upgrades_one_weapon") return "dp_ach_all_upgrades";
        if (id == "total_kills_100")         return "dp_ach_kills_100";
        if (id == "total_kills_1000")        return "dp_ach_kills_1000";
        if (id == "ricochet_chain")          return "dp_ach_ricochet_chain";
        if (id == "kill_streak_5")           return "dp_ach_kill_streak_5";
        if (id == "kill_streak_10")          return "dp_ach_kill_streak_10";
        if (id == "kill_streak_25")          return "dp_ach_kill_streak_25";
        if (id == "companion_survives")      return "dp_ach_companion_survives";
        if (id == "companion_resurrect")     return "dp_ach_companion_resurrect";
        if (id == "no_death_map")            return "dp_ach_no_death_map";
        if (id == "indestructible_used")     return "dp_ach_indestructible_used";
        if (id == "xp_comeback")             return "dp_ach_xp_comeback";
        if (id == "secret_finder")           return "dp_ach_secret_finder";
        if (id == "perfect_map")             return "dp_ach_perfect_map";
        // VUAS default achievements
        if (id == "first_blood")             return "dp_ach_first_blood";
        if (id == "kill_50")                 return "dp_ach_kill_50";
        if (id == "kill_100_imps")           return "dp_ach_kill_100_imps";
        if (id == "kill_100_zombiemen")      return "dp_ach_kill_100_zombiemen";
        if (id == "secret_hunter")           return "dp_ach_secret_hunter";
        if (id == "uv_warrior")              return "dp_ach_uv_warrior";
        if (id == "hidden_gem")              return "dp_ach_hidden_gem";
        return "";
    }
}

// =============================================================================
// SM_RunProgressHandler — EventHandler that manages SM_RunProgress lifecycle.
// Handles the manual reset netevent from the menu.
// =============================================================================
class SM_RunProgressHandler : EventHandler
{
    override void WorldLoaded(WorldEvent e)
    {
        let plr = players[consoleplayer].mo;
        let progress = plr ? SM_RunProgress(plr.FindInventory("SM_RunProgress")) : null;

        if (progress)
        {
            // Item exists: either a map transition or a save load.
            // In both cases, push paidIDs back into the CVar so the achievement
            // handler sees the correct paid list for this run.
            progress.SyncCVar();
        }
        else
        {
            // No item: fresh game start (inventory wiped by engine).
            // Clear any stale CVar value left over from a previous session.
            CVar cv = CVar.FindCVar("sm_run_paid_ids");
            if (cv) cv.SetString("");
        }
    }

    override void NetworkProcess(ConsoleEvent evt)
    {
        let plr = players[evt.player].mo;
        if (!plr) return;

        if (evt.name == "sm_reset_run_progress")
        {
            let progress = SM_RunProgress(plr.FindInventory("SM_RunProgress"));
            if (progress)
            {
                progress.Reset();
                Console.PrintF("\c[CYAN]Supermerged:\c- Run achievement progress reset.");
            }
            else
            {
                Console.PrintF("\c[DARKGRAY]Supermerged:\c- No run progress to reset (fresh run already).");
            }
        }
        else if (evt.name.Left(13) == "sm_mark_paid:")
        {
            // Called by Supermerged EventHandler to record a paid achievement.
            // Creates the SM_RunProgress item if it doesn't exist yet.
            String achID = evt.name.Mid(13);
            if (achID.Length() == 0) return;

            let progress = SM_RunProgress(plr.FindInventory("SM_RunProgress"));
            if (!progress)
            {
                progress = SM_RunProgress(Actor.Spawn("SM_RunProgress"));
                if (progress)
                {
                    if (!progress.CallTryPickup(plr)) { progress.Destroy(); return; }
                    progress = SM_RunProgress(plr.FindInventory("SM_RunProgress"));
                }
            }
            if (progress) progress.MarkPaid(achID);
        }
    }
}
