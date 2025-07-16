#!/bin/bash

# Camel Case Renaming Script
# This script renames files and folders to camel case format
# - Capitalizes the first letter after spaces, punctuation, and underscores
# - Preserves file extensions
# - Works with both files and directories

# Function to check if a string is already in proper camelCase
is_already_camel_case() {
    local input="$1"
    
    # Check if the string contains obvious separators that need processing (but not hyphens for now)
    if [[ "$input" =~ [[:space:]_] ]]; then
        return 1  # Contains separators, needs processing
    fi
    
    # Check for multiple consecutive hyphens or other obvious issues
    if [[ "$input" =~ [[:space:]]{2,}|_{2,}|--+ ]]; then
        return 1  # Has formatting issues, needs processing
    fi
    
    # If it starts with uppercase and has a mix of cases, likely already camelCase (even with single hyphens)
    if [[ "$input" =~ ^[A-Z][a-zA-Z0-9-]*$ ]] && [[ "$input" =~ [a-z] ]] && [[ "$input" =~ [A-Z] ]]; then
        return 0  # Probably already good camelCase, just might need hyphen processing
    fi
    
    return 1  # Needs processing
}

# Function to convert a string to camel case (improved version)
to_camel_case() {
    local input="$1"
    local extension="$2"
    
    # First check if it's already in good camelCase format
    if is_already_camel_case "$input"; then
        # Handle single hyphens in camelCase strings (like "EEG-based" or "EEG-Based")
        if [[ "$input" =~ - ]]; then
            # Only process single hyphens, preserve the rest
            local result="$input"
            
            # Replace hyphen followed by any letter (lower or uppercase) with uppercase letter
            while [[ "$result" =~ -([a-zA-Z]) ]]; do
                local letter="${BASH_REMATCH[1]}"
                local upper_letter=$(echo "$letter" | tr '[:lower:]' '[:upper:]')
                result="${result/-$letter/$upper_letter}"
            done
            
            if [[ -n "$extension" ]]; then
                result="${result}${extension}"
            fi
            echo "$result"
        else
            # Already good, just add extension
            if [[ -n "$extension" ]]; then
                echo "${input}${extension}"
            else
                echo "$input"
            fi
        fi
        return 0
    fi
    
    # For strings that need full processing
    # Convert to lowercase first
    local lowercase_input=$(echo "$input" | tr '[:upper:]' '[:lower:]')
    
    # Replace various separators and punctuation with spaces
    local normalized=$(echo "$lowercase_input" | sed 's/[[:space:]_-]\+/ /g' | sed 's/[^a-z0-9[:space:]]/ /g' | sed 's/  \+/ /g' | sed 's/^ \+\| \+$//g')
    
    # Split by spaces and capitalize each word
    local result=""
    IFS=' ' read -ra words <<< "$normalized"
    
    for word in "${words[@]}"; do
        if [[ -n "$word" ]]; then
            # Capitalize first letter
            first_char=$(echo "${word:0:1}" | tr '[:lower:]' '[:upper:]')
            rest_of_word="${word:1}"
            capitalized="${first_char}${rest_of_word}"
            result="${result}${capitalized}"
        fi
    done
    
    # Add back the extension if it exists
    if [[ -n "$extension" ]]; then
        result="${result}${extension}"
    fi
    
    echo "$result"
}

# Function to rename a single item (file or directory)
rename_item() {
    local item_path="$1"
    local item_name=$(basename "$item_path")
    local item_dir=$(dirname "$item_path")
    
    # Skip if item doesn't exist
    if [[ ! -e "$item_path" ]]; then
        echo "Warning: '$item_path' does not exist, skipping..."
        return 1
    fi
    
    # Extract extension for files (not directories)
    local extension=""
    local name_without_ext="$item_name"
    
    if [[ -f "$item_path" ]]; then
        # Extract extension (including the dot)
        if [[ "$item_name" == *.* ]]; then
            extension=".${item_name##*.}"
            name_without_ext="${item_name%.*}"
        fi
    fi
    
    # Convert to camel case
    local new_name=$(to_camel_case "$name_without_ext" "$extension")
    local new_path="$item_dir/$new_name"
    
    # Check if rename is needed
    if [[ "$item_name" == "$new_name" ]]; then
        echo "No change needed: '$item_name'"
        return 0
    fi
    
    # Check if target already exists
    if [[ -e "$new_path" ]]; then
        echo "Warning: Target '$new_name' already exists, skipping '$item_name'"
        return 1
    fi
    
    # Perform the rename
    if mv "$item_path" "$new_path" 2>/dev/null; then
        echo "Renamed: '$item_name' → '$new_name'"
        return 0
    else
        echo "Error: Failed to rename '$item_name'"
        return 1
    fi
}

# Function to process directory recursively
process_directory() {
    local dir_path="$1"
    local recursive="$2"
    
    if [[ ! -d "$dir_path" ]]; then
        echo "Error: '$dir_path' is not a directory"
        return 1
    fi
    
    echo "Processing directory: $dir_path"
    
    # First, rename files in the current directory
    find "$dir_path" -maxdepth 1 -type f -print0 | while IFS= read -r -d '' file; do
        rename_item "$file"
    done
    
    # If recursive mode, process subdirectories
    if [[ "$recursive" == "true" ]]; then
        find "$dir_path" -mindepth 1 -type d -print0 | while IFS= read -r -d '' subdir; do
            process_directory "$subdir" "true"
        done
    fi
    
    # Finally, rename directories (do this last to avoid path issues)
    find "$dir_path" -maxdepth 1 -type d ! -path "$dir_path" -print0 | while IFS= read -r -d '' subdir; do
        rename_item "$subdir"
    done
}

# Function to display usage
show_usage() {
    cat << EOF
Usage: $0 [OPTIONS] [FILE/DIRECTORY...]

Convert filenames and folder names to camel case while preserving file extensions.

OPTIONS:
    -r, --recursive    Process directories recursively
    -h, --help         Show this help message
    
EXAMPLES:
    $0 "my file.pdf"                    # Rename single file
    $0 "my_folder"                      # Rename single directory
    $0 -r "/path/to/directory"          # Rename all items in directory recursively
    $0 *.txt                            # Rename all .txt files in current directory
    
CAMEL CASE RULES:
    - Capitalizes first letter
    - Capitalizes letters after spaces, underscores, hyphens, punctuation
    - Removes spaces, underscores, hyphens
    - Preserves file extensions (e.g., .pdf, .txt)
    
EXAMPLES OF CONVERSIONS:
    "my document.pdf"     → "MyDocument.pdf"
    "user_data.json"      → "UserData.json"
    "old-file-name.txt"   → "OldFileName.txt"
    "folder name"         → "FolderName"
EOF
}

# Main script logic
main() {
    local recursive=false
    local items=()
    
    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -r|--recursive)
                recursive=true
                shift
                ;;
            -h|--help)
                show_usage
                exit 0
                ;;
            -*)
                echo "Unknown option: $1"
                show_usage
                exit 1
                ;;
            *)
                items+=("$1")
                shift
                ;;
        esac
    done
    
    # If no items specified, show usage
    if [[ ${#items[@]} -eq 0 ]]; then
        echo "Error: No files or directories specified"
        echo ""
        show_usage
        exit 1
    fi
    
    # Process each item
    local success_count=0
    local total_count=${#items[@]}
    
    for item in "${items[@]}"; do
        if [[ -f "$item" ]]; then
            # It's a file
            if rename_item "$item"; then
                ((success_count++))
            fi
        elif [[ -d "$item" ]]; then
            # It's a directory
            process_directory "$item" "$recursive"
            ((success_count++))
        else
            echo "Warning: '$item' does not exist or is not accessible"
        fi
    done
    
    echo ""
    echo "Summary: Processed $success_count out of $total_count items"
}

# Run the main function with all arguments
main "$@"
