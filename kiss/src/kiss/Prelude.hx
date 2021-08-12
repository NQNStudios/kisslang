package kiss;

using Std;

import kiss.ReaderExp;
import haxe.ds.Either;
import haxe.Constraints;
#if (!macro && hxnodejs)
import js.node.ChildProcess;
import js.node.Buffer;
#elseif sys
import sys.io.Process;
#end
#if (sys || hxnodejs)
import sys.FileSystem;
#end
#if python
import python.lib.subprocess.Popen;
import python.Bytearray;
#end
import uuid.Uuid;
import haxe.io.Path;

using StringTools;
using uuid.Uuid;

/** What functions that process Lists should do when there are more elements than expected **/
enum ExtraElementHandling {
    Keep; // Keep the extra elements
    Drop; // Drop the extra elements
    Throw; // Throw an error
}

class Prelude {
    static function stringOrFloat(d:Dynamic):Either<String, Float> {
        return switch (Type.typeof(d)) {
            case TInt | TFloat: Right(0.0 + d);
            default:
                if (Std.isOfType(d, String)) {
                    Left(d);
                } else {
                    throw 'cannot use $d in multiplication';
                };
        };
    }

    // Kiss arithmetic will incur overhead because of these switch statements, but the results will not be platform-dependent
    static function _add(values:Array<Dynamic>):Dynamic {
        var sum:Dynamic = values[0];
        for (value in values.slice(1))
            sum += value;
        return sum;
    }

    public static var add:Function = Reflect.makeVarArgs(_add);

    static function _subtract(values:Array<Dynamic>):Dynamic {
        var difference:Float = values[0];
        for (value in values.slice(1))
            difference -= value;
        return difference;
    }

    public static var subtract:Function = Reflect.makeVarArgs(_subtract);

    static function _multiply2(a:Dynamic, b:Dynamic):Dynamic {
        return switch ([stringOrFloat(a), stringOrFloat(b)]) {
            case [Right(f), Right(f2)]:
                f * f2;
            case [Left(a), Left(b)]:
                throw 'cannot multiply strings "$a" and "$b"';
            case [Right(i), Left(s)] | [Left(s), Right(i)] if (i % 1 == 0):
                var result = "";
                for (_ in 0...Math.floor(i)) {
                    result += s;
                }
                result;
            default:
                throw 'cannot multiply $a and $b';
        };
    }

    static function _multiply(values:Array<Dynamic>):Dynamic {
        var product = values[0];
        for (value in values.slice(1))
            product = _multiply2(product, value);
        return product;
    }

    public static var multiply:Function = Reflect.makeVarArgs(_multiply);

    static function _divide(values:Array<Dynamic>):Dynamic {
        var quotient:Float = values[0];
        for (value in values.slice(1))
            quotient /= value;
        return quotient;
    }

    public static var divide:Function = Reflect.makeVarArgs(_divide);

    public static function mod(top:Dynamic, bottom:Dynamic):Dynamic {
        return top % bottom;
    }

    public static function pow(base:Dynamic, exponent:Dynamic):Dynamic {
        return Math.pow(base, exponent);
    }

    static function _min(values:Array<Dynamic>):Dynamic {
        var min = values[0];
        for (value in values.slice(1))
            min = Math.min(min, value);
        return min;
    }

    public static var min:Function = Reflect.makeVarArgs(_min);

    static function _max(values:Array<Dynamic>):Dynamic {
        var max = values[0];
        for (value in values.slice(1))
            max = Math.max(max, value);
        return max;
    }

    public static var max:Function = Reflect.makeVarArgs(_max);

    static function _comparison(op:String, values:Array<Dynamic>):Bool {
        for (idx in 1...values.length) {
            var a:Dynamic = values[idx - 1];
            var b:Dynamic = values[idx];
            var check = switch (op) {
                case ">": a > b;
                case ">=": a >= b;
                case "<": a < b;
                case "<=": a <= b;
                case "==": a == b;
                default: throw 'Unreachable case';
            }
            if (!check)
                return false;
        }
        return true;
    }

    public static var greaterThan:Function = Reflect.makeVarArgs(_comparison.bind(">"));
    public static var greaterEqual:Function = Reflect.makeVarArgs(_comparison.bind(">="));
    public static var lessThan:Function = Reflect.makeVarArgs(_comparison.bind("<"));
    public static var lesserEqual:Function = Reflect.makeVarArgs(_comparison.bind("<="));
    public static var areEqual:Function = Reflect.makeVarArgs(_comparison.bind("=="));

    public static function sort<T>(a:Array<T>, ?comp:(T, T) -> Int):kiss.List<T> {
        if (comp == null)
            comp = Reflect.compare;
        var sorted = a.copy();
        sorted.sort(comp);
        return sorted;
    }

    public static function groups<T>(a:Array<T>, size, extraHandling = Drop):kiss.List<kiss.List<T>> {
        var numFullGroups = Math.floor(a.length / size);
        var fullGroups = [
            for (num in 0...numFullGroups) {
                var start = num * size;
                var end = (num + 1) * size;
                a.slice(start, end);
            }
        ];
        if (a.length % size != 0) {
            switch (extraHandling) {
                case Throw:
                    throw 'groups was given a non-divisible number of elements: $a, $size';
                case Keep:
                    fullGroups.push(a.slice(numFullGroups * size));
                case Drop:
            }
        }

        return fullGroups;
    }

    static function _concat(arrays:Array<Dynamic>):kiss.List<Dynamic> {
        var arr:Array<Dynamic> = arrays[0];
        for (nextArr in arrays.slice(1)) {
            arr = arr.concat(nextArr);
        }
        return arr;
    }

    public static var concat:Function = Reflect.makeVarArgs(_concat);

    static function _zip(iterables:Array<Dynamic>, extraHandling:ExtraElementHandling):kiss.List<kiss.List<Dynamic>> {
        var lists = [];
        var iterators = [for (iterable in iterables) iterable.iterator()];

        while (true) {
            var zipped:Array<Dynamic> = [];

            var someNonNull = false;
            for (it in iterators) {
                switch (extraHandling) {
                    case Keep:
                        zipped.push(
                            if (it.hasNext()) {
                                someNonNull = true;
                                it.next();
                            } else {
                                null;
                            });
                    default:
                        if (it.hasNext())
                            zipped.push(it.next());
                }
            }

            switch (extraHandling) {
                case _ if (zipped.length == 0):
                    break;
                case Keep if (!someNonNull):
                    break;
                case Drop if (zipped.length != iterators.length):
                    break;
                case Throw if (zipped.length != iterators.length):
                    throw 'zip${extraHandling} was given iterables of mis-matched size: $iterables';
                default:
            }

            lists.push(zipped);
        }
        return lists;
    }

    public static var zipKeep:Function = Reflect.makeVarArgs(_zip.bind(_, Keep));
    public static var zipDrop:Function = Reflect.makeVarArgs(_zip.bind(_, Drop));
    public static var zipThrow:Function = Reflect.makeVarArgs(_zip.bind(_, Throw));

    public static function enumerate(l:kiss.List<Dynamic>, startingIdx = 0):kiss.List<kiss.List<Dynamic>> {
        return zipThrow(range(startingIdx, startingIdx + l.length, 1), l);
    }

    public static function pairs(l:kiss.List<Dynamic>, loopAround = false):kiss.List<kiss.List<Dynamic>> {
        var l1 = l.slice(0, l.length - 1);
        var l2 = l.slice(1, l.length);
        if (loopAround) {
            l1.push(l[-1]);
            l2.unshift(l[0]);
        }
        return zipThrow(l1, l2);
    }

    public static function reversed<T>(l:kiss.List<T>):kiss.List<T> {
        var c = l.copy();
        c.reverse();
        return c;
    }

    // Ranges with a min, exclusive max, and step size, just like Python.
    public static function range(min, max, step):Iterator<Int>
        & Iterable<Int>

    {
        if (step <= 0 || max < min)
            throw "(range...) can only count up";
        var count = min;
        var iterator = {
            next: () -> {
                var oldCount = count;
                count += step;
                oldCount;
            },
            hasNext: () -> {
                count < max;
            }
        };

        return {
            iterator: () -> iterator,
            next: () -> iterator.next(),
            hasNext: () -> iterator.hasNext()
        };
    }
    static function _joinPath(parts:Array<Dynamic>) {
        return Path.join([for (part in parts) cast(part, String)]);
    }

    public static var joinPath:Function = Reflect.makeVarArgs(_joinPath);

    public static dynamic function truthy<T>(v:T) {
        return switch (Type.typeof(v)) {
            case TNull: false;
            case TBool: cast(v, Bool);
            default:
                // Empty strings are falsy
                if (v.isOfType(String)) {
                    var str:String = cast v;
                    str.length > 0;
                } else if (v.isOfType(Array)) {
                    // Empty lists are falsy
                    var lst:Array<Dynamic> = cast v;
                    lst.length > 0;
                } else {
                    // Any other value is true by default
                    true;
                };
        }
    }

    public static function chooseRandom<T>(l:kiss.List<T>) {
        return l[Std.random(l.length)];
    }

    // Based on: http://old.haxe.org/doc/snip/memoize
    public static function memoize(func:Function, ?caller:Dynamic):Function {
        var argMap = new Map<String, Dynamic>();
        var f = (args:Array<Dynamic>) -> {
            var argString = args.join('|');
            return if (argMap.exists(argString)) {
                argMap[argString];
            } else {
                var ret = Reflect.callMethod(caller, func, args);
                argMap[argString] = ret;
                ret;
            };
        };
        f = Reflect.makeVarArgs(f);
        return f;
    }

    public static dynamic function printStr(s:String) {
        #if (sys || hxnodejs)
        Sys.println(s);
        #else
        trace(s);
        #end
    }

    public static function print<T>(v:T, label = ""):T {
        var toPrint = label;
        if (label.length > 0) {
            toPrint += ": ";
        }
        toPrint += Std.string(v);
        printStr(toPrint);
        return v;
    }

    public static function symbolNameValue(s:ReaderExp):String {
        return switch (s.def) {
            case Symbol(name): name;
            default: throw 'expected $s to be a plain symbol';
        };
    }

    // ReaderExp helpers for macros:
    public static function symbol(?name:String):ReaderExpDef {
        if (name == null)
            name = '_${Uuid.v4().toShort()}';
        return Symbol(name);
    }

    public static function symbolName(s:ReaderExp):ReaderExpDef {
        return switch (s.def) {
            case Symbol(name): StrExp(name);
            default: throw 'expected $s to be a plain symbol';
        };
    }

    public static function expList(s:ReaderExp):kiss.List<ReaderExp> {
        return switch (s.def) {
            case ListExp(exps):
                exps;
            default: throw 'expected $s to be a list expression';
        }
    }

    #if sys
    private static var kissProcess:Process = null;
    #end

    public static function walkDirectory(basePath, directory, processFile:(String) -> Void, processSubdirectory:(String) -> Void) {
        #if (sys || hxnodejs)
        for (fileOrFolder in FileSystem.readDirectory(joinPath(basePath, directory))) {
            switch (fileOrFolder) {
                case folder if (FileSystem.isDirectory(joinPath(basePath, directory, folder))):
                    var subdirectory = joinPath(directory, folder);
                    processSubdirectory(subdirectory);
                    walkDirectory(basePath, subdirectory, processFile, processSubdirectory);
                case file:
                    processFile(joinPath(directory, file));
            }
        }
        #else
        throw "Can't walk a directory on this target.";
        #end
    }

    /**
     * On Sys targets and nodejs, Kiss can be converted to hscript at runtime
     * NOTE on non-nodejs targets, after the first time calling this function,
     * it will be much faster -- but things like reader macros will get stuck in the KissState, which you may not intend
     * NOTE on non-nodejs sys targets, newlines in raw strings will be stripped away.
     * So don't use raw string literals in Kiss you want parsed and evaluated at runtime.
     */
    public static function convertToHScript(kissStr:String):String {
        #if (!macro && hxnodejs)
        var hscript = try {
            assertProcess("haxelib", ["run", "kiss", "convert", "--all", "--hscript"], kissStr.split('\n'));
        } catch (e) {
            throw 'failed to convert ${kissStr} to hscript:\n$e';
        }
        if (hscript.startsWith(">>> ")) {
            hscript = hscript.substr(4);
        }
        return hscript.trim();
        #elseif (!macro && python)
        var hscript = try {
            assertProcess("haxelib", ["run", "kiss", "convert", "--hscript"], [kissStr.replace('\n', ' ')], false);
        } catch (e) {
            throw 'failed to convert ${kissStr} to hscript:\n$e';
        }
        if (hscript.startsWith(">>> ")) {
            hscript = hscript.substr(4);
        }
        return hscript.trim();
        #elseif sys
        if (kissProcess == null)
            kissProcess = new Process("haxelib", ["run", "kiss", "convert", "--hscript"]);

        kissProcess.stdin.writeString('${kissStr.replace("\n", " ")}\n');

        try {
            var output = kissProcess.stdout.readLine();
            if (output.startsWith(">>> ")) {
                output = output.substr(4);
            }
            return output;
        } catch (e) {
            var error = kissProcess.stderr.readAll().toString();
            throw 'failed to convert ${kissStr} to hscript: ${error}';
        }
        #else
        throw "Can't convert Kiss to HScript on this target.";
        #end
    }

    public static function assertProcess(command:String, args:Array<String>, ?inputLines:Array<String>, fullProcess = true):String {
        #if test
        Prelude.print('running $command $args $inputLines');
        #end
        if (inputLines != null) {
            for (line in inputLines) {
                if (line.indexOf("\n") != -1) {
                    throw 'newline is not allowed in the middle of a process input line: "${line.replace("\n", "\\n")}"';
                }
            }
        }
        #if python
        // on Python, after new Process() is called, writing inputLines to stdin becomes impossible. Use python.lib.subprocess instead
        var p = Popen.create([command].concat(args), {
            stdin: -1, // -1 represents PIPE which allows communication
            stdout: -1,
            stderr: -1,
        });
        if (inputLines != null) {
            for (line in inputLines) {
                p.stdin.write(new Bytearray('$line\n', "utf-8"));
            }
        }

        if (fullProcess) {
            if (p.wait() == 0) {
                return p.stdout.readall().decode().trim();
            } else {
                throw 'process $command $args failed:\n${p.stdout.readall().decode().trim() + p.stderr.readall().decode().trim();}';
            }
        } else {
            // The haxe extern for FileIO.readline() says it's a string, but it's not, it's bytes!
            var bytes:Dynamic = p.stdout.readline();
            var s:String = bytes.decode();
            return s.trim();
        }
        #elseif sys
        var p = new Process(command, args);
        if (inputLines != null) {
            for (line in inputLines) {
                p.stdin.writeString('$line\n');
            }
        }
        if (fullProcess) {
            if (p.exitCode() == 0) {
                return p.stdout.readAll().toString().trim();
            } else {
                throw 'process $command $args failed:\n${p.stdout.readAll().toString().trim() + p.stderr.readAll().toString().trim()}';
            }
        } else {
            return p.stdout.readLine().toString().trim();
        }
        #elseif hxnodejs
        var p = if (inputLines != null) {
            ChildProcess.spawnSync(command, args, {input: inputLines.join("\n")});
        } else {
            ChildProcess.spawnSync(command, args);
        }
        switch (p.status) {
            case 0:
                var output:Buffer = p.stdout;
                return output.toString();
            default:
                var output:Buffer = p.stdout;
                var error:Buffer = p.stderr;
                throw 'process $command $args failed:\n${output.toString() + error.toString()}';
        }
        #else
        throw "Can't run a subprocess on this target.";
        #end
    }
}
