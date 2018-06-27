#!/bin/sh

branch=$1
arch=$2
version=$3
mirror=http://dl-cdn.alpinelinux.org/alpine
sigs=/var/www/localhost/htdocs/sigs/$branch/$arch/$version
tarball=alpine-netboot-$version-$arch.tar.gz

# CA Settings
CA_CRT="/etc/ssl/alpine-netboot-ca/ca.crt"
SIGN_CRT="/etc/ssl/alpine-netboot-ca/codesign.crt"
SIGN_KEY="/etc/ssl/alpine-netboot-ca/codesign.key"
PASS_FILE="/etc/ssl/alpine-netboot-ca/passwd"

sign_image() {
	local in=$1 out=$2
	echo "Signing image: $in"
	openssl cms -sign -binary -noattr -in "$in" \
	-signer "$SIGN_CRT" -inkey "$SIGN_KEY" \
	-certfile "$CA_CRT" \
	-outform DER -out "$out" \
	-passin file:"$PASS_FILE"
}

fetch_and_verify() {
	for file in "$tarball" "$tarball".asc; do
		wget -q -P "$tmpdir" "$mirror"/$branch/releases/$arch/$file
	done
	gpg --verify "$tmpdir/$tarball".asc "$tmpdir/$tarball" &> /dev/null
}

tmpdir=$(mktemp -d)
mkdir -p "$sigs" && rm -f "$sigs"/*

if fetch_and_verify; then
	tar -C "$tmpdir" -zxvf "$tmpdir"/"$tarball" | while read file; do
		case $file in
		*modloop*|*vmlinuz*|*initramfs*)
		sign_image "$tmpdir/$file" "$sigs/${file##*/}.sig" ;;
		esac
	done
else
	echo "Failed to verify: $branch/$tarball"
fi

rm -rf "$tmpdir"

