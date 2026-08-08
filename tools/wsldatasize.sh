#!/bin/sh
# What the MNIST data weighs, packed and unpacked.
#
# The packed size decides the download; the unpacked size decides how much of a
# browser tab's memory the guest's filesystem holds while it trains.
cd "$(dirname "$0")/.."
total_gz=0
total_raw=0
for f in web/data/*.gz; do
    [ -f "$f" ] || continue
    gz=$(stat -c%s "$f")
    raw=$(gzip -dc "$f" | wc -c)
    total_gz=$((total_gz + gz))
    total_raw=$((total_raw + raw))
    printf '  %-32s %7.1f MB  ->  %7.1f MB\n' "$(basename "$f")" \
        "$(awk "BEGIN{print $gz/1048576}")" "$(awk "BEGIN{print $raw/1048576}")"
done
printf '  %-32s %7.1f MB  ->  %7.1f MB\n' 'total' \
    "$(awk "BEGIN{print $total_gz/1048576}")" \
    "$(awk "BEGIN{print $total_raw/1048576}")"

echo
echo "  what a run actually holds, with the current settings:"
awk 'BEGIN {
    printf "    the four files, unpacked        %6.1f MB\n", '"$total_raw"'/1048576
    printf "    600 training images as float    %6.1f MB\n", 600*784*4/1048576
    printf "    200 test images as float        %6.1f MB\n", 200*784*4/1048576
}'
