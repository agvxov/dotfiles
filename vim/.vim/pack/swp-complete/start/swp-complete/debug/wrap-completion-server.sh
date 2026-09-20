#!/bin/sh
#FILE=/home/anon/stow/vim/.vim/plugin/HiTags/vim.tags
FILE=test/test.tags

#bash -c './swp-completion-server.py $$ '$FILE
bash -c 'python -m cProfile -o profile_output.prof ./swp-completion-server.py $$ '$FILE
