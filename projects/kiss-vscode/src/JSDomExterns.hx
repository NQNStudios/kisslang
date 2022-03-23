import js.html.Document;

typedef JSDOMWindow = {
    document:Document
};

@:jsRequire("jsdom")
extern class JSDOM {
    function new(html:String);
    var window:JSDOMWindow;
}
