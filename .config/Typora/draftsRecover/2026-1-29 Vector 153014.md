# vector(向量) 常用

### 定义

```cpp
template <
	class T,
	class Allocator = std::allocator<T>
> class vector;
```

## 构造函数

```cpp
// 构造一个空的 vector，带有一个默认构造的分配器。
vector() : vector(Allocator());

// 构造一个包含 count 个值为 value 的元素的副本的 vector
// value 默认值：
// 		数值型：0
// 		字符串：“”
vector(size_t count, const T& value = T());

// 构造一个包含范围 [first, last) 内容的 vector。
// Iter 可以是任意容器的迭代器或C语言数组指针
vector(Iter first, Iter last);
```

## 元素访问

```cpp
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
```

## 修改器

```cpp
// 清除内容
void clear();

// ==== 插入元素 ====
// 在 pos 前插入
// value 的副本
// 返回指向插入操作中第一个插入的元素的迭代器
iterator insert(const_iterator pos, const T& value);
// count 个 value 的副本
iterator insert(const_iterator pos, size_t count, const T& value);
// 来自范围[first, last)的元素
// Iter 可以是任意容器的迭代器或C语言数组指针
iterator insert(const_iterator pos, Iter first, Iter last);
// 来自初始化列表 ilist 的元素
iterator insert(const_iterator pos, std::initializer_list<T> ilist);

// 就地构造元素
// 相当于 iterator insert(const_iterator pos, const T& value);
// args 为 value 的构造函数的参数
// 返回指向插入元素的迭代器
template <class... Args>
iterator emplace(const_iterator pos, Args&&... args);

// 擦出元素
// 返回指向删除元素的下一个有效元素的迭代器
// 移除 pos 处的元素
iterator erase(iterator pos);
// 移除范围 [first, last) 中的元素
iterator erase(iterator first, iterator last);

// 添加元素到结尾
void push_back(const T& value);

// 就地构造元素于结尾
// 返回插入元素的引用
template <class... Args>
reference emplace(Args&&... args);

// 移除末元素
void pop_back();

// 更改存储的元素数量
void resize(size_t count, const T& value = T());

// 将值赋给容器
vector& operator=(const vector& other);
vector& operator=(std::initializer_list<T> ilist);

void assign(size_t count, count T& value);
void assign(Iter first, Iter last);
void assign(std::initializer_list<T> ilist);
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
