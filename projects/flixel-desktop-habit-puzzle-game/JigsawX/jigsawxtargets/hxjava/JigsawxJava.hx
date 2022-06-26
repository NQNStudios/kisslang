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

import jigsawx.Jigsawx;
import java.javax.swing.JPanel;
import java.awt.Color;
import java.awt.Rectangle;
import java.awt.Cursor;
import java.awt.event.KeyEvent;
import java.awt.event.KeyListener;
import java.awt.event.MouseAdapter;
import java.awt.event.MouseListener;
import java.awt.event.MouseMotionListener;
import java.awt.event.MouseEvent;
import java.awt.image.BufferedImage;
import java.awt.Image;
import java.awt.Point;
import java.javax.swing.JSlider;
import java.StdTypes;// Int64

#if applet
    import javax.swing.JApplet;
#elseif update_task
    import java.lang.System;
    import java.javax.swing.JFrame;
    import java.util.Timer;
    import java.util.TimerTask;
    import jigsawxtargets.hxjava.UpdateTask;
#else
    import java.lang.System;
    import java.javax.swing.JFrame;
#end

class JigsawxJava
#if applet
    extends JApplet 
#else
    extends JFrame
#end
implements KeyListener 
implements MouseListener 
implements MouseMotionListener
{
    
    var wid:                        Int;
    var hi:                         Int;
    var rows:                       Int;
    var cols:                       Int;
    var jigsawx:                    Jigsawx;
    var surface:                    Surface;
    var currentGraphic:             GraphicsTexture;
    var pressPoint:                 Point;
    var enabledMove:                Bool;
    var up                          = KeyEvent.VK_UP;
    var down                        = KeyEvent.VK_DOWN;
    var right                       = KeyEvent.VK_RIGHT;
    var left                        = KeyEvent.VK_LEFT;                      
    #if applet
        public static var japplet:  JigsawxJava;
    #elseif update_task
        var mutex:                  Dynamic;
        var updateTask:             UpdateTask;
        var updateTimer:            Timer;
        static var slowUpdateSpeed: Int64;
    #end
    
    inline static var   imageSrc:   String = "tablecloth.jpg";
    
    function setup()
    {
        setSize( 700, 500 );
        
        #if applet
            japplet = this;
        #else
            setDefaultCloseOperation( JFrame.EXIT_ON_CLOSE );
            setBackground( Color.black );
        #end
        
    }
    
    public static function main() { new JigsawxJava(); } public function new()
    {
        #if applet
            super();
        #else
            super( 'Jigsawx Java Example' );
            System.setProperty( "sun.java2d.opengl", "True" );
        #end
        
        setup();
        createSurface();
        
        setVisible( true );
    }
    
    function createSurface()
    {
        #if update_task
            var mutex = {};
        #end
        
        surface = new Surface( 
                                
                            );
        #if applet
        #elseif update_task
            surface.mutex = mutex;
        #end
        surface.graphicsTextures = createGraphicsTextures();
        getContentPane().add( surface );
        
        
        surface.addKeyListener( this );
        surface.setFocusable( true );
        surface.requestFocusInWindow();
        addMouseListener( this );
        addMouseMotionListener( this );
        
        #if update_task
            updateTimer         = new java.util.Timer();
            updateTask          = new UpdateTask();
            updateTask.newMore( surface, mutex );
            // Re-retrieve this value before directly starting the timer for max
            // accuracy.
            updateTask.oldTime  = System.nanoTime();
            // Start the timer in 0ms (right away), updating every
            // "slowUpdateSpeed" milliseconds
            slowUpdateSpeed     = 20;
            var startAt: Int64  = 0;
            updateTimer.schedule(   updateTask
                                ,   startAt
                                ,   slowUpdateSpeed 
                                );
        #end
        
    }
    
    public function mousePressed( e: MouseEvent )
    {
        for( graphicsTexture in surface.graphicsTextures )
        {
            if( graphicsTexture.jig.enabled == true )
            {
                var point = e.getPoint();
                pressPoint = new Point( 
                        cast graphicsTexture.getLocation().x - point.x
                    ,   cast graphicsTexture.getLocation().y - point.y );
                point.y -= 20;
                
                if( graphicsTexture.generalPath.contains( point ) ) 
                {
                    currentGraphic = graphicsTexture;
                    surface.moveToTop( graphicsTexture );
                    enabledMove = true;
                }
            }
        }
    }
    
    public function mouseDragged( e: MouseEvent ) 
    {
        if( enabledMove == true )
        {
            var x = e.getX();
            var y = e.getY();// + 20;
            
            if( checkLock( new Point( x, y ) ) == true ) return;
            currentGraphic.setLocation( x + pressPoint.x, y + pressPoint.y );
            
            #if applet 
                surface.repaint();
            #elseif update_task
                
            #else
                surface.repaint();
            #end
        }
    }
    
    public function mouseExited( e: MouseEvent ) 
    {
        enabledMove = false;
    }
    
    public function mouseMoved( e: MouseEvent ) {
        overCheck( e ); 
    }  
    
    public function overCheck( e: MouseEvent )
    {
        var showCursor = false;
        for( graphicsTexture in surface.graphicsTextures )
        {
            if( currentGraphic.jig.enabled == true )
            {
                var point   =  e.getPoint();
                point.y     -= 20;
                if( graphicsTexture.generalPath.contains( point ) ) 
                {
                    showCursor = true;
                }
            } 
        }
        if( showCursor ) 
        {
            e.getComponent().setCursor( 
                Cursor.getPredefinedCursor( Cursor.HAND_CURSOR )
                                    );
        } 
        else
        {
            e.getComponent().setCursor(
                Cursor.getPredefinedCursor( Cursor.DEFAULT_CURSOR )
                                    );
        }
    }
    
    public function mouseEntered( e: MouseEvent ) {}  
    public function mouseClicked( e: MouseEvent ) {}  
    public function mouseReleased( e: MouseEvent )
    {
        enabledMove = false;
    }
    
    private function checkLock( tempSp: Point ):Bool
    {   
        if( !enabledMove ) return true;
        var jig = currentGraphic.jig;
        if( jig == null ) return true;
        if( Math.abs( jig.xy.x - ( tempSp.x - wid ) ) < ( wid + hi )/7  &&
            Math.abs( jig.xy.y - ( tempSp.y - hi ) ) < ( wid + hi )/7 )
        {
            
            currentGraphic.setLocation( jig.xy.x, jig.xy.y );
            currentGraphic.alpha        = 1;
            jig.enabled                 = false;
            enabledMove                 = false;
            #if applet 
                surface.repaint();
            #elseif update_task
                
            #else
                surface.repaint();
            #end
            return true;
        }
        return false;
    }
    
    public function keyTyped( e: KeyEvent ){}
    public function keyReleased(e: KeyEvent ){}
    public function keyPressed( e: KeyEvent ) nudge( e );
    
    private function nudge( e: KeyEvent ){
        var location = currentGraphic.getLocation();
        switch( e.getKeyCode() )
        {
            case up:
                currentGraphic.setLocation( location.x, location.y - 1 );
            case down:
                currentGraphic.setLocation( location.x, location.y + 1 );
            case left:
                currentGraphic.setLocation( location.x - 1, location.y );
            case right:
                currentGraphic.setLocation( location.x + 1, location.y );
        }
        
        #if applet 
            surface.repaint();
        #elseif update_task
            
        #else
            surface.repaint();
        #end
    }
    
    function createGraphicsTextures(): Array<GraphicsTexture>
    {
        var arr         = new Array<GraphicsTexture>();
        rows            = 3;//6;
        cols            = 5;//10;
        wid             = 100;//50;
        hi              = 100;//50;
        jigsawx         = new Jigsawx( wid, hi, rows, cols );
        
        var count = 0;
        var isRandom = false;
        var unCompletedPieces = new Array<GraphicsTexture>();
        
        for( jig in jigsawx.jigs )
        {
            var rec  = new Rectangle(   Std.int( wid/2 )
                                    ,   Std.int( hi/2 )
                                    ,   Std.int( 360 * 3/2 )
                                    ,   Std.int( 240 * 3/2 ) 
                                    );
            
            var graphicsTexture = new GraphicsTexture(  jig
                                                    ,   imageSrc
                                                    ,   rec
                                                    ,   jig.xy.x
                                                    ,   jig.xy.y
                                                    );
            var randX = 0.;
            var randY = 0.;
            
            if( Math.random()*5 > 2 )
            {
                randX                   = Math.random()*200;
                randY                   = Math.random()*100; 
                isRandom                = true;
                graphicsTexture.alpha   = 0.6;
            }
            else
            {
                isRandom = false;
                graphicsTexture.jig.enabled = false;
            }
            
            graphicsTexture.setLocation( jig.xy.x + randX, jig.xy.y + randY );
            
            if( isRandom )
            {
                unCompletedPieces.push( graphicsTexture );
            }
            else
            {
                arr.push( graphicsTexture );
            }
            
            count++;
        }
        
        currentGraphic = arr[0];
        
        // push un completed on top
        for( graphicsTexture in unCompletedPieces ) arr.push( graphicsTexture );
        
        return arr;
        
    }
}



