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

package spine.atlas;

import spine.compat.ArgumentError;
import spine.compat.Error;

using StringTools;

class Atlas
{
    private var pages : Array<AtlasPage> = new Array<AtlasPage>();
    private var regions : Array<AtlasRegion> = new Array<AtlasRegion>();
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
        var tuple : Array<Dynamic> = new Array<Dynamic>();
        spine.compat.Compat.setArrayLength(tuple, 4);
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
                        page.width = spine.compat.Compat.parseInt(tuple[0]);
                        page.height = spine.compat.Compat.parseInt(tuple[1]);
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
                    var region : AtlasRegion = new AtlasRegion();
                    region.name = line;
                    region.page = page;

                    region.rotate = reader.readValue() == "true";

                    reader.readTuple(tuple);
                    var x : Int = spine.compat.Compat.parseInt(tuple[0]);
                    var y : Int = spine.compat.Compat.parseInt(tuple[1]);

                    reader.readTuple(tuple);
                    var width : Int = spine.compat.Compat.parseInt(tuple[0]);
                    var height : Int = spine.compat.Compat.parseInt(tuple[1]);

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
    public function findRegion(name : String) : AtlasRegion
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



class Reader
{
    private var lines : Array<Dynamic>;
    private var index : Int;

    public function new(text : String)
    {
        lines = text.replace("\r\n", "\n").replace("\r", "\n").split("\n");
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
        var lastMatch : Int = spine.compat.Compat.parseInt(colon + 1);
                while (i < 3)
        {
            var comma : Int = line.indexOf(",", lastMatch);
            if (comma == -1)
            {
                break;
            }
            tuple[i] = trim(line.substr(lastMatch, comma - lastMatch));
            lastMatch = spine.compat.Compat.parseInt(comma + 1);
            i++;
        }
        tuple[i] = trim(line.substring(lastMatch));
        return spine.compat.Compat.parseInt(i + 1);
    }
}
