vector<int> prime;
vector<bool> is_prime;

void euler_prime(int n)
{
    is_prime.resize(n + 1, true);
    for (int i = 2; i <= n; ++i)
    {
        if (is_prime[i])
            prime.push_back(i);
        for (auto &p : prime)
        {
            if (p * i > n)
                break;
            is_prime[i * p] = false;
            if (i % p == 0)
                break;
        }
    }
}
