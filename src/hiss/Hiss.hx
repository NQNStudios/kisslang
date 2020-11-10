package hiss;

import haxe.macro.Context;
import haxe.macro.Expr;
import hiss.Stream;
import hiss.Reader;

class Hiss {
	/**
		Build a Haxe class from a corresponding .hiss file
	**/
	macro static public function build(hissFile:String):Array<Field> {
		var classFields = Context.getBuildFields();

		var stream = new Stream(hissFile);
		var reader = new Reader();
		while (true) {
			stream.dropWhitespace();
			if (stream.isEmpty())
				break;
			var position = stream.position();
			var nextExp = reader.read(stream);
			trace(nextExp);
			// The last expression might be a comment, in which case None will be returned
			switch (nextExp) {
				case Some(nextExp):
					classFields.push(readerExpToField(nextExp, position));
				case None:
					stream.dropWhitespace(); // If there was a comment, drop whitespace that comes after
			}
		}

		return classFields;
	}

	static function readerExpToField(exp:ReaderExp, position:String):Field {
		return switch (exp) {
			case Call(Symbol("defvar"), args) if (args.length == 2):
				{
					name: switch (args[0]) {
						case Symbol(name):
							name;
						default:
							throw 'The first argument to defvar at $position should be a variable name';
					},
					access: [APublic, AStatic],
					kind: FVar(null, // TODO allow type anotations
						readerExpToHaxeExpr(args[1])),
					pos: Context.currentPos()
				};
			case Call(Symbol("defun"), args) if (args.length > 2):
				{
					name: switch (args[0]) {
						case Symbol(name):
							name;
						default:
							throw 'The first argument to defun at $position should be a function name';
					},
					access: [APublic, AStatic],
					kind: FFun({
						args: switch (args[1]) {
							case List(funcArgs):
								[
									for (funcArg in funcArgs)
										{
											name: switch (funcArg) {
												case Symbol(name):
													name;
												default:
													throw '$funcArg should be a symbol for a function argument';
											},
											type: null
										}
								];
							default:
								throw '$args[1] should be an argument list';
						},
						ret: null,
						expr: {
							pos: Context.currentPos(),
							expr: EReturn(readerExpToHaxeExpr(Call(Symbol("begin"), args.slice(2))))
						}
					}),
					pos: Context.currentPos()
				};
			default:
				throw '$exp at $position is not a valid defvar or defun expression';
		};
	}

	static function readerExpToHaxeExpr(exp:ReaderExp):Expr {
		var expr = switch (exp) {
			case Symbol(name):
				Context.parse(name, Context.currentPos());
			case Str(s):
				{
					pos: Context.currentPos(),
					expr: EConst(CString(s))
				};
			case Call(Symbol("begin"), body):
				{
					pos: Context.currentPos(),
					expr: EBlock([for (bodyExp in body) readerExpToHaxeExpr(bodyExp)])
				};
			case Call(func, body):
				{
					pos: Context.currentPos(),
					expr: ECall(readerExpToHaxeExpr(func), [for (bodyExp in body) readerExpToHaxeExpr(bodyExp)])
				};
			case RawHaxe(code):
				Context.parse(code, Context.currentPos());
			default:
				throw 'cannot convert $exp yet';
		};
		trace(expr.expr);
		return expr;
	}
}
