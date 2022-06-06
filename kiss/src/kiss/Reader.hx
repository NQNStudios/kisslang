package kiss;

import haxe.ds.Option;
import kiss.Stream;
import kiss.Kiss;
import kiss.ReaderExp;

using kiss.Reader;
using kiss.Stream;
using kiss.Helpers;
using StringTools;

class UnmatchedBracketSignal {
    public var type:String;
    public var position:Stream.Position;

    public function new(type, position) {
        this.type = type;
        this.position = position;
    }
}

typedef ReadFunction = (Stream, KissState) -> Null<ReaderExpDef>;
typedef ReadTable = Map<String, ReadFunction>;

class Reader {
    // The built-in readtable
    public static function builtins() {
        var readTable:ReadTable = [];

        readTable["("] = (stream, k) -> CallExp(assertRead(stream, k), readExpArray(stream, ")", k));
        readTable["["] = (stream, k) -> ListExp(readExpArray(stream, "]", k));
        readTable["[::"] = (stream, k) -> ListEatingExp(readExpArray(stream, "]", k));
        readTable["..."] = (stream, k) -> ListRestExp(nextToken(stream, "name for list-eating rest exp", true));
        // Provides a nice syntactic sugar for (if... {[then block]} {[else block]}),
        // and also handles string interpolation cases like "${exp}moreString"
        readTable["{"] = (stream:Stream, k) -> CallExp(Symbol("begin").withPos(stream.position()), readExpArray(stream, "}", k));

        readTable['"'] = readString.bind(_, _, false);
        readTable["#"] = readRawString;

        // Special symbols that wouldn't read as symbols, but should:
        function forceSymbol(sym:String) {
            readTable[sym] = (stream, k) -> Symbol(sym);
        }
        forceSymbol("#if");
        forceSymbol("#when");
        forceSymbol("#unless");
        forceSymbol("#cond");
        forceSymbol("#case");
        forceSymbol("#extern");

        readTable["/*"] = (stream:Stream, k) -> {
            stream.takeUntilAndDrop("*/");
            null;
        };
        readTable["//"] = (stream:Stream, k) -> {
            stream.takeUntilAndDrop("\n");
            null;
        }; 
        // Special comment syntax that disables the next whole reader expression:
        readTable["**"] = (stream:Stream, k) -> {
            assertRead(stream, k);
            null;
        };

        readTable["'"] = (stream:Stream, k) -> {
            CallExp(Symbol("quote").withPos(stream.position()), [assertRead(stream, k)]);
        };

        readTable["#|"] = (stream:Stream, k) -> {
            var pos = stream.position();
            var haxe = stream.expect("closing |#", () -> stream.takeUntilAndDrop("|#"));
            var def = RawHaxe(haxe);
            var haxeWithSemi = haxe.trim();
            if (!haxeWithSemi.endsWith(";"))
                haxeWithSemi += ";";
            KissError.warnFromExp(def.withPos(pos), '#|rawHaxe()|# expressions are deprecated because they only parse one statement and ignore the rest. Try this: #{$haxeWithSemi}#');
            def;
        };

        readTable["#{"] = (stream:Stream, k) -> {
            RawHaxeBlock(stream.expect("closing }#", () -> stream.takeUntilAndDrop("}#")));
        };

        readTable[":"] = (stream:Stream, k) -> TypedExp(nextToken(stream, "a type path"), assertRead(stream, k));

        readTable["&"] = (stream:Stream, k) -> MetaExp(nextToken(stream, "a meta symbol like mut, optional, rest"), assertRead(stream, k));

        readTable["!"] = (stream:Stream, k) -> CallExp(Symbol("not").withPos(stream.position()), [assertRead(stream, k)]);

        // Helpful for quickly debugging an expression by printing the value:
        readTable["~"] = (stream:Stream, k) -> {
            var pos = stream.position();
            var expToPrint = assertRead(stream, k);
            var expToPrintRepresentation = StrExp(Reader.toString(expToPrint.def)).withPos(pos);
            CallExp(Symbol("print").withPos(pos), [expToPrint, expToPrintRepresentation]);
        }

        // Helpful for defining predicates to pass to Haxe functions:
        readTable["?"] = (stream:Stream, k) -> CallExp(Symbol("Prelude.truthy").withPos(stream.position()), [assertRead(stream, k)]);

        // Lets you dot-access a function result without binding it to a name
        readTable["."] = (stream:Stream, k) -> FieldExp(nextToken(stream, "a field name"), assertRead(stream, k));

        // Lets you construct key-value pairs for map literals or for-loops
        readTable["=>"] = (stream:Stream, k) -> KeyValueExp(assertRead(stream, k), assertRead(stream, k));

        function unmatchedBracket(b:String) {
            readTable[b] = (stream:Stream, k) -> {
                stream.putBackString(b);
                throw new UnmatchedBracketSignal(b, stream.position());
            };
        }

        unmatchedBracket(")");
        unmatchedBracket("]");
        unmatchedBracket("}");

        readTable["`"] = (stream:Stream, k) -> Quasiquote(assertRead(stream, k));
        readTable[","] = (stream:Stream, k) -> Unquote(assertRead(stream, k));
        readTable[",@"] = (stream:Stream, k) -> UnquoteList(assertRead(stream, k));

        // Command line syntax:
        readTable["```"] = (stream:Stream, k) -> {
            var shell = switch (stream.takeLine()) {
                case Some(shell): shell;
                default: "";
            };
            var pos = stream.position();
            var script = readString(stream, k, true).withPos(pos);
            CallExp(
                Symbol("Prelude.shellExecute").withPos(pos), [
                    script,
                    StrExp(shell).withPos(pos)
                ]);
        };

        // Lambda arrow syntaxes:
        //     ->[args] body
        //     ->arg body
        //     ->{body}
        // OR, for countingLambda:
        //     -+>countVar [args] body
        //     -+>countVar arg body
        //     -+>countVar {body}
        // or any of those with the first expression after -> or -+> prefixed by :Void
        function arrowSyntax(countingLambda:Bool, stream:Stream, k:KissState) {
            var countVar = if (countingLambda) {
                assertRead(stream, k);
            } else {
                null;
            }
            var firstExp = assertRead(stream, k);
            var b = firstExp.expBuilder();

            var argsExp:ReaderExp = null;
            var bodyExp:ReaderExp = null;

            var returnsValue = true;
            switch (firstExp.def) {
                case TypedExp("Void", realFirstExp):
                    firstExp = realFirstExp;
                    returnsValue = false;
                default:
            }
            switch (firstExp.def) {
                case ListExp(_):
                    argsExp = firstExp;
                    bodyExp = assertRead(stream, k);
                case Symbol(_):
                    argsExp = b.list([firstExp]);
                    bodyExp = assertRead(stream, k);
                case CallExp(_, _):
                    argsExp = b.list([]);
                    bodyExp = firstExp;
                default:
                    throw KissError.fromExp(firstExp, "first expression after -> should be [args...], arg, (exp) or {body}, or one of those prefixed with :Void");
            }
            if (!returnsValue) {
                argsExp = TypedExp("Void", argsExp).withPosOf(argsExp);
            }
            return if (countingLambda) {
                CallExp(b.symbol("countingLambda"), [countVar, argsExp, bodyExp]);
            } else {
                CallExp(b.symbol("lambda"), [argsExp, bodyExp]);
            };
        }

        readTable["->"] = arrowSyntax.bind(false);
        readTable["-+>"] = arrowSyntax.bind(true);

        // Because macro keys are sorted by length and peekChars(0) returns "", this will be used as the default reader macro:
        readTable[""] = (stream:Stream, k:KissState) -> {
            var position = stream.position();
            var token = nextToken(stream, "a symbol name");
            // Process dot-access on alias identifiers
            return if (token.indexOf(".") != -1) {
                if (!Math.isNaN(Std.parseFloat(token))) {
                    Symbol(token);
                } else {
                    var tokenParts = token.split(".");
                    var fieldExpVal = tokenParts.shift();
                    var fieldExp = Symbol(fieldExpVal);
                    if (k.identAliases.exists(fieldExpVal)) {
                        while (tokenParts.length > 0) {
                            fieldExp = FieldExp(tokenParts.shift(), fieldExp.withPos(position));
                        }
                        fieldExp;
                    } else {
                        Symbol(token);
                    }
                }
            } else {
                Symbol(token);
            };
        }

        return readTable;
    }

    public static final terminators = [")", "]", "}", '"', "/*", "\n", " "];

    public static function nextToken(stream:Stream, expect:String, allowEmptyString = false) {
        switch (stream.takeUntilOneOf(terminators, true)) {
            case Some(tok) if (tok.length > 0 || allowEmptyString):
                return tok;
            default:
                stream.error('Expected $expect');
                return null;
        }
    }

    public static function assertRead(stream:Stream, k:KissState):ReaderExp {
        var position = stream.position();
        return switch (read(stream, k)) {
            case Some(exp):
                exp;
            case None:
                stream.error('Ran out of Kiss expressions');
                return null;
        };
    }

    static function chooseReadFunction(stream:Stream, readTable:ReadTable):Null<ReadFunction> {
        var readTableKeys = [for (key in readTable.keys()) key];
        readTableKeys.sort((a, b) -> b.length - a.length);

        for (key in readTableKeys) {
            switch (stream.peekChars(key.length)) {
                case Some(ky) if (ky == key):
                    stream.dropString(key);
                    return readTable[key];
                default:
            }
        }

        return null;
    }

    public static function read(stream:Stream, k:KissState):Option<ReaderExp> {
        var readTable = k.readTable;
        stream.dropWhitespace();

        if (stream.isEmpty())
            return None;

        var position = stream.position();

        var readFunction = null;
        if (stream.startOfLine)
            readFunction = chooseReadFunction(stream, k.startOfLineReadTable);
        if (readFunction != null)
            stream.startOfLine = false;
        else
            readFunction = chooseReadFunction(stream, k.readTable);
        // This should never happen, because there is a readFunction for "":
        if (readFunction == null)
            throw 'No macro to read next expression';

        var expOrNull = readFunction(stream, k);
        return if (expOrNull != null) {
            Some(expOrNull.withPos(position));
        } else {
            read(stream, k);
        }
    }

    public static function readExpArray(stream:Stream, end:String, k:KissState):Array<ReaderExp> {
        var array = [];
        var startingPos = stream.position();
        while (!stream.startsWith(end)) {
            stream.dropWhitespace();
            if (!stream.startsWith(end)) {
                try {
                    switch (read(stream, k)) {
                        case Some(exp):
                            array.push(exp);
                        case None:
                            throw new StreamError(startingPos, 'Ran out of expressions before $end was found.');
                    }
                } catch (s:UnmatchedBracketSignal) {
                    if (s.type == end)
                        break;
                    else
                        throw s;
                }
            }
        }
        stream.dropString(end);
        return array;
    }

    /**
        Read all the expressions in the given stream, processing them one by one while reading.
        They can't be read all at once because some expressions change the Readtable state
    **/
    public static function readAndProcess(stream:Stream, k:KissState, process:(ReaderExp) -> Void) {
        for (key => func in k.startOfFileReadTable) {
            if (stream.startsWith(key)) {
                var pos = stream.position();
                stream.dropString(key);
                var v = func(stream, k);
                if (v != null)
                    process(v.withPos(pos));
                break;
            }
        }

        while (true) {
            stream.dropWhitespace();
            for (key => func in k.endOfFileReadTable) {
                if (stream.content == key) {
                    var pos = stream.position();
                    stream.dropString(key);
                    var v = func(stream, k);
                    if (v != null)
                        process(v.withPos(pos));
                    break;
                }
            }

            if (stream.isEmpty())
                break;
            var position = stream.position();
            var nextExp = Reader.read(stream, k);
            // The last expression might be a comment, in which case None will be returned
            switch (nextExp) {
                case Some(nextExp):
                    process(nextExp);
                case None:
                    stream.dropWhitespace(); // If there was a comment, drop whitespace that comes after
            }
        }
    }

    public static function withPos(def:ReaderExpDef, pos:Position) {
        return {
            pos: pos,
            def: def
        };
    }

    public static function withPosOf(def:ReaderExpDef, exp:ReaderExp) {
        return {
            pos: exp.pos,
            def: def
        };
    }

    // Read a string literal OR a shell section which supports interpolation
    static function readString(stream:Stream, k:KissState, shell = false) {
        var pos = stream.position();
        var stringParts:Array<ReaderExp> = [];
        var currentStringPart = "";

        function endCurrentStringPart() {
            stringParts.push(StrExp(currentStringPart).withPos(pos));
            currentStringPart = "";
        }

        var terminator = if (shell) "```" else '"';
        var escapes = ["$" => "$"];
        if (!shell) {
            escapes['\\'] = '\\';
            escapes['t'] = '\t';
            escapes['n'] = '\n';
            escapes['r'] = '\r';
            escapes['"'] = '"';
        }

        do {
            var next = switch (stream.takeChars(1)) {
                case Some(c): c;
                default: 
                    var type = if (shell) "shell block" else "string literal";
                    throw new StreamError(pos, 'Unterminated $type. Expected $terminator');
            }

            switch (next) {
                case '$':
                    endCurrentStringPart();
                    var wrapInIf = false;
                    var firstAfterDollar = stream.expect('interpolation expression', () -> stream.peekChars(1));
                    if (firstAfterDollar == '"') {
                        throw new StreamError(pos, "$ at end of string should be prefixed with \\ or followed by an expression to interpolate");
                    }
                    if (firstAfterDollar == "?") {
                        wrapInIf = true;
                        stream.dropChars(1);
                    }
                    var interpExpression = assertRead(stream, k);
                    var b = interpExpression.expBuilder();
                    interpExpression = b.callSymbol("Std.string", [interpExpression]);
                    if (wrapInIf) {
                        interpExpression = b.callSymbol("if", [interpExpression, interpExpression, b.str("")]);
                    }
                    stringParts.push(interpExpression);
                case '\\':
                    var escapeSequence = stream.expect('valid escape sequence', () -> stream.takeChars(1));
                    if (escapes.exists(escapeSequence)) {
                        currentStringPart += escapes[escapeSequence];
                    } else {
                        stream.error('unsupported escape sequence \\$escapeSequence');
                        return null;
                    }
                case t if (terminator.startsWith(t)):
                    if (terminator.length == 1 ||
                        switch (stream.takeChars(terminator.length - 1)) {
                            case Some(rest) if (rest == terminator.substr(1)):
                                true;
                            case Some(other):
                                stream.putBackString(other);
                                false;
                            default:
                                throw new StreamError(pos, 'Unterminated shell block. Expected $terminator');
                        }) {
                        endCurrentStringPart();
                        return if (stringParts.length == 1) {
                            stringParts[0].def;
                        } else {
                            var b = stringParts[0].expBuilder();
                            b.the(b.symbol("String"), b.callSymbol("+", stringParts)).def;
                        };
                    } else {
                        currentStringPart += t;
                    }
                default:
                    currentStringPart += next;
            }
        } while (true);
    }

    // Read a raw string literal
    static function readRawString(stream:Stream, k:KissState) {
        var terminator = '"#';
        do {
            var next = stream.expect('# or "', () -> stream.takeChars(1));
            switch (next) {
                case "#":
                    terminator += "#";
                case '"':
                    break;
                default:
                    stream.error('Invalid syntax for raw string.');
                    return null;
            }
        } while (true);

        var startingPos = stream.position();
        // TODO here, give the position of the start of the literal if expect fails

        return switch (stream.takeUntilAndDrop(terminator)) {
            case Some(str):
                StrExp(str);
            default:
                throw new StreamError(startingPos, 'Unterminated string literal. Expected $terminator');
        };
    }

    public static function toString(exp:ReaderExpDef) {
        return switch (exp) {
            case CallExp(func, args):
                // (f a1 a2...)
                var str = '(' + func.def.toString();
                if (args.length > 0)
                    str += " ";
                str += [
                    for (arg in args) {
                        arg.def.toString();
                    }
                ].join(" ");
                str += ')';
                str;
            case ListExp(exps):
                // [v1 v2 v3]
                var str = '[';
                str += [
                    for (exp in exps) {
                        exp.def.toString();
                    }
                ].join(" ");
                str += ']';
                str;
            case StrExp(s):
                // "literal"
                '"$s"';
            case Symbol(name):
                // s
                name;
            case RawHaxe(code):
                // #| haxeCode() |#
                '#| $code |#';
            case RawHaxeBlock(code):
                // #{ haxeCode(); moreHaxeCode(); }#
                '#{ $code }#';
            case TypedExp(path, exp):
                // :Type [exp]
                ':$path ${exp.def.toString()}';
            case MetaExp(meta, exp):
                // &meta
                '&$meta ${exp.def.toString()}';
            case FieldExp(field, exp):
                '.$field ${exp.def.toString()}';
            case KeyValueExp(keyExp, valueExp):
                '=>${keyExp.def.toString()} ${valueExp.def.toString()}';
            case Quasiquote(exp):
                '`${exp.def.toString()}';
            case Unquote(exp):
                ',${exp.def.toString()}';
            case UnquoteList(exp):
                ',@${exp.def.toString()}';
            case ListEatingExp(exps):
                var str = '[::';
                str += [
                    for (exp in exps) {
                        exp.def.toString();
                    }
                ].join(" ");
                str += ']';
                str;
            case ListRestExp(name):
                '...${name}';
            case None:
                '';
        }
    }
}
