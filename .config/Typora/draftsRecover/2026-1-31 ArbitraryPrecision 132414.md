# Arbitrary-Precision Arithmetic

## 加法



```cpp
// 进位最多为1,可以直接使用字符串存储
// 直接读入两个 bignum
// cin >> a >> b;
string add(string a, string b)
{
    // 反转
    reverse(a.begin(), a.end()), reverse(b.begin(), b.end());
    
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

