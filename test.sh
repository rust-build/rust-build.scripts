#!/bin/sh

TARGETS="$(cat targets)"

REPO="$1"
if [ -z "$REPO" ]; then
  REPO="rust-build/rust-build.test"
fi
REMOTE="https://github.com/$REPO.git"

EXTRA_FILES="$3"
if [ -z "$EXTRA_FILES" ]; then
  EXTRA_FILES="LICENSE README.md"
fi

if [ -d "test" ]; then
  cd "test"
  REPO_REMOTE=$(git remote get-url origin)
  if [ "$REPO_REMOTE" != "$REMOTE" ]; then
    cd ..
    rm -rf "test"
    git clone "$REMOTE" "test"
    cd "test"
  else
    git pull
  fi
else
  git clone "$REMOTE" "test"
  cd "test"
fi

for target in $TARGETS; do
  echo "Testing $target"
  sudo docker run \
    --mount "type=bind,source=$PWD,destination=/github/$REPO" \
    -e GITHUB_EVENT_DATA="{\"release\":{\"upload_url\":\"\",\"tag_name\":\"test\"}}" \
    -e GITHUB_REPOSITORY="$REPO" \
    -e GITHUB_WORKSPACE="/github/$REPO" \
    -e EXTRA_FILES="$EXTRA_FILES" \
    -e RUSTTARGET="$target" \
    -e SRC_DIR="$2" \
    -e GITHUB_TOKEN="" \
    --rm -it rust-build
done
