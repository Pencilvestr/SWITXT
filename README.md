<div align="center">

# SWITXT
### Switch positions. Clear status.

Display custom, color-coded text on your EdgeTX home screen.

**Three assignments · Custom text & colors · Automatically centered**

[Install](#installation) · [Configure](#configuration) · [Screenshots](#screenshots) · [Report an issue](https://github.com/Pencilvestr/SWITXT/issues)

</div>

---

SWITXT is a lightweight Lua widget that turns switch positions into readable status labels. Use it to show messages such as **ARMED**, **DISARMED**, or **MOTOR OFF**, with a separate text color for each assignment.

## At a glance

- **Three independent assignments:** choose a switch position, message, and color for each.
- **Centered labels:** text is centered horizontally and vertically within the widget area.
- **Simple setup:** configure the widget directly on your radio.

The script identifies its intended platform as **RadioMaster TX16S MK3 running EdgeTX 2.12.x**. Compatibility with other radios or firmware versions has not been confirmed here.

## Screenshots

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

The folder layout follows the [EdgeTX widget script documentation](https://luadoc.edgetx.org/edgetx-v2.8/part_i_-_script_type_overview/widget_scripts).

## Configuration

Each assignment has three options:

| Assignment | Switch position | Display text | Text color |
| :--- | :--- | :--- | :--- |
| 1 | `Switch1` | `Text1` | `Color1` |
| 2 | `Switch2` | `Text2` | `Color2` |
| 3 | `Switch3` | `Text3` | `Color3` |

Choose a switch position for each assignment you want to use, then enter its label and select its color. Switches are unassigned by default.

### Example setup

| Switch position | Text | Color |
| :--- | :--- | :--- |
| SD ↑ | ARMED | Green |
| SD ↓ | DISARMED | Red |
| SF ↓ | MOTOR OFF | Yellow |

These are example labels; configure the switch positions to match your model.

**Display priority:** SWITXT checks assignments in order: **1 → 2 → 3**. If multiple assigned positions are active, only the first matching assignment is displayed. If none match, the widget displays no text.

## Troubleshooting

| What you see | What to check |
| :--- | :--- |
| SWITXT is missing from the widget list | Confirm the file is at `/WIDGETS/SWITXT/main.lua`, then restart the radio. |
| No text appears | Assign a switch position, make that position active, and check that its text is not empty. |
| A different label appears than expected | Check whether an earlier assignment is also active; the first match takes priority. |
| Text is difficult to read | Choose a color that contrasts with your theme and use a larger widget area or shorter label. |

## Feedback

Have an idea or found a problem? [Open an issue](https://github.com/Pencilvestr/SWITXT/issues) and include your radio model, EdgeTX version, widget settings, and a screenshot if helpful.
