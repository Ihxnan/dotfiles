struct HLD {
    int n, cur;
    vector<int> sz, top, dep, fa, in, out, seq;
    vector<vector<int>> adj;
    
    HLD(int n) : n(n), cur(1), sz(n + 1), top(n + 1), dep(n + 1), fa(n + 1), in(n + 1), out(n + 1), seq(n + 1), adj(n + 1) {}

    void add(int u, int v) {
        adj[u].push_back(v);
        adj[v].push_back(u);
    }
    void work(int root = 1) {
        top[root] = root;
        dep[root] = 0;
        fa[root] = 0;
        dfs1(root);
        dfs2(root);
    }
    void dfs1(int u) {
        if (fa[u] != 0) {
            adj[u].erase(find(adj[u].begin(), adj[u].end(), fa[u]));
        }
        sz[u] = 1;
        for (auto &v : adj[u]) {
            fa[v] = u;
            dep[v] = dep[u] + 1;
            dfs1(v);
            sz[u] += sz[v];
            if (sz[v] > sz[adj[u][0]]) {
                swap(v, adj[u][0]);
            }
        }
    }
    void dfs2(int u) {
        in[u] = cur++;
        seq[in[u]] = u;
        for (auto v : adj[u]) {
            top[v] = v == adj[u][0] ? top[u] : v;
            dfs2(v);
        }
        out[u] = cur;
    }
    int lca(int u, int v) {
        while (top[u] != top[v]) {
            if (dep[top[u]] < dep[top[v]])
                swap(u, v);
            u = fa[top[u]];
        }
        if (dep[u] > dep[v])
            swap(u, v);
        return u;
    }
    
    int dist(int u, int v) {
        return dep[u] + dep[v] - 2 * dep[lca(u, v)];
    }
    
    int jump(int u, int k) {
        if (dep[u] < k) {
            return 0;
        }
        
        int d = dep[u] - k;
        
        while (dep[top[u]] > d) {
            u = fa[top[u]];
        }
        
        return seq[in[u] - dep[u] + d];
    }
    
    bool isAncester(int u, int v) {
        return in[u] <= in[v] && in[v] < out[u];
    }
    
    int rootedParent(int u, int v) {
        swap(u, v);
        if (u == v) {
            return u;
        }
        if (!isAncester(u, v)) {
            return fa[u];
        }
        auto it = upper_bound(adj[u].begin(), adj[u].end(), v, [&](int x, int y) {
            return in[x] < in[y];
        }) - 1;
        return *it;
    }
    
    int rootedSize(int u, int v) {
        if (u == v) {
            return n;
        }
        if (!isAncester(v, u)) {
            return sz[v];
        }
        return n - sz[rootedParent(u, v)];
    }
    
    int rootedLca(int a, int b, int c) {
        return lca(a, b) ^ lca(b, c) ^ lca(c, a);
    }
};
