#!/bin/bash

# Define the input file name
input_file="nmap_output.txt"

# Check if the file exists
if [[ ! -f "$input_file" ]]; then
    echo "Error: File '$input_file' not found."
    exit 1
fi

# Use awk to find the line starting with "Nmap scan report for" 
# and then print the last field ($NF) which is the IP address.
awk '/^Nmap scan report for/ {print $NF}' "$input_file"
