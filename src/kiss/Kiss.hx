package kiss;

import haxe.macro.Context;
import haxe.macro.Expr;
import kiss.Stream;
import kiss.Reader;
import kiss.FieldForms;
import kiss.SpecialForms;
import kiss.Macros;

class Kiss {
	/**
		Build a Haxe class from a corresponding .kiss file
	**/
	macro static public function build(kissFile:String):Array<Field> {
		var classFields = Context.getBuildFields();

		var stream = new Stream(kissFile);

		var readTable = Reader.builtins();
		var fieldForms = FieldForms.builtins();
		var specialForms = SpecialForms.builtins();
		var macros = Macros.builtins();

		while (true) {
			stream.dropWhitespace();
			if (stream.isEmpty())
				break;
			var position = stream.position();
			var nextExp = Reader.read(stream, readTable);
			#if test
			trace(nextExp);
			#end
			// The last expression might be a comment, in which case None will be returned
			switch (nextExp) {
				case Some(nextExp):
					classFields.push(readerExpToField(nextExp, position, fieldForms, macros, specialForms));
				case None:
					stream.dropWhitespace(); // If there was a comment, drop whitespace that comes after
			}
		}

		return classFields;
	}

	static function readerExpToField(exp:ReaderExp, position:String, fieldForms:Map<String, FieldFormFunction>, macros:Map<String, MacroFunction>,
			specialForms:Map<String, SpecialFormFunction>):Field {
		return switch (exp) {
			case CallExp(Symbol(formName), args) if (fieldForms.exists(formName)):
				fieldForms[formName](position, args, readerExpToHaxeExpr.bind(_, macros, specialForms));
			default:
				throw '$exp at $position is not a valid field form';
		};
	}

	static function readerExpToHaxeExpr(exp:ReaderExp, macros:Map<String, MacroFunction>, specialForms:Map<String, SpecialFormFunction>):Expr {
		// Bind the table arguments of this function for easy recursive calling/passing
		var convert = readerExpToHaxeExpr.bind(_, macros, specialForms);
		var expr = switch (exp) {
			case Symbol(name):
				Context.parse(name, Context.currentPos());
			case StrExp(s):
				{
					pos: Context.currentPos(),
					expr: EConst(CString(s))
				};
			case CallExp(Symbol(mac), args) if (macros.exists(mac)):
				convert(macros[mac](args));
			case CallExp(Symbol(specialForm), args) if (specialForms.exists(specialForm)):
				specialForms[specialForm](args, convert);
			case CallExp(func, body):
				{
					pos: Context.currentPos(),
					expr: ECall(readerExpToHaxeExpr(func, macros, specialForms), [for (bodyExp in body) readerExpToHaxeExpr(bodyExp, macros, specialForms)])
				};
			case ListExp(elements):
				{
					pos: Context.currentPos(),
					expr: ENew({
						pack: ["kiss"],
						name: "List"
					}, [
						{
							pos: Context.currentPos(),
							expr: EArrayDecl([for (elementExp in elements) convert(elementExp)])
						}
					])
				}
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
