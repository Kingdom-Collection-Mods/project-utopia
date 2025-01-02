#!/bin/bash

# Directory containing the files to process
directory="map_data/state_regions"

# Check if the directory exists
if [ ! -d "$directory" ]; then
    echo "Directory '$directory' not found."
    exit 1
fi

# Process each file in the directory
for file in "$directory"/*; do
    if [ -f "$file" ]; then
        echo "Processing $file..."

        # Remove existing bg_rare_earths_mining lines, ensuring no spaces before the equals sign
        sed -i '/^\s*bg_rare_earths_mining = .*/d' "$file"

        # Add new bg_rare_earths_mining lines based on bg_gold_mining
        awk '
            /bg_gold_mining = [0-9]+/ {
                match($0, /bg_gold_mining = ([0-9]+)/, arr)
                gold_value = arr[1]
                rare_earths_value = int((gold_value + 1) / 2)  # This ensures rounding up
                print $0
                printf "        bg_rare_earths_mining = %d \n", rare_earths_value
                next
            }
            { print }
        ' "$file" > "${file}.tmp" && mv "${file}.tmp" "$file"

        echo "Finished processing $file."
    fi
done
