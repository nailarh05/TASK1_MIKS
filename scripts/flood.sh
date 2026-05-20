#!/bin/bash
for i in $(seq 1 1000); do
    curl -s -o /dev/null http://70.153.148.250/ &
    if [ $((i % 50)) -eq 0 ]; then
        wait
        echo "Batch $i done"
    fi
done
wait
echo "ALL 1000 REQUESTS DONE"
