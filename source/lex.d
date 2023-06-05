module lex;
import std.range;
import std.conv;

char* name_start;
size_t name_length;

struct M_string {
    string internal = "";
    bool is_good() {
        return internal.length > 0;
    }
    T opCast(T)() {
        static if (is(T == string)) {return internal;} else
        static if (is(T == bool)) {return is_good();}
    }
    this(string str) {
        internal = str;
    }
}

alias Input = string;


M_string try_lex_identifier(ref Input input) {
    import std.uni;
    if (input.front().is_identifier_head()) {
        return cast(M_string) lex_identifier(input);
    }
    return cast(M_string) "";
}


string lex_identifier(ref Input input) {
    string identifier = input.front().to!string;
    input.popFront;
    while (!input.empty() && input.front.is_identifier_tail) {
        identifier ~= input.front();
        input.popFront();
    }
    return identifier;
}


unittest {
    string s = "bucket)   ";
    auto output = lex_identifier(s);
    assert("bucket" == output, output);
}


bool is_identifier_head(dchar input) {
    import std.uni;
    return (
        input.isAlpha()
        || input == '$'
        || input == ':'
        || input == '_'
        || input == '.'
    );
}


bool is_identifier_tail(dchar input) {
    import std.uni;
    return (
        input.isAlphaNum()
        || input == '$'
        || input == ':'
        || input == '_'
        || input == '.'
    );
}


alias ws = lex_whitespace_inline;
alias ws_line = lex_blank_line;


void lex_blank_line(ref Input input) {
    lex_whitespace_inline(input);
    if (input.front() == '\n') {
        input.popFront();
        lex_whitespace_inline(input);
    }
}


void lex_whitespace_inline(ref Input input) {
    while (!input.empty()) {
        if (!input.front.is_white()) {break;}
        input.popFront();
    }
}


unittest {
    string s = "     test";
    lex_whitespace_inline(s);
    assert(s == "test", s);
}


bool is_white(dchar input) {
    import std.uni;
    return (0
        || input == ' '
        || input == '\t'
    );
}


unittest {
    assert(is_white(' '));
    assert(is_white('\t'));
}


bool try_lex_symbol(string symbols)(dchar input) {
    static foreach (character; symbols) {
        if (input.front() == character) {
            input.popFront();
            return true;
        }
    }
    return false;
}
