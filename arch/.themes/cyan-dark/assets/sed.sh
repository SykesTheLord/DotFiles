#!/bin/sh
sed -i \
         -e 's/#4d4d4d/rgb(0%,0%,0%)/g' \
         -e 's/#bfbfbf/rgb(100%,100%,100%)/g' \
    -e 's/#565656/rgb(50%,0%,0%)/g' \
     -e 's/#40bfff/rgb(0%,50%,0%)/g' \
     -e 's/#bfbfbf/rgb(50%,0%,50%)/g' \
     -e 's/#2d303d/rgb(0%,0%,50%)/g' \
	"$@"
