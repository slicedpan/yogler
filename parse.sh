readelf -Ws $1 | grep 'gl' | awk -e '{ print $1 }'
