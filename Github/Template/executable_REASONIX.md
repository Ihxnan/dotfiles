# REASONIX.md

## Stack
- **Language:** C++17/20 (GCC extensions), header-only `.hpp` templates
- **Target:** ACM-XCPC competitive programming (no production usage)
- **No build system, no test runner, no CI, no lint**

## Layout
| Path | Contents |
|---|---|
| `DataStructure/` | DSU, Fenwick, SegmentTree, SparseTable, Bit (整数位封装,位移/位运算/比较/IO 重载齐全), BitSet (块类型可选 32/64/128 位), Treap (FHQ Treap 数组版: 插入/删除/排名/第k小/前驱/后继, 按值或按大小分裂) · TreapPtr (同 API 的指针版, 无需预估节点上限, 内存池+回收站自动管理) |
| `Graph/` | `MinCostFlow.hpp` (SPFA 朴素版, **默认**, 支持负权) + `MinCostFlowDijkstra.hpp` (Dijkstra + potentials 优化版) — min-cost max-flow (**0-indexed**) |
| `Tree/` | Heavy-Light Decomposition (embeds inline `SegmentTree`) |
| `Math/` | Combinatorics, Euler sieve, exgcd, Miller–Rabin, Pollard-Rho, linear basis, modint (`Mod.hpp`) |
| `String/` | Sequence automaton, string hash, trie, AhoCorasick (`String/AhoCorasick.md` 教程) |
| `Random/` | Random graph / data generator |
| `Debug/` | `dbg.hpp` — var-dump + assert + timer macros · `check.hpp` — 对拍/SPJ 校验（Error/WA/OK 输出 + chk_eq/chk_double/chk_token/chk_ge/chk_le + 三文件 `Checker`） · `check.cpp` — check.hpp 使用示例 |
| `Template/ihxnan.hpp` | Canonical solution skeleton with fast I/O + all macros |
| `symlink.py` | Creates flat symlinks → `/usr/local/include/` |

## Commands
- `sudo python3 symlink.py` — link all `.hpp` into `/usr/local/include/`
- `sudo python3 symlink.py -c` — clean + re-link
- `python3 symlink.py -d` — dry-run preview

No build, test, lint, or format commands exist.

## Conventions
- **1-indexed** — arrays run from 1..n, all structs allocate `n+1`
- **Globals via `Template/ihxnan.hpp`** — macros (`ls(x)`, `rs(x)`, `bi(x)`, `bl(x)`, `br(x)`, `fid(x,y)`/`gx(id)`/`gy(id)`, `rd0(x)`/`rd1(x)`) and type aliases (`ll`, `ul`, `lll`, `pii`, `pll`, `vi`, `vl`, etc.) are defined there, not in the `.hpp` headers
- **`#include <bits/stdc++.h>`** assumed by every `.hpp` — no standard library includes in headers
- **GCC extensions** — `__lg`, `std::__lg`, `__int128` used throughout
- **Debug gated by `#ifdef IHXNAN`** — `dbg.hpp` macros (`gdb()`, `gdbif()`, `gdb_assert()`, `TIME()`) are no-ops without the define

## Watch out for
- **`ls(x)` / `rs(x)` are NOT defined in `SegmentTree.hpp` or `HLD.hpp`** — they rely on macros from `Template/ihxnan.hpp`. Copying either header standalone requires prepending `#define ls(x) ((x) << 1)` / `rs(x) ((x) << 1 | 1)`.
- **`HLD.hpp` inlines its own `SegmentTree`** (not the one from `DataStructure/`). Changes to `DataStructure/SegmentTree.hpp` do NOT affect `Tree/HLD.hpp`.
- **`dbg.hpp` is included via `#include <dbg>`** (bare name, no path) — works because `symlink.py` creates a symlink at `/usr/local/include/dbg` → `Debug/dbg.hpp`. Must symlink before compiling with `-DIHXNAN`.
- **Template code is copy-pasted, not linked** — no CMake / Makefile / package manager. Every `.hpp` is meant to be dropped into a single-file solution.
- **`MillerRabin.hpp` and `PollarRho.hpp` define the same symbols** (`vi Bases`, `mul`, `qmi`, `is_prime`) — including both in one file causes redefinition errors.
- **`Mod.hpp` output with `Template/ihxnan.hpp`:** `IO::operator<<` 对非整数类型退回 `std::cout`，所以只要类型有 `ostream operator<<`（`Mod.hpp` 提供），`cout << Z` 可以编译并正确输出。注意退回路径每次会 flush 快写缓冲（略慢），热循环仍建议 `cout << x.val()`。`IO::operator>>` 对无法快读的类型同样退回 `std::cin` —— 注意：fin 的 `fread` 预读与这类 `std::cin` 混用可能错位（浮点已由 fin 自解析，int/float/char/string 混读是安全的）。
- **`Mod.hpp` `using Z = MInt<MOD>` is illegal** — `ihxnan.hpp` defines `MOD`/`mod` as runtime variables, and template args must be compile-time constants; use the literal `MInt<998244353>`. `inv()` is Fermat-based (`qmi(*this, mod-2)`), so a `MInt<0>` dynamic mod must also be prime; `MInt<0>::Mod` is the only defined specialization of the static member.
- **`Graph/MinCostFlow.hpp` and `Graph/MinCostFlowDijkstra.hpp` are 0-indexed** — exception to the 1-indexed convention; needs `vi`/`vvi`/`vb` from `Template/ihxnan.hpp`. SPFA 版是日常默认（支持负权），Dijkstra 版被卡时间时再换。
- **`BitSet.hpp` (DataStructure/) 是 0-indexed** — 位 0..N-1,与 `std::bitset` 一致;块类型仅支持 32/64/128 位无符号(`unsigned int`/`unsigned long long`/`unsigned __int128`)。**N ≤ 64 的题直接 `uint32_t`/`uint64_t` 位运算,不必用模板。**
