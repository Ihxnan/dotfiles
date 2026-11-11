vector<int> Bases{2, 3, 5, 7, 11, 13, 17, 19, 23};

ll mul(ll a, ll b, ll m)
{
    return lll(a) * b % m;
}

ll qmi(ll a, ll b, ll mod)
{
    ll res = 1;
    for (; b; b >>= 1, a = mul(a, a, mod))
        if (b & 1)
            res = mul(res, a, mod);
    return res;
}

bool is_prime(ll n)
{
    if (n < 2)
        return false;
    int s = __builtin_ctzll(n - 1);
    ll d = (n - 1) >> s;
    for (auto &p : Bases)
    {
        if (p == n)
            return true;
        ll x = qmi(p, d, n);
        if (x == 1 || x == n - 1)
            continue;
        bool ok = false;
        for (int i = 0; i < s - 1; ++i)
        {
            x = mul(x, x, n);
            if (x == n - 1)
            {
                ok = true;
                break;
            }
        }
        if (!ok)
            return false;
    }
    return true;
}

vector<ll> factorize(ll n)
{
    vector<ll> factors;
    auto dfs = [&](auto &&self, ll n) {
        if (n <= 10000)
        {
            for (int i = 2; i * i <= n; ++i)
                for (; n % i == 0; n /= i)
                    factors.push_back(i);
            if (n > 1)
                factors.push_back(n);
            return;
        }
        if (is_prime(n))
        {
            factors.push_back(n);
            return;
        }
        ll c = 1;
        auto rho_func = [&](ll x) { return (mul(x, x, n) + c) % n; };
        ll x0 = 2;
        while (true)
        {
            ll x = x0;
            ll y = x0;
            ll d = 1;
            ll power = 1, lam = 0;
            ll v = 1;
            while (d == 1)
            {
                y = rho_func(y);
                ++lam;
                v = mul(v, abs(x - y), n);
                if (lam % 127 == 0)
                {
                    d = gcd(v, n);
                    v = 1;
                }
                if (power == lam)
                {
                    x = y;
                    power *= 2;
                    lam = 0;
                    d = gcd(v, n);
                    v = 1;
                }
            }
            if (d != n)
            {
                self(self, d);
                self(self, n / d);
                return;
            }
            ++x0;
            ++c;
        }
    };
    dfs(dfs, n);
    sort(factors.begin(), factors.end());
    return factors;
}
