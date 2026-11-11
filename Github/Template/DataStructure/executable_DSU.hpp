struct DSU
{
    vector<int> fa, sz;

    DSU(int n) : fa(n + 1), sz(n + 1, 1)
    {
        iota(fa.begin(), fa.end(), 0);
    }

    int get(int x)
    {
        while (x != fa[x])
            x = fa[x] = fa[fa[x]];
        return x;
    }

    bool merge(int x, int y)
    {
        if ((x = get(x)) == (y = get(y)))
            return false;
        fa[y] = x;
        sz[x] += sz[y];
        return true;
    }

    bool same(int x, int y)
    {
        return get(x) == get(y);
    }

    int size(int x)
    {
        return sz[get(x)];
    }
};
