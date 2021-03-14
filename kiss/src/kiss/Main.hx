package kiss;

#if macro
import haxe.macro.Expr;
import kiss.Kiss;
import kiss.Reader;
import kiss.Stream;

using tink.MacroApi;
#end

class Main {
    static macro function macroMain():Expr {
        var kissInputStream = Stream.fromString(Sys.stdin().readAll().toString());
        var k = Kiss.defaultKissState();
        Reader.readAndProcess(kissInputStream, k, (readerExp) -> {
            Sys.println(Kiss.readerExpToHaxeExpr(readerExp, k).toString());
        });

        return macro null;
    }

    // When called from the command-line, `kiss` converts its stdin output to Haxe expressions
    // TODO write tests for this
    // TODO use this to implement runAtRuntime() for sys targets by running a haxe subprocess
    static function main() {
        macroMain();
    }
}
