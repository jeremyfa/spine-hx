package spine.support.extensions;

class StringExtensions {

    /** Just to make java-style string comparison work in haxe. */
    inline public static function equals(str0:String, str1:String):Bool {
        return str0 == str1;
    }

    /** Hash code for mappings. */
    inline public static function getHashCode(str:String):Int {
        var hash = 0, chr;
        if (str.length == 0) return hash;
        for (i in 0...str.length) {
            chr   = str.charCodeAt(i);
            hash  = ((hash << 5) - hash) + chr;
        }
        return hash;
    }

} //StringExtensions
