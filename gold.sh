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
                rare_earths_value = int(gold_value) #1:1
                print $0
                printf "        bg_rare_earths_mining = %d \n", rare_earths_value
                next
            }
            { print }
        ' "$file" > "${file}.tmp" && mv "${file}.tmp" "$file"

        
        # Add new resource block for bg_rare_earths_mining based on bg_gold_fields
        awk '
            BEGIN {
                inside_block = 0
                block_lines = ""
                has_rare_earths = 0
                file_content = ""
            }

            {
                file_content = file_content $0 "\n"
                if ($0 ~ /type\s*=\s*"bg_rare_earths_mining"/) {
                    has_rare_earths = 1
                }
            }

            END {
                if (has_rare_earths) {
                    sub(/\n$/, "", file_content)  # Remove trailing newline
                    printf "%s", file_content
                    exit
                }

                # Process file content to add rare earths
                split(file_content, lines, "\n")
                inside_block = 0
                block_lines = ""

                for (i = 1; i <= length(lines); i++) {
                    line = lines[i]

                    if (line ~ /^\s*resource\s*=\s*{/) {
                        inside_block = 1
                        block_lines = line "\n"
                        continue
                    }

                    if (inside_block) {
                        block_lines = block_lines line "\n"
                        if (line ~ /^\s*}/) {
                            inside_block = 0

                            if (block_lines ~ /type\s*=\s*"bg_gold_fields"/) {
                                # Print original block
                                printf "%s", block_lines

                                # Extract undiscovered amount
                                amt = 0
                                if (block_lines ~ /undiscovered_amount\s*=\s*([0-9]+)/) {
                                    match(block_lines, /undiscovered_amount\s*=\s*([0-9]+)/, m)
                                    amt = m[1]
                                }

                                # Add rare earths block once
                                print "    resource = {"
                                print "        type = \"bg_rare_earths_mining\""
                                print "        discovered_amount = " amt
                                print "    }"
                                continue
                            } else {
                                printf "%s", block_lines
                                continue
                            }
                        }
                        continue
                    }

                    print line
                }
            }
        ' "$file" > "${file}.tmp" && mv "${file}.tmp" "$file"






        echo "Finished processing $file."
    fi
done