#!/bin/bash
WATCH_DIR="$HOME/sense"

# Ensure the directory exists
mkdir -p "$WATCH_DIR"
TIMEOUT="120s"

echo "Watching $WATCH_DIR for changes..."

# -m: monitor indefinitely
# -e close_write: trigger only when a file is written to and closed
# --format "%f": output only the filename
inotifywait -m -e close_write --format "%f" "$WATCH_DIR" | while read -r filename; do
    if [[ "$filename" =~ \.py$ ]]; then
        filepath="$WATCH_DIR/$filename"
        echo "[RUN] $filename changed or created."

        # Execute it (limiting to 2 mins)
        timeout "$TIMEOUT" python3 "$filepath"
        if [ "$?" -eq "124" ]; then
          echo "[TIMEOUT] $filename timed out"
        else
          echo "[DONE] $filename is done"
        fi
    fi
done