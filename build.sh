#!/bin/sh

if [ -d action ]; then
  cd action
  git pull
else
  git clone https://github.com/rust-build/rust-build.action.git action
  cd action
fi

sudo docker build -t rust-build .
