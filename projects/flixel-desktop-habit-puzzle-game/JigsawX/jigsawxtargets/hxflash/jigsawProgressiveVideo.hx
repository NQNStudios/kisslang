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


package jigsawxtargets.hxflash;

import flash.Lib;
import flash.display.Sprite ;
import flash.display.Graphics;
import flash.events.MouseEvent;

import flash.display.Bitmap;
import flash.display.BitmapData;
import flash.geom.Rectangle;
import flash.geom.Point;
import flash.display.PixelSnapping;
import flash.geom.Matrix;

import haxe.Timer;

import jigsawx.JigsawPiece ;
import jigsawx.Jigsawx;
import jigsawx.math.Vec2;
import zpartan.media.WebCameraView;
import zpartan.media.ProgressiveVideo;
import flash.net.NetConnection;


class JigsawProgressiveVideo
{
    
    
    private var progressiveVideo:       ProgressiveVideo;
    private var webcam:                 WebCameraView;
    
    private var holder :                Sprite;
    private var hit:                    Sprite;
    private var jigsawx :               Jigsawx;
    private var videoSource:            Sprite;
    private var wid:                    Float;
    private var hi:                     Float;
    private var rows:                   Int;
    private var cols:                   Int;
    private var count:                  Int;
    private var atimer:                 Timer;
    private var depth:                  Int;
    
    private var tiles:                  Array<Sprite>;
    private var surfaces:               Array<Bitmap>;
    private var offset:                 Array<Vec2>;
    private var current:                Sprite;
    
    private var videoHolder:            Sprite;
    
    private inline static var videoSrc:        String = 'big_buck_bunny.flv';
    
    
    static function main(){ new JigsawProgressiveVideo(); }
    
    public function new()
    {
        
        current                         = Lib.current;
        holder                          = new Sprite();
        holder.x                        = 0;
        holder.y                        = 0;
        
        current.addChild( holder ) ;
        count                           = 0;
        rows                            = 8;
        cols                            = 8;
        wid                             = 40;
        hi                              = 40;
        
        createVisuals();
        #if !noVideo
            progressiveVideoDisplay();
        #end
        
        var allTiles = tiles;
        Lib.current.addEventListener( MouseEvent.MOUSE_UP, function( e: MouseEvent )
        {
            
            // TODO: Need to add is close snap code for this case...
            for( all in allTiles ) all.stopDrag();
            
        });
        
    }
    
    
    public function progressiveVideoDisplay()
    {
        
        var progressiveVideo           = new ProgressiveVideo();
        videoHolder                    = progressiveVideo.getHolder();
        progressiveVideo.setVideo( videoSrc );
        progressiveVideo.playVideo();
        
        atimer = new Timer( 40 );
        atimer.run = copyAcross;
        
        #if showCamSource
        
            videoHolder                    = progressiveVideo.getHolder();
            videoHolder.x                  = 0;
            videoHolder.y                  = 0;
            holder.addChild( videoHolder );
            
        #end
        
        
        
    }
    
    
    private function copyAcross()
    {
        count++;
        
        //if( count > 1000 ) atimer.stop();
        
        var off:    Vec2;
        var xy              = new Vec2( 0, 0 );
        var count           = 0;
        
        for( row in 0...rows )
        {
            
            for( col in 0...cols )
            {
                
                off     = offset[ count ];
                // optimisation could try render blitting to single surface and implement dragging in the same way as javascript.
                // scale 1.2 times
                surfaces[ count ].bitmapData.draw( videoHolder, new Matrix( 1.2, 0, 0, 1.2, -xy.x - off.x, -xy.y - off.y) );
                
                xy.x    += wid;
                count++;
                
            }
            
            xy.x        = 0;
            xy.y        += hi;
            
        }
        
    }
    
    
    public function createVisuals()
    {
        
        var sp:             Sprite;
        var maskSp:         Sprite;
        var tile:           Sprite;
        
        var surface:        Graphics;
        tiles                           = [];
        surfaces                        = [];
        offset                          = [];
        var first:          Vec2;
        
        jigsawx                         = new Jigsawx( wid, hi, rows, cols );
        depth                           = 0;
        
        for( jig in jigsawx.jigs )
        {
            
            // create sprite and surface and mask
            
            sp                          = new Sprite();
            tiles.push( sp );
            holder.addChild( sp );
            tile                        = new Sprite();
            sp.addChild( tile );
            
            //sp.fill                   = '#ffffff';
            
            sp.x                        = jig.xy.x;
            sp.y                        = jig.xy.y;
            maskSp                      = new Sprite();
            tile.mask                   = maskSp;
            maskSp.x                  = -wid/2;
            maskSp.y                  = -hi/2;
            surface                     = maskSp.graphics;
            
            sp.addChild( maskSp );
            
            // local copies so that local functions can get the the current loop variables, not sure if they are all needed.
            var tempSp                          = sp;
            var wid_                            = wid/2;
            var hi_                             = hi/2;
            var ajig                            = jig;
            
            // Select some pieces out of place.
            if( Math.random()*5 > 2 )
            {
                
                sp.x                                = 600 - Math.random()*200;
                sp.y                                = 400 - Math.random()*400;
                sp.alpha                            = 0.7;
                
                drawEdge( surface, jig, 0x0000ff );
                
                sp.addEventListener( MouseEvent.MOUSE_DOWN, function( e: MouseEvent )
                {
                    
                    tempSp.parent.addChild( tempSp );
                    tempSp.startDrag();
                    
                });
                
                
                sp.addEventListener( MouseEvent.MOUSE_UP, function( e: MouseEvent )
                {
                    
                    if( Math.abs( ajig.xy.x - tempSp.x ) < ( wid_ + hi_ )/4  &&  Math.abs( ajig.xy.y - tempSp.y ) < ( wid_ + hi_ )/4 )
                    {
                        
                        tempSp.x                    = ajig.xy.x;
                        tempSp.y                    = ajig.xy.y;
                        tempSp.alpha                = 1;
                        jig.enabled                 = false;
                        tempSp.mouseEnabled         = false;
                        tempSp.mouseChildren        = false;
                        tempSp.buttonMode           = false;
                        tempSp.useHandCursor        = false;
                        
                    }
                    
                    tempSp.stopDrag();
                    
                });
                
            }
            else
            {
                
                maskSp.alpha                        = 0;
                jig.enabled                         = false;
                tempSp.mouseEnabled                 = true;
                tempSp.mouseChildren                = true;
                tempSp.buttonMode                   = true;
                tempSp.useHandCursor                = true;
                
                drawEdge( surface, jig, 0x000000 );
                
            }
            
            var bounds                              = maskSp.getBounds( sp );
            tile.x                                  = bounds.x;
            tile.y                                  = bounds.y;
            var tileW                               = Std.int( maskSp.width );
            var tileH                               = Std.int( maskSp.height );
            var bd                                  = new BitmapData( tileW, tileH, true, 0x000000 );
            var bm                                  = new Bitmap( bd, PixelSnapping.ALWAYS, true );
            
            // May not need this line... possibly change bm to not transparent.
            bd.fillRect( new Rectangle( 0, 0, tileW, tileH ), 0xff000000 );
            
            tile.addChild( bm );
            surfaces.push( bm );
            offset.push( new Vec2( bounds.x, bounds.y ) );
            
        }
        
    }
    
    
    public function drawEdge( surface: Graphics, jig: JigsawPiece, c: Int )
    {
        
        surface.lineStyle( 1, c, 1 );
        surface.beginFill( c, 1 );
        var first = jig.getFirst();
        
        surface.moveTo( first.x, first.y );
        
        for( v in jig.getPoints() )  {  surface.lineTo( v.x, v.y ); }
        
        surface.endFill();
        
    }
    
    
}