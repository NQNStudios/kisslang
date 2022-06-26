
package utils;

import core.DisplayDiv;
import core.GradientFiller;
import haxe.Timer;
import zpartanlite.Enumerables;
import core.WebBrowser;
import zpartanlite.DispatchTo;

// Example draggable window.  
// Note: Requires fillColor.png for header bar.
// The displayDiv for WindowView is passed in rather than inherited so that a Divtastic DisplayDiv can be used if required.

using core.DivDrawing;
class WindowView
{
    
    public static inline var headerHeight:  Int = 20;
    private var headerBarBg:                DisplayDiv;
    private var bodyBg:                     DisplayDiv;
    private var headerBarTitle:             DisplayDiv;
    private var minimizeButton:             DisplayDiv;
    private var minimizeButtonBg:           DisplayDiv;
    private var heightMax:                  Int;
    private var widthMax:                   Int;
    private var widthMin:                   Int;
    private var _holder:                    DisplayDiv;//Divtastic;
    private var gradFill:                   GradientFiller;
    public var onMinimized:                 DispatchTo;
    public var onMaximized:                 DispatchTo;
    public var timerMovement:               Timer;
    public var tim:                         Float;
    
    public function new(    holder_:    DisplayDiv, 
                            title_:     String, 
                            x_:         Int, 
                            y_:         Int, 
                            width_:     Int, 
                            height_:    Int, 
                            fill_:      String
                        )
    {
        
        onMinimized             = new DispatchTo();
        onMaximized             = new DispatchTo();
        _holder                 = holder_;
        _holder.x               = x_;
        _holder.y               = y_;
        _holder.width           = width_;
        _holder.height          = height_;
        heightMax               = height_;
        widthMax                = width_;
        headerBarBg             = new DisplayDiv();
        headerBarBg.tile        = true;
        headerBarBg.x           = 0;
        headerBarBg.y           = 0;
        headerBarBg.height      = headerHeight;
        headerBarBg.width       = width_;
       
        headerBarBg.set_image('img/fillColor.png');
        _holder.addChild( headerBarBg );
        headerBarBg.setupParentDrag();
        
        headerBarTitle          = new DisplayDiv();
        headerBarTitle.x        = 9;
        headerBarTitle.y        = 4;
        
        
        headerBarTitle.getStyle().cursor = "pointer";
        headerBarBg.addChild( headerBarTitle );
        
        
        var txStyle             = headerBarTitle.getStyle();
        txStyle.fontFamily      = 'Arial';
        txStyle.color           = '#aaaaaa';
        txStyle.lineHeight      = '1.3';
        txStyle.letterSpacing   = '1px';
        txStyle.fontSize        = '10px';
        title                   = title_;        
        widthMin                = Std.int( headerBarTitle.width + headerBarTitle.x + 30 );
        
        bodyBg                  = new DisplayDiv();
        bodyBg.x                = 0;
        bodyBg.fill             = fill_;
        bodyBg.y                = headerHeight;
        bodyBg.height           = height_ - headerHeight;
        bodyBg.width            = width_;
        
        _holder.addChild( bodyBg );
        //_holder.alpha           = 0.9;
        minimizeButton          = new DisplayDiv();
        minimizeButton.x        = width_ - 18 - 4 + 1;
        minimizeButton.y        = 7;
        minimizeButton.width    = 15;
        minimizeButton.height   = 10;
        var closeDivs           = minimizeButton.drawGradHexagon(   0
                                                                ,   0
                                                                ,   9 + 2
                                                                ,   6
                                                                ,   0xd67297
                                                                ,   0xd67297
                                                                ,   1
                                                                ,   Horizontal
                                                                );
        headerBarBg.addChild( minimizeButton );
        
        //currently not supported
        if ( WebBrowser.browserType != IE )
        {
            _holder.getStyle().overflow     = 'Hidden';        
        }
        
        gradFill                        = new GradientFiller( closeDivs );
        minPressSetup() ;
        
    }
    
    private var _title: String;
    public var title( get_title, set_title ): String;
    
    public function get_title(): String
    {
        return _title;
    }
    
    public function set_title( title_: String ): String
    {   
        headerBarTitle.text = title_;
        _title = title_;
        widthMin                = Std.int( headerBarTitle.width + headerBarTitle.x + 30 );
        return title_;
    }
    
    
    public function set_fill( fill: Int ): Int
    {
        //TODO: Need to simplify this code!!
        bodyBg.fill = '#' + StringTools.lpad( StringTools.hex( (fill >> 16) << 16 | ( fill >> 8 & 0xff) << 8 | ( fill & 0xff ) ), '0', 6 );
        return fill;
    }
    
    
    public function minPressSetup()
    {
        
        minimizeButton.press.swap( maximize, minimize );
        onMinimized.dispatch();
        
    }
    
    
    public function minimize()
    {
        
        gradFill.fill( 0x9d9e6a, 0x9d9e6a );
        if( timerMovement != null )
        { 
            timerMovement.stop();
            timerMovement = null;
        }
        timerMovement       = new Timer( 10 );
        tim                 = 0;
        var duration        = 50;
        timerMovement.run   = minimizeMove.bind( _holder, duration );
    }
    
    public function minimizeMove( instance: DisplayDiv, duration )
    {
        if ( tim > duration )
        {
            tim = 0;
            timerMovement.stop();
            timerMovement = null;
            maxPressSetup();
        }
        else
        {
            var t               = 1 - tim/duration;
            instance.height     = t*( heightMax - headerHeight ) + headerHeight;
            instance.width      = t*( widthMax - widthMin ) + widthMin;
            minimizeButton.x    = instance.width - 18 - 4 + 1;
            tim++;
        }
    
    }
    
    
    public function maxPressSetup()
    {
        
        minimizeButton.press.swap( minimize, maximize );
        onMaximized.dispatch();
        
    }
    
    
    public function maximize()
    {
        
        gradFill.fill( 0xd67297, 0xd67297 );
        if( timerMovement != null )
        { 
            timerMovement.stop();
            timerMovement = null;
        }
        timerMovement       = new Timer( 10 );
        tim                 = 0;
        var duration        = 50;
        timerMovement.run   = maximizeMove.bind( _holder, duration );
    }

    public function maximizeMove( instance: DisplayDiv, duration )
    {
        if ( tim > duration )
        {
            tim = 0;
            timerMovement.stop();
            timerMovement = null;
            minPressSetup();
        }
        else
        {
            var t               = tim/duration;
            instance.height     = t*( heightMax - headerHeight ) + headerHeight;
            instance.width      = t*( widthMax - widthMin ) + widthMin;
            minimizeButton.x    = instance.width - 18 - 4 + 1;
            tim++;
        }

    }
    
    
    // TODO add functionality for changing height and width of box.
    
}
