package kiss;

import haxe.macro.Expr;
import haxe.macro.Context;

class Helpers {
    public static function withPos(e:ExprDef):Expr {
        return {
            pos: Context.currentPos(),
            expr: e
        };
    }
}
