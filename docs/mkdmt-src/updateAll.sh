#!/bin/bash

cp -vax ../../README.md src/index.md
#cp -vax ../../inst/docs/*md src/vignettes/
~/git/mkdocsmaterial-with-r/mkManPages.r ../../
~/git/mkdocsmaterial-with-r/mkChangelog.r ../../
~/git/mkdocsmaterial-with-r/mkNews.r ../../

~/git/mkdocsmaterial-with-r/runMe.sh build

~/git/mkdocsmaterial-with-r/runMe.sh

./deploy.sh
