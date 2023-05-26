import std.stdio;
import std.exception;
import std.file: exists;
import std.path: baseName, withExtension;

void main(string[] args) {
    if (args.length < 2) {
        writeln("No file provided");
        return;
    }
    string input_path = args[1];
    string input = [];
    if (!input_path.exists()) {
        writefln!("File \"%s\" not found.")(input_path.baseName());
        return;
    }
    else {
        File file = File(input_path, "rb");
        input = cast(string) file.rawRead(new char[](file.size()));
    }
    short[] binary = assemble(input);
    string output_path = input_path.withExtension(".o");
    if (output_path == input_path) {
        output_path ~= ".o";
    }
    File file_out = File(output_path, "wb");
    file_out.rawWrite(binary);
}
