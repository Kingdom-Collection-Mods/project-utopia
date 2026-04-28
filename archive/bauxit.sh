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

       awk '
        function ceil_half(x) { return int((x + 1) / 2) }

        {
            line = $0

            # Track when we are inside capped_resources block
            if ($0 ~ /^\s*capped_resources\s*=\s*{/) {
            in_capped = 1
            inserted = 0
            sulfur = -1
            lead   = -1
            }

            if (in_capped) {
            if (match($0, /building_sulfur_mine\s*=\s*([0-9]+)/, a)) sulfur = a[1]
            if (match($0, /building_lead_mine\s*=\s*([0-9]+)/, b))   lead   = b[1]

            # Print the line as-is
            print line

            # If this line is sulfur or lead and we have not inserted yet,
            # insert ONE bauxite line based on max(sulfur, lead) if known so far.
            if (!inserted && ($0 ~ /building_sulfur_mine\s*=/ || $0 ~ /building_lead_mine\s*=/)) {
                maxv = sulfur
                if (lead > maxv) maxv = lead

                # If at least one of them exists, insert
                if (maxv >= 0) {
                printf "        building_bauxite_mine = %d\n", ceil_half(maxv)
                inserted = 1
                }
            }

            # End of capped_resources block
            if ($0 ~ /^\s*}\s*$/) {
                in_capped = 0
            }

            next
            }

            # Outside capped_resources, just print
            print line
        }
        ' "$file" > "${file}.tmp" && mv "${file}.tmp" "$file"

        echo "Finished processing $file."
    fi
done
