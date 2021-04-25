package asciilib;

interface GraphicsBackend {
    function initialize(title:String, width:Int, height:Int, letterWidth:Int, letterHeight:Int):Void;
    function draw(graphics:Graphics):Void;
}
