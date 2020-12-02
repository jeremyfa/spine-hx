package spine.support.math;

class MathUtils {

    static public var degRad:Float = Math.PI / 180.0;
    static public var radDeg:Float = 180.0 / Math.PI;

	inline static public function sinDeg(degrees:Float):Float {
		return Math.sin(degrees * degRad);
	}

	inline static public function cosDeg(degrees:Float):Float {
		return Math.cos(degrees * degRad);
	}

	inline static public function sin(angle:Float):Float {
		return Math.sin(angle);
	}

	inline static public function cos(angle:Float):Float {
		return Math.cos(angle);
	}

    inline static public function clamp(value:Float, min:Float, max:Float) {
        if (value < min) return min;
        if (value > max) return max;
        return value;
    }

    #if cs

    // To avoid boxing/unboxing, we might want to improve spine runtime conversion
    // to make it call different methods depending on wether we use Int of Float

    inline static public function max(val1:Dynamic, val2:Dynamic):Dynamic {
        return Math.max(val1, val2);
    }

    inline static public function min(val1:Dynamic, val2:Dynamic):Dynamic {
        return Math.min(val1, val2);
    }

    #else

    inline static public function max<T>(val1:T, val2:T):T {
        return untyped Math.max(untyped val1, untyped val2);
    }

    inline static public function min<T>(val1:T, val2:T):T {
        return untyped Math.min(untyped val1, untyped val2);
    }
    
    #end

    inline static public function signum(val:Float):Int {
        return val > 0 ? 1 : val < 0 ? -1 : 0;
    }
    
}
