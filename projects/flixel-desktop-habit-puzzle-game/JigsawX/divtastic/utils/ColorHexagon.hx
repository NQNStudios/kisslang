
package utils;
import core.DisplayDiv;
import zpartanlite.Enumerables;
import js.html.DivElement;
using core.DivDrawing;
typedef ColorHex =
{
    var div:            DisplayDiv;
    var firstColor:     Int;
    var secondColor:    Int;
    var xStart:         Float;
    var yStart:         Float;
    var hexGrad:        List<DivElement>;
}

enum ColorPallet
{
    
    Light;
    Dark;
    
}



class ColorHexagon
{
    
    private var _holder:        DisplayDiv;
    private var _firstColor:    Int;
    private var _secondColor:   Int;
    public var hexagons:        Array<ColorHex>;
    
    public function new(    holder_:        DisplayDiv
                        ,   offX:           Int
                        ,   offY:           Int
                        ,   hexWidth:       Int
                        ,   hexHeight:      Int
                        ,   first_:         ColorPallet
                        ,   second_:        ColorPallet
                        ,   orientation:    Orientation
                        )
    {
        
        switch( first_ )
        {
            case ColorPallet.Light:
                _firstColor = 1;
            case ColorPallet.Dark:
                _firstColor = 0;
        }
        
        switch( second_ )
        {
            case ColorPallet.Light:
                _secondColor = 1;
            case ColorPallet.Dark:
                _secondColor = 0;
        }
        
        _holder = holder_;
        var colors: Array<Array<Array<Int>>> = [ 
                        [       [ 0xff00ff, 0xff00ff ]
                            ,   [ 0xCC00FF, 0xCC00FF ]
                            ,   [ 0x9900FF, 0x6600FF ]
                            ,   [ 0x6600FF, 0x6600ff ]
                            ,   [ 0x3300ff, 0x3300ff ]
                            ,   [ 0x0000ff, 0x0000ff ]
                        ],
                        [       [ 0xff00cc, 0xff00cc ]
                            ,   [ 0xcc00cc, 0xff33ff ]
                            ,   [ 0x9900cc, 0xcc33ff ]
                            ,   [ 0x6600cc, 0x9933ff ]
                            ,   [ 0x3300cc, 0x6633ff ]
                            ,   [ 0x0000cc, 0x3333ff ]
                            ,   [ 0x0033ff, 0x0033ff ]
                        ],
                        [       [ 0xff0099, 0xff0099 ]
                            ,   [ 0xcc0099, 0xff33cc ]
                            ,   [ 0x990099, 0xff66ff ]
                            ,   [ 0x660099, 0xcc66ff ]
                            ,   [ 0x330099, 0x9966ff ]
                            ,   [ 0x000099, 0x6666ff ]
                            ,   [ 0x0033cc, 0x3366ff ]
                            ,   [ 0x0066ff, 0x0066ff ]
                        ],
                        [       [ 0xff0066, 0xff0066 ]
                            ,   [ 0xcc0066, 0xff3399 ]
                            ,   [ 0x990066, 0xff66cc ]
                            ,   [ 0x660099, 0xff99ff ]
                            ,   [ 0x330066, 0xcc99ff ]
                            ,   [ 0x000066, 0x9999ff ]
                            ,   [ 0x003399, 0x6699ff ]
                            ,   [ 0x0066cc, 0x3399ff ]
                            ,   [ 0x0099ff, 0x0099ff ]
                        ],
                        [       [ 0xff0033, 0xff0033 ]
                            ,   [ 0xcc0033, 0xff3366 ]
                            ,   [ 0x990033, 0xff6699 ]
                            ,   [ 0x660033, 0xff99cc ]
                            ,   [ 0x330033, 0xffccff ]
                            ,   [ 0x000033, 0xccccff ]
                            ,   [ 0x003366, 0x99ccff ]
                            ,   [ 0x006699, 0x66ccff ]
                            ,   [ 0x0099cc, 0x33ccff ]
                            ,   [ 0x00ccff, 0x00ccff ]
                        ],
                        [       [ 0xff0000, 0xff0000 ]
                            ,   [ 0xcc0000, 0xff3333 ]
                            ,   [ 0x990000, 0xff6666 ]
                            ,   [ 0x660000, 0xff9999 ]
                            ,   [ 0x330000, 0xffcccc ]
                            ,   [ 0x000000, 0xffffff ]
                            ,   [ 0x003333, 0xccffff ]
                            ,   [ 0x006666, 0x99ffff ]
                            ,   [ 0x009999, 0x66ffff ]
                            ,   [ 0x00cccc, 0x33ffff ]
                            ,   [ 0x00ffff, 0x00ffff ]
                        ],
                        [       [ 0xff3300, 0xff3300 ]
                            ,   [ 0xcc3300, 0xff6633 ]
                            ,   [ 0x993300, 0xff9966 ]
                            ,   [ 0x663300, 0xffcc99 ]
                            ,   [ 0x333300, 0xffffcc ]
                            ,   [ 0x003300, 0xccffcc ]
                            ,   [ 0x006633, 0x99ffcc ]
                            ,   [ 0x009966, 0x66ffcc ]
                            ,   [ 0x00cc99, 0x33ffcc ]
                            ,   [ 0x00ffcc, 0x00ffcc ]
                        ],
                        [       [ 0xff6600, 0xff6600 ]
                            ,   [ 0xcc6600, 0xff9933 ]
                            ,   [ 0x996600, 0xffcc66 ]
                            ,   [ 0x666600, 0xffff99 ]
                            ,   [ 0x336600, 0xccff99 ]
                            ,   [ 0x006600, 0x99ff99 ]
                            ,   [ 0x009933, 0x66ff99 ]
                            ,   [ 0x00cc66, 0x33ff99 ]
                            ,   [ 0x00ff99, 0x00ff99 ]
                        ],
                        [       [ 0xff9900, 0xff9900 ]
                            ,   [ 0xcc9900, 0xffcc33 ]
                            ,   [ 0x999900, 0xffff66 ]
                            ,   [ 0x669900, 0xccff66 ]
                            ,   [ 0x339900, 0x99ff66 ]
                            ,   [ 0x009900, 0x66ff66 ]
                            ,   [ 0x00cc33, 0x33ff99 ]
                            ,   [ 0x00ff66, 0x00ff66 ]
                        ],
                        [       [ 0xffcc00, 0xffcc00 ]
                            ,   [ 0xcccc00, 0xffff33 ]
                            ,   [ 0x99cc00, 0xccff33 ]
                            ,   [ 0x66cc00, 0x99ff33 ]
                            ,   [ 0x33cc00, 0x66ff33 ]
                            ,   [ 0x00cc00, 0x33ff33 ]
                            ,   [ 0x00ff33, 0x00ff33 ]
                        ],
                        [       [ 0xffff00, 0xffff00 ]
                            ,   [ 0xccff00, 0xccff00 ]
                            ,   [ 0x99ff00, 0x99ff00 ]
                            ,   [ 0x66ff00, 0x66ff00 ]
                            ,   [ 0x33ff00, 0x33ff00 ]
                            ,   [ 0x00ff00, 0x00ff00 ]
                        ]
                        ];
        
        var stepX   = hexWidth;//15;//30;//*2;
        var stepY   = hexHeight;//12;//25;//*2;
        var initX   = offX;//200;
        var initY   = offY;//200;
        var startY  = initY;
        var hex: DisplayDiv;
        var hexGrad: List<DivElement>;
        hexagons = new Array();
        for( i in 0...6 )
        {
            
            for( j in 0...colors[ i ].length )
            {
                
                hex         = new DisplayDiv();
                _holder.addChild( hex );
                hex.width   = Std.int( stepX );
                hex.height  = Std.int( stepY );
                hex.x       = initX;
                hex.y       = initY;
                hexGrad = hex.drawGradHexagon(    0
                                    ,   0
                                    ,   Std.int( stepX )
                                    ,   Std.int( stepY )
                                    ,   colors[ i ][ j ][ _firstColor ]
                                    ,   colors[ i ][ j ][ _secondColor ]
                                    ,   1
                                    ,   orientation 
                                    ) ;
                initY += stepY;
                hexagons.push(  {   div:            hex
                                ,   firstColor:     colors[ i ][ j ][ _firstColor ]
                                ,   secondColor:    colors[ i ][ j ][ _secondColor ] 
                                ,   xStart:         hex.x
                                ,   yStart:         hex.y
                                ,   hexGrad:        hexGrad
                                }
                            );
            }
            
            initX   += Std.int( stepX*0.7 );
            startY  -= Std.int( stepY/2 );
            initY   = startY;
            
        }
        
        initY += Std.int( stepY );
        startY = initY;
        
        for( i in 6...11 )
        {
            
            for( j in 0...colors[ i ].length )
            {
                
                hex         = new DisplayDiv();
                _holder.addChild( hex );
                hex.width   = Std.int( stepX );
                hex.height  = Std.int( stepY );
                hex.x       = initX;
                hex.y       = initY;
                hexGrad = hex.drawGradHexagon(    0
                                    ,   0
                                    ,   Std.int( stepX )
                                    ,   Std.int( stepY )
                                    ,   colors[ i ][ j ][ _firstColor ]
                                    ,   colors[ i ][ j ][ _secondColor ]
                                    ,   1
                                    ,   orientation 
                                    ) ;
                initY += stepY;
                hexagons.push(  {   div:            hex
                                ,   firstColor:     colors[ i ][ j ][ _firstColor ]
                                ,   secondColor:    colors[ i ][ j ][ _secondColor ]
                                ,   xStart:         hex.x
                                ,   yStart:         hex.y
                                ,   hexGrad:        hexGrad
                                }
                            );
            }
            
            initX   += Std.int( stepX*0.7 );
            startY  += Std.int( stepY/2 );
            initY   = startY;
            
        }
        
    }
    
}
