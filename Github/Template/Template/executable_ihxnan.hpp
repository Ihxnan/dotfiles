#include <bits/stdc++.h>
#define endl '\n'                               // 输出换行, 配合下方 IO 结构体使用 (末尾无多余空白)
#define ls(x) ((x) << 1)                        // 线段树/树状结构: 节点 x 的左儿子下标 (x*2)
#define rs(x) ((x) << 1 | 1)                    // 线段树/树状结构: 节点 x 的右儿子下标 (x*2+1)
#define bl(x) ((x) * blen + 1)                  // 分块: 块 x 的左边界下标 (1 起始, 含)
#define bi(x) (((x) - 1) / blen)                // 分块: 下标 x 所属的块编号 (0 起始, blen 为块长)
#define br(x) (min(((x) + 1) * blen, n))        // 分块: 块 x 的右边界下标 (受全局 n 限制, 含)
#define fid(x,y) ((m)*(x-1)+(y))                // 二维坐标 (x,y) -> 一维编号 (1-indexed, m 为列数)
#define gx(id) (((id) - 1) / m + 1)             // fid 逆变换: 编号 id -> 行号 x (1-indexed)
#define gy(id) (((id) - 1) % m + 1)             // fid 逆变换: 编号 id -> 列号 y (1-indexed)
#define rd0(x) for(auto &p : x) cin >> p       // 容器整体读入: 对 x 中每个元素执行 cin >> p (vector/array/deque 等, 不含 map 嵌套)
#define rd1(x) for(int i = 1; i < x.size(); ++i) cin >> x[i]
int t=1;void solve();int main(){while(t--)solve();return 0;}
using namespace std;using ll=long long;using ul=unsigned long long;using lll=__int128;using ld=long double;using vb=vector<bool>;using vi=vector<int>;using vvi=vector<vi>;using vl=vector<ll>;using vvl=vector<vl>;using pii=pair<int, int>;using pll=pair<ll,ll>;using ti=tuple<int,int,int>;using tl=tuple<ll,ll,ll>;
const ll iINF=0x3f3f3f3f,mod=998244353,lINF=0x3f3f3f3f3f3f3f3f,MOD=1000000007;
#ifdef IHXNAN
    #include <dbg>
#else
    #define cin fin
    #define cout fout
    #define gdb(...)              ((void)0)
    #define TIME(name)            ((void)0)
    struct IO{
        static const int S=1<<21;uint8_t buf[S],*p1,*p2;int st[105],Top;bool ok;
        IO():p1(nullptr),p2(nullptr),Top(0),ok(true){st[0]=0;}~IO(){clear();}inline void clear(){fwrite(buf,1,Top,stdout);Top=0;}
        inline int inc(){if(p1==p2){p2=(p1=buf)+fread(buf,1,S,stdin);if(p1==p2)return EOF;}return*p1++;}inline void outc(int c){if(Top==S)clear();buf[Top++]=(uint8_t)c;}inline explicit operator bool()const{return ok;}
        template<typename T>inline IO&operator<<(T x){int f=0;if constexpr(std::is_signed_v<T>){if(x<0)outc('-'),f=1;}do{st[++st[0]]=f?-(x%10):x%10,x/=10;}while(x);while(st[0])outc(48^st[st[0]--]);return*this;}
        inline IO&operator<<(char c){outc(c);return*this;}inline IO&operator<<(const char*x){while(*x)outc(*x++);return*this;}inline IO&operator<<(char*x){while(*x)outc(*x++);return*this;}inline IO&operator<<(const string&x){for(auto c:x)outc(c);return*this;}
        template<typename T>inline IO&operator>>(T&x){x=0;int f=0,ch=inc();while(ch!=EOF&&!isdigit(ch)){if(ch=='-')f^=1;ch=inc();}if(ch==EOF){ok=false;return*this;}while(ch!=EOF&&isdigit(ch))x=(x<<3)+(x<<1)+(ch^48),ch=inc();f?x=-x:0;return*this;}
        inline IO&operator>>(char&x){int c=inc();while(c!=EOF&&isspace(c))c=inc();if(c==EOF){ok=false;return*this;}x=(char)c;return*this;}inline IO&operator>>(string&x){x.clear();int c=inc();while(c!=EOF&&isspace(c))c=inc();if(c==EOF){ok=false;return*this;}while(c!=EOF&&!isspace(c))x+=char(c),c=inc();return*this;}
    }fin,fout;
#endif
