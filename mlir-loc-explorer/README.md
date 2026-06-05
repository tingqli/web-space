# MLIR Loc Explorer

A VS Code extension for side-by-side MLIR IR exploration with `loc("file":line:col)` cross-file navigation.

## Features

- Open all files from a selected directory in the explorer webview.
- Focus on `.mlir` files while keeping source files available for reference.
- Click `loc(...)` references to jump to source code in the workspace.
- Right-click any folder in Explorer and launch the tool with that folder as input.

## Commands

- `MLIR: Open Loc Explorer (Select Directory)`
- `MLIR: Open Loc Explorer Here`

## Enable python call-stack tracing based LOC

Take FlyDSL for example, add following code into your MLIR python binding based source:

```python
    # search following code and fix False with True
    # this will 
    #   -  add pass to pass loc to llvm ir:  ensure-debug-info-scope-on-llvm-func{emission-kind=LineTablesOnly}
    #   - add "-g" to pass gpu-module-to-binary, so assembly has line-number too
    enable_debug_info = OptBool(True, description="Generate debug info in compiled code")
```

```python
from flydsl._mlir import ir

def compile(...):
    ....
    ir._globals.register_traceback_file_inclusion(__file__)
    ir._globals.register_traceback_file_exclusion(r"/root/path/prefix/to/exclude")
    ir._globals.set_loc_tracebacks_frame_limit(40)
    ir._globals.set_loc_tracebacks_enabled(True)
    ....

```

Run your test with mlir dumpping:

```bash
FLYDSL_DUMP_ASM=1 FLYDSL_DUMP_IR=1 FLYDSL_DUMP_DIR=dump_ir python3 your_test.py ...
```

Check folder `dump_ir`, right-click the dump folder of your kernel, choose `MLIR: Open Loc Explorer`.

## Build

```bash
npm install
npm run compile
```

## Package

```bash
npm run package
```

This produces a `.vsix` package in the extension root.

## Publish

1. Create/verify your Visual Studio Marketplace publisher (`ltqusst`).
2. Create a Marketplace PAT under Azure DevOps org `ltq18` (you can start from: https://dev.azure.com/ltq18/_usersSettings/tokens).
3. Export your Marketplace token in the current shell:

```bash
export VSCE_PAT="<your-marketplace-token>"
```

4. (Optional) Verify PAT access:

```bash
npx @vscode/vsce verify-pat -p "$VSCE_PAT"
```

5. Publish:

```bash
npm run publish
```
