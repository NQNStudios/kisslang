package kiss_firefox;

@:native("")
extern class API {
    @:native("browser")
    static var browser:webextension_polyfill.Browser;
}