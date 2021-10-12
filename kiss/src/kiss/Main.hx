package kiss;

import sys.io.Process;
#if macro
import haxe.macro.Expr;
import haxe.macro.Context;
import kiss.Kiss;
import kiss.Reader;
import kiss.Stream;

using tink.MacroApi;
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
            case "implement":
                // kiss implement [type] [fromLib]
                var _pwd = args.pop();
                var theInterface = args.shift();
                var pArgs = ["build-scripts/common-args.hxml", "-lib", "kiss"];
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

    static function makeFileForNewProject(templateFile:Array<String>, workingDir:String, projectName:String, pkg:String) {
        var kissLibPath = new Process("haxelib", ["libpath", "kiss"]).stdout.readAll().toString().trim();
        var fullTemplateFilePath = Path.join([kissLibPath, "template"].concat(templateFile));
        var newFileContent = File.getContent(fullTemplateFilePath).replace("template", pkg);
        var templateFileInNewProject = [for (part in templateFile) if (part == "template") pkg else part];
        var newFilePath = Path.join([workingDir, projectName].concat(templateFileInNewProject));
        File.saveContent(newFilePath, newFileContent);
    }

    static function newProject(args:Array<String>) {
        var name = promptFor("name");
        // TODO put the prompted description in a README.md
        var pkg = name.replace("-", "_");
        var haxelibJson = {
            "name": name,
            "contributors": promptFor("authors (comma-separated)").split(",").map(StringTools.trim),
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
        FileSystem.createDirectory(Path.join([workingDir, name, "src", pkg]));
        makeFileForNewProject(["src", "template", "Main.hx"], workingDir, name, pkg);
        makeFileForNewProject(["src", "template", "Main.kiss"], workingDir, name, pkg);
        makeFileForNewProject(["build.hxml"], workingDir, name, pkg);
        makeFileForNewProject(["test.sh"], workingDir, name, pkg);
        File.saveContent(Path.join([workingDir, name, 'haxelib.json']), Json.stringify(haxelibJson, null, "\t"));
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
        k.hscript = args.indexOf("--hscript") != -1;

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

    static function implement(theInterface:String) {
        #if macro
        var type = Context.resolveType(Helpers.parseComplexType(theInterface), Context.currentPos());
        trace(type);
        #end
    }
}
