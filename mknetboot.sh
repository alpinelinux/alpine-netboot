#!/bin/sh -e

ARCH=$(apk --print-arch)
FLAVOR="vanilla"
FEATURE="base squashfs network zfs"
PACKAGE="spl-vanilla zfs-vanilla"
OUTDIR="$PWD/out"
RELEASE="edge"
MIRROR="http://dl-cdn.alpinelinux.org/alpine"

usage() {
	local ws=$(printf %${#0}s)
	cat <<-EOF

	    $0                  [--arch ARCH] [--flavor FLAVOR] [--feature FEATURE]
	    $ws                  [--outdir OUTDIR] [--release RELEASE] [--repository REPO]
	    $0                  --help

	    options:
	    --arch              Specify which architecture images to build
	    --flavor            Specify which kernel flavor images to build
	    --feature           Specify which initramfs features to include
	    --package           Additional module or firmware package
	    --outdir            Specify directory for the created images
	    --release           Build images for specified release from main repository
	    --repository        Package repository to use (overides --release)
	    --extra-repository  Add repository to search packages from (overides --release)

	EOF
}

# parse parameters
while [ $# -gt 0 ]; do
	opt="$1"
	shift
	case "$opt" in
		--arch) ARCH="$1"; shift ;;
		--flavor) FLAVOR="$1"; shift ;;
		--feature) FEATURE="$1"; shift ;;
		--outdir) OUTDIR="$1"; shift ;;
		--release) RELEASE="$1"; shift ;;
		--repository) REPO="$1"; shift ;;
		--extra-repository) EXTRAREPO="$EXTRAREPO $1"; shift ;;
		--) break ;;
		-*) usage; exit 1;;
	esac
done

rm -rf "$OUTDIR"
mkdir -p "$OUTDIR"

REPOFILE=$(mktemp)
DEFAULT_REPO="$MIRROR/$RELEASE/main"
echo "${REPO:-$DEFAULT_REPO}" >> "$REPOFILE"
for repo in $EXTRAREPO; do
	echo "$repo" >> "$REPOFILE"
done

echo "Creating netboot image: $RELEASE/$ARCH/$FLAVOR"

update-kernel \
	--arch "$ARCH" \
	--flavor "$FLAVOR" \
	--feature "$FEATURE" \
	--package "$PACKAGE" \
	--repositories-file "$REPOFILE" \
	"$OUTDIR"

# older vanilla kernels do not have the flavor appended.
for file in vmlinuz config System.map; do
	if [ -f "$OUTDIR"/$file ]; then
		mv "$OUTDIR"/$file "$OUTDIR"/$file-"$FLAVOR"
	fi
done

rm -f "$REPOFILE"
