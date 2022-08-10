package jigsawx ;
import jigsawx.OpenEllipse ;
import jigsawx.JigsawPiece ;
import jigsawx.math.Vec2;
import jigsawx.JigsawSideData;
import kiss.List;
import flixel.math.FlxRandom;
class Jigsawx {
    private var rows:                       Int;
    private var cols:                       Int;
    private var pieces:                     kiss.List<kiss.List<JigsawPiece>>;
    public var jigs:                        Array<JigsawPiece>;
    private var sides:                      Array<Array<JigsawPieceData>>;
    private var lt:                         Float;
    private var rt:                         Float;
    private var rb:                         Float;
    private var lb:                         Float;
    private var dx:                         Float;
    private var dy:                         Float;
    private var length:                     Int;
    public function new(    pieceWidth:            Float
                        ,   pieceHeight:            Float
                        ,   totalWidth: Float
                        ,   totalHeight: Float
                        ,   edgeLeeway:             Float
                        ,   bubbleSize:             Float
                        ,   rows_:          Int
                        ,   cols_:          Int
                        ,   r:              FlxRandom) {
        pieces                              = [];
        jigs                                = [];
        sides                               = [];
        dx                                  = pieceWidth;
        dy                                  = pieceHeight;
        rows                                = rows_;
        cols                                = cols_;
        //corners, theoretically JigsawSideData could be modified to allow these to have a random element.
        var xy                              = new Vec2( edgeLeeway,      edgeLeeway );
        var lt                              = new Vec2( edgeLeeway,      edgeLeeway );
        var rt                              = new Vec2( edgeLeeway + dx, edgeLeeway );
        var rb                              = new Vec2( edgeLeeway + dx, dy + edgeLeeway );
        var lb                              = new Vec2( edgeLeeway,      dy + edgeLeeway );
        length                              = 0;
        var last:   JigsawPieceData; 
        for( row in 0...rows  ){
            last                            = { north: null, east: null, south: null, west: null };
            sides.push( new Array() );
            for( col in 0...cols ){
                var jigsawPiece             = JigsawSideData.halfPieceData(r);
                if( last.east != null )     jigsawPiece.west = JigsawSideData.reflect( last.east );
                if( col == cols - 1 )       jigsawPiece.east = null;
                sides[ row ][ col ]         = jigsawPiece;
                last                        = jigsawPiece;
                length++;
            }
        }
        for( col in 0...cols  ){
            last                            = { north: null, east: null, south: null, west: null };
            for( row in 0...rows ){
                var jigsawPiece             = sides[ row ][ col ];
                if( last.south != null )    jigsawPiece.north = JigsawSideData.reflect( last.south );
                if( row == rows - 1 )       jigsawPiece.south = null;
                last                        = jigsawPiece;
            }
        }
        var jig:    JigsawPiece;
        for( row in 0...rows  ){
            pieces.push( new Array() );
            for( col in 0...cols ){
                jig                         = new JigsawPiece( xy, row, col, bubbleSize, lt, rt, rb, lb, sides[ row ][ col ] );
                pieces[ row ][ col ]        = jig;
                jigs.push( jig );
                xy.x                        += dx;
            }
            xy.x                            = edgeLeeway;
            xy.y                            += dy;
        }

        // Assert that this puzzle's geometry contains the actual corners of the image:
        var corners = ["top left", "top right", "bottom left", "bottom right"];
        
        function contains(p:JigsawPiece, v:Vec2) {
            for (pt in p.getPoints()) {
                if (pt.x == v.x - p.xy.x && pt.y == v.y - p.xy.y)
                    return true;
            }
            return false;
        }
        var containsCorners = [
            contains(pieces[0][0], new Vec2(0, 0)),
            contains(pieces[0][-1], new Vec2(totalWidth, 0)),
            contains(pieces[-1][0], new Vec2(0, totalHeight)),
            contains(pieces[-1][-1], new Vec2(totalWidth, totalHeight))
        ];
        var containsAllCorners = true;
        for (i in 0...corners.length) {
            if (!containsCorners[i]) {
                trace('missing ${corners[i]} corner');
                containsAllCorners = false;
            }
        }
        if (!containsAllCorners) {
            throw "jigsawX geometry doesn't cover the whole image dimensions!";
        }
    }
}
