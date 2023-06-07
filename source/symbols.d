module symbols;

import std.exception;
import std.sumtype;

int address = 0;


struct Symbol {
    string name;
    int offset;
}

enum int not_defined = -1;

int[string] symbol_table;
static this() {
    symbol_table = [
        "SP"     :  0,
        "LCL"    :  1,
        "ARG"    :  2,
        "THIS"   :  3,
        "THAT"   :  4,

        "R0"     :  0,
        "R1"     :  1,
        "R2"     :  2,
        "R3"     :  3,
        "R4"     :  4,
        "R5"     :  5,
        "R6"     :  6,
        "R7"     :  7,
        "R8"     :  8,
        "R9"     :  9,
        "R10"    : 10,
        "R11"    : 11,
        "R12"    : 12,
        "R13"    : 13,
        "R14"    : 14,
        "R15"    : 15,

        "SCREEN" : 0x4000,
        "KBD"    : 0x6000,
    ];
}


void add_symbol(string identifier) {
    enforce(identifier !in symbol_table);
    symbol_table[identifier] = address;
}


int[][string] reference_table;


void add_reference(string identifier) {
    if (identifier in reference_table) {
        reference_table[identifier] ~= address;
    }
    else {
        reference_table[identifier] = [address];
    }
}




// ushort computation_to_binary() {}
// 0       0b101010
// 1       0b111111
// -1      0b111010
// D       0b001100
// A       0b110000
// !D      0b001101
// !A      0b110001
// -D      0b001111
// -A      0b110011

// D+1     0b011111
// A+1     0b110111
// D-1     0b001110
// A-1     0b110010
// D+A     0b000010
// D-A     0b010011
// A-D     0b000111
// D&A     0b000000
// D|A     0b010101
