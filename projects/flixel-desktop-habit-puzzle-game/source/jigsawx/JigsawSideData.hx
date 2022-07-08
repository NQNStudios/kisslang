package jigsawx;
import flixel.math.FlxRandom;
typedef JigsawPieceData = {
    var north:     JigsawSideData;
    var east:    JigsawSideData;
    var south:    JigsawSideData;
    var west:    JigsawSideData;
}
enum Bubble{
    IN;
    OUT;
}
class JigsawSideData{
    // if the nobble is IN OUT or null ( flat side )
    public var bubble:          Bubble;
    //offsets random multiplier
    public var squew:           Float;
    // inout random multiplier
    public var inout:           Float;
    //ellipse width and height random multiplier, drawn in the order left, centre, right
    public var leftWide:        Float;
    public var leftHi:          Float;
    public var centreWide:      Float;
    public var centreHi:        Float;
    public var rightWide:       Float;
    public var rightHi:         Float;
    // returns half a jigsawPieceData, the other side is populated from piece above and from left
    public static function halfPieceData(r:FlxRandom): JigsawPieceData{
        #if !noRandom return  { north: null, east: create(r), south: create(r), west: null };
        // Test use -D noRandom
        #else return  { north: null, east: createSimple(r), south: createSimple(r), west: null };
        #end
    }
    private static function createBubble(r:FlxRandom): Bubble { 
        return r.bool() ? IN: OUT; 
    }
    private static function swapBubble( bubble: Bubble ): Bubble {
        if( bubble == OUT ) return IN;
        if( bubble == IN ) return OUT;
        return null;
    }
    // reflect side
    public static function reflect( j: JigsawSideData ): JigsawSideData {
        var side            = new JigsawSideData();
        side.bubble         = swapBubble( j.bubble );
        //left right or up dawn offset.
        side.squew          = j.squew;
        // in out
        side.inout          = j.inout;
        // radii of ellipses
        side.leftWide       = j.rightWide;
        side.leftHi         = j.rightHi;
        side.centreWide     = j.centreWide;
        side.centreHi       = j.centreHi;
        side.rightWide      = j.leftWide;
        side.rightHi        = j.leftHi;
        return side;
    }
    // when you want to test no random.
    public static function createSimple(r:FlxRandom): JigsawSideData {
        var side            = new JigsawSideData();
        side.bubble         = createBubble(r);
        //left right or up dawn offset.
        side.squew          = 0.5;
        // in out
        side.inout          = 0.5;
        // radii of ellipses
        side.leftWide       = 0.5;
        side.leftHi         = 0.5;
        side.centreWide     = 0.5;
        side.centreHi       = 0.5;
        side.rightWide      = 0.5;
        side.rightHi        = 0.5;
        return side;
    }
    public static function create(r:FlxRandom): JigsawSideData {
        var side            = new JigsawSideData();
        side.bubble         = createBubble(r);
        //left right or up dawn offset.
        side.squew          = r.float();
        // in out
        side.inout          = r.float();
        // radii of ellipses
        side.leftWide       = r.float();
        side.leftHi         = r.float();
        side.centreWide     = r.float();
        side.centreHi       = r.float();
        side.rightWide      = r.float();
        side.rightHi        = r.float();
        return side;
    }
    // use create instead
    private function new(){}
}
