#!/bin/bash

rm -rf logs bin results
mkdir -p logs bin results
rm -f tasks.txt

touch tasks.txt

for OFFSET in 2 3 4; do
    for INDEX in 4 5 6; do
        for SET in 0 1 2; do
            echo "$OFFSET $INDEX $SET" >> tasks.txt
        done
    done
done

cat tasks.txt | xargs -P "$(nproc)" -n 3 bash -c '
    OFFSET=$0
    INDEX=$1
    SET=$2

    NAME="o${OFFSET}_i${INDEX}_s${SET}"

    make \
        OFFSET_WIDTH=$OFFSET \
        INDEX_WIDTH=$INDEX \
        SET_WIDTH=$SET \
        BATCH_MODE=1 \
        IMAGE=bin/cachesim_${NAME} \
        run
'

echo
echo "================ ALL RESULTS ================"
echo "offset\tindex\tset\taccess_count\thit_count\tmiss_count\thit_rate"
for f in results/*.csv; do
    cat "$f"
done

