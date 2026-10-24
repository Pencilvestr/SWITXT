# Native simulator screenshots

These are direct LCD-framebuffer captures from the official, fingerprint-pinned
EdgeTX **2.12.5** simulator. They show SWITXT 1.3 with synthetic model settings
and native logical-switch conditions. The production Lua files were copied
unchanged. These are firmware renders, not mockups or physical-radio photographs.

Capture and source hashes are recorded in [native-verification.json](native-verification.json).
See [compatibility](compatibility.md) and the [native test guide](../tests/native/README.md).

## Color radios

| TX16S MK3 · 800×480 | TX16S · 480×272 |
| :--- | :--- |
| ![TX16S MK3 showing ARMED in full-screen mode](images/native-tx16smk3.png) | ![TX16S showing ARMED](images/native-tx16s.png) |

| TX15 · 480×320 | PA01 · 320×240 |
| :--- | :--- |
| ![TX15 showing DISARMED in red](images/native-tx15.png) | ![PA01 showing ARMED](images/native-pa01.png) |

### NV14 · 320×480 portrait

<img src="images/native-nv14.png" alt="NV14 portrait screen showing centered ARMED text" width="320">

## Monochrome radios

| Boxer · 128×64 | Pocket · 128×64 | X9D+ 2019 · 212×64 |
| :--- | :--- | :--- |
| ![Boxer showing ARMED](images/native-boxer.png) | ![Pocket showing MOTOR OFF](images/native-pocket.png) | ![X9D+ 2019 showing DISARMED](images/native-x9d2019.png) |

## Small-area fitting

The observer supplies an 80×40 area near the upper-left corner to the unchanged
color renderer. The remaining display area is intentionally blank.

| Short label | Long label, visibly shortened |
| :--- | :--- |
| ![ARMED fitted within a small area](images/native-small.png) | ![Long label fitted with an ellipsis](images/native-long-small.png) |

The automated suite also checks that inactive labels leave blank pixels,
configured colors render correctly, and full-screen entry and return use real
native event values. Physical-radio validation is still pending.
