//TODO: use htmlhelper
package core;
import js.html.Event;
import js.Browser;
import js.html.Element;
import js.html.CSSStyleDeclaration;
class CSSenterFrame
{
    
    var onEnterFrame:    Void -> Void;

    public function new( onEnterFrame_: Void->Void )
    {
        onEnterFrame = onEnterFrame_;
        var s = Browser.document.createStyleElement();
        s.innerHTML = "@keyframes spin {  from { transform:rotate( 0deg ); } to { transform:rotate( 360deg ); } }";
        Browser.document.getElementsByTagName("head")[0].appendChild( s );
        //.addEventListener("animationiteration", onEnterFrame, false );
        (cast s).animation = "spin 1s linear infinite";
        loop( 60 );
    }
    
    
    private function loop( tim: Float ):Bool
    {
        Browser.window.requestAnimationFrame( loop );
        onEnterFrame( );
        return true;
    }
    
}
