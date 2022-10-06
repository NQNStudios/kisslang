package kiss;

import kiss.Kiss;
import tink.syntaxhub.*;
import haxe.macro.Expr;
import haxe.macro.Context;
import haxe.macro.Expr.ImportMode;

class KissFrontend implements FrontendPlugin {
	
	public function new() {}
	
	public function extensions() 
		return ['kiss'].iterator();
	
	public function parse(file:String, context:FrontendContext):Void {

		final fields = Kiss.build(file,null,false,context);
		#if debug
			trace(context.name);
		#end 
		final type = context.getType();
		var pos = Context.makePosition({ file: file, min: 0, max: 0 });
		context.addImport('kiss.Prelude',INormal,pos);
		for (field in fields) {
			type.fields.push(field);
		}
	}

	static function use()
		tink.SyntaxHub.frontends.whenever(new KissFrontend());
}