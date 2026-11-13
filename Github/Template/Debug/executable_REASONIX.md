# dbg.hpp — 竞赛调试头文件

> `Debug/` 目录下还有 `check.hpp` — 对拍 / SPJ 校验辅助头文件（详见下文）。
>
> 本文档标题沿袭旧名，实际同时覆盖 `dbg.hpp` 与 `check.hpp`。

## Stack

- **Language** — C++17（核心） / C++20（`DbgStream` 需 `source_location`）
- **Platform** — Linux（POSIX, `execinfo.h` 用于 backtrace）
- **Dependencies** — 零外部依赖，仅标准库 + POSIX
- **Size** — `dbg.hpp` 单文件 ~29KB, ~890 行；`check.hpp` ~8KB, ~230 行

## Layout

- `dbg.hpp` — 全部调试库代码（单头文件）
- `check.hpp` — 对拍 / SPJ 校验辅助库（单头文件，自带 `#include <bits/stdc++.h>` + `using namespace std;`）
- `check.cpp` — `check.hpp` 的使用示例（对拍"两数之和"）
- `README.md` — 使用文档和完整示例

## Commands

头文件库，无构建系统 / 测试 / lint 脚本。`check.cpp` 可直接编译运行：

```bash
g++ -O2 -std=c++17 Debug/check.cpp -o check
./check <in.txt> <ans.txt> <out.txt>
```

## Conventions

- 所有调试宏通过 `#ifdef IHXNAN` 门控，未定义时展开为 `((void)0)`（零开销）
- 类型检测使用 SFINAE 函数重载（`_DBG_DETECT` 宏），而非 `void_t`
- `dbg_print` 的 `if constexpr` 分支顺序固定：`nullptr → string/char* → ... → iterable → streamable → [?]`
- 嵌套容器深度 ≥1 时自动换行缩进（`DBG_INDENT=2` 空格）；`vector<vector<简单类型>>` 自动转为网格格式
- 递归深度上限 `MAX_DBG_DEPTH=10`，超限打印 `"..."`
- 所有调试输出前先 `cout.flush(); fflush(NULL)` 确保与 `cout`/`putchar` 输出流同步
- GCC 16 兼容：`_dbg_print_tuple` 使用递归展开而非折叠表达式
- 输出默认走 `stdout`，可 `dbg_set_output(FILE*)` 重定向
- **`check.hpp` 输出统一走 `fprintf`/`fputs` 到 `stdout`（FILE\* 接口）**，不用 `cout`——`ihxnan.hpp` 会把 `cout` 宏重定义为 `fout`，check.hpp 因此不受影响，可与 `ihxnan.hpp` 同文件混用
- **`Checker::read_t()` 只从输入文件读 `t`**——标准答案 / 选手输出文件不含 `t`，直接是数据（原 `check.cpp` 语义）

## Watch out for

- **C 数组**（`int arr[5]`）由独立重载 `dbg_print(T (&arr)[N])` 处理，不在主模板的 `if constexpr` 链中——因为数组传参会退化为指针
- **malloc 数组**（`int* p = (int*)malloc(n)`）不支持直接打印，需用 `std::span(p, n)` 包装
- **`private: #define`** 在用户模板（非 IHXNAN）中将 `cin`/`cout` 重定义为 `fin`/`fout`；IHXNAN 下 dbg.hpp 定义与提交模式**完全同逻辑**的 `struct IO`（inc→getchar、outc→紫色 `dbg_putchar`，回车即生效、无需 EOF），`cin`/`cout` 宏同样指向 `fin`/`fout`，类型支持与提交模式完全一致（整数/char/string 快读写，`double` 等其余类型编译期报错，本地即可发现）——勿与 dbg.hpp 自身的宏混淆
- **GCC 16 可能有的问题**：当前已处理了 tuple 折叠表达式，但如果遇到模板偏特化 `void_t` 编译失败，`is_specialization_of` 系列结构体是后备方案
- **`check.hpp` 的输出函数都是 `printf` 风格可变参数**（如 `chk_fail(test, "%s mismatch: %d", ...)`）——`%lld` 配 `long long`，不要传 `int` 到 `%lld`
- **`chk_rest` 与 `ensure_eof` 二选一**：`chk_rest` 会把答案/输出流读到 EOF，之后再调 `ensure_eof` 无意义
- **`ensure_eof` 不检查输入文件**——checker 往往只读输入的一部分（如只读 `t`），输入有余量是正常现象
- include <bits/stdc++.h>
/* ──▶  INCLUDE  ◀── */
// #define MULTIT
#include <ihxnan>
/* ──▶  /INCLUDE  ◀── */
struct A
{
    int a;
    int b;
    int c;
};
DBG_STRUCT(A, r, r.a, r.b, r.c);

/* ╔══════════ SOLVE ══════════╗ */
void solve()
{
    A a;
    gdb(a);
}
/* ╚══════════ /SOLVE ══════════╝ */
