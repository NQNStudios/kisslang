package;

import js.node.Buffer;
import js.lib.Promise;

@:jsRequire("pdf-lib", "PDFDocument")
extern class PDFDocument {
    public static function create():Promise<PDFDocument>;
    public static function load(bytes:Buffer):Promise<PDFDocument>;
    public function save():Promise<Buffer>;
}
