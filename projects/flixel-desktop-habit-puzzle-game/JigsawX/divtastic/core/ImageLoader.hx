
package core;
import js.Lib;
import js.html.ImageElement;
import js.html.Event;
import js.html.Document;
import js.Browser;
typedef Hash<T> = haxe.ds.StringMap<T>;

class ImageLoader
{
    
    public var images:  Hash<ImageElement>;
    
    private var loaded: Void -> Void;
    private var count: Int;
    
	public function new( imageNames: Array<String>, loaded_: Void -> Void )
    {
        images = new Hash();
        loaded = loaded_;
        count = imageNames.length;
        for( name in imageNames ) load( name );        
    }
      
    private function load( img: String )
    { 
	    var image: ImageElement     = js.Browser.document.createImageElement();
	    var imgStyle                = image.style;
	    imgStyle.left               = '0px';
        imgStyle.top                = '0px';
        imgStyle.paddingLeft        = "0px";
        imgStyle.paddingTop         = "0px";
	    image.onload                = store.bind( image, img.split('/').pop() );
	    imgStyle.position           = "absolute";
	    image.src                   = img;
	}
	
	private function store( image: ImageElement, name: String,  e: Event )
	{
	    count--;
	    trace( 'store ' + name + ' ' + count );
	    images.set( name, image );
	    if( count == 0 )
	    {
	        loaded();
	    }
	}
		
}
