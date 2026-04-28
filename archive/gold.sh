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
        sed -i '/^\s*building_rare_earths_mine = .*/d' "$file"

        sed '/{N;N;N;N;/type = "building_rare_earths_mine"/{d}}' "$file" > "${file}.sedtmp" && mv "${file}.sedtmp" "$file"
        sed '
        /^[[:space:]]*N;# calculated.*$/{
            :a
            N
            /\n[[:space:]]*}[[:space:]]*$/!ba
            /type[[:space:]]*=[[:space:]]*"building_rare_earths_mine"/d
        }
        ' "$file" > "${file}.sedtmp" && mv "${file}.sedtmp" "$file"



        # Add new bg_rare_earths_mining lines based on bg_gold_mining
        awk '
        function count_char(s, c,    t) {
            t = s
            return gsub(c, "", t)
        }

        BEGIN {
            in_state = 0
            state_depth = 0
            current_state = ""

            in_resource = 0
            res_depth = 0
            res_type = ""
            res_amount = ""

            gold_total = 0
            rubber_total = 0
            seen_rare_earth = 0

            # ---- CUSTOM OVERRIDES (per state) ----
            # --- LARGE (30) ---
            custom["STATE_CALIFORNIA"]      = 30
            custom["STATE_HINGGAN"]         = 30

            # --- MEDIUM (20) ---
            custom["STATE_SOUTH_MADAGASCAR"] = 20
            custom["STATE_CONGO"]            = 20
            custom["STATE_TONKIN"]           = 20
            custom["STATE_MALAYA"]           = 20
            custom["STATE_KOLA"]             = 20

            # --- SMALL (10) ---
            custom["STATE_NORRLAND"]              = 10
            custom["STATE_QUEBEC"]                = 10
            custom["STATE_NORTHWEST_TERRITORIES"] = 10
            custom["STATE_BAJA_CALIFORNIA"]       = 10
            custom["STATE_FORMOSA"]               = 10

            # --- TINY (3) ---
            custom["STATE_RHONE"]          = 3
            custom["STATE_AQUITAINE"]      = 3
            custom["STATE_BAVARIA"]        = 3
            custom["STATE_SAXONY"]         = 3
            custom["STATE_WESTERN_SERBIA"] = 3
            custom["STATE_TALLINN"]        = 3
            # --------------------------------------
        }

        {
            line = $0

            # Detect start of a state block (STATE_SOMETHING = {)
            if (!in_state && match(line, /^[ \t]*(STATE_[A-Z0-9_]+)[ \t]*=[ \t]*\{/, sm)) {
                in_state = 1
                state_depth = 0
                current_state = sm[1]

                gold_total = 0
                rubber_total = 0
                seen_rare_earth = 0
            }

            # Detect start of a resource block
            if (in_state && !in_resource && line ~ /^[ \t]*resource[ \t]*=[ \t]*\{/) {
                in_resource = 1
                res_depth = 0
                res_type = ""
                res_amount = ""
            }

            # While in a resource block, capture type and discovered/undiscovered amount
            if (in_state && in_resource) {
                if (match(line, /^[ \t]*type[ \t]*=[ \t]*"([^"]+)"/, m)) {
                    res_type = m[1]
                }
                if (match(line, /^[ \t]*(discovered_amount|undiscovered_amount)[ \t]*=[ \t]*([0-9]+)/, a)) {
                    res_amount = a[2] + 0
                }
            }

            # Capture plain building_gold_mine = N lines (e.g. in capped_resources)
            if (in_state && match(line, /^[ \t]*building_gold_mine[ \t]*=[ \t]*([0-9]+)/, gm)) {
                gold_total += (gm[1] + 0)
            }

            # Track if rare earth already exists in this state
            if (in_state && line ~ /type[ \t]*=[ \t]*"building_rare_earths_mine"/) {
                seen_rare_earth = 1
                printf "WARNING seen_rare_earth at line %d: %s\n", NR, $0 > "/dev/stderr"
            }

            pending_line = line

            # Update depths based on braces on this line
            open_braces  = count_char(line, "{")
            close_braces = count_char(line, "}")

            if (in_state) {
                state_depth += (open_braces - close_braces)
            }

            if (in_state && in_resource) {
                res_depth += (open_braces - close_braces)

                # End of resource block
                if (res_depth <= 0) {
                    in_resource = 0

                    # Apply this resource block to totals (if it had an amount)
                    if (res_amount != "") {
                        if (res_type == "building_gold_field" || res_type == "building_gold_mine") {
                            gold_total += res_amount
                        } else if (res_type == "building_rubber_plantation") {
                            rubber_total += res_amount
                        }
                    }
                }
            }

            # If this line closes the state, insert before it
            if (in_state && state_depth == 0 && line ~ /^[ \t]*}\s*$/) {
                if (!seen_rare_earth) {
                    # Default calculation
                    rare_from_rubber = int(rubber_total / 4)
                    rare_total = gold_total + rare_from_rubber

                    # Custom override if present
                    if (current_state in custom) {
                        rare_total = rare_total + custom[current_state] + 0
                    }

                    if (rare_total > 0) {
                        print ""
                        print "    # calculated (rubber: " rare_from_rubber ", gold: " gold_total ", custom: " (current_state in custom ? custom[current_state] : "none") ")"
                        print "    resource = {"
                        print "        type = \"building_rare_earths_mine\""
                        print "        discovered_amount = " rare_total
                        print "    }"
                    }
                }

                print pending_line
                in_state = 0
                current_state = ""
                next
            }

            print pending_line
        }
    ' "$file" > "${file}.tmp" && mv "${file}.tmp" "$file"







        echo "Finished processing $file."
    fi
done