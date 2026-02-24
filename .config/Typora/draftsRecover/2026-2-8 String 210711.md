# string(字符串)

### 定义

```cpp
template <
	class CharT,
	class Traits = std::char_traits<CharT>,
	class Allocator = std::allocator<CharT>
> class string;
```

## 构造函数

```cpp
// 构造一个空字符串，使用默认构造的分配器
string() : string(Allocator());

// 构造一个包含 count 个字符 ch 副本的字符串
string(size_t count, CharT ch);

// 构造一个包含范围 [first, last) 内容的字符串
string(Iter first, Iter last);

// 构造一个包含范围 [s, s + count) 内容的字符串
// count 默认为 s 的长度
string(const charT *s, size_t count = Traits::length(s));

// 构造一个包含范围 [other.data() + pos, other.data() + pos + count) 内容的字符串。
// count 超出范围会取到末尾
string(const string &other, size_t pos = 0, size_t count = npos);

// 等价于 string(ilist.begin(), ilist.end())
string(std::initializer_list<CharT> ilist);
```

## 元素访问

```cpp
// 执行边界检查
reference at(size_t pos);

// 不执行边界检查
reference operator[](size_t pos);

// 返回第一个元素的引用
reference front();

// 返回最后一个元素的引用
reference back();
```

## 迭代器

```cpp
// 返回指向起始的迭代器
iterator begin();

// 返回指向末尾的迭代器
iterator end();

// 返回指向起始的逆向迭代器
reverse_iterator rbegin();

// 返回指向末尾的逆向迭代器
reverse_iterator rend();
```

## 容量

```cpp
// 检查是否为空
bool empty() const;

// 返回元素数量
size_t size() const;
size_t lenght() const;
```

## 修改器

```cpp
// 清除内容
void clear();

// ==== 插入元素 ====
//
// 在位置 index 插入
// count 个字符 ch 的副本
string& insert(size_t index, size_t count, CharT ch);
// 范围 [s, s + count) 中的字符
// count 默认为s的长度
string& insert(size_t index, const CharT *s, size_t count = Traits::length(s));
// 字符串 str
string& insert(size_t index, const string &str);
// 通过 str.substr(s_index, count) 获得的字符串
string& insert(size_t index, const string &str, size_t s_index, size_t count = npos);
//
// 返回指向插入操作中第一个插入的元素的迭代器
// 在 pos 指向的字符之前插入
// 字符 ch
iterator insert(const_iterator pos, CharT ch);
// count 个 ch 的副本
iterator insert(const_iterator pos, size_t count, CharT ch);
// 来自初始化列表 ilist 的元素
iterator insert(const_iterator pos, std::initializer_list<CharT> ilist);
// 来自范围[first, last)的元素
void insert(const_iterator pos, Iter first, Iter last);

// 擦出元素
// 移除从 index 开始的 count 个字符
// 超出范围删除到结尾
// 默认删除到结尾
string& erase(size_t index = 0, size_t count = npos);
// 返回指向删除元素的下一个有效元素的迭代器
// 移除 pos 处的字符
iterator erase(iterator pos);
// 移除范围 [first, last) 中的字符
iterator erase(iterator first, iterator last);

// 添加元素到结尾
void push_back(CharT ch);
string& operator+=(CharT ch);

// 移除末元素
void pop_back();

// 将字符追加到末尾
// 追加 count 个字符 ch 的副本
string& append(size_t count, CharT ch);
// 追加范围 [s, s + count) 中的字符
string& append(const CharT *s, size_t count = Traits::length(s));
string& operator+=(const CharT *s)
// 追加另一个字符串 str 中的字符
string& append(const string &str);
string& operator+=(const string &str);
// 通过 str.substr(s_index, count) 获得的字符串
string& append(const string &str, size_t index, size_t count = npos);
// 等价于 return append(basic_string(first, last)
string& append(Iter first, Iter last);
// 等价于 return append(ilist.begin(), ilist.size())
string& append(std::initializer_list<CharT> ilist);
string& operator+=(std::initializer_list<CharT> ilist);

// 替代字符串的指定部分
// 范围字符被 str 替换
string& replace(size_t index, size_t count, const string &str);
string& replace(iterator first, iterator last, const string &str);

// 范围字符被 str.substr(s_index, s_count) 替换
string& replace(size_t index, size_t count, const string &str， size_t s_index, s_count = npos);

// 范围字符被范围 [cstr, cstr + count2) 中的字符替换
string& replace(size_t index, size_t count, const CharT *cstr, size_t cs_count = Traits::length(cstr))
string& replace(iterator first, iterator last, const CharT *cstr, size_t cs_count = Traits::length(cstr));

// 范围字符被字符 ch 替换
string& replace(size_t index, size_t count, size_t count2, CharT ch)
string& replace(iterator first, iterator last, size_t count2, CharT ch);

// 范围字符被范围 [first, last) 的字符替换
string& replace(iterator first, iterator last, Iter first2, Iter last2);

// 范围字符被 ilist 中的字符替换
string& replace(size_t index, size_t count, std::initializer_list<CharT> ilist);
string& replace(iterator first, iterator last, std::initializer_list<CharT> ilist);

// 更改存储的元素数量
void resize(size_t count, CharT ch = CharT());

// 将值赋给容器
string& operator=(const string &str);
string& operator=(const CharT *s);
string& operator=(std::initializer_list<CharT> ilist);

void assign(const string &str);
void assign(size_t count, CharT ch);
void assign(const CharT* s, size_t count = Traits::length(s));
void assign(const string& str, size_t index, size_t count = npos);
void assign(Iter first, Iter last);
void assign(std::initializer_list<CharT> ilist);
```



## 非成员函数

```cpp
// 字典序比较两个 vector 的值

template <class T, class Alloc>
bool operator==(const std::vector<T, Alloc>& lhs,
                const std::vector<T, Alloc>& rhs);

template <class T, class Alloc>
bool operator!=(const std::vector<T, Alloc>& lhs,
                const std::vector<T, Alloc>& rhs);

template <class T, class Alloc>
bool operator<(const std::vector<T, Alloc>& lhs,
               const std::vector<T, Alloc>& rhs);

template <class T, class Alloc>
bool operator<=(const std::vector<T, Alloc>& lhs,
                const std::vector<T, Alloc>& rhs);

template <class T, class Alloc>
bool operator>(const std::vector<T, Alloc>& lhs,
               const std::vector<T, Alloc>& rhs);

template <class T, class Alloc>
bool operator>=(const std::vector<T, Alloc>& lhs,
                const std::vector<T, Alloc>& rhs);

template <class T, class Alloc>
constexpr synth-three-way-result<T>
    operator<=>(const std::vector<T, Alloc>& lhs,
                const std::vector<T, Alloc>& rhs);
```
