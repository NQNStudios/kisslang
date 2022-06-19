package kiss;

import kiss.Reader;
import kiss.List;

using kiss.Stream;
using kiss.Reader;

enum ErrorType {
    CantCompile;
    CompileWarning;
    AssertionFail;
}

// Internal Kiss errors
class KissError {
    var exps:List<ReaderExp>;
    var message:String;

    public function new(exps:Array<ReaderExp>, message:String) {
        this.exps = exps;
        this.message = message;
    }

    public static function fromExp(exp:ReaderExp, message:String) {
        return new KissError([exp], message);
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
        return new KissError(exps, message);
    }

    public function toString(type = CantCompile) {
        var posPrefix = switch (exps.length) {
            case 1:
                exps[0].pos.toPrint();
            default:
                var firstPos = exps[0].pos.toPrint();
                var lastPos = exps[-1].pos.toPrint();
                var justLineAndColumnIdx = lastPos.indexOf(":") + 1;
                firstPos + '-' + lastPos.substr(justLineAndColumnIdx);
        }

        var typePrefix = switch (type) {
            case CantCompile:
                "Kiss compilation failed";
            case CompileWarning:
                "Kiss compilation warning";
            case AssertionFail:
                "Assertion failed";
        };

        return '$posPrefix: $typePrefix: $message'
            + "\nFrom:"
            + [for (exp in exps) exp.def.toString()].toString();
    }

    public static function warnFromExp(exp:ReaderExp, message:String) {
        Prelude.print(new KissError([exp], message).toString(CompileWarning));
    }
}
