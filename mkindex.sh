#!/bin/sh

htmldir="/var/www/localhost/htdocs"

if ! command -v discount-theme >/dev/null 2>&1; then
	echo "Cannot find discount-theme please install discount"
	exit 1
fi

for i in html boot.ipxe; do
	[ -L "$htmldir/$i" ] || ln -s "$(realpath $i)" "$htmldir"
done

discount-theme -t html/page.theme \
	-o "$htmldir"/index.html README.md
