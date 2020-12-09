package kiss;

#if macro
import haxe.macro.Expr;
import haxe.macro.Context;
import haxe.macro.PositionTools;
import sys.io.File;
#end
import kiss.Kiss;

typedef Command = () -> Void;

/**
    Utility class for making statically typed, debuggable, embedded Kiss-based DSLs.
    Basic examples:
        kiss/src/test/cases/DSLTestCase.hx
        projects/aoc/year2020/BootCode.hx
**/
class EmbeddedScript {
    var instructionPointer = 0;
    var running = false;

    private var instructions:Array<Command> = null;
    private var breakPoints:Map<Int, () -> Bool> = [];
    private var onBreak:() -> Void = null;

    public function setBreakHandler(handler:() -> Void) {
        onBreak = handler;
    }

    public function addBreakPoint(instruction:Int, ?condition:() -> Bool) {
        if (condition == null) {
            condition = () -> true;
        }
        breakPoints[instruction] = condition;
    }

    public function removeBreakPoint(instruction:Int) {
        breakPoints.remove(instruction);
    }

    public function new() {}

    #if macro
    public static function build(dslFile:String, scriptFile:String):Array<Field> {
        var k = Kiss.defaultKissState();

        var classFields = Context.getBuildFields();

        var commandList:Array<Expr> = [];

        // This brings in the DSL's functions and global variables.
        // As a side-effect, it also fills the KissState with the macros and reader macros that make the DSL syntax
        for (field in Kiss.build(dslFile, k)) {
            classFields.push(field);
        }

        Reader.readAndProcess(new Stream(scriptFile), k.readTable, (nextExp) -> {
            var field = Kiss.readerExpToField(nextExp, k, false);
            if (field != null) {
                classFields.push(field);
            } else {
                // In a DSL script, anything that's not a field definition is a command line
                commandList.push(macro function() {
                    ${Kiss.readerExpToHaxeExpr(nextExp, k)};
                });
            }
            // TODO also allow label setting and multiple commands coming from the same expr?
            // Multiple things could come from the same expr by returning begin, or a call to a function that does more stuff
            // i.e. knot declarations need to end the previous knot, and BELOW that set a label for the new one, then increment the read count
            // TODO test await
        });

        classFields.push({
            pos: PositionTools.make({
                min: 0,
                max: File.getContent(scriptFile).length,
                file: scriptFile
            }),
            name: "instructions",
            access: [APrivate],
            kind: FFun({
                ret: Helpers.parseComplexType("Array<Command>", null),
                args: [],
                expr: macro return [$a{commandList}]
            })
        });

        classFields.push({
            pos: PositionTools.make({
                min: 0,
                max: File.getContent(scriptFile).length,
                file: scriptFile
            }),
            name: "step",
            access: [APublic],
            kind: FFun({
                ret: null,
                args: [],
                expr: macro {
                    instructions()[instructionPointer]();
                    ++instructionPointer;
                    if (breakPoints.exists(instructionPointer) && breakPoints[instructionPointer]()) {
                        running = false;
                        if (onBreak != null) {
                            onBreak();
                        }
                    } else if (instructionPointer >= instructions().length) {
                        running = false;
                    }
                }
            })
        });

        classFields.push({
            pos: PositionTools.make({
                min: 0,
                max: File.getContent(scriptFile).length,
                file: scriptFile
            }),
            name: "run",
            access: [APublic],
            kind: FFun({
                ret: null,
                args: [],
                expr: macro {
                    running = true;
                    while (running) {
                        step();
                    }
                }
            })
        });

        // Start a process that needs to take control of the main thread, and will call back to resume the script
        classFields.push({
            pos: PositionTools.make({
                min: 0,
                max: File.getContent(scriptFile).length,
                file: scriptFile
            }),
            name: "await",
            access: [APublic],
            kind: FFun({
                ret: null,
                args: [
                    {
                        type: Helpers.parseComplexType("(()->Void)->Void", null),
                        name: "c"
                    }
                ],
                expr: macro {
                    running = false;
                    c(run);
                }
            })
        });

        return classFields;
    }
    #end
}
