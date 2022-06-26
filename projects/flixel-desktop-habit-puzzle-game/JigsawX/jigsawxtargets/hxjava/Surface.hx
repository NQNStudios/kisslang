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

import java.awt.Graphics;
import java.awt.Graphics2D;
import java.awt.RenderingHints;

import java.javax.swing.JPanel;

import jigsawxtargets.hxjava.GraphicsTexture;

class Surface extends JPanel
{
    
    public var graphicsTextures:    Array<GraphicsTexture>;
    
    #if applet
    #elseif update_task
    public var mutex:                  Dynamic;
    #else
    #end
    
    public function moveToTop( graphicsTexture: GraphicsTexture )
    {
        graphicsTextures.remove( graphicsTexture );
        graphicsTextures.push( graphicsTexture );
    }
    
    public function new()
    {
        super( true );
    }
    @:overload override 
    public function paintComponent( g: Graphics )
    {
        
        #if applet
        #elseif update_task
        untyped __lock__(mutex,
        {
        #else
        #end
            super.paintComponent( g );
            var g2D: Graphics2D = cast g;
            g2D.setRenderingHint(RenderingHints.KEY_ANTIALIASING,
                                RenderingHints.VALUE_ANTIALIAS_ON );
            g2D.setRenderingHint(RenderingHints.KEY_RENDERING,
                                RenderingHints.VALUE_RENDER_QUALITY );
            for( i in 0...graphicsTextures.length ) graphicsTextures[ i ].render( g2D );
            g2D.dispose();
            1;
        #if applet
        #elseif update_task
        });
        #else
        #end
        
        
    }
  
}
