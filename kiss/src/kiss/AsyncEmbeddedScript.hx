package kiss;

#if macro
import haxe.macro.Expr;
import haxe.macro.Context;
import haxe.macro.PositionTools;
import sys.io.File;
import haxe.io.Path;
#end
import kiss.Kiss;
import kiss.cloner.Cloner;


typedef Continuation = () -> Void;
typedef AsyncCommand = (AsyncEmbeddedScript, Continuation) -> Void;

/**
    Utility class for making statically typed, debuggable, ASYNC-BASED embedded Kiss-based DSLs.
    Examples are in the hollywoo project.
**/
class AsyncEmbeddedScript {
    private var instructions:Array<AsyncCommand> = null;
    private var breakPoints:Map<Int, () -> Bool> = [];
    private var onBreak:AsyncCommand = null;

    public function setBreakHandler(handler:AsyncCommand) {
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

        var classPath = Context.getPosInfos(Context.currentPos()).file;
        var loadingDirectory = Path.directory(classPath);
        var classFields = Context.getBuildFields();

        var commandList:Array<Expr> = [];

        // This brings in the DSL's functions and global variables.
        // As a side-effect, it also fills the KissState with the macros and reader macros that make the DSL syntax
        classFields = classFields.concat(Kiss.build(dslFile, k));
        scriptFile = Path.join([loadingDirectory, scriptFile]);

        Reader.readAndProcess(Stream.fromFile(scriptFile), k, (nextExp) -> {
            var expr = Kiss.readerExpToHaxeExpr(nextExp, k);

            if (expr != null) {
                commandList.push(macro function(self, cc) {
                    $expr;
                });
            }

            // This return is essential for type unification of concat() and push() above... ugh.
            return;
        });

        classFields.push({
            pos: PositionTools.make({
                min: 0,
                max: File.getContent(scriptFile).length,
                file: scriptFile
            }),
            name: "resetInstructions",
            access: [APrivate],
            kind: FFun({
                ret: null,
                args: [],
                expr: macro this.instructions = [$a{commandList}]
            })
        });

        classFields.push({
            pos: PositionTools.make({
                min: 0,
                max: File.getContent(scriptFile).length,
                file: scriptFile
            }),
            name: "instructionCount",
            access: [APublic],
            kind: FFun({
                ret: null,
                args: [],
                expr: macro {
                    if (instructions == null)
                        resetInstructions();
                    return instructions.length;
                }
            })
        });

        classFields.push({
            pos: PositionTools.make({
                min: 0,
                max: File.getContent(scriptFile).length,
                file: scriptFile
            }),
            name: "runInstruction",
            access: [APublic],
            kind: FFun({
                ret: null,
                args: [
                    {name: "instructionPointer"},
                    {
                        name: "withBreakPoints",
                        value: macro true
                    }
                ],
                expr: macro {
                    if (instructions == null)
                        resetInstructions();
                    if (withBreakPoints && breakPoints.exists(instructionPointer) && breakPoints[instructionPointer]()) {
                        if (onBreak != null) {
                            onBreak(this, () -> runInstruction(instructionPointer, false));
                        }
                    }
                    var continuation = if (instructionPointer < instructions.length - 1) {
                        () -> runInstruction(instructionPointer + 1);
                    } else {
                        () -> {};
                    }
                    instructions[instructionPointer](this, continuation);
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
                    runInstruction(0);
                }
            })
        });

       return classFields;
    }
    #end
}
