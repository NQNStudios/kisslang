package kiss;

#if macro
import haxe.macro.Expr;
import haxe.macro.Context;
import haxe.macro.PositionTools;
import sys.io.File;
#end
import kiss.Kiss;
import kiss.cloner.Cloner;

// Commands handlers accept a Dynamic argument because when fork() happens
// (1) the calling context can no longer assume the instance it constructed is the instance running the command.
// (2) I don't know how to put a generic parameter <T extends EmbeddedScript> on the Command typedef.
typedef Command = (Dynamic) -> Void;

/**
    Utility class for making statically typed, debuggable, embedded Kiss-based DSLs.
    Basic examples:
        kiss/src/test/cases/DSLTestCase.hx
        projects/aoc/year2020/BootCode.hx
**/
class EmbeddedScript {
    public var instructionPointer(default, null) = 0;

    var running = false;

    private var instructions:Array<Command> = null;
    private var breakPoints:Map<Int, () -> Bool> = [];
    private var onBreak:Command = null;

    public function setBreakHandler(handler:Command) {
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
        classFields = classFields.concat(Kiss.build(dslFile, k));

        Reader.readAndProcess(Stream.fromFile(scriptFile), k, (nextExp) -> {
            var fields = Kiss.readerExpToFields(nextExp, k, false);
            if (fields.length > 0) {
                classFields = classFields.concat(fields);
            } else {
                // In a DSL script, anything that's not a field definition is a command line
                commandList.push(macro function(self) {
                    ${Kiss.readerExpToHaxeExpr(nextExp, k)};
                });
            }
            // This return is essential for type unification of concat() and push() above... ugh.
            return;
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
            name: "step",
            access: [APublic],
            kind: FFun({
                ret: null,
                args: [],
                expr: macro {
                    if (instructions == null)
                        resetInstructions();
                    instructions[instructionPointer](this);
                    ++instructionPointer;
                    if (breakPoints.exists(instructionPointer) && breakPoints[instructionPointer]()) {
                        running = false;
                        if (onBreak != null) {
                            onBreak(this);
                        }
                    } else if (instructionPointer < 0 || instructionPointer >= instructions.length) {
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

        // Fork the script down two or more different commands.
        classFields.push({
            pos: PositionTools.make({
                min: 0,
                max: File.getContent(scriptFile).length,
                file: scriptFile
            }),
            name: "fork",
            access: [APublic],
            kind: FFun({
                ret: Helpers.parseComplexType("Array<EmbeddedScript>", null),
                args: [
                    {
                        type: Helpers.parseComplexType("Array<Command>", null),
                        name: "commands"
                    }
                ],
                expr: macro {
                    if (instructions == null)
                        resetInstructions();
                    return [
                        for (command in commands) {
                            // a fork needs to be a thorough copy that includes all of the EmbeddedScript subclass's
                            // fields, otherwise DSL state will be lost when forking, which is unacceptable
                            var fork = new kiss.cloner.Cloner().clone(this);
                            fork.instructions[instructionPointer] = command;
                            trace(fork.breakPoints);
                            trace('running a fork from ' + Std.string(instructionPointer + 1));
                            fork.run();
                            trace("fork finished");
                            fork;
                        }
                    ];
                }
            })
        });
        return classFields;
    }
    #end
}
