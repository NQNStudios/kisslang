package kiss;

import sys.io.Process;
#if macro
import haxe.macro.Expr;
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

        // TODO `kiss run` subcommand with optional target option. With no target specified, keep trying targets until one exits with status 0 (side-effect danger)

        switch (args.shift()) {
            case "convert":
                convert(args);
            case "new-project":
                newProject(args);
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

    static function makeFileForNewProject(templateFile:Array<String>, projectName:String, pkg:String) {
        var kissLibPath = new Process("haxelib", ["libpath", "kiss"]).stdout.readAll().toString().trim();
        var fullTemplateFilePath = Path.join([kissLibPath, "template"].concat(templateFile));
        var newFileContent = File.getContent(fullTemplateFilePath).replace("template", pkg);
        var templateFileInNewProject = [for (part in templateFile) if (part == "template") pkg else part];
        var newFilePath = Path.join([projectName].concat(templateFileInNewProject));
        File.saveContent(newFilePath, newFileContent);
    }

    static function newProject(args:Array<String>) {
        var name = promptFor("name");
        var pkg = name.replace("-", "_");
        var haxelibJson = {
            "name": name,
            "url": promptFor("url"),
            "license": promptFor("license", "LGPL"),
            "tags": promptFor("tags (comma-separated)", "").split(","),
            "description": promptFor("description", ""),
            "version": "0.0.0",
            "releasenote": "",
            "contributors": [promptFor("author")],
            "classPath": "src/",
            "main": '${pkg}.Main',
            "dependencies": {
                "kiss": ""
            }
        };
        FileSystem.createDirectory('$name/src/$pkg');
        makeFileForNewProject(["src", "template", "Main.hx"], name, pkg);
        makeFileForNewProject(["src", "template", "Main.kiss"], name, pkg);
        makeFileForNewProject(["build.hxml"], name, pkg);
        makeFileForNewProject(["test.sh"], name, pkg);
        File.saveContent('$name/haxelib.json', Json.stringify(haxelibJson));
    }

    static function convert(args:Array<String>) {
        // `kiss convert` converts its stdin input to Haxe expressions.
        // with --all, it reads everything from stdin at once (for piping). Without --all, it acts as a repl,
        // where \ at the end of a line signals that the expression is not complete
        // TODO write tests for this
        // TODO use this to implement runAtRuntime() for sys targets by running a haxe subprocess
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
}
