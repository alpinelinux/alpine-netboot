#!/bin/sh -e

REPO="http://dl-cdn.alpinelinux.org/alpine"
BRANCHES="edge latest-stable"
ARCHS="x86 x86_64 aarch64"
IMGDIR="/var/www/localhost/htdocs/images"

# CA Settings
CA_CRT="/etc/ssl/alpine-netboot-ca/ca.crt"
SIGN_CRT="/etc/ssl/alpine-netboot-ca/codesign.crt"
SIGN_KEY="/etc/ssl/alpine-netboot-ca/codesign.key"
PASS_FILE="/etc/ssl/alpine-netboot-ca/passwd"

if [ -f "/lib/libalpine.sh" ]; then
	. /lib/libalpine.sh
else
	echo "Error: cannot find libalpine.sh" >&2
	exit 1
fi

CACHE_DIR="/var/cache/alpine-netboot"
APK="apk --no-cache --repositories-file /dev/null"

compare_files() {
	[ -f "$1" ] || return 1
	[ -f "$2" ] || return 1
	diff -q "$1" "$2" > /dev/null 2>&1
}

# list all runtime depencencies for alpine-base
resolve_base() {
	local branch="$1"
	local arch="$2"
	ALPINE_BASE=$($APK --arch $arch -X $REPO/$branch/main fetch -R --simulate alpine-base 2> /dev/null)
	[ "$?" = "0" ] || die "Failed to get base dependency tree"
	echo "$ALPINE_BASE" | grep -v '^fetch' | cut -d' ' -f2
}

# find the latest kernel and firmware.
# kernel/firmware deps are not interesting so we do not resolve the tree.
get_latest_kernel() {
	local branch="$1"
	local arch="$2"
	KERNEL=$($APK --arch $arch -X $REPO/$branch/main search -x linux-vanilla linux-firmware)
	[ "$?" = "0" ] || die "Failed to get kernel version"
	echo "$KERNEL" | grep -v '^fetch'
}

sign_images() {
	local imgdir="$1"
	local img
	for img in vmlinuz initramfs; do
		local file=$(realpath $imgdir/*${img}*)
		echo "Signing image: $file"
		openssl cms -sign -binary -noattr -in "$file" \
			-signer "$SIGN_CRT" -inkey "$SIGN_KEY" \
			-certfile "$CA_CRT" \
			-outform DER -out "$file".sig \
			-passin file:"$PASS_FILE"
	done
}


#############
#  M a i n  #
#############

mkdir -p "$CACHE_DIR"
tmpfile=$(mktemp)
tmpdir=$(mktemp -d)

for branch in $BRANCHES; do
	mkdir -p "$IMGDIR"/$branch
	for arch in $ARCHS; do
		echo "Checking: $branch/$arch"
		for i in $(resolve_base $branch $arch && get_latest_kernel $branch $arch); do
			echo "$i" >> $tmpfile
		done
		sort $tmpfile -o $tmpfile
		if ! compare_files $tmpfile "$CACHE_DIR"/$branch-$arch.lst; then
			echo "Dependencies updated for: $branch/$arch"
			./mknetboot.sh --release "$branch" --arch "$arch" --outdir "$tmpdir"
			(cd "$tmpdir" && sha512sum * > alpine-netboot-$branch-$arch.sha512 || true)
			sign_images "$tmpdir"
			rm -rf "$IMGDIR"/$branch/$arch
			mv "$tmpdir" "$IMGDIR"/$branch/$arch
			mv "$tmpfile" "$CACHE_DIR"/$branch-$arch.lst
		else
			printf "No update found\n"
			rm -f $tmpfile
		fi
	done
done
