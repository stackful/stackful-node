#!/bin/sh

STACK_DIR=$(dirname $(readlink -f "$0"))
chef-solo -c "$STACK_DIR/stack.rb" -j "$STACK_DIR/stack.json"
