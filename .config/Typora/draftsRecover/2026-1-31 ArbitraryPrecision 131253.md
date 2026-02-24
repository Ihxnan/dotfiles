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
    
    
}
```

