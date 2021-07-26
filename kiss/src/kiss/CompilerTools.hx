package kiss;

import sys.io.Process;
#if macro
import kiss.Kiss;
import kiss.Helpers;
import sys.FileSystem;
import sys.io.File;
import haxe.io.Path;

using StringTools;
using haxe.io.Path;

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
        // if folder exists, delete it
        if (FileSystem.exists(args.outputFolder)) {
            for (file in FileSystem.readDirectory(args.outputFolder)) {
                FileSystem.deleteFile(Path.join([args.outputFolder, file]));
            }
            FileSystem.deleteDirectory(args.outputFolder);
        }

        // create it again
        FileSystem.createDirectory(args.outputFolder);

        // Copy all files in that don't need to be processed in some way
        function copyToFolder(file) {
            File.copy(file, Path.join([args.outputFolder, file.withoutDirectory()]));
        }

        if (args.extraFiles == null) {
            args.extraFiles = [];
        }
        for (file in [args.importHxFile, args.hxmlFile, args.langProjectFile].concat(args.extraFiles)) {
            if (file != null) {
                copyToFolder(file);
            }
        }
        
        // If a main haxe file was given, use it
        var mainHxFile = if (args.mainHxFile != null) {
            args.mainHxFile;
        }
        // Otherwise use the default
        else {
            Path.join([Helpers.libPath("kiss"), "src", "kiss", "ScriptMain.hx"]);
        }
        copyToFolder(mainHxFile);

        var mainClassName = mainHxFile.withoutDirectory().withoutExtension();

        // make the kiss file just the given expressions dumped into a file,
        // with a corresponding name to the mainClassName
        var kissFileContent = "";
        for (exp in exps) {
            kissFileContent += Reader.toString(exp.def) + "\n";
        }
        File.saveContent(Path.join([args.outputFolder, '$mainClassName.kiss']), kissFileContent);

        // generate build.hxml
        var buildHxmlContent = "";
        buildHxmlContent += "-lib kiss\n";
        buildHxmlContent += '--main $mainClassName\n';
        switch (args.lang) {
            case JavaScript:
                // Throw in hxnodejs because we know node will be running the script:
                buildHxmlContent += '-lib hxnodejs\n';
                buildHxmlContent += '-js $mainClassName.js\n';
            case Python:
                buildHxmlContent += '-python $mainClassName.py\n';
        }
        var buildHxmlFile = Path.join([args.outputFolder, 'build.hxml']);
        File.saveContent(buildHxmlFile, buildHxmlContent);

        // run haxelib install on given hxml and generated hxml
        var hxmlFiles = [buildHxmlFile];
        Helpers.assertProcess("haxelib", ["install", "--always", buildHxmlFile]);
        if (args.hxmlFile != null) {
            hxmlFiles.push(args.hxmlFile);
            Helpers.assertProcess("haxelib", ["install", "--always", args.hxmlFile]);
        }

        // TODO install language-specific dependencies from langProjectFile (which might be tricky because we can't set the working directory)

        // Compile the script
        Helpers.assertProcess("haxe", ["--cwd", args.outputFolder].concat(hxmlFiles.map(Path.withoutDirectory)));

        var command = "";
        var scriptExt = "";
        switch (args.lang) {
            case JavaScript:
                command = "node";
                scriptExt = "js";
            case Python:
                command = "python";
                scriptExt = "py";
        }
 
        // return lambda that calls new Process() that runs the target-specific file
        return () -> Helpers.assertProcess(command, [Path.join([args.outputFolder, '$mainClassName.$scriptExt'])]);
    }
}
#end
