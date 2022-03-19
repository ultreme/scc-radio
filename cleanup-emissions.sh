#!/bin/bash

for year in {2015..2025}; do
    for month in 0{1..9} {10..12}; do
	mkdir -p  playlists/emissions/guest/$year/$month
	chmod 777 playlists/emissions/guest/$year/$month
    done
done

rmdir playlists/emissions/guest/{2015..2021}/*/

#FIXME: remove file less than 1ko
