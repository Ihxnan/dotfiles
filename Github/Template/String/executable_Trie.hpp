struct Trie
{
    int tot;
    vector<int> pass, end;
    vector<vector<int>> trie;

    int get(const char &x)
    {
        if (x >= 'a' && x <= 'z')
            return x - 'a';
        if (x >= 'A' && x <= 'Z')
            return x - 'A' + 26;
        return x - '0' + 52;
    }

    Trie(int n) : tot(0), pass(n + 5), end(n + 5), trie(n + 5, vector<int>(62))
    {
    }

    void insert(const string &str)
    {
        int cur = 0;
        ++pass[cur];
        for (auto &p : str)
        {
            int x = get(p);
            if (!trie[cur][x])
                trie[cur][x] = ++tot;
            cur = trie[cur][x];
            ++pass[cur];
        }
        ++end[cur];
    }

    int search(const string &str)
    {
        int cur = 0;
        for (auto &p : str)
        {
            int x = get(p);
            if (!trie[cur][x])
                return 0;
            cur = trie[cur][x];
        }
        return end[cur];
    }

    int query(const string &str)
    {
        int cur = 0;
        for (auto &p : str)
        {
            int x = get(p);
            if (!trie[cur][x])
                return 0;
            cur = trie[cur][x];
        }
        return pass[cur];
    }

    void del(const string &str)
    {
        if (search(str) > 0)
        {
            int cur = 0;
            --pass[cur];
            for (auto &p : str)
            {
                int x = get(p);
                if (!--pass[trie[cur][x]])
                {
                    trie[cur][x] = 0;
                    return;
                }
                cur = trie[cur][x];
            }
            --end[cur];
        }
    }

    void clear()
    {
        for (int i = 0; i <= tot; ++i)
        {
            pass[i] = end[i] = 0;
            fill(trie[i].begin(), trie[i].end(), 0);
        }
        tot = 0;
    }
};
