
package core;
import js.Browser;
import js.html.Element;
import js.html.CSSStyleDeclaration;
import js.html.CanvasElement;
import js.html.CanvasRenderingContext2D;
import js.html.Element;
import js.html.BodyElement;
import js.html.ImageElement;

class SetupCanvas
{
    
    public var surface:     CanvasRenderingContext2D;
    public var dom:         Element;
    public var image:       ImageElement;
    public var canvas:      CanvasElement;
    public var style:       CSSStyleDeclaration;
    public var body:        Element;
    public function new( ?wid: Int = 1024, ?hi: Int = 768 )
    {
        canvas                      = Browser.document.createCanvasElement();
        dom                         = cast canvas;
        body                        = Browser.document.body;
        surface                     = canvas.getContext2d();
        style                       = dom.style;
        canvas.width                = wid;
        canvas.height               = hi;
        style.paddingLeft           = "0px";
        style.paddingTop            = "0px";
        style.left                  = Std.string( 0 + 'px' );
        style.top                   = Std.string( 0 + 'px' );
        style.position              = "absolute";
        image                       = cast dom;
    }
}
