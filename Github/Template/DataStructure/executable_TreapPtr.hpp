template <class T> struct TreapPtr
{
    struct Node
    {
        T val;
        int key, siz;
        Node *ch[2];
        Node(const T &v = T{}, int k = 0) : val(v), key(k), siz(1)
        {
            ch[0] = ch[1] = nullptr;
        }
    };

    Node *root;
    vector<Node *> pool, trash;
    mt19937_64 gen;

    TreapPtr() : root(nullptr), gen(chrono::steady_clock::now().time_since_epoch().count()) {}
    TreapPtr(const TreapPtr &) = delete;
    TreapPtr &operator=(const TreapPtr &) = delete;
    ~TreapPtr()
    {
        for (Node *p : pool)
            delete p;
    }

    int rnd()
    {
        return int(gen());
    }

    int sz(Node *p)
    {
        return p ? p->siz : 0;
    }

    Node *newNode(const T &v)
    {
        Node *p;
        if (!trash.empty())
        {
            p = trash.back(), trash.pop_back();
            p->val = v, p->key = rnd(), p->siz = 1;
            p->ch[0] = p->ch[1] = nullptr;
        }
        else
            pool.push_back(p = new Node(v, rnd()));
        return p;
    }

    void update(Node *now)
    {
        now->siz = sz(now->ch[0]) + sz(now->ch[1]) + 1;
    }

    Node *merge(Node *u, Node *v)
    {
        if (!u || !v)
            return u ? u : v;
        if (u->key < v->key)
        {
            u->ch[1] = merge(u->ch[1], v);
            update(u);
            return u;
        }
        else
        {
            v->ch[0] = merge(u, v->ch[0]);
            update(v);
            return v;
        }
    }

    void split_val(Node *now, const T &k, Node *&x, Node *&y, bool eq = true)
    {
        if (!now)
            return (void)(x = y = nullptr);
        if (now->val < k || (eq && now->val == k))
            x = now, split_val(now->ch[1], k, now->ch[1], y, eq);
        else
            y = now, split_val(now->ch[0], k, x, now->ch[0], eq);
        update(now);
    }

    void split_k(Node *now, int k, Node *&x, Node *&y)
    {
        if (!now)
            return (void)(x = y = nullptr);
        if (sz(now->ch[0]) < k)
            x = now, split_k(now->ch[1], k - sz(now->ch[0]) - 1, now->ch[1], y);
        else
            y = now, split_k(now->ch[0], k, x, now->ch[0]);
        update(now);
    }

    T kth(Node *&now, int k)
    {
        Node *a, *b, *c, *d;
        split_k(now, k - 1, a, b);
        split_k(b, 1, c, d);
        T res = c ? c->val : T{};
        now = merge(a, merge(c, d));
        return res;
    }

    void insert(const T &x)
    {
        Node *a, *b;
        split_val(root, x, a, b);
        root = merge(merge(a, newNode(x)), b);
    }

    void erase(const T &x)
    {
        Node *a, *b, *c, *d;
        split_val(root, x, a, b, false);
        split_k(b, 1, c, d);
        if (c && c->val == x)
            trash.push_back(c), root = merge(a, d);
        else
            root = merge(a, merge(c, d));
    }

    int size()
    {
        return sz(root);
    }

    int count(const T &x)
    {
        Node *a, *b, *c, *d;
        split_val(root, x, a, b, false);
        split_val(b, x, c, d, true);
        int res = sz(c);
        root = merge(a, merge(c, d));
        return res;
    }

    int rank(const T &x)
    {
        Node *a, *b;
        split_val(root, x, a, b, false);
        int res = sz(a) + 1;
        root = merge(a, b);
        return res;
    }

    T val(int k)
    {
        return kth(root, k);
    }

    T pre(const T &x)
    {
        Node *a, *b;
        split_val(root, x, a, b, false);
        T res = kth(a, sz(a));
        root = merge(a, b);
        return res;
    }

    T back(const T &x)
    {
        Node *a, *b;
        split_val(root, x, a, b);
        T res = kth(b, 1);
        root = merge(a, b);
        return res;
    }
};
