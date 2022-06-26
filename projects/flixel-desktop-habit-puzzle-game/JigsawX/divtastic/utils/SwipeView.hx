
package utils;
import zpartanlite.Enumerables;
import core.DisplayDiv;
import zpartanlite.Pages;
import zpartanlite.DispatchTo;
import haxe.Timer;

class SwipeView
{
    
    
    private var velocity:           Int;    
    public var index0:              Int;
    public var index1:              Int;
    
    private var _old:               DisplayDiv;
    private var _curr:              DisplayDiv;
    private var _oldContent:        DisplayDiv;
    private var _distance:          Int;
    private var pages:              Pages<String>;
    private var _direction:         Orientation;
    private var _enabled:           Bool;
    public var pageChange:          DispatchTo;
    private var tim:                Float;
    private var timerMovement:      Timer;
    
    // _oldcontent should be within _old for this class to work
    public function new(    direction_:     Orientation
                        ,   distance_:      Int
                        ,   curr_:          DisplayDiv
                        ,   old_:           DisplayDiv
                        ,   oldContent_:    DisplayDiv
                        ,   pages_:         Pages<String>
                        )
    {
        
        pageChange  = new DispatchTo();
        _direction  = direction_;
        _distance   = distance_;
        _curr       = curr_;
        _old        = old_;
        pages      = pages_;
        _oldContent = oldContent_;
        _curr.setClip();
        _old.setClip();
        _oldContent.setClip();
        _enabled    = true;
        velocity    = 500;
        pages.pageChange.add( setImage );
        
    }
    
    
    public var orientation( get_orientation, set_orientation ):Orientation;
    
    private function get_orientation():Orientation
    {
        return _direction;
    }
    
    public function set_orientation( val: Orientation ): Orientation
    {
        _direction = val;
        return val;
    }
    
    
    public var enabled( get_enabled, set_enabled ):Bool;
    
    private function get_enabled(): Bool
    {
        
        return _enabled;
        
    }
    
    private function set_enabled( val: Bool )
    {
        var was = _enabled;
        _enabled = val;
        if( _enabled && was != _enabled )
        {
            pages.pageChange.add( setImage );
        }
        else if( !_enabled && was != _enabled )
        {
            pages.pageChange.remove( setImage );
        }
        return _enabled;
    }
    
    
    public function setImage()
    {
        _curr.visible    = false;
        _oldContent.visible     = false;
        var s:          Int;
        switch( pages.dir )
        { 
            case Forward:
                _oldContent.set_image( pages.last );
                index0 = pages.getLastIndex();
                _curr.set_image( pages.curr );
                index1 = pages.getIndex();
                s = 0;
            case Back:
                index0 = pages.getIndex();
                _oldContent.set_image( pages.curr );
                _curr.set_image( pages.last );
                index1 = pages.getLastIndex();
                s = _distance;
        }
        pageChange.dispatch();
        switch( _direction ) 
        {
            case Horizontal:
                _curr.width         = s; 
                _old.width          = _distance - s;
                _old.x              = _curr.x + s; 
                _oldContent.x       = -s;
            case Vertical:
                _curr.height        = s; 
                _old.height         = _distance - s;
                _old.y              = _curr.y + s; 
                _oldContent.y       = -s;
        }
        _curr.visible    = true;
        _oldContent.visible     = true;
        if( timerMovement != null )
        { 
            timerMovement.stop();
            timerMovement = null;
        }
        timerMovement = new Timer( 10 );
        tim = 0;
        var duration = 100;
        switch( _direction ) 
        {
            case Horizontal:
                timerMovement.run = swipeHorizMovement.bind( duration, pages.dir );
            case Vertical:
                timerMovement.run = swipeVertMovement.bind( duration, pages.dir );
        }
    }
    
    private function swipeHorizMovement( duration: Int, travel: Travel )
    {
        if ( tim > duration )
        {
            tim = 0;
            timerMovement.stop();
            timerMovement = null;
        }
        else
        {
            var e: Float;
            switch( travel )
            {
                case Forward:
                    e       = _distance*tim/duration;
                case Back:
                    e       = _distance - _distance*tim/duration;
            }
            
            _curr.width     = e;
            _old.width      = _distance - e;
            _old.x          = _curr.x + e; 
            _oldContent.x   = -e;
            tim++;
        }
        
    }
    
    private function swipeVertMovement( duration: Int, travel: Travel )
    {
        if ( tim > duration )
        {
            tim = 0;
            timerMovement.stop();
            timerMovement = null;
        }
        else
        {
            
            var e: Float;
            switch( travel )
            {
                case Forward:
                    e       = _distance*tim/duration;
                case Back:
                    e       = _distance - _distance*tim/duration;
            }
            
            _curr.height     = e; 
            _old.height      = _distance - e;
            _old.y           = _curr.y + e; 
            _oldContent.y           = -e;
            tim++;
        }
    }
    
}
