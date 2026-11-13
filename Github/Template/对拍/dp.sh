g++ -O2 data.cpp -o data.out
g++ -O2 ans.cpp -o ans.out
g++ -O2 test.cpp -o test.out

N=100

if [ "${1}" != "" ]; then
    N=${1}
fi

cnt=0
while [ ${cnt} -lt ${N} ]; do
    cnt=$((cnt + 1))
    echo 第 ${cnt} 组

    ./data.out >data.txt
    ./ans.out <data.txt >ans.txt
    ./test.out <data.txt >test.txt

    if ! diff ans.txt test.txt; then
        echo "Wrong"
        exit 0
    fi
done
