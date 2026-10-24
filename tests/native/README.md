# Native EdgeTX checks

This Windows x64 adapter reuses the direct LCD-framebuffer technique from
ELRS SignalView. It runs the official EdgeTX 2.12.5 simulator DLLs in isolated
processes, with the normal `lcdChange` / `lcdFlushed` handshake. It creates no
desktop window and does not require screen-capture permissions.

The exact MSVC x64 ABI is experimental. The adapter refuses changed binary
fingerprints. Runtime files are extracted from the fingerprint-checked official
release ZIP without executing its installer or modifying installed Companion.
See `binding-manifest.json` for the release URL and fingerprints, and
`ADAPTER-LICENSE.txt` for the reused adapter's MIT attribution.

## Reproduce

Use Python 3.10+ x64, Pillow, and full 7-Zip with NSIS extraction support:

```powershell
python -m pip install -r tests/native/requirements.txt
python tests/native/prepare_runtime.py --extractor "C:\Program Files\7-Zip\7z.exe"
python tests/native/run_tests.py
```

An existing official release ZIP can be supplied with `--archive PATH`.
`SWITXT_RUNTIME` can point to an already extracted, fingerprint-matching `bin`
directory. Restrict a run with `--radios tx16smk3 boxer`.

Results, logs, synthetic SD-card/model settings, and PNG captures are generated
under `work/native-results/`. Runtime binaries and generated settings are not
included in the installable widget or committed as runtime dependencies.
The fixture settings are synthetic test models, not personal radio backups.

## What the checks establish

- Both production Lua files load and execute unchanged in actual firmware.
- Native logical switches L01/L02/L03 drive the expected labels and priority.
- All-off conditions remove previously drawn text; this is checked in pixels.
- Color labels fit actual firmware font measurements, including a small area
  and long-label truncation.
- Color full-screen entry and exit occur through native simulator input and
  generate the expected real event values.
- 128×64 monochrome frames use page-packed bits; 212×64 frames use four-bit
  grayscale pixel pairs. Color frames are decoded from RGB565.

The test observer loads the unchanged production entry point and records its
drawing calls. Color option values are seeded in model fixtures, and logical
switch conditions are changed through the native model API. The observer does
not replace the native switch evaluation or LCD functions with stubs.

These are simulator tests on version 2.12.5, not physical-radio tests or proof
of every firmware release. Interactive option editing, settings after restart,
long-duration endurance, other concurrent scripts, and hardware performance
are not established by this suite.
