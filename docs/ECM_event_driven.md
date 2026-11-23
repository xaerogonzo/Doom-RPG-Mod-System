# ECM: event-driven tracking (and how to go back to the original scan)

## What changed
`TFLV_Upgrade_ECM.Tick` used to run a `ThinkerIterator` over every actor in the level on every tic while the
upgrade was held. It now keeps a short `pending` list of missiles, filled from `WorldThingSpawned`
(`TFLV_EventHandler` -> `PerPlayerStats.OnHostileMissileSpawned` -> `UpgradeBag` -> `ECM.OnHostileMissileSpawned`),
and only checks that list. Ranges, chances and the three outcomes (redirect / reprogram / fail) are unchanged.
See the CHANGELOG entry "ECM no longer scans every actor" for the full rules (lazy tracer, 5-tic grace for
late `+SEEKERMISSILE`, rebuild scan after a tick gap).

Commits: `7e24c26` (event-driven list) and `88f258f` (late seekers, gap recovery), merged to master as one merge commit.

## Known differences from the original scan
- A projectile that gains `+SEEKERMISSILE` more than 5 tics after spawning is not noticed.
- Random numbers are drawn in list order instead of thinker order (same distributions).
- ECM now also has outcome tallies (`n_redirected`, `n_reprogrammed`, `n_failed`) shown in the debug dump.

## Reverting
Preferred (keeps history): revert the merge commit on master.

    git revert -m 1 <merge-commit-sha>

That restores the original scan. The hook methods (`OnHostileMissileSpawned`) and the `BONSAI ecm` debug line go
away with it. To revert only ECM and keep the hook plumbing, replace the body of `Tick` in
`Super_merged_91B_src/zscript/bonsai/upgrades/ECM.zsc` with the original below (it needs no `pending`/`born`
fields, `Prime` or `Forget`; the `Redirect`/`Reprogram`/`Fail` helpers can stay and be called from it).

Original `Tick` (from `ae2c7a2`):

```zscript
  override void Tick(Actor owner) {
    let radius = EcmRange(self.level);
    ThinkerIterator it = ThinkerIterator.Create("Actor", Thinker.STAT_DEFAULT);
    Actor shot;
    Array<Actor> monsters; bool did_monsters = false;
    while (shot = Actor(it.next())) {
      if (!shot || !shot.bSEEKERMISSILE || shot.tracer != owner || shot.bINCOMBAT || owner.Distance3D(shot) > radius) {
        // DEBUG("Skipping %s", TAG(shot));
        continue;
      }
//      DEBUG("Found shot %s with tracer=%s target=%s",
//        TAG(shot), TAG(shot.tracer), TAG(shot.target));
      // Found a seeker missile aimed at the player.
      // First, try to redirect it against a nearby enemy.
      if (!did_monsters) {
        TFLV_Util.MonstersInRadius(owner, LockRange(self.level), monsters);
        did_monsters = true;
      }
      if (monsters.size()) {
        // If we found a nearby monster to judo it into, do so.
        shot.tracer = monsters[random[TFLV_Upgrade_RNG_ECMTarget](0, monsters.size()-1)];
        shot.target = owner;
      } else if (frandom[TFLV_Upgrade_RNG_ECMHack](0.0, 1.0) >= UnhackableChance(self.level)) {
        // Else we have a chance to reprogram it to hunt its creator.
        shot.tracer = shot.target;
        shot.target = owner;
      } else {
        // We set the +INCOMBAT flag to keep track of shots we've already tried
        // and failed to redirect.
        // This shouldn't break anything since this flag is normally used to control
        // Strife dialogue and homing missiles are not known for being particularly
        // conversational.
        shot.bINCOMBAT = true;
      }
    }
  }
```
