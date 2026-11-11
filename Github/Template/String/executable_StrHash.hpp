struct StrHash {
    ul base;
    vector<ul> pow, h, rh;

    StrHash(const string &str) : base(13331)
    {
        int n = str.size();
        pow.resize(n + 1);
        h.resize(n + 1);
        rh.resize(n + 1);
        pow[0] = 1, h[0] = 0, rh[n] = 0;
        for (int i = 0; i < n; i++)
        {
            pow[i + 1] = pow[i] * base;
            h[i + 1] = h[i] * base + str[i];
        }
        for (int i = n - 1; i >= 0; i--)
            rh[i] = rh[i + 1] * base + str[i];
    }

    ul full()
    {
        return h.back();
    }

    ul get(int l, int r)
    {
        return h[r + 1] - h[l] * pow[r - l + 1];
    }

    ul rget(int l, int r)
    {
        return rh[l] - rh[r + 1] * pow[r - l + 1];
    }

    ul link(int l1, int r1, int l2, int r2)
    {
        return get(l1, r1) * pow[r2 - l2 + 1] + get(l2, r2);
    }

    bool same(int l1, int r1, int l2, int r2)
    {
        return get(l1, r1) == get(l2, r2);
    }

    bool is_palindrome(int l, int r)
    {
        return get(l, r) == rget(l, r);
    }
};
