#!/bin/sh
sed -i \
         -e 's/rgb(0%,0%,0%)/#4d4d4d/g' \
         -e 's/rgb(100%,100%,100%)/#bfbfbf/g' \
    -e 's/rgb(50%,0%,0%)/#565656/g' \
     -e 's/rgb(0%,50%,0%)/#40bfff/g' \
 -e 's/rgb(0%,50.196078%,0%)/#40bfff/g' \
     -e 's/rgb(50%,0%,50%)/#bfbfbf/g' \
 -e 's/rgb(50.196078%,0%,50.196078%)/#bfbfbf/g' \
     -e 's/rgb(0%,0%,50%)/#2d303d/g' \
	"$@"
