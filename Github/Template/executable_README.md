ACM-XCPC Template
================

C++ header-only `.hpp` template library for competitive programming.

## Structure

| Directory | Files | Description |
|---|---|---|
| `DataStructure/` | `DSU.hpp` `Fenwick.hpp` `SegmentTree.hpp` `ST.hpp` | Disjoint Set Union, Fenwick tree, segment tree, sparse table |
| `Tree/` | `HLD.hpp` | Heavy-light decomposition (embedded segment tree) |
| `Math/` | `Comb.hpp` `EulerPrime.hpp` `IsPrime.hpp` `LinearBasis.hpp` | Combinatorics, Euler sieve, primality test, linear basis |
| `String/` | `SequenceAM.hpp` `Trie.hpp` | Sequence automaton, trie |
| `Random/` | `Generator.hpp` | Random graph / data generator |
| `Debug/` | `dbg.hpp` | Debug print utilities |

## Conventions

- 1-indexed — arrays run from 1 to n.
- Assumes `#include <bits/stdc++.h>` and GCC extensions (`__lg`, `std::__lg`).
- No build system, tests, or CI. Copy the needed `.hpp` into your solution.

## HLD Gotcha

`Tree/HLD.hpp` embeds a `SegmentTree<T>` that uses `ls(x)` / `rs(x)` macros defined in `DataStructure/SegmentTree.hpp:14-15`. When copying `HLD.hpp` alone, prepend:

```cpp
#define ls(x) ((x) << 1)
#define rs(x) ((x) << 1 | 1)
```

## Setup

`symlink.py` creates flat symlinks of all `.hpp` files into `/usr/local/include/` for global `#include` access:

```bash
sudo python3 symlink.py
```
