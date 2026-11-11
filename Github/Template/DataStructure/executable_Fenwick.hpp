template <typename T> struct Fenwick
{
    int n;
    vector<T> tree;

    Fenwick(int n) : n(n), tree(n + 1)
    {
    }

    void add(int x, const T &v)
    {
        for (; x <= n; x += x & -x)
            tree[x] += v;
    }

    T query(int x)
    {
        T ans{};
        for (; x > 0; x -= x & -x)
            ans += tree[x];
        return ans;
    }

    T query(int l, int r)
    {
        return query(r) - query(l - 1);
    }

    int select(const T &k)
    {
        int x = 0;
        T cur{};
        for (int i = 1 << __lg(n); i; i >>= 1)
            if (x + i <= n && cur + tree[x + i] <= k)
                cur += tree[x += i];
        return x;
    }
};
