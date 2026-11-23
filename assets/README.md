# Generated assets

Sources for assets made with the Doom Creator Toolkit (`D:\Games\Doom wads\My Projects\Doom Creator Toolkit`).
The generated files are copied into `Super_merged_91B_src/` (this folder is not part of the mod pk3).

| script | output | used by |
|---|---|---|
| `sfx/stage_a.json` (seed 2026) | `sounds/rpg_levelup.wav`, `rpg_parry.wav` (layered composite-armour hit), `rpg_parry2.wav` (softer layered thud), `rpg_parry_armor.wav` (metal-led variant); all three are played at random for both `parry/crit` and `parry/normal` | `SNDINFO.txt`: `bonsai/gunlevelup`, `parry/crit1`, `parry/normal1` |

| `sfx/gen_stage_b.py` -> `sfx/stage_b_candidates.json` (seed 2028) | 22 candidates; shipped: `sounds/rpg_jump__a1/a3`, `rpg_dash__c2/c3/c5`, `rpg_doublejump__b1/b2`, `rpg_climb__d2`, `rpg_climbtop__e1` | `SNDINFO.txt`: `hv/jump`, `hv/dash`, `hv/doublejump`, `hv/climb`, `hv/climbtop` |

Regenerate and check:

```
python -m doomcreator validate assets/sfx/stage_a.json
python -m doomcreator build assets/sfx/stage_a.json -o out/stage_a.pk3 --loose out/loose --manifest out/manifest.json
```

`sfx/stage_a.manifest.json` lists the SHA-256 of each file (WAV is the canonical output; same script and seed give the same bytes).
Procedurally generated from the scripts only, no samples used; released under CC0 1.0 (see the toolkit's `OUTPUT-LICENSE.txt`).

`rpg_parry.wav`, `rpg_parry2.wav` and `rpg_parry_armor.wav` are layered (composite) sounds: a short low thud, a noise slap, three tiny grit bursts, a hard tick, a noisy low rattle tail and a settling thump, mixed by the toolkit's `layers` feature (branch `feature/sound-layers` of Doom Creator Toolkit). Each layer's `level` in `sfx/stage_a.json` is the knob for roughness (grit layers), weight (thud layers) and tail (rattle).

Audition and balance: `python -m doomcreator audition assets/sfx/stage_b_candidates.json -o audition.html --reference "Doom pistol=-12.2"` makes one page where every candidate can be played and rated; each sound has `target_rms_dbfs` so its loudness is chosen on purpose (Doom reference audible RMS: pistol -12.2, player pain -14.1, oof -18.3, item pickup -25.3).
