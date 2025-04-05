#!/bin/bash

# Clean up any previous outputs
rm -f lex.yy.c y.tab.c y.tab.h y.output *.o a.exe 21301559_log.txt

# Generate the parser (yacc)
yacc -d -y --debug --verbose syntax_analyzer.y
echo 'Generated the parser C file as well the header file'

# Generate parser object file
g++ -w -c -o y.o y.tab.c
echo 'Generated the parser object file'

# Generate the scanner (flex)
flex lex_analyzer.l
echo 'Generated the scanner C file'

# Generate scanner object file
g++ -std=c++17 -fpermissive -w -c -o l.o lex.yy.c
echo 'Generated the scanner object file'

# Link and create executable
g++ -std=c++17 y.o l.o
echo 'All ready, running'

# Run test cases
for input in InputOutput/input*.c; do
    if [ -f "$input" ]; then
        echo "Processing $input..."
        ./a.exe "$input"
        echo "Done. Log file generated as 21301559_log.txt"
        echo "----------------------------------------"
    fi
