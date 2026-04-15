#!/bin/bash

set -euo pipefail

# PDF merge helper using Ghostscript.
OUTPUT_FILE="merged_output.pdf"
PASSWORD=""
QUIET=true

show_usage() {
    cat << 'EOF'
Usage:
  ./pdf_merge.sh [OPTIONS] <pdf1> <pdf2> [pdf3 ...]

Merge multiple PDF files with Ghostscript.

OPTIONS:
  -o, --output <file>      Output PDF filename (default: merged_output.pdf)
    -p, --password <value>   PDF password for encrypted input files
  --no-quiet               Disable quiet mode (show Ghostscript logs)
  -h, --help               Show this help message

EXAMPLES:
  ./pdf_merge.sh -o "Final Application.pdf" \
    2026_04_check_EN.pdf ApplicationForm.pdf 2026_05_bank_EN.pdf \
    images.pdf MaumeIELTSCert.pdf NaoIncomeStatementDyson.pdf NaoIncomeStatementMedtronic.pdf

  ./pdf_merge.sh --output merged.pdf file1.pdf file2.pdf
EOF
}

require_command() {
    local cmd="$1"
    if ! command -v "$cmd" >/dev/null 2>&1; then
        echo "Error: '$cmd' is not installed or not in PATH."
        echo "Install Ghostscript on macOS with: brew install ghostscript"
        exit 1
    fi
}

main() {
    local input_files=()

    while [[ $# -gt 0 ]]; do
        case "$1" in
            -o|--output)
                if [[ $# -lt 2 ]]; then
                    echo "Error: Missing value for $1"
                    show_usage
                    exit 1
                fi
                OUTPUT_FILE="$2"
                shift 2
                ;;
            -p|--password)
                if [[ $# -lt 2 ]]; then
                    echo "Error: Missing value for $1"
                    show_usage
                    exit 1
                fi
                PASSWORD="$2"
                shift 2
                ;;
            --no-quiet)
                QUIET=false
                shift
                ;;
            -h|--help)
                show_usage
                exit 0
                ;;
            --)
                shift
                while [[ $# -gt 0 ]]; do
                    input_files+=("$1")
                    shift
                done
                ;;
            -*)
                echo "Error: Unknown option: $1"
                show_usage
                exit 1
                ;;
            *)
                input_files+=("$1")
                shift
                ;;
        esac
    done

    if [[ ${#input_files[@]} -lt 2 ]]; then
        echo "Error: Provide at least 2 PDF files to merge."
        show_usage
        exit 1
    fi

    require_command gs

    local missing=0
    local file
    for file in "${input_files[@]}"; do
        if [[ ! -f "$file" ]]; then
            echo "Error: Input file not found: $file"
            missing=1
        fi
    done

    if [[ $missing -ne 0 ]]; then
        exit 1
    fi

    local -a gs_args
    gs_args=(
        -dNOPAUSE
        -dBATCH
        -sDEVICE=pdfwrite
        -sOutputFile="$OUTPUT_FILE"
    )

    if [[ -n "$PASSWORD" ]]; then
        gs_args+=(-sPDFPassword="$PASSWORD")
    fi

    if [[ "$QUIET" == true ]]; then
        gs_args=(-q "${gs_args[@]}")
    fi

    gs "${gs_args[@]}" "${input_files[@]}"

    echo "Merged ${#input_files[@]} file(s) into: $OUTPUT_FILE"
}

main "$@"
