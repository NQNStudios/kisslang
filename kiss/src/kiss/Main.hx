package kiss;

#if macro
import haxe.macro.Expr;
import kiss.Kiss;
import kiss.Reader;
import kiss.Stream;

using tink.MacroApi;
using StringTools;
#end

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
            case other:
                // TODO show a helpful list of subcommands
                Sys.println('$other is not a kiss subcommand');
                Sys.exit(1);
        }

        return macro null;
    }

    static function convert(args:Array<String>) {
        // `kiss convert` converts its stdin input to Haxe expressions.
        // with --all, it reads everything from stdin at once (for piping). Without --all, it acts as a repl,
        // where \ at the end of a line signals that the expression is not complete
        // TODO write tests for this
        // TODO use this to implement runAtRuntime() for sys targets by running a haxe subprocess

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

        var line = "";
    }
}
