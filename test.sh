#!/bin/sh

docker_ip="$(ip -4 -j a show dev docker0 | jq -r ".[] | .addr_info[] | .local")"
printf "%s" "{\"release\":{\"upload_url\":\"http://$docker_ip:8000/\",\"tag_name\":\"test\"}}" > event/event.json
cargo build --release --manifest-path ./http-post-capture/Cargo.toml
./http-post-capture/target/release/http-post-capture -l "$docker_ip:8000" -o "output" &
listener_pid="$!"

TARGETS="$(cat targets)"

REPO="$1"
if [ -z "$REPO" ]; then
  REPO="rust-build/rust-build.test"
fi
REMOTE="https://github.com/$REPO.git"

EXTRA_FILES="$3"
if [ -z "$EXTRA_FILES" ]; then
  EXTRA_FILES=""
fi

if [ -d "test" ]; then
  cd "test"
  REPO_REMOTE=$(git remote get-url origin)
  if [ "$REPO_REMOTE" != "$REMOTE" ]; then
    REMOTE="$REPO_REMOTE"
  fi
else
  git clone "$REMOTE" "test"
  cd "test"
fi

for target in $TARGETS; do
  printf "\033[31m\033[1mTesting %s\033[0m\n" "$target"
  sudo docker run \
    --mount "type=bind,source=$PWD,destination=/github/$REPO" \
    --mount "type=bind,source=$(readlink -f "$PWD/../event"),destination=/event,ro=true" \
    -e GITHUB_EVENT_PATH="/event/event.json" \
    -e GITHUB_EVENT_DATA="{\"release\":{\"upload_url\":\"http://$docker_ip:8000/\",\"tag_name\":\"test\"}}" \
    -e GITHUB_REPOSITORY="$REPO" \
    -e GITHUB_WORKSPACE="/github/$REPO" \
    -e EXTRA_FILES="$EXTRA_FILES" \
    -e RUSTTARGET="$target" \
    -e SRC_DIR="$2" \
    -e GITHUB_TOKEN="" \
    -e MINIFY="true" \
    --rm -it rust-build
done

kill "$listener_pid"
