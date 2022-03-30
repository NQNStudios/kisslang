package prokgen;

import haxe.macro.Context;
import haxe.macro.Expr;

class Generable {
    public static macro function build():Array<Field> {
        var fields = Context.getBuildFields();

        var instanceFields:Map<String, ComplexType> = [];
        var generatorFields:Map<ComplexType,String> = [];
        var hasGenScore = false;

        for (field in fields) {
            switch (field) {
                // TODO find all the fields that are generators
                case {
                    name: name,
                    doc: _,
                    access: access,
                    kind: FVar(type, _),
                    pos: _,
                    meta: _
                } if (access.indexOf(AStatic) != -1):
                // TODO find all fields that are non-generator instance variables
                case {
                    name: name,
                    doc: _,
                    access: access,
                    kind: FVar(type, _),
                    pos: _,
                    meta: _
                } if (access.indexOf(AStatic) == -1):
                // TODO make sure genScore() is defined and returns Float
                case {
                    name: "genScore",
                    doc: _,
                    access: access,
                    kind: FFun({
                        // TODO ret needs to be float or Tink_macro needs to identify the expression as returning Float
                        ret: _,
                        args: [],
                        expr: _
                    }),
                    pos: _,
                    meta: _
                }:
                    hasGenScore = true;
                default:
            }
        }


        var generateField = {
            name: "generate",
            access: [AStatic, APublic],
            kind: FFun({
                ret: null,
                // TODO accept a ProkRandom arg
                args: [],
                expr: macro return 0
            }),
            pos: Context.currentPos()
        };

        fields.push(generateField);

        return fields;
    }
}