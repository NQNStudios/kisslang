package core;
import js.Lib;
import js.Browser;
import core.DisplayDiv;
import js.html.HTMLDocument;
class GlobalDiv{
    public static var _root: HTMLDocument = Browser.document;
    public static function ROOT( d: Dynamic ){
        return _root;
        
    }
    
    
    public static function addChild( d: Dynamic, mc: DisplayDiv ):Void
    {
        
        _root.body.appendChild( mc.getInstance() );
        
    }
    
/*
    public static function add( div: DisplayDiv, content: String ): DisplayDiv
    {
        
        var child                      = new DisplayDiv( content );
        
        child.fill                   = '#ffffff';
        child.x                      = 0;
        child.y                      = 0;
        child.width                  = 0;
        child.height                 = 0;
        child.getStyle().position    = 'absolute';
        div.addChild( child );
        
        return child;
        
    }*/
    
}
