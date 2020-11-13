package kiss;

import haxe.macro.Expr;
import kiss.Reader;

// A lot of special forms need to convert expressions recursively, so they get passed an ExprConversion
typedef ExprConversion = (ReaderExp) -> Expr;
