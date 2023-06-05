module parse;

import lex;

import std.range;
import std.sumtype;


short[] assemble(string input) {
    // foreach (instruction; parse(input)) {

    // }
    return [];
}

void parse(string input) {
    while (input.length > 0) {
        ws(input);
        try_parse_instruction(input);
    }
}


struct Label {
    string name;
    size_t address;
}


bool try_parse_instruction(ref Input input_) {
    Input input = input_.save();
    switch (input.front) {
        case '@':
            parse_tail_load_a(input);
            return true;
        case '(':
            parse_tail_label(input);
            return true;
        case '/':
            parse_tail_label(input);
            return true;
        default:
            break;
    }

    // Some identifier
    M_string m_identifier = try_lex_identifier(input);
    if (!m_identifier) {
        return false;
    }
    string identifier = cast(string) m_identifier;
    switch (identifier) {
        case "A":
            return true;
        case "D":
            return true;
        case "M":
            return true;
        default: break;
    }
    // Variable
    ws(input);
    if (input.front == '=') {
        input.popFront();
        return parse_assign_variable(input);
    }
    return false;
}


unittest {
    string input = "
        fuck=you
        asshole
    ";
    try_parse_instruction(input);
}

bool parse_tail_load_a(ref Input input_) {
    Input input = input_.save();
    input.popFront();
    if ('0' <= input.front && input.front <= '9') {
        input
    }
}


bool parse_tail_label(ref Input input_) {
    Input input = input_.save();
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

    Symbol s = Label(
        cast(string) m_name,
        cast(size_t) input.ptr,
    );
    symbol_table ~= s;
    input_ = input;
    return true;
}


unittest {

    Symbol sym = Label(
        "signal",
        11,
    );
    symbol_table ~= sym;

    Input input = "(  bucket  )";

    assert(parse_tail_label(input));
    symbol_table.back.match!(
        (Label label) {assert(label.name == "bucket", label.name);},
        // (_) {assert(false);}
    );
}
