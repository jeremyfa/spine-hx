package spine.support.graphics;

import spine.support.graphics.TextureAtlas;

interface TextureLoader
{

    function loadPage(page : AtlasPage, path : String) : Void;

    function loadRegion(region : AtlasRegion) : Void;

    function unloadPage(page : AtlasPage) : Void;

}
