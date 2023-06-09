module symbols;

import std.exception;
import std.sumtype;

ushort current_address = 0;


struct Symbol {
    string name;
    int offset;
}

enum int not_defined = -1;

ushort[string] symbol_table;
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

ushort next_address = 16;

void add_symbol(string identifier) {
    enforce(identifier !in symbol_table);
    symbol_table[identifier] = current_address;
}


ushort[][string] reference_table;


void add_reference(string identifier) {
    if (identifier in reference_table) {
        reference_table[identifier] ~= current_address;
    }
    else {
        reference_table[identifier] = [current_address];
    }
}


void apply_all_symbols(ushort[] binary) {
    foreach (identifier, locations; reference_table) {
        if (identifier in symbol_table) {
            foreach (location; locations) {
                binary[location] = symbol_table[identifier];
            }
        } else {
            foreach (location; locations) {
                binary[location] = next_address;
            }
            next_address += 1;
        }
    }
}
