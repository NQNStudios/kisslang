package kiss;

import kiss.Kiss;
import tink.syntaxhub.*;
import haxe.macro.Expr;
import haxe.macro.Context;
import haxe.macro.Expr.ImportMode;
using StringTools;

class KissFrontend implements FrontendPlugin {
	
	var extension:String;
	var dslFile:String;
	public function new(extension = "kiss", dslFile = "") {
		this.extension = extension;
		this.dslFile = dslFile;
	}
	
	public function extensions() {
		return [extension].iterator();
	}
	
	public function parse(file:String, context:FrontendContext):Void {

		var files = [file];
		if (dslFile.length > 0) {
			files.unshift(dslFile);
		}

		final fields = Kiss.buildAll(files,null,false,context);
		#if debug
			trace(context.name);
		#end 
		final type = context.getType();
		var pos = Context.makePosition({ file: file, min: 0, max: 0 });
		context.addImport('kiss.Prelude',INormal,pos);
		context.addImport('haxe.ds.Option',INormal,pos);
		context.addUsing('StringTools',pos);
		for (field in fields) {
			type.fields.push(field);
		}
	}

	static function use() {
		tink.SyntaxHub.frontends.whenever(new KissFrontend());
	}
	
	static function dsl(extension:String, dslFile:String) {
		if (extension.startsWith(".")) {
			extension = extension.substr(1);
		}
		tink.SyntaxHub.frontends.whenever(new KissFrontend(extension, dslFile));
	}
}