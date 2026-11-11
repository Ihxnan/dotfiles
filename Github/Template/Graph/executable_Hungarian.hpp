vector<bool> visit(n + 1);
vector<int> match(n + 1);
auto dfs = [&](auto &&self, int x) -> bool {
    for (auto &p : adj[x])
        if (!visit[p])
        {
            visit[p] = true;
            if (!match[p] || self(self, match[p]))
            {
                match[p] = x;
                return true;
            }
        }
    return false;
};

// int cnt = 0;
// for (int i = 1; i <= m; ++i)
// {
//     fill(visit.begin(), visit.end(), false);
//     cnt += dfs(dfs, i);
// }
