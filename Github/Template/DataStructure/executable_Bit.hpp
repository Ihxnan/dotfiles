template <class T> struct bit
{
    T value;
    bit(T x = 0) : value(x) {}
    bool operator[](int x) const { return value >> x & 1; }
    void set(int x) { value |= T(1) << x; }
    void reset(int x) { value &= ~(T(1) << x); }
    void flip(int x) { value ^= T(1) << x; }
    bit operator<<(int x) const { return bit(value << x); }
    bit operator>>(int x) const { return bit(value >> x); }
    bit &operator<<=(int x) { value <<= x; return *this; }
    bit &operator>>=(int x) { value >>= x; return *this; }
    bit operator&(const bit &o) const { return bit(value & o.value); }
    bit operator|(const bit &o) const { return bit(value | o.value); }
    bit operator^(const bit &o) const { return bit(value ^ o.value); }
    bit &operator&=(const bit &o) { value &= o.value; return *this; }
    bit &operator|=(const bit &o) { value |= o.value; return *this; }
    bit &operator^=(const bit &o) { value ^= o.value; return *this; }
    bit operator~() const { return bit(~value); }
    bool operator==(const bit &o) const { return value == o.value; }
    bool operator!=(const bit &o) const { return value != o.value; }
    bool operator<(const bit &o) const { return value < o.value; }
    bool operator>(const bit &o) const { return value > o.value; }
    bool operator<=(const bit &o) const { return value <= o.value; }
    bool operator>=(const bit &o) const { return value >= o.value; }
};
