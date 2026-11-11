template <class T> struct SegmentTree
{
    int n;
    vector<T> in;
    vector<T> tree, tag;

    SegmentTree(int n) : n(n), in(n + 1), tree(4 * n), tag(4 * n)
    {
    }

    SegmentTree(vector<T> &arr) : n(arr.size() - 1), in(arr), tree(4 * n), tag(4 * n)
    {
        build();
    }

    void push_up(int p)
    {
        tree[p] = tree[ls(p)] + tree[rs(p)];
    }

    void build(int p, int l, int r)
    {
        if (l == r)
        {
            tree[p] = in[l];
            return;
        }
        int mid = l + r >> 1;
        build(ls(p), l, mid);
        build(rs(p), mid + 1, r);
        push_up(p);
    }

    void change(int p, int l, int r, T k)
    {
        tree[p] += (r - l + 1) * k;
        tag[p] += k;
    }

    void push_down(int p, int l, int r)
    {
        if (tag[p])
        {
            int mid = l + r >> 1;
            change(ls(p), l, mid, tag[p]);
            change(rs(p), mid + 1, r, tag[p]);
            tag[p] = 0;
        }
    }

    void update(int ul, int ur, int p, int l, int r, T k)
    {
        if (ul <= l && r <= ur)
        {
            change(p, l, r, k);
            return;
        }
        push_down(p, l, r);
        int mid = l + r >> 1;
        if (ul <= mid)
            update(ul, ur, ls(p), l, mid, k);
        if (ur > mid)
            update(ul, ur, rs(p), mid + 1, r, k);
        push_up(p);
    }

    T query(int ql, int qr, int p, int l, int r)
    {
        if (ql <= l && r <= qr)
            return tree[p];
        push_down(p, l, r);
        T ans = 0;
        int mid = l + r >> 1;
        if (ql <= mid)
            ans += query(ql, qr, ls(p), l, mid);
        if (qr > mid)
            ans += query(ql, qr, rs(p), mid + 1, r);
        return ans;
    }

    void build()
    {
        build(1, 1, n);
    }

    void update(int ul, int ur, T k)
    {
        update(ul, ur, 1, 1, n, k);
    }

    T query(int ql, int qr)
    {
        return query(ql, qr, 1, 1, n);
    }
};
