#!/bin/bash

rm -rf logs bin results
mkdir -p logs bin results
rm -f tasks.txt

touch tasks.txt

for OFFSET in 2; do
    for INDEX in 0 1 2 3 4 5 6 7 8; do
        for WAY in 0 1 2; do
            if [ "$WAY" -le "$INDEX" ]; then
                SET=$((INDEX - WAY))
                echo "$OFFSET $INDEX $SET" >> tasks.txt
            fi
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
        IMAGE=bin/branchsim_${NAME} \
        run > logs/${NAME}.log 2>&1
'

echo
echo "================ ALL RESULTS ================"
echo "offset,index,set,branch_count,btb_hit_rate,always_nt,always_t,btfnt,one_bit,two_bit"
for f in results/*.csv; do
    cat "$f"
done