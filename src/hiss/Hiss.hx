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
		while (!stream.isEmpty()) {
			var position = stream.position();
			var nextExp = reader.read(stream);
			trace(nextExp);
			// The last expression might be a comment, in which case None will be returned
			switch (nextExp) {
				case Some(nextExp):
					classFields.push(readerExpToField(nextExp, position));
				case None:
			}
		}

		return classFields;
	}

	static function readerExpToField(exp:ReaderExp, position:String):Field {
		switch (exp) {
			case Call(Symbol("defvar"), args) if (args.length == 2):
				return {
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
			default:
				throw '$exp at $position is not a valid defvar or defun expression';
		}
	}

	static function readerExpToHaxeExpr(exp:ReaderExp):Expr {
		return switch (exp) {
			case Symbol(name):
				Context.parse(name, Context.currentPos());
			case Str(s):
				return {
					pos: Context.currentPos(),
					expr: EConst(CString(s))
				};
			default:
				throw 'cannot convert $exp yet';
		};
	}
}
