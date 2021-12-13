package year2021;

enum LineType {
    Incomplete(expected:Array<String>);
    Corrupt(char:String);
}
