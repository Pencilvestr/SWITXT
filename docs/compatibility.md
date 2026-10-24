# Compatibility and validation

SWITXT 1.3 targets EdgeTX 2.11 and later on radios with Lua scripting enabled.
There are two entry points because EdgeTX uses different interfaces for color
widgets and monochrome telemetry screens. A radio's inclusion in EdgeTX's
[supported-radio list](https://edgetx.org/supportedradios/) does not mean this
project has been tested on that radio.

| Screen family | Entry point | SD-card destination | Design coverage |
| :--- | :--- | :--- | :--- |
| Color, landscape or portrait | `main.lua` | `/WIDGETS/SWITXT/main.lua` | Layout follows the live widget zone; full-screen mode uses `LCD_W`/`LCD_H`. |
| Monochrome 128×64 | `mono/switxt.lua` | `/SCRIPTS/TELEMETRY/switxt.lua` | Text font and length adapt to `LCD_W`. |
| Monochrome 212×64 | `mono/switxt.lua` | `/SCRIPTS/TELEMETRY/switxt.lua` | Same entry point; no radio-model detection. |

The color widget uses the `SWITCH` option picker, so available positions come
from the current radio. The monochrome script resolves switch names using
`getSwitchIndex`, rather than assuming numeric IDs are portable. Its defaults
use logical switches L01, L02, and L03, which can be configured independently
for each model.

Monochrome displays cannot reproduce the color settings. Their script uses
text alone and does not call color LCD functions. Large monochrome fonts have
a limited character set, so labels containing other punctuation or non-ASCII
characters use the normal or small font. Glyph availability still depends on
the firmware's fonts and language.

## Checks performed

The automated suite in `tests/run.lua` checks:

- Existing color option names, order, and defaults.
- Assignment priority, including an empty higher-priority label.
- Unassigned, inactive, unavailable, and inverted switch IDs.
- Missing color values and a valid zero-valued color.
- Landscape, portrait, high-resolution, offset, resized, and very small zones.
- Full-screen entry and return to the normal widget zone.
- Per-instance measurement caching and configuration updates.
- Visible truncation without splitting UTF-8 characters.
- 128×64 and 212×64 monochrome logic using only monochrome LCD functions.
- Monochrome configuration errors, font selection, and clearing inactive labels.

Run from the repository root with Lua 5.2 or later:

```sh
lua tests/run.lua
```

The tests use stubbed EdgeTX APIs and synthetic font measurements. They verify
script behavior, not firmware loading, actual glyph rendering, available memory,
or a manufacturer's firmware build. Automated layout checks include color areas
of 480×272, 480×320, 320×480, and 800×480, plus smaller widget zones.

No radio or EdgeTX simulator acceptance test has been completed for this change.

## Radio/simulator acceptance checklist

For each target radio and firmware version, record the result before marking
it verified:

1. Confirm that Lua is enabled, install the correct entry point, and restart.
2. Select the widget or telemetry screen and confirm there is no script error.
3. Activate each assignment separately, then activate multiple assignments and
   confirm that assignment 1 wins over 2, and 2 over 3.
4. Turn all assignments off and check that no old label remains.
5. On color radios, test a small zone, the top bar, a larger zone, and full-screen
   mode; change the layout and confirm centering and font fitting.
6. On monochrome radios, configure the model's L01/L02/L03 and check all labels.
7. Try long labels and check the font fallback and visible `...` truncation.
8. Save the model, restart, and check that settings still load correctly.

| Radio | Screen | EdgeTX version | Result |
| :--- | :--- | :--- | :--- |
| Hardware / simulator acceptance | — | — | Pending |

## API sources reviewed

- [EdgeTX 2.11 widget option capacity](https://github.com/EdgeTX/edgetx/blob/v2.11.0/radio/src/gui/colorlcd/mainview/widgets_container.h)
- [EdgeTX 2.11 color LCD API](https://github.com/EdgeTX/edgetx/blob/v2.11.0/radio/src/lua/api_colorlcd.cpp)
- [EdgeTX 2.12 color LCD API](https://github.com/EdgeTX/edgetx/blob/v2.12.0/radio/src/lua/api_colorlcd.cpp)
- [EdgeTX 2.11 switch API and exported constants](https://github.com/EdgeTX/edgetx/blob/v2.11.0/radio/src/lua/api_general.cpp)
- [EdgeTX 2.12 switch API and exported constants](https://github.com/EdgeTX/edgetx/blob/v2.12.0/radio/src/lua/api_general.cpp)
- [EdgeTX monochrome LCD drawing](https://github.com/EdgeTX/edgetx/blob/v2.12.0/radio/src/gui/128x64/lcd.cpp)
- [Widget script interface](https://luadoc.edgetx.org/2.9/part_i_-_script_type_overview/widget_scripts)
- [Telemetry script interface](https://luadoc.edgetx.org/overview/script-types/telemetry-scripts.md)
