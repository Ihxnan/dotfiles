template <class T> struct MinCostFlow
{
    struct _Edge
    {
        int to;
        T cap;
        T cost;

        _Edge(int _to, T _cap, T _cost) : to(_to), cap(_cap), cost(_cost)
        {
        }
    };

    struct Edge
    {
        int from;
        int to;
        T cap;
        T cost;
        T flow;
    };

    int n;
    vector<_Edge> e;
    vector<vector<int>> g;
    vector<T> dis;
    vector<int> pre;

    MinCostFlow()
    {
    }

    MinCostFlow(int n_) : n(n_), g(n_)
    {
    }

    void init(int n_)
    {
        n = n_;
        e.clear();
        g.assign(n, {});
    }

    void add(int u, int v, T cap, T cost)
    {
        g[u].push_back(e.size());
        e.emplace_back(v, cap, cost);
        g[v].push_back(e.size());
        e.emplace_back(u, 0, -cost);
    }

    bool spfa(int s, int t)
    {
        dis.assign(n, numeric_limits<T>::max());
        pre.assign(n, -1);
        vector<bool> inq(n, false);
        queue<int> que;
        dis[s] = 0;
        que.push(s);
        inq[s] = true;
        while (!que.empty())
        {
            int u = que.front();
            que.pop();
            inq[u] = false;
            for (int i : g[u])
            {
                int v = e[i].to;
                T cap = e[i].cap;
                T cost = e[i].cost;
                if (cap > 0 && dis[v] > dis[u] + cost)
                {
                    dis[v] = dis[u] + cost;
                    pre[v] = i;
                    if (!inq[v])
                    {
                        inq[v] = true;
                        que.push(v);
                    }
                }
            }
        }
        return dis[t] != numeric_limits<T>::max();
    }

    pair<T, T> flow(int s, int t, int k = iINF)
    {
        T flow = 0;
        T cost = 0;
        while (spfa(s, t) && flow < k)
        {
            T aug = numeric_limits<T>::max();
            for (int i = t; i != s; i = e[pre[i] ^ 1].to)
                aug = min(aug, e[pre[i]].cap);
            for (int i = t; i != s; i = e[pre[i] ^ 1].to)
            {
                e[pre[i]].cap -= aug;
                e[pre[i] ^ 1].cap += aug;
            }
            flow += aug;
            cost += aug * dis[t];
        }
        return make_pair(flow, cost);
    }

    vector<Edge> edges()
    {
        vector<Edge> a;
        for (int i = 0; i < e.size(); i += 2)
        {
            Edge x;
            x.from = e[i + 1].to;
            x.to = e[i].to;
            x.cap = e[i].cap + e[i + 1].cap;
            x.cost = e[i].cost;
            x.flow = e[i + 1].cap;
            a.push_back(x);
        }
        return a;
    }
};
