#!/bin/bash

show_help() {
    echo "Usage: $0 [-h|--help] <n> <c|cpp|p|py>"
    echo "  n           Number of files to create (A, B, C, ...)"
    echo "  c|cpp|p|py  File extension (cpp or py)"
    echo "  -h, --help  Show this help message"
    exit 0
}

# Parse first argument
case "${1:-}" in
    -h|--help)
        show_help
        ;;
    "")
        echo "Error: Missing arguments. Use -h or --help for usage." >&2
        exit 1
        ;;
    *)
        n="$1"
        if ! [[ "$n" =~ ^[0-9]+$ ]] || [ "$n" -lt 1 ]; then
            echo "Error: First argument must be a positive integer." >&2
            exit 1
        fi
        ;;
esac

# Parse second argument
case "${2:-}" in
    c|cpp)
        ext="cpp"
        ;;
    p|py)
        ext="py"
        ;;
    "")
        echo "Error: Missing extension. Use -h or --help for usage." >&2
        exit 1
        ;;
    *)
        echo "Error: Unknown extension \"$2\". Use c, cpp, p, or py." >&2
        exit 1
        ;;
esac

for ((i=0; i<n; i++)); do
    letter=$(printf \\$(printf '%03o' $((65 + i))))
    > "${letter}.${ext}"
done
