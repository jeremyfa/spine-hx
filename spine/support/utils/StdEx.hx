package spine.support.utils;

class StdEx {

    inline public static function parseInt(val:String, base:Int):Int {
        return base == 16 ? Std.parseInt('0x' + val) : Std.parseInt(val);
    }

}