```cpp
void solve() {
    int n;
    cin >> n;

    AhoCorasick ac;
    string str;
    vi ends(n);                       // 每个模式串的终点编号

    for (auto &p : ends) {
        cin >> str;
        p = ac.add(str);
    }
    ac.work();                        // 所有串加完后统一构建

    cin >> str;                       // 文本
    vi cnt(ac.size());                // cnt[x]：状态 x 被经过的次数
    int p = 1;
    for (auto &ch : str)
        ++cnt[p = ac.next(p, ch - 'a')];

    // 按串长降序 = fail 树自底向上的拓扑序
    vi order(ac.size());
    iota(order.begin(), order.end(), 0);
    sort(order.begin(), order.end(),
         [&](int a, int b) { return ac.len(a) > ac.len(b); });

    for (auto &q : order)
        cnt[ac.link(q)] += cnt[q];    // 子树和推给 fail 父亲

    for (auto &p : ends)
        cout << cnt[p] << endl;       // 每个模式串的出现次数
}
```

```cpp
auto manacher = [](string s) -> vector<int> {
    string str = "^#";                  // '^' 左哨兵，'#' 分隔符；二者不能出现在原串
    for (auto &p : s)
        str += p, str += '#';           // 逗号运算符：先接字符再接 '#'
    // "abc" -> "^#a#b#c#"，长度 2n+2，s[k] 位于 str[2k+2]

    vector<int> len(str.size());        // 长度 2n+2，全 0；len[0] 不用

    for (int i = 1, r = 1, mid = 0; i < str.size(); ++i) {
        // r：已发现回文的最右边界（开区间）；mid：取到该边界的中心
        if (i < r)
            // 镜像优化：i 关于 mid 对称到 2*mid-i。
            // 初值取 min(镜像值, 到边界距离)，只会低估，不会高估。
            len[i] = min(len[2 * mid - i], r - i);

        // 从初值继续向两边扩；第一次比较 str[i] 与自身，必然成功
        while (str[i + len[i]] == str[i - len[i]])
            ++len[i];

        if (i + len[i] > r)             // 更新最右边界
            r = i + len[i], mid = i;
    }
    return len;
};
```

```bash
g++ -O2 data.cpp -o data.out      # 编译数据生成器
g++ -O2 ans.cpp  -o ans.out       # 编译标准解
g++ -O2 test.cpp -o test.out      # 编译待测解

N=100                             # 默认对拍轮数

if [ "${1}" != "" ]; then         # 有第一个参数就覆盖轮数
    N=${1}
fi

cnt=0
while [ ${cnt} -lt ${N} ]; do      # 循环 N 轮
    cnt=$((cnt + 1))
    echo 第 ${cnt} 组

    ./data.out > data.txt                 # 1. 造数据
    ./ans.out < data.txt > ans.txt         # 2. 标准答案
    ./test.out < data.txt > test.txt       # 3. 待测输出

    if ! diff ans.txt test.txt; then       # 4. 有差异：diff 会打印不同行
        echo "Wrong"
        exit 0                             #    退出；现场文件保留，方便复现
    fi
done
```
