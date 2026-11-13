auto manacher = [](string s) -> vector<int> {
    string str = "^#";
    for (auto &p : s)
        str += p, str += '#';
    vector<int> len(str.size());
    for (int i = 1, r = 1, mid = 0; i < str.size(); ++i)
    {
        if (i < r)
            len[i] = min(len[2 * mid - i], r - i);
        while (str[i + len[i]] == str[i - len[i]])
            ++len[i];
        if (i + len[i] > r)
            r = i + len[i], mid = i;
    }
    return len;
};
