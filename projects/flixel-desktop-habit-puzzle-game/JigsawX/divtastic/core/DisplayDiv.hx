package core;

import js.Lib;
import core.ImageDiv;
import core.GlobalDiv;
import core.WebBrowser;
import zpartanlite.DispatchTo;
import js.html.Element;
import js.html.DivElement;
import js.html.CSSStyleSheet;
import js.html.VideoElement;
import js.html.Event;
import js.html.HTMLDocument;
import js.html.CanvasElement;
import js.html.CanvasRenderingContext2D;
import js.html.CSSStyleDeclaration;
import js.html.MouseEvent;
using core.GlobalDiv;
class DisplayDiv
{
    
    private var isIE:           Bool;
    public var fixedTextWidth:  Int;
    public var fixedTextHeight: Int;
    
   
    public var _d:              Int;
    public var _negd:           Int;
    public var _dom:            Element;
    
    private var _style:         CSSStyleDeclaration;
    private var _bgColor:       String;
    private var _img:           String;
    private var _tile:          Bool;
    private var offSetX:        Int;
    private var offSetY:        Int;
    private var imageDiv:       ImageDiv;
    private var viz:            Bool;
    
    private var _clientX:       Float;
    private var _clientY:       Float;
    
    public var press:           DispatchTo;
    public var release:         DispatchTo;
    public var out:             DispatchTo;
    public var over:            DispatchTo;
    public var dragging:        DispatchTo;
    public var draggingParent:  DispatchTo;
    
    public var _vid:            VideoElement;
    private var _src:           String;
    public var dragInform:      Bool;
    
    private var _scale:         Float;
    private var _scaleY:        Float;
    private var _scaleX:        Float;
    private var _alpha:         Float;
    private var _rotation:      Float;
    private var _angle:         Int;
    private var _y:             Float;
    private var _x:             Float;
    private var _width:         Float;
    private var _height:        Float;
    public var afflines:        Array<Float>;
    
    
    
    public function new( ?img: String )
    {
        
        if( isVideo( img ) )
        {
            _vid = ROOT().createVideoElement();
            _dom = cast _vid;
        }
        else
        {
            
            if( img == 'canvas' )
            {
                _dom        = ROOT().createCanvasElement();
            }
            else
            {
                _dom        = ROOT().createDivElement();   
            }
            
        }
        
        _style      = _dom.style;
        isIE        =  ( WebBrowser.browserType == IE );
        
        // sets up mouse signals and maps them so the dispatch.
        out         = new DispatchTo();
        out.tellEnabled = outEnabled;
        out.tellDisabled = outDisabled;
        
        over        = new DispatchTo();
        over.tellEnabled = overEnabled;
        over.tellDisabled = overDisabled;
        
        release     = new DispatchTo();
        release.tellEnabled = releaseEnabled;
        release.tellDisabled = releaseDisabled;
        
        press       = new DispatchTo();
        press.tellEnabled = pressEnabled;
        press.tellDisabled = pressDisabled;
        
        dragging    = new DispatchTo();
        dragInform  = false;
        
        draggingParent = new DispatchTo();
        
        set_tile( false );
        if( img != null )
        {
            set_image( img );
        }
        
        _style.position =  "absolute";
        
    }
    
    
    public function getGlobalMouseXY():List<Float>
    {
        
        var globalPos = getGlobalXY();
        var pos =     new List<Float>();
        pos.add( globalPos.first() + _clientX );
        pos.add( globalPos.last() + _clientY );
        return pos;
        
    }
    
    
    //TODO: Take into account rotation and scale?
    public function getGlobalXY():List<Float>
    {
        var p = this;
        var gX = p.x;
        var gY = p.y;
        
        while( p.parent != null )
        {
            p = p.parent;
            gX += p.x;
            gY += p.y;
        }
        var pos: List<Float> = new List();
        pos.add( gX );
        pos.add( gY );
        return pos;
    }
    
    
    private function pressEnabled()
    {
        _dom.onmousedown = function( e )
        {
            var em: MouseEvent = cast e;
            _clientX = em.clientX;
            _clientY = em.clientY; 
            press.dispatch(); 
        };   
    }
    
    
    private function pressDisabled()
    {
        _dom.onmousedown = null;
    }
    
    
    private function releaseEnabled()
    {
        _dom.onmouseup = function( e: Event )
        { 
            var em: MouseEvent = cast e;
            _clientX = em.clientX;
            _clientY = em.clientY;
            release.dispatch(); 
        };
    }
    
    
    public function releaseDisabled()
    {
        _dom.onmouseup = null;
    }
    
    
    private function overEnabled()
    {
        _dom.onmouseover = function( e ){ over.dispatch(); };
    }
    
    
    private function overDisabled()
    {
        _dom.onmouseover = null;
    }
    
    private function outEnabled()
    {
        _dom.onmouseout = function( e ){ out.dispatch(); };
    }
    
    private function outDisabled()
    {
        _dom.onmouseout = null;
    }
    
    
    public function setupDrag()
    {
        _style.cursor       = "pointer";
        press.add( startDrag );
        release.add( stopDrag );
/*
        ROOT().onmousedown = function( e )
        {
            stopDrag();
        }
*/ 
    }
    
    public function startDrag()
    {
        offSetX = Std.int( _clientX - x );
        offSetY = Std.int( _clientY - y );
        ROOT().onmousemove = drag;
    }
    
    
    public function stopDrag()
    {
        ROOT().onmousemove = null;
    }
    
    
    private function drag( e: Event )
    {
        if( dragInform ) dragging.dispatch();
        var em: MouseEvent = cast e;
        x = em.clientX - offSetX;
        y = em.clientY - offSetY;
    }
    
    
    public function setupParentDrag()
    {
        var me              = this;
        _style.cursor       = "pointer";
        press.add( parentStartDrag );
        release.add( parentStopDrag );
    }
    
    
    public function parentStartDrag()
    {
        offSetX = Std.int( _clientX - parent.x );
        offSetY = Std.int( _clientY - parent.y );
        ROOT().onmousemove = parentDrag;
    }
    
    
    public function parentStopDrag()
    {
        ROOT().onmousemove = null;
    }
    
    
    private function parentDrag( e: Event )
    {
        if( dragInform ) draggingParent.dispatch();
        var em: MouseEvent = cast e;
        parent.x = em.clientX - offSetX;
        parent.y = em.clientY - offSetY;
    }
    
    
    public function play()
    {
        if( _vid != null ) _vid.play();
    }
    
    
    private function isVideo( img ): Bool
    {
        
        if( img == null ) return false;
        var arr: Array<String> =  img.split('.');
        if( arr.length == null ) return false;
        var str: String = arr[ 1 ];
        switch( str )
        {
            case 'ogv', 'mpeg', 'mov', 'mp4', 'webm':
                videoType = 'video/'+str;
                return true;
        }
        return false;
        
    }
    private var videoType: String;
    
    public function set_image( img: String )
    {
        
        _img = img;
        
        if ( isIE ) createImageDivIfNot();
        
        if( img.split('.').length > 1 )
        {
            if ( isIE )
            {
                imageDiv.set_image( img );
            }
            else
            {
                if( _vid == null )
                {
                    _style.backgroundImage = 'url(' + img +')';
                }
                else
                {
                    _dom.setAttribute( 'src', img );
                    _dom.setAttribute( 'type', videoType );
                }
            }
        }
        else
        {
            if ( isIE )
            {
                imageDiv.set_image( img );
            }
            else
            {
                _dom.className = img ;
            }
        }
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
        
        if ( isIE )
        {
            createImageDivIfNot();
        }
        
        if( _tile )
        {
            if ( isIE )
            {
                imageDiv.tile = true;
            }
            else
            {
                _style.backgroundRepeat = 'repeat';
            }
        }
        else
        {
            if ( isIE )
            {
                imageDiv.tile = false;
            }
            else
            {
                _style.backgroundRepeat = 'no-repeat';
            }
        }
        return tile_;
    }
    
    
    public function createImageDivIfNot(): ImageDiv 
    {
        if( imageDiv == null )
        {
            imageDiv        = new ImageDiv();
            imageDiv.x      = 0 ;
            imageDiv.y      = 0 ;
            addChild2( imageDiv );
        }
        imageDiv.width     = width ;
        imageDiv.height = height ;
        return imageDiv;
    }
    
    
    public function getInstance(): Element
    {
        return _dom;
    }
    
    
    public function getStyle(): CSSStyleDeclaration
    {
        
        return _style;
        
    }
    
    
    public var text( get_text, set_text ): String;
    
    public function set_text( txt: String ): String
    {
        
        // TODO: look at this code not sure it is ideal but seems useful at moment.
        _dom.innerHTML = '';
        set_width( 0 );
        set_height( 0 );
        if( parent != null ) parent.updateSizeBasedOnChild( this );
        _dom.innerHTML = txt;
        // TODO: not ideal to have browser type in this class think about moving?
        switch( WebBrowser.browserType )
        {
            case FireFox:                           untyped _style.MozUserSelect = 'none';
            case WebKitOther, Safari, Chrome:       untyped _style.webkitUserSelect = 'none';
            case IE, Opera:                         untyped _style.unselectable = 'on';
        }
        set_width( _width );
        set_height( _height );
        if( parent != null ) parent.updateSizeBasedOnChild( this );
        return txt;
    }
    
    
    public function updateText( txt: String )
    {
        _dom.innerHTML = '';
        set_width( 0 );
        set_height( 0 );
        _dom.innerHTML  = txt;
        _style.width    = Std.string( fixedTextWidth );
        if( fixedTextHeight != null ) _style.height = Std.string( fixedTextHeight );
        _style.overflow  = 'Hidden';
    }
    
    
    public function get_text(): String
    {
        return _dom.innerHTML;
    }
    
    
    public var visible( get_visible, set_visible ): Bool;
    
    public function set_visible( val: Bool ): Bool
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
    
    
    public function get_visible(): Bool
    {
        if( viz == null ) viz = true;
        return viz;
    }
    
    
    public var fill( get_fill, set_fill ):          String;
    
    public function set_fill( c: String ):          String
    {
        if ( isIE )
        {
            createImageDivIfNot();
            imageDiv.fill = c;
        }
        else
        {
            _style.backgroundColor = c;
        }
        _bgColor = c;
        return c;
    }
    
    
    public function get_fill():                     String
    {
        return _bgColor;
    }
   
     
    public function addChild( mc: DisplayDiv ): DisplayDiv
    {
        //trace( 'adding child ' + mc );
        _dom.appendChild( mc.getInstance() );   
        //trace( mc.getInstance() );
        mc.parent = this;
        updateSizeBasedOnChild( mc );
        mc.appended();
        return mc;
        //trace( 'new width ' +  mc.width );
    }
    
    
    public function addChild2( mc: ImageDiv ): ImageDiv
    {
        _dom.appendChild( mc.getInstance() );   
        mc.parent = this;
        updateSizeBasedOnChild2( mc );
        mc.appended();
        return mc;
    }
    
    public function appended()
    {
        
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
    
    
    public function updateSizeBasedOnChild2( mc: ImageDiv )
    {
        if( width < mc.width + mc.x )   set_width( mc.width + mc.x );
        if( height < mc.height + mc.y ) set_height( mc.height + mc.y );
    }
    
    public function updateSizeBasedOnChild( mc: DisplayDiv )
    {
        if( width < mc.width + mc.x )   set_width( mc.width + mc.x );
        if( height < mc.height + mc.y ) set_height( mc.height + mc.y );
    }
    
    
    public var height( get_height, set_height ): Float;
    public function set_height( val: Float ): Float
    {
        _height = val;
        if( _twoD == null )
        {
            _style.paddingTop = val + "px";
        } 
        else
        {
            _style.paddingTop = "0px";
        }
        return val;
    }
    
    public function get_height(): Float
    {
        if( _height == null || _height < _dom.clientHeight )
        {
            _height = _dom.clientHeight;
        }
        return _height;
    }
    
    public var width( get_width, set_width ): Float;
    public function set_width( val: Float ): Float
    {
        _width = val;
        if( _twoD == null )
        {
            _style.paddingLeft = val + "px";
        }
        else
        {
            _style.paddingLeft = "0px";
        }
        return val;
    }
    
    private function get_width(): Float
    {   
        if( _width == null || _width < _dom.clientWidth )
        {
            _width = _dom.clientWidth;
        }
        return _width;
    }
    
    public var y( get_y, set_y ): Float;
    
    private function set_y( val: Float ): Float
    {
        _y = val;
        _style.top = val + "px";
        return val;
    }
    
    private function get_y(): Float
    {
        return _y;
    }
    
    
    public var x( get_x, set_x ): Float;
    
    private function set_x( val: Float ): Float
    {
        _x = val;
        _style.left = val + "px";
        return val;
    }
    
    private function get_x(): Float
    {
        return _x;
    }
    

    private var _canvas:      CanvasElement;
    private var _twoD:        CanvasRenderingContext2D;
    
    public var twoD( get_twoD, null ): CanvasRenderingContext2D;
    
    private function get_twoD(): CanvasRenderingContext2D
    {
        if( _canvas == null ) _canvas = cast _dom;
        if( _twoD == null ) _twoD = _canvas.getContext2d();
        return _twoD;
    }
    
    public var scale( get_scale, set_scale ): Float;
    
    private function get_scale( ):Float
    {
        if( _scale == null )
        {
            _scale = 1;
            _scaleX = 1;
            _scaleY = 1;
        }
        return _scale;
    }
    
    private function set_scale( scale_: Float ): Float
    {
        var scaleStr    =  Std.string( scale_ );
        var str         = "scale("+ scaleStr + ', ' + scaleStr + ")";
        switch( WebBrowser.browserType )
        {
            case WebKitOther, Safari, Chrome:       untyped _style.WebkitTransform  = str;
            case Opera:                             untyped _style.OTransform       = str;
            case FireFox:                           untyped _style.MozTransform     = str;
            case IE:                                affineTrans( scale_, 0, 0, scale_, 0, 0 ) ;
        }
        _scale  = scale_;
        _scaleX = scale_;
        _scaleY = scale_;
        return _scale;
    }
    
    
    public var scaleY( get_scaleY, set_scaleY ): Float;
    
    private function get_scaleY( ):Float
    {
        if( _scaleY == null ) _scaleY = 1;
        return _scaleY;
    }
    
    private function set_scaleY( scaleY_: Float ): Float
    {
        switch( WebBrowser.browserType )
        {
            case WebKitOther, Chrome, Safari:   untyped _style.WebkitTransform  = "scaleY("+ Std.string( scaleY_ ) + ")";
            case Opera:                         untyped _style.OTransform       = "scaleY("+ Std.string( scaleY_ ) + ")";
            case FireFox:                       untyped _style.MozTransform     = "scaleY("+ Std.string( scaleY_ ) + ")";
            case IE:                            affineTrans( scaleX, 0, 0, scaleY_, 0, 0 ) ;
        }
        _scaleY = scaleY_;
        return _scaleY;
    }
    
    

    public var scaleX( get_scaleX, set_scaleX ): Float;
    
    private function get_scaleX( ):Float
    {
        if( _scaleX == null ) _scaleX = 1;
        return _scaleX;
    }
    
    private function set_scaleX( scaleX_: Float ): Float
    {
        // a and d 
        switch( WebBrowser.browserType )
        {
            case WebKitOther, Safari, Chrome:       untyped _style.WebkitTransform  = "scaleX("+ Std.string( scaleX_ ) + ")";
            case Opera:                             untyped _style.OTransform       = "scaleX("+ Std.string( scaleX_ ) + ")";
            case FireFox:                           untyped _style.MozTransform     = "scaleX("+ Std.string( scaleX_ ) + ")";
            case IE:                                affineTrans( scaleX_, 0, 0, scaleY, 0, 0 ) ;
        }
        _scaleX = scaleX_;
        return _scaleX;
    }
    
    
    /*
        
        http://c2.com/cgi/wiki?AffineTransformation
        
        xnew = a*x + c*y + e
        ynew = b*x + d*y + f
    
    */
    public function affineTrans( a: Float, b: Float, c: Float, d: Float, e: Float, f: Float )
    {
        afflines = [a,b,c,d,e,f];
        var mat0 = 'matrix( '+ Std.string( a ) + ', ' + Std.string( b ) + ', ' + Std.string( c ) + ', ' + Std.string( d ) + ', ' ;
        var matrixFirefox = mat0 + Std.string( e ) + 'px, ' + Std.string( e ) + 'px ) ';
        var matrixGeneral = mat0 + Std.string( e ) + Std.string( e ) + ' ) ';
        switch( WebBrowser.browserType )
        {
            
            case WebKitOther, Chrome, Safari:    untyped _style.WebkitTransform  = matrixGeneral;
            case Opera:                          untyped _style.OTransform       = matrixGeneral;
            case FireFox:                        untyped _style.MozTransform     = matrixFirefox ;
            case IE:                             affineTransIE( a, b, c, d, e, f );
            
        }
        
        
    }
    
    
    // credit to http://extremelysatisfactorytotalitarianism.com/blog/?p=922 for code (  I am on a mac so untested! )
    private function affineTransIE( a: Float, b: Float, c: Float, d: Float, e: Float, f: Float )
    {
        
        // set linear transformation via Matrix Filter
        untyped _style.filter = 'progid:DXImageTransform.Microsoft.Matrix(M11=' + a + ', M21=' + b + ', M12=' + c + ', M22=' + d + ', SizingMethod="auto expand")';
        var w2 = width/2;//style.offsetWidth
        var h2 = height/2;//offsetHeight?
        x = Math.round( x + e - ( Math.abs(a) - 1)*w2 + Math.abs(c)*h2 ) ;
        y = Math.round( y + f - Math.abs(b)*w2 + (Math.abs(d) - 1)*h2 ) ;
        
    }
    
    
    public var rotation( get_rotation, set_rotation ): Float;
    
    /*
        xnew = a*x + c*y + e
        ynew = b*x + d*y + f
        xnew = cos(r)*x - sin(r)*y + e
        ynew = sin(r)*x + cos(r)*y + f
    */
    public function set_rotation( angle: Float ): Float
    {
        
        _rotation = angle;
        
        //if( _angle != Std.int( angle ) )
        //{
            _angle = Std.int( angle );
            var rad = _rotation*(Math.PI/180);
            var cos = Math.cos( rad );
            var sin = Math.sin( rad );
            
            switch( WebBrowser.browserType )
            {
                case WebKitOther, Safari, Chrome:   untyped _style.WebkitTransform  = "rotate("+ Std.string( _angle ) + "deg)";
                case Opera:                         untyped _style.OTransform       = "rotate("+ Std.string( _angle ) + "deg)";
                case FireFox:                       untyped _style.MozTransform     = "rotate("+ Std.string( _angle ) + "deg)";
                case IE:                            affineTrans( cos, -sin, sin, cos, 0, 0 );
                //case IE:        untyped _style.filter           = "progid:DXImageTransform.Microsoft.BasicImage(rotation=" + _angle + ")";
            }
            
        //}
        
        return angle;
        
    }
    
    
    public function get_rotation( ): Float
    {
        if( _rotation == null )
        {
            _rotation = 0;
            _angle = 0;
        }
        return _rotation;
    }
    
    
    public var alpha( get_alpha, set_alpha ): Float;
    
    public function get_alpha(): Float
    {
        if( _alpha == null ) _alpha = 1;
        return _alpha;
    }
    
    public function set_alpha( alpha_: Float ): Float
    {
        switch( WebBrowser.browserType )
        {
            case FireFox, Opera, WebKitOther, Chrome, Safari: untyped _style.opacity  =  alpha_ ;
            case IE: untyped _style.filter   = 'alpha(opacity=' + Std.String( Math.round( alpha_*10 ) ) + ')';
        /*
            case IE:    
            var val =     'alpha(opacity' + Std.string( Math.round( alpha_ * 10 ) ) + ')';
                        untyped _style.filter   = val;
                        
                        untyped _dom.filters.item("progid:DXImageTransform.Microsoft.Alpha").opacity =    Std.String( Math.round(alpha_ * 10) );    
                        untyped _style.-ms-filter = 'progid:DXImageTransform.Microsoft.Alpha(opacity=' +  Std.String( Math.round(alpha_*10) ) + ')';             
                        untyped _style.filter   = 'alpha(opacity=' + Std.String( alpha_*10 ) + ')';
        */
        }
        _alpha = alpha_;
        return _alpha;
    }
    
}
