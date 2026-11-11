struct SqAM
{
    int n;
    vector<vector<int>> next;
    SqAM() = default;
    SqAM(const string &str)
    {
        init(str);
    }
    void clear()
    {
        n = 0, next.clear();
    }
    void init(const string &str)
    {
        n = str.size();
        next.resize(n + 1, vector<int>(26, -1));
        for (int i = n - 1; i >= 0; --i)
        {
            for (int j = 0; j < 26; ++j)
                next[i][j] = next[i + 1][j];
            next[i][str[i] - 'a'] = i;
        }
    }
    bool find(const string &str)
    {
        int idx = 0;
        for (auto p : str)
        {
            idx = next[idx][p - 'a'] + 1;
            if (idx <= 0)
                return false;
        }
        return true;
    }
};
