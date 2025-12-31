#!/bin/sh

PAK_DIR="$(dirname "$0")"
PAK_NAME="$(basename "$PAK_DIR")"
PAK_NAME="${PAK_NAME%.*}"
[ -f "$USERDATA_PATH/$PAK_NAME/debug" ] && set -x

rm -f "$LOGS_PATH/$PAK_NAME.txt"
exec >>"$LOGS_PATH/$PAK_NAME.txt"
exec 2>&1

echo "$0" "$@"
cd "$PAK_DIR" || exit 1
mkdir -p "$USERDATA_PATH/$PAK_NAME"

architecture=arm
if uname -m | grep -q '64'; then
    architecture=arm64
fi

export HOME="$USERDATA_PATH/$PAK_NAME"
export LD_LIBRARY_PATH="$PAK_DIR/lib/$PLATFORM:$PAK_DIR/lib:$LD_LIBRARY_PATH"
export PATH="$PAK_DIR/bin/$architecture:$PAK_DIR/bin/$PLATFORM:$PAK_DIR/bin:$PATH"

cleanup() (
    rm -f /tmp/stay_awake
    killall minui-presenter >/dev/null 2>&1 || true
)

show_message() (
    message="$1"
    seconds="$2"
    platform="$PLATFORM"

    if [ -z "$seconds" ]; then
        seconds="forever"
    fi

    killall minui-presenter >/dev/null 2>&1 || true
    echo "$message" 1>&2
    if [ "$platform" = "miyoomini" ]; then
        return 0
    fi
    if [ "$seconds" = "forever" ]; then
        minui-presenter --message "$message" --timeout -1 &
    else
        minui-presenter --message "$message" --timeout "$seconds"
    fi
)

main() {
    echo "1" >/tmp/stay_awake
    trap "cleanup" EXIT INT TERM HUP QUIT

    if [ "$PLATFORM" = "tg3040" ] && [ -z "$DEVICE" ]; then
        export DEVICE="brick"
        export PLATFORM="tg5040"
    fi

    if ! command -v minui-presenter >/dev/null 2>&1; then
        show_message "Minui-presenter not found." 2
        return 1
    fi

    if ! command -v bash >/dev/null 2>&1; then
        show_message "bash not found." 2
        return 1
    fi

    allowed_platforms="tg5040"
    if ! echo "$allowed_platforms" | grep -q "$PLATFORM"; then
        show_message "$PLATFORM is not a supported platform." 2
    fi

    chmod +x "$PAK_DIR/bin/$PLATFORM/minui-presenter"
    chmod +x "$PAK_DIR/bin/$architecture/bash"

    cd "$PAK_DIR/BitPal" && bash "./launch.sh"

}

main "$@"
