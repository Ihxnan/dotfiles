# Arbitrary-Precision Arithmetic

## 加法



```cpp
// 进位最多为1,可以直接使用字符串存储
// 直接读入两个 bignum
// cin >> a >> b;
string add(string a, string b)
{
    // 反转
    reverse(a.begin(), a.end());
    reverse(b.begin(), b.end());
    
    // char to int
    for (char &ch : a)
        ch -= '0';
    for (char &ch : b)
        ch -= '0';
    
    // 两数相加，最多进一位，多分配一位空间用来进位
    string ans(max(a.size(), b.size()) + 1, 0);
    
    // 相加
    for (int i = 0; i < max(a.size(), b.size()); ++i)
    {
        // 有 a 加 a
        if (i < a.size())
            ans[i] += a[i];
        // 有 b 加 b
        if (i < b.size())
            ans[i] += b[i];
        // 大于 10 的话进位
        ans[i + 1] = ans[i] / 10;
        ans[i] %= 10;
    }
    
	// 多分配的空间为0,没有进位
    // 删除多余0
    if (!ans.back())
		ans.pop_back();
    
    // int to char
    for (char &ch : ans)
        ch += '0';
    
    // 反转
    reverse(ans.begin(), ans.end());
    
    return ans;
}
```

## 减法

```cpp
string sub(string a, string b)
{
    // 判断是否添加负号
    bool flag = false;
    // 如果 a < b 的话添加负号并且交换 a 和 b
    // 保证 a >= b
    if (a.size() == b.size())
    {
        if (a < b)
            swap(a, b), flag = true;
    }
    else if (a.size() < b.size())
        swap(a, b), flag = true;

    // 反转
    reverse(a.begin(), a.end());
    reverse(b.begin(), b.end());

    // char to int
    for (char &ch : a)
        ch -= '0';
    for (char &ch : b)
        ch -= '0';

    // 相减
    int i = 0;
    for (; i < b.size(); ++i)
    {
        a[i] -= b[i];
        // 不够的话借位
        if (a[i] < 0)
        {
            a[i] += 10;
            --a[i + 1];
        }
    }
    
    // 如果被借位的位不够继续借位
    // 因为 a > b 所以一定成立
    for (; a[i] < 0; ++i)
    {
        a[i] += 10;
        --a[i + 1];
    }

    // 删除多余的 0
    while (a.size() > 1 && !a.back())
        a.pop_back();

    // int to char
    for (char &ch : a)
        ch += '0';

    // 添加负号
    if (flag)
        a += '-';

    // 反转
    reverse(a.begin(), a.end());

    return a;
}
```

高精度 * 单精度

```cpp
void mul(vector<int> &arr, int x)
{
    int cnt = 0;
    for (int &p : arr)
    {
        p = p * x + cnt;
        cnt = p / 10;
        p %= 10;
    }
    while (cnt)
    {
        arr.push_back(cnt % 10);
        cnt /= 10;
    }
}
```

