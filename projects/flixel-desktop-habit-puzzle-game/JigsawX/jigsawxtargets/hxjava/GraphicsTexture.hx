/*
* Copyright (c) 2013 Justinfront Ltd
* author: Justin L Mills
* email: JLM at Justinfront dot net
* created: 8 August 2013
* language: Haxe 3
* All rights reserved.
*
* Redistribution and use in source and binary forms, with or without
* modification, are permitted provided that the following conditions are met:
* * Redistributions of source code must retain the above copyright
* notice, this list of conditions and the following disclaimer.
* * Redistributions in binary form must reproduce the above copyright
* notice, this list of conditions and the following disclaimer in the
* documentation and/or other materials provided with the distribution.
* * Neither the name of the Justinfront Ltd nor the
* names of its contributors may be used to endorse or promote products
* derived from this software without specific prior written permission.
*
* THIS SOFTWARE IS PROVIDED BY Justinfront Ltd ''AS IS'' AND ANY
* EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
* WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
* DISCLAIMED. IN NO EVENT SHALL Justinfront Ltd BE LIABLE FOR ANY
* DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
* (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
* LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
* ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
* (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
* SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/


package jigsawxtargets.hxjava;

import java.awt.geom.AffineTransform;
import java.awt.geom.GeneralPath;
import java.awt.TexturePaint;
import java.awt.image.BufferedImage;
import java.awt.Image;
import java.awt.Graphics2D;
import java.awt.Rectangle;
import java.awt.image.RescaleOp;

import java.NativeArray;
import java.javax.imageio.ImageIO;

import jigsawx.JigsawPiece;
import jigsawx.math.Vec2;
import jigsawxtargets.hxjava.JigsawxJava;

#if applet
    import java.javax.swing.JApplet;
    import java.net.URL;
    
#else
    import java.io.File;
    import java.io.IOException;
#end

class GraphicsTexture
{
    
    public var textureRectangle:    Rectangle;
    public var generalPath:         GeneralPath;
    var x:                          Float = 0;
    var y:                          Float = 0;
    var sx:                         Float;
    var sy:                         Float;
    public var jig:                 JigsawPiece;
    public var image:               BufferedImage;
    
    @:isVar var texturePaint( get, null ):   TexturePaint;
    
    public function new(    jig_:                   JigsawPiece 
                        ,   imageSrc:               String
                        ,   textureRectangle_ :     Rectangle
                        ,   sx_:                    Float
                        ,   sy_:                    Float
                        )
    {
        
        
        jig = jig_;
        createPath( jig_ );
        sx = sx_;
        sy = sy_;
        alpha = 1.;
        image = GraphicsTexture.bufferedImage( imageSrc );
        textureRectangle = textureRectangle_;
        
    }
    
    @:isVar public var alpha( get, set ): Float;
    public function get_alpha( ) : Float
    {
        return alpha;
    }
    public function set_alpha( alpha_: Float ): Float
    {
        alpha = alpha_;
        return alpha;
    }
    
    
    private function createPath( jig: JigsawPiece )
    {
        generalPath = new GeneralPath();
        var first   = jig.getFirst();
        generalPath.moveTo( first.x, first.y );
        for( v in jig.getPoints() ) generalPath.lineTo( v.x, v.y );
        generalPath.closePath();
    }
    
    public function get_texturePaint( ): TexturePaint
    {
        return texturePaint;
    }
    
    public function getLocation(): Vec2
    {
        return new Vec2( x, y );
    }
    
    public function setLocation( x_: Float, y_: Float )
    {
        generalPath.transform( AffineTransform.getTranslateInstance( x_ - x, y_ - y ) );
        textureRectangle = new Rectangle( Std.int( x_ - sx + 25 )
                                        , Std.int( y_ - sy + 25)
                                        , Std.int( 360 * 3/2 )
                                        , Std.int( 240 * 3/2 ) );
        texturePaint = new TexturePaint( cast image, textureRectangle );
        x = x_; 
        y = y_;
    }
    
    public function render( g2D: Graphics2D )
    {
        
        g2D.setClip( generalPath );
        
        var arr = [ 1., 1., 1., alpha ];
        var scaleFactors = new NativeArray<Single>( 4 ); 
        for ( i in 0...arr.length ) scaleFactors[ i ] = arr[ i ];
        
        var offsets =  new NativeArray<Single>( 4 );
        for ( i in 0...arr.length ) offsets[ i ] = arr[ i ];
        arr = [ 0., 0., 0., 0. ];
        
        var rescaleOp = new RescaleOp( scaleFactors, offsets, null ); 
        var alphaImage = rescaleOp.filter( image, null );
        g2D.drawImage(  alphaImage
                    ,   textureRectangle.x
                    ,   textureRectangle.y
                    ,   textureRectangle.width
                    ,   textureRectangle.height
                    ,   null );
        
    }
    
    public static function bufferedImage( imageSrc: String ): BufferedImage
    {
        try{
            var alphaImage = new BufferedImage( 100, 50
                                            ,   BufferedImage.TYPE_INT_ARGB );
            #if applet
                // Issue with permissions
            #else
                var file = new File( imageSrc );
                var loadedImg = ImageIO.read( file );
                alphaImage = new BufferedImage( 
                                                loadedImg.getWidth( null )
                                            ,   loadedImg.getHeight( null )
                                            ,   BufferedImage.TYPE_INT_ARGB); 
                alphaImage.getGraphics().drawImage( loadedImg, 0, 0, null );
            #end 
            return alphaImage;
        }
        catch
            #if applet
                ( e: Dynamic )
            #else
                ( e: IOException )
            #end
        {
            #if applet 
                e.printStackTrace();
            #end
            trace('image load fail');
        }
        return new BufferedImage( 100, 50, BufferedImage.TYPE_INT_ARGB );
    }
    
}
