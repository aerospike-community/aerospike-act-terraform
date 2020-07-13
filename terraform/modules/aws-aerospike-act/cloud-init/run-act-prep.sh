#!/usr/bin/bash

if [ ${skip_act_prep} -gt 0 ]
then
    echo "Skipping act_prep"
else
    echo "Running act_prep on devices: ${devices}"

    IFS=',' read -ra devices <<< "${devices}"
    pids=()

    for device in "$${devices[@]//[[:space:]]}"; do
        sudo act_prep $device &
        pids+=($!)
    done

    # Block until all processes complete
    for pid in $${pids[*]}; do
        wait $pid
    done
fi
