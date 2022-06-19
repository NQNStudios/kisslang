package kiss;

import kiss.KissError;
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
    // whether to skip haxelib install all --always
    ?skipHaxelibInstall:Bool,
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
    public static function compileToScript(exps:Array<ReaderExp>, lang:CompileLang, args:CompilationArgs, ?sourceExp:ReaderExp):Expr {
        var handleError = (error) -> {
            var error = 'External compilation error: $error';
            if (sourceExp != null) {
                throw KissError.fromExp(sourceExp, error);
            } else {
                throw new KissError(exps, error);
            }
        }

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

        // Find the haxelib folder of the class compiling a script (trickier than it should be):
        var module = Context.getLocalModule();
        var moduleFile = module.replace(".", "/") + ".hx";
        var fullFile = Context.getPosInfos(Context.currentPos()).file.replace("\\", "/");
        var classPath = fullFile.replace(moduleFile, "");
        var classPathFolders = classPath.split("/");
        while (classPathFolders.length > 0) {
            try {
                Prelude.libPath(classPathFolders[classPathFolders.length - 1]);
                break;
            } catch (e) {
                classPathFolders.pop();
            }
        }
        if (classPathFolders.length == 0) {
            handleError('compileToScript called by file $moduleFile which is not in a haxelib folder');
        }
        var haxelibPath = classPathFolders.join("/");

        function copyToFolder(file, ?libPath) {
            if (libPath == null) {
                libPath = haxelibPath;
            }

            File.copy(Path.join([libPath, file]), Path.join([args.outputFolder, file.withoutDirectory()]));
        }

        // Copy all files in that don't need to be processed in some way
        if (args.extraFiles == null) {
            args.extraFiles = [];
        }
        for (file in [args.importHxFile, args.hxmlFile, args.langProjectFile].concat(args.extraFiles)) {
            if (file != null) {
                copyToFolder(file);
            }
        }

        var haxelibSetupOutput = Prelude.tryProcess("haxelib", ["setup"], handleError, [""]);
        var messageBeforePath = "haxelib repository is now ";
        var haxelibRepositoryPath = haxelibSetupOutput.substr(haxelibSetupOutput.indexOf(messageBeforePath)).replace(messageBeforePath, "");

        // If a main haxe file was given, use it.
        // Otherwise use the default
        var mainHxFile = "ScriptMain.hx";
        if (args.mainHxFile != null) {
            mainHxFile = args.mainHxFile;
            copyToFolder(mainHxFile);
        } else {
            copyToFolder(mainHxFile, Path.join([Prelude.libPath("kiss"), "src", "kiss"]));
        }

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

        // install language-specific dependencies from langProjectFile (which might be tricky because we can't set the working directory)
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

                    // Special handling for dts2hx bindings after a finished or failed npm build:
                    function clearDotHaxelib() {
                        if (FileSystem.exists(".haxelib")) {
                            for (externLib in FileSystem.readDirectory(".haxelib")) {
                                if (FileSystem.exists(Prelude.joinPath(haxelibRepositoryPath, externLib))) {
                                    Prelude.purgeDirectory(Prelude.joinPath(haxelibRepositoryPath, externLib));
                                }
                                move(Prelude.joinPath(".haxelib", externLib), Prelude.joinPath(haxelibRepositoryPath, externLib));
                            }
                            Prelude.purgeDirectory(".haxelib");
                        }
                    }

                    move("package.json", "package.json.temp");
                    move("package-lock.json", "package-lock.json.temp");
                    move("node_modules", "node_modules.temp");

                    File.copy(Path.join([haxelibPath, args.langProjectFile]), "package.json");

                    var oldHandleError = handleError;
                    handleError = (error) -> {
                        clearDotHaxelib();   
                        oldHandleError(error);
                    }
                    if (Sys.systemName() == "Windows") {
                        Prelude.tryProcess("cmd.exe", ["/c", 'npm', 'install'], handleError);
                    } else {
                        Prelude.tryProcess("npm", ['install'], handleError);
                    }

                    FileSystem.deleteFile("package.json");
                    move("node_modules", Prelude.joinPath(args.outputFolder, "node_modules"));
                    move("package-lock.json", Prelude.joinPath(args.outputFolder, "package-lock.json"));
                    
                    clearDotHaxelib();

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
                    Prelude.tryProcess("python", ["-m", "venv", envFolder], handleError);
                    var envBinDir = if (Sys.systemName() == "Windows") "Scripts" else "bin";
                    // trace(Prelude.assertProcess("ls", [envFolder]).replace("\n", " "));
                    // trace(Prelude.assertProcess("ls", [Path.join([envFolder, envBinDir])]).replace("\n", " "));
                    var envPython = Path.join([envFolder, envBinDir, "python"]);
                    command = envPython;
                    switch (args.langProjectFile.extension()) {
                        case "txt":
                            // the requirements file's original path is fine for this case
                            Prelude.tryProcess(envPython, ["-m", "pip", "install", "-r", Path.join([haxelibPath, args.langProjectFile])], handleError);
                        case "py":
                            // python setup.py install
                            Prelude.tryProcess(envPython, [Path.join([args.outputFolder, args.langProjectFile.withoutDirectory()]), "install"], handleError);
                    }
                }
        }

        // run haxelib install on given hxml and generated hxml
        var hxmlFiles = [buildHxmlFile];
        Prelude.tryProcess("haxelib", ["install", "--always", buildHxmlFile], handleError);
        if (args.hxmlFile != null) {
            if (args.skipHaxelibInstall == null || !args.skipHaxelibInstall) {
                Prelude.tryProcess("haxelib", ["install", "--always", Path.join([haxelibPath, args.hxmlFile])], handleError);
            }
            hxmlFiles.push(args.hxmlFile);
        }

        // Compile the script
        Prelude.tryProcess("haxe", ["--cwd", args.outputFolder].concat(hxmlFiles.map(Path.withoutDirectory)), handleError);

        // return an expression for a lambda that calls new Process() that runs the target-specific file
        var callingCode = 'function (?inputLines:Array<String>) { if (inputLines == null) inputLines = []; return kiss.Prelude.assertProcess("$command", [haxe.io.Path.join(["${args.outputFolder}", "$mainClassName.$scriptExt"])].concat(inputLines)); }';
        #if test
        trace(callingCode);
        #end
        return Context.parse(callingCode, Context.currentPos());
    }

    static var nextAnonymousScriptId = 0;
}
#end
