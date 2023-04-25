package;

import js.node.Buffer;
import js.lib.Promise;

@:jsRequire("pdf-lib", "PDFDocument")
extern class PDFDocument {
    public static function create():Promise<PDFDocument>;
    public static function load(bytes:Buffer, ?options:LoadOptions):Promise<PDFDocument>;
    public function save():Promise<Buffer>;
    public function getPageCount():Int;
    public function copyPages(srcDoc:PDFDocument, indices:Array<Int>):Promise<Array<PDFPage>>;
    public function addPage(page:PDFPage):Void;
}

typedef LoadOptions = {
    ?capNumbers:Bool,
    ?ignoreEncryption:Bool,
    ?parseSpeed:Float,
    ?throwOnInvalidObject:Bool,
    ?updateMetadata:Bool
};

@:jsRequire("pdf-lib", "PDFPage")
extern class PDFPage {}
