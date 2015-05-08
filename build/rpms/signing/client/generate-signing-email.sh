#!/bin/sh
echo $1 > build.txt
gpg --clearsign build.txt
cat build.txt.asc
rm -f build.txt build.txt.asc
