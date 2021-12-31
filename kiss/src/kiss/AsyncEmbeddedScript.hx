package kiss;

#if macro
import haxe.macro.Expr;
import haxe.macro.Context;
import haxe.macro.PositionTools;
import sys.io.File;
import haxe.io.Path;
using kiss.Helpers;
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
    private var breakPoints:Map<Int, () -> Bool> = [];
    private var onBreak:AsyncCommand = null;
    private var lastInstructionPointer = -1;
    private var labels:Map<String,Int> = [];
    private var noSkipInstructions:Map<Int,Bool> = [];

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

    private function resetInstructions() {}

    public function instructionCount() { 
        if (instructions == null)
            resetInstructions();
        return instructions.length;
    }

    private function runInstruction(instructionPointer:Int, withBreakPoints = true) {
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

    public function run(withBreakPoints = true) {
        runInstruction(0, withBreakPoints);
    }

    private function skipToInstruction(ip:Int) {
        var lastCC = ()->runInstruction(ip);
        // chain together the unskippable instructions prior to running the requested ip
        var noSkipList = [];
        for (cIdx in lastInstructionPointer+1... ip) {
            if (noSkipInstructions.exists(cIdx)) {
                noSkipList.push(cIdx);
            }
        }
        if (noSkipList.length > 0) {
            var cc = null;
            cc = ()->{
                if (noSkipList.length == 0) {
                    lastCC();
                } else {
                    var inst = noSkipList.shift();
                    lastInstructionPointer = inst;
                    instructions[inst](this, cc);
                }
            };
            cc();
        } else {
            lastCC();
        }

        // TODO remember whether breakpoints were requested
    }

    public function skipToNextLabel() {
        var labelPointers = [for (ip in labels) ip];
        labelPointers.sort(Reflect.compare);
        for (ip in labelPointers) {
            if (ip > lastInstructionPointer) {
                skipToInstruction(ip);
                break;
            }
        }
    }

    public function skipToLabel(name:String) {
        var ip = labels[name];
        if (lastInstructionPointer > ip) {
            throw "Rewinding AsyncEmbeddedScript is not implemented";
        }
        skipToInstruction(ip);
    }

    public function labelRunners():Map<String,Void->Void> {
        return [for (label => ip in labels) label => () -> skipToInstruction(ip)];
    }

    #if macro
    public static function build(dslHaxelib:String, dslFile:String, scriptFile:String):Array<Field> {
        // trace('AsyncEmbeddedScript.build $dslHaxelib $dslFile $scriptFile');
        var k = Kiss.defaultKissState();

        k.file = scriptFile;
        var classPath = Context.getPosInfos(Context.currentPos()).file;
        var loadingDirectory = Path.directory(classPath);
        var classFields = []; // Kiss.build() will already include Context.getBuildFields()

        var commandList:Array<Expr> = [];
        var labelsList:Array<Expr> = [];
        var noSkipList:Array<Expr> = [];

        k.macros["label"] = (wholeExp:ReaderExp, args:Array<ReaderExp>, k:KissState) -> {
            wholeExp.checkNumArgs(1, 1, '(label <label>)');
            var label = Prelude.symbolNameValue(args[0]);
            labelsList.push(macro labels[$v{label}] = $v{commandList.length});
            
            wholeExp.expBuilder().callSymbol("cc", []);
        };

        k.macros["noSkip"] = (wholeExp:ReaderExp, args:Array<ReaderExp>, k:KissState) -> {
            wholeExp.checkNumArgs(1, null, '(noSkip <body...>)');
            noSkipList.push(macro noSkipInstructions[$v{commandList.length}] = true);

            wholeExp.expBuilder().begin(args);
        }

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
                expr = macro { Prelude.print($v{exprString}); $expr; };
                #end
                if (expr != null) {
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
            access: [APrivate, AOverride],
            kind: FFun({
                ret: null,
                args: [],
                expr: macro {
                    this.instructions = [$a{commandList}];
                    $b{labelsList};
                    $b{noSkipList};
                }
            })
        });

        return classFields;
    }
    #end
}
