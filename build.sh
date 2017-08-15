#!/bin/bash
for i in maps/*.tmx; do
    tiled --export-map "Lua files (*.lua)" "$i" "maps/$(basename "$i" .tmx).lua"; 
done
love "$(dirname "$0")"