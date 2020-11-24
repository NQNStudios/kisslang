package kiss;

import haxe.macro.Expr;
import haxe.macro.Context;

using StringTools;

class Helpers {
    public static function withContextPos(e:ExprDef):Expr {
        return {
            pos: Context.currentPos(),
            expr: e
        };
    }

    static function startsWithUpperCase(s:String) {
        return s.charAt(0) == s.charAt(0).toUpperCase();
    }

    // TODO this doesn't parse generic typeparams yet
    public static function parseTypePath(path:String):TypePath {
        var parts:List<String> = path.split(".");
        var uppercaseParts:List<Bool> = parts.map(startsWithUpperCase);
        for (isUpcase in uppercaseParts.slice(0, -2)) {
            if (isUpcase) {
                throw 'Type path $path should only have capitalized type and subtype';
            }
        }
        var lastIsCap = uppercaseParts[-1];
        var penultIsCap = uppercaseParts[-2];

        return if (lastIsCap && penultIsCap) {
            {
                sub: parts[-1],
                name: parts[-2],
                pack: parts.slice(0, -2)
            };
        } else if (lastIsCap) {
            {
                name: parts[-1],
                pack: parts.slice(0, -1)
            };
        } else {
            throw 'Type path $path should end with a capitalized type';
        };
    }

    public static function parseComplexType(path:String):ComplexType {
        return TPath(parseTypePath(path));
    }
}
