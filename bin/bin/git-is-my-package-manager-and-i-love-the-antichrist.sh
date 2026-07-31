#!/bin/bash

git fetch --all
git submodule update --init --recursive
git lfs fetch --all
git lfs checkout
git submodule foreach 'git lfs fetch --all; git lfs checkout'
