package spine.support.extensions;

class SpineExtensions {

    /** Just to make java-style comparison work in haxe. */
    inline public static function equals(anim1:spine.Animation, anim2:spine.Animation):Bool {
        return anim1 == anim2;
    }

    /** Hash code for mappings. */
    inline public static function getHashCode(anim:spine.Animation):Int {
        return @:privateAccess anim.hashCode;
    }

} //SpineExtensions
