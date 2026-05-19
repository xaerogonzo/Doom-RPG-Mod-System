@D:/Claude Co worker/Token Save Manager Source/templates\project-baseline.md
@BASIC_INSTRUCTIONS.md

# Doom RPG Mod - Claude Instructions

## Tool Strategy
- **Priority:** Use `tokensave` tools for all code exploration. Avoid `grep` or `read_file` unless editing.
- **Exploration:** Use `tokensave_context` to understand actor relationships before suggesting changes.

## Shadow Extension Rule (tokensave hardlinks)
ZScript (`.zs`, `.zsc`) and ACS (`.acs`) are not natively supported by tokensave. NTFS hardlinks
with `.cpp`/`.c` suffixes were created so tree-sitter can parse them (e.g. `Blood.zsc.cpp`).
- When tokensave returns results from a file ending in `.zsc.cpp`, `.zs.cpp`, or `.acs.c`, the
  **real file to edit is the base name** — strip the trailing `.cpp` or `.c` suffix.
- Never write to or reference the shadow files directly. Always edit the `.zs`/`.zsc`/`.acs` source.
- If new `.zs`, `.zsc`, or `.acs` files are added to the project, run the hardlink script again
  (PowerShell: `New-Item -ItemType HardLink -Path "$src.cpp" -Target $src`) and then `tokensave sync`.

## Modding Standards
- **Language:** ZScript (primary), ACS (scripts).
- **Naming:** Follow existing conventions in the project (e.g., `DR_` prefix for actors).
- **Safety:** Always check for `null` pointers when using `target`, `master`, or `tracer`.