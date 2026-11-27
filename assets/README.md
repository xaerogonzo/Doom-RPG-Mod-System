# Generated assets

Sources for assets made with the Doom Creator Toolkit (`D:\Games\Doom wads\My Projects\Doom Creator Toolkit`).
The generated files are copied into `Super_merged_91B_src/` (this folder is not part of the mod pk3).

| script | output | used by |
|---|---|---|
| `sfx/stage_a.json` (seed 2026) | `sounds/rpg_levelup.wav`, `rpg_parry.wav` (layered composite-armour hit), `rpg_parry2.wav` (softer layered thud), `rpg_parry_armor.wav` (metal-led variant); all three are played at random for both `parry/crit` and `parry/normal` | `SNDINFO.txt`: `bonsai/gunlevelup`, `parry/crit1`, `parry/normal1` |

| `sfx/gen_stage_b.py` -> `stage_b_candidates.json` (seed 2028), `sfx/gen_stage_b2.py` -> `stage_b2_candidates.json` (seed 2029) | candidates (round 1: 22, round 2: 16); shipped (provisional): `rpg_jump__f1/f3/f5`, `rpg_dash__c3/h3/h6`, `rpg_doublejump__g1/g4/g5`, `rpg_climb__d3/d2`, `rpg_climbtop__e2/e1` | `SNDINFO.txt`: `hv/jump`, `hv/dash`, `hv/doublejump`, `hv/climb`, `hv/climbtop` |

Regenerate and check:

```
python -m doomcreator validate assets/sfx/stage_a.json
python -m doomcreator build assets/sfx/stage_a.json -o out/stage_a.pk3 --loose out/loose --manifest out/manifest.json
```

`sfx/stage_a.manifest.json` lists the SHA-256 of each file (WAV is the canonical output; same script and seed give the same bytes).
Procedurally generated from the scripts only, no samples used; released under CC0 1.0 (see the toolkit's `OUTPUT-LICENSE.txt`).

`rpg_parry.wav`, `rpg_parry2.wav` and `rpg_parry_armor.wav` are layered (composite) sounds: a short low thud, a noise slap, three tiny grit bursts, a hard tick, a noisy low rattle tail and a settling thump, mixed by the toolkit's `layers` feature (branch `feature/sound-layers` of Doom Creator Toolkit). Each layer's `level` in `sfx/stage_a.json` is the knob for roughness (grit layers), weight (thud layers) and tail (rattle).

Audition and balance: `python -m doomcreator audition assets/sfx/stage_b_candidates.json -o audition.html --reference "Doom pistol=-12.2"` makes one page where every candidate can be played and rated; each sound has `target_rms_dbfs` so its loudness is chosen on purpose (Doom reference audible RMS: pistol -12.2, player pain -14.1, oof -18.3, item pickup -25.3).

ECM cues: `sfx/gen_ecm.py` -> `sfx/ecm_candidates.json` (seed 2030, 10 candidates); shipped (provisional): `rpg_ecm_hacked__a1/a2/a4`, `rpg_ecm_failed__b1/b2/b5` as `ecm/hacked` and `ecm/failed` in `SNDINFO.txt`.

Thorns and Shield: `sfx/gen_thorns_shield.py` -> `sfx/thorns_shield_candidates.json` (seed 2031, 16 candidates); shipped (provisional): `rpg_thorns2__w2/w4/w5/w8` and `w2b/w4b/w5b/w8b` from `sfx/gen_thorns2.py` -> `thorns2_candidates.json` (seed 2032, replaces the harsher spark round) (`thorns/zap`), `rpg_shield_up__s1/s3/s4`, `rpg_shield_down__t1/t2/t3`, `rpg_shield_hit2__x1-x5` and `x1b/x2b/x4b` (from `sfx/gen_shield_hit2.py` -> `shield_hit2_candidates.json`, seed 2033) (`shield/up`, `shield/down`, `shield/hit`).

Bouncy Shots: `sfx/gen_bouncy2.py` -> `sfx/bouncy2_candidates.json` (seed 2035, 8 layered candidates, shipped: `rpg_bouncy2__m1/m2/m6`, provisional; round 1 single-tone blips in `bouncy_candidates.json` were too close to the Thorns chimes) as `bouncy/field` in `SNDINFO.txt`.

Explosion sound: 7 sounds picked from the Doom Creator Toolkit sound-search lab (rounds 4-5, gene vectors and measures in `sfx/explosions_picked.json`; the earlier `sfx/gen_explosions.py` -> `sfx/explosions_candidates.json` hand-made set, seed 2043, is no longer shipped; provisional) as `bonsai/smallboom` in `SNDINFO.txt`.

Blood/Kiln cues: `sfx/gen_blood_kiln.py` -> `sfx/blood_kiln_candidates.json` (seed 2042; 12 quiet tonal one-shots, provisional) as `blood/exsanguinate`, `blood/vitaldrain`, `fire/kiln` in `SNDINFO.txt`.

Acid/Poison cues: `sfx/gen_acid_poison.py` -> `sfx/acid_poison_candidates.json` (seed 2039; 16 quiet one-shots, provisional) as `acid/spray`, `acid/embrittle`, `poison/hallucinate`, `poison/putrefy` in `SNDINFO.txt`.

Fire/Lightning cues: `sfx/gen_fire_lightning.py` still ships `fire/terror`, `fire/spread`, `lightning/thunder`, `lightning/revive`. **Chain Lightning:** hops `lightning/arc` = eight shorter snaps (`sfx/chain_zap_arc_picked.json`); start `lightning/chain` = six longer keeps plus 013 (`sfx/lightning_chain_picked.json`). Old FM chain variants and `chain_arc_picked.json` are no longer shipped. Thunderbolt keepers are still unwired. Plan: Doom Hub `LIGHTNING_SFX.md`.

Submunitions: `sfx/gen_submunitions.py` -> `sfx/submunitions_candidates.json` (seed 2037, 5 rhythmic 5.83 s loop variants matched to the measured bomblet bounce rhythm, all shipped, provisional; needs the toolkit's 96-layer limit) as `submunitions/cluster` in `SNDINFO.txt`.
