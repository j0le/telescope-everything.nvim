#!/bin/sh

set -e

gcc -o main.so main.c -shared -fPIC
