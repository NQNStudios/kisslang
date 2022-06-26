
package utils;

typedef Pen =
{
    var fill:       ColorHtml5;
    var lineColor:  ColorHtml5;
    var thickness:  Int;
    var hasEdge:    Bool;
    var hasFill:    Bool;
}

enum ColorHtml5
{
    AliceBlue; AntiqueWhite; Aqua; Aquamarine; Azure;
    Beige; Bisque; Black; BlanchedAlmond; Blue; BlueViolet; Brown; BurlyWood;
    CadetBlue; Chartreuse; Chocolate; Coral; CornflowerBlue; Cornsilk; Crimson; Cyan;
    DarkBlue; DarkCyan; DarkGoldenRod; DarkGray; DarkGrey; DarkGreen; DarkKhaki; 
    DarkMagenta; DarkOliveGreen; Darkorange; DarkOrchid; DarkRed; DarkSalmon;
    DarkSeaGreen; DarkSlateBlue; DarkSlateGray; DarkSlateGrey; DarkTurquoise; DarkViolet;
    DeepPink; DeepSkyBlue; DimGray; DimGrey; DodgerBlue;
    FireBrick; FloralWhite; ForestGreen; Fuchsia;
    Gainsboro; GhostWhite; Gold; GoldenRod; Gray; Grey; Green; GreenYellow;
    HoneyDew; HotPink;
    IndianRed; Indigo; Ivory;
    Khaki;
    Lavender; LavenderBlush; LawnGreen; LemonChiffon;
    LightBlue; LightCoral; LightCyan; LightGoldenRodYellow; LightGray; LightGrey; 
    LightGreen; LightPink; LightSalmon; LightSeaGreen; LightSkyBlue;
    LightSlateGray; LightSlateGrey; LightSteelBlue; LightYellow;
    Lime; LimeGreen; Linen;
    Magenta; Maroon; 
    MediumAquaMarine; MediumBlue; MediumOrchid; MediumPurple; MediumSeaGreen;
    MediumSlateBlue; MediumSpringGreen; MediumTurquoise; MediumVioletRed;
    MidnightBlue; MintCream; MistyRose; Moccasin; 
    NavajoWhite; Navy;
    OldLace; Olive; OliveDrab; Orange; OrangeRed; Orchid; 
    PaleGoldenRod; PaleGreen; PaleTurquoise; PaleVioletRed; PapayaWhip; 
    PeachPuff; Peru; Pink; Plum; PowderBlue; Purple;
    Red; RosyBrown; RoyalBlue;
    SaddleBrown; Salmon; SandyBrown; SeaGreen; SeaShell; Sienna; Silver;
    SkyBlue; SlateBlue; SlateGray; SlateGrey; Snow; SpringGreen; SteelBlue;
    Tan; Teal; Thistle; Tomato; Turquoise; Violet; Wheat; White; WhiteSmoke;
    Yellow; YellowGreen;
}
/*
enum ColorHtml
{
    Aqua; Black; Blue; 
    Brown; Chartreuse; Fuchsia; 
    Gray; Green; Lime; 
    Maroon; Navy; Olive; 
    Orange; Purple; Red; 
    Silver; Teal; Violet; 
    White; Yellow;
}*/
class Colorjs
{
	public function new()
	{
		
	}
	
	public static function penClone( p: Pen ): Pen
	{
	    return { fill: p.fill, lineColor: p.lineColor, thickness: p.thickness, hasEdge: p.hasEdge, hasFill: p.hasFill };
	}
	
	public static function redFill()
	{
	    return { fill: Red, lineColor: White, thickness: 3, hasEdge: false, hasFill: true };
	}
/*
	static public function colorHtmlAsHexString( color: ColorHtml )
	{
	    switch( color )
	    {
	        case Aqua:          "#00FFFF"; 
	        case Black:         "#000000";
	        case Blue:          "#0000FF";
	        case Brown:         "#A02820";
	        case Chartreuse:    "#80FF00"; 
            case Fuchsia:       "#FF00FF"; 
            case Gray:          "#808080"; 
            case Green:         "#008000"; 
            case Lime:          "#00FF00";
            case Maroon:        "#800000";
            case Navy:          "#000080"; 
            case Olive:         "#808000"; 
            case Orange:        "#FFA000"; 
            case Purple:        "#800080"; 
            case Red:           "FF0000"; 
            case Silver:        "#C0C0C0";
            case Teal:          "#008080"; 
            case Violet:        "#F080F0"; 
            case White:         "#FFFFFF";
            case Yellow:        "#FFFF00" ; 
	    }
	}
	*/
	static inline public function str( color: ColorHtml5 ): String
	{
	    return switch( color )
	    {
            case AliceBlue:  	        '#F0F8FF';
            case AntiqueWhite:          '#FAEBD7';
            case Aqua:  	            '#00FFFF';
            case Aquamarine:            '#7FFFD4';
            case Azure:  	            '#F0FFFF';
            case Beige:                 '#F5F5DC';
            case Bisque:      	        '#FFE4C4';
            case Black:                 '#000000';
            case BlanchedAlmond:        '#FFEBCD';
            case Blue:                  '#0000FF';
            case BlueViolet:       	    '#8A2BE2';
            case Brown:           	    '#A52A2A';
            case BurlyWood:       	    '#DEB887';
            case CadetBlue:       	    '#5F9EA0';
            case Chartreuse:      	    '#7FFF00';
            case Chocolate:       	    '#D2691E';
            case Coral:           	    '#FF7F50';
            case CornflowerBlue:  	    '#6495ED';
            case Cornsilk:  	        '#FFF8DC';
            case Crimson:         	    '#DC143C';
            case Cyan:            	    '#00FFFF';
            case DarkBlue:        	    '#00008B';
            case DarkCyan:        	    '#008B8B';
            case DarkGoldenRod:  	    '#B8860B';
            case DarkGray:      	    '#A9A9A9';
            case DarkGrey:      	    '#A9A9A9';
            case DarkGreen:     	    '#006400';
            case DarkKhaki:       	    '#BDB76B';
            case DarkMagenta:     	    '#8B008B';
            case DarkOliveGreen: 	    '#556B2F';
            case Darkorange:     	    '#FF8C00';
            case DarkOrchid:      	    '#9932CC';
            case DarkRed:         	    '#8B0000';
            case DarkSalmon:      	    '#E9967A';
            case DarkSeaGreen:    	    '#8FBC8F';
            case DarkSlateBlue:  	    '#483D8B';
            case DarkSlateGray:  	    '#2F4F4F';
            case DarkSlateGrey:  	    '#2F4F4F';
            case DarkTurquoise:  	    '#00CED1';
            case DarkViolet:      	    '#9400D3';
            case DeepPink:        	    '#FF1493';
            case DeepSkyBlue:     	    '#00BFFF';
            case DimGray:         	    '#696969';
            case DimGrey:         	    '#696969';
            case DodgerBlue:      	    '#1E90FF';
            case FireBrick:       	    '#B22222';
            case FloralWhite:     	    '#FFFAF0';
            case ForestGreen:     	    '#228B22';
            case Fuchsia:         	    '#FF00FF';
            case Gainsboro:       	    '#DCDCDC';
            case GhostWhite:      	    '#F8F8FF';
            case Gold:            	    '#FFD700';
            case GoldenRod:       	    '#DAA520';
            case Gray:  	            '#808080';
            case Grey:  	            '#808080';
            case Green:  	            '#008000';
            case GreenYellow:  	        '#ADFF2F';
            case HoneyDew:  	        '#F0FFF0';
            case HotPink:  	            '#FF69B4';
            case IndianRed:   	        '#CD5C5C';
            case Indigo:   	            '#4B0082';
            case Ivory:  	            '#FFFFF0';
            case Khaki:  	            '#F0E68C';
            case Lavender:  	        '#E6E6FA';
            case LavenderBlush:  	    '#FFF0F5';
            case LawnGreen:  	        '#7CFC00';
            case LemonChiffon:  	    '#FFFACD';
            case LightBlue:  	        '#ADD8E6';
            case LightCoral:  	        '#F08080';
            case LightCyan:  	        '#E0FFFF';
            case LightGoldenRodYellow:  '#FAFAD2';
            case LightGray:  	        '#D3D3D3';
            case LightGrey:  	        '#D3D3D3';
            case LightGreen:  	        '#90EE90';
            case LightPink:  	        '#FFB6C1';
            case LightSalmon:  	        '#FFA07A';
            case LightSeaGreen:  	    '#20B2AA';
            case LightSkyBlue:          '#87CEFA';
            case LightSlateGray:  	    '#778899';
            case LightSlateGrey:  	    '#778899';
            case LightSteelBlue:  	    '#B0C4DE';
            case LightYellow:  	        '#FFFFE0';
            case Lime:               	'#00FF00';
            case LimeGreen:             '#32CD32';
            case Linen:               	'#FAF0E6';
            case Magenta:             	'#FF00FF';
            case Maroon:              	'#800000';
            case MediumAquaMarine:    	'#66CDAA';
            case MediumBlue:          	'#0000CD';
            case MediumOrchid:        	'#BA55D3';
            case MediumPurple:        	'#9370DB';
            case MediumSeaGreen:      	'#3CB371';
            case MediumSlateBlue:     	'#7B68EE';
            case MediumSpringGreen:  	'#00FA9A';
            case MediumTurquoise:     	'#48D1CC';
            case MediumVioletRed:     	'#C71585';
            case MidnightBlue:        	'#191970';
            case MintCream:           	'#F5FFFA';
            case MistyRose:           	'#FFE4E1';
            case Moccasin:            	'#FFE4B5';
            case NavajoWhite:         	'#FFDEAD';
            case Navy:                	'#000080';
            case OldLace:             	'#FDF5E6';
            case Olive:               	'#808000';
            case OliveDrab:           	'#6B8E23';
            case Orange:              	'#FFA500';
            case OrangeRed:           	'#FF4500';
            case Orchid:              	'#DA70D6';
            case PaleGoldenRod:       	'#EEE8AA';
            case PaleGreen:           	'#98FB98';
            case PaleTurquoise:       	'#AFEEEE';
            case PaleVioletRed:       	'#DB7093';
            case PapayaWhip:          	'#FFEFD5';
            case PeachPuff:           	'#FFDAB9';
            case Peru:                	'#CD853F';
            case Pink:                	'#FFC0CB';
            case Plum:                	'#DDA0DD';
            case PowderBlue:          	'#B0E0E6';
            case Purple:              	'#800080';
            case Red:                 	'#FF0000';
            case RosyBrown:           	'#BC8F8F';
            case RoyalBlue:           	'#4169E1';
            case SaddleBrown:         	'#8B4513';
            case Salmon:              	'#FA8072';
            case SandyBrown:          	'#F4A460';
            case SeaGreen:            	'#2E8B57';
            case SeaShell:            	'#FFF5EE';
            case Sienna:              	'#A0522D';
            case Silver:              	'#C0C0C0';
            case SkyBlue:             	'#87CEEB';
            case SlateBlue:           	'#6A5ACD';
            case SlateGray:           	'#708090';
            case SlateGrey:           	'#708090';
            case Snow:                	'#FFFAFA';
            case SpringGreen:         	'#00FF7F';
            case SteelBlue:           	'#4682B4';
            case Tan:                 	'#D2B48C';
            case Teal:                	'#008080';
            case Thistle:             	'#D8BFD8';
            case Tomato:              	'#FF6347';
            case Turquoise:           	'#40E0D0';
            case Violet:              	'#EE82EE';
            case Wheat:               	'#F5DEB3';
            case White:               	'#FFFFFF';
            case WhiteSmoke:          	'#F5F5F5';
            case Yellow:              	'#FFFF00';
            case YellowGreen: 	        '#9ACD32';
            
	    }
	}
	static inline public function rgb( color: ColorHtml5 ): Array<Int>
	{
	    return switch( color )
	    {
            case AliceBlue:  	        [ 0xF0, 0xF8, 0xFF ];
            case AntiqueWhite:          [ 0xFA, 0xEB, 0xD7 ];
            case Aqua:  	            [ 0x00, 0xFF, 0xFF ];
            case Aquamarine:            [ 0x7F, 0xFF, 0xD4 ];
            case Azure:  	            [ 0xF0, 0xFF, 0xFF ];
            case Beige:                 [ 0xF5, 0xF5, 0xDC ];
            case Bisque:      	        [ 0xFF, 0xE4, 0xC4 ];
            case Black:                 [ 0x00, 0x00, 0x00 ];
            case BlanchedAlmond:        [ 0xFF, 0xEB, 0xCD ];
            case Blue:                  [ 0x00, 0x00, 0xFF ];
            case BlueViolet:       	    [ 0x8A, 0x2B, 0xE2 ];
            case Brown:           	    [ 0xA5, 0x2A, 0x2A ];
            case BurlyWood:       	    [ 0xDE, 0xB8, 0x87 ];
            case CadetBlue:       	    [ 0x5F, 0x9E, 0xA0 ];
            case Chartreuse:      	    [ 0x7F, 0xFF, 0x00 ];
            case Chocolate:       	    [ 0xD2, 0x69, 0x1E ];
            case Coral:           	    [ 0xFF, 0x7F, 0x50 ];
            case CornflowerBlue:  	    [ 0x64, 0x95, 0xED ];
            case Cornsilk:  	        [ 0xFF, 0xF8, 0xDC ];
            case Crimson:         	    [ 0xDC, 0x14, 0x3C ];
            case Cyan:            	    [ 0x00, 0xFF, 0xFF ];
            case DarkBlue:        	    [ 0x00, 0x00, 0x8B ];
            case DarkCyan:        	    [ 0x00, 0x8B, 0x8B ];
            case DarkGoldenRod:  	    [ 0xB8, 0x86, 0x0B ];
            case DarkGray:      	    [ 0xA9, 0xA9, 0xA9 ];
            case DarkGrey:      	    [ 0xA9, 0xA9, 0xA9 ];
            case DarkGreen:     	    [ 0x00, 0x64, 0x00 ];
            case DarkKhaki:       	    [ 0xBD, 0xB7, 0x6B ];
            case DarkMagenta:     	    [ 0x8B, 0x00, 0x8B ];
            case DarkOliveGreen: 	    [ 0x55, 0x6B, 0x2F ];
            case Darkorange:     	    [ 0xFF, 0x8C, 0x00 ];
            case DarkOrchid:      	    [ 0x99, 0x32, 0xCC ];
            case DarkRed:         	    [ 0x8B, 0x00, 0x00 ];
            case DarkSalmon:      	    [ 0xE9, 0x96, 0x7A ];
            case DarkSeaGreen:    	    [ 0x8F, 0xBC, 0x8F ];
            case DarkSlateBlue:  	    [ 0x48, 0x3D, 0x8B ];
            case DarkSlateGray:  	    [ 0x2F, 0x4F, 0x4F ];
            case DarkSlateGrey:  	    [ 0x2F, 0x4F, 0x4F ];
            case DarkTurquoise:  	    [ 0x00, 0xCE, 0xD1 ];
            case DarkViolet:      	    [ 0x94, 0x00, 0xD3 ];
            case DeepPink:        	    [ 0xFF, 0x14, 0x93 ];
            case DeepSkyBlue:     	    [ 0x00, 0xBF, 0xFF ];
            case DimGray:         	    [ 0x69, 0x69, 0x69 ];
            case DimGrey:         	    [ 0x69, 0x69, 0x69 ];
            case DodgerBlue:      	    [ 0x1E, 0x90, 0xFF ];
            case FireBrick:       	    [ 0xB2, 0x22, 0x22 ];
            case FloralWhite:     	    [ 0xFF, 0xFA, 0xF0 ];
            case ForestGreen:     	    [ 0x22, 0x8B, 0x22 ];
            case Fuchsia:         	    [ 0xFF, 0x00, 0xFF ];
            case Gainsboro:       	    [ 0xDC, 0xDC, 0xDC ];
            case GhostWhite:      	    [ 0xF8, 0xF8, 0xFF ];
            case Gold:            	    [ 0xFF, 0xD7, 0x00 ];
            case GoldenRod:       	    [ 0xDA, 0xA5, 0x20 ];
            case Gray:  	            [ 0x80, 0x80, 0x80 ];
            case Grey:  	            [ 0x80, 0x80, 0x80 ];
            case Green:  	            [ 0x00, 0x80, 0x00 ];
            case GreenYellow:  	        [ 0xAD, 0xFF, 0x2F ];
            case HoneyDew:  	        [ 0xF0, 0xFF, 0xF0 ];
            case HotPink:  	            [ 0xFF, 0x69, 0xB4 ];
            case IndianRed:   	        [ 0xCD, 0x5C, 0x5C ];
            case Indigo:   	            [ 0x4B, 0x00, 0x82 ];
            case Ivory:  	            [ 0xFF, 0xFF, 0xF0 ];
            case Khaki:  	            [ 0xF0, 0xE6, 0x8C ];
            case Lavender:  	        [ 0xE6, 0xE6, 0xFA ];
            case LavenderBlush:  	    [ 0xFF, 0xF0, 0xF5 ];
            case LawnGreen:  	        [ 0x7C, 0xFC, 0x00 ];
            case LemonChiffon:  	    [ 0xFF, 0xFA, 0xCD ];
            case LightBlue:  	        [ 0xAD, 0xD8, 0xE6 ];
            case LightCoral:  	        [ 0xF0, 0x80, 0x80 ];
            case LightCyan:  	        [ 0xE0, 0xFF, 0xFF ];
            case LightGoldenRodYellow:  [ 0xFA, 0xFA, 0xD2 ];
            case LightGray:  	        [ 0xD3, 0xD3, 0xD3 ];
            case LightGrey:  	        [ 0xD3, 0xD3, 0xD3 ];
            case LightGreen:  	        [ 0x90, 0xEE, 0x90 ];
            case LightPink:  	        [ 0xFF, 0xB6, 0xC1 ];
            case LightSalmon:  	        [ 0xFF, 0xA0, 0x7A ];
            case LightSeaGreen:  	    [ 0x20, 0xB2, 0xAA ];
            case LightSkyBlue:          [ 0x87, 0xCE, 0xFA ];
            case LightSlateGray:  	    [ 0x77, 0x88, 0x99 ];
            case LightSlateGrey:  	    [ 0x77, 0x88, 0x99 ];
            case LightSteelBlue:  	    [ 0xB0, 0xC4, 0xDE ];
            case LightYellow:  	        [ 0xFF, 0xFF, 0xE0 ];
            case Lime:               	[ 0x00, 0xFF, 0x00 ];
            case LimeGreen:             [ 0x32, 0xCD, 0x32 ];
            case Linen:               	[ 0xFA, 0xF0, 0xE6 ];
            case Magenta:             	[ 0xFF, 0x00, 0xFF ];
            case Maroon:              	[ 0x80, 0x00, 0x00 ];
            case MediumAquaMarine:    	[ 0x66, 0xCD, 0xAA ];
            case MediumBlue:          	[ 0x00, 0x00, 0xCD ];
            case MediumOrchid:        	[ 0xBA, 0x55, 0xD3 ];
            case MediumPurple:        	[ 0x93, 0x70, 0xDB ];
            case MediumSeaGreen:      	[ 0x3C, 0xB3, 0x71 ];
            case MediumSlateBlue:     	[ 0x7B, 0x68, 0xEE ];
            case MediumSpringGreen:  	[ 0x00, 0xFA, 0x9A ];
            case MediumTurquoise:     	[ 0x48, 0xD1, 0xCC ];
            case MediumVioletRed:     	[ 0xC7, 0x15, 0x85 ];
            case MidnightBlue:        	[ 0x19, 0x19, 0x70 ];
            case MintCream:           	[ 0xF5, 0xFF, 0xFA ];
            case MistyRose:           	[ 0xFF, 0xE4, 0xE1 ];
            case Moccasin:            	[ 0xFF, 0xE4, 0xB5 ];
            case NavajoWhite:         	[ 0xFF, 0xDE, 0xAD ];
            case Navy:                	[ 0x00, 0x00, 0x80 ];
            case OldLace:             	[ 0xFD, 0xF5, 0xE6 ];
            case Olive:               	[ 0x80, 0x80, 0x00 ];
            case OliveDrab:           	[ 0x6B, 0x8E, 0x23 ];
            case Orange:              	[ 0xFF, 0xA5, 0x00 ];
            case OrangeRed:           	[ 0xFF, 0x45, 0x00 ];
            case Orchid:              	[ 0xDA, 0x70, 0xD6 ];
            case PaleGoldenRod:       	[ 0xEE, 0xE8, 0xAA ];
            case PaleGreen:           	[ 0x98, 0xFB, 0x98 ];
            case PaleTurquoise:       	[ 0xAF, 0xEE, 0xEE ];
            case PaleVioletRed:       	[ 0xDB, 0x70, 0x93 ];
            case PapayaWhip:          	[ 0xFF, 0xEF, 0xD5 ];
            case PeachPuff:           	[ 0xFF, 0xDA, 0xB9 ];
            case Peru:                	[ 0xCD, 0x85, 0x3F ];
            case Pink:                	[ 0xFF, 0xC0, 0xCB ];
            case Plum:                	[ 0xDD, 0xA0, 0xDD ];
            case PowderBlue:          	[ 0xB0, 0xE0, 0xE6 ];
            case Purple:              	[ 0x80, 0x00, 0x80 ];
            case Red:                 	[ 0xFF, 0x00, 0x00 ];
            case RosyBrown:           	[ 0xBC, 0x8F, 0x8F ];
            case RoyalBlue:           	[ 0x41, 0x69, 0xE1 ];
            case SaddleBrown:         	[ 0x8B, 0x45, 0x13 ];
            case Salmon:              	[ 0xFA, 0x80, 0x72 ];
            case SandyBrown:          	[ 0xF4, 0xA4, 0x60 ];
            case SeaGreen:            	[ 0x2E, 0x8B, 0x57 ];
            case SeaShell:            	[ 0xFF, 0xF5, 0xEE ];
            case Sienna:              	[ 0xA0, 0x52, 0x2D ];
            case Silver:              	[ 0xC0, 0xC0, 0xC0 ];
            case SkyBlue:             	[ 0x87, 0xCE, 0xEB ];
            case SlateBlue:           	[ 0x6A, 0x5A, 0xCD ];
            case SlateGray:           	[ 0x70, 0x80, 0x90 ];
            case SlateGrey:           	[ 0x70, 0x80, 0x90 ];
            case Snow:                	[ 0xFF, 0xFA, 0xFA ];
            case SpringGreen:         	[ 0x00, 0xFF, 0x7F ];
            case SteelBlue:           	[ 0x46, 0x82, 0xB4 ];
            case Tan:                 	[ 0xD2, 0xB4, 0x8C ];
            case Teal:                	[ 0x00, 0x80, 0x80 ];
            case Thistle:             	[ 0xD8, 0xBF, 0xD8 ];
            case Tomato:              	[ 0xFF, 0x63, 0x47 ];
            case Turquoise:           	[ 0x40, 0xE0, 0xD0 ];
            case Violet:              	[ 0xEE, 0x82, 0xEE ];
            case Wheat:               	[ 0xF5, 0xDE, 0xB3 ];
            case White:               	[ 0xFF, 0xFF, 0xFF ];
            case WhiteSmoke:          	[ 0xF5, 0xF5, 0xF5 ];
            case Yellow:              	[ 0xFF, 0xFF, 0x00 ];
            case YellowGreen: 	        [ 0x9A, 0xCD, 0x32 ];
            
	    }
	}
}
