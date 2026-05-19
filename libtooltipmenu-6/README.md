# libtooltipmenu

A ZScript library for GZDoom / UZDoom that adds hover tooltips to option menus,
plus a global override system that lets players reposition and restyle every
tooltip in every loaded mod from one central settings page.

Requires GZDoom 4.11+ or a compatible fork (UZDoom 4.14+).

---

## What it does

**For players:** Adds an **Options → Tooltip Appearance** menu. When *Tooltip
Overrides* is On, every tooltip in every mod that uses this library follows the
global position, size, and style you set there — live, with no restart. The
menu itself shows a working tooltip as you adjust sliders so you can see the
effect in real time.

**For mod authors:** Drop-in base classes (`TFLV_TooltipOptionMenu`,
`TFLV_TooltipListMenu`) that replace GZDoom's built-in `OptionMenu` and
`ListMenu`. Add `TFLV_Tooltip "text"` after any menu item to attach a tooltip
to it. One `TFLV_TooltipGeometry` and one `TFLV_TooltipAppearance` line set
your mod's default look. The player's global overrides layer on top
automatically — you don't write any CVar-reading code yourself.

---

## File layout

```
libtooltipmenu.pk3
├── CVARINFO.txt                          global override CVars
├── MENUDEF.txt                           adds Tooltip Appearance to Options menu
├── zscript.txt                           includes all ZScript files
└── zscript/libtooltipmenu/
    ├── Tooltips.zsc                      TFLV_Tooltip, TFLV_GlobalOverride, mixins
    ├── TooltipOptionMenu.zsc             TFLV_TooltipOptionMenu + helper items
    ├── TooltipListMenu.zsc               TFLV_TooltipListMenu  + helper items
    └── TooltipConfig.zsc                 the Tooltip Appearance settings menu
```

---

## Quick start for mod authors

### 1. Change your menu class

In your `MENUDEF.txt`, change `class OptionMenu` to `class TFLV_TooltipOptionMenu`
(or `TFLV_TooltipListMenu` for list-style menus):

```
OptionMenu "MyModOptions"
{
    class TFLV_TooltipOptionMenu          // ← was: (nothing, or class OptionMenu)
    Title "My Mod"

    Option "Some Setting", "my_cvar", "YesNo"
    TFLV_Tooltip "What this setting does and why you might change it."

    Slider "Speed", "my_speed_cvar", 0.0, 5.0, 0.25, 2
    TFLV_Tooltip "Movement speed multiplier. 1.0 is the original value."
}
```

That's it. Players hovering over any item that has a `TFLV_Tooltip` line beneath
it will see your text. The global override system is automatic.

### 2. Set your mod's default appearance (optional)

Add `TFLV_TooltipGeometry` and/or `TFLV_TooltipAppearance` anywhere in the
menu block (order doesn't matter — they apply to all tooltips in that menu):

```
OptionMenu "MyModOptions"
{
    class TFLV_TooltipOptionMenu
    Title "My Mod"
    TFLV_TooltipGeometry 0.0, 0.5, 0.30, 1.0, 0.5    // x, y, w, xpad, ypad
    TFLV_TooltipAppearance "", "Gold", "MYMODBG"       // font, colour, texture

    Option "Some Setting", "my_cvar", "YesNo"
    TFLV_Tooltip "Explanation here."
}
```

If you omit these lines the library uses its built-in defaults:
left-anchored (`x=0.0`), vertically centred (`y=0.5`), 30% screen width
(`w=0.30`), white text on a default background.

### 3. That's all

You don't need to add CVars, write override logic, or touch `libtooltipmenu.pk3`.

---

## Player settings reference

All settings live in **Options → Tooltip Appearance**.

### Master switch

| Setting | CVar | Default |
|---|---|---|
| Tooltip Overrides | `tflv_tt_override_enabled` | On |

When Off, every mod reverts to its own built-in tooltip appearance instantly.

### Layout presets

| Value | Name | x | y | w | xpad | ypad |
|---|---|---|---|---|---|---|
| 0 | Custom | — | — | — | — | — |
| 1 | Left Panel | 0.0 | 0.5 | 0.30 | 1.0 | 0.5 |
| 2 | Right Panel | 1.0 | 0.5 | 0.30 | 1.0 | 0.5 |
| 3 | Bottom Bar | 0.5 | 1.0 | 0.70 | 1.5 | 0.5 |
| 4 | Top Bar | 0.5 | 0.0 | 0.70 | 1.5 | 0.5 |
| 5 | Centre Box | 0.5 | 0.5 | 0.40 | 1.5 | 0.75 |

Selecting any preset other than Custom disables the individual geometry sliders.

### Geometry

| Slider | CVar | Range | Meaning |
|---|---|---|---|
| X Position | `tflv_tt_x` | −1 to 1.0 | Horizontal anchor: 0.0=left, 0.5=centre, 1.0=right |
| Y Position | `tflv_tt_y` | −1 to 1.0 | Vertical anchor: 0.0=top, 0.5=middle, 1.0=bottom |
| Width | `tflv_tt_w` | −1 to 1.0 | Box width as fraction of virtual screen width |
| H Padding | `tflv_tt_xpad` | −1 to 4.0 | Horizontal padding, in em-widths |
| V Padding | `tflv_tt_ypad` | −1 to 2.0 | Vertical padding, in line-heights |
| Scale | `tflv_tt_scale` | −1 to 3.0 | Whole-tooltip size multiplier |

**−1 is the sentinel value** — it means "use whatever the mod author set". Set
a slider to −1 to stop overriding that field for all mods.

### Appearance

| Field | CVar | Sentinel | Meaning |
|---|---|---|---|
| Font | `tflv_tt_font` | `""` (blank) | Font lump name |
| Colour | `tflv_tt_colour` | `""` (blank) | Font colour name |
| Texture | `tflv_tt_texture` | `""` (blank) | Background texture lump name |

Leave any field blank to stop overriding it. See `MODDING.md` for font,
colour, and texture reference values.

---

## Compatibility

libtooltipmenu only hooks menus that explicitly use its classes. Mods that don't
include `class TFLV_TooltipOptionMenu` are unaffected. Multiple mods using the
library simultaneously share the one global settings page with no conflicts.

The `TFLV_TooltipID` and `TFLV_TooltipPage` keywords are accepted for backwards
compatibility with older versions of this library but are otherwise no-ops in
this release — there is no per-mod override system in this version.

---

## License

Public domain / CC0. Copy, modify, and redistribute freely, with or without
attribution.
