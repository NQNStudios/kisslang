package kiss;

#if macro
import kiss.Kiss;

enum CompileLang {
    JavaScript;
    Python;
}

typedef CompilationArgs = {
    lang:CompileLang,
    // path to a folder where the script will be compiled
    outputFolder:String,
    // path to a file with haxe import statements in it
    ?importHxFile:String,
    // path to a file with hxml args in it (SHOULD NOT specify target or main class)
    ?hxmlFile:String,
    // path to a package.json or requirements.txt file
    ?langProjectFile:String,
    // path to a haxe file defining the Main class
    ?mainHxFile:String,
    // paths to extra files to copy
    ?extraFiles:Array<String>
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
        // TODO if folder exists, delete it
        // TODO create it again
        // TODO copy all files in
            // import.hx if given
            // hxml file if given
            // language-specific project file if given
            // main .hx file if given, or default
                // make sure it calls build() on the right file, and imports kiss.Prelude
            // all extra files
            // make the main.kiss file just a begin of array(exps)

        // TODO generate build.hxml
            // -lib kiss
            // target compiler arguments and -cmd argument according to lang
        // run haxelib install all in folder
        // install language-specific dependencies
        // call haxe args.hxml build.hxml
        // return lambda that calls new Process() that runs the target-specific file

        return () -> "";
    }
}
#end
