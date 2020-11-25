package kiss;

import kiss.Reader;
import kiss.List;

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

    public static function fromArgs(exps:Array<ReaderExp>, message:String) {
        return new CompileError(exps, message);
    }

    public function toString() {
        var posPrefix = switch (exps.length) {
            case 1:
                exps[0].pos;
            default:
                var justLineAndColumnIdx = exps[-1].pos.indexOf(":") + 1;
                exps[0].pos + '-' + exps[-1].pos.substr(justLineAndColumnIdx);
        }

        return '\nKiss compilation failed!\n'
            + posPrefix
            + ": "
            + message
            + "\nFrom:"
            + [for (exp in exps) exp.def.toString()].toString();
    }
}
