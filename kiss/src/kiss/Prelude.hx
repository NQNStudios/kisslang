package kiss;

using Std;

import kiss.ReaderExp;
import haxe.ds.Either;
import haxe.Constraints;
import haxe.DynamicAccess;
#if (!macro && hxnodejs)
import js.node.ChildProcess;
import js.node.Buffer;
#elseif sys
import sys.io.Process;
#end
#if (sys || hxnodejs)
import sys.FileSystem;
import sys.io.File;
#end
#if python
import python.lib.subprocess.Popen;
import python.Bytearray;
#end
import uuid.Uuid;
import haxe.io.Path;
import haxe.Json;
#if target.threaded
import sys.thread.Mutex;
#end
using StringTools;
using uuid.Uuid;

/** What functions that process Lists should do when there are more elements than expected **/
enum ExtraElementHandling {
    Keep; // Keep the extra elements
    Drop; // Drop the extra elements
    Throw; // Throw an error
}

enum KissTarget {
    Cpp;
    CSharp;
    Haxe;
    JavaScript;
    NodeJS;
    Python;
    Macro;
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

    static function _and(values:Array<Dynamic>):Dynamic {
        for (value in values) {
            if (!truthy(value)) {
                return false;
            }
        }
        return values[values.length - 1];
    }
    public static var and:Function = Reflect.makeVarArgs(_and);

    static function _or(values:Array<Dynamic>):Dynamic {
        for (value in values) {
            if (truthy(value)) {
                return value;
            }
        }
        return values[values.length-1];
    }
    public static var or:Function = Reflect.makeVarArgs(_or);

    static function makeVarArgsWithArrayCheck(f:Array<Dynamic>->Dynamic, name:String):Function {
        function fWithArrayCheck(args:Array<Dynamic>):Dynamic {
            if (args.length == 1 && args[0] is Array) {
                throw 'Array ${args[0]} was passed to variadic function $name. Use (apply $name args) instead';
            }
            return f(args);
        }
        return Reflect.makeVarArgs(fWithArrayCheck);
    }

    // Kiss arithmetic will incur overhead because of these switch statements, but the results will not be platform-dependent
    static function _add(values:Array<Dynamic>):Dynamic {
        var sum:Dynamic = values[0];
        for (value in values.slice(1))
            sum += value;
        return sum;
    }

    public static var add:Function = makeVarArgsWithArrayCheck(_add, "+");

    static function _subtract(values:Array<Dynamic>):Dynamic {
        var difference:Float = values[0];
        for (value in values.slice(1))
            difference -= value;
        return difference;
    }

    public static var subtract:Function = makeVarArgsWithArrayCheck(_subtract, "-");

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

    public static var multiply:Function = makeVarArgsWithArrayCheck(_multiply, "*");

    static function _divide(values:Array<Dynamic>):Dynamic {
        var quotient:Float = values[0];
        for (value in values.slice(1))
            quotient /= value;
        return quotient;
    }

    public static var divide:Function = makeVarArgsWithArrayCheck(_divide, "/");

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

    public static var min:Function = makeVarArgsWithArrayCheck(_min, "min");

    static function _max(values:Array<Dynamic>):Dynamic {
        var max = values[0];
        for (value in values.slice(1)) {
            max = Math.max(max, value);
        }
        return max;
    }

    public static var max:Function = makeVarArgsWithArrayCheck(_max, "max");

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

    public static var greaterThan:Function = makeVarArgsWithArrayCheck(_comparison.bind(">"), ">");
    public static var greaterEqual:Function = makeVarArgsWithArrayCheck(_comparison.bind(">="), ">=");
    public static var lessThan:Function = makeVarArgsWithArrayCheck(_comparison.bind("<"), "<");
    public static var lesserEqual:Function = makeVarArgsWithArrayCheck(_comparison.bind("<="), "<=");
    public static var areEqual:Function = makeVarArgsWithArrayCheck(_comparison.bind("=="), "=");

    // Like quickNths but for division. Support int and float output:
    private static function iFraction (num:Float, denom:Float) {
        return Std.int(num / denom);
    }
    public static var iHalf:Float->Int = iFraction.bind(_, 2);
    public static var iThird:Float->Int = iFraction.bind(_, 3);
    public static var iFourth:Float->Int = iFraction.bind(_, 4);
    public static var iFifth:Float->Int = iFraction.bind(_, 5);
    public static var iSixth:Float->Int = iFraction.bind(_, 6);
    public static var iSeventh:Float->Int = iFraction.bind(_, 7);
    public static var iEighth:Float->Int = iFraction.bind(_, 8);
    public static var iNinth:Float->Int = iFraction.bind(_, 9);
    public static var iTenth:Float->Int = iFraction.bind(_, 10);
    private static function fFraction (num:Float, denom:Float) {
        return num / denom;
    }
    public static var fHalf:Float->Float = fFraction.bind(_, 2);
    public static var fThird:Float->Float = fFraction.bind(_, 3);
    public static var fFourth:Float->Float = fFraction.bind(_, 4);
    public static var fFifth:Float->Float = fFraction.bind(_, 5);
    public static var fSixth:Float->Float = fFraction.bind(_, 6);
    public static var fSeventh:Float->Float = fFraction.bind(_, 7);
    public static var fEighth:Float->Float = fFraction.bind(_, 8);
    public static var fNinth:Float->Float = fFraction.bind(_, 9);
    public static var fTenth:Float->Float = fFraction.bind(_, 10);


    public static function sort<T>(a:Array<T>, ?comp:(T, T) -> Int):kiss.List<T> {
        if (comp == null)
            comp = Reflect.compare;
        var sorted = a.copy();
        sorted.sort(comp);
        return sorted;
    }

    public static function sortBy<T,U>(a:Array<T>, index:T->U, ?comp:(U, U) -> Int):kiss.List<T> {
        if (comp == null)
            comp = Reflect.compare;

        return sort(a, (v1, v2) -> {
            return comp(index(v1), index(v2));
        });
    }

    public static function groups<T>(a:Array<T>, size, extraHandling = Throw):kiss.List<kiss.List<T>> {
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

    static function _intersect(iterables:Array<Dynamic>):kiss.List<kiss.List<Dynamic>> {
        var iterators:Array<Iterator<Dynamic>> = [for (iterable in iterables) iterable.iterator()];

        var intersections:Array<Array<Dynamic>> = [for (elem in iterators.shift()) [elem]];
        
        for (iterator in iterators) {
            intersections = cast _concat([for (elem in iterator) [for (intersection in intersections) intersection.concat([elem])]]);
        }
        
        return intersections;
    }

    // Return an array of every N-dimensional intersection of elements in N iterables.
    // Callers should not rely on the order of the intersections
    public static var intersect:Function = Reflect.makeVarArgs(_intersect);

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

    public static function reverse<T>(l:kiss.List<T>):kiss.List<T> {
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

    public static function isNull<T>(v:T) {
        return switch (Type.typeof(v)) {
            case TNull: true;
            default: false;
        }
    }

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
    public static function memoize(func:Function, ?caller:Dynamic, ?jsonFile:String, ?jsonArgMap:Map<String, Dynamic>):Function {
        var argMap = if (jsonArgMap != null) {
            jsonArgMap;
        } else {
            new Map<String, Dynamic>();
        }
        var f = (args:Array<Dynamic>) -> {
            var argString = args.join('|');
            return if (argMap.exists(argString)) {
                argMap[argString];
            } else {
                var ret = Reflect.callMethod(caller, func, args);
                argMap[argString] = ret;
                #if (sys || hxnodejs)
                if (jsonFile != null) {
                    File.saveContent(jsonFile, Json.stringify(argMap));
                }
                #end
                ret;
            };
        };
        f = Reflect.makeVarArgs(f);
        return f;
    }

    #if (sys || hxnodejs)
    public static function fsMemoize(func:Function, funcName:String, cacheDirectory = "", ?caller:Dynamic):Function {
        var fileName = '${funcName}.memoized';
        if (cacheDirectory.length > 0) {
            FileSystem.createDirectory(cacheDirectory);
            fileName = '$cacheDirectory/$fileName';
        }
        if (!FileSystem.exists(fileName))
            File.saveContent(fileName, "{}");

        var pastResults:DynamicAccess<Dynamic> = Json.parse(File.getContent(fileName));
        var argMap:Map<String, Dynamic> = [for (key => value in pastResults) key => value];
        return memoize(func, caller, fileName, argMap);
    }
    #end

    public static function _printStr(s:String) {
        #if (sys || hxnodejs)
        Sys.println(s);
        #else
        trace(s);
        #end
    }

    #if (sys || hxnodejs)
    static var externLogFile = "externLog.txt";

    public static function _externPrintStr(s:String) {
        var logContent = try {
            File.getContent(externLogFile);
        } catch (e) {
            "";
        }
        File.saveContent(externLogFile, '${logContent}${s}\n');
    }
    #end

    public static var printStr:(String) -> Void = _printStr;

    public static function withLabel(v:Any, label = "") {
        var toPrint = label;
        if (label.length > 0) {
            toPrint += ": ";
        }
        toPrint += Std.string(v);
        return toPrint;
    }

    public static function print<T>(v:T, label = ""):T {
        var toPrint = withLabel(v, label);
        printStr(toPrint);
        return v;
    }

    public static function symbolNameValue(s:ReaderExp, allowTyped:Null<Bool> = false, allowMeta:Null<Bool> = false):String {
        return switch (s.def) {
            case Symbol(name): name;
            case TypedExp(_, innerExp) if (allowTyped): symbolNameValue(innerExp, false); // Meta must always precede type annotation
            case MetaExp(_, innerExp) if (allowMeta): symbolNameValue(innerExp, allowTyped, false); // TODO will more than one meta on the same expression be necessary?
            default: throw 'expected $s to be a plain symbol'; // TODO convert s def to print & modify this message to reflect allowTyped and allowMeta parameters
        };
    }

    public static function uuid() {
        return Uuid.v4().toShort();
    }

    // ReaderExp helpers for macros:
    public static function symbol(?name:String):ReaderExpDef {
        if (name == null)
            name = '_${Uuid.v4().toShort()}'; // TODO the underscore will make fields defined with gensym names all PRIVATE!
        return Symbol(name);
    }

    // TODO make this behavior DRY with symbolNameValue
    public static function symbolName(s:ReaderExp, allowTyped:Null<Bool> = false, allowMeta:Null<Bool> = false):ReaderExpDef {
        return switch (s.def) {
            case Symbol(name): StrExp(name);
            case TypedExp(_, innerExp) if (allowTyped): symbolName(innerExp, false); // Meta must always precede type annotation
            case MetaExp(_, innerExp) if (allowMeta): symbolName(innerExp, allowTyped, false); // TODO will more than one meta on the same expression be necessary?
            default: throw 'expected $s to be a plain symbol'; // TODO convert s def to print & modify this message to reflect allowTyped and allowMeta parameters;
        };
    }

    public static function expList(s:ReaderExp):kiss.List<ReaderExp> {
        return switch (s.def) {
            case ListExp(exps):
                exps;
            default: throw 'expected $s to be a list expression';
        };
    }
    
    public static function isListExp(s:ReaderExp):Bool {
        return switch (s.def) {
            case ListExp(exps):
                true;
            default:
                false;
        };
    }

    #if sys
    private static var kissProcess:Process = null;
    #end

    public static function walkDirectory(basePath, directory, processFile:(String) -> Void, ?processFolderBefore:(String) -> Void,
            ?processFolderAfter:(String) -> Void) {
        #if (sys || hxnodejs)
        for (fileOrFolder in FileSystem.readDirectory(joinPath(basePath, directory))) {
            switch (fileOrFolder) {
                case folder if (FileSystem.isDirectory(joinPath(basePath, directory, folder))):
                    var subdirectory = joinPath(directory, folder);
                    if (processFolderBefore != null) {
                        processFolderBefore(subdirectory);
                    }
                    walkDirectory(basePath, subdirectory, processFile, processFolderBefore, processFolderAfter);
                    if (processFolderAfter != null) {
                        processFolderAfter(subdirectory);
                    }
                case file:
                    processFile(joinPath(directory, file));
            }
        }
        #else
        throw "Can't walk a directory on this target.";
        #end
    }

    public static function purgeDirectory(directory) {
        #if (sys || hxnodejs)
        walkDirectory("", directory, FileSystem.deleteFile, null, FileSystem.deleteDirectory);
        FileSystem.deleteDirectory(directory);
        #else
        throw "Can't delete files/folders on this target.";
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

    #if (sys || hxnodejs)
    public static function userHome() {
        var msysHome = Sys.getEnv("MSYSHOME");
        var home = Sys.getEnv("HOME");
        var userProfile = Sys.getEnv("UserProfile");
        return if (msysHome != null)
            msysHome;
        else if (home != null)
            home;
        else if (userProfile != null)
            userProfile;
        else
            throw "Cannot find user's home directory";
    }

    public static var cachedConvertToHScript:String->String = cast(fsMemoize(convertToHScript, "convertToHScript", '${userHome()}/.kiss-cache'));
    #end

    public static function getTarget():KissTarget {
        return #if cpp
            Cpp;
        #elseif cs
            CSharp;
        #elseif interp
            Haxe;
        #elseif hxnodejs
            NodeJS;
        #elseif js
            JavaScript;
        #elseif python
            Python;
        #elseif macro
            Macro;
        #else
            throw "Unsupported target language for Kiss";
        #end
    }

    public static function assertProcess(command:String, args:Array<String>, ?inputLines:Array<String>, fullProcess = true, cwd = null):String {
        return tryProcess(command, args, (error) -> { throw error; }, inputLines, fullProcess, cwd);    
    }
    
    public static function tryProcess(command:String, args:Array<String>, handleError:String->Void, ?inputLines:Array<String>, fullProcess = true, cwd:String = null):String {
        #if test
        Prelude.print('running $command $args $inputLines from ${Prelude.getTarget()}');
        #end
        if (inputLines != null) {
            for (line in inputLines) {
                if (line.indexOf("\n") != -1) {
                    handleError('newline is not allowed in the middle of a process input line: "${line.replace("\n", "\\n")}"');
                    return null;
                }
            }
        }
        #if python
        // on Python, after new Process() is called, writing inputLines to stdin becomes impossible. Use python.lib.subprocess instead
        var p = try {
            Popen.create([command].concat(args), {
                stdin: -1, // -1 represents PIPE which allows communication
                stdout: -1,
                stderr: -1,
                cwd: cwd
            });
        } catch (e:Dynamic) {
            handleError(Std.string(e));
            return null;
        }
        if (inputLines != null) {
            for (line in inputLines) {
                p.stdin.write(new Bytearray('$line\n', "utf-8"));
            }
        }

        var output = if (fullProcess) {
            if (p.wait() == 0) {
                p.stdout.readall().decode().trim();
            } else {
                handleError('process $command $args failed:\n${p.stdout.readall().decode().trim() + p.stderr.readall().decode().trim();}');
                return null;
            }
        } else {
            // The haxe extern for FileIO.readline() says it's a string, but it's not, it's bytes!
            var bytes:Dynamic = p.stdout.readline();
            var s:String = bytes.decode();
            s.trim();
        }
        p.terminate();
        return output;
        #elseif sys
        var lastCwd = Sys.getCwd();
        if (cwd != null) {
            #if java
            throw 'Kiss cannot specify the working directory of a subprocess in Java';
            #end
            Sys.setCwd(cwd);
        }
        try {
            var p = new Process(command, args);
            if (inputLines != null) {
                for (line in inputLines) {
                    p.stdin.writeString('$line\n');
                }
            }
            var output =
                #if !cs
                if (fullProcess) {
                    if (p.exitCode() == 0) {
                        p.stdout.readAll().toString().trim();
                    } else {
                        handleError('process $command $args failed:\n${p.stdout.readAll().toString().trim() + p.stderr.readAll().toString().trim()}');
                        return null;
                    }
                } else
                #end
                    p.stdout.readLine().toString().trim();
            #if !cs
            p.kill();
            p.close();
            #end
            if (cwd != null) {
                Sys.setCwd(lastCwd);
            }
            return output;
        } catch (e) {
            handleError('process $command $args failed: $e');
            return null;
        }
        #elseif hxnodejs
        var p = if (inputLines != null) {
            ChildProcess.spawnSync(command, args, {input: inputLines.join("\n"), cwd: cwd});
        } else {
            ChildProcess.spawnSync(command, args, {cwd: cwd});
        }
        var output = switch (p.status) {
            case 0:
                var output:Buffer = p.stdout;
                if (output == null) output = Buffer.alloc(0);
                output.toString();
            default:
                var output:Buffer = p.stdout;
                if (output == null) output = Buffer.alloc(0);
                var error:Buffer = p.stderr;
                if (error == null) error = Buffer.alloc(0);
                handleError('process $command $args failed:\n${output.toString() + error.toString()}');
                return null;
        }
        return output;
        #else
        handleError("Can't run a subprocess on this target.");
        return null;
        #end
    }

    // Get the path to a haxelib the user has installed
    public static function libPath(haxelibName:String) {
        return assertProcess("haxelib", ["libpath", haxelibName]).trim();
    }

    #if target.threaded
    static var shellCountMutex = new Mutex();
    #end

    static var shellCount = 0;

    public static function shellExecute(script:String, shell:String) {
        #if (sys || hxnodejs)
        if (shell.length == 0) {
            shell = if (Sys.systemName() == "Windows") "cmd /c" else "bash";
        }

        #if target.threaded
        shellCountMutex.acquire();
        #end
        var tempScript = 'tempScript${shellCount++}.${shell.split(" ")[0]}';
        #if target.threaded
        shellCountMutex.release();
        #end
        
        File.saveContent(tempScript, script);
        try {
            if (Sys.systemName() != "Windows") tempScript = joinPath(Sys.getCwd(), tempScript);
            var parts = shell.split(" ").concat([tempScript]);
            var shell = parts.shift();
            assertProcess(shell, parts);
            FileSystem.deleteFile(tempScript);
        } catch (e) {
            printStr('# Failing script:');
            printStr(script);
            printStr('#################');
            FileSystem.deleteFile(tempScript);
            throw e;
        }

        #else
        throw "Can't run a shell script on this target.";
        #end
    }

    public static function filter<T>(l:Iterable<T>, ?p:(T) -> Bool):kiss.List<T> {
        if (p == null)
            p = Prelude.truthy;
        return Lambda.filter(l, p);
    }

    #if (sys || hxnodejs)
    public static function readDirectory(dir:String) {
        return [for (file in FileSystem.readDirectory(dir)) {
            joinPath(dir, file);
        }];
    }
    #end

    // TODO this could get confusing, because its behavior (index to index) is the opposite of haxe substr.
    public static function substr(str:String, startIdx:Int, ?endIdx:Int) {
        function negIdx(idx) {
            return if (idx < 0) str.length + idx else idx;
        }

        if (endIdx == null) endIdx = str.length;

        return str.substring(negIdx(startIdx), negIdx(endIdx));
    }

    public static function runtimeInsertAssertionMessage(message:String, error:String, colonsInPrefix:Int) {
        var colonIdx = 0;
        for (_ in 0...colonsInPrefix) {
            colonIdx = error.indexOf(":", colonIdx) + 1;
        }
        colonIdx += 1;
        return error.substr(0, colonIdx) + message + error.substr(colonIdx);
    }

    public static var newLine = "\n";
    public static var backSlash = "\\";
    public static var doubleQuote = "\"";
    public static var dollar = "$";
}
