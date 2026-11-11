#include <algorithm>
#include <cassert>
#include <chrono>
#include <iostream>
#include <numeric>
#include <random>
#include <set>
#include <string>
#include <utility>
#include <vector>

using namespace std;
using ll = long long;

// 随机数据生成器：对拍时直接用全局实例 g
//   例: int n = g.rd(1, 10); cout << n << endl; g.array(n, 100);
//       g.permutation(n);
//       auto a = g.gen_array(n, 1, 1e9);                       // 拿到数据自行加工
//       g.print(g.gen_graph(n, m, 1, true, true, true, -10, 10)); // 1基/有向/连通/带权[-10,10]
//       g.print(g.gen_bracket(n));                             // 合法括号序列
class Generator
{
    mt19937_64 gen;

  public:
    Generator() : gen(chrono::steady_clock::now().time_since_epoch().count())
    {
    }

    // ================= 基础随机 =================
    // [l, r] 内随机整数（支持负数）
    ll rd(ll l, ll r)
    {
        assert(l <= r);
        return uniform_int_distribution<ll>(l, r)(gen);
    }
    // 0 或 1
    ll rd01() { return rd(0, 1); }
    // [l, r) 内随机浮点
    double rdf(double l, double r) { return uniform_real_distribution<double>(l, r)(gen); }
    // 从容器中随机取一个元素
    template <class T> const T &pick(const vector<T> &v)
    {
        assert(!v.empty());
        return v[rd(0, (ll)v.size() - 1)];
    }
    // 打乱容器（vector / string 均可），返回引用便于链式调用
    template <class T> T &shuffle(T &v)
    {
        std::shuffle(v.begin(), v.end(), gen);
        return v;
    }

    // ================= 字符集 =================
    static inline const string LOWER = "abcdefghijklmnopqrstuvwxyz";
    static inline const string UPPER = "ABCDEFGHIJKLMNOPQRSTUVWXYZ";
    static inline const string DIGIT = "0123456789";
    static inline const string MIXED = LOWER + UPPER + DIGIT;

    // ================= 数据生成（返回数据，便于加工） =================
    // n 个 [l, r] 内整数（可重复）
    vector<ll> gen_array(int n, ll l, ll r)
    {
        vector<ll> a(n);
        for (auto &x : a)
            x = rd(l, r);
        return a;
    }
    vector<ll> gen_array(int n, ll range = 1e9) { return gen_array(n, 1, range); }
    // 从 [l, r] 取 n 个互不相同的整数（区间很大时用采样，不爆内存）
    vector<ll> gen_distinct(int n, ll l, ll r)
    {
        assert(n <= r - l + 1);
        if (n <= (r - l + 1) / 2)
        {
            set<ll> s;
            while ((ll)s.size() < n)
                s.insert(rd(l, r));
            return vector<ll>(s.begin(), s.end());
        }
        vector<ll> v(r - l + 1);
        iota(v.begin(), v.end(), l);
        shuffle(v);
        v.resize(n);
        return v;
    }
    // 1..n 的随机排列
    vector<int> gen_permutation(int n)
    {
        vector<int> p(n);
        iota(p.begin(), p.end(), 1);
        shuffle(p);
        return p;
    }
    // 随机字符串：从 chars 中取 n 个字符
    string gen_str(int n, const string &chars = LOWER)
    {
        string s;
        s.reserve(n);
        for (int i = 0; i < n; ++i)
            s += chars[rd(0, (ll)chars.size() - 1)];
        return s;
    }
    // n 对括号的随机合法括号序列（均匀分布）
    string gen_bracket(int n)
    {
        string s(n, '(');
        s += string(n, ')');
        shuffle(s);
        int bal = 0, mn = 0, pos = 0;
        for (int i = 0; i < 2 * n; ++i)
        {
            bal += (s[i] == '(' ? 1 : -1);
            if (bal < mn)
                mn = bal, pos = i + 1;
        }
        return s.substr(pos) + s.substr(0, pos);
    }
    // n 个随机区间 [a, b]（保证 a <= b）
    vector<pair<ll, ll>> gen_intervals(int n, ll l, ll r)
    {
        vector<pair<ll, ll>> v;
        v.reserve(n);
        for (int i = 0; i < n; ++i)
        {
            ll a = rd(l, r), b = rd(l, r);
            if (a > b)
                swap(a, b);
            v.emplace_back(a, b);
        }
        return v;
    }
    // n 行 m 列矩阵，元素 [l, r]
    vector<vector<ll>> gen_matrix(int n, int m, ll l, ll r)
    {
        vector<vector<ll>> a(n);
        for (auto &row : a)
            row = gen_array(m, l, r);
        return a;
    }

    // ================= 图 =================
    struct Graph
    {
        vector<pair<int, int>> e; // 边
        vector<ll> w;             // 权值（weighted 时与 e 等长）
    };
    // 通用图生成
    // base:     节点编号起点（0 或 1）
    // directed: 有向边
    // connect:  保证连通（m 过小时自动补到 n-1）
    // weighted: 带权 [wl, wr]（可负）
    // self_loop: 允许自环; multi: 允许重边
    // renumber: 随机重标号节点（打破固定编号顺序）
    // 注意: m 越界（> 饱和边数）时自动 clamp 到饱和；connect 时 m < n-1 自动补到 n-1
    Graph gen_graph(int n, int m, int base = 1, bool directed = false, bool connect = true,
                    bool weighted = false, ll wl = 1, ll wr = 1e9,
                    bool self_loop = false, bool multi = false, bool renumber = true)
    {
        assert(n >= 1 && m >= 0);
        assert(base == 0 || base == 1);
        ll max_edges = self_loop ? (ll)n * n : (ll)n * (n - 1);
        if (!directed)
            max_edges = self_loop ? (ll)n * (n + 1) / 2 : (ll)n * (n - 1) / 2;
        if (connect && n > 1)
            m = max(m, n - 1); // 连通至少需要 n-1 条边
        if (!multi)
            m = (int)min((ll)m, max_edges); // 不超过无重边上限
        if (!self_loop && n == 1)
            m = 0; // 单点无自环时没有任何合法边（含重边）

        Graph g;
        g.e.reserve(m);
        set<pair<int, int>> used;
        auto push = [&](int a, int b)
        {
            g.e.emplace_back(a, b);
            if (weighted)
                g.w.push_back(rd(wl, wr));
        };

        // 先生成连通生成树，保证连通
        if (connect && n > 1)
            for (int i = 1; i < n; ++i)
            {
                int p = rd(0, i - 1);
                int x = i, y = p;
                if (directed && rd01())
                    swap(x, y);
                push(x, y);
                used.insert(directed ? make_pair(x, y) : make_pair(min(x, y), max(x, y)));
            }

        // 补足剩余边
        int fail = 0;
        while ((int)g.e.size() < m)
        {
            int a = rd(0, n - 1), b = rd(0, n - 1);
            pair<int, int> key = directed ? make_pair(a, b) : make_pair(min(a, b), max(a, b));
            if ((!self_loop && a == b) || (!multi && used.count(key)))
            {
                if (++fail > 200000)
                { // 图接近饱和时随机采样过慢，顺序扫描补齐
                    for (int x = 0; x < n && (int)g.e.size() < m; ++x)
                        for (int y = 0; y < n && (int)g.e.size() < m; ++y)
                        {
                            if (!self_loop && x == y)
                                continue;
                            pair<int, int> k = directed ? make_pair(x, y) : make_pair(min(x, y), max(x, y));
                            if (!multi && used.count(k))
                                continue;
                            push(x, y);
                            used.insert(k);
                        }
                    break;
                }
                continue;
            }
            fail = 0;
            push(a, b);
            used.insert(key);
        }

        // 编号映射（0..n-1 -> base..base+n-1，可随机置换）
        vector<int> id(n);
        iota(id.begin(), id.end(), 0);
        if (renumber && n > 1)
            shuffle(id);
        for (auto &[a, b] : g.e)
        {
            a = id[a] + base;
            b = id[b] + base;
        }
        return g;
    }
    // 随机树（n 点，等价于连通的 n-1 边无向图）
    Graph gen_tree(int n, int base = 1, bool weighted = false, ll wl = 1, ll wr = 1e9)
    {
        return gen_graph(n, n - 1, base, false, true, weighted, wl, wr, false, false, true);
    }

    // ================= 输出 =================
    template <class T> void print(const vector<T> &v)
    {
        for (size_t i = 0; i < v.size(); ++i)
        {
            if (i)
                cout << ' ';
            cout << v[i];
        }
        cout << '\n';
    }
    void print(const string &s) { cout << s << '\n'; }
    template <class K, class V> void print(const vector<pair<K, V>> &v)
    {
        for (const auto &[a, b] : v)
            cout << a << ' ' << b << '\n';
    }
    template <class T> void print(const vector<vector<T>> &a)
    {
        for (const auto &row : a)
            print(row);
    }
    void print(const Graph &g)
    {
        for (size_t i = 0; i < g.e.size(); ++i)
        {
            cout << g.e[i].first << ' ' << g.e[i].second;
            if (!g.w.empty())
                cout << ' ' << g.w[i];
            cout << '\n';
        }
    }

    // ================= 旧接口（直接输出，兼容原有写法） =================
    void str(int n, bool num = false) { print(gen_str(n, num ? MIXED : LOWER)); }
    void array(int n, int range = 1e5) { print(gen_array(n, 1, range)); }
    void permutation(int n) { print(gen_permutation(n)); }
    void graph(int n, int m, bool weight = false, int range = 1e5, int root = -1)
    {
        (void)root;
        print(gen_graph(n, m, 1, false, true, weight, 1, range, false, false, true));
    }
    void tree(int n, bool weight = false, int range = 1e5, int root = -1)
    {
        graph(n, n - 1, weight, range, root);
    }
} g;
