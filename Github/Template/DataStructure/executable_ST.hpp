struct ST
{
    const int n, len;
    vector<int> in;
    vector<vector<int>> st;
    function<int(int, int)> Max;

    ST(
        int n, function<int(int, int)> Max = [](int a, int b) { return max(a, b); })
        : n(n), len(__lg(n) + 1), in(n + 1), Max(Max)
    {
        st.resize(len, vector<int>(n + 1));
    }

    ST(
        vector<int> &arr, function<int(int, int)> Max = [](int a, int b) { return max(a, b); })
        : n(arr.size() - 1), len(__lg(n) + 1), in(arr), Max(Max)
    {
        st.resize(len, vector<int>(n + 1));
    }

    void init()
    {
        for (int i = 1; i <= n; ++i)
            st[0][i] = in[i];
        for (int i = 1; i < len; ++i)
            for (int j = 1; j + (1 << i) - 1 <= n; ++j)
                st[i][j] = Max(st[i - 1][j], st[i - 1][j + (1 << i - 1)]);
    }

    int query(int l, int r)
    {
        int k = __lg(r - l + 1);
        return Max(st[k][l], st[k][r - (1 << k) + 1]);
    }
};
