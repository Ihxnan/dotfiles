# AGENTS.md

ACM-XCPC competitive programming template library — header-only C++ `.hpp` files by category. Best usage/API reference for every header: `打印/*.md` (printable Chinese docs, most up-to-date).

## Project
- **Stack:** C++17 for submission, C++20 for debug mode; GCC extensions (`__lg`, `__int128`). Templates are copy-pasted into single-file solutions — no build system, no test runner, no CI, no lint.
- **Python equivalent:** `Template/ihxnan.py` (fast-I/O helpers `I()`/`II()`/`MII()`/`LII()`/`GMI()`/`LGMI()`).
- **Verify header changes by compiling** a scratch solution both ways: `g++ -std=c++17 -O2` (submission) and `g++ -std=c++20 -O2 -DIHXNAN` (debug). Baseline results in `Template/test_report.md`.

## Commands
- `sudo python3 symlink.py` — flat-link every `.hpp` to `/usr/local/include/<name-without-.hpp>` (enables `#include <ihxnan>`, `#include <dbg>`). Recurses all dirs — re-run after adding files. Root required unless `-d`.
- `sudo python3 symlink.py -c` — clean + relink. `-d` dry-run, `-v` verbose.
- Duplicate basenames: only the first (sorted) is linked, with a warning.

## Starting point: `Template/ihxnan.hpp`
- Solution skeleton: `bits/stdc++.h`, macros (`endl`, `ls`/`rs`, `bl`/`bi`/`br`, `fid`/`gx`/`gy`, `rd0`/`rd1`), aliases (`ll`, `ul`, `lll`, `ld`, `vb`, `vi`, `vvi`, `vl`, `pii`, `pll`, `ti`, `tl`), constants (`iINF=0x3f3f3f3f`, `mod=998244353`, `lINF`, `MOD=1000000007`), and `int t=1; void solve();` multi-case `main`.
- Fast I/O: without `-DIHXNAN`, `cin`/`cout` are `#define`d to `fin`/`fout` (fread/fwrite). Integers/`char`/`string` only — `double` etc. fail at compile time in **both** modes (no "compiles locally, fails on judge"). Don't mix `printf` with the buffered writer.
- `-DIHXNAN` pulls in `Debug/dbg.hpp` (`gdb()`, `gdbif()`, `gdb_assert()`, `TIME()`; needs **`-std=c++20`** for `source_location`) plus a twin `IO` with identical behavior. But the submission-mode no-op fallbacks cover only `gdb`/`TIME` — using `gdbif`/`gdb_assert` without `-DIHXNAN` is a compile error.
- Under `-DIHXNAN` never write `std::cin`/`std::cout` (they're macros). New `.hpp` files must compile when included after `Template/ihxnan.hpp`.

## Structure
| Path | Contents |
|---|---|
| `DataStructure/` | `DSU`, `Fenwick`, `SegmentTree`, `ST` (sparse table), `Bit` (`bit<T>` integer-bit wrapper), `Treap` (FHQ, array), `TreapPtr` (same API, pointers, pool + trash, no node-count pre-estimate), `Mo` (片段式: 普通/带修/回滚莫队 + 值域分块 mex) |
| `Graph/` | `MaxFlow` (Dinic), `MinCostFlow` (SPFA, **default**), `MinCostFlowDijkstra` (potentials, TLE fallback), `SCC`, `EBCC`, `BlockCutTree`, `TwoSat`, `MaxAssignment` (KM), `Hungarian`, `HLD` |
| `Math/` | `Comb`, `EulerPrime`, `Exgcd`, `LinearBasis`, `MillerRabin`, `PollarRho` (MillerRabin superset + factorization), `Point` (point/line/polygon/half-plane) |
| `String/` | `KMP` (fail / z / automaton), `StrHash` (natural overflow), `Trie` (62-char: a-z A-Z 0-9), `AhoCorasick` (lowercase), `SequenceAM` (struct `SqAM`), `SuffixArray` |
| `Random/` | `Generator.hpp` — standalone: own includes + `using namespace std` |
| `Debug/` | `dbg.hpp` (+ docs) |
| `Template/` | `ihxnan.hpp`, `ihxnan.py`, `cpp.json` (VS Code snippet, trigger `acm`), `test_report.md` |
| `打印/` | per-category usage docs: 00 skeleton, 01 DS, 02 graph, 03 math, 04 string; `md2pdf.py` regenerates `pdf/*.pdf` (each `##` template starts a new page) plus merged `pdf/ACM模板合集.pdf` with a cover + TOC, page numbers, and bookmarks (needs pandoc, chromium, poppler; `pip install --user --break-system-packages pypdf reportlab`) |
| `symlink.py` | see Commands |

## Indexing is mixed — check per header
- **0-indexed:** all flow/SCC-family structs in `Graph/` (`MaxFlow`, `MinCostFlow`, `MinCostFlowDijkstra`, `SCC`, `EBCC`, `BlockCutTree`, `TwoSat`, `MaxAssignment`), plus `String/StrHash.hpp` and `String/SuffixArray.hpp`.
- **1-indexed:** everything in `DataStructure/` (structs allocate `n+1`; `Mo.hpp` is a 1-indexed snippet), `Graph/HLD.hpp` (root = 1), `Graph/Hungarian.hpp` (`match[p]==0` = unmatched), `String/KMP.hpp` — KMP expects a placeholder at `str[0]` (build as `" " + s`), returns `fail`/`z` over 1..n.
- `Trie`/`AhoCorasick` use their own node numbering — see `打印/04-字符串.md`.

## Conventions
- Macros/aliases/constants come from `Template/ihxnan.hpp`, never from individual headers. All headers assume `bits/stdc++.h` is already included (exception: standalone `Generator.hpp`).
- `DataStructure/SegmentTree.hpp` uses `ls()`/`rs()` macros — copying it standalone requires prepending `#define ls(x) ((x) << 1)` / `#define rs(x) ((x) << 1 | 1)`.
- `bi`/`bl`/`br` need `blen` (and `n` for `br`) in scope; `fid`/`gx`/`gy` need `m`.
- File-scope state to watch when pasting several headers into one solution: `EBCC.hpp` declares global `set<pii> E` (collects bridges), `EulerPrime.hpp` declares `vi prime; vector<bool> is_prime;`.
- `Math/Exgcd.hpp`, `Graph/Hungarian.hpp` and `DataStructure/Mo.hpp` are snippet-style (file-scope / `solve()` fragments assuming globals like `n`/`arr`/`adj`/`blen` already exist), not reusable structs — drop them into the solution body.

## Watch out for
- **Both min-cost-flow headers define `struct MinCostFlow`** — include at most one. SPFA version is the daily default (negative costs OK without negative cycles; `flow(s,t,k=iINF)` accepts a flow limit); switch to Dijkstra only on TLE (no negative edges guaranteed).
- **`MillerRabin.hpp` + `PollarRho.hpp` clash** (`Bases`, `mul`, `qmi`, `is_prime`) — never include both; PollarRho is the superset (adds `factorize`).
- **`Graph/HLD.hpp` is pure HLD** — no embedded segment tree, no `ls`/`rs`. Provides `lca`, `dist`, `jump`, `isAncester`, `rootedParent/Size/Lca`, plus `in`/`out`/`seq` (Euler order) for binding your own segment tree.
- **`MaxAssignment` (KM):** asserts `nx ≤ ny` and non-negative weights.
- **Stale sibling docs:** `README.md`, `REASONIX.md`, `Debug/README.md`, `Debug/REASONIX.md` still reference deleted files (`Tree/`, `Mod.hpp`, `BitSet.hpp`, `check.hpp`, `AhoCorasick.md`) — trust the directory listing, `打印/`, and this file.
