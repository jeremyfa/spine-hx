package spine.support.utils;

abstract FloatArray(Array<Float>) from Array<Float> to Array<Float> {

    inline public function new(capacity:Int = 16) {
        return new Array();
    }

    public var items(get,never):FloatArray;
    inline function get_items():FloatArray {
        return this;
    }

    public var size(get,never):Int;
    inline function get_size():Int {
        return this.length;
    }

    inline public function clear():Void {
        this.splice(0, this.length);
    }

    inline public function setSize(size:Int):FloatArray {
        var len = this.length;
        if (len > size) {
            this.splice(size, size - len);
        }
        else if (len < size) {
            while (len < size) {
                this.push(0);
                len++;
            }
        }
        return this;
    }

    inline public function add(item:Float):Void {
        this.push(item);
    }

    inline public function removeIndex(index:Int):Void {
        this.splice(index, 1);
    }

}
