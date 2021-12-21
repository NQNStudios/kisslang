package kiss;

#if macro
import haxe.macro.Expr;
import haxe.macro.Context;
import haxe.macro.PositionTools;
import sys.io.File;
import haxe.io.Path;
#end
import kiss.Kiss;
import kiss.Prelude;
import kiss.cloner.Cloner;

typedef Continuation = () -> Void;
typedef AsyncCommand = (AsyncEmbeddedScript, Continuation) -> Void;

/**
    Utility class for making statically typed, debuggable, ASYNC-BASED embedded Kiss-based DSLs.
    Examples are in the hollywoo project.
**/
class AsyncEmbeddedScript {
    private var instructions:Array<AsyncCommand> = null;
    public var instructionPointersByLine:Map<Int,Int> = [];
    private var breakPoints:Map<Int, () -> Bool> = [];
    private var onBreak:AsyncCommand = null;
    public var lastInstructionPointer = 0;

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
    public static function build(dslHaxelib:String, dslFile:String, scriptFile:String):Array<Field> {
        // trace('AsyncEmbeddedScript.build $dslHaxelib $dslFile $scriptFile');
        var k = Kiss.defaultKissState();

        k.file = scriptFile;
        var classPath = Context.getPosInfos(Context.currentPos()).file;
        var loadingDirectory = Path.directory(classPath);
        var classFields = []; // Kiss.build() will already include Context.getBuildFields()

        var commandList:Array<Expr> = [];
        var mappedIndexList:Array<Expr> = [];

        if (dslHaxelib.length > 0) {
            dslFile = Path.join([Prelude.libPath(dslHaxelib), dslFile]);
        }

        // This brings in the DSL's functions and global variables.
        // As a side-effect, it also fills the KissState with the macros and reader macros that make the DSL syntax
        classFields = classFields.concat(Kiss.build(dslFile, k));

        scriptFile = Path.join([loadingDirectory, scriptFile]);
        k.fieldList = [];
        Kiss._try(() -> {
            Reader.readAndProcess(Stream.fromFile(scriptFile), k, (nextExp) -> {
                var exprString = Reader.toString(nextExp.def);
                var expr = Kiss.readerExpToHaxeExpr(nextExp, k);

                #if debug
                expr = macro { trace($v{exprString}); $expr; };
                #end

                if (expr != null) {
                    mappedIndexList.push(macro instructionPointersByLine[$v{nextExp.pos.line}] = $v{commandList.length});

                    commandList.push(macro function(self, cc) {
                        $expr;
                    });
                }

                // This return is essential for type unification of concat() and push() above... ugh.
                return;
            });
            null;
        });

        classFields = classFields.concat(k.fieldList);

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
                expr: macro {
                    this.instructions = [$a{commandList}];
                    $b{mappedIndexList};
                }
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
                    lastInstructionPointer = instructionPointer;
                    if (instructions == null)
                        resetInstructions();
                    if (withBreakPoints && breakPoints.exists(instructionPointer) && breakPoints[instructionPointer]()) {
                        if (onBreak != null) {
                            onBreak(this, () -> runInstruction(instructionPointer, false));
                        }
                    }
                    var continuation = if (instructionPointer < instructions.length - 1) {
                        () -> {
                            // runInstruction may be called externally to skip through the script.
                            // When this happens, make sure other scheduled continuations are canceled
                            // by verifying that lastInstructionPointer hasn't changed
                            if (lastInstructionPointer == instructionPointer) {
                                runInstruction(instructionPointer + 1);
                            }
                        };
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
