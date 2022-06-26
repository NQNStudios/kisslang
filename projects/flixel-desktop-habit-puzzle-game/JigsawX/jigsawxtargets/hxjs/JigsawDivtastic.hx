/*
* Copyright (c) 2012, Justinfront Ltd
*   author:  Justin L Mills
*   email:   JLM at Justinfront dot net
*   created: 17 June 2012
* All rights reserved.
*
* Redistribution and use in source and binary forms, with or without
* modification, are permitted provided that the following conditions are met:
*     * Redistributions of source code must retain the above copyright
*       notice, this list of conditions and the following disclaimer.
*     * Redistributions in binary form must reproduce the above copyright
*       notice, this list of conditions and the following disclaimer in the
*       documentation and/or other materials provided with the distribution.
*     * Neither the name of the Justinfront Ltd nor the
*       names of its contributors may be used to endorse or promote products
*       derived from this software without specific prior written permission.
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


package jigsawxtargets.hxjs;

import js.Browser;

import core.DisplayDiv;
import js.html.Event;
import js.html.MouseEvent;
import haxe.Timer;
import js.html.CanvasRenderingContext2D;
import jigsawx.JigsawPiece;
import jigsawx.Jigsawx;
import jigsawx.math.Vec2;
import js.html.ImageElement;
import core.ImageLoader;
import haxe.ds.StringMap;
import core.SetupCanvas;
//https://developer.mozilla.org/En/Manipulating_video_using_canvas

using core.GlobalDiv;

class JigsawDivtastic
{
    
    var holder:                     DisplayDiv;
    var hit:                        DisplayDiv;
    var jigsawx:                    Jigsawx;
    var visualSource:               DisplayDiv;
    var wid:                        Float;
    var hi:                         Float;
    var rows:                       Int;
    var cols:                       Int;
    var count:                      Int;
    var atimer:                     Timer;
    var depth:                      Int;
    var tiles:                      Array<DisplayDiv>;
    var surfaces:                   Array<CanvasRenderingContext2D>;
    var loader:                     ImageLoader;
    inline static var videoSrc:     String = 'big_buck_bunny.webm';
    inline static var imageSrc:     String = "tablecloth.jpg";
    
    static function main(){ new JigsawDivtastic(); }
    
    public function new()
    {
        
        holder                          = new DisplayDiv() ;
        holder.x                        = 0 ;
        holder.y                        = 0 ;
        holder.width                    = 520 ;
        holder.height                   = 260 ;
        count                           = 0;
        addChild( holder ) ;
        
        
        createVisuals();
        createHit();
        #if !noVideo 
        visualDisplay(); 
        #else
        loader = new ImageLoader( [ imageSrc ], onLoaded );
        #end
    }
    
    public function onLoaded()
    {
        var count = 0;
        var images: StringMap<ImageElement> = loader.images;	    
        var tablecloth                      = images.get('tablecloth.jpg');
        var xy                              = new Vec2( 20, 20 );
        for( row in 0...rows )
        {
            
            for( col in 0...cols )
            {
                
                surfaces[ count ].drawImage( tablecloth, 32 - xy.x, 42 - xy.y, tablecloth.width*0.81, tablecloth.height*0.81 );
                xy.x                    += wid;
                count++;
            }
            
            xy.x                        = 20;
            xy.y                        += hi;
            
        }
    }
    
    
    public function createHit()
    {
        
        hit                             = new DisplayDiv() ;
        hit.x                           = 0 ;
        hit.y                           = 0 ;
        hit.width                       = 1000 ;
        hit.height                      = 1000 ;
        hit.getStyle().cursor           = 'pointer';
        hit.getStyle().zIndex           = Std.string( 1000000000 );
         
        addChild( hit ) ;
        hit.press.add( checkForDrag );
        
    }
    
    
    public function checkForDrag()
    {
        
        ROOT().onmousemove              = null;
        
        var pos                         = hit.getGlobalMouseXY();
        var px                          = pos.first();
        var py                          = pos.last();
        var distance                    = 1000000000.;
        
        // set a default value
        var closest                     = tiles[ 0 ];
        var jig                         = jigsawx.jigs[ 0 ];
        var surface                     = surfaces[ 0 ];
        var currI                       = 0;
        
        var dx:                         Float;
        var dy:                         Float;
        var dr2:                        Float;
        var vXY:                        DisplayDiv;
        
        for( i in 0...tiles.length )
        {
            
            if( jigsawx.jigs[ i ].enabled )
            {
                
                dx                      = tiles[ i ].x - px;
                dy                      = tiles[ i ].y - py;
                dr2                     = dx * dx + dy * dy;
                
                if( dr2 < distance )
                {
                    
                    closest             = tiles[ i ];
                    jig                 = jigsawx.jigs[ i ];
                    surface             = surfaces[ i ];
                    distance            = dr2; 
                    currI               = i;
                }
                
            }
            
        }
        
        var wid_                        = wid/2;
        var hi_                         = hi/2;
        
        if( distance < wid * hi )
        {
            
            closest.getStyle().zIndex   = Std.string( depth++ );
            
            ROOT().onmouseup            = function( e: Event )
            {
                var em: MouseEvent = cast e;
                if( closest.alpha != 1 )
                {
                    closest.x               = em.clientX - wid_/2;
                    closest.y               = em.clientY - hi_/2;
                    closest.alpha           = 0.74;
                }
                
                if(  Math.abs( jig.xy.x - closest.x ) < ( wid_ + hi_ )/6  &&  Math.abs( jig.xy.y - closest.y ) < ( wid_ + hi_ )/6 )
                {
                    
                    closest.x           = jig.xy.x;
                    closest.y           = jig.xy.y;
                    //drawEdge( surface, jigsawx.jigs[ currI ], 'white' );
                    closest.alpha       = 1;
                    jig.enabled         = false;
                    
                }
                
                ROOT().onmousemove      = null;
                
            }
            
            ROOT().onmousemove          = function( e: Event )
            { 
                var em: MouseEvent = cast e;
                if( closest.alpha != 1 )
                {
                    closest.x               = em.clientX - wid_/2;
                    closest.y               = em.clientY - hi_/2;
                    closest.alpha           = 0.87;
                }
            }
        }
        
    }
    
    
    public function drawEdge(   surface:    CanvasRenderingContext2D
                            ,   jig:        JigsawPiece
                            ,   c:          String
                            )
    {
        surface.strokeStyle             = c;
        surface.lineWidth               = 2;
        surface.beginPath();
        
        var first                       = jig.getFirst();
        
        surface.moveTo( first.x + 3, first.y + 3 );
        
        for( v in jig.getPoints() )    surface.lineTo(  v.x  + 3,  v.y  + 3 );
        
        surface.stroke();
        surface.closePath();
        // make it a mask
        surface.clip();
        
    }
    
    
    
    
    public function visualDisplay()
    {
        //371x262
        visualSource                     = new DisplayDiv( videoSrc );
        
        visualSource.x                   = 0;
        visualSource.y                   = 0;
        visualSource.width               = 10;
        visualSource.height              = 10;
        
        // if you want to show the source video ( or image) uncomment this line:
        holder.addChild( visualSource ) ;
        visualSource.play();
        visualSource.getStyle().position = 'absolute';
        
        atimer                          = new Timer( 40 );
        atimer.run                      = copyAcross;
        
    }
    
    
    public function createVisuals()
    {
        
        var sp:             DisplayDiv;
        // holder for canvs
        var canvasSp:       DisplayDiv;
        var surface:        CanvasRenderingContext2D;
        var first:          Vec2;
        
        surfaces                        = [];
        tiles                           = [];
        rows            = 3;//6;
        
        #if !noVideo
        cols            = 5;//10;
        #else
        cols            = 4;
        #end
        
        wid             = 70;//100//50;
        hi              = 70;//100//50;
        jigsawx                         = new Jigsawx( wid, hi, rows, cols );
        depth                           = 0;
        
        for( jig in jigsawx.jigs )
        {
            
            // create sprite and surface
            sp                          = new DisplayDiv();
            holder.addChild( sp );
            tiles.push( sp );
            
            // if you want to check position
            //sp.fill                   = '#ffffff';
            
            sp.x                        = jig.xy.x;
            sp.y                        = jig.xy.y;
            sp.width                    = 0;
            sp.height                   = 0;
            canvasSp                    = new DisplayDiv( 'canvas' );
            canvasSp.x                  = -wid/2 + -5;
            canvasSp.y                  = -hi/2 + -5;
            surface                     = canvasSp.twoD;
            sp.getStyle().zIndex        = Std.string( depth++ );
            
            sp.addChild( canvasSp );
            
            // select a random number to be out of place ( 2/5 th's )
            if( Math.random()*5 > 2 )
            {
                
                sp.x                    = 215+520/2 - Math.random()*(520-350);
                sp.y                    = 260/2 - Math.random()*255/2 + 15;
                sp.alpha                = 0.74;
                
                drawEdge( surface, jig, 'white' );
                
            }
            else
            {
                
                // Disable movement of correctly placed jigsaw pieces
                jig.enabled = false;
                drawEdge( surface, jig, 'white' );
                
            }
            
            surfaces.push( surface );
            
        }
        
    }
    
    
    private function copyAcross()
    {
        
        count++;
        
        // if you want to stop video early
        //if( count > 1000 ) atimer.stop();
        
        var xy                          = new Vec2( 20, 20 );
        trace( visualSource.getInstance() );
        var image: ImageElement         = cast visualSource.getInstance();
        var count                       = 0;
        
        for( row in 0...rows )
        {
            
            for( col in 0...cols )
            {
                
                surfaces[ count ].drawImage( image, -xy.x, -xy.y );
                
                xy.x                    += wid;
                count++;
                
            }
            
            xy.x                        = 20;
            xy.y                        += hi;
            
        }
        
    }
    
    
}