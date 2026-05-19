# libtooltipmenu — Mod Author Reference

This document covers everything a mod author needs to integrate libtooltipmenu,
with full reference tables for fonts, colours, and textures.

---

## How the system works

When a player opens one of your menus, libtooltipmenu applies tooltip settings
in this priority order:

```
player's global override CVars   (Options → Tooltip Appearance)
  └─ if slider is −1 / field is blank, fall through to:
       your TFLV_TooltipGeometry / TFLV_TooltipAppearance values
         └─ if you omitted those, fall through to:
              library defaults  (x=0.0, y=0.5, w=0.30, white text)
```

Your defaults are always preserved as the middle layer. The player's overrides
only activate per-field — if they leave X Position at −1, your x value is used
exactly. Hitting *Reset to Mod Defaults* in the settings menu writes −1 back to
every slider and blanks every text field, instantly restoring your values.

---

## MENUDEF integration

### Minimum required change

```
OptionMenu "MyModOptions"
{
    class TFLV_TooltipOptionMenu    // ← add this line
    Title "My Mod Settings"

    Option "Enable Feature", "my_feature_cvar", "YesNo"
    TFLV_Tooltip "Turns the feature on or off."

    Slider "Intensity", "my_intensity_cvar", 0.0, 10.0, 0.5, 1
    TFLV_Tooltip "Controls how intense the effect is. Higher values are more dramatic."
}
```

### Setting your mod's defaults

```
OptionMenu "MyModOptions"
{
    class TFLV_TooltipOptionMenu
    Title "My Mod Settings"

    // Geometry: x, y, w, xpad, ypad  (scale is optional sixth argument)
    TFLV_TooltipGeometry 1.0, 0.5, 0.28, 1.0, 0.5

    // Appearance: font, colour, texture  (use "" to keep the library default)
    TFLV_TooltipAppearance "", "Gold", "MYMODBG"

    Option "Enable Feature", "my_feature_cvar", "YesNo"
    TFLV_Tooltip "Explanation."
}
```

Order of `TFLV_TooltipGeometry` and `TFLV_TooltipAppearance` relative to each
other and to the menu items doesn't matter — they set menu-wide defaults.

### ListMenu support

For list-style menus, use `TFLV_TooltipListMenu` instead:

```
ListMenu "MyModList"
{
    class TFLV_TooltipListMenu
    // same TFLV_Tooltip / TFLV_TooltipGeometry / TFLV_TooltipAppearance syntax
}
```

### Multi-line tooltips

Use `\n` inside the string for explicit line breaks. The renderer also
word-wraps automatically to fit the box width.

```
TFLV_Tooltip "First line.\nSecond line.\n\nNew paragraph after a blank line."
```

### Localisation

`TFLV_Tooltip` accepts LANGUAGE table keys exactly like other MENUDEF strings:

```
TFLV_Tooltip "$MYMOD_TT_FEATURE"
```

Define `MYMOD_TT_FEATURE` in your `LANGUAGE.xx` lump as usual.

---

## MENUDEF keyword reference

| Keyword | Arguments | Description |
|---|---|---|
| `TFLV_TooltipGeometry` | `x, y, w [, xpad [, ypad [, scale]]]` | Sets default geometry for all tooltips in this menu |
| `TFLV_TooltipAppearance` | `"font", "colour", "texture"` | Sets default appearance; use `""` for any field to keep library default |
| `TFLV_Tooltip` | `"text"` | Attaches a tooltip to the immediately preceding menu item |
| `TFLV_TooltipID` | `"id" ["page"]` | Accepted for backwards compatibility; no-op in this version |
| `TFLV_TooltipPage` | `"page"` | Accepted for backwards compatibility; no-op in this version |

### Geometry values explained

| Field | Default | Range | Meaning |
|---|---|---|---|
| `x` | 0.0 | 0.0–1.0 | Horizontal anchor. 0.0 pins the box to the left edge of the screen; 1.0 to the right; 0.5 centres it. The box is shifted so that `x` × (screen width − box width) pixels fall to its left. |
| `y` | 0.5 | 0.0–1.0 | Vertical anchor. 0.0 = top, 1.0 = bottom, 0.5 = vertically centred. Same calculation as x but vertically. |
| `w` | 0.30 | 0.0–1.0 | Maximum box width as a fraction of the virtual screen width. Text wraps inside this. The actual box width shrinks to the longest line if text is narrower. |
| `xpad` | 1.0 | 0.0–4.0 | Horizontal padding between text and box edge, measured in em-widths (the width of the letter 'm' in the tooltip font). Applied to both sides. |
| `ypad` | 0.5 | 0.0–2.0 | Vertical padding, measured in line-heights. Applied above the first line and below the last. |
| `scale` | 1.0 | >0.0 | Whole-tooltip size multiplier. Scales the virtual render target; affects text size and background together. Values below 1.0 make everything smaller and finer. |

---

## ZScript integration

If you build menus in ZScript rather than MENUDEF, extend
`TFLV_TooltipOptionMenu` and call `PushTooltip()` after pushing each item:

```zscript
class MyMod_SettingsMenu : TFLV_TooltipOptionMenu {

  override void Init(Menu parent, OptionMenuDescriptor desc) {
    InitDynamic(parent, desc);   // clears desc and sets up tooltip_settings

    // Set defaults (optional — omit to use library defaults)
    TooltipGeometry(1.0, 0.5, 0.28, 1.0, 0.5);
    TooltipAppearance("", "Gold", "MYMODBG");

    desc.mItems.push(new("OptionMenuItemOption").Init(
        "Enable Feature", "my_feature_cvar", "YesNo", null, 0));
    PushTooltip("Turns the feature on or off.");

    desc.mItems.push(new("OptionMenuItemSlider").Init(
        "Intensity", "my_intensity_cvar", 0.0, 10.0, 0.5, 1));
    PushTooltip("Controls the effect strength.");
  }
}
```

`PushTooltip(text, n)` — attaches `text` to the last `n` items pushed (default
`n=1`). Must be called immediately after the item(s) it describes. Returns the
`TFLV_Tooltip` object in case you want to store it and update `.text` later.

`TooltipGeometry(x, y, w, xpad, ypad, scale)` — any argument passed as −1.0
is ignored (leaves the library default for that field).

`TooltipAppearance(font, colour, texture)` — any argument passed as `""`
is ignored.

---

## Font reference

These fonts are always available in GZDoom and UZDoom:

| Name | Description |
|---|---|
| `SmallFont` | Small, fixed-width console font |
| `NewSmallFont` | Proportional small font; default for this library |
| `BigFont` | Large display font used for menu titles |
| `ConsoleFont` | Monospaced font used in the console |
| `IntermissionFont` | Bold font used on intermission screens |

IWAD-specific fonts (only available when that IWAD is loaded):

| Name | IWAD | Description |
|---|---|---|
| `DoomFont` | Doom / Doom II | The classic stone-carved Doom font |
| `HereticFont` | Heretic | Decorative fantasy font |
| `HexenFont` | Hexen | Dark medieval font |
| `StrifeFont` | Strife | Small dialogue font |

Custom fonts from PWADs and texture packs can be used by name if they are
defined in a `FONTDEFS` lump. For example, some popular packs include fonts
named `BIGFONT2`, `CONFONT2`, and similar variants. If a font name is not
recognised at draw time, the tooltip silently falls back to the mod's font.

---

## Colour reference

GZDoom built-in colour names (case-insensitive):

| Name | Appearance |
|---|---|
| `White` | Pure white |
| `Black` | Pure black |
| `Red` | Bright red |
| `Green` | Bright green |
| `Blue` | Bright blue |
| `Yellow` | Bright yellow |
| `Gold` | Warm golden orange |
| `Orange` | Orange |
| `Purple` | Purple-violet |
| `Cyan` | Cyan / aqua |
| `Gray` / `Grey` | Mid grey |
| `DarkGray` / `DarkGrey` | Dark grey |
| `LightBlue` | Light sky blue |
| `Olive` | Dark olive green |
| `DarkGreen` | Dark green |
| `DarkRed` | Dark red / maroon |
| `DarkBrown` | Dark brown |
| `TrueBlack` | Absolute black (no palette rounding) |
| `TrueWhite` | Absolute white |

IWAD-specific colour names (palette-dependent, may shift in modded palettes):

| Name | Typical appearance |
|---|---|
| `Cream` | Off-white / light tan |
| `Ice` | Cold blue-white |
| `Fire` | Deep red-orange |
| `Sapphire` | Rich blue |
| `Teal` | Teal-green |

Custom colour names can be defined in a `FONTDEFS` lump with a
`PaletteRange` or `TrueColorRange` block. Any name defined there is usable in
the Colour field.

If an unrecognised name is entered, GZDoom silently uses white. The field is
case-insensitive.

---

## Texture reference

The texture is stretched to fill the entire tooltip background box. Any
single-patch texture or flat defined in the loaded WADs and PK3s can be used
by its lump name.

### Solid colour patches (always available)

| Name | Description |
|---|---|
| `TBLACK` | Solid black |
| `TGRAY` | Solid mid grey |
| `TWHITE` | Solid white |

### Doom IWAD textures (useful as tooltip backgrounds)

| Name | Description |
|---|---|
| `BOSSBACK` | Dark grey stone texture (used on the episode end screen) |
| `FLOOR7_2` | Dark metal grate flat |
| `FLAT14` | Dark brownish flat — low visual noise |
| `CEIL3_5` | Dark grey concrete ceiling flat |

### Heretic IWAD

| Name | Description |
|---|---|
| `FLOOR00` | Dark stone — low contrast |
| `FLAT513` | Dark wood |

### Common filler approach

Many mods define a dedicated small dark texture in their own PK3 and name it
something like `MODBG`, `TTBG`, or `TOOLTIPB`. This is the recommended approach
if you want a custom background: add a 1×1 or 8×8 PNG patch to your PK3 with a
low-contrast colour matching your mod's palette, declare it in `TEXTURE1` or as
a standalone patch, and reference it by name.

```
// TEXTURE1 entry (or just drop the PNG as a patch and reference directly)
MYMODBG   0    8    8
```

Then in your menu:

```
TFLV_TooltipAppearance "", "Gold", "MYMODBG"
```

If the texture name is not found at draw time, the tooltip draws with no
background (text only). This is not an error.

---

## Complete worked example

A mod called *Vortex Armoury* with a right-side panel style and gold text on
a custom dark background:

**MENUDEF.txt**
```
OptionMenu "VortexArmouryOptions"
{
    class TFLV_TooltipOptionMenu
    Title "Vortex Armoury"

    TFLV_TooltipGeometry 1.0, 0.5, 0.28, 1.0, 0.5
    TFLV_TooltipAppearance "", "Gold", "VABG"

    StaticText ""
    StaticText "WEAPON BEHAVIOUR", Red

    Option "Auto-reload",  "va_autoreload",  "YesNo"
    TFLV_Tooltip "Automatically reload the active weapon when the magazine is empty and you have spare ammo."

    Slider  "Spread",      "va_spread",      0.0, 5.0, 0.25, 2
    TFLV_Tooltip "Bullet spread in degrees. 0.0 is perfectly accurate. Default is 1.5."

    Option  "Penetration", "va_penetration", "YesNo"
    TFLV_Tooltip "When On, bullets pass through enemies and can hit multiple targets in a line."

    StaticText ""
    StaticText "VISUAL", Red

    Option  "Muzzle flash",   "va_muzzleflash",   "YesNo"
    TFLV_Tooltip "Enables the dynamic light on the muzzle of the weapon when firing."

    Option  "Shell casings",  "va_shellcasings",  "YesNo"
    TFLV_Tooltip "Spawns ejected shell casings. Turn off for a small performance gain on older hardware."
}
```

**sprites/VABG.png** — an 8×8 pixel PNG, colour #1a1a1a (near-black). Referenced
from MENUDEF as `"VABG"`. Because it is a graphic in the sprites namespace it is
available as a texture name without a TEXTURE1 entry.

---

## Frequently asked questions

**Does my mod need to ship a copy of libtooltipmenu?**
No. libtooltipmenu is loaded separately alongside your mod. Your MENUDEF just
uses its class names. If it's not loaded, GZDoom will report an unknown class
for `TFLV_TooltipOptionMenu` — you may want to note the dependency in your
mod's readme.

**What happens if the player hasn't loaded libtooltipmenu?**
GZDoom will fail to parse any MENUDEF that references the unknown class and
skip that menu. The rest of your mod is unaffected. You can guard against this
with a conditional class reference if needed, but most mods simply list it as
a required companion file.

**Can I use TFLV_Tooltip on StaticText items?**
Only selectable items can be hovered, so a tooltip attached to a `StaticText`
will never appear. Attach tooltips to `Option`, `Slider`, `TextField`,
`ColorPicker`, and similar interactive items only.

**Can I attach one tooltip to multiple items?**
Yes — pass `n` to `PushTooltip` in ZScript: `PushTooltip("text", 3)` attaches
to the last 3 items pushed. In MENUDEF there is no equivalent; place an
identical `TFLV_Tooltip` after each item.

**Do changes to geometry or appearance require a menu restart?**
No. `TFLV_Tooltip.Draw()` reads all CVars fresh on every frame. Adjusting a
slider immediately moves the tooltip on screen.

**Is there a per-mod override system?**
Not in this version. The global override CVars (`tflv_tt_x`, `tflv_tt_colour`,
etc.) apply to all mods simultaneously. Per-mod overrides were a feature of an
earlier version of this library and may return in a future release.
