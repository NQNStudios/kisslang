package jigsawx;
import jigsawx.JigsawSideData;
import jigsawx.math.Vec2;
import jigsawx.JigsawMagicNumbers;
enum Compass{
    NORTH;
    SOUTH;
    EAST;
    WEST;
}
class JigsawPiece{
    public var enabled:                 Bool;
    private var curveBuilder:           OpenEllipse;
    private var stepAngle:              Float;
    private var centre:                 Vec2;
    private var points:                 Array<Vec2>;
    public var sideData:                JigsawPieceData;
    private var first:                  Vec2;
    public var xy:                      Vec2;
    public var wh:                      Vec2;
    public var row:                     Int;
    public var col:                     Int;
    public function new(    xy_:        Vec2
                        ,   row:        Int
                        ,   col:        Int
                        ,   lt:         Vec2,    rt:    Vec2,   rb:     Vec2,   lb:     Vec2
                        ,   sideData_:  JigsawPieceData 
                        ){
        enabled                         = true;
        xy                              = new Vec2( xy_.x, xy_.y );
        sideData                        = sideData_;
        points                          = [];
        stepAngle                       = JigsawMagicNumbers.stepSize*Math.PI/180;
        first                           = lt;
        // NORTH side
        if( sideData.north != null )    createVertSide( lt, rt, sideData.north, NORTH );
        points.push( rt );
        // EAST side
        if( sideData.east != null )     createHoriSide( rt, rb, sideData.east, EAST );
        points.push( rb );
        // SOUTH side
        if( sideData.south != null )    createVertSide( rb, lb, sideData.south, SOUTH );
        points.push( lb );
        // WEST side
        if( sideData.west != null )     createHoriSide( lb, lt, sideData.west, WEST );
        points.push( lt );

        var maxX = 0.0;
        var maxY = 0.0;
        for (point in points) {
            if (point.x > maxX)
                maxX = point.x;
            if (point.y > maxY)
                maxY = point.y;
        }
        wh = new Vec2(maxX, maxY);
    }
    public function getPoints(): Array<Vec2> {
        return points;
    }
    public function getFirst(): Vec2 {
        return first;
    }
    private function createVertSide(    A:          Vec2
                                    ,   B:          Vec2
                                    ,   side:       JigsawSideData
                                    ,   compass:    Compass
                                    ){
        drawSide(       A.x + ( B.x - A.x )/2 + JigsawMagicNumbers.dMore/2  - side.squew*( JigsawMagicNumbers.dMore )
                ,       A.y + ( B.y - A.y )/2 + JigsawMagicNumbers.dinout/2 - side.inout*( JigsawMagicNumbers.dinout )
                ,       side
                ,       compass
                );
    }
    private function createHoriSide (   A:          Vec2
                                    ,   B:          Vec2
                                    ,   side:       JigsawSideData
                                    ,   compass:    Compass
                                    ){
        
        drawSide(       A.x + ( B.x - A.x )/2 + JigsawMagicNumbers.dinout/2 - side.inout*( JigsawMagicNumbers.dinout )
                ,       A.y + ( B.y - A.y )/2 + JigsawMagicNumbers.dMore/2  - side.squew*( JigsawMagicNumbers.dMore )
                ,       side
                ,       compass 
                );
    }
    private function drawSide( dx: Float, dy: Float, sideData: JigsawSideData, compass: Compass ){
        var halfPI                      = Math.PI/2;
        var dimensions                  = new Vec2();
        var offsetCentre                = new Vec2();
        var bubble                      = sideData.bubble;
        centre = 
        switch( compass )
        {
            case NORTH:     new Vec2( dx,                                                   dy + 6*switch bubble{ case IN: 1; case OUT: -1; }   );
            case EAST:      new Vec2( dx - 6*switch bubble{ case IN: 1; case OUT: -1; },    dy                                                  );
            case SOUTH:     new Vec2( dx,                                                   dy - 6*switch bubble{ case IN: 1; case OUT: -1; }   );
            case WEST:      new Vec2( dx + 6*switch bubble{ case IN: 1; case OUT: -1; },    dy                                                  );
        }
        curveBuilder                    = new OpenEllipse();
        curveBuilder.centre             = centre;
        // large Arc
        dimensions.x                    = ( 1 + ( 0.5 - sideData.centreWide )/2 ) *  JigsawMagicNumbers.ellipseLargex;
        dimensions.y                    = ( 1 + ( 0.5 - sideData.centreHi )/2 ) *    JigsawMagicNumbers.ellipseLargex;
        curveBuilder.dimensions         = dimensions;
        curveBuilder.beginAngle         = Math.PI/8;
        curveBuilder.finishAngle        = -Math.PI/8;
        curveBuilder.stepAngle          = stepAngle;
        curveBuilder.rotation           = switch bubble { case IN: 0; case OUT: Math.PI; }
        switch( compass ){
            case NORTH:
            case EAST:      curveBuilder.rotation += halfPI;
            case SOUTH:     curveBuilder.rotation += Math.PI; 
            case WEST:      curveBuilder.rotation += 3*halfPI; 
        }
        var secondPoints                = curveBuilder.getRenderList();
        if( bubble == IN )              secondPoints.reverse();
        var theta                       = curveBuilder.beginAngle - curveBuilder.finishAngle + Math.PI;
        var cosTheta                    = Math.cos( theta );
        var sinTheta                    = Math.sin( theta );
        var hyp                         = curveBuilder.getBeginRadius();
        // left Arc
        dimensions.x                    = ( 1 + ( 0.5 - sideData.leftWide )/2 ) *   JigsawMagicNumbers.ellipseSmallx;
        dimensions.y                    = ( 1 + ( 0.5 - sideData.leftHi )/2 ) *     JigsawMagicNumbers.ellipseSmally;
        curveBuilder.dimensions         = dimensions;
        curveBuilder.beginAngle         = halfPI;
        curveBuilder.finishAngle        = -halfPI;
        curveBuilder.stepAngle          = stepAngle;
        curveBuilder.rotation           = theta + switch bubble { case IN: 0; case OUT: halfPI; };
        switch( compass ){
            case NORTH:
            case EAST:      curveBuilder.rotation += halfPI;
            case SOUTH:     curveBuilder.rotation += Math.PI; 
            case WEST:      curveBuilder.rotation += 3*halfPI; 
        }
        var hypLeft                     = hyp + curveBuilder.dimensions.x;
        switch( compass ){ 
            case NORTH:
                offsetCentre.x          = centre.x + hypLeft*cosTheta;
                offsetCentre.y          = centre.y + switch bubble { case IN: hypLeft*sinTheta; case OUT: -hypLeft*sinTheta; }
            case EAST:
                offsetCentre.x          = centre.x + switch bubble { case IN: -hypLeft*cosTheta; case OUT: hypLeft*cosTheta; }
                offsetCentre.y          = centre.y + hypLeft*sinTheta;
            case SOUTH:
                offsetCentre.x          = centre.x - hypLeft*cosTheta;
                offsetCentre.y          = centre.y - switch bubble { case IN: hypLeft*sinTheta; case OUT: - hypLeft*sinTheta; }
            case WEST:
                offsetCentre.x          = centre.x + switch bubble { case IN: hypLeft*cosTheta; case OUT: -hypLeft*cosTheta; }
                offsetCentre.y          = centre.y - hypLeft*sinTheta;
        }
        curveBuilder.centre             = offsetCentre;
        var startPoint                  = curveBuilder.getBegin();
        var firstPoints                 = curveBuilder.getRenderList();
        if( sideData.bubble == OUT )    firstPoints.reverse();
        firstPoints.pop();
        firstPoints.pop();
        secondPoints.shift();
        secondPoints.shift();
        secondPoints.shift();
        points                          =  points.concat( firstPoints.concat( secondPoints ) );
        // right Arc
        dimensions.x                    = ( 1 + ( 0.5 - sideData.rightWide )/2 ) *  JigsawMagicNumbers.ellipseSmallx;
        dimensions.y                    = ( 1 + ( 0.5 - sideData.rightHi )/2 ) *    JigsawMagicNumbers.ellipseSmally;
        curveBuilder.dimensions         = dimensions;
        curveBuilder.beginAngle         = halfPI;
        curveBuilder.finishAngle        = -halfPI;
        curveBuilder.stepAngle          = stepAngle;
        curveBuilder.rotation           = theta + switch bubble { case IN: - halfPI; case OUT: Math.PI; };
        switch( compass ){
            case NORTH:
            case EAST:      curveBuilder.rotation += halfPI;
            case SOUTH:     curveBuilder.rotation += Math.PI; 
            case WEST:      curveBuilder.rotation += 3*halfPI; 
        }
        var hypRight                    = hyp + curveBuilder.dimensions.x;
        switch( compass ){ 
            case NORTH:
                offsetCentre.x          = centre.x - hypRight*cosTheta;
                offsetCentre.y          = centre.y + switch bubble { case IN: hypRight*sinTheta; case OUT: -hypRight*sinTheta; };
            case EAST:
                offsetCentre.x         = centre.x + switch bubble { case IN: -hypLeft*cosTheta; case OUT: hypLeft*cosTheta; }
                offsetCentre.y         = centre.y - hypLeft*sinTheta;
            case SOUTH:
                offsetCentre.x          = centre.x + hypRight*cosTheta;
                offsetCentre.y          = centre.y - switch bubble { case IN: hypRight*sinTheta; case OUT: -hypRight*sinTheta; };
            case WEST:
                offsetCentre.x         = centre.x + switch bubble { case IN: hypLeft*cosTheta; case OUT: -hypLeft*cosTheta; }
                offsetCentre.y         = centre.y + hypLeft*sinTheta;
        }
        curveBuilder.centre             = offsetCentre;
        var    thirdPoints              = curveBuilder.getRenderList();
        if( bubble == OUT )             thirdPoints.reverse();
        thirdPoints.shift();
        thirdPoints.shift();
        points.pop();
        points.pop();
        points.pop();
        points                          = points.concat( thirdPoints );
    }
}
