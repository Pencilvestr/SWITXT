<div align="center">

# SWITXT
### Switch positions. Clear status.

Display custom switch-status text on color and monochrome EdgeTX radios.

**Three assignments · Adaptive text · Color widget & monochrome screen**

[Install](#installation) · [Configure](#configuration) · [Screenshots](#screenshots) · [Report an issue](https://github.com/Pencilvestr/SWITXT/issues)

</div>

---

SWITXT is a lightweight Lua widget that turns switch positions into readable status labels. Use it to show messages such as **ARMED**, **DISARMED**, or **MOTOR OFF**, with a separate text color for each assignment on color radios.

## At a glance

- **Three independent assignments:** choose a switch position, message, and color for each.
- **Adaptive labels:** text is centered and sized to fit the available area. Labels that are still too long use a visible `...` suffix.
- **Two screen families:** a color home-screen widget and a separate monochrome telemetry screen.

## Compatibility

SWITXT 1.3 targets **EdgeTX 2.11 and later with Lua enabled**. Choose the version for your display:

| Your display | Version | Configuration |
| :--- | :--- | :--- |
| Color, landscape or portrait | [main.lua](main.lua) | Switch positions, labels, and colors in Widget settings |
| Monochrome 128×64 or 212×64 | [mono/switxt.lua](mono/switxt.lua) | Logical switches per model; labels edited in the script |

Layout follows the available screen area rather than a radio model name. **Eight native EdgeTX 2.12.5 simulator targets pass**, spanning five color radios and three monochrome radios. Physical-radio testing remains pending. See the [compatibility notes and test checklist](docs/compatibility.md) for the exact targets and limitations.

## Screenshots

Screenshots below show the original color widget. The [native simulator gallery](docs/native-screenshots.md) shows this update on color and monochrome targets using synthetic test models.

<p align="center">
  <img src="Images/screen-2026-08-18-100929.png" alt="SWITXT screenshot 1 on the radio display" width="480">
</p>

<table>
  <tr>
    <td width="50%"><img src="Images/screen-2026-08-18-100947.png" alt="SWITXT screenshot 2 on the radio display" width="480"></td>
    <td width="50%"><img src="Images/screen-2026-08-18-100950.png" alt="SWITXT screenshot 3 on the radio display" width="480"></td>
  </tr>
</table>

## Installation

### Color radios

1. Download [main.lua](https://github.com/Pencilvestr/SWITXT/raw/refs/heads/main/main.lua) and keep its filename as `main.lua`.
2. On your radio's SD card, create a folder named `SWITXT` inside `WIDGETS`.
3. Copy the file into that folder:

   ```text
   WIDGETS/
   └── SWITXT/
       └── main.lua
   ```

4. Safely disconnect the SD card or radio, then restart the radio to load the widget.
5. In your home-screen layout settings, add **SWITXT** to a widget area and open its settings.

When upgrading, replace only `main.lua` in the existing folder and restart. The nine option names and their order are unchanged, preserving the existing widget configuration.

### Monochrome radios

1. Download [mono/switxt.lua](https://github.com/Pencilvestr/SWITXT/raw/refs/heads/main/mono/switxt.lua).
2. Copy it to `/SCRIPTS/TELEMETRY/switxt.lua` on the SD card. Keep the filename at six characters or fewer before `.lua`.
3. In your model's telemetry/display screen settings, set an available screen to **Script** and select **switxt**.
4. Configure the model's **L01**, **L02**, and **L03** logical switches as described below.
5. Open that telemetry screen to view the label.

Monochrome radios use a telemetry screen rather than a home-screen widget. They display text without colors.

Installation locations follow EdgeTX's [widget](https://luadoc.edgetx.org/2.9/part_i_-_script_type_overview/widget_scripts) and [telemetry script](https://luadoc.edgetx.org/overview/script-types/telemetry-scripts.md) interfaces.

## Configuration

### Color widget

Each assignment has three options:

| Assignment | Switch position | Display text | Text color |
| :--- | :--- | :--- | :--- |
| 1 | `Switch1` | `Text1` | `Color1` |
| 2 | `Switch2` | `Text2` | `Color2` |
| 3 | `Switch3` | `Text3` | `Color3` |

Choose a switch position for each assignment you want to use, then enter its label and select its color. Switches are unassigned by default.

#### Example setup

| Switch position | Text | Color |
| :--- | :--- | :--- |
| SD ↑ | ARMED | Green |
| SD ↓ | DISARMED | Red |
| SF ↓ | MOTOR OFF | Yellow |

These are example labels; configure the switch positions to match your model.

**Display priority:** SWITXT checks assignments in order: **1 → 2 → 3**. If multiple assigned positions are active, only the first matching assignment is displayed. If none match, the widget displays no text.

### Monochrome telemetry screen

The default labels are driven by logical switches, so the same script can be used across radio models with different physical switches:

| Logical switch | Default text |
| :--- | :--- |
| L01 | ARMED |
| L02 | DISARMED |
| L03 | MOTOR OFF |

Configure each logical switch to become true for the model condition you want to show. Use the radio's actual switch positions when configuring those conditions. If more than one is true, the first assignment wins.

To change a label, edit the `assignments` table near the top of `switxt.lua`. You can also replace a switch name with another valid EdgeTX switch-position name; use `switch = ""` to disable an entry. Logical names such as `L01` avoid special-character entry and keep physical switch mapping in the model settings.

Text edits apply to all models using that same file. For different labels on different models, keep separate copies with different filenames of six characters or fewer, and select the appropriate script for each model. Restart the radio after editing script files.

### Text sizing

Color labels use the largest of the standard font sizes that fits, including in full-screen mode and top-bar areas. Very small areas that cannot fit even `...` draw no label. Monochrome labels use a large font when its character set and width allow it, then normal or small text. Unsupported glyphs still depend on the firmware language and fonts.

## Troubleshooting

| What you see | What to check |
| :--- | :--- |
| SWITXT is missing from the widget list | Confirm the file is at `/WIDGETS/SWITXT/main.lua`, then restart the radio. |
| No text appears | Assign a switch position, make that position active, and check that its text is not empty. |
| A different label appears than expected | Check whether an earlier assignment is also active; the first match takes priority. |
| Text is difficult to read | On color radios, choose a contrasting color. Use a larger area or a shorter label if text is small or ends in `...`. |
| The monochrome screen is blank | Configure L01/L02/L03 for this model and make the desired condition true. A blank or inactive assignment displays no text. |
| The monochrome screen says “Check switch names” | Check the names in the script's `assignments` table. Unavailable or misspelled switch names prevent normal display. |
| A script cannot be selected | Use the installation location for your screen family and confirm the firmware has Lua enabled. |

## Feedback

Have an idea or found a problem? [Open an issue](https://github.com/Pencilvestr/SWITXT/issues) and include your radio model, EdgeTX version, widget settings, and a screenshot if helpful.

