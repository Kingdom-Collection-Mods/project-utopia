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
            BEGIN { inside_block = 0; block_lines = "" }

            /^\s*resource\s*=\s*{/ {
                inside_block = 1
                block_lines = $0 "\n"
                next
            }

            inside_block {
                block_lines = block_lines $0 "\n"
                if ($0 ~ /^\s*}/) {
                    inside_block = 0
                    if (block_lines ~ /type\s*=\s*"bg_gold_fields"/) {
                        # Print original block
                        printf "%s", block_lines

                        # Create and print clean duplicated block
                        type_line = ""
                        amount_line = ""

                        split(block_lines, lines, "\n")
                        for (i in lines) {
                            line = lines[i]
                            if (line ~ /type\s*=\s*"bg_gold_fields"/) {
                                type_line = "        type = \"bg_rare_earths_mining\""
                            } else if (line ~ /^\s*undiscovered_amount\s*=/) {
                                match(line, /undiscovered_amount\s*=\s*[0-9]+/, amt)
                                amount_line = "        " amt[0]
                            }
                        }

                        if (type_line != "" && amount_line != "") {
                            print "    resource = {"
                            print type_line
                            print amount_line
                            print "    }"
                        }
                        next
                    } else {
                        # Not a gold fields block — print as-is
                        printf "%s", block_lines
                        next
                    }
                }
                next
            }

            # Default: print other lines
            { print }
        ' "$file" > "${file}.tmp" && mv "${file}.tmp" "$file"




        echo "Finished processing $file."
    fi
done