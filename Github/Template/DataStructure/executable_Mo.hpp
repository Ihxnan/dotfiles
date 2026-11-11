// ============================================================================
// 莫队 Mo's algorithm —— 片段式模板 (需配合 Template/ihxnan.hpp 使用)
// ----------------------------------------------------------------------------
// 约定: 数组 1-indexed; 依赖 ihxnan.hpp 的别名 ti/vi/vl 与分块宏 bi(x);
//       bi(x) = ((x) - 1) / blen, 故作用域内必须有名为 blen 的块长变量;
//       回滚莫队/P4137 中的 bl()/br() 还依赖名为 n 的变量。
// 用法: 片段式 (同 Math/Exgcd.hpp、Graph/Hungarian.hpp), 把所需片段粘进
//       solve() 后按题目改写 ins/del 等 lambda, 不能直接 #include 编译。
//       下面四段是互斥变体, 每次只取其中一段 (会重复定义 blen/qry 等)。
// ============================================================================


// ============================================================================
// 一、普通莫队 (P2709 小 B 的询问 / P3901 数列找不同 / P1494 小 Z 的袜子)
// 适用: 静态区间, 单个元素可 O(1) 增删贡献, 无修改.
// 前置: int n, m; vi arr(n + 1); (已读入)
// ============================================================================
int blen = sqrt(n); // 块长一般取 sqrt(n)
vector<ti> qry(m);  // (l, r, id), 1-indexed
int dn = 0;
for (auto &[l, r, id] : qry)
    cin >> l >> r, id = dn++;

sort(qry.begin(), qry.end(), [&](auto &x, auto &y) {
    auto &[l1, r1, id1] = x;
    auto &[l2, r2, id2] = y;
    if (bi(l1) != bi(l2))
        return bi(l1) < bi(l2);
    return bi(l1) & 1 ? r1 > r2 : r1 < r2; // 奇偶优化: 块内 r 交替方向
});

vl ans(m);
int left = 1, right = 0; // 空窗口 [1, 0]

// ---- 按题目维护 "增删一个下标" 对答案的贡献 (改下面两个 lambda) ----
// 例 (P2709, 求同色对数): cnt 为颜色计数, res 为答案
vi cnt(k + 1);
ll res = 0;
auto ins = [&](int x) -> void { res += 2 * ++cnt[arr[x]] - 1; };
auto del = [&](int x) -> void { res -= 2 * cnt[arr[x]]-- - 1; };
// P3901 (区间是否无重复, sum 记种类数):
//     ins: if (++vis[arr[x]] == 1) ++sum;   del: if (!--vis[arr[x]]) --sum;
// P1494 (维护 A, B): ins: ++B, A += 2 * cnt[arr[x]]++;
//                    del: --B, A -= 2 * --cnt[arr[x]];
// -------------------------------------------------------------------

for (auto &[l, r, id] : qry)
{
    while (left < l)
        del(left++);
    while (left > l)
        ins(--left);
    while (right < r)
        ins(++right);
    while (right > r)
        del(right--);
    ans[id] = res; // 到达 [l, r] 后取当前答案
}
for (auto &p : ans)
    cout << p << endl;


// ============================================================================
// 二、莫队 + 值域分块 (P4137 Rmq Problem / mex)
// 在普通莫队基础上, 额外维护值域块 "已出现的不同值个数" tag[],
// 于是求 mex 只需 O(√n): 先跳到第一个未满的块, 再块内找第一个未出现的值.
// 前置: int n, m; vi arr(n + 1);
// ============================================================================
int blen = max(2, (int)sqrt(n)); // 值域分块需 blen>=2, 才能保证 bi(0)=0 (值 0 归入第 0 块)
int bnum = (n + blen - 1) / blen; // 值域块数

vector<ti> qry(m);
int dn = 0;
for (auto &[l, r, id] : qry)
    cin >> l >> r, id = dn++;

sort(qry.begin(), qry.end(), [&](auto &x, auto &y) {
    auto &[l1, r1, id1] = x;
    auto &[l2, r2, id2] = y;
    if (bi(l1) != bi(l2))
        return l1 < l2;
    return bi(l1) & 1 ? r1 > r2 : r1 < r2;
});

vi tag(bnum), ans(m), cnt(n + 1);
int left = 1, right = 0;

auto ins = [&](int x) -> void { // 只统计 <= n 的值 (mex 一定 <= n)
    if (arr[x] <= n && ++cnt[arr[x]] == 1)
        ++tag[bi(arr[x])];
};
auto del = [&](int x) -> void {
    if (arr[x] <= n && !--cnt[arr[x]])
        --tag[bi(arr[x])];
};

for (auto &[l, r, id] : qry)
{
    while (left < l)
        del(left++);
    while (left > l)
        ins(--left);
    while (right < r)
        ins(++right);
    while (right > r)
        del(right--);

    int idx = 0; // 找第一个 "块内值未全部出现" 的块 (第 0 块含 0 号值, 多一个)
    while (tag[idx] == br(idx) - bl(idx) + 1 + !idx)
        ++idx;
    idx = bl(idx) - !idx; // 定位到该块左端 (第 0 块从 0 开始)
    while (cnt[idx])      // 块内线性找第一个未出现的值
        ++idx;
    ans[id] = idx;
}
for (auto &p : ans)
    cout << p << endl;


// ============================================================================
// 三、带修莫队 (P1903 数颜色 / [国家集训队] 维护队列)
// 查询是三维 (l, r, 时间 t) 的莫队, 块长取 n^(2/3).
// 修改存 (pos, after, before); front/back 沿时间轴应用 / 撤销修改.
// 前置: int n, m; vi arr(n + 1);
// ============================================================================
int blen = pow(n, 0.66);               // 带修块长 ≈ n^(2/3)
vector<tuple<int, int, int, int>> qry; // (l, r, t, id)
vector<ti> func;                       // (pos, after, before)
int t = 0, dn = 0;
vi tmp = arr; // 沿操作顺序推进, 记录每次修改的 before
for (int i = 0, l, r; i < m; ++i)
{
    char op;
    cin >> op >> l >> r;
    if (op == 'Q')
        qry.emplace_back(l, r, t, dn++);
    else
        func.emplace_back(l, r, tmp[l]), tmp[l] = r, ++t;
}

sort(qry.begin(), qry.end(), [&](auto &x, auto &y) {
    auto &[l1, r1, t1, id1] = x;
    auto &[l2, r2, t2, id2] = y;
    if (bi(l1) != bi(l2))
        return bi(l1) < bi(l2);
    if (bi(r1) != bi(r2))
        return bi(l1) & 1 ? r1 > r2 : r1 < r2;
    return bi(l1) + bi(r1) & 1 ? t1 > t2 : t1 < t2; // 时间维同样奇偶优化
});

vi ans(dn);
int left = 1, right = 0, time = 0;

// ---- 按题目维护贡献 (以 "颜色种类数" 为例) ----
vi cnt(1000001);
int sum = 0;
auto ins = [&](int x) -> void { sum += ++cnt[arr[x]] == 1; };
auto del = [&](int x) -> void { sum -= !--cnt[arr[x]]; };
// -----------------------------------------------

auto front = [&](int x) -> void { // 时间前进: 应用第 x 次修改
    auto &[pos, after, before] = func[x];
    arr[pos] = after;
    if (left <= pos && pos <= right) // 落点当前在窗口内才需改贡献
        sum -= !--cnt[before], sum += ++cnt[after] == 1;
};
auto back = [&](int x) -> void { // 时间回退: 撤销第 x 次修改
    auto &[pos, after, before] = func[x];
    arr[pos] = before;
    if (left <= pos && pos <= right)
        sum -= !--cnt[after], sum += ++cnt[before] == 1;
};

for (auto &[l, r, t, id] : qry)
{
    while (left < l)
        del(left++);
    while (left > l)
        ins(--left);
    while (right < r)
        ins(++right);
    while (right > r)
        del(right--);
    while (time < t) // 时间轴对齐
        front(time++);
    while (time > t)
        back(--time);
    ans[id] = sum;
}
for (auto &p : ans)
    cout << p << endl;


// ============================================================================
// 四、回滚莫队 (P14420 [JOISC 2014] 历史的研究)
// 适用: 只有 "加入" 好维护、"删除" 难维护 (如区间 max).
// 右端点在块内只增; 左端点临时加入后整体回滚 (撤销).
// 前置: int n, q; vl arr(n + 1);  (值域大, 计数用 map)
// ============================================================================
int blen = sqrt(n);
vector<ti> qry(q); // (l, r, id)
int dn = 0;
for (auto &[l, r, id] : qry)
    cin >> l >> r, id = dn++;

sort(qry.begin(), qry.end(), [&](auto &x, auto &y) {
    auto &[l1, r1, id1] = x;
    auto &[l2, r2, id2] = y;
    if (bi(l1) != bi(l2))
        return l1 < l2;
    return r1 < r2; // 同块内 r 升序 (右端只增)
});

vl ans(q);
int block = -1;
ll cur = 0, back = 0;
int left = 1, right = 0;
unordered_map<int, int> cnt; // 值域大用 map / unordered_map

auto ins = [&](int x) -> void { cur = max(cur, arr[x] * ++cnt[arr[x]]); };
auto del = [&](int x) -> void { --cnt[arr[x]]; }; // 只回退计数, 不动 cur

for (auto &[l, r, id] : qry)
{
    if (block <= bi(l)) // 进入新块: 把窗口重置为该块右侧的空窗口
    {
        block = bi(l) + 1;
        while (left < br(block - 1) + 1) // 移到 "上一块右端之后"; 末块不满时 bl(block) 会越过 n, 故用 br+1
            del(left++);
        while (right < br(block - 1))
            ins(++right);
        while (right > br(block - 1))
            del(right--);
        cur = 0; // 窗口已清空; del 不维护 cur 故需显式归零
    }

    if (bi(l) == bi(r)) // 同块: 直接暴力扫 [l, r]
    {
        ll res = 0;
        for (int i = l; i <= r; ++i)
            res = max(res, arr[i] * ++cnt[arr[i]]);
        for (int i = l; i <= r; ++i)
            --cnt[arr[i]];
        ans[id] = res;
    }
    else // 跨块: 右端只增, 左端临时加入后回滚
    {
        while (right < r)
            ins(++right);
        back = cur; // 快照右端贡献
        while (left > l)
            ins(--left);
        ans[id] = cur;
        while (left < br(block - 1) + 1) // 撤销左端临时加入, 回到 "上一块右端之后"
            del(left++);
        cur = back; // 恢复快照
    }
}
for (auto &p : ans)
    cout << p << endl;
