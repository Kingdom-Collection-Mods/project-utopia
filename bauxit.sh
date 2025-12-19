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

        # Remove existing bg_bauxite_mining lines
        sed -i '/^\s*building_bauxite_mine = .*/d' "$file"

        # Add new bg_bauxite_mining lines based on building_sulfur_mine
        awk '
            /building_sulfur_mine = [0-9]+/ {
                match($0, /building_sulfur_mine = ([0-9]+)/, arr)
                sulfur_value = arr[1]
                bauxite_value = int((sulfur_value + 1) / 2)
                print $0
                printf "        building_bauxite_mine = %d \n", bauxite_value, sulfur_value
                next
            }
            { print }
        ' "$file" > "${file}.tmp" && mv "${file}.tmp" "$file"

        echo "Finished processing $file."
    fi
done
