
import std.exception;
import std.file: exists;
import std.stdio: File, writef;
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


    ushort[] binary = parse(input_path);

    string output_extension = ".hack";

    string output_path = "";//input_path.withExtension(output_extension);
    if (input_path.extension == output_extension) {
        output_path = input_path ~ output_extension;
    } else {
        output_path = input_path.setExtension(output_extension);
    }

    File file_out = File(output_path, "wb");
    file_out.writef!"%(%016b\n%)\n"(binary);
    // output_path.write(binary.map!(inst => swapEndian(inst)).array);
}
