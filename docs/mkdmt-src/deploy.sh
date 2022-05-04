#!/bin/bash

rsync --exclude mkdmt-src/ --delete -ncav docs/ ../
echo ""
echo "** Now run 'rsync --exclude mkdmt-src/ --delete -cav docs/ ../'"
echo ""
