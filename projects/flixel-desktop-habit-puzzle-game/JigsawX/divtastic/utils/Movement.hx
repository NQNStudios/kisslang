
package utils;

class Movement
{
    
    // See this link for more information...
    // http://jonmanatee.blogspot.com/2011/03/moving-beyond-linear-bezier.html
    // you just need to use one for each axis..
    // see http://www.codng.com/2005/07/intersecting-quadcurve2d-part-ii.html
    // and then modify it to go through the point I think penner has a curveThru
    // for instance see my code here:
    // http://forums.swishzone.com/index.php?s=d8b09993f33ccb9361b069fda0bbae89&showtopic=923
    // 
    public static function quadraticBezierThru  (   t:            Float
                                                ,   startPoint:   Float
                                                ,   controlPoint: Float
                                                ,   endPoint:     Float
                                                )
    {
        
        var newControlPoint = ( 2*controlPoint ) - .5*( startPoint + endPoint );
        var u = 1 - t;
        return  Math.pow( u, 2) * startPoint + 2 * u * t * newControlPoint + Math.pow( t, 2 ) * endPoint; 
        
    }
    
    
    public static function quadraticBezier  (   t:                  Float
                                                ,   startPoint:     Float
                                                ,   controlPoint:   Float
                                                ,   endPoint:       Float
                                                )
    {
        
        var u = 1 - t;
        return  Math.pow( u, 2) * startPoint + 2 * u * t * controlPoint + Math.pow( t, 2 ) * endPoint; 
        
    }
    
    
    public static function cubicBezier( t:                Float
                                , startPoint:       Float
                                , controlPoint1:    Float
                                , controlPoint2:    Float
                                , endPoint:         Float 
                                ) 
    {
        
        var u = 1 - t;
        
        return  Math.pow( u, 3 ) * startPoint + 3 * Math.pow( u, 2 ) * t * controlPoint1 +
                3* u * Math.pow( t, 2 ) * controlPoint2 + Math.pow( t, 3 ) * endPoint;
                
    }
    
    
}


