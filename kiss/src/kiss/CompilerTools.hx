package kiss;

#if macro
import kiss.Kiss;
import kiss.Helpers;
import sys.FileSystem;
import sys.io.File;
import haxe.io.Path;
import haxe.macro.Expr;
import haxe.macro.Context;

using StringTools;
using haxe.io.Path;

enum CompileLang {
    JavaScript;
    Python;
}

typedef CompilationArgs = {
    // path to a folder where the script will be compiled
    ?outputFolder:String,
    // path to a file with haxe import statements in it
    ?importHxFile:String,
    // path to a file with hxml args in it (SHOULD NOT specify target or main class)
    ?hxmlFile:String,
    // path to a package.json, requirements.txt, or setup.py file
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
     * @return An expression of a function that, when called, executes the script and returns the script output as a string.
     */
    public static function compileFileToScript(kissFile:String, lang:CompileLang, args:CompilationArgs):Expr {
        var k = Kiss.defaultKissState();
        var beginExpsInFile = Kiss.load(kissFile, k, "", true);
        return compileToScript([beginExpsInFile], lang, args);
    }

    /**
     * Compile kiss expressions into a standalone script
     * @return An expression of a function that, when called, executes the script and returns the script output as a string.
     */
    public static function compileToScript(exps:Array<ReaderExp>, lang:CompileLang, args:CompilationArgs):Expr {
        if (args.outputFolder == null) {
            args.outputFolder = Path.join(["bin", '_kissScript${nextAnonymousScriptId++}']);
        }

        // if folder exists, delete it
        // TODO this assumes the user hasn't put folders in the folder, which
        // would cause a failure because we're not deleting recursively
        if (FileSystem.exists(args.outputFolder)) {
            Prelude.walkDirectory(null, args.outputFolder, (file) -> FileSystem.deleteFile(file), null, (folder) -> FileSystem.deleteDirectory(folder));
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
        switch (lang) {
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
        Prelude.assertProcess("haxelib", ["install", "--always", buildHxmlFile]);
        if (args.hxmlFile != null) {
            hxmlFiles.push(args.hxmlFile);
            Prelude.assertProcess("haxelib", ["install", "--always", args.hxmlFile]);
        }

        // Compile the script
        Prelude.assertProcess("haxe", ["--cwd", args.outputFolder].concat(hxmlFiles.map(Path.withoutDirectory)));

        // TODO install language-specific dependencies from langProjectFile (which might be tricky because we can't set the working directory)

        var command = "";
        var scriptExt = "";
        switch (lang) {
            case JavaScript:
                command = "node";
                scriptExt = "js";
                // npm install outputfolder
                if (args.langProjectFile != null) {
                    // This can only be done in the current working directory, so the project file needs to be moved here
                    // Move existing package.json, package-lock.json, node_modules out of the way:
                    function move(file, newName) {
                        if (FileSystem.exists(file)) {
                            FileSystem.rename(file, newName);
                        }
                    }
                    move("package.json", "package.json.temp");
                    move("package-lock.json", "package-lock.json.temp");
                    move("node_modules", "node_modules.temp");

                    File.copy(args.langProjectFile, "package.json");

                    if (Sys.systemName() == "Windows") {
                        Prelude.assertProcess("cmd.exe", ["/c", 'npm', 'install']);
                    } else {
                        Prelude.assertProcess("npm", ['install']);
                    }

                    FileSystem.deleteFile("package.json");
                    move("node_modules", Prelude.joinPath(args.outputFolder, "node_modules"));
                    move("package-lock.json", Prelude.joinPath(args.outputFolder, "package-lock.json"));

                    move("package.json.temp", "package.json");
                    move("package-lock.json.temp", "package-lock.json");
                    move("node_modules.temp", "node_modules");
                }
            case Python:
                command = "python";
                scriptExt = "py";
                if (args.langProjectFile != null) {
                    // Make a virtual environment
                    // NOTE this is placed outside the output folder, so it will get reused.
                    // In some cases this might be bad if the virtual environment gets bad
                    // versions of dependencies stuck in it
                    var envFolder = '${args.outputFolder}-env';
                    Prelude.assertProcess("python", ["-m", "venv", envFolder]);
                    var envBinDir = if (Sys.systemName() == "Windows") "Scripts" else "bin";
                    // trace(Prelude.assertProcess("ls", [envFolder]).replace("\n", " "));
                    // trace(Prelude.assertProcess("ls", [Path.join([envFolder, envBinDir])]).replace("\n", " "));
                    var envPython = Path.join([envFolder, envBinDir, "python"]);
                    command = envPython;
                    switch (args.langProjectFile.extension()) {
                        case "txt":
                            // the requirements file's original path is fine for this case
                            Prelude.assertProcess(envPython, ["-m", "pip", "install", "-r", args.langProjectFile]);
                        case "py":
                            // python setup.py install
                            Prelude.assertProcess(envPython, [Path.join([args.outputFolder, args.langProjectFile.withoutDirectory()]), "install"]);
                    }
                }
        }

        // return an expression for a lambda that calls new Process() that runs the target-specific file
        var callingCode = 'function (?inputLines:Array<String>) { return kiss.Prelude.assertProcess("$command", [haxe.io.Path.join(["${args.outputFolder}", "$mainClassName.$scriptExt"])].concat(inputLines)); }';
        #if test
        trace(callingCode);
        #end
        return Context.parse(callingCode, Context.currentPos());
    }

    static var nextAnonymousScriptId = 0;
}
#end
