package spine.support.extensions;

class StringExtensions {

    /** Just to make java-style string comparison work in haxe. */
    inline public static function equals(str0:String, str1:String):Bool {
        return str0 == str1;
    }

} //StringExtensions
