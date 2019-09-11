#!/bin/sh
mkdir build 2>/dev/null || true
elm make --output build/main.js  src/Main.elm
