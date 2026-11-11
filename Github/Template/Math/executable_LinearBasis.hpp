template <typename T> struct LinearBasis
{
    const int BITS = sizeof(T) * 8;
    int sz;
    bool zero;
    vector<T> basis;
    vector<T> standard;

    LinearBasis() : sz(0), zero(false), basis(BITS, T(0))
    {
    }

    void rebuild()
    {
        for (int i = BITS - 1; i >= 0; i--)
            for (int j = i - 1; j >= 0; j--)
                if (basis[i] >> j & 1)
                    basis[i] ^= basis[j];

        standard.clear();
        for (int i = 0; i < BITS; i++)
            if (basis[i])
                standard.push_back(basis[i]);
    }

    void clear()
    {
        sz = 0;
        zero = false;
        basis.assign(BITS, T(0));
        standard.clear();
    }

    bool insert(T x)
    {
        for (int i = BITS - 1; i >= 0; i--)
            if (x >> i & 1)
            {
                if (!basis[i])
                {
                    basis[i] = x, ++sz;
                    return true;
                }
                x ^= basis[i];
            }
        zero = true;
        return false;
    }

    bool find(T x)
    {
        for (int i = BITS - 1; i >= 0; i--)
            if (x >> i & 1)
            {
                if (!basis[i])
                    return false;
                x ^= basis[i];
            }
        return true;
    }

    T max()
    {
        T res = 0;
        for (int i = BITS - 1; i >= 0; --i)
            res = std::max(res, res ^ basis[i]);
        return res;
    }

    T min()
    {
        for (int i = 0; i < BITS; ++i)
            if (basis[i])
                return basis[i];
        return 0;
    }

    int size()
    {
        return sz;
    }

    T kth(T k)
    {
        if (standard.empty())
            rebuild();
        if (zero)
            --k;
        T res = T(0);
        for (auto &x : standard)
        {
            if (k & 1)
                res ^= x;
            k >>= 1;
        }
        return k ? T(-1) : res;
    }
};
