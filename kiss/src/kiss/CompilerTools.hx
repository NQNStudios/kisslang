package kiss;

#if macro
import kiss.Kiss;

enum CompileLang {
    JavaScript;
    Python;
}

typedef CompilationArgs = {
    lang:CompileLang,
    outputFolder:String,
    // path to a folder where the script will be compiled
    ?importHxFile:String,
    // path to a file with haxe import statements in it
    ?hxmlFile:String,
    // path to a file with hxml args in it (SHOULD NOT specify target or main class)
    ?langProjectFile:String,
    // path to a package.json or requirements.txt file
    ?mainHxFile:String,
    // path to a haxe file defining the Main class
}

/**
 * Multi-purpose tools for compiling Kiss projects.
 */
class CompilerTools {
    /**
     * Compile a kiss file into a standalone script.
     * @return A function that, when called, executes the script and returns the script output as a string.
     */
    public static function compileFileToScript(kissFile:String, args:CompilationArgs):() -> String {
        var k = Kiss.defaultKissState();
        var beginExpsInFile = Kiss.load(kissFile, k, "", true);
        return compileToScript([beginExpsInFile], args);
    }

    /**
     * Compile kiss expressions into a standalone script
     * @return A function that, when called, executes the script and returns the script output as a string.
     */
    public static function compileToScript(exps:Array<ReaderExp>, args:CompilationArgs):() -> String {
        return () -> "";
    }
}
#end
