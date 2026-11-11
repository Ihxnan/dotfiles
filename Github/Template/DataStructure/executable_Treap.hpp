template <class T> struct Treap
{
    struct Node
    {
        T val;
        int key, siz, ch[2];
        void clear()
        {
            ch[0] = ch[1] = siz = key = 0;
            val = T{};
        }
    };

    int cnt, root;
    vector<Node> t;
    mt19937_64 gen;

    Treap(int n) : cnt(0), root(0), t(n + 1), gen(chrono::steady_clock::now().time_since_epoch().count())
    {
    }

    int rnd()
    {
        return int(gen());
    }

    void update(int now)
    {
        t[now].siz = t[t[now].ch[0]].siz + t[t[now].ch[1]].siz + 1;
    }

    int merge(int u, int v)
    {
        if (!u || !v)
            return u | v;
        if (t[u].key < t[v].key)
        {
            t[u].ch[1] = merge(t[u].ch[1], v);
            update(u);
            return u;
        }
        else
        {
            t[v].ch[0] = merge(u, t[v].ch[0]);
            update(v);
            return v;
        }
    }

    void split_val(int now, const T &k, int &x, int &y, bool eq = true)
    {
        if (!now)
            return (void)(x = y = 0);
        if (t[now].val < k || (eq && t[now].val == k))
            x = now, split_val(t[now].ch[1], k, t[now].ch[1], y, eq);
        else
            y = now, split_val(t[now].ch[0], k, x, t[now].ch[0], eq);
        update(now);
    }

    void split_k(int now, int k, int &x, int &y)
    {
        if (!now)
            return (void)(x = y = 0);
        if (t[t[now].ch[0]].siz < k)
            x = now, split_k(t[now].ch[1], k - t[t[now].ch[0]].siz - 1, t[now].ch[1], y);
        else
            y = now, split_k(t[now].ch[0], k, x, t[now].ch[0]);
        update(now);
    }

    T kth(int &now, int k)
    {
        int a, b, c, d;
        split_k(now, k - 1, a, b);
        split_k(b, 1, c, d);
        T res = t[c].val;
        now = merge(a, merge(c, d));
        return res;
    }

    void insert(const T &x)
    {
        int u = ++cnt, a, b;
        t[u].val = x, t[u].key = rnd(), t[u].siz = 1;
        split_val(root, x, a, b);
        root = merge(merge(a, u), b);
    }

    void erase(const T &x)
    {
        int a, b, c, d;
        split_val(root, x, a, b, false);
        split_k(b, 1, c, d);
        if (c && t[c].val == x)
            t[c].clear(), root = merge(a, d);
        else
            root = merge(a, merge(c, d));
    }

    int size()
    {
        return t[root].siz;
    }

    int count(const T &x)
    {
        int a, b, c, d;
        split_val(root, x, a, b, false);
        split_val(b, x, c, d, true);
        int res = t[c].siz;
        root = merge(a, merge(c, d));
        return res;
    }

    int rank(const T &x)
    {
        int a, b;
        split_val(root, x, a, b, false);
        int res = t[a].siz + 1;
        root = merge(a, b);
        return res;
    }

    T val(int k)
    {
        return kth(root, k);
    }

    T pre(const T &x)
    {
        int a, b;
        split_val(root, x, a, b, false);
        T res = kth(a, t[a].siz);
        root = merge(a, b);
        return res;
    }

    T back(const T &x)
    {
        int a, b;
        split_val(root, x, a, b);
        T res = kth(b, 1);
        root = merge(a, b);
        return res;
    }
};
