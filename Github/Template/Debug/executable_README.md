# dbg.hpp — 竞赛调试头文件

## 快速入手

```cpp
#ifdef IHXNAN
    #include <dbg>
#else
    #define gdb(...)              ((void)0)
    #define gdbif(c, ...)         ((void)0)
    #define gdb_assert(cond, msg) ((void)0)
    #define TIME(name)            ((void)0)
    #define gc() (p1==p2&&(p2=(p1=buf)+fread(buf,1,S,stdin),p1==p2)?EOF:*p1++)
#endif
```

---

## 宏一览

| 宏 | 作用 |
|---|---|
| `gdb(x, y, ...)` | 打印变量名和值，多变量逗号分隔一行 |
| `gdbif(cond, ...)` | 条件 gdb |
| `gdb_assert(cond, msg)` | 断言失败打印消息并 `exit(1)` |
| `TIME(name)` | RAII 计时器，离开作用域打印耗时 |
| `cin` / `cout`（IHXNAN 下） | `cin` 走 `getchar` 轻量快读（stdio 行缓冲，回车即生效、无需 EOF）；`cout` 重定向为紫色输出（随 `dbg_set_color` 开关），见下文"彩色 cout" |

## 函数/类型一览（非宏，需 C++20 或 POSIX）

| 名称 | 作用 | 依赖 |
|---|---|---|
| `DbgStream` | 流式输出 `[file:line]`，适合表达式打印 | C++20 `source_location` |
| `dbg_binary(os, val)` | 整数二进制打印（四位分组加下划线） | 无 |
| `Bench` | 多轮计时器，析构输出 run count / avg / min / max | 无 |
| `dbg_register_signal_handlers()` | 注册 SIGSEGV/SIGABRT/SIGFPE 处理器，崩溃时打印 backtrace | POSIX (`execinfo.h`) |
| `dbg_set_color(bool)` | 运行时开关 ANSI 颜色 | 无 |
| `fin`/`fout`（dbg.hpp 第 10 节定义，`cin`/`cout` 宏指向） | 与 `ihxnan.hpp` 的 `IO` 完全同逻辑（inc→getchar、outc→紫色 `dbg_putchar`）：整数/char/string 快读写，`double` 等其余类型与提交模式一样在编译期报错 | 无 |

> 首次触发任何调试输出时，会先打印一个空行，防止与前置 `cout` 输出粘连。
> 非宏的功能**不受** `#ifdef IHXNAN` / `#else` 分支控制——需要在 `#ifdef IHXNAN` 块内 `#include <dbg>`，否则不会被编译。

---

## 彩色 cout

配合 `Template/ihxnan.hpp` 使用：正常提交（非 IHXNAN）时 `cout` 被宏替换为 `fout` 快写（无色）；
`-DIHXNAN` 调试模式下 `cout` 自动输出**紫色**（与 `dbg_putchar` 同款，随 `dbg_set_color` 开关），
`cin` 走基于 `getchar` 的轻量快读 —— 不重定向到 `fin`（`fread` 快读从终端读数据会一直阻塞到
EOF，手敲输入必须补 Ctrl+D 之类的末尾符号）；`getchar` 走 stdio 行缓冲，回车即生效、无需 EOF，
且比标准 `std::cin` 少一层 C++ 流封装、更快。整数 / `char` / `string` 走 `getchar`，其余类型
（如 `double`）自动退回 `std::cin`。

```cpp
#ifdef IHXNAN
    cin >> n;                        // getchar 快读，回车即生效
    cout << "n = " << n << endl;     // 紫色输出（调试模式）
#else
    cin >> n;                        // fin 快读（提交模式）
    cout << n << endl;               // fout 快写，无色（正常提交）
#endif
```

注意：IHXNAN 下 `cout`/`cin` 被宏替换，**不要写 `std::cout` / `std::cin` / `std::endl`**（`endl` 被宏定义为 `'\n'`，宏替换会编译报错；换行写 `endl` 或 `'\n'` 即可）；
调试输出用 `cout`（紫色），正式输出建议用 `fout`（无色）区分。

---

## gdb

### 基础变量

```cpp
int n = 5, m = 10;
gdb(n, m);
// [main.cpp:42]
// n = 5, m = 10
```

### 顺序容器

```cpp
vi v = {1, 2, 3};
gdb(v);          // [main.cpp:42]
// v = [1, 2, 3]

deque<int> dq = {7, 8, 9};
gdb(dq);         // [main.cpp:42]
// dq = [7, 8, 9]

list<int> lst = {100, 200, 300};
gdb(lst);        // [main.cpp:42]
// lst = [100, 200, 300]

array<int, 4> arr = {0, 1, 2, 3};
gdb(arr);        // [main.cpp:42]
// arr = [0, 1, 2, 3]
```

### 关联容器

```cpp
set<int> st = {3, 1, 4};
gdb(st);         // [main.cpp:42]
// st = {1, 3, 4}

map<string, int> mp = {{"alice", 90}, {"bob", 85}};
gdb(mp);         // [main.cpp:42]
// mp = {"alice": 90, "bob": 85}
```

### 容器适配器

> 自动拷贝后遍历，原容器不受影响。

```cpp
stack<int> stk; stk.push(1); stk.push(2); stk.push(3);
gdb(stk);        // [main.cpp:42]
// stk = [3, 2, 1]    (弹栈顺序)

queue<int> q; q.push(10); q.push(20); q.push(30);
gdb(q);          // [main.cpp:42]
// q = [10, 20, 30]   (FIFO)

priority_queue<int> pq; pq.push(5); pq.push(2); pq.push(8);
gdb(pq);         // [main.cpp:42]
// pq = [8, 5, 2]      (优先级降序)
```

### 结构类型

```cpp
pair<int, double> p = {42, 3.14};
gdb(p);          // [main.cpp:42]
// p = <42, 3.14>

tuple<int, char, string> t = {1, 'x', "hello"};
gdb(t);          // [main.cpp:42]
// t = (1, 'x', "hello")

optional<int> opt = 7, nopt = nullopt;
gdb(opt, nopt);  // [main.cpp:42]
// opt = 7, nopt = nullopt

variant<int, string> var = "world";
gdb(var);        // [main.cpp:42]
// var = "world"

bitset<8> bs(42);
gdb(bs);         // [main.cpp:42]
// bs = 00101010

__int128_t big = (__int128_t)1e18 * 1e9;
gdb(big);        // [main.cpp:42]
// big = 1000000000000000000000000000
```

### 嵌套容器

> `vector<vector<T>>` 自动以网格格式输出（行列号红色高亮），其余嵌套容器多行缩进。

```cpp
vvi dp = {{1, 0}, {0, 1}};
gdb(dp);
// dp = 
//        0     1
//    0       1     0
//    1       0     1

vector<set<int>> vec_set = {{1, 2}, {3}};
gdb(vec_set);
// vec_set = [
//   {1, 2},
//   {3}
// ]
```

---

## gdbif — 条件调试

```cpp
gdbif(i > 100, i, arr[i]);    // 仅当 i > 100 时打印
```

---

## gdb_assert — 调试断言

```cpp
gdb_assert(cnt > 0, "cnt must be positive but got " + to_string(cnt));
// 失败输出: [file:line] ASSERT FAILED [...msg...]  然后 exit(1)
```

---

## TIME — 计时器

```cpp
{ TIME("dp"); solve(); }    // 离开作用域打印耗时
// [Timer] dp : 0.001234 s

TIME("sort"); sort(v.begin(), v.end());  // 单语句也适用
```

---

## dbg_print — 直接调用

```cpp
dbg_print(cerr, 42);              // 42
dbg_print(cerr, vector{1,2});     // [1, 2]
dbg_print(cerr, x); cerr << '\n'; // 手动换行
```

---

## DbgStream — 流式临时调试

适合打印表达式（无变量名）：

```cpp
DbgStream() << "partial = " << (a + b) * c;
// [main.cpp:42]
// partial = 42
```

> 需要 `-std=c++20`（`source_location`）。

---

## dbg_binary — 整数二进制打印

```cpp
dbg_binary(cerr, 0b10110110u);
// 0b1011_0110
```

---

## Bench — 多轮计时统计

对比两种做法时，多轮跑出 min / avg / max：

```cpp
Bench b("quick_vs_merge");
for (int t = 0; t < 10; ++t) {
    auto data = gen_data(1e6);
    b.start(); quick_sort(data); b.stop();
    b.start(); merge_sort(data); b.stop();
}
// [Bench] quick_vs_merge : 20 runs, avg 0.0123 s, min 0.0101 s, max 0.0145 s
```

---

## dbg_backtrace — 崩溃定位

在 `main()` 开头调一次，段错误/断言/浮点异常时自动打印调用栈：

```cpp
int main() {
    dbg_register_signal_handlers();
    // ...
}
// [CRASH] Caught SIGSEGV
// 0x... (调用栈)
```

> 编译加 `-g -rdynamic` 可获得函数名。仅 Linux（POSIX）。

---

## dbg_set_color — 运行时颜色开关

```cpp
dbg_set_color(false);   // 关闭所有 ANSI 颜色，适合输出重定向到文件
```

---

## 支持的容器/类型

- `pair`, `tuple`, `optional`, `variant`
- `vector`, `deque`, `list`, `forward_list`, `array`
- `set`, `multiset`, `unordered_set`
- `map`, `multimap`, `unordered_map`
- `stack`, `queue`, `priority_queue` (自动拷贝后遍历)
- `bitset`
- `__int128` / `__uint128`
- 所有有 `operator<<` 的基础类型
- 嵌套容器 (元素为容器时自动多行缩进)
- 整数二进制打印 (`dbg_binary`)

## 需要额外运行时支持的功能

| 功能 | C++ 标准 | 平台 |
|---|---|---|
| `DbgStream` | C++20 (`source_location`) | 全平台 |
| `dbg_backtrace` | C++11 | Linux（POSIX） |
| 其余全部 | C++17 | 全平台 |

---

# check.hpp — 对拍 / SPJ 校验辅助头文件

> `check.hpp` 与 `dbg.hpp` 同风格：单头文件，自带 `#include <bits/stdc++.h>` 和
> `using namespace std;`，无外部依赖。输出走 `fprintf`/`fputs` 到 `stdout`
> （FILE\* 接口），不受 `ihxnan.hpp` 的 `#define cout fout` 宏重定义影响，
> 可与 `ihxnan.hpp` 同文件混用。

## 快速入手

```cpp
#include <bits/stdc++.h>
#include "check.hpp"

int main(int argc, char *argv[])
{
    Checker ck(argv[1], argv[2], argv[3]);   // 输入, 标准答案, 选手输出
    int t = ck.read_t();                      // 测试组数（只从输入文件读）
    for (int i = 1; i <= t; ++i)
    {
        ll a = ck.read_ans<ll>(), b = ck.read_ans<ll>();
        ll c = ck.read_out<ll>(), d = ck.read_out<ll>();
        chk_eq(i, "a+b", a + b, c + d);       // 不符 → 打印 Error 并 exit(1)
    }
    ck.ensure_eof();                          // 选手输出不得有多余 token
    chk_ok(t);                                // OK: all 3 tests passed
}
```

完整可编译示例见 `Debug/check.cpp`（对拍"两数之和"）。

## 常用输出

失败统一以 `Error:` / `Wrong Answer:` 开头并 `exit(1)`，成功打印 `OK:` 并
`exit(0)`，便于脚本 grep 关键字与检查退出码。

| 函数 | 输出示例 |
|---|---|
| `chk_error("...")` | `Error: cannot open output file: out.txt` |
| `chk_fail(3, "...")` | `Error: on test 3 : a+b mismatch: expected 5, got 4` |
| `chk_wa(3, "...")` | `Wrong Answer: on test 3 : token 2 mismatch: expected "5", got "4"` |
| `chk_ok(3)` | `OK: all 3 tests passed` |

全部为 `printf` 风格可变参数（`chk_ok` 除外）。

## 比较断言

| 函数 | 语义 |
|---|---|
| `chk_eq(test, what, expected, got)` | 整数相等 |
| `chk_double(test, what, expected, got, eps=1e-6)` | 浮点相等（相对 eps） |
| `chk_token(test, what, expected, got)` | 字符串 / token 相等 |
| `chk_ge(test, what, expected, got)` | `got >= expected` |
| `chk_le(test, what, expected, got)` | `got <= expected` |

## Checker 成员

| 成员 | 作用 |
|---|---|
| `read_t()` | 读测试组数（只从输入文件；答案/输出不含 `t`） |
| `read_in<T>()` / `read_ans<T>()` / `read_out<T>()` | 从对应文件读一个 token，EOF/格式错 → `Error` |
| `chk_rest(test)` | 答案与输出剩余 token 逐 token 比对（忽略空白/换行） |
| `ensure_eof()` | 校验答案/输出都已读完；不检查输入文件（checker 常只读输入一部分） |

> `chk_rest` 与 `ensure_eof` 二选一：`chk_rest` 会把两侧流读到 EOF。
