package spine.support.math;

@:structInit
class Vector2 {

    public var x:Float = 0;

    public var y:Float = 0;

    inline public function new(x:Float = 0, y:Float = 0) {
        this.x = x;
        this.y = y;
    }

    inline public function set(x:Float, y:Float) {
        this.x = x;
        this.y = y;
        return this;
    }

}
