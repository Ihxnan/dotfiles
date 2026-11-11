struct Comb
{
    int n;
    ll mod;
    vector<ll> _fac, _inv;

    Comb(ll mod) : n(0), mod(mod), _fac{1}, _inv{1}
    {
    }

    ll qmi(ll a, ll b)
    {
        ll ans = 1;
        for (; b; b >>= 1, a = a * a % mod)
            if (b & 1)
                ans = ans * a % mod;
        return ans;
    }

    void init(int m)
    {
        if (m <= n)
            return;
        _fac.resize(m + 1);
        _inv.resize(m + 1);
        for (int i = n + 1; i <= m; ++i)
            _fac[i] = _fac[i - 1] * i % mod;
        _inv[m] = qmi(_fac[m], mod - 2);
        for (int i = m; i > n; --i)
            _inv[i - 1] = _inv[i] * i % mod;
        n = m;
    }

    ll fac(int x)
    {
        if (x > n)
            init(x);
        return _fac[x];
    }

    ll inv(ll x)
    {
        return qmi(x, mod - 2);
    }

    ll ifac(int x)
    {
        if (x > n)
            init(x);
        return _inv[x];
    }

    ll C(int x, int y)
    {
        if (x < 0 || y < 0 || x < y)
            return 0;
        return fac(x) * ifac(y) % mod * ifac(x - y) % mod;
    }

    ll P(int x, int y)
    {
        if (x < 0 || y < 0 || x < y)
            return 0;
        return fac(x) * ifac(x - y) % mod;
    }
};
