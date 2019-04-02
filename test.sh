#!/bin/bash
COMMANDS="../ex1"
stdbuf -o 0 "$COMMANDS" 2>stderr.txt | tee stdout.txt
