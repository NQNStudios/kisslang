package kiss;

import haxe.macro.Context;
import haxe.macro.Expr;
import kiss.Stream;
import kiss.Reader;
import kiss.FieldForms;
import kiss.SpecialForms;

class Kiss {
	/**
		Build a Haxe class from a corresponding .kiss file
	**/
	macro static public function build(kissFile:String):Array<Field> {
		var classFields = Context.getBuildFields();

		var stream = new Stream(kissFile);
		var reader = new Reader();

		var fieldForms = FieldForms.builtins();
		var specialForms = SpecialForms.builtins();

		while (true) {
			stream.dropWhitespace();
			if (stream.isEmpty())
				break;
			var position = stream.position();
			var nextExp = reader.read(stream);
			#if test
			trace(nextExp);
			#end
			// The last expression might be a comment, in which case None will be returned
			switch (nextExp) {
				case Some(nextExp):
					classFields.push(readerExpToField(nextExp, position, fieldForms, specialForms));
				case None:
					stream.dropWhitespace(); // If there was a comment, drop whitespace that comes after
			}
		}

		return classFields;
	}

	static function readerExpToField(exp:ReaderExp, position:String, fieldForms:Map<String, FieldFormFunction>,
			specialForms:Map<String, SpecialFormFunction>):Field {
		return switch (exp) {
			case Call(Symbol(formName), args) if (fieldForms.exists(formName)):
				fieldForms[formName](position, args, readerExpToHaxeExpr.bind(_, specialForms));
			default:
				throw '$exp at $position is not a valid field form';
		};
	}

	static function readerExpToHaxeExpr(exp:ReaderExp, specialForms:Map<String, SpecialFormFunction>):Expr {
		var expr = switch (exp) {
			case Symbol(name):
				Context.parse(name, Context.currentPos());
			case Str(s):
				{
					pos: Context.currentPos(),
					expr: EConst(CString(s))
				};
			case Call(Symbol(specialForm), args) if (specialForms.exists(specialForm)):
				specialForms[specialForm](args, readerExpToHaxeExpr.bind(_, specialForms));
			case Call(func, body):
				{
					pos: Context.currentPos(),
					expr: ECall(readerExpToHaxeExpr(func, specialForms), [for (bodyExp in body) readerExpToHaxeExpr(bodyExp, specialForms)])
				};
			case RawHaxe(code):
				Context.parse(code, Context.currentPos());
			default:
				throw 'cannot convert $exp yet';
		};
		#if test
		trace(expr.expr);
		#end
		return expr;
	}
}
