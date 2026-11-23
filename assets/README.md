# Generated assets

Sources for assets made with the Doom Creator Toolkit (`D:\Games\Doom wads\My Projects\Doom Creator Toolkit`).
The generated files are copied into `Super_merged_91B_src/` (this folder is not part of the mod pk3).

| script | output | used by |
|---|---|---|
| `sfx/stage_a.json` (seed 2026) | `sounds/rpg_levelup.wav`, `rpg_parry.wav` (composite-armour knock), `rpg_parry2.wav` (softer mitt-catch thud), `rpg_parry_armor.wav` (unused alternative: armour thunk) | `SNDINFO.txt`: `bonsai/gunlevelup`, `parry/crit1`, `parry/normal1` |

Regenerate and check:

```
python -m doomcreator validate assets/sfx/stage_a.json
python -m doomcreator build assets/sfx/stage_a.json -o out/stage_a.pk3 --loose out/loose --manifest out/manifest.json
```

`sfx/stage_a.manifest.json` lists the SHA-256 of each file (WAV is the canonical output; same script and seed give the same bytes).
Procedurally generated from the scripts only, no samples used; released under CC0 1.0 (see the toolkit's `OUTPUT-LICENSE.txt`).
