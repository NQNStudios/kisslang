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

import java.util.Timer;
import java.util.TimerTask;
import java.javax.swing.JPanel;
import java.lang.System;
import java.StdTypes;// Int64

class UpdateTask extends TimerTask
{
    // Set true to limit fps (sleep the thread), false to not
    var limitingFPS:    Bool;
    // Set true to sync draws and updates together, false to not
    var syncingUpdates: Bool;
    public var oldTime:        Int64;
    var nanoseconds:    Int64;
    var frames:         Int;
    var updates:        Int;
    // Holds the latest calculated value of updates per second
    var fps:            Int;
    // Holds the latest calculated value of updates per second
    var ups:            Int;
    var jpanel:         JPanel;
    var mutex:          Dynamic;
    
    public function new()
    {
        super();
    }
    
    public function newMore(jpanel_: JPanel, mutex_: Dynamic )
    {
        jpanel = jpanel_;
        mutex = mutex_;
        init();
    }
    
    public function init()
    {
        oldTime         = System.nanoTime();
        limitingFPS     = true;
        syncingUpdates  = true;
        nanoseconds     = 0;
        frames          = 0;
        updates         = 0;
        fps             = 0;
        ups             = 0;
    }
    
    @:overload override public function run()
    {
        
        //synchronized( mutex )
        untyped __lock__( mutex, 
        {
            // Calculating a new fps/ups value every second
            if( nanoseconds >= 1000000000 )
            {
                fps = frames;
                ups = updates;
                nanoseconds = nanoseconds - 1000000000;
                frames = 0;
                updates = 0;
            }
            
            var elapsedTime: Int64 = System.nanoTime();
            elapsedTime = elapsedTime - oldTime;
            oldTime = oldTime - elapsedTime;
            nanoseconds = nanoseconds + elapsedTime;
            //update(elapsedTime);
            // An update occured, increment.
            updates++;

            // Ask for a repaint
            jpanel.repaint();
            1;
        });
        
        
    }
}
