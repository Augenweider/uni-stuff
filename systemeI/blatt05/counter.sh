#! /bin/bash

let x=0             # setze Variable x auf 0
while true          # wiederhole endlos
do
    echo $x         # gib Variable x aus
    let x=x+1       # Zähle x um 1 hoch
    sleep 1         # Warte 1 Sekunde
done

