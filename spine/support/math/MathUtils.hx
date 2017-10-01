package spine.support.math;

class MathUtils {

    inline public function clamp (value:Int, min:Int, max:Int) {
        if (value < min) return min;
        if (value > max) return max;
        return value;
    }
    
}