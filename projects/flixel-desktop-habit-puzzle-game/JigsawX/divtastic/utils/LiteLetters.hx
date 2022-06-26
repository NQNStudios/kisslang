
package utils;
import Main;
import js.html.CanvasRenderingContext2D;
enum DrawingCommand
{
    MOVE;
    LINE;
    ARC;
}
typedef DrawInstruction = 
{
    var instruction: DrawingCommand;
    var param: Array<Dynamic>;
}
class LiteLetters
{
    
    var surface:        CanvasRenderingContext2D;
    public var scale:   Float;
    public var dx:      Int;
    public var dy:      Int;
    var dia:            Int; 
    var piSmall:        Float;
    var pi:             Float;
    var gap:            Int;
    var radius:         Int;
    var twoDia:         Int;
    var three4Dia:      Int;
    var oneHalfDia:     Int;
    var north:          Float;
    var south:          Float;
    var east:           Float;
    var west:           Float;
    var clock:          Bool;
    var dPix:           Int;
    var dPiy:           Int;
    
    public function new( surface_: CanvasRenderingContext2D )
    {
        surface     = surface_;
        dia         = 8;
        radius      = Std.int( dia/2 );
        dx          = 100;
        dy          = 100;
        twoDia      = dia*2;
        clock       = false;
        dPix        = 3;
        dPiy        = 2;
        oneHalfDia  = Std.int(1.5*dia);
        three4Dia   = Std.int( dia*(3/4) );
        gap         = Std.int( dia/2.5);
        piSmall     = Math.PI/4;
        pi          = Math.PI;
        north       = -pi/2;
        south       = pi/2;
        west        = pi;
        east        = 0;
        setColorStroke( '#ff0000', 1.5 );
    }
    
    public function setColorStroke( col: String, stroke: Float )
    {
        surface.strokeStyle     = col;
        surface.lineWidth       = stroke;
    }
    
    public function letterChoose( letter: String ): Array<DrawInstruction>
    {
        return switch( letter )
        {
            case 'a':   [   {   instruction: MOVE
                            ,   param: [ dx + radius + dPix, dy + dPiy ] 
                            },   
                            {   instruction: ARC
                            ,   param: [ dx + radius, dy + radius, radius, north + piSmall, south - piSmall, true ]
                            },
                            {   instruction: MOVE
                            ,   param: [ dx + radius + dPix + 2, dy + dia ]
                            },
                            {   instruction: LINE
                            ,   param: [ dx + radius + dPix, dy + dia - 1 ]
                            },
                            {   instruction: LINE
                            ,   param: [ dx + radius + dPix, dy - 1 ]
                            }
                        ];
            case 'b':   [   {   instruction: MOVE
                            ,   param: [ dx + radius - dPix, dy + dPiy ] 
                            },  
                            {   instruction: ARC
                            ,   param: [ dx + radius, dy + radius, radius, north - piSmall, south + piSmall, false ]
                            },
                            {   instruction: MOVE
                            ,   param: [ dx + radius - dPix - 1, dy - dia + 1 ]
                            },
                            {   instruction: LINE
                            ,   param: [ dx + radius - dPix - 1, dy + dia ]
                            }
                        ];
            case 'c':   [   {   instruction: MOVE
                            ,   param: [ dx + radius + dPix, dy + dPiy ] 
                            },   
                            {   instruction: ARC
                            ,   param: [ dx + radius, dy + radius, radius, north + piSmall, south - piSmall, true ]
                            }
                        ];
            case 'd':   [   {   instruction: MOVE
                            ,   param: [ dx + radius + dPix, dy + dPiy ] 
                            },   
                            {   instruction: ARC
                            ,   param: [ dx + radius, dy + radius, radius, north + piSmall, south - piSmall, true ]
                            },
                            {   instruction: MOVE
                            ,   param: [ dx + radius + dPix, dy + dia ]
                            },
                            {   instruction: LINE
                            ,   param: [ dx + radius + dPix, dy - dia + 1 ]
                            }
                        ];
            case 'e':   [   {   instruction: MOVE
                            ,   param:  [ dx + radius + dPix, dy + dPiy ]
                            },
                            {   instruction: ARC
                            ,   param:  [ dx + radius, dy + radius, radius, north + 1.5*piSmall, south - piSmall, true ]
                            },
                            {   instruction: MOVE
                            ,   param: [ dx, dy + radius ]
                            },
                            {   instruction: LINE
                            ,   param: [ dx + dia, dy + radius ]
                            }
                        ];
            case 'f':   [   {   instruction: MOVE
                            ,   param: [ dx + dia, dy - radius + 1 ]
                            },
                            {   instruction: ARC
                            ,   param: [ dx + radius, dy + radius - dia + 1, radius - 1, east - piSmall, west , true ]
                            },
                            {   instruction: MOVE
                            ,   param: [ dx + 1, dy - radius + 1 ]
                            },
                            {   instruction: LINE
                            ,   param: [ dx + 1, dy + dia ]
                            },
                            {   instruction: MOVE
                            ,   param: [ dx, dy ]
                            },
                            {   instruction: LINE
                            ,   param: [ dx + radius + 1, dy ] 
                            }
                        ];
            case 'g':   [   {   instruction: MOVE
                            ,   param: [ dx + radius + dPix, dy + dPiy ] 
                            },   
                            {   instruction: ARC
                            ,   param: [ dx + radius, dy + radius, radius, north + piSmall, south - piSmall, true ]
                            },
                            {   instruction: MOVE
                            ,   param: [ dx + radius + dPix, dy + dPiy ]
                            },
                            {   instruction: LINE
                            ,   param:  [ dx + radius + dPix, dy + dia + radius - 1 ]
                            },
                            {   instruction: ARC
                            ,   param: [ dx + radius, dy + dia + radius - 1, radius - 1, east, west, false ]
                            }
                        ];
            case 'h':   [   {   instruction: MOVE
                            ,   param: [ dx, dy + radius ]
                            },
                            {   instruction: ARC
                            ,   param: [ dx + radius, dy + radius, radius, west, east, false ]
                            },
                            {   instruction: MOVE
                            ,   param: [ dx, dy - dia + 1 ]
                            },
                            {   instruction: LINE
                            ,   param: [ dx, dy + dia ]
                            },
                            {   instruction: MOVE
                            ,   param: [ dx + dia, dy + radius ]    
                            },
                            {   instruction: LINE
                            ,   param: [ dx + dia, dy + dia ]    
                            }
                        ];
            case 'i':   [   {   instruction: MOVE
                            ,   param: [ dx + radius, dy ]
                            },
                            {   instruction: LINE
                            ,   param: [ dx + radius, dy + dia ]
                            },
                            {   instruction: MOVE
                            ,   param: [ dx + radius, dy - radius ]
                            },
                            {   instruction: LINE
                            ,   param: [ dx + radius, dy - radius + 2 ]
                            }
                        ];
            case 'j':   [   {   instruction: MOVE
                            ,   param: [ dx + radius, dy - radius ]
                            },
                            {   instruction: LINE
                            ,   param: [ dx + radius, dy - radius + 2 ]
                            },
                            {   instruction: MOVE
                            ,   param: [ dx + radius, dy ]
                            },
                            {   instruction: ARC
                            ,   param: [    dx + Std.int(radius/2), dy + dia + radius - 1
                                        ,   Std.int(radius/2), east - Math.PI/8, west
                                        ,   false ]
                            }
                        ];
            case 'k':   [   {   instruction: MOVE
                            ,   param: [ dx, dy + dia ]
                            },
                            {   instruction: LINE 
                            ,   param: [ dx, dy - dia + 1 ]
                            },
                            {   instruction: MOVE 
                            ,   param: [ dx, dy + radius ]
                            },
                            {   instruction: LINE
                            ,   param: [ dx + dia - 1, dy ]
                            },
                            {   instruction: MOVE
                            ,   param: [ dx + 2, dy + radius - 2 ]
                            },
                            {   instruction: LINE
                            ,   param: [ dx + dia - 1, dy + dia ]
                            },                                            
                        ];
            case 'l':   [   {   instruction: MOVE
                            ,   param: [ dx + radius, dy - dia + 1 ]
                            },
                            {   instruction: LINE
                            ,   param: [ dx + radius, dy + dia - 1 ]
                            },
                            {   instruction: LINE
                            ,   param: [ dx + radius + 2, dy + dia ]
                            }
                        ];
            //re-think this letter?
            case 'm':   [   {   instruction: MOVE
                            ,   param: [ dx, dy + 3 ]
                            },
                            {   instruction: LINE
                            ,   param: [ dx + 2, dy ]
                            },
                            {   instruction: LINE
                            ,   param: [ dx + radius, dy + 4 ]
                            },
                            {   instruction: LINE
                            ,   param: [ dx + radius, dy + dia - 2 ]
                            },
                            {   instruction: LINE
                            ,   param: [ dx + radius, dy + 4 ]
                            },
                            {   instruction: LINE
                            ,   param: [ dx + dia - 2, dy ]
                            },
                            {   instruction: LINE
                            ,   param: [ dx + dia, dy + 3 ]                                                                                          
                            },
                            {   instruction: LINE
                            ,   param: [ dx + dia, dy + dia ]
                            },
                            {   instruction: MOVE
                            ,   param: [ dx - 1, dy ]
                            },
                            {   instruction: LINE
                            ,   param: [ dx, dy + dia ]
                            }
                        ];     
            case 'n':   [   {   instruction: MOVE
                            ,   param: [ dx, dy + radius ]
                            },
                            {   instruction: ARC  
                            ,   param: [ dx + radius, dy + radius, radius, west, east, false ]
                            },
                            {   instruction: MOVE 
                            ,   param: [ dx, dy - 1 ]
                            },
                            {   instruction: LINE
                            ,   param: [ dx, dy + dia ]
                            },
                            {   instruction: MOVE
                            ,   param: [ dx + dia, dy + radius ]
                            },
                            {   instruction: LINE
                            ,   param: [ dx + dia, dy + dia ]
                            },
                        ];
            case 'o':   [   {   instruction: MOVE
                            ,   param: [ dx, dy + radius ]
                            },
                            {   instruction: ARC
                            ,   param: [ dx + radius, dy + radius, radius, west + pi*2, west, true ]
                            }
                        ];
            case 'p':   [   {   instruction: MOVE
                            ,   param: [ dx + radius - dPix, dy + dPiy ]
                            },
                            {   instruction: ARC
                            ,   param: [ dx + radius, dy + radius, radius, north - piSmall, south + piSmall, false ]
                            },
                            {   instruction: MOVE
                            ,   param: [ dx + radius - dPix - 1, dy ]
                            },
                            {   instruction: LINE
                            ,   param: [ dx + radius - dPix - 1, dy + 2*dia - 1 ]
                            },
                        ];            	    
            case 'q':   [   {   instruction: MOVE
                            ,   param: [ dx + radius + dPix, dy + dPiy ]
                            },
                            {   instruction: ARC
                            ,   param: [ dx + radius, dy + radius, radius, north + piSmall, south - piSmall, true ]
                            },
                            {   instruction: MOVE
                            ,   param: [ dx + radius + dPix, dy ]
                            },
                            {   instruction: LINE
                            ,   param: [ dx + radius + dPix, dy + 2*dia - 1 ]
                            }
                        ];
            case 'r':   [   {   instruction: MOVE
                            ,   param: [ dx, dy + radius ]
                            },
                            {   instruction: ARC
                            ,   param: [ dx + radius, dy + radius, radius, west, north + piSmall, false ]
                            },
                            {   instruction: MOVE
                            ,   param: [ dx, dy - 1 ]
                            },
                            {   instruction: LINE
                            ,   param: [ dx, dy + dia ] 
                            }
                        ];   
            case 's':   [   {   instruction: MOVE
                            ,   param: [ dx + dia - 1, dy + 2 ]
                            },
                            {   instruction: LINE
                            ,   param: [ dx + radius, dy ] 
                            },
                            {   instruction: LINE
                            ,   param: [ dx + 2, dy + 2 ] 
                            },
                            {   instruction: LINE
                            ,   param: [ dx + radius, dy + radius ] 
                            },
                            {   instruction: LINE
                            ,   param: [ dx + dia - 2, dy + 6 ]
                            },
                            {   instruction: LINE
                            ,   param: [ dx + radius, dy + dia ] 
                            },
                            {   instruction: LINE
                            ,   param: [ dx + 1, dy + dia -1 ]
                            }
                        ];
            case 't':   [   {   instruction: MOVE
                            ,   param: [ dx + radius -  1, dy - radius ]
                            },
                            {   instruction: LINE
                            ,   param: [ dx + radius -  1, dy + dia - 1 ]
                            },
                            {   instruction: LINE
                            ,   param: [ dx + radius + 1, dy + dia ]
                            },
                            {   instruction: LINE
                            ,   param: [ dx + radius + 3, dy + dia - 1 ] 
                            },
                            {   instruction: MOVE
                            ,   param: [ dx, dy ] 
                            },
                            {   instruction: LINE
                            ,   param: [ dx + dia - dPix, dy ] 
                            }
                        ];
            case 'u':   [   {   instruction: MOVE
                            ,   param: [ dx, dy - 1 ]
                            },
                            {   instruction: LINE   
                            ,   param: [ dx, dy + radius - 1 ] 
                            },
                            {   instruction: ARC
                            ,   param: [ dx + radius, dy + radius - 1, radius, west, east, true ]    
                            },
                            {   instruction: LINE
                            ,   param: [ dx + dia, dy - 1 ]
                            },
                            {   instruction: LINE
                            ,   param: [ dx + dia, dy + dia ]
                            }
                        ];
            case 'v':   [   {   instruction: MOVE
                            ,   param: [ dx, dy ]
                            },
                            {   instruction: LINE
                            ,   param: [ dx + radius, dy + dia ]
                            },
                            {   instruction: LINE
                            ,   param: [ dx + dia, dy ]
                            }
                        
                        ];
            case 'w':   [   {   instruction: MOVE
                            ,   param: [ dx, dy ]
                            },
                            {   instruction: LINE
                            ,   param: [ dx + 1, dy + dia ]
                            },
                            {   instruction: LINE
                            ,   param: [ dx + radius, dy + radius - 1 ]
                            },
                            {   instruction: LINE
                            ,   param: [ dx + dia - 1, dy + dia ]
                            },
                            {   instruction: LINE
                            ,   param: [ dx + dia, dy ]
                            }
                        ];    
            case 'x':   [   {   instruction: MOVE
                            ,   param: [ dx, dy ]
                            },
                            {   instruction: LINE
                            ,   param: [ dx + dia, dy + dia ]
                            },
                            {   instruction: MOVE
                            ,   param: [ dx + dia, dy ]
                            },
                            {   instruction: LINE
                            ,   param: [ dx, dy + dia ]
                            }
                        ];
            case 'y':   [   {   instruction: MOVE
                            ,   param: [ dx, dy ] 
                            },
                            {   instruction: LINE
                            ,   param: [ dx, dy + radius ]
                            },
                            {   instruction: ARC
                            ,   param: [ dx + radius, dy + radius, radius, west, east, true ]
                            },
                            {   instruction: LINE
                            ,   param: [ dx + dia, dy ]
                            },
                            {   instruction: LINE
                            ,   param: [ dx + dia, dy + dia + radius - 1 ]
                            },
                            {   instruction: ARC
                            ,   param: [ dx + radius + 1, dy + dia + radius, radius - 1, east, west, false ]
                            }
                        ];
            case 'z':   [   {   instruction: MOVE
                            ,   param: [ dx, dy ]
                            },
                            {   instruction: LINE
                            ,   param: [ dx + dia -1, dy ]    
                            },
                            {   instruction: LINE
                            ,   param: [ dx, dy + dia ]
                            },
                            {   instruction: LINE
                            ,   param: [ dx + dia, dy + dia ]
                            }
                        ];        
            case '0':   [   {   instruction: MOVE
                            ,   param: [ dx + 1, dy - radius + 1 ]
                            },
                            {   instruction: ARC
                            ,   param: [ dx + radius, dy - radius + 1, radius-0.7, west, east, false ]
                            },
                            {   instruction: ARC
                            ,   param: [ dx + radius, dy + radius, radius, east , west, false ]
                            },
                            {   instruction: LINE
                            ,   param: [ dx + 1, dy - radius + 1 ]
                            },
                            {   instruction: MOVE
                            ,   param: [ dx + 1, dy + radius + 4 ]
                            },
                            {   instruction: LINE
                            ,   param: [ dx + dia - 1, dy - radius - 1 ]
                            }
                        ];
            case '1':   [   {   instruction: MOVE
                            ,   param: [ dx + radius - dPix, dy - dia + dPiy + 1 ]
                            },
                            {   instruction: LINE
                            ,   param: [ dx + radius, dy - dia + 1 ]
                            },
                            {   instruction: LINE
                            ,   param: [ dx + radius, dy + dia ]
                            },
                            {   instruction: LINE
                            ,   param: [ dx + radius - dPix, dy + dia ]
                            },
                            {   instruction: LINE
                            ,   param: [ dx + radius + dPix, dy + dia ]    
                            }
                        ];
            case '2':   [   {   instruction: MOVE 
                            ,   param: [ dx, dy - radius - 1 ]
                            },
                            {   instruction: ARC
                            ,   param: [ dx + radius, dy - radius + 1, radius, west, east + piSmall, false ]
                            },
                            {   instruction: LINE
                            ,   param: [ dx + 2, dy + dia - 4 ]
                            },
                            {   instruction: LINE
                            ,   param: [ dx, dy + dia ]
                            },
                            {   instruction: LINE
                            ,   param: [ dx + dia, dy + dia ]
                            }
                        ];
            case '3':   [   {   instruction: MOVE
                            ,   param: [ dx, dy - radius - 1 ]
                            },
                            {   instruction: ARC
                            ,   param: [ dx + radius, dy - radius + 1, radius, west, east + piSmall, false ]
                            },
                            {   instruction: ARC
                            ,   param: [ dx + radius, dy + radius, radius, east - piSmall, west, false ]
                            },
                            {   instruction: MOVE
                            ,   param: [ dx + radius-1, dy ]
                            },
                            {   instruction: LINE
                            ,   param: [ dx + radius + 3, dy ]
                            }
                        ];        
            case '4':   [   {   instruction: MOVE
                            ,   param: [ dx + dia + 1, dy + 1 ]
                            },
                            {   instruction: LINE
                            ,   param: [ dx, dy + 1 ]
                            },
                            {   instruction: LINE
                            ,   param: [ dx, dy ]    
                            },
                            {   instruction: LINE
                            ,   param: [ dx + radius + 2, dy - dia + 1 ]
                            },
                            {   instruction: LINE
                            ,   param: [ dx + radius + 2, dy + dia ]
                            }
                        ];
            case '5':   [   {   instruction: MOVE
                            ,   param: [ dx + dia, dy - dia + 1 ]
                            },
                            {   instruction: LINE
                            ,   param: [ dx, dy - dia + 1 ]
                            },
                            {   instruction: LINE
                            ,   param: [ dx, dy ]
                            },
                            {   instruction: LINE
                            ,   param: [ dx + radius - 2, dy - 1 ]
                            },
                            {   instruction: ARC
                            ,   param: [ dx + radius, dy + radius - 1, radius, north, east, false ]
                            },
                            {   instruction: ARC
                            ,   param: [ dx + radius, dy + radius, radius, east, west, false ]
                            }
                        ];
            case '6':   [   {   instruction: MOVE
                            ,   param: [ dx, dy + radius ]
                            },
                            {   instruction: ARC
                            ,   param: [ dx + radius, dy + radius, radius, west + 2*pi, west, true ]
                            },
                            {   instruction: ARC
                            ,   param: [ dx + radius, dy - radius + 1, radius, west, east - piSmall, false ]
                            }
                        ];
            case '7':   [   {   instruction: MOVE
                            ,   param: [ dx, dy - dia + 1 ]
                            },
                            {   instruction: LINE
                            ,   param: [ dx + dia, dy - dia + 1 ]
                            },
                            {   instruction: LINE
                            ,   param: [ dx + dia, dy - dia + 3 ]
                            },
                            {   instruction: LINE
                            ,   param: [ dx + 2 + 1, dy + radius -1 ]
                            },
                            {   instruction: LINE
                            ,   param: [ dx + 2, dy + dia ] 
                            }
                        ];
            case '8':   [   {   instruction: MOVE 
                            ,   param: [ dx + radius, dy ]
                            },
                            {   instruction: ARC
                            ,   param: [ dx + radius, dy - radius, radius - 1, south, south + pi*2, false ]
                            },
                            {   instruction: ARC
                            ,   param: [ dx + radius, dy + radius, radius, north, north + pi*2, true ]
                            }  
                        ];
            case '9':   [   {   instruction: MOVE
                            ,   param: [ dx + dia, dy - radius + 1 ]
                            },
                            {   instruction: ARC
                            ,   param: [ dx + radius, dy - radius + 1, radius-0.5, east, east + pi*2, true ]
                            },
                            {   instruction: ARC
                            ,   param: [ dx + radius, dy + radius, radius, east , west- 1.4*piSmall, false ]    
                            }
                        ];
              default: null;         
	    }
	    
	}
    
    public function write( str: String )
    {
        surface.beginPath();
	    for( ii in 0...str.length)
	    {
	        var letter = str.charAt( ii );
	        if( letter == " " )
	        { 
	            nextLetter(); 
	            continue;
	        }
	        letter = letter.toLowerCase();
	        var letterCommands = letterChoose( letter );
	        if( letterCommands == null )
	        {
	            nextLetter(); 
	            continue;
	        }
	        for( jj in 0...letterCommands.length )
	        {
	            var drawCommand =   letterCommands[ jj ];
	            var instruction =   switch( drawCommand.instruction )
	                                {
                    	                case MOVE: 'moveTo';
                                        case LINE: 'lineTo';  
                                        case ARC:  'arc'   ;
                    	            };
                var param       =   drawCommandScale( drawCommand );
                Reflect.callMethod  (   surface
                                    ,   Reflect.field( surface, instruction )
                                    ,   param 
                                    );
	        }
	        nextLetter();
	    }
	    end();
    }

    public function drawCommandScale( command: DrawInstruction ): Array<Dynamic>
    {
        var param = command.param;
        var dy_ = dy;
        var dx_ = dx;
        return switch( command.instruction )
        {
            case MOVE, LINE:
                [ scale*( param[ 0 ] - dx ) + dx_
                , scale*( param[ 1 ] - dy ) + dy_
                ];
            case ARC:
                [ scale*( param[ 0 ] - dx ) + dx_
                , scale*( param[ 1 ] - dy ) + dy_
                , scale*param[ 2 ]
                , param[ 3 ]
                , param[ 4 ]
                , param[ 5 ]
                ];
        }
    }
    
    public function nextLetter()
    {
        dx += gap + Math.ceil( dia*scale );
    }
    
    public function end()
    {
        surface.stroke();
    }
    
}
