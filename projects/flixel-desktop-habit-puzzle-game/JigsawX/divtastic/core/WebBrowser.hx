
package core;

import js.Lib;
import js.Browser;
enum BrowserType
{
    Chrome;
    Safari;
    WebKitOther;
    FireFox;
    Opera;
    IE;
}

class WebBrowser
{
	
    private static var _browserType:    BrowserType;
	private static var _userAgent:		String;
	
    public static var browserType( get_browserType, null ): BrowserType;
    private static var _hasCanvas2d:	Bool;
	public static var hasCanvas2d( get_hasCanvas2d, null ): Bool;
    
	private static function get_hasCanvas2d(): Bool
	{
		
		if( _hasCanvas2d == null )
		{
			
			set_hasCanvas2d();
			
		}
		return _hasCanvas2d;
		
	}
	
	private static function set_hasCanvas2d()
	{
		
		if( Browser.document.createCanvasElement().getContext == null )
		{
			
			_hasCanvas2d = false;
			
		}
		else
		{
			
			_hasCanvas2d = true;
			
		}
		
	}
	
    private static function get_browserType(): BrowserType
    {
        
        if( _browserType == null )
        {
            
            set_browserType( Browser.window.navigator.userAgent );
            
        }
        
        return _browserType;
        
    }
    
	public static function traceAgent()
	{
		get_browserType();
		trace( _userAgent );
	}
    
    private static function set_browserType( agent: String ): BrowserType
    {
		
        _userAgent = agent;
		
        if( (~/WebKit/).match( agent ) )
        {
            
            if((~/Chrome/).match( agent ) )
            {
                
                _browserType = Chrome;
                
            }
            else if( (~/Safari/).match( agent ) )
            {
                
                _browserType = Safari;
                
            }
            else
            {
            
                _browserType = Opera;
            
            }
            
        }
        else if( (~/Opera/).match( agent ) )
        {
            //(__js__("typeof window!='undefined'") && window.opera != null );
            _browserType = Opera;
            
        }
        else if( (~/Mozilla/).match( agent ) )
        {
			 
			var isIE = untyped (__js__("typeof document!='undefined'") && document.all != null && __js__("typeof window!='undefined'") && window.opera == null );
            if ( isIE )
            {
                _browserType = IE;
            }
            else
            {
                _browserType = FireFox;
			}
        }
        else
        {
            _browserType = IE;
        }
        
        return _browserType;
        
    }
    
}
