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

class TextureAtlas
{
    private var pages : Array<AtlasPage> = new Array<AtlasPage>();
    private var regions : Array<TextureRegion> = new Array<TextureRegion>();
    private var textureLoader : TextureLoader;

    /** @param object A String. */
    public function new(object : String, textureLoader : TextureLoader)
    {
        if (object == null)
        {
            return;
        }
        load(Std.string(object), textureLoader);
    }

    private function load(atlasText : String, textureLoader : TextureLoader) : Void
    {
        if (textureLoader == null)
        {
            throw new ArgumentError("textureLoader cannot be null.");
        }
        this.textureLoader = textureLoader;

        var reader : Reader = new Reader(atlasText);
        var tuple : Array<Dynamic> = [null, null, null, null];
        var page : AtlasPage = null;
        while (true)
        {
            var line : String = reader.readLine();
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

                    if (reader.readTuple(tuple) == 2)
                    {
                        // size is only optional for an atlas packed with an old TexturePacker.
                        page.width = Std.parseInt(tuple[0]);
                        page.height = Std.parseInt(tuple[1]);
                        reader.readTuple(tuple);
                    }
                    page.format = tuple[0];

                    reader.readTuple(tuple);
                    page.minFilter = tuple[0];
                    page.magFilter = tuple[1];

                    var direction : String = reader.readValue();
                    page.uWrap = TextureWrap.clampToEdge;
                    page.vWrap = TextureWrap.clampToEdge;
                    if (direction == "x")
                    {
                        page.uWrap = TextureWrap.repeat;
                    }
                    else
                    {
                        if (direction == "y")
                        {
                            page.vWrap = TextureWrap.repeat;
                        }
                        else
                        {
                            if (direction == "xy")
                            {
                                page.uWrap = page.vWrap = TextureWrap.repeat;
                            }
                        }
                    }

                    textureLoader.loadPage(page, line);

                    pages[pages.length] = page;
                }
                else
                {
                    var region : TextureRegion = new TextureRegion();
                    region.name = line;
                    region.page = page;

                    region.rotate = reader.readValue() == "true";

                    reader.readTuple(tuple);
                    var x : Int = Std.parseInt(tuple[0]);
                    var y : Int = Std.parseInt(tuple[1]);

                    reader.readTuple(tuple);
                    var width : Int = Std.parseInt(tuple[0]);
                    var height : Int = Std.parseInt(tuple[1]);

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

                    if (reader.readTuple(tuple) == 4)
                    {
                        // split is optional
                        region.splits = new Array<Int>();

                        if (reader.readTuple(tuple) == 4)
                        {
                            // pad is optional, but only present with splits
                            region.pads = [spine.compat.Compat.parseInt(tuple[0]), spine.compat.Compat.parseInt(tuple[1]), spine.compat.Compat.parseInt(tuple[2]), spine.compat.Compat.parseInt(tuple[3])];

                            reader.readTuple(tuple);
                        }
                    }

                    region.originalWidth = spine.compat.Compat.parseInt(tuple[0]);
                    region.originalHeight = spine.compat.Compat.parseInt(tuple[1]);

                    reader.readTuple(tuple);
                    region.offsetX = spine.compat.Compat.parseInt(tuple[0]);
                    region.offsetY = spine.compat.Compat.parseInt(tuple[1]);

                    region.index = spine.compat.Compat.parseInt(reader.readValue());

                    textureLoader.loadRegion(region);
                    regions[regions.length] = region;
                }
            }
        }
    }

    /** Returns the first region found with the specified name. This method uses string comparison to find the region, so the result
	 * should be cached rather than calling this method multiple times.
	 * @return The region, or null. */
    public function findRegion(name : String) : TextureRegion
    {
        var i : Int = 0;
        var n : Int = regions.length;
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

    public function dispose() : Void
    {
        var i : Int = 0;
        var n : Int = pages.length;
        while (i < n)
        {
            textureLoader.unloadPage(pages[i]);
            i++;
        }
    }
}

interface TextureLoader
{
    function loadPage(page : AtlasPage, path : String) : Void;

    function loadRegion(region : TextureRegion) : Void;

    function unloadPage(page : AtlasPage) : Void;
}

class Reader
{
    private var lines : Array<Dynamic>;
    private var index : Int;

    public function new(text : String)
    {
        lines = text.trim().replace("\r\n", "\n").replace("\r", "\n").split("\n");
        index = 0;
    }

    public function trim(value : String) : String
    {
        return value.trim();
    }

    public function readLine() : String
    {
        if (index >= lines.length)
        {
            return null;
        }
        return lines[index++];
    }

    public function readValue() : String
    {
        var line : String = readLine();
        var colon : Int = line.indexOf(":");
        if (colon == -1)
        {
            throw new Error("Invalid line: " + line);
        }
        return trim(line.substring(colon + 1));
    }

    /** Returns the number of tuple values read (1, 2 or 4). */
    public function readTuple(tuple : Array<Dynamic>) : Int
    {
        var line : String = readLine();
        var colon : Int = line.indexOf(":");
        if (colon == -1)
        {
            throw new Error("Invalid line: " + line);
        }
        var i : Int = 0;
        var lastMatch : Int = colon + 1;
                while (i < 3)
        {
            var comma : Int = line.indexOf(",", lastMatch);
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
    public var name : String;
    public var format : Format;
    public var minFilter : TextureFilter;
    public var magFilter : TextureFilter;
    public var uWrap : TextureWrap;
    public var vWrap : TextureWrap;
    public var rendererObject : Dynamic;
    public var width : Int;
    public var height : Int;
    
    public function new()
    {
    }
}

@:enum
abstract Format(String) from String to String {
	var Alpha = "alpha";
	var Intensity = "intensity";
	var LuminanceAlpha = "luminanceAlpha";
	var Rgb565 = "rgb565";
	var Rgba4444 = "rgba4444";
	var Rgb888 = "rgb888";
	var Rgba8888 = "rgba8888";
}

@:enum
abstract TextureFilter(String) from String to String {
	var Nearest = "nearest";
	var Linear = "linear";
	var MipMap = "mipMap";
	var MipMapNearestNearest = "mipMapNearestNearest";
	var MipMapLinearNearest = "mipMapLinearNearest";
	var MipMapNearestLinear = "mipMapNearestLinear";
	var MipMapLinearLinear = "mipMapLinearLinear";
}

class TextureWrap
{
    public static var mirroredRepeat : TextureWrap = new TextureWrap(0, "mirroredRepeat");
    public static var clampToEdge : TextureWrap = new TextureWrap(1, "clampToEdge");
    public static var repeat : TextureWrap = new TextureWrap(2, "repeat");
    
    public var ordinal : Int;
    public var name : String;
    
    public function new(ordinal : Int, name : String)
    {
        this.ordinal = ordinal;
        this.name = name;
    }
}


