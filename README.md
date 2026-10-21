# pnpm: hoisted installs re-import patched packages and their peer dependents

With `nodeLinker: hoisted`, pnpm leaves a package already in place alone on the
next install. pnpm 12 makes an exception for a patched package, and also for
every package whose peers include a patched one, since its dependency path
carries the peer's `patch_hash`. Every install that reaches the linker imports
them again.

Here `react` is patched and `react-dom` peers on it. Adding one unrelated,
dependency-free package should import that package only.

## Run

```sh
./repro.sh                      # the pnpm on PATH
./repro.sh path/to/pnpm         # any other pnpm binary
```

The script copies the project to a temporary directory, installs, adds
`is-number`, and checks whether `node_modules/react` and
`node_modules/react-dom` are still the same directories.

## Results

| pnpm    | `pnpm add is-number` | `react`, `react-dom` |
| ------- | -------------------- | -------------------- |
| 10.34.7 | `Packages: +1`       | left in place        |
| 11.28.6 | `Packages: +1`       | left in place        |
| 12.4.0  | `Packages: +4`       | imported again       |
| 12.14.0 | `Packages: +3`       | imported again       |

Expected:

```
Packages: +1
ok:   node_modules/react was left in place
ok:   node_modules/react-dom was left in place
```

Actual (pnpm 12.14.0):

```
Packages: +3
FAIL: node_modules/react was imported again
FAIL: node_modules/react-dom was imported again
```

Without `patchedDependencies`, pnpm 12.14.0 prints `Packages: +1` too.

In a React Native app, every package peering on a patched `react-native` or
`expo` follows: 115 packages imported again on each such install.
