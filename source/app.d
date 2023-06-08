
import std.exception;
import std.file: exists, read, write;
import std.path;//: baseName, withExtension;
import std.stdio: writefln, writeln;
import std.algorithm: map;
import std.bitmanip: swapEndian;
import std.array: array;

import parsing;

void main(string[] args) {
    if (args.length < 2) {
        writeln("No file provided");
        return;
    }
    string input_path = args[1];

    if (!input_path.exists()) {
        writefln!("File \"%s\" not found.")(input_path.baseName());
        return;
    }


    Instruction[] binary = parse(cast(string) read(input_path));


    string output_path = "";//input_path.withExtension(".o");
    if (input_path.extension == ".o") {
        output_path = input_path ~ ".o";
    } else {
        output_path = input_path.setExtension(".o");
    }

    // File file_out = File(output_path, "wb");
    output_path.write(binary.map!(inst => swapEndian(inst.internal)).array);
}
