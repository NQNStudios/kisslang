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

    // When called from the command-line, `kiss` converts its stdin input to Haxe expressions.
    // with --all, it reads everything from stdin at once (for piping). Without --all, it acts as a repl,
    // where \ at the end of a line signals that the expression is not complete
    // TODO write tests for this
    // TODO use this to implement runAtRuntime() for sys targets by running a haxe subprocess
    static macro function macroMain():Expr {
        var k = Kiss.defaultKissState();
        if (Sys.args().indexOf("--all") != -1) {
            var kissInputStream = Stream.fromString(Sys.stdin().readAll().toString());
            Reader.readAndProcess(kissInputStream, k, (readerExp) -> {
                Sys.println(Kiss.readerExpToHaxeExpr(readerExp, k).toString());
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
                        Sys.println(Kiss.readerExpToHaxeExpr(readerExp, k).toString());
                    });

                    line = "";
                }
            } catch (e:haxe.io.Eof) {}
        }

        var line = "";
        return macro null;
    }
}
