package core;

// Used by internet explorer for displaying.


import js.Lib;
import js.html.Element;
import js.html.CSSStyleDeclaration;
using core.GlobalDiv;
class ImageDiv
{
    
    public var fixedTextWidth:  Int;
    public var fixedTextHeight: Int;
    
    // TODO: possibly remove
    public var _d:              Int;
    
    // TODO: Check if this should be public?
    public var _dom:            Element;
    
    private var _y:             Float;
    private var _x:             Float;
    private var _width:         Float;
    private var _height:        Float;
    private var _style:         CSSStyleDeclaration;
    private var _bgColor:       String;
    private var _img:           String;
    private var _tile:          Bool;
    private var offSetX:        Int;
    private var offSetY:        Int;
    private var viz:            Bool;
    
    // NOTE: Divtastic properties here so we can take them into account in getGlobalXY etc...
    
    private var _scale:         Float;
    private var _scaleY:        Float;
    private var _scaleX:        Float;
    private var _alpha:         Float;
    private var _rotation:      Float;
    private var _angle:         Int;
    
    // NOTE: Not currently used possibly store affines when tested more.
    public var afflines:        Array<Float>;
    
    
    public function new( ?img: String )
    {
        trace('imageDiv');
        _dom           = ROOT().createElement( "div" );
        _style          = _dom.style; 
        
        set_tile( false );
        if( img != null )
        {
            
            set_image( img );
            
        }
        
        _style.position =  "absolute";
        _d = 0;
        
    }
    
    
    public function set_image( img: String )
    {
        
        _img = img;
        
        if( img.split('.').length > 1 )
        {
            
            //trace('setting image to ' + img );
            _style.backgroundImage = 'url(' + img +')';
            
        }
        else
        {
            
            _dom.className = img ;
            
        }
        
    }
    
    
    public function appended()
    {
        
        
        
    } 
    
    
    // for width and height to be adjustable ( tweenable ) you need to set this.
    public function setClip()
    {
        
        _style.overflow  = 'Hidden';
        
    }
    
    
    public var tile( get_tile, set_tile ):Bool;
    
    
    private function get_tile():Bool
    {
        
        if( _tile == null )
        {
            
            set_tile( false ) ;
            
        }
        return _tile ;
        
    }
    
    
    private function set_tile( tile_: Bool ):Bool
    {
        
        _tile = tile_;
        if( _tile )
        {
            
            _style.backgroundRepeat = 'repeat';
            
        }
        else
        {
            
            _style.backgroundRepeat = 'no-repeat';
            
        }
        return tile_;
        
    }
    
    
    public function getInstance():                  Element
    {
        
        return _dom;
        
    }
    
    
    public function getStyle():                     CSSStyleDeclaration
    {
        
        return _style;
        
    }
    
    
    public var visible( get_visible, set_visible ): Bool;
    
    public function set_visible( val: Bool ):       Bool
    {
        
        //TODO: consider collapse
        
        if( val )
        {
            
            _style.visibility = "visible"; 
            
        } 
        else
        {
            
            _style.visibility = "hidden"; 
            
        }
        
        viz = val;
        
        return viz;
        
    }
    
    
    public function get_visible():                  Bool
    {
        
        if( viz == null )
        {
            
            viz = true;
            
        }    
        
        return viz;
        
    }
    
    
    public var fill( get_fill, set_fill ):          String;
    
    public function set_fill( c: String ):          String
    {
        
        _bgColor = c;
        _style.backgroundColor = c;
        return c;
        
    }
    
    
    public function get_fill():                     String
    {
        
        return _bgColor;
        
    }
    
    
    public var height( get_height, set_height ):    Float;
    public function set_height( val: Float ):      Float
    {
        
        _height = val;
        _style.paddingTop = val + "px";
        return val;
        
    }
    public function get_height():                  Float
    {
        
        if( _height == null || _height < _dom.clientHeight )
        {
            _height = _dom.clientHeight;
        }
        return _height;
        
    }
    
    
    public var width( get_width, set_width ):       Float;
    public function set_width( val: Float ):       Float
    {
        
        _width = val;
        _style.paddingLeft = val + "px";
        return val;
        
    }
    private function get_width():                   Float
    {   
        
        if( _width == null || _width < _dom.clientWidth )
        {
            _width = _dom.clientWidth;
        }
        return _width;
        
    }
    
    
    public var y( get_y, set_y ):                   Float;
    private function set_y( val: Float ):           Float
    {
        
        _y = val;
        _style.top = val + "px";
        return val;
        
    }
    private function get_y():                       Float
    {
        
        return _y;
        
    }
    
    public var x( get_x, set_x ):                   Float;
    private function set_x( val: Float ):           Float
    {
        
        _x = val;
        _style.left = val + "px";
        return val;
        
    }
    private function get_x():                       Float
    {
        
        return _x;
        
    }
    
    
    public var _parent:                                     DisplayDiv;
    public var parent( get_parent, set_parent ):            DisplayDiv;
    public function set_parent( mc: DisplayDiv ):  DisplayDiv
    {
        
        _parent = mc;
        return mc;
        
    }
    public function get_parent():                           DisplayDiv
    {
        
        return _parent;
        
    }
    
    
}
