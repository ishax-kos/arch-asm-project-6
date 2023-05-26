module assemble;
import std.range;

short[] assemble(string input) {
    // foreach (instruction; parse(input)) {

    // }
}

void parse(string input) {
    while (input.length > 0) {

    }
}


struct M_string {
    string internal = "";
    bool is_good() {
        return internal.length > 0;
    }
    T opCast(T)() {
        static if (T == string) {return internal;}
    }
    this(string str) {
        internal = str;
    }
}


M_string try_lex_identifier(Stream input) {
    import std.uni;
    if (input.front().is_identifier_head()) {
        return cast(M_string) lex_identifier(input);
    }
    return cast(M_string) "";
}


string lex_identifier(Stream input) {
    string identifier = "" ~ input.front();
    while (input.front().is_identifier_tail()) {
        identifier ~= input.front();
        input.removeFront();
    }
    return identifier;
}


bool is_identifier_head(Dchar input) {
    import std.uni;
    return (
        input.isAlpha()
        || input == '$'
        || input == ':'
        || input == '_'
        || input == '.'
    );
}


bool is_identifier_tail(Dchar input) {
    import std.uni;
    return (
        input.isAlphaNum()
        || input == '$'
        || input == ':'
        || input == '_'
        || input == '.'
    );
}


void lex_whitespace_inline(string input) {
    while (input.front().is_white()) {
        input.removeFront();
    }
}


void lex_blank_line(string input) {
    lex_whitespace_inline(input);
    if (input.front() == '\n') {
        input.removeFront();
        lex_whitespace_inline(input);
    }
}


void lex_whitespace(string input) {
    lex_whitespace_inline();
    lex_blank_line();
}


bool is_white(Dchar input) {
    import std.uni;
    return (0
        || input == ' '
        || input == '\t'
    );
}
