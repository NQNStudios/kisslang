package kiss;

import sys.io.Process;
#if macro
import haxe.macro.Expr;
import haxe.macro.Context;
import haxe.macro.Type;
import kiss.Kiss;
import kiss.Reader;
import kiss.Stream;

using tink.MacroApi;
using kiss.Kiss;
#end

import haxe.Json;
import haxe.io.Path;
import sys.io.File;
import sys.io.Process;
import sys.FileSystem;

using StringTools;

class Main {
    static function main() {
        macroMain();
    }

    // When called from the command-line, Kiss has various subcommands, some of which can only run in macro context
    static macro function macroMain():Expr {
        var args = Sys.args();

        switch (args.shift()) {
            case "convert":
                convert(args);
            case "new-project":
                newProject(args);
            case "new-flixel-project":
                newFlixelProject(args);
            case "new-express-project":
                newExpressProject(args);
            case "new-vscode-project":
                newVscodeProject(args);
            case "new-firefox-project":
                newFirefoxProject(args);
            case "implement":
                // kiss implement [type] [fromLib]
                var _pwd = args.pop();
                var theInterface = args.shift();
                var pArgs = ["-D", "no-extern", "build-scripts/common-args.hxml", "-lib", "kiss"];
                // pass --lib and the lib containing the interface as specified
                if (args.length > 0) {
                    pArgs = pArgs.concat(["-lib", args.shift()]);
                }
                pArgs = pArgs.concat(["--run", "kiss.Main", "_implement", theInterface]);
                var p = new Process("haxe", pArgs);
                var exitCode = p.exitCode(true);
                Sys.print(p.stdout.readAll().toString());
                Sys.print(p.stderr.readAll().toString());
                Sys.exit(exitCode);
            case "_implement":
                implement(args[0]);
            case other:
                // TODO show a helpful list of subcommands
                Sys.println('$other is not a kiss subcommand');
                Sys.exit(1);
        }

        return macro null;
    }

    static function promptFor(what:String, ?defaultVal:String) {
        var prompt = what;
        if (defaultVal != null) {
            if (defaultVal.length == 0) {
                prompt += ' (default empty)';
            } else {
                prompt += ' (default $defaultVal)';
            }
        }
        prompt += ": ";
        Sys.print(prompt);
        var input = Sys.stdin().readLine();
        if (input.trim().length == 0) {
            if (defaultVal != null) {
                input = defaultVal;
            } else {
                Sys.println('value required for $what');
                Sys.exit(1);
            }
        }
        return input;
    }

    static function _makeFileForNewProject(templateDir:String, templateFile:Array<String>, workingDir:String, projectName:String, pkg:String) {
        // Expand this list when making new templates with different binary extensions
        var extensionsForBytes = [
            "png"
        ];
        var replaceStringTemplate = true;
        var getContent:haxe.Constraints.Function = File.getContent;
        var saveContent:haxe.Constraints.Function = File.saveContent;
        if (extensionsForBytes.indexOf(Path.extension(templateFile[templateFile.length - 1])) != -1) {
            replaceStringTemplate = false;
            getContent = File.getBytes;
            saveContent = File.saveBytes;
        }

        var fullTemplateFilePath = Path.join([templateDir, "template"].concat(templateFile));
        var newFileContent:Dynamic = getContent(fullTemplateFilePath);
        if (replaceStringTemplate)
            newFileContent = StringTools.replace(newFileContent, "template", pkg);
        var templateFileInNewProject = [for (part in templateFile) if (part == "template") pkg else part];
        var newFilePath = Path.join([workingDir, projectName].concat(templateFileInNewProject));
        saveContent(newFilePath, newFileContent);
    }

    static function _makeFolderForNewProject(templateDir:String, templateFolder:Array<String>, workingDir:String, projectName:String, pkg:String) {
        var fullTemplateFolderPath = Path.join([templateDir, "template"].concat(templateFolder));
        var templateFolderInNewProject = [for (part in templateFolder) if (part == "template") pkg else part];
        var newFolderPath = Path.join([workingDir, projectName].concat(templateFolderInNewProject));
        FileSystem.createDirectory(newFolderPath);

        for (fileOrFolder in FileSystem.readDirectory(fullTemplateFolderPath)) {
            if (FileSystem.isDirectory(Path.join([fullTemplateFolderPath, fileOrFolder]))) {
                _makeFolderForNewProject(templateDir, templateFolder.concat([fileOrFolder]), workingDir, projectName, pkg);
            } else {
                _makeFileForNewProject(templateDir, templateFolder.concat([fileOrFolder]), workingDir, projectName, pkg);
            }
        }
    }

    static function newProject(args:Array<String>) {
        var kissLibPath = new Process("haxelib", ["libpath", "kiss"]).stdout.readAll().toString().trim();
        var name = promptFor("name");
        // TODO put the prompted name and description in a README.md
        var pkg = name.toLowerCase().replace("-", "_");
        var haxelibJson = {
            "name": name,
            "contributors": promptFor("authors (comma-separated)").split(",").map(StringTools.trim),
            // TODO can make the default URL actually point to the projects subdirectory... but only want that functionality if the working dir is in kisslang/projects
            "url": promptFor("url", "https://github.com/NQNStudios/kisslang"),
            "license": promptFor("license", "LGPL"),
            "tags": {
                var t = promptFor("tags (comma-separated)", "").split(",").map(StringTools.trim);
                t.remove("");
                t;
            },
            "description": promptFor("description", ""),
            "version": "0.0.0",
            "releasenote": "",
            "classPath": "src/",
            "main": '${pkg}.Main',
            "dependencies": {
                "kiss": ""
            }
        };
        var workingDir = Sys.args().pop();
        var makeFileForNewProject:haxe.Constraints.Function = _makeFileForNewProject.bind(kissLibPath, _, workingDir, name, pkg);
        FileSystem.createDirectory(Path.join([workingDir, name, "src", pkg]));
        makeFileForNewProject(["src", "template", "Main.hx"]);
        makeFileForNewProject(["src", "template", "Main_.kiss"]);
        makeFileForNewProject(["build.hxml"]);
        makeFileForNewProject(["test.sh"]);
        File.saveContent(Path.join([workingDir, name, 'haxelib.json']), Json.stringify(haxelibJson, null, "\t"));
    }

    static function newFlixelProject(args:Array<String>) {
        var title = promptFor("title");
        var company = promptFor("creator/studio");
        var width = Std.parseInt(promptFor("window width", "1280"));
        var height = Std.parseInt(promptFor("window height", "720"));
        var background = promptFor("background color", "#000000");

        var kissFlixelLibPath = new Process("haxelib", ["libpath", "kiss-flixel"]).stdout.readAll().toString().trim();
        var workingDir = Sys.args().pop();
        FileSystem.createDirectory(Path.join([workingDir, title]));

        // Substitute the specified values into the Project.xml:
        var projectXml:Xml = Xml.parse(File.getContent(Path.join([kissFlixelLibPath, "template", "Project.xml"])));
        var root = projectXml.elements().next();

        var firstAppElement = Lambda.find(root, (node) -> node.nodeType == Xml.Element && node.nodeName == 'app');
        firstAppElement.set("title", title);
        firstAppElement.set("file", title);
        firstAppElement.set("company", company);

        var firstWindowElement = Lambda.find(root, (node) -> node.nodeType == Xml.Element && node.nodeName == 'window');
        firstWindowElement.set("width", '$width');
        firstWindowElement.set("height", '$height');
        firstWindowElement.set("background", background);

        File.saveContent(Path.join([workingDir, title, 'Project.xml']), projectXml.toString());
        var makeFileForNewProject:haxe.Constraints.Function = _makeFileForNewProject.bind(kissFlixelLibPath, _, workingDir, title, "");
        var makeFolderForNewProject:haxe.Constraints.Function = _makeFolderForNewProject.bind(kissFlixelLibPath, _, workingDir, title, "");
        makeFolderForNewProject([".vscode"]);
        makeFolderForNewProject(["assets"]);
        makeFolderForNewProject(["source"]);
        makeFileForNewProject(["hxformat.json"]);
        makeFileForNewProject([".gitignore"]);
    }

    static function newExpressProject(args:Array<String>) {
        var title = promptFor("title (lower-case!)").toLowerCase();
        var pkg = title.replace("-", "_");
        var kissExpressLibPath = new Process("haxelib", ["libpath", "kiss-express"]).stdout.readAll().toString().trim();
        var workingDir = Sys.args().pop();
        var projectDir = Path.join([workingDir, title]);
        FileSystem.createDirectory(projectDir);

        var makeFileForNewProject:haxe.Constraints.Function = _makeFileForNewProject.bind(kissExpressLibPath, _, workingDir, title, pkg);
        var makeFolderForNewProject:haxe.Constraints.Function = _makeFolderForNewProject.bind(kissExpressLibPath, _, workingDir, title, pkg);
        makeFolderForNewProject(["src", "template"]);
        makeFileForNewProject([".gitignore"]);
        makeFileForNewProject(["build.hxml"]);
        {
            makeFileForNewProject(["package.json"]);
            var packageFile = Path.join([projectDir, "package.json"]);
            var packageJson = Json.parse(File.getContent(packageFile));
            packageJson.name = title;
            File.saveContent(packageFile, Json.stringify(packageJson, null, "\t"));
        }
        makeFileForNewProject(["test.sh"]);
    }

    static function newVscodeProject(args:Array<String>) {
		var title = promptFor("title (lower-case!)").toLowerCase();
		var pkg = title.replace("-", "_");
        var kissVscodeApiLibPath = new Process("haxelib", ["libpath", "kiss-vscode-api"]).stdout.readAll().toString().trim();
        var workingDir = Sys.args().pop();
        var projectDir = Path.join([workingDir, title]);
        FileSystem.createDirectory(projectDir);

        var makeFileForNewProject:haxe.Constraints.Function = _makeFileForNewProject.bind(kissVscodeApiLibPath, _, workingDir, title, pkg);
        var makeFolderForNewProject:haxe.Constraints.Function = _makeFolderForNewProject.bind(kissVscodeApiLibPath, _, workingDir, title, pkg);
        makeFolderForNewProject(["src"]);
        makeFolderForNewProject([".vscode"]);
        makeFileForNewProject([".gitignore"]);
        makeFileForNewProject([".vscodeignore"]);
        makeFileForNewProject(["README.md"]);
        makeFileForNewProject(["build.hxml"]);
        {
            makeFileForNewProject(["package.json"]);
            var packageFile = Path.join([projectDir, "package.json"]);
            var packageJson = Json.parse(File.getContent(packageFile));
            packageJson.name = title;
            File.saveContent(packageFile, Json.stringify(packageJson, null, "\t"));
        }
        makeFileForNewProject(["test.sh"]);
    }

    static function newFirefoxProject(args:Array<String>) {
		var title = promptFor("title (lower-case!)").toLowerCase();
		var description = promptFor("description");
		var pkg = title.replace("-", "_");
        var urlPatterns = [];
        while (true) {
            var nextPattern = promptFor("url pattern (i.e. '*://*.mozilla.org/*') (blank to finish)", "");
            if (nextPattern.length == 0)
                break;
            urlPatterns.push(nextPattern);
        }
        var kissFirefoxLibPath = new Process("haxelib", ["libpath", "kiss-firefox"]).stdout.readAll().toString().trim();
        var workingDir = Sys.args().pop();
        var projectDir = Path.join([workingDir, title]);
        FileSystem.createDirectory(projectDir);

        var makeFileForNewProject:haxe.Constraints.Function = _makeFileForNewProject.bind(kissFirefoxLibPath, _, workingDir, title, pkg);
        var makeFolderForNewProject:haxe.Constraints.Function = _makeFolderForNewProject.bind(kissFirefoxLibPath, _, workingDir, title, pkg);
        makeFolderForNewProject(["src"]);
        makeFolderForNewProject(["icons"]);
        makeFileForNewProject([".gitignore"]);
        makeFileForNewProject(["build.hxml"]);
        {
            makeFileForNewProject(["manifest.json"]);
            var manifestFile = Path.join([projectDir, "manifest.json"]);
            var manifestJson = Json.parse(File.getContent(manifestFile));
            manifestJson.name = title;
            manifestJson.description = description;
            manifestJson.content_scripts[0].matches = urlPatterns;
            File.saveContent(manifestFile, Json.stringify(manifestJson, null, "\t"));
        }
        {
            makeFileForNewProject(["package.json"]);
            var packageFile = Path.join([projectDir, "package.json"]);
            var packageJson = Json.parse(File.getContent(packageFile));
            packageJson.name = title;
            packageJson.description = description;
            File.saveContent(packageFile, Json.stringify(packageJson, null, "\t"));
        }
        makeFileForNewProject(["test.sh"])
    }

    static function convert(args:Array<String>) {
        // `kiss convert` converts its stdin input to Haxe expressions.
        // with --all, it reads everything from stdin at once (for piping). Without --all, it acts as a repl,
        // where \ at the end of a line signals that the expression is not complete
        // TODO write tests for this
        #if macro
        var k = Kiss.defaultKissState();
        k.wrapListExps = false;
        var pretty = args.indexOf("--pretty") != -1;

        if (args.indexOf("--hscript") != -1)
            k = k.forHScript();

        function print(s:String) {
            if (!pretty)
                s = s.replace("\n", " ");

            Sys.println(s);
        }

        if (args.indexOf("--all") != -1) {
            var kissInputStream = Stream.fromString(Sys.stdin().readAll().toString());
            Reader.readAndProcess(kissInputStream, k, (readerExp) -> {
                print(Kiss.readerExpToHaxeExpr(readerExp, k).toString());
            });
        } else {
            var line = "";
            try {
                while (true) {
                    if (line.length == 0) {
                        Sys.print(">>> ");
                    } else {
                        Sys.print("    ");
                    }

                    line += Sys.stdin().readLine();

                    if (line.endsWith("\\")) {
                        line = line.substr(0, line.length - 1);
                        continue;
                    }

                    var kissInputStream = Stream.fromString(line);
                    Reader.readAndProcess(kissInputStream, k, (readerExp) -> {
                        print(Kiss.readerExpToHaxeExpr(readerExp, k).toString());
                    });

                    line = "";
                }
            } catch (e:haxe.io.Eof) {}
        }
        #end
    }

    // edge cases for this:
    // TODO interfaces that extend other interfaces
    // TODO generic interfaces
    // TODO this could be useful for typedefs as well
    // TODO merging a generated implementation with a Kiss file that already has some functions implemented
    static function implement(theInterface:String) {
        // This runs in a subprocess whose stdout output can only be read all at once,
        // so re-implement trace to write to a file:
        haxe.Log.trace = (v, ?infos) -> {
            File.saveContent("implementLog.txt", "");
            File.saveContent("implementLog.txt", File.getContent("implementLog.txt") + "\n" + Std.string(v));
            v;
        }
        #if macro
        var type = Context.resolveType(Helpers.parseComplexType(theInterface), Context.currentPos());
        switch (type) {
            case TInst(classTypeRef, params):
                var classType = classTypeRef.get();
                var fields = classType.fields.get();
                trace(fields);

                for (field in fields) {
                    function printAccess() {
                        if (!field.isPublic) {
                            Sys.print("&private ");
                        }
                        switch (field.kind) {
                            case FVar(_, _):
                                if (!field.isFinal) {
                                    Sys.print("&mut ");
                                }
                            default:
                        }
                    }
                    function printPropertyAccess(access, getOrSet:Bool) {
                        Sys.print(switch (access) {
                            case AccNormal: "default";
                            case AccNo: "null";
                            case AccCall if (getOrSet): "get";
                            case AccCall if (!getOrSet): "set";
                            default: '/* TODO automatic interface property access printing is not supported for access ${access}*/';
                        });
                    }
                    function printType(type, precedingColon = true, followingSpace = true, argType = false) {
                        function _printType(t:{function get():{var name:String;}}, params:Array<Type>) {
                            var t = t.get();
                            Sys.print(t.name);
                            if (params.length > 0) {
                                Sys.print("<");
                                var first = true;
                                for (param in params) {
                                    if (!first) {
                                        Sys.print(",");
                                    }
                                    first = false;
                                    printType(param, false, false);
                                }
                                Sys.print(">");
                            }
                            if (followingSpace) {
                                Sys.print(" ");
                            }
                        }

                        if (precedingColon) {
                            Sys.print(":");
                        }
                        switch (type) {
                            case TInst(t, params):
                                _printType(t, params);
                            case TEnum(t, params):
                                _printType(t, params);
                            case TAbstract(t, params):
                                _printType(t, params);
                            case TType(t, params):
                                _printType(t, params);
                            case TFun(args, ret) if (argType):
                                Sys.print("(");
                                var first = true;
                                for (arg in args) {
                                    if (!first) {
                                        Sys.print(",");
                                    }
                                    first = false;
                                    printType(arg.t,false,false,true);
                                }
                                Sys.print(")->");
                                printType(ret, false);
                            case TFun(_args, ret):
                                printType(ret, false);
                            default:
                                Sys.print('/* TODO Automatic interface type printing is not supported for type: $type */');
                        }
                    }

                    switch (field.kind) {
                        case FVar(read, write):
                            Sys.print("(prop ");
                            printAccess();
                            printType(field.type);
                            Sys.print('${field.name} ');
                            {
                                Sys.print("(property ");
                                printPropertyAccess(read, true);
                                Sys.print(" ");
                                printPropertyAccess(write, false);
                                Sys.print(")");
                            }
                            Sys.print(")");
                        case FMethod(k):
                            Sys.print("(method ");
                            printAccess();
                            switch (k) {
                                case MethNormal:
                                case MethInline:
                                    Sys.print("/* TODO Automatic interface implementation does not support inline methods */");
                                case MethMacro:
                                    throw "There should never be macro functions in an interface";
                                case MethDynamic:
                                    Sys.print("&dynamic ");    
                            }
                            printType(field.type);
                            Sys.print('${field.name} ');
                            Sys.print("[");
                            switch (field.type) {
                                case TFun(args, _ret):
                                    var first = true;
                                    for (arg in args) {
                                        if (!first) {
                                            Sys.print(" ");
                                        }
                                        first = false;
                                        if (arg.opt) {
                                            Sys.print("&opt ");
                                        }
                                        printType(arg.t, true, true, true);
                                        Sys.print(arg.name);
                                    }
                                default:
                                    throw "Function is not a function?";
                            }

                            Sys.print("] ");
                            Sys.print('(throw "TODO Not implemented!")');
                            Sys.print(")");
                        default:
                            Sys.print("// TODO Automatic interface implementation not supported for field:");
                            Sys.print('/* ${Std.string(field).replace("/*", "").replace("*/", "")} */');
                        }
                    Sys.println("");
                }
            default:
                throw 'Unexpected result from resolveType of $theInterface';
        }
        #end
    }
}
