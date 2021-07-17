/******************************************************************************
 * Spine Runtimes Software License v2.5
 *
 * Copyright (c) 2013-2016, Esoteric Software
 * All rights reserved.
 *
 * You are granted a perpetual, non-exclusive, non-sublicensable, and
 * non-transferable license to use, install, execute, and perform the Spine
 * Runtimes software and derivative works solely for personal or internal
 * use. Without the written permission of Esoteric Software (see Section 2 of
 * the Spine Software License Agreement), you may not (a) modify, translate,
 * adapt, or develop new applications using the Spine Runtimes or otherwise
 * create derivative works or improvements of the Spine Runtimes or (b) remove,
 * delete, alter, or obscure any trademarks or any copyright, trademark, patent,
 * or other intellectual property or proprietary rights notices on or in the
 * Software, including any copy thereof. Redistributions in binary or source
 * form must include this license and terms.
 *
 * THIS SOFTWARE IS PROVIDED BY ESOTERIC SOFTWARE "AS IS" AND ANY EXPRESS OR
 * IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO
 * EVENT SHALL ESOTERIC SOFTWARE BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
 * PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES, BUSINESS INTERRUPTION, OR LOSS OF
 * USE, DATA, OR PROFITS) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER
 * IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
 * POSSIBILITY OF SUCH DAMAGE.
 *****************************************************************************/
 
package spine.support.graphics;

/******************************************************************************
 * Spine Runtimes Software License
 * Version 2.3
 *
 * Copyright (c) 2013-2015, Esoteric Software
 * All rights reserved.
 *
 * You are granted a perpetual, non-exclusive, non-sublicensable and
 * non-transferable license to use, install, execute and perform the Spine
 * Runtimes Software (the "Software") and derivative works solely for personal
 * or internal use. Without the written permission of Esoteric Software (see
 * Section 2 of the Spine Software License Agreement), you may not (a) modify,
 * translate, adapt or otherwise create derivative works, improvements of the
 * Software or develop new applications using the Software or (b) remove,
 * delete, alter or obscure any trademarks or any copyright, trademark, patent
 * or other intellectual property or proprietary rights notices on or in the
 * Software, including any copy thereof. Redistributions in binary or source
 * form must include this license and terms.
 *
 * THIS SOFTWARE IS PROVIDED BY ESOTERIC SOFTWARE "AS IS" AND ANY EXPRESS OR
 * IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO
 * EVENT SHALL ESOTERIC SOFTWARE BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
 * PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS;
 * OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
 * WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR
 * OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
 * ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *****************************************************************************/

using StringTools;

class TextureAtlas
{
    private var pages:Array<AtlasPage> = new Array<AtlasPage>();
    private var regions:Array<AtlasRegion> = new Array<AtlasRegion>();
    private var textureLoader:TextureLoader;

    /** @param object A String. */
    public function new(object:String, textureLoader:TextureLoader)
    {
        if (object == null)
        {
            return;
        }
        load(Std.string(object), textureLoader);
    }

    private function load(atlasText:String, textureLoader:TextureLoader):Void
    {
        if (textureLoader == null)
        {
            throw new IllegalArgumentException("textureLoader cannot be null.");
        }
        this.textureLoader = textureLoader;

        var reader:Reader = new Reader(atlasText);
        var tuple:Array<String> = [null, null, null, null];
        var page:AtlasPage = null;
        while (true)
        {
            var line:String = reader.readLine();
            if (line == null)
            {
                break;
            }
            line = reader.trim(line);
            if (line.length == 0)
            {
                page = null;
            }
            else
            {
                if (page == null)
                {
                    page = new AtlasPage();
                    page.name = line;
                    page.uWrap = TextureWrap.clampToEdge;
                    page.vWrap = TextureWrap.clampToEdge;

                    var key = reader.nextLineKey();
                    while (key != null) {
                        
                        switch key {

                            case 'size':
                                reader.readTuple(tuple);
                                page.width = Std.parseInt(tuple[0]);
                                page.height = Std.parseInt(tuple[1]);
                            
                            case 'format':
                                page.format = reader.readValue();
                            
                            case 'filter':
                                reader.readTuple(tuple);
                                page.minFilter = tuple[0];
                                page.magFilter = tuple[1];

                            case 'repeat':
                                var direction:String = reader.readValue();
                                if (direction == "x") {
                                    page.uWrap = TextureWrap.repeat;
                                }
                                else {
                                    if (direction == "y") {
                                        page.vWrap = TextureWrap.repeat;
                                    }
                                    else {
                                        if (direction == "xy") {
                                            page.uWrap = page.vWrap = TextureWrap.repeat;
                                        }
                                    }
                                }

                            case 'scale':
                                reader.readTuple(tuple);
                                page.scale = Std.parseFloat(tuple[0]);
                            
                            default:
                                reader.readLine();

                        }

                        key = reader.nextLineKey();
                    }

                    if (page.format == null) {
                        page.format = 'rgba8888';
                    }

                    textureLoader.loadPage(page, line);

                    pages[pages.length] = page;
                }
                else
                {
                    var region:AtlasRegion = new AtlasRegion();
                    region.name = line;
                    region.page = page;

                    var x:Int = 0;
                    var y:Int = 0;
                    var width:Int = 0;
                    var height:Int = 0;
                    var originalWidth:Int = -1;
                    var originalHeight:Int = -1;

                    var key = reader.nextLineKey();
                    while (key != null) {

                        switch key {

                            case 'bounds':
                                reader.readTuple(tuple);
                                x = Std.parseInt(tuple[0]);
                                y = Std.parseInt(tuple[1]);
                                width = Std.parseInt(tuple[2]);
                                height = Std.parseInt(tuple[3]);

                            case 'rotate':
                                var value = reader.readValue();
                                region.rotate = (value == "true" || value == "90");

                            case 'xy':
                                reader.readTuple(tuple);
                                x = Std.parseInt(tuple[0]);
                                y = Std.parseInt(tuple[1]);

                            case 'size':
                                reader.readTuple(tuple);
                                width = Std.parseInt(tuple[0]);
                                height = Std.parseInt(tuple[1]);

                            case 'orig':
                                reader.readTuple(tuple);
                                originalWidth = Std.parseInt(tuple[0]);
                                originalHeight = Std.parseInt(tuple[1]);

                            case 'offset':
                                reader.readTuple(tuple);
                                region.offsetX = Std.parseInt(tuple[0]);
                                region.offsetY = Std.parseInt(tuple[1]);

                            case 'split':
                                reader.readTuple(tuple);
                                region.splits = [Std.parseInt(tuple[0]), Std.parseInt(tuple[1]), Std.parseInt(tuple[2]), Std.parseInt(tuple[3])];

                            case 'pad':
                                reader.readTuple(tuple);
                                region.pads = [Std.parseInt(tuple[0]), Std.parseInt(tuple[1]), Std.parseInt(tuple[2]), Std.parseInt(tuple[3])];
                            
                            case 'index':
                                region.index = Std.parseInt(reader.readValue());

                            default:
                                reader.readLine();
                        }

                        key = reader.nextLineKey();
                    }

                    region.u = x / page.width;
                    region.v = y / page.height;
                    if (region.rotate)
                    {
                        region.u2 = (x + height) / page.width;
                        region.v2 = (y + width) / page.height;
                    }
                    else
                    {
                        region.u2 = (x + width) / page.width;
                        region.v2 = (y + height) / page.height;
                    }
                    region.x = x;
                    region.y = y;
                    region.width = cast Math.abs(width);
                    region.height = cast Math.abs(height);
                    region.originalWidth = originalWidth != -1 ? originalWidth : region.width;
                    region.originalHeight = originalHeight != -1 ? originalHeight : region.height;

                    //trace('region u=${region.u} v=${region.v} u2=${region.u2} v2=${region.v2}');
                    
                    if (region.rotate) {
                        region.packedWidth = region.originalHeight;
                        region.packedHeight = region.originalWidth;
                    } else {
                        region.packedWidth = region.originalWidth;
                        region.packedHeight = region.originalHeight;
                    }

                    textureLoader.loadRegion(region);
                    regions[regions.length] = region;
                }
            }
        }
    }

    /** Returns the first region found with the specified name. This method uses string comparison to find the region, so the result
	 * should be cached rather than calling this method multiple times.
	 * @return The region, or null. */
    public function findRegion(name:String):AtlasRegion
    {
        var i:Int = 0;
        var n:Int = regions.length;
        while (i < n)
        {
            if (regions[i].name == name)
            {
                return regions[i];
            }
            i++;
        }
        return null;
    }

    public function dispose():Void
    {
        var i:Int = 0;
        var n:Int = pages.length;
        while (i < n)
        {
            textureLoader.unloadPage(pages[i]);
            i++;
        }
    }
}



class Reader
{
    private var lines:Array<String>;
    private var index:Int;

    public function new(text:String)
    {
        lines = text.trim().replace("\r\n", "\n").replace("\r", "\n").split("\n");
        index = 0;
    }

    public function trim(value:String):String
    {
        return value.trim();
    }

    public function readLine():String
    {
        if (index >= lines.length)
        {
            return null;
        }
        return lines[index++];
    }

    public function nextLineKey():String {

        if (index >= lines.length) {
            return null;
        }
        else {
            var line = lines[index];
            var colon = line.indexOf(':');
            if (colon != -1) {
                return line.substring(0, colon).trim();
            }
            else {
                return null;
            }
        }

    }

    public function readValue():String
    {
        var line:String = readLine();
        var colon:Int = line.indexOf(":");
        if (colon == -1)
        {
            throw new Error("Invalid line: " + line);
        }
        return trim(line.substring(colon + 1));
    }

    /** Returns the number of tuple values read (1, 2 or 4). */
    public function readTuple(tuple:Array<Dynamic>):Int
    {
        var line:String = readLine();
        var colon:Int = line.indexOf(":");
        if (colon == -1)
        {
            throw new Error("Invalid line: " + line);
        }
        var i:Int = 0;
        var lastMatch:Int = colon + 1;
                while (i < 3)
        {
            var comma:Int = line.indexOf(",", lastMatch);
            if (comma == -1)
            {
                break;
            }
            tuple[i] = trim(line.substr(lastMatch, comma - lastMatch));
            lastMatch = comma + 1;
            i++;
        }
        tuple[i] = trim(line.substring(lastMatch));
        return i + 1;
    }
}

class AtlasPage
{
    public var name:String;
    public var format:Format;
    public var minFilter:TextureFilter;
    public var magFilter:TextureFilter;
    public var uWrap:TextureWrap;
    public var vWrap:TextureWrap;
    public var rendererObject:Dynamic;
    public var width:Int = 0;
    public var height:Int = 0;
    public var scale:Float = 1.0;
    
    public function new()
    {
    }

    function toString() {

        return '' + {
            name: name, format: format, width: width, height: height, scale: scale
        };

    }
}

class AtlasRegion extends TextureRegion
{
    public var name:String;
    public var x:Int = 0;
    public var y:Int = 0;
    public var width:Int = 0;
    public var height:Int = 0;
    public var packedWidth:Int = 0;
    public var packedHeight:Int = 0;
    public var offsetX:Float = 0;
    public var offsetY:Float = 0;
    public var originalWidth:Int = 0;
    public var originalHeight:Int = 0;
    public var index:Int = -1;
    public var degrees:Int = 0;
    public var splits:Array<Int>;
    public var pads:Array<Int>;
    public var page:AtlasPage;

    public var rotate (get,set):Bool;
    inline function get_rotate():Bool {
        return degrees == 90;
    }
    inline function set_rotate(rotate:Bool):Bool {
        degrees = (rotate ? 90:0);
        return rotate;
    }

    public function new()
    {
        super();
    }

    inline public function getTexture():AtlasRegionTexture {
        return this;
    }
}

abstract AtlasRegionTexture(AtlasRegion) from AtlasRegion to AtlasRegion {

    inline public function getWidth():Int {
        return this.page.width;
    }

    inline public function getHeight():Int {
        return this.page.height;
    }

}
