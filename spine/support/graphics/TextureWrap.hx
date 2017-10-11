package spine.support.graphics;

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
