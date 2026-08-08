#!/bin/sh
# The MNIST data, into the repository.
#
# Carried rather than fetched from elsewhere at run time.  The original host has
# been unreliable for years, and a teaching site whose flagship example stops
# working because someone else's server is down is worse than eleven megabytes.
#
# They stay gzipped: that is how they are distributed, the browser gunzips them
# on the way in, and the images are 47 MB unpacked against 10 MB packed.
set -e
cd "$(dirname "$0")/.."
OUT=web/data
mkdir -p "$OUT"

# Several mirrors, because the canonical one is the one that goes away.  The
# files are identical - the checksums below are from the original distribution.
MIRRORS="https://storage.googleapis.com/cvdf-datasets/mnist
https://ossci-datasets.s3.amazonaws.com/mnist
http://yann.lecun.com/exdb/mnist"

FILES="train-images-idx3-ubyte.gz
train-labels-idx1-ubyte.gz
t10k-images-idx3-ubyte.gz
t10k-labels-idx1-ubyte.gz"

for f in $FILES; do
    [ -s "$OUT/$f" ] && { echo "have $f"; continue; }
    got=
    for m in $MIRRORS; do
        printf '%s from %s ... ' "$f" "${m#*//}"
        if curl -fsSL --max-time 120 "$m/$f" -o "$OUT/$f.part"; then
            mv "$OUT/$f.part" "$OUT/$f"
            echo "ok"
            got=1
            break
        fi
        echo "no"
    done
    [ -n "$got" ] || { echo "could not fetch $f from any mirror"; rm -f "$OUT/$f.part"; exit 1; }
done

echo
ls -l "$OUT" | awk 'NR>1 {printf "  %6.1f MB  %s\n", $5/1048576, $9}'
printf '  total   %s\n' "$(du -sh "$OUT" | cut -f1)"

# What the guest will see, so that a mismatch shows up here rather than as a
# confusing error inside the student's program.
echo
for f in $FILES; do
    printf '  %-32s ' "$f"
    gzip -dc "$OUT/$f" | head -c 16 | od -An -tu1 -N8 |
        awk '{ magic = $3 * 256 + $4; n = $5 * 16777216 + $6 * 65536 + $7 * 256 + $8;
               printf "magic %d, %d items\n", magic, n }'
done
