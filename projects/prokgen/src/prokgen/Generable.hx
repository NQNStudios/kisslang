package prokgen;

import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Type;

using haxe.macro.ComplexTypeTools;
using haxe.macro.TypeTools;

using tink.MacroApi;
using tink.core.Outcome;

class Generable {
    public static macro function build():Array<Field> {
        var generatorClass:Ref<ClassType> = null;
        
        function classIsGenerator(cls:ClassType) {
            if (cls == null) return false;
            if (cls.name == "Generator" && cls.pack.join(".") == "prokgen") {
                return true;
            }
            if (cls.superClass != null) {
                var scls = cls.superClass.t.get();
                if (classIsGenerator(scls)) return true;
            }
            for (iface in cls.interfaces) {
                var ref = iface.t;
                generatorClass = ref;
                var icls = ref.get();
                if (classIsGenerator(icls)) return true;
            }
            return false;
        }

        function typeIsGenerator(t:Type) {
            return classIsGenerator(t.getClass());
        }

        function typeFromField(c:ComplexType, e:Expr) {
            if (c != null) return c.toType().sure();
            return e.typeof().sure();
        }

        function checkFieldIsGenerator(name:String, c:ComplexType, e:Expr, generators:Map<String, Type>) {
            var t = typeFromField(c, e);
            if (typeIsGenerator(t)) {
                generators[name] = t;
            }
        }

        var fields = Context.getBuildFields();

        var instanceFields:Map<String, Type> = [];
        var generatorFields:Map<String, Type> = [];
        var generatorsByFieldType:Map<Type, String> = [];
        var hasGenScore = false;

        var genTypes:Array<ComplexType> = [];

        for (field in fields) {
            switch (field) {
                // Find all the fields that are generators and map them by type generated
                case {
                    name: name,
                    doc: _,
                    access: access,
                    kind: FVar(type, expr),
                    pos: _,
                    meta: _
                } if (access.indexOf(AStatic) != -1):
                    checkFieldIsGenerator(name, type, expr, generatorFields);
                // find all fields that are uninitialized, non-generator instance variables
                case {
                    name: name,
                    doc: _,
                    access: access,
                    kind: FVar(type, null),
                    pos: _,
                    meta: _
                } if (access.indexOf(AStatic) == -1):
                    instanceFields[name] = type.toType().sure();
                // make sure genScore() is defined and returns Float
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

        var useLines = [for (generator => _ in generatorFields) {
            macro $i{generator}.use(r);
        }];

        var genLines = [];
        for (name => type in instanceFields) {
            var generatorName = if (generatorsByFieldType.exists(type)) {
                generatorsByFieldType[type];
            } else {
                for (genName => genType in generatorFields) {
                    var desiredType = TInst(generatorClass, [type]);
                    if (genType.unify(desiredType))
                        generatorsByFieldType[type] = genName;
                }
                generatorsByFieldType[type];
            };
            if (generatorName == null) {
                throw 'No generator found for $name';
            }
            
            genLines.push(macro $i{name} = $i{generatorName}.makeRandom());
        }

        // TODO when generating fields, make sure they are handled alphabetically so seeded generation is deterministic, not dependent on Map iterator order
        var generateSpecimenField = {
            name: "_generate",
            access: [APrivate],
            kind: FFun({
                ret: null,
                args: [],
                expr: macro $b{genLines}
            }),
            pos: Context.getLocalClass().get().pos
        }
        
        // TODO create a population and evolve it
        var generateField = {
            name: "generate",
            access: [AStatic, APublic],
            kind: FFun({
                ret: null,
                // TODO accept a ProkRandom arg
                args: [{
                    name: "r"
                }],
                expr: macro {
                    var inst = Type.createEmptyInstance(HighNumbers);
                    $b{useLines}
                    inst._generate();
                    return inst;
                }
            }),
            pos: Context.getLocalClass().get().pos
        };

        fields.push(generateSpecimenField);
        fields.push(generateField);

        return fields;
    }
}