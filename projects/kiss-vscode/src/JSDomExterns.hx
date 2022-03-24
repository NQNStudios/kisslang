import js.html.Document;

typedef JSDOMWindow = {
    document:Document
};

@:jsRequire("jsdom", "JSDOM")
extern class JSDOM {
    function new(html:String);
    var window:JSDOMWindow;
}
