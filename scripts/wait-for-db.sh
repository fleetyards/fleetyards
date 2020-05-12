#!/bin/bash

echo "Waiting for db..."
counter=0
MAXTRIES=30

while [ $counter -le $MAXTRIES ]
do
    if $(pg_isready -h $DATABASE_HOST -p 5432 > /dev/null); then
        echo
        echo "DB is ready!"
        exit 0
    fi
    echo $counter
    sleep 2
    counter=$((counter + 1))
done

echo
echo "WARNING: DB not ready after $((MAXTRIES * 2)) seconds! Aborting."
exit 1
