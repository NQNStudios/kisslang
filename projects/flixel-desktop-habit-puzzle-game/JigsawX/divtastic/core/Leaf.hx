
package core;

import js.Lib;
import core.Leaf;
import js.html.CanvasElement;
import js.html.CanvasRenderingContext2D;
import js.html.ImageElement;
import js.Browser;
using core.Leaf;


typedef Point2D = 
{
    var x: Int;
    var y: Int;
} 
typedef Axis = 
{
    var beta: Float;
    var hyp: Float;
}


class Leaf
{
    public static var showBoxes:    Bool = false;
    public static var showCrosses:  Bool = false;
	private static var canvas:      CanvasElement;
    private static var surface:     CanvasRenderingContext2D;
    private static var imageTemp:   ImageElement;
    public static var testSurface:  CanvasRenderingContext2D;
    public var parent:              Leaf;
    public var name:                String;
    // source
    public var image( default, set_image ):  ImageElement;
    // image position
    public var x:           Int;
    public var y:           Int;
    // image dim
    public var w ( default, null ):    Int;
    public var h ( default, null ):    Int;
    // rotation point
    public var rx:         Float;
    public var ry:         Float;
    // angle in radians
    public var theta( default, set_theta ): Float;
    
    // store by depth
    public var leaves:                      Array<Leaf>;
    public var leafCentre:                  Array<Point2D>;
    public var leafAxis:                    Array<Axis>;
    public var left( default, default ):    Int;
    public var top( default, default ):     Int;
    public var wid( default, null ):        Int;
    public var hi( default, null ):         Int;    
    public var cx( default, null ):         Float;
    public var cy( default, null ):         Float;
    public var hyp:                         Float;
    public var beta:                        Float;
    var dx:                                 Float;
    var dy:                                 Float;
    public var offset:                      Point2D;
    
    public function set_image( image_: ImageElement ): ImageElement
    {
        image   = image_;
        w       = image.width;
		h       = image.height;
		
		return image;
    }
    
    
    public function set_theta( theta_: Float ): Float 
    {
        if( theta == null ) theta = 0;
        var dTheta = theta - theta_;
        theta = theta_;
        if( rx == null ) rx = 0;
        if( ry == null ) ry = 0;
    	var sine            = Math.sin( theta );
    	var cos             = Math.cos( theta );

    	// new dimensions
        wid                 = Std.int( Math.abs( w*cos ) + Math.abs( h*sine ) );
    	hi                  = Std.int( Math.abs( w*sine ) + Math.abs( h*cos ) ); 
        // new centre
        cx                  = wid/2;
    	cy                  = hi/2;
        
        // calculates offset of pivot
        offset              = pivotOffset();
        left                = Std.int( x + offset.x );
        top                 = Std.int( y + offset.y );
        
        return theta_;
        
    }
    
    public function addLeaf( leaf: Leaf, rx_: Int, ry_: Int )
    {
        leafCentre.push( { x: rx_, y: ry_ } );
	    leaves.push( leaf );
    }   
    
    public function rotate( theta_: Float, rx_: Float, ry_: Float )
    {
        rx = rx_;
        ry = ry_;
        theta = theta_;
        for( i in 0...leafCentre.length )
        {
            if( leafAxis[i] == null )
            {
                var dx2     = rx - leafCentre[i].x;
    	        var dy2     = ry - leafCentre[i].y;
    	        leafAxis.push( { beta: Math.atan2( dy2, dx2 ), hyp: Math.pow( dx2*dx2 + dy2*dy2, 0.5 ) } ); 
    	    }
        }
    }
    
	public function new( image_: ImageElement, ?x_: Int = 0, ?y_: Int = 0 )
	{
	    leaves  = [];
	    leafAxis = new Array<Axis>();
	    leafCentre = new Array<Point2D>();
		image   = image_;
		x       = x_;
		y       = y_;
        
	}
	
	public function pivotOffset(): Point2D
	{
	    var dx      = w/2 - rx;
	    var dy      = h/2 - ry;
	    // calculates the angle from the old centre to the pivot point.
	    beta        = Math.atan2( dy, dx );
	    // calculates the diagonal distance from the old centre to the pivot point.
	    hyp         = Math.pow( dx*dx + dy*dy, 0.5 );
        var bt      = beta + theta;
        
	    return  {   x: Std.int( rx - cx + hyp*Math.cos( bt ) )
	            ,   y: Std.int( ry - cy + hyp*Math.sin( bt ) )
	            };
	}
	
	public function renderOn( surfaceOut: CanvasRenderingContext2D )
	{
	    
	    if( canvas == null )
	    {
	        // creates a canvas if one does not exist
	        var dom    = Browser.document.createElement('Canvas');
		    canvas              = cast dom;
            surface             = untyped canvas.getContext('2d');
            imageTemp           = untyped canvas;
	    }
	    
	    canvas.width        = wid;
        canvas.height       = hi;
	    // position canvas so whole rotation fits. 
        surface.translate( cx, cy );
        surface.rotate( theta );
        // draws to the temporary canvas
        surface.drawImage( image, -w/2, -h/2, w, h );
        //surfaceOut.clearRect( 0,0,768,1000);
        surfaceOut.drawImage( imageTemp, left, top, wid, hi ); 
        //var rotPoint = { x: Std.int( left + cx - hyp*Math.cos( beta + theta ) ), y: Std.int(top + cy - hyp*Math.sin( beta + theta ) ) };
        var bt = beta + theta;
        var rotX = left + cx - hyp*Math.cos( bt );
        var rotY = top  + cy - hyp*Math.sin( bt );
        // show top cross
        if( showCrosses ) surfaceOut.quickCross( 
                                        { x: Std.int( rotX )
                                        , y: Std.int( rotY ) }
                                                );
        // show boxes
        if( showBoxes ) addBox( surfaceOut, left, top, wid, hi );
        
	    surface.rotate( -theta );
        surface.translate( -cx, -cy );
        surface.clearRect( 0, 0, Math.ceil( cx ), Math.ceil( cy ) );
        
        for( i in 0...leaves.length ) 
        {
            var axis                = leafAxis[ i ];
            var leaf                = leaves[ i ];
            var loff                = leaf.offset;
            var hyp2                = axis.hyp;
            var b2t                 = axis.beta + theta;
            
            // show bottom cross
            if( showCrosses ) surfaceOut.quickCross( 
                                    { x: Std.int( rotX - hyp2*Math.cos( b2t ) )
                                    , y: Std.int( rotY - hyp2*Math.sin( b2t ) ) }
                                                    );
                                                   
            
            leaf.left = Std.int( rotX - hyp2*Math.cos( b2t ) + loff.x - leaf.rx ) ;
            leaf.top  = Std.int( rotY - hyp2*Math.sin( b2t ) + loff.y - leaf.ry );
            
            leaves[ i ].renderOn( surfaceOut );
            
	    }   
	    
    		
	}	    
    //public var rotPoint: Point2D;
    
	public static inline function addBox(   surfaceOut: CanvasRenderingContext2D
	                                    ,   left:       Int
	                                    ,   top:        Int
	                                    ,   wid:        Int
	                                    ,   hi:         Int 
	                                    )
	{
        surfaceOut.beginPath();
        surfaceOut.strokeStyle     = '#00000f';
        surfaceOut.lineWidth       = 0.1;
        surfaceOut.moveTo( left, top );
        surfaceOut.lineTo( left + wid, top );
        surfaceOut.lineTo( left + wid, top + hi );
        surfaceOut.lineTo( left, top + hi );
        surfaceOut.lineTo( left, top );
        surfaceOut.stroke(); 
	}
	public static inline function quickCross( surface: CanvasRenderingContext2D, p: Point2D )
	{
	    surface.beginPath();
	    surface.strokeStyle     = '#f000f0';
        surface.lineWidth       = 2;
	    surface.moveTo( p.x - 5, p.y );
        surface.lineTo( p.x + 5, p.y );
        surface.moveTo( p.x, p.y - 5 );
        surface.lineTo( p.x, p.y + 5 );
        surface.stroke();
	}
	
	
}
