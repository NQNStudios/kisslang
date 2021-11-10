package kiss;

import kiss.Reader;
import kiss.List;

using kiss.Stream;
using kiss.Reader;

class CompileError {
    var exps:List<ReaderExp>;
    var message:String;

    function new(exps:Array<ReaderExp>, message:String) {
        this.exps = exps;
        this.message = message;
    }

    public static function fromExp(exp:ReaderExp, message:String) {
        return new CompileError([exp], message);
    }

    public static function fromExpStr(pos:Position, expStr:String, message:String) {
        switch (Reader.read(Stream.fromString(expStr), Kiss.defaultKissState())) {
            case Some(exp):
                return fromExp({pos: pos, def: exp.def}, message);
            default:
                throw 'bad'; // TODO better message
        }
    }

    public static function fromArgs(exps:Array<ReaderExp>, message:String) {
        return new CompileError(exps, message);
    }

    public function toString(warning = false) {
        var posPrefix = switch (exps.length) {
            case 1:
                exps[0].pos.toPrint();
            default:
                var firstPos = exps[0].pos.toPrint();
                var lastPos = exps[-1].pos.toPrint();
                var justLineAndColumnIdx = lastPos.indexOf(":") + 1;
                firstPos + '-' + lastPos.substr(justLineAndColumnIdx);
        }

        var failed = if (warning) "warning"; else "failed";

        return '$posPrefix: Kiss compilation $failed: $message'
            + "\nFrom:"
            + [for (exp in exps) exp.def.toString()].toString();
    }

    public static function warnFromExp(exp:ReaderExp, message:String) {
        Prelude.print(new CompileError([exp], message).toString(true));
    }
}
