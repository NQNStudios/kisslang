package jigsawx;
import jigsawx.ds.CircleIter;
import jigsawx.math.Vec2;
class OpenEllipse {
    public var rotation:                Float;
    public var beginAngle:              Float;
    public var finishAngle:             Float;
    public var stepAngle:               Float;
    public var centre:                  Vec2;
    public var dimensions:              Vec2;
    private var circleIter:             CircleIter;
    private var _points:                Array<Vec2>;
    public function new(){}
    public function getBegin(): Vec2 {
        return createPoint( centre, dimensions, beginAngle );
    }
    public function getFinish(): Vec2 {
        return createPoint( centre, dimensions, finishAngle );    
    }
    public function getBeginRadius(){
        return pointDistance( centre, getBegin() );
    }
    public function getFinishRadius(){
        return pointDistance( centre, getFinish() );
    }
    private function pointDistance( A: Vec2, B: Vec2 ): Float {
        var dx         = A.x - B.x;
        var dy         = A.y - B.y;
        return Math.sqrt( dx*dx + dy*dy );
    }
    public function setUp(){
        circleIter = CircleIter.pi2pi( beginAngle, finishAngle, stepAngle );
    }
    public function getRenderList(): Array<Vec2> { 
        _points = new Array();
        if( circleIter == null ) setUp();
        _points.push( createPoint( centre, dimensions, beginAngle ) );
        for( theta in CircleIter.pi2pi( beginAngle, finishAngle, stepAngle ).reset() ){
            _points.push( createPoint( centre, dimensions, theta ) );
        }
        return _points;
    }
    public function createPoint( centre: Vec2, dimensions: Vec2, theta: Float ): Vec2 {
        var offSetA     = 3*Math.PI/2 - rotation;// arange so that angle moves from 0... could tidy up dxNew and dyNew!
        var dx          = dimensions.x*Math.sin( theta );// select the relevant sin cos so that 0 is upwards.
        var dy          = -dimensions.y*Math.cos( theta );
        var dxNew       = centre.x -dx*Math.sin( offSetA ) + dy*Math.cos( offSetA );
        var dyNew       = centre.y -dx*Math.cos( offSetA ) - dy*Math.sin( offSetA );
        return new Vec2( dxNew, dyNew );
    }
}
