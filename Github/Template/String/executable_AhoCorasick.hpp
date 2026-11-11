struct AhoCorasick
{
    static constexpr int ALPHABET = 26;
    struct Node
    {
        int len;
        int link;
        array<int, ALPHABET> next;
        Node() : len{0}, link{0}, next{}
        {
        }
    };

    vector<Node> tree;

    AhoCorasick()
    {
        init();
    }

    void init()
    {
        tree.assign(2, Node());
        tree[0].next.fill(1);
        tree[0].len = -1;
    }

    int newNode()
    {
        tree.emplace_back();
        return tree.size() - 1;
    }

    int add(const string &str)
    {
        int p = 1;
        for (auto c : str)
        {
            int x = c - 'a';
            if (tree[p].next[x] == 0)
            {
                tree[p].next[x] = newNode();
                tree[tree[p].next[x]].len = tree[p].len + 1;
            }
            p = tree[p].next[x];
        }
        return p;
    }

    void work()
    {
        queue<int> que;
        que.push(1);

        while (!que.empty())
        {
            int x = que.front();
            que.pop();

            for (int i = 0; i < ALPHABET; i++)
            {
                if (tree[x].next[i] == 0)
                {
                    tree[x].next[i] = tree[tree[x].link].next[i];
                }
                else
                {
                    tree[tree[x].next[i]].link = tree[tree[x].link].next[i];
                    que.push(tree[x].next[i]);
                }
            }
        }
    }

    int next(int p, int x)
    {
        return tree[p].next[x];
    }

    int link(int p)
    {
        return tree[p].link;
    }

    int len(int p)
    {
        return tree[p].len;
    }

    int size()
    {
        return tree.size();
    }
};
