package core;
import js.html.Element;
import js.html.DivElement;
import js.html.CSSStyleDeclaration;
import js.Browser;
import core.DivDrawing;
import zpartanlite.Enumerables;
/*
//TODO: change some code to use this
enum Compass
{
    North;
    South;
    East;
    West;
}

enum Orientation
{
    Horizontal;
    Vertical;
}
*/
using core.DivDrawing;
class DivDrawing
{
    
    public static function curveFromTo  (   ddiv:           DisplayDiv
                                        ,   p1x:            Float
                                        ,   p1y:            Float
                                        ,   p2x:            Float
                                        ,   p2y:            Float
                                        ,   p3x:            Float
                                        ,   p3y:            Float
                                        ,   _lineWidth:     Int
                                        ,   _lineHeight:    Int
                                        ,   ?c0:            String = '#ff0000' 
                                        ): List<DivElement>
    {
        //Credits for info PIXELWIT see: http://www.pixelwit.com/blog/2007/11/curveto-visualization/
        var p12x:           Float;
        var p12y:           Float;
        var p23x:           Float;
        var p23y:           Float;
        var p123x:          Int;
        var p123y:          Int;
        var ratio:          Float           = 0;
        var _points         = new List<List<Int>>();
        var _grads          = new List<DivElement>();
        var __curve:        DivElement;
        var __point:        List<Int>;
        var __style:        CSSStyleDeclaration;
        var steps:          Int             = 2*Math.ceil( Math.pow( Math.pow( p1x - p3x, 2) + Math.pow( p1y - p3y, 2), 0.5 ) );
        
        var inter                           = new IntIterator( 0, steps );
        var i:              Int;
         
        for( i in inter )
        {
            
            __point                 = new List();
            ratio                   = i/steps;
            p12x                    = p1x + ( p2x - p1x )*ratio;
            p23x                    = p2x + ( p3x - p2x )*ratio;
            p123x                   = Std.int( p12x + ( p23x - p12x )*ratio  );
            p12y                    = p1y + ( p2y - p1y )*ratio;
            p23y                    = p2y + ( p3y - p2y )*ratio;
            p123y                   = Std.int( p12y + ( p23y - p12y )*ratio );
            
            __curve                 = Browser.document.createDivElement(); //Element( 'div'  );//+ ddiv._d++
            _grads.push( __curve );
            __point.add( p123x );
            __point.add( p123y );
            _points.add( __point );
            
            __style                 = __curve.style;
            __style.paddingTop      = _lineHeight + 'px';
            __style.paddingLeft     = _lineWidth + 'px';
            __style.top             = p123y + 'px';
            __style.left            = p123x + 'px';
            
            __style.backgroundColor = c0;
            __style.position        = 'absolute';
            
            ddiv._dom.appendChild( __curve );
            
            
        }
        
        
        // TODO: REMOVE EXTRA POINTS
        var _points2   = new List<List<Int>>();
        var old:        Int                 = 10000;
        
        for( i in _points.iterator() )
        {
            
            if( i.last() != old )
            {
                
                _points2.add(i);
                
            }
            
            old = i.last();
            
        }
        
        
        //return _points2;
        return _grads;
        //Need to add clever code to only create on new points (maybe have a lookup of previous points)
        //Need current pen?
    }
    
    
    // Maybe not best way!!
    public static function drawElipse( ddiv: DisplayDiv,
                                    cx:             Float,
                                    cy:             Float,
                                    rx:             Float,
                                    ry:             Float,
                                    _lineWidth:     Int, 
                                    _lineHeight:    Int
                                ): Array<List<Float>>
    {
        
        var px:     Float;
        var py:     Float;
        var theta:  Float               = ( 2*Math.PI ) /8;
        var points = new Array<List<Float>>();
        
        var iterPoints                  = new IntIterator( 0, 9 );
        
        for( i in iterPoints )
        {
            
            var point = new List<Float>();
            
            point.add( cx + rx*Math.sin( theta*i ));
            point.add( cy + ry*Math.cos( theta*i ));
            points[ i ] = point;
            
        }
        
        var j:      Int = 0;
        while( j < 8  )
        {
            
            ddiv.curveThru( 
                                points[ j ].first(),        points[ j ].last(),
                                points[ j + 1 ].first(),    points[ j + 1 ].last(), 
                                points[ j + 2 ].first(),    points[ j + 2 ].last(),
                                _lineWidth, _lineHeight
                            );
            
            j += 2;
            
        }
        
        return points;
        
    }
    
    
    public static function drawGradient(  ddiv: DisplayDiv,
                                x0:         Int,
                                y0:         Int,
                                w0:         Int,
                                h0:         Int,
                                c1_:        Int,
                                c0_:        Int,
                                ?_minPixel: Int = 1,
                                ?direction: Orientation = null 
                            ): List<DivElement>
    {
        
        var _tot:       Int;
        var _grads      = new List<DivElement>();
        var __grad:     DivElement;
        var __style:    CSSStyleDeclaration;
        
        //var point = drawElipse( x0 + w0/2, y0 + h0/2, w0/2, h0/2, 1 ,1 );
        
        if( direction == Horizontal )
        {
            _tot = Std.int( Math.floor( w0/_minPixel ) );
            var iter = new IntIterator( 0, _tot );
            
            for( i in iter)
            {
                __grad                      = Browser.document.createDivElement(); //Element( 'div' );//+ ddiv._d++
                _grads.add( __grad );
                __style                     = __grad.style;
                __style.height              = h0 + 'px';//__style.paddingTop
                __style.width               = _minPixel + 'px';//__style.paddingLeft
                __style.top                 = y0 + 'px';
                __style.left                = (x0 + _minPixel*i) + 'px';
                __style.position            = 'absolute';
                
                ddiv._dom.appendChild( __grad );
                
            }
            
        }
        else
        {
            
            _tot = Std.int( Math.floor( h0/_minPixel ) );
            var iter = new IntIterator( 0, _tot );
            
            for( i in iter)
            {
                __grad                      = Browser.document.createDivElement(); //Element( 'div' );//+ ddiv._d++
                _grads.add( __grad );
                __style                     = __grad.style;
                __style.height              = _minPixel +'px';
                __style.width               = w0 + 'px';
                __style.top                 = ( y0 + _minPixel*i ) + 'px';
                __style.left                = x0 +'px';
                __style.position            = 'absolute';
                
                ddiv._dom.appendChild( __grad );
                
            }
            
        }
        
        var gradfill = new GradientFiller( _grads );
        gradfill.fill( c0_, c1_ );
        return _grads;
        
    }
    
    
    public static function drawGradElipse( ddiv:        DisplayDiv,
                                            x0:         Int,
                                            y0:         Int,
                                            w0:         Int,
                                            h0:         Int,
                                            c1_:        Int,
                                            c0_:        Int,
                                            ?_minPixel: Int = 1,
                                            ?direction: Orientation = null 
                                            ): List<DivElement>
    {
        
        var _tot:       Int;
        var _grads      = new List<DivElement>();
        var __grad:     DivElement;
        var __style:    CSSStyleDeclaration;
        
        // Elipse Equations
        // x2/a2 + y2/b2 = 1;
        // so...
        // y2 = b2( 1 - x2/a2 )
        
        var rx0     = w0/2;
        //var a2      = Math.pow( rx0, 2 );
        var ry0     = h0/2;
        //var b2      = Math.pow( ry0, 2 );
        var cx0     = x0 + rx0;
        var cy0     = y0 + ry0;
        
        var delta: Float;
        
        
        //trace( 'direction ' + direction ) ;
        if( direction == Horizontal )
        {
            //trace('horizontal') ;
            
            _tot        = Std.int( Math.floor( w0/_minPixel ) );
            var iter    = new IntIterator( 0, _tot );
            
            for( i in iter)
            {
                __grad                      = Browser.document.createDivElement();//( 'div' );//+ ddiv._d++
                _grads.add( __grad );
                __style                     = __grad.style;
                __style.width               = _minPixel + 'px';//__style.paddingLeft
                delta                       = Math.pow( Math.pow( ry0, 2 )*( 1 - Math.pow( i - rx0 , 2 )/Math.pow( rx0, 2 ) ), 0.5 );
                __style.top                 = Std.string( ( cy0 - delta) )+ 'px';
                __style.height              = Std.string( ( 2*delta) )+ 'px';
                __style.left                = (x0 + _minPixel*i) + 'px';
                __style.position            = 'absolute';
                
                ddiv._dom.appendChild( __grad );
                
            }
            
        }
        else
        {
            _tot        = Std.int( Math.floor( h0/_minPixel ) );
            var iter    = new IntIterator( 0, _tot );
            
            for( i in iter)
            {
                __grad                      = Browser.document.createDivElement(); //( 'div' );//+ ddiv._d++
                _grads.add( __grad );
                __style                     = __grad.style;
                __style.height              = _minPixel + 'px';
                delta                       = Math.pow( Math.pow( rx0, 2 )*( 1 - Math.pow( i - ry0 , 2 )/Math.pow( ry0, 2 ) ), 0.5 );
                __style.left                 = Std.string( ( cx0 - delta) )+ 'px';
                __style.width               = Std.string( ( 2*delta) )+ 'px';
                __style.top                 = (y0 + _minPixel*i) + 'px';
                __style.position            = 'absolute';
                
                ddiv._dom.appendChild( __grad );
                
            }
        }
        
        var gradfill = new GradientFiller( _grads );
        gradfill.fill( c0_, c1_ );
        return _grads;
        
    }
    
    
    
    public static function drawGradHexagon( ddiv:       DisplayDiv,
                                        x0:         Int,
                                        y0:         Int,
                                        w0:         Int,
                                        h0:         Int,
                                        c1_:        Int,
                                        c0_:        Int,
                                        ?_minPixel: Int = 1,
                                        ?direction: Orientation = null 
                                    ): List<DivElement>
    {
        var _tot:       Int;
        var _grads      = new List<DivElement>();
        var __grad:     DivElement;
        var __style:    CSSStyleDeclaration;
        
        //trace( 'direction ' + direction ) ;
        if( direction == Horizontal )
        {
            
            _tot        = Std.int( Math.floor( w0/_minPixel ) );
            var iter    = new IntIterator( 0, _tot );
            var deg30 = Math.PI/6;
            
            var smallTriBase = h0/2;
            var smallHypot = smallTriBase/Math.cos(deg30);
            var leftDist = smallHypot*Math.sin(deg30);
            // side length = smallHypot 
            var rightDist = _tot - leftDist;
            
            for( i in iter)
            {
                __grad                      = Browser.document.createDivElement();//( 'div' );//+ ddiv._d++
                _grads.add( __grad );
                __style                     = __grad.style;
                __style.width               = _minPixel + 'px';//__style.paddingLeft
                
                if( i < leftDist )
                {
                    //leftside
                    __style.height          =  Math.floor((h0/leftDist)*(i)) + 'px';
                    __style.top             =  y0 + h0/2 - Math.floor((h0/leftDist)*i/2)+'px';
                } 
                else if( i > rightDist )
                {
                    __style.height          =   Math.floor((h0/leftDist)*(leftDist + rightDist - i )) + 'px';
                    __style.top             =   y0 - Math.floor((h0/leftDist)*(rightDist-i)/2)+'px';
                }
                else
                {
                    __style.height          = cast h0 + 'px';
                    __style.top             = cast y0 + 'px';
                }
                
                
                //__style.top                 = y0 + 'px';
                
                __style.left                = (x0 + _minPixel*i) + 'px';
                __style.position            = 'absolute';
                
                ddiv._dom.appendChild( __grad );
                
            }
            
        }
        else
        {
            
            _tot        = Std.int( Math.floor( h0/_minPixel ) );
            var iter    = new IntIterator( 0, _tot );
            
            for( i in iter)
            {
                __grad                      = Browser.document.createDivElement(); //( 'div' );//+ ddiv._d++
                _grads.add( __grad );
                __style                     = __grad.style;
                __style.height              = _minPixel +'px';
                
                __style.top                 = ( y0 + _minPixel*i ) + 'px';
                if( i > _tot/2 )
                {
                    //draw bottom half
                    __style.width               =  Math.floor((w0/_tot)*(_tot-i+_tot/2)) + 'px';
                    __style.left                = (x0 + w0/2 - Math.floor((w0/_tot)*(_tot-i+_tot/2)/2))+'px';
                } 
                else
                {
                    //draw top half
                    __style.width               =  Math.floor((w0/_tot)*(i+_tot/2)) + 'px';
                    __style.left                = (x0 + w0/2 - Math.floor( (w0/_tot)*(i+_tot/2)/2 ))+'px';
                }
                
                __style.position            = 'absolute';
                
                ddiv._dom.appendChild( __grad );
                
            }
            
        }
        
        var gradfill = new GradientFiller( _grads );
        gradfill.fill( c0_, c1_ );
        return _grads;
        
    }
    
    
    public static function drawGradTriangle(  ddiv: DisplayDiv,
                                x0:         Int,
                                y0:         Int,
                                w0:         Int,
                                h0:         Int,
                                c1_:        Int,
                                c0_:        Int,
                                ?_compass:  Compass = null,
                                ?_minPixel: Int = 1,
                                ?direction: Orientation = null 
                            ): List<DivElement>
    {
        // add code for direction
        var _tot:       Int;
        var _grads      = new List<DivElement>();
        var __grad:     DivElement;
        var __style:    CSSStyleDeclaration;
        
        if( direction == Horizontal )
        {
            //trace('horizontal') ;
            _tot        = Std.int( Math.floor( w0/_minPixel ) );
            var iter    = new IntIterator( 0, _tot );
            
            for( i in iter)
            {
                __grad                      = Browser.document.createDivElement(); //Element( 'div' );//+ ddiv._d++
                _grads.add( __grad );
                __style                     = __grad.style;
                //__style.height              = h0 + 'px';//__style.paddingTop
                __style.width               = _minPixel + 'px';//__style.paddingLeft
                if( _compass == West )
                {
                    __style.height          =  Math.floor((h0/_tot)*(_tot-i)) + 'px';
                    __style.top             = (y0 + h0/2 - Math.floor((h0/_tot)*(_tot-i))/2)+'px';
                } 
                else
                {
                    __style.height          =  Math.floor((h0/_tot)*i) + 'px';
                    __style.top             = (y0 + h0/2 - Math.floor((h0/_tot)*i)/2)+'px';
                }
                /*
                
                
                __style.top                 = y0 + 'px';
                */
                __style.left                = (x0 + _minPixel*i) + 'px';
                __style.position            = 'absolute';
                
                ddiv._dom.appendChild( __grad );
                
            }
            
        }
        else
        {
            
            _tot        = Std.int( Math.floor( h0/_minPixel ) );
            var iter    = new IntIterator( 0, _tot );
            
            for( i in iter)
            {
                __grad                      = Browser.document.createDivElement(); //Element( 'div' );//+ ddiv._d++
                _grads.add( __grad );
                __style                     = __grad.style;
                __style.height              = _minPixel +'px';
                
                __style.top                 = ( y0 + _minPixel*i ) + 'px';
                if( _compass == South )
                {
                    __style.width               =  Math.floor((w0/_tot)*(_tot-i)) + 'px';
                    __style.left                = (x0 + w0/2 - Math.floor((w0/_tot)*(_tot-i))/2)+'px';
                } 
                else
                {
                    __style.width               =  Math.floor((w0/_tot)*i) + 'px';
                    __style.left                = (x0 + w0/2 - Math.floor((w0/_tot)*i)/2)+'px';
                }
                
                __style.position            = 'absolute';
                
                ddiv._dom.appendChild( __grad );
                
            }
            
        }
        
        var gradfill = new GradientFiller( _grads );
        gradfill.fill( c0_, c1_ );
        return _grads;
    }
    
    
    public static function lineFromTo( ddiv: DisplayDiv,
                                    p1x:            Float, 
                                    p1y:            Float, 
                                    p2x:            Float, 
                                    p2y:            Float, 
                                    _lineWidth:     Int, 
                                    _lineHeight:    Int,
                                    ?c0: String = '#ff0000' 
                                ): List<DivElement>
    {
        
        var _grads          = new List<DivElement>();
        var __grad:         DivElement;
        var __style:        CSSStyleDeclaration;
        var ratio:          Float;
        
        if( p1x - p2x == 0 )
        {
            
            var steps:          Int     =   2*Math.ceil(Math.abs(p1y - p2y));
            
        }
        else if(  p1y - p2y == 0 )
        {
            
            var steps:          Int     =   2*Math.ceil(Math.abs(p1x - p2x));
            
        }
        
        var steps:          Int     =   Math.ceil( Math.pow( Math.pow( p1x - p2x, 2 ) + Math.pow( p1y - p2y, 2 ), 0.5 ) );
        var px:             Int;
        var py:             Int;
        
        var inter = new IntIterator( 0, steps );
        for( i in inter )
        {
            ratio                   = i/steps;
            px                      = Std.int(p1x + ( p2x - p1x )*ratio  );
            py                      = Std.int(p1y + ( p2y - p1y )*ratio  );
            __grad                  = Browser.document.createDivElement(); //createElement( 'div' );//+ ddiv._d++
            
            _grads.add( __grad );
            
            __style                 = __grad.style;
            __style.paddingTop      = _lineHeight + 'px';
            __style.paddingLeft     = _lineWidth + 'px';
            __style.top             = py + 'px';
            __style.left            = px + 'px';
            __style.backgroundColor = c0;
            __style.position        = 'absolute';
            
            ddiv._dom.appendChild( __grad );
            
        }
        return _grads;
        
    }
    
    
    
    
    public static function curveThru(   ddiv:           DisplayDiv
                                    ,   p1x:            Float
                                    ,   p1y:            Float
                                    ,   p2x:            Float
                                    ,   p2y:            Float
                                    ,   p3x:            Float
                                    ,   p3y:            Float
                                    ,   _lineWidth:     Int
                                    ,   _lineHeight:    Int
                                    ,   ?c0:            String
                            ): List<DivElement>
    {
        
        var newx: Float = ( ( 2*p2x ) - .5*( p1x + p3x ) );
        var newy: Float = ( ( 2*p2y ) - .5*( p1y + p3y ) );
        
        return  ddiv.curveFromTo( 
                                p1x, 
                                p1y, 
                                newx, 
                                newy, 
                                p3x, 
                                p3y, 
                                _lineWidth, 
                                _lineHeight,
                                c0
                            );
        
    }
    
}
