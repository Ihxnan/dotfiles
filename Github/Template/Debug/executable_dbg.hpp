// =============================================================================
// dbg.hpp — 竞赛调试头文件
//
// ===== 使用样例 =====
//
// --- gdb：打印变量名和值，多变量逗号分隔单行 ---
//   int n = 5, m = 10;
//   gdb(n, m);              // n = 5, m = 10
//
// --- 顺序容器 ---
//   vector<int> v = {1, 2, 3};
//   gdb(v);                 // v = [1, 2, 3]
//
//   deque<int> dq = {7, 8, 9};
//   gdb(dq);                // dq = [7, 8, 9]
//
//   list<int> lst = {100, 200, 300};
//   gdb(lst);               // lst = [100, 200, 300]
//
//   array<int, 4> arr = {0, 1, 2, 3};
//   gdb(arr);               // arr = [0, 1, 2, 3]
//
// --- 关联容器 ---
//   set<int> st = {3, 1, 4};
//   gdb(st);                // st = {1, 3, 4}
//
//   map<string, int> mp = {{"alice", 90}, {"bob", 85}};
//   gdb(mp);                // mp = {"alice": 90, "bob": 85}
//
// --- 容器适配器（自动拷贝后遍历）---
//   stack<int> stk; stk.push(1); stk.push(2); stk.push(3);
//   gdb(stk);               // stk = [3, 2, 1]    (弹栈顺序)
//
//   queue<int> q; q.push(10); q.push(20); q.push(30);
//   gdb(q);                 // q = [10, 20, 30]   (FIFO)
//
//   priority_queue<int> pq; pq.push(5); pq.push(2); pq.push(8);
//   gdb(pq);                // pq = [8, 5, 2]      (优先级降序)
//
// --- 结构类型 ---
//   pair<int, double> p = {42, 3.14};
//   gdb(p);                 // p = <42, 3.14>
//
//   tuple<int, char, string> t = {1, 'x', "hello"};
//   gdb(t);                 // t = (1, 'x', "hello")
//
//   optional<int> opt = 7, nopt = nullopt;
//   gdb(opt, nopt);         // opt = 7, nopt = nullopt
//
//   variant<int, string> var = "world";
//   gdb(var);               // var = "world"
//
//   bitset<8> bs(42);
//   gdb(bs);                // bs = 00101010
//
//   __int128_t big = (__int128_t)1e18 * 1e9;
//   gdb(big);               // big = 1000000000000000000000000000
//
// --- 嵌套容器（元素为容器时自动多行缩进）---
//   vector<vector<int>> dp = {{1, 0}, {0, 1}};
//   gdb(dp);                // dp =
//                           //        0     1
//                           //    0       1     0
//                           //    1       0     1
//
//   vector<set<int>> vec_set = {{1, 2}, {3}};
//   gdb(vec_set);           // vec_set = [
//                           //   {1, 2},
//                           //   {3}
//                           // ]
//
// --- gdbif：条件调试 ---
//   gdbif(i > 100, i, arr[i]);     // 仅当 i > 100 时打印
//
// --- gdb_assert：调试断言（失败打印消息并 exit(1)）---
//   gdb_assert(cnt > 0, "cnt must be positive but got " + to_string(cnt));
//   // 失败输出:  [file:line] ASSERT FAILED [...msg...]
//
// --- TIME：RAII 计时器 ---
//   { TIME("dp"); solve(); }   // 离开作用域打印耗时
//   // 输出: [Timer] dp : 0.001234 s
//
//   TIME("sort"); sort(v.begin(), v.end());   // 单语句也适用
//
// --- dbg_print：直接调用打印引擎（不自动换行）---
//   dbg_print(cerr, 42);              // 42
//   dbg_print(cerr, vector{1,2});     // [1, 2]
//   dbg_print(cerr, x); cerr << '\n'; // 手动换行
//
// --- 彩色 cout + getchar 快读（IHXNAN 调试模式下自动启用）---
//   正常提交（非 IHXNAN）时 cin/cout 被宏替换为 fin/fout 快读写（无色）；
//   -DIHXNAN 调试模式下 dbg.hpp 定义与提交模式完全同逻辑的 struct IO
//   （inc→getchar：stdio 行缓冲，回车即生效、无需 EOF/Ctrl+D，不像 fread
//   快读会阻塞到 EOF；outc→紫色 dbg_putchar，随 dbg_set_color 开关），
//   cin/cout 宏同样指向 fin/fout。类型支持与提交模式完全一致：
//   整数/char/string 快读写，double 等其余类型在编译期报错（本地即可发现）。
//   注意：IHXNAN 下勿写 std::cout / std::cin（宏替换会编译报错）。
//
// ===== 输入代码示例 =====
//   #ifdef IHXNAN
//       #include <dbg>
//   #else
//       #define cin fin
//       #define cout fout
//       #define gdb(...)              ((void)0)
//       #define gdbif(c, ...)         ((void)0)
//       #define gdb_assert(cond, msg) ((void)0)
//       #define TIME(name)          ((void)0)
//   #endif
//
// ===== 支持的容器/类型（自动适配）=====
//   - pair, tuple, optional, variant
//   - vector, deque, list, forward_list, array
//   - set, multiset, unordered_set
//   - map, multimap, unordered_map
//   - stack, queue, priority_queue (自动拷贝后遍历)
//   - bitset
//   - __int128 / __uint128
//   - 所有有 operator<< 的基础类型
//   - 嵌套容器（元素为容器时自动多行缩进）
// =============================================================================

// ==================== 0. 头文件 & 常量 & 颜色 ====================
#include <bits/stdc++.h>
#include <execinfo.h>
using namespace std;

// 嵌套深度上限，超出打印 "..."
#define MAX_DBG_DEPTH 10

// 嵌套容器每层缩进空格数
#define DBG_INDENT 2

// ANSI 颜色码
#define RED "\033[1;31m"
#define YELLOW "\033[1;33m"
#define CYAN "\033[1;36m"
#define RESET "\033[0m"

// ---- 运行时颜色开关 ----
inline bool &_dbg_color_enabled()
{
    static bool en = true;
    return en;
}
inline void dbg_set_color(bool on)
{
    _dbg_color_enabled() = on;
}

// 颜色辅助：颜色开关关闭时返回空串
inline const char *_dbg_c(const char *code)
{
    return _dbg_color_enabled() ? code : "";
}

// ---- 可重定向输出的 ostream 包装 ----
// 默认写 stderr：让 stdout 只保留程序结果，便于本地与 .out 对比判题。
//   - 程序正常输出仍走 stdout（调试模式下经 dbg_putchar 包成紫色）；
//   - gdb / gdbif / DbgStream / TIME / Bench / gdb_assert / 崩溃栈 等调试信息统一走这里 → stderr。
// 如需改回流，可在运行时调用 dbg_set_output(stdout)。
inline FILE *&_dbg_out_fp()
{
    static FILE *fp = stderr;
    return fp;
}
inline void dbg_set_output(FILE *fp)
{
    _dbg_out_fp() = fp;
}

struct _dbg_streambuf : streambuf {
    int overflow(int c) override
    {
        if (c != EOF)
            return fputc(c, _dbg_out_fp());
        return EOF;
    }
    streamsize xsputn(const char *s, streamsize n) override
    {
        return fwrite(s, 1, n, _dbg_out_fp());
    }
};

inline ostream &_dbg_os()
{
    static _dbg_streambuf buf;
    static ostream os(&buf);
    return os;
}

// ==================== 1. __int128 打印 ====================

// __int128 和 __uint128 是 GCC 扩展，无标准库 operator<<，
// 这里手动实现十进制输出（先转无符号取绝对值，避免 INT128_MIN 取反溢出）。
ostream &operator<<(ostream &os, __uint128_t x)
{
    if (x > 9)
        os << x / 10;
    return os << char('0' + x % 10);
}
ostream &operator<<(ostream &os, __int128_t x)
{
    if (x < 0)
        os << '-';
    __uint128_t u = x < 0 ? -(__uint128_t)x : (__uint128_t)x;
    if (u > 9)
        os << u / 10; // 调用上面的 __uint128_t 重载，高位在前
    return os << char('0' + u % 10);
}

// ==================== 1b. dbg_binary — 整数二进制打印 ====================

template <typename T> enable_if_t<is_integral_v<T>> dbg_binary(ostream &os, T val)
{
    os << "0b";
    for (int i = 8 * (int)sizeof(T) - 1; i >= 0; --i)
    {
        if (i < 8 * (int)sizeof(T) - 1 && (i + 1) % 4 == 0)
            os << '_';
        os << char('0' + ((val >> i) & 1));
    }
}

// ==================== 2. 类型检测 ====================
// 采用函数重载 + decltype 表达式 SFINAE，
// 避免 void_t 在 GCC 16 类模板偏特化中的兼容性问题。

// ---------------------------------------------------------------
// is_specialization_of<T, Tmpl>：判断 T 是否为 Tmpl<Args...> 实例
// ---------------------------------------------------------------
template <typename, template <typename...> class> struct is_specialization_of : false_type {};
template <template <typename...> class Tmpl, typename... Args>
struct is_specialization_of<Tmpl<Args...>, Tmpl> : true_type {};

// ---------------------------------------------------------------
// is_specialization_of_nontype<T, Tmpl>：
//     判断 T 是否为 Tmpl<nontype...> 实例（例如 bitset<N>）
// ---------------------------------------------------------------
template <typename, template <auto...> class> struct is_specialization_of_nontype : false_type {};
template <template <auto...> class Tmpl, auto... Args>
struct is_specialization_of_nontype<Tmpl<Args...>, Tmpl> : true_type {};

// ---------------------------------------------------------------
// 基于重载的表达式检测宏：生成 _trait(int) -> decltype(expr, true_type{})
//                              _trait(long) -> false_type
//                              trait_v = decltype(_trait<T>(0))::value
// ---------------------------------------------------------------
#define _DBG_DETECT(trait, ...)                                                                                        \
    template <typename T> constexpr auto _dbg_##trait(int) -> enable_if_t<true, decltype(__VA_ARGS__, true_type{})>    \
    {                                                                                                                  \
        return {};                                                                                                     \
    }                                                                                                                  \
    template <typename T> constexpr false_type _dbg_##trait(long)                                                      \
    {                                                                                                                  \
        return {};                                                                                                     \
    }                                                                                                                  \
    template <typename T> constexpr bool trait##_v = decltype(_dbg_##trait<T>(0))::value;

// ---- 具体检测 ----
_DBG_DETECT(has_begin, declval<T>().begin())
_DBG_DETECT(has_end, declval<T>().end())
_DBG_DETECT(has_pop, declval<T>().pop())
_DBG_DETECT(has_top, declval<T>().top())
_DBG_DETECT(has_front, declval<T>().front())
_DBG_DETECT(has_mapped, typename T::mapped_type{})
_DBG_DETECT(has_key, typename T::key_type{})
_DBG_DETECT(is_output, declval<ostream &>() << declval<const T &>())

#undef _DBG_DETECT

// ---- 复合判断（在基础 _v 之上组合） ----
template <typename T> constexpr bool is_pair_v = is_specialization_of<T, pair>::value;
template <typename T> constexpr bool is_tuple_v = is_specialization_of<T, tuple>::value;
template <typename T> constexpr bool is_optional_v = is_specialization_of<T, optional>::value;
template <typename T> constexpr bool is_variant_v = is_specialization_of<T, variant>::value;
template <typename T> constexpr bool is_bitset_v = is_specialization_of_nontype<T, bitset>::value;
// std::array<T,N> 检测
template <typename T> struct _dbg_is_std_array : false_type {};
template <typename T, size_t N> struct _dbg_is_std_array<array<T, N>> : true_type {};
template <typename T> constexpr bool _dbg_is_std_array_v = _dbg_is_std_array<T>::value;
template <typename T> constexpr bool is_map_v = has_mapped_v<T>;
template <typename T> constexpr bool is_set_v = has_key_v<T> && !is_map_v<T>;
template <typename T> constexpr bool is_container_adaptor_v = has_pop_v<T> && !has_begin_v<T>;
template <typename T> constexpr bool is_iterable_v = has_begin_v<T> && has_end_v<T>;
template <typename T> constexpr bool is_streamable_v = is_output_v<T>;

// C 数组检测（编译期已知大小）
template <typename T> struct _dbg_is_c_array : false_type {};
template <typename T, size_t N> struct _dbg_is_c_array<T[N]> : true_type {};
template <typename T> constexpr bool _dbg_is_c_array_v = _dbg_is_c_array<T>::value;

// is_structured_v：元素是否为结构体/容器，用于深度 0 时判断父容器是否需要多行缩进
template <typename T>
constexpr bool is_structured_v =
    is_iterable_v<T> || is_map_v<T> || is_set_v<T> || is_container_adaptor_v<T> || is_pair_v<T> || is_tuple_v<T> ||
    is_optional_v<T> || is_variant_v<T> || is_bitset_v<T> || _dbg_is_c_array_v<T>;

// is_expandable_v：深度 >=1 时，仅对"可展开"容器（有多元素的）继续多行，pair/tuple 等保持紧凑
template <typename T>
constexpr bool is_expandable_v =
    is_iterable_v<T> || is_map_v<T> || is_set_v<T> || is_container_adaptor_v<T> || _dbg_is_c_array_v<T>;

// ==================== 3. tuple 展开辅助 ====================

// dbg_print 前向声明，供 _dbg_print_tuple 使用
template <typename T> ostream &dbg_print(ostream &os, const T &x, int depth = 0);

// 2D 网格打印的前向声明，供 dbg_print 内 vector<vector<T>> 自动路由使用
template <typename T> void _dbg_print_grid(ostream &os, const vector<vector<T>> &, int, int, int, int);

template <typename T> void _dbg_print_2d(ostream &os, const vector<vector<T>> &mat)
{
    int r = (int)mat.size();
    int c = 0;
    for (const auto &row : mat)
        c = max(c, (int)row.size());
    _dbg_print_grid(os, mat, 0, r, 0, c);
}

// 递归 if constexpr 展开 tuple，避免 GCC 16 对折叠表达式内逗号运算符的限制。
template <typename Tuple, size_t I = 0> void _dbg_print_tuple(ostream &os, const Tuple &t, int depth)
{
    if constexpr (I < tuple_size_v<Tuple>)
    {
        if constexpr (I > 0)
            os << ", ";
        dbg_print(os, get<I>(t), depth + 1);
        _dbg_print_tuple<Tuple, I + 1>(os, t, depth);
    }
}

// ---------------------------------------------------------------
// _dbg_print_2d_c_array_grid：二维 C 数组网格打印（Unicode 边框）
// ---------------------------------------------------------------
template <typename T, size_t R, size_t C> void _dbg_print_2d_c_array_grid(ostream &os, const T (&arr)[R][C])
{
    // 计算各列最大宽度（+2 为两侧各一空格）
    int w = 1;
    for (size_t i = 0; i < R; ++i)
        for (size_t j = 0; j < C; ++j)
        {
            ostringstream ss;
            dbg_print(ss, arr[i][j]);
            w = max(w, (int)ss.str().size() + 2);
        }
    // 列标（列号）可能比数据更宽，将其纳入单元格宽度
    w = max(w, (C ? (int)to_string(C - 1).size() : 1) + 2);
    int rw = max(1, (int)to_string(R - 1).size());
    int wr = rw + 2; // 行号列宽度（含两侧空格）

    // 重复一个 UTF-8 字符 n 次
    auto rep = [](int n, const char *ch) {
        string s;
        for (int i = 0; i < n; ++i)
            s += ch;
        return s;
    };
    string dash_c = rep(w, "─");
    string dash_r = rep(wr, "─");

    // 画横线：left ─dash_r── mid_r ─dash_c─ mid_c ─dash_c─ right
    auto hline = [&](const char *left, const char *mid_r, const char *mid_c, const char *right) {
        os << left << dash_r << mid_r;
        for (size_t j = 0; j < C; ++j)
            os << dash_c << (j + 1 < C ? mid_c : right);
    };

    os << _dbg_c(RESET) << '\n';

    // ── 顶边框 ──
    hline("┌", "┬", "┬", "┐");
    os << '\n';

    // ── 列号标尺（首格为空，对齐行号列宽度）──
    os << "│" << string(wr, ' ') << "│";
    for (size_t j = 0; j < C; ++j)
    {
        os << ' ' << _dbg_c(RED) << setw(w - 2) << j << _dbg_c(RESET) << ' ' << "│";
    }
    os << '\n';

    // ── 表头/数据分隔线 ──
    hline("├", "┼", "┼", "┤");
    os << '\n';

    // ── 数据行 ──
    for (size_t i = 0; i < R; ++i)
    {
        os << "│" << ' ' << _dbg_c(RED) << setw(rw) << i << _dbg_c(RESET) << ' ' << "│";
        for (size_t j = 0; j < C; ++j)
        {
            ostringstream ss;
            dbg_print(ss, arr[i][j]);
            os << ' ' << _dbg_c(CYAN) << setw(w - 2) << ss.str() << _dbg_c(RESET) << ' ' << "│";
        }
        os << '\n';

        if (i + 1 < R)
        {
            hline("├", "┼", "┼", "┤");
            os << '\n';
        }
    }

    // ── 底边框 ──
    hline("└", "┴", "┴", "┘");
    os << '\n';
}

// ---------------------------------------------------------------
// _dbg_print_1d_table：一维简单数组的单行表格（列号标尺 + 数据）
// ---------------------------------------------------------------
template <typename Fn> void _dbg_print_1d_table(ostream &os, size_t N, Fn &&get_val)
{
    int w = 1;
    for (size_t i = 0; i < N; ++i)
    {
        ostringstream ss;
        dbg_print(ss, get_val(i));
        w = max(w, (int)ss.str().size() + 2);
    }
    // 列标（列号）可能比数据更宽，将其纳入单元格宽度
    w = max(w, (N ? (int)to_string(N - 1).size() : 1) + 2);
    string dash;
    for (int i = 0; i < w; ++i)
        dash += "─";

    os << _dbg_c(RESET) << '\n';

    os << "┌";
    for (size_t i = 0; i < N; ++i)
        os << dash << (i + 1 < N ? "┬" : "┐");
    os << '\n';

    os << "│";
    for (size_t i = 0; i < N; ++i)
        os << ' ' << _dbg_c(RED) << setw(w - 2) << i << _dbg_c(RESET) << ' ' << "│";
    os << '\n';

    os << "├";
    for (size_t i = 0; i < N; ++i)
        os << dash << (i + 1 < N ? "┼" : "┤");
    os << '\n';

    os << "│";
    for (size_t i = 0; i < N; ++i)
    {
        ostringstream ss;
        dbg_print(ss, get_val(i));
        os << ' ' << _dbg_c(CYAN) << setw(w - 2) << ss.str() << _dbg_c(RESET) << ' ' << "│";
    }
    os << '\n';

    os << "└";
    for (size_t i = 0; i < N; ++i)
        os << dash << (i + 1 < N ? "┴" : "┘");
    os << '\n';
}

// ---------------------------------------------------------------
// dbg_print C 数组重载：通过引用保留大小信息
// ---------------------------------------------------------------
template <typename T, size_t N> ostream &dbg_print(ostream &os, const T (&arr)[N], int depth = 0)
{
    if constexpr (is_same_v<T, char>)
    {
        os << '"';
        for (size_t i = 0; i < N && arr[i]; ++i)
            os << arr[i];
        os << '"';
        return os;
    }
    else if constexpr (_dbg_is_c_array_v<T>)
    {
        // T 本身是数组 → 至少是二维
        // 检查最内层元素是否是简单类型
        using Innermost = remove_all_extents_t<T>;
        if constexpr (!is_structured_v<Innermost>)
        {
            // 二维简单数组 → 网格格式
            using Inner = remove_extent_t<T>;
            constexpr size_t COLS = extent_v<T, 0>;
            _dbg_print_2d_c_array_grid(os, reinterpret_cast<const Inner(&)[N][COLS]>(arr));
            return os;
        }
        // 元素是结构体 → 走通用递归逻辑
    }
    else if constexpr (!is_structured_v<T>)
    {
        // 一维简单数组 → 列号标尺 + 数据行 表格
        _dbg_print_1d_table(os, N, [&](size_t i) -> const T & { return arr[i]; });
        return os;
    }

    // 通用数组逻辑：一维结构体元素 / 高维但元素是结构体
    bool multiline = false;
    if (N > 0)
    {
        if (depth == 0)
            multiline = is_structured_v<T>;
        else
            multiline = is_expandable_v<T>;
    }
    string indent(depth * DBG_INDENT, ' ');

    os << '[';
    for (size_t i = 0; i < N; ++i)
    {
        if (i > 0)
            os << (multiline ? "," : ", ");
        if (multiline)
            os << '\n' << indent << string(DBG_INDENT, ' ');
        dbg_print(os, arr[i], depth + 1);
    }
    if (multiline)
        os << '\n' << indent;
    os << ']';
    return os;
}

// ==================== 4. 统一打印引擎 dbg_print ====================
// 核心函数，通过 if constexpr 按优先级分发到对应分支。
// depth 控制嵌套容器的缩进级别：
//   depth = 0：紧凑输出（单行，元素逗号分隔）
//   depth >= 1：换行 + 缩进输出
// depth > MAX_DBG_DEPTH 直接打印 "..." 防无限递归。

template <typename T> ostream &dbg_print(ostream &os, const T &x, int depth /* = 0 */)
{
    // 递归深度保护
    if (depth > MAX_DBG_DEPTH)
    {
        os << "...";
        return os;
    }

    // ---- 0. 空指针 ----
    if constexpr (is_same_v<T, nullptr_t>)
    {
        os << "null";
    }
    // ---- 1. 字符串类型，用双引号包裹 ----
    else if constexpr (is_same_v<T, string> || is_same_v<T, string_view>)
    {
        os << '"' << x << '"';
    }
    else if constexpr (is_same_v<T, const char *> || is_same_v<T, char *>)
    {
        os << '"' << x << '"';
    }
    else if constexpr (is_same_v<T, char>)
    {
        os << '\'' << x << '\'';
    }
    // ---- 2. __int128 已重载 operator<< ----
    else if constexpr (is_same_v<T, __int128_t> || is_same_v<T, __uint128_t>)
    {
        os << x;
    }
    // ---- 3. pair ----
    else if constexpr (is_pair_v<T>)
    {
        os << '<';
        dbg_print(os, x.first, depth + 1);
        os << ", ";
        dbg_print(os, x.second, depth + 1);
        os << '>';
    }
    // ---- 4. tuple ----
    else if constexpr (is_tuple_v<T>)
    {
        os << '(';
        _dbg_print_tuple(os, x, depth);
        os << ')';
    }
    // ---- 5. optional ----
    else if constexpr (is_optional_v<T>)
    {
        if (x.has_value())
            dbg_print(os, *x, depth);
        else
            os << "nullopt";
    }
    // ---- 6. variant ----
    else if constexpr (is_variant_v<T>)
    {
        std::visit([&](const auto &v) { dbg_print(os, v, depth); }, x);
    }
    // ---- 7. bitset ----
    else if constexpr (is_bitset_v<T>)
    {
        os << x.to_string();
    }
    // ---- 8. 容器适配器：stack / queue / priority_queue ----
    //       拷贝一份后 pop 遍历，打印弹出顺序。
    else if constexpr (is_container_adaptor_v<T>)
    {
        auto cp = x; // 拷贝，避免破坏原容器
        bool fst = true;
        os << '[';
        while (!cp.empty())
        {
            if (!fst)
                os << ", ";
            fst = false;
            if constexpr (has_top_v<T>)
                dbg_print(os, cp.top(), depth + 1);
            else if constexpr (has_front_v<T>)
                dbg_print(os, cp.front(), depth + 1);
            cp.pop();
        }
        os << ']';
    }
    // ---- 9. map / multimap / unordered_map 系列 ----
    else if constexpr (is_map_v<T>)
    {
        bool fst = true;
        bool multiline = (depth >= 1);
        string indent(depth * DBG_INDENT, ' ');

        os << '{';
        for (const auto &[k, v] : x)
        {
            if (!fst)
                os << (multiline ? "," : ", ");
            fst = false;
            if (multiline)
                os << '\n' << indent << string(DBG_INDENT, ' ');
            dbg_print(os, k, depth + 1);
            os << ": ";
            dbg_print(os, v, depth + 1);
        }
        if (multiline)
            os << '\n' << indent;
        os << '}';
    }
    // ---- 10. set / multiset / unordered_set 系列 ----
    else if constexpr (is_set_v<T>)
    {
        bool fst = true;
        bool multiline = false;
        if (!x.empty())
        {
            using Elem = decay_t<decltype(*x.begin())>;
            if (depth == 0)
                multiline = is_structured_v<Elem>;
            else
                multiline = is_expandable_v<Elem>;
        }
        string indent(depth * DBG_INDENT, ' ');

        os << '{';
        for (const auto &e : x)
        {
            if (!fst)
                os << (multiline ? "," : ", ");
            fst = false;
            if (multiline)
                os << '\n' << indent << string(DBG_INDENT, ' ');
            dbg_print(os, e, depth + 1);
        }
        if (multiline)
            os << '\n' << indent;
        os << '}';
    }
    // ---- 11. 顺序容器：vector / deque / list / forward_list / array 等 ----
    else if constexpr (is_iterable_v<T>)
    {
        // vector<vector<U>>：当 U 为简单类型时自动网格格式，否则退回多行缩进
        if (!x.empty())
        {
            using Elem = decay_t<decltype(*x.begin())>;
            if constexpr (is_specialization_of<Elem, vector>::value)
            {
                using Deep = decay_t<decltype(*declval<const Elem &>().begin())>;
                if constexpr (!is_structured_v<Deep>)
                {
                    os << '\n';
                    _dbg_print_2d(os, x);
                    return os;
                }
            }
            else if constexpr ((is_specialization_of<T, vector>::value || _dbg_is_std_array_v<T>) &&
                               !is_structured_v<Elem>)
            {
                // 1D vector<简单类型> → 列号标尺 + 数据行表格
                _dbg_print_1d_table(os, x.size(), [&](size_t i) -> decltype(auto) { return x[i]; });
                return os;
            }
        }

        bool fst = true;
        bool multiline = false;
        if (!x.empty())
        {
            using Elem = decay_t<decltype(*x.begin())>;
            if (depth == 0)
                multiline = is_structured_v<Elem>;
            else
                multiline = is_expandable_v<Elem>;
        }
        string indent(depth * DBG_INDENT, ' ');

        os << '[';
        for (const auto &e : x)
        {
            if (!fst)
                os << (multiline ? "," : ", ");
            fst = false;
            if (multiline)
                os << '\n' << indent << string(DBG_INDENT, ' ');
            dbg_print(os, e, depth + 1);
        }
        if (multiline)
            os << '\n' << indent;
        os << ']';
    }
    // ---- 12. 基础类型：有 operator<< 的整数/浮点等 ----
    else if constexpr (is_streamable_v<T>)
    {
        os << x;
    }
    // ---- 13. 无法打印的类型 ----
    else
    {
        os << "[?]";
    }
    return os;
}

// ==================== 5. gdb 宏的名称解析 ====================
// 从 #__VA_ARGS__ 逗号分隔串中提取下一个变量名，
// 支持模板参数角括号 <>、括号 ()、中括号 [] 嵌套，避免模板变量名中的逗号误切。

inline string _gdb_next_name(const char *&p)
{
    while (*p == ' ')
        ++p;
    if (!*p)
        return "";
    const char *beg = p;
    int a = 0, r = 0, b = 0; // angle, round, square bracket 深度
    while (*p)
    {
        if (*p == '<')
            ++a;
        else if (*p == '>')
            --a;
        else if (*p == '(')
            ++r;
        else if (*p == ')')
            --r;
        else if (*p == '[')
            ++b;
        else if (*p == ']')
            --b;
        else if (*p == ',' && a == 0 && r == 0 && b == 0)
            break;
        ++p;
    }
    // 去掉末尾空格
    const char *end = p;
    while (end > beg && *(end - 1) == ' ')
        --end;
    string name(beg, end);
    if (*p == ',')
        ++p;
    return name;
}

// ---------------------------------------------------------------
// _gdb_all_vars：递归打印多个变量值（不使用前缀，只负责 name = value 部分）
// 配合 gdb 宏使用，前缀 [file:line] 由宏统一输出一次。
// ---------------------------------------------------------------

// 递归基础（单变量，不加末尾逗号）
template <typename T> void _gdb_all_vars(ostream &os, const char *names, const T &val)
{
    string name = _gdb_next_name(names);
    os << _dbg_c(RED) << name << _dbg_c(RESET) << " = " << _dbg_c(CYAN);
    dbg_print(os, val, 0);
    os << _dbg_c(RESET);
}

// 递归步（多个变量，当前变量后面加逗号）
template <typename T, typename... Args>
void _gdb_all_vars(ostream &os, const char *names, const T &val, const Args &...rest)
{
    string name = _gdb_next_name(names);
    os << _dbg_c(RED) << name << _dbg_c(RESET) << " = " << _dbg_c(CYAN);
    dbg_print(os, val, 0);
    os << _dbg_c(RESET) << ", ";
    _gdb_all_vars(os, names, rest...);
}

// ==================== 6. 调试宏 ====================

/// 主调试宏：打印变量名和值
/// 用法：gdb(n, m, v);
/// 输出：
///   n = 5, m = 10, v = [1, 2, 3]
#define gdb(...)                                                                                                       \
    (fflush(stdout),                                                                                                   \
     _gdb_all_vars(_dbg_os(), #__VA_ARGS__, __VA_ARGS__), _dbg_os() << '\n', fflush(_dbg_out_fp()), 0)

/// 条件 gdb，仅当 cond 为 true 时输出
/// 用法：gdbif(i > 100, i, arr[i]);
#define gdbif(cond, ...) ((cond) ? (gdb(__VA_ARGS__)) : (0))

/// 断言宏：失败时打印诊断信息并退出
/// 用法：gdb_assert(cnt > 0, "cnt must be positive but got " + to_string(cnt));
#define gdb_assert(cond, msg)                                                                                          \
    ((void)((cond) || (fflush(stdout),                                                                                 \
                       _dbg_os() << _dbg_c(RED) << "ASSERT FAILED [" << __FILE__ << ":" << __LINE__ << "] " << msg     \
                                 << _dbg_c(RESET) << "\n",                                                             \
                       fflush(_dbg_out_fp()), exit(1), 0)))

// ==================== 6b. DbgStream — 流式临时调试（无需变量名）====================

/// 用法：
///   DbgStream() << "partial = " << (a + b) * c;
///   // [main.cpp:42]
///   // partial = 42
struct DbgStream {
    source_location loc;
    DbgStream(source_location l = source_location::current()) : loc(l)
    {
        fflush(stdout);
        _dbg_os() << _dbg_c(YELLOW) << "[" << loc.file_name() << ":" << loc.line() << "]\n" << _dbg_c(RESET);
    }
    ~DbgStream()
    {
        _dbg_os() << '\n';
        fflush(_dbg_out_fp());
    }
    template <typename T> DbgStream &operator<<(const T &v)
    {
        dbg_print(_dbg_os(), v, 0);
        return *this;
    }
    DbgStream(const DbgStream &) = delete;
    DbgStream &operator=(const DbgStream &) = delete;
};

// ==================== 7. 网格打印底层实现 ====================

template <typename T> void _dbg_print_grid(ostream &os, const vector<vector<T>> &mat, int r1, int r2, int c1, int c2)
{
    // 第一遍：扫描所有元素，计算最大显示宽度（跳过短行不存在的元素）
    int w = 1;
    for (int i = r1; i < r2; ++i)
    {
        int row_cols = (int)mat[i].size();
        for (int j = c1; j < c2 && j < row_cols; ++j)
        {
            ostringstream ss;
            dbg_print(ss, mat[i][j]);
            w = max(w, (int)ss.str().size() + 2); // +2 为两侧各一空格
        }
    }
    // 列标（列号）可能比数据更宽，将其纳入单元格宽度
    w = max(w, (c2 > c1 ? (int)to_string(c2 - 1).size() : 1) + 2);
    int rw = max(1, (int)to_string(r2 - 1).size());
    int wr = rw + 2; // 行号列宽度（含两侧空格）
    int cols = c2 - c1;

    auto rep = [](int n, const char *ch) {
        string s;
        for (int i = 0; i < n; ++i)
            s += ch;
        return s;
    };
    string dash_c = rep(w, "─");
    string dash_r = rep(wr, "─");

    auto hline = [&](const char *left, const char *mid_r, const char *mid_c, const char *right) {
        os << left << dash_r << mid_r;
        for (int j = 0; j < cols; ++j)
            os << dash_c << (j + 1 < cols ? mid_c : right);
    };

    // 安全获取 mat[i][j]，越界时返回空字符串
    auto safe_cell = [&](int i, int j) -> string {
        if (i < (int)mat.size() && j < (int)mat[i].size())
        {
            ostringstream ss;
            dbg_print(ss, mat[i][j]);
            return ss.str();
        }
        return "";
    };

    os << _dbg_c(RESET) << '\n';

    // ── 顶边框 ──
    hline("┌", "┬", "┬", "┐");
    os << '\n';

    // ── 列号标尺 ──
    os << "│" << string(wr, ' ') << "│";
    for (int j = c1; j < c2; ++j)
    {
        os << ' ' << _dbg_c(RED) << setw(w - 2) << j << _dbg_c(RESET) << ' ' << "│";
    }
    os << '\n';

    // ── 表头/数据分隔线 ──
    hline("├", "┼", "┼", "┤");
    os << '\n';

    // ── 数据行 ──
    for (int i = r1; i < r2; ++i)
    {
        os << "│" << ' ' << _dbg_c(RED) << setw(rw) << i << _dbg_c(RESET) << ' ' << "│";
        for (int j = c1; j < c2; ++j)
        {
            string val = safe_cell(i, j);
            os << ' ' << _dbg_c(CYAN) << setw(w - 2) << val << _dbg_c(RESET) << ' ' << "│";
        }
        os << '\n';

        if (i + 1 < r2)
        {
            hline("├", "┼", "┼", "┤");
            os << '\n';
        }
    }

    // ── 底边框 ──
    hline("└", "┴", "┴", "┘");
    os << '\n';
}

// ==================== 8. Timer + TIME ====================

/// RAII 计时器：构造时记录起始时间，析构时打印耗时（秒）
/// 直接使用：{ Timer t("sort"); sort(v); }
/// 宏方式：  TIME("sort"); sort(v);
struct Timer {
    using clock_t = chrono::high_resolution_clock;
    clock_t::time_point start;
    const char *name;

    Timer(const char *_name) : start(clock_t::now()), name(_name)
    {
    }
    ~Timer()
    {
        double elapsed = chrono::duration<double>(clock_t::now() - start).count();
        fflush(stdout);
        _dbg_os() << _dbg_c(CYAN) << "[Timer] " << name << " : " << fixed << setprecision(6) << elapsed << " s"
                  << _dbg_c(RESET) << "\n";
        fflush(_dbg_out_fp());
    }
    Timer(const Timer &) = delete;
    Timer &operator=(const Timer &) = delete;
};

/// TIME(name)：在作用域结束时自动打印耗时。
/// 用法：
///   { TIME("dp"); solve(); }
///   TIME("sort"); sort(v.begin(), v.end());
#define TIME(name) Timer _timer_##__LINE__(name)

// ==================== 8b. Bench — 多轮计时统计 ====================

/// 用法：
///   Bench b("quick_vs_merge");
///   for (int t = 0; t < 10; ++t) {
///       auto data = gen_data(1e6);
///       b.start(); quick_sort(data); b.stop();
///       b.start(); merge_sort(data); b.stop();
///   }
///   // 析构输出: [Bench] quick_vs_merge : 20 runs, avg 0.0123 s, min ...
struct Bench {
    using clock_t = chrono::high_resolution_clock;
    const char *name;
    vector<double> samples;

    Bench(const char *n) : name(n)
    {
    }
    void start()
    {
        samples.push_back(-(double)clock_t::now().time_since_epoch().count());
    }
    void stop()
    {
        samples.back() += (double)clock_t::now().time_since_epoch().count();
    }
    ~Bench()
    {
        if (samples.empty())
            return;
        double sum = 0, mn = samples[0], mx = samples[0];
        for (auto s : samples)
        {
            sum += s;
            if (s < mn)
                mn = s;
            if (s > mx)
                mx = s;
        }
        double avg = sum / samples.size();
        fflush(stdout);
        _dbg_os() << _dbg_c(CYAN) << "[Bench] " << name << " : " << samples.size() << " runs, avg " << fixed
                  << setprecision(6) << avg / 1e9 << " s, min " << mn / 1e9 << " s, max " << mx / 1e9 << " s"
                  << _dbg_c(RESET) << "\n";
        fflush(_dbg_out_fp());
    }
    Bench(const Bench &) = delete;
    Bench &operator=(const Bench &) = delete;
};

// ==================== 8c. dbg_backtrace — 崩溃信号处理器 ====================

/// 在 main 开头调用一次，遇到 SIGSEGV / SIGABRT / SIGFPE 时打印调用栈。
/// 编译需要 -g -rdynamic 以获得函数名。
/// 用法：
///   int main() {
///       dbg_register_signal_handlers();
///       // ... 你的代码
///   }
inline void _dbg_signal_handler(int sig)
{
    const char *name = "";
    if (sig == SIGSEGV)
        name = "SIGSEGV";
    else if (sig == SIGABRT)
        name = "SIGABRT";
    else if (sig == SIGFPE)
        name = "SIGFPE";
    else
        name = "SIG???";

    fflush(stdout);
    fputs(_dbg_c(RED), _dbg_out_fp());
    fputs("\n[CRASH] Caught ", _dbg_out_fp());
    fputs(name, _dbg_out_fp());
    fputs(_dbg_c(RESET), _dbg_out_fp());
    fputs("\n", _dbg_out_fp());
    fflush(_dbg_out_fp());
    void *buffer[64];
    int n = backtrace(buffer, 64);
    backtrace_symbols_fd(buffer, n, STDERR_FILENO);
    _exit(1);
}

inline void dbg_register_signal_handlers()
{
    signal(SIGSEGV, _dbg_signal_handler);
    signal(SIGABRT, _dbg_signal_handler);
    signal(SIGFPE, _dbg_signal_handler);
}

// ==================== 8d. dbg_putchar — putchar 包装（固定紫色）====================

/// 给通过 putchar 输出的内容加上紫色前缀，与 gdb 的彩色输出区分。
/// 用法：在模板中将 `#define pc putchar` 改为 `#define pc dbg_putchar`
///       non-debug 分支加 `#define dbg_putchar(c) putchar(c)`
inline void dbg_putchar(int c)
{
    static bool _dbg_pc_init = false;
    if (!_dbg_pc_init)
    {
        _dbg_pc_init = true;
        atexit([] { fputs("\033[0m", stdout); });
    }
    if (_dbg_color_enabled())
        fputs("\033[35m", stdout);
    putchar(c);
    if (c == '\n' && _dbg_color_enabled())
        fputs("\033[0m", stdout);
}

// ==================== 9. 兼容旧接口 ====================

// gc: 快速读字符，保留旧接口。
#define gc getchar

// pc: putchar 包装，固定紫色输出（配合 gdb 区分）
#define pc dbg_putchar

// ==================== 10. 彩色 cout + getchar 快读（配合 ihxnan.hpp 调试模式）====================

// 与 ihxnan.hpp（提交模式）完全同逻辑的 IO：成员/运算符语义逐一对应，
// 仅把 inc() 换成 getchar（stdio 行缓冲，终端回车即生效、无需 EOF/Ctrl+D；
// 不像 fread 快读会阻塞到 EOF），把 outc() 换成带颜色的 dbg_putchar（紫色，
// 随 dbg_set_color 开关）。
// 类型支持与提交模式完全一致：
//   整数（含 __int128 / bool / 无符号）走 getchar/putchar 快读写；
//   char / const char* / char* / string 同样快读写；
//   其余类型（如 double）与提交模式一样在编译期报错 —— 本地即可发现，
//   不会出现"本地能编译、提交编译失败"。
// 用法：-DIHXNAN 编译时 cin/cout 宏与提交模式完全一致，均指向这里的 fin/fout；
//       注意 IHXNAN 下不要写 std::cout / std::cin（宏替换会编译报错）。
struct IO{
    int st[105];bool ok;
    IO():ok(true){st[0]=0;}
    template<typename T>inline IO&operator<<(T x){int f=0;if constexpr(std::is_signed_v<T>){if(x<0)dbg_putchar('-'),f=1;}do{st[++st[0]]=f?-(x%10):x%10,x/=10;}while(x);while(st[0])dbg_putchar(48^st[st[0]--]);return*this;}
    inline IO&operator<<(char c){dbg_putchar(c);return*this;}inline IO&operator<<(const char*x){while(*x)dbg_putchar(*x++);return*this;}inline IO&operator<<(char*x){while(*x)dbg_putchar(*x++);return*this;}inline IO&operator<<(const string&x){for(auto c:x)dbg_putchar(c);return*this;}
    template<typename T>inline IO&operator>>(T&x){x=0;int f=0,ch=getchar();while(ch!=EOF&&!isdigit(ch)){if(ch=='-')f^=1;ch=getchar();}if(ch==EOF){ok=false;return*this;}while(ch!=EOF&&isdigit(ch))x=(x<<3)+(x<<1)+(ch^48),ch=getchar();f?x=-x:0;return*this;}
    inline IO&operator>>(char&x){int c=getchar();while(c!=EOF&&isspace(c))c=getchar();if(c==EOF){ok=false;return*this;}x=(char)c;return*this;}inline IO&operator>>(string&x){x.clear();int c=getchar();while(c!=EOF&&isspace(c))c=getchar();if(c==EOF){ok=false;return*this;}while(c!=EOF&&!isspace(c))x+=char(c),c=getchar();return*this;}
    inline explicit operator bool()const{return ok;}
}fin,fout;

// IHXNAN 下 cin/cout 宏与提交模式完全一致，均指向 fin/fout。
// 注意勿写 std::cin / std::cout（宏替换会编译报错）。
#define endl '\n'
#define cin fin
#define cout fout
