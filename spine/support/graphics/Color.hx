package spine.support.graphics;

import spine.support.utils.Either;

/** Color class ported from some of libgdx's Color code. */
class Color {

    public static var CLEAR = new Color(0, 0, 0, 0);
    public static var BLACK = new Color(0, 0, 0, 1);

    public static var WHITE = new Color().setRgba888(0xffffffff);
    public static var LIGHT_GRAY = new Color().setRgba888(0xbfbfbfff);
    public static var GRAY = new Color().setRgba888(0x7f7f7fff);
    public static var DARK_GRAY = new Color().setRgba888(0x3f3f3fff);

    public static var BLUE = new Color(0, 0, 1, 1);
    public static var NAVY = new Color(0, 0, 0.5, 1);
    public static var ROYAL = new Color().setRgba888(0x4169e1ff);
    public static var SLATE = new Color().setRgba888(0x708090ff);
    public static var SKY = new Color().setRgba888(0x87ceebff);
    public static var CYAN = new Color(0, 1, 1, 1);
    public static var TEAL = new Color(0, 0.5, 0.5, 1);

    public static var GREEN = new Color().setRgba888(0x00ff00ff);
    public static var CHARTREUSE = new Color().setRgba888(0x7fff00ff);
    public static var LIME = new Color().setRgba888(0x32cd32ff);
    public static var FOREST = new Color().setRgba888(0x228b22ff);
    public static var OLIVE = new Color().setRgba888(0x6b8e23ff);

    public static var YELLOW = new Color().setRgba888(0xffff00ff);
    public static var GOLD = new Color().setRgba888(0xffd700ff);
    public static var GOLDENROD = new Color().setRgba888(0xdaa520ff);
    public static var ORANGE = new Color().setRgba888(0xffa500ff);

    public static var BROWN = new Color().setRgba888(0x8b4513ff);
    public static var TAN = new Color().setRgba888(0xd2b48cff);
    public static var FIREBRICK = new Color().setRgba888(0xb22222ff);

    public static var RED = new Color().setRgba888(0xff0000ff);
    public static var SCARLET = new Color().setRgba888(0xff341cff);
    public static var CORAL = new Color().setRgba888(0xff7f50ff);
    public static var SALMON = new Color().setRgba888(0xfa8072ff);
    public static var PINK = new Color().setRgba888(0xff69b4ff);
    public static var MAGENTA = new Color(1, 0, 1, 1);

    public static var PURPLE = new Color().setRgba888(0xa020f0ff);
    public static var VIOLET = new Color().setRgba888(0xee82eeff);
    public static var MAROON = new Color().setRgba888(0xb03060ff);

    public static function valueOf(hex:String):Color {
        hex = hex.charAt(0) == '#' ? hex.substring(1) : hex;
        hex = hex.substr(0, 2) == '0x' ? hex.substring(2) : hex;
        var r:Float = Std.parseInt('0x' + hex.substring(0, 2));
        var g:Float = Std.parseInt('0x' + hex.substring(2, 4));
        var b:Float = Std.parseInt('0x' + hex.substring(4, 6));
        var a:Float = hex.length != 8 ? 255 : Std.parseInt('0x' + hex.substring(6, 8));
        return new Color(r / 255.0, g / 255.0, b / 255.0, a / 255.0);
    }

    public var r:Float;
    public var g:Float;
    public var b:Float;
    public var a:Float;

    public function new(r:Float = 0, g:Float = 0, b:Float = 0, a:Float = 0) {
        this.r = r;
        this.g = g;
        this.b = b;
        this.a = a;
    }
    
    public function set(r:Either<Color,Float>, g:Float = -1, b:Float = -1, a:Float = -1):Color {
        if (Std.is(r, Float)) {
            this.r = r;
            this.g = g;
            this.b = b;
            if (a != -1) this.a = a;
        }
        else {
            var color:Color = r;
            this.r = color.r;
            this.g = color.g;
            this.b = color.b;
            this.a = color.a;
        }
        return this;
    }
    
    inline public function add(r:Float, g:Float, b:Float, a:Float):Color {
        this.r += r;
        this.g += g;
        this.b += b;
        this.a += a;
        return this;
    }
    
    inline public function mul(r:Float, g:Float, b:Float, a:Float):Color {
        this.r *= r;
        this.g *= g;
        this.b *= b;
        this.a *= a;
        return this;
    }

    inline public function setRgba888(value:Int):Color {
        r = ((value & 0xff000000) >>> 24) / 255.0;
        g = ((value & 0x00ff0000) >>> 16) / 255.0;
        b = ((value & 0x0000ff00) >>> 8) / 255.0;
        a = ((value & 0x000000ff)) / 255.0;
        return this;
    }

}
