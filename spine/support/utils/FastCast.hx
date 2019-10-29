package spine.support.utils;

class FastCast {

    inline public static function fastCast<T>(value:Dynamic, toClass:Class<T>):T {
        var result:T = cast value;
        return result;
    }

} //FastCast
