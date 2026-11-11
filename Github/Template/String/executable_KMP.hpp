vector<int> get_fail(const string &str)
{
    int n = str.size() - 1;
    vector<int> fail(n + 1);
    for (int i = 2, j = 0; i <= n; ++i)
    {
        while (j && str[i] != str[j + 1])
            j = fail[j];
        if (str[i] == str[j + 1])
            ++j;
        fail[i] = j;
    }
    return fail;
}

vector<vector<int>> get_tr(const string &str, const vector<int> &fail)
{
    int n = fail.size() - 1;
    vector<vector<int>> tr(fail.size(), vector<int>(26));
    for (int i = 0; i < n; ++i)
    {
        for (int j = 0; j < 26; ++j)
            tr[i][j] = tr[fail[i]][j];
        tr[i][str[i + 1] - 'a'] = i;
    }
    return tr;
}

vector<int> get_z(const string &str)
{
    int n = str.size() - 1;
    vector<int> z(n + 1);
    if (n == 0)
        return z;
    z[1] = n;
    for (int i = 2, l = 0, r = 0; i <= n; i++)
    {
        if (i <= r)
            z[i] = min(r - i + 1, z[i - l + 1]);
        while (i + z[i] <= n && str[1 + z[i]] == str[i + z[i]])
            z[i]++;
        if (i + z[i] - 1 > r)
            l = i, r = i + z[i] - 1;
    }
    return z;
}
