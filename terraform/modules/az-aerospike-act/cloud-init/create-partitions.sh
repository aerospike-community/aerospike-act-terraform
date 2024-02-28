#!/usr/bin/bash

if [ ${partition_count} -eq 0 ]
then
    echo "Leaving devices unpartitioned: ${devices}"
else
    echo "Creating partitions on devices: ${devices}"

    devices=(${devices})
    for device in $${devices[@]}
    do
        size="$(((100-${over_provision})/${partition_count}))"
        start=0
        stop=$size
        parts=""

        for ((i=0;i<${partition_count};i++))
        do
            parts="$${parts}mkpart primary $start% $stop% "
            ((start += $size))
            ((stop += $size))
        done

        parted -a opt --script $device mklabel gpt $parts
    done
fi
