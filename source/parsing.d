module parsing;

import lexing;
import symbols;

import std.range;
import std.sumtype;
import std.exception;
import std.algorithm.searching: canFind, find;
import std.format;

int line_count = 0;
string file_path = "";

ushort[] parse(string input_path) {
    import std.file: read;
    import std.regex: splitter, ctRegex;
    auto range = (cast(string) read(input_path)).splitter(ctRegex!"\r\n|\n|\r");
    file_path = input_path;
    ushort[] instructions = [];
    foreach(line; range) {
        line_count += 1;
        ws(line);
        if (line.empty) {continue;}
        M_instruction result = try_parse_instruction(line);
        if (result) {
            instructions ~= result.internal;
            current_address += 1;
        }
    }
    // debug { import std.stdio : writeln; try { writeln(symbol_table); } catch (Exception) {} }
    apply_all_symbols(instructions);
    return instructions;
}


string current_position() {
    return format!"%s(%d)"(file_path, line_count);
}


align
struct Instruction {
    ushort internal;
    this(int number) {
        internal = cast(ushort) number;
    }
}

struct M_instruction {
    align(1):
    ushort internal;
    bool is_good = false;
    enum M_instruction none = (){M_instruction ret; ret.is_good = false; return ret;}();

    T opCast(T)() const {
        static if (is(T == bool)) { return is_good; }
        static if (is(T == Instruction)) { return Instruction(internal); }
        assert(0, T.stringof ~ " is not implemented.");
    }
    this(int number) {
        internal = cast(ushort) number;
        is_good = true;
    }
}
M_instruction maybe(Instruction instruction) {
    M_instruction ret;
    ret.internal = cast(ushort) instruction.internal;
    ret.is_good = true;
    return ret;
}
Instruction unwrap(M_instruction m_instruction, string error = "Unwrapped a non-value.") {
    if (m_instruction.is_good) {
        return Instruction(m_instruction.internal);
    }
    throw new Exception(error);
}


M_instruction try_parse_instruction(ref Input input_) {
    Input input = input_.save();
    dchar front = input.front();

    if (front == '@') {
        return M_instruction(parse_load_a(input));
    }
    if (front == '(') {
        parse_label(input);
        return M_instruction.none;
    }


    ushort instruction = 0b111_0_000000_000000;

    auto pos_equals = input.find('=');

    if (!pos_equals.empty) {
        instruction |= parse_destination(input);
    }


    if (pos_equals.empty) {pos_equals = input;}
    else {pos_equals.popFront;}
    auto pos_semi = pos_equals.find(';');

    pos_equals = pos_equals[0..($-pos_semi.length)];
    ws(pos_equals);
    instruction |= parse_arithmetic(pos_equals);

    if (!pos_semi.empty) {
        ushort jump = parse_jump(pos_semi);
        // debug { import std.stdio : writeln; try { writeln(jump); } catch (Exception) {} }

        instruction |= jump;
    }

    return M_instruction(instruction);
}


unittest {
    string line = "A D = 1";
    auto result = cast(Instruction) try_parse_instruction(line);
}


ushort parse_load_a(ref Input input) {
    input.popFront();
    input.ws();
    uint value = 0;

    if (input.front.is_number()) {
        value = input.lex_number();
        enforce(value < 0b1000_0000_0000_0000);
        return cast(ushort) value;
    }
    M_string identifier = try_lex_identifier(input);
    enforce(identifier, "%s Invalid number or symbol".format(current_position));
    {
        add_reference(cast(string) identifier);
        return cast(ushort) value;
    }

}

unittest {
    string input = "
        @wabadoo
    ";
    parse_load_a(input);
}


bool is_number(dchar ch) {
    return '0' <= ch && ch <= '9';
}


bool parse_label(ref Input input) {
    // Input input = input_.save();
    // if (input.front != '(') {
    //     return(false);
    // }
    input.popFront();

    ws(input);

    M_string m_name = try_lex_identifier(input);
    if (!m_name) {
        return(false);
    }
    string name = cast(string) m_name;
    ws(input);

    if (input.front != ')') {
        return(false);
    }
    input.popFront();

    add_symbol(cast(string) m_name);
    // input_ = input;
    return true;
}


unittest {
    Input input = "(  bucket  )";

    assert(parse_label(input));
    assert("bucket" in symbol_table);
}


string invalid_digit_or_register() {

    return format!("%s Invalid expression, "
    ~"valid expressions may use M, A, D, 0, or 1.")(current_position);
}



ushort parse_arithmetic(ref string input_) {
    auto input = input_.save();

    if (input.front == '!' || input.front == '-') {
        return parse_arithmetic_unary(input);
    }

    dchar[3] tokens = [0,0,0];

    enforce("MAD01".canFind(input.front));
    tokens[0] = input.front;
    input.popFront();

    ws(input);

    if (input.empty || input.front == ';') {
        ushort ret = 1;
        switch (tokens[0]) {
            case 'M': ret = 0b1_110000_000000; break;
            case 'A': ret = 0b0_110000_000000; break;
            case 'D': ret = 0b0_001100_000000; break;
            case '1': ret = 0b0_111111_000000; break;
            case '0': ret = 0b0_101010_000000; break;
            default: throw new Exception(invalid_digit_or_register);
        }
        input_ = input;
        return ret;
    }

    enforce(!input.front.is_identifier_tail, invalid_digit_or_register);

    enforce("+-&|".canFind(input.front), input_);
    tokens[1] = input.front;
    input.popFront();

    ws(input);

    enforce("MAD01".canFind(input.front), invalid_digit_or_register);
    tokens[2] = input.front;
    input.popFront();
    // debug { import std.stdio : writeln; try { writeln(input_); } catch (Exception) {} }
    // enforce(!input.front.is_identifier_tail);


    ushort ret;
    switch (tokens) {
        case "D+1"d: ret = 0b0_011111_000000; break;
        case "1+D"d: ret = 0b0_011111_000000; break;
        case "A+1"d: ret = 0b0_110111_000000; break;
        case "1+A"d: ret = 0b0_110111_000000; break;
        case "M+1"d: ret = 0b1_110111_000000; break;
        case "1+M"d: ret = 0b1_110111_000000; break;

        case "D+A"d: ret = 0b0_000010_000000; break;
        case "A+D"d: ret = 0b0_000010_000000; break;
        case "D+M"d: ret = 0b1_000010_000000; break;
        case "M+D"d: ret = 0b1_000010_000000; break;

        case "D-1"d: ret = 0b0_001110_000000; break;
        case "A-1"d: ret = 0b0_110010_000000; break;
        case "M-1"d: ret = 0b1_110010_000000; break;

        case "D-A"d: ret = 0b0_010011_000000; break;
        case "D-M"d: ret = 0b1_010011_000000; break;
        case "A-D"d: ret = 0b0_000111_000000; break;
        case "M-D"d: ret = 0b1_000111_000000; break;

        case "D&A"d: ret = 0b0_000000_000000; break;
        case "A&D"d: ret = 0b0_000000_000000; break;
        case "D&M"d: ret = 0b1_000000_000000; break;
        case "M&D"d: ret = 0b1_000000_000000; break;

        case "D|A"d: ret = 0b0_010101_000000; break;
        case "A|D"d: ret = 0b0_010101_000000; break;
        case "D|M"d: ret = 0b1_010101_000000; break;
        case "M|D"d: ret = 0b1_010101_000000; break;

        default: throw new Exception(invalid_digit_or_register);
    }
    input_ = input;
    return ret;
}


ushort parse_arithmetic_unary(ref string input) {
    // debug { import std.stdio : writeln; try { writeln(input); } catch (Exception) {} }
    ushort ret = 0;
    dchar front = input.front;
    input.popFront();
    ws(input);
    enforce(!input.empty() || input.front != ';', "%s Dangling '%s'".format(current_position, front));
    // enforce(, "%s Dangling '%s'".format(current_position, front));
    if (front == '!') {
        switch (input.front()) {
            case 'M': ret = 0b1_110001_000000; break;
            case 'A': ret = 0b0_110001_000000; break;
            case 'D': ret = 0b0_001101_000000; break;
            case '0': ret = 0b0_111010_000000; break;
            case '1': ret = 0b0_111110_000000; break;
            default: ret = 1; break;
        }
    }else if (front == '-') {
        switch (input.front()) {
            case 'M': ret = 0b1_110011_000000; break;
            case 'A': ret = 0b0_110011_000000; break;
            case 'D': ret = 0b0_001111_000000; break;
            case '1': ret = 0b0_111010_000000; break;
            case '0': ret = 0b0_101010_000000; break;
            case '2': ret = 0b0_111110_000000; break;
            default: ret = 1; break;
        }
    }
    input.popFront();
    // debug { import std.stdio : writeln; try { writeln(input); } catch (Exception) {} }
    enforce(0
        || ret != 1
        || input.empty
        || input.front == ';',
        invalid_digit_or_register
    );
    return ret;
}


unittest {
    string line = "1";
    assert(parse_arithmetic(line) == 0b0_111111_000000);
    line = "M  -  1  ; wabadoo";
    assert(parse_arithmetic(line) == 0b1_110010_000000);
    assert(line == "  ; wabadoo", line);

    line = "^1  ; wabadont";
    assertThrown!Exception(parse_arithmetic(line));

    line = "-M -1  ; wabadont";
    assertThrown!Exception(parse_arithmetic(line));
}

//*             0x  !x  0y  !y  &/+ !o
//*     0       1   0   1   0   1   0
//*     1       1   1   1   1   1   1
//*     -1      1   1   1   0   1   0
//*     D       0   0   1   1   0   0
//*     A       1   1   0   0   0   0
//*     !D      0   0   1   1   0   1
//*     !A      1   1   0   0   0   1
//*     -D      0   0   1   1   1   1
//*     -A      1   1   0   0   1   1

//*     D+1     0   1   1   1   1   1
//*     A+1     1   1   0   1   1   1
//*     D-1     0   0   1   1   1   0
//*     A-1     1   1   0   0   1   0
//*     D+A     0   0   0   0   1   0
//*     D-A     0   1   0   0   1   1
//*     A-D     0   0   0   1   1   1
//*     D&A     0   0   0   0   0   0
//*     D|A     0   1   0   1   0   1


ushort parse_jump(ref string input) {
    if (input.front != ';') {
        return 0b000;
    }
    input.popFront;
    ws(input);

    if (input.empty) {
        throw new Exception("Invalid jump symbol after ';'");
    }
    if (input.length >= 3) {
        scope (exit) input.popFrontN(3);
        switch (input[0..3]) {
            case "JGT" : return 0b001;
            case "JEQ" : return 0b010;
            case "JGE" : return 0b011;
            case "JLT" : return 0b100;
            case "JNE" : return 0b101;
            case "JLE" : return 0b110;
            case "JMP" : return 0b111;
            default: break;
        }
    }
    throw new Exception("Invalid jump symbol after ';'");
}


unittest {
    string line = ";   JNE    ";
    assert(parse_jump(line) == 0b101);
    assert(line == "    ", line);
    line = ";  ";
    try {
        parse_jump(line);
        assert(false);
    }
    catch (Exception) {}
}


struct M_destination {
    align(1):
    ushort internal = 0;
    bool is_good() {
        return internal == 0;
    }
    enum M_destination none = M_destination.init;

    T opCast(T)() const {
        static if (is(T == bool)) { return is_good; }
        static if (is(T == Destination)) { return internal; }
    }
    this(int number) {
        internal = cast(ushort) number;
    }
}


ushort parse_destination(ref string input_) {
    string input = input_.save();
    ushort ret = 0;

    while (true) {
        ws(input);
        ushort mask;
        switch (input.front) {
            case 'A': mask = 0b100_000; break;
            case 'D': mask = 0b010_000; break;
            case 'M': mask = 0b001_000; break;
            case '=':
                input.popFront();
                input_ = input;
                return ret;
            default:
                return throw new Exception("Invalid destination name. Must be A, M, or D.");
        }
        if ((mask & ret) != 0) {
            return throw new Exception("Invalid destination. Can only mention registers once each.");
        }
        ret |= mask;
        input.popFront();
    }
}

unittest {
    {
        string input = "A M D = 1";
        auto val = parse_destination(input);
        assert(input == " 1", input);
        assert(val == 0b111_000);
    }

    {
        string input = "DMAQ = 1";
        assertThrown!Exception(parse_destination(input));
    }
    {
        string input = "AAAA = 1";
        assertThrown!Exception(parse_destination(input));
    }
}
