package spine.support.utils;

@:forward(iterator, length, push, pop, shift, unshift, splice)
abstract FloatArray(std.Array<Float>) from std.Array<Float> to std.Array<Float> {

    public inline static function create(length:Float = 0):FloatArray {
        var len = Std.int(length);
        var array = new FloatArray(len != 0 ? len : 16);
        if (length > 0) {
            array.setSize(len);
        }
        return array;
    }

    inline public function new(capacity:Int = 16) {
        this = [];
    }

    public var items(get,never):FloatArray;
    inline function get_items():FloatArray {
        return this;
    }

    public var size(get,never):Int;
    inline function get_size():Int {
        return this.length;
    }

    inline public function shrink():FloatArray {
        return this;
    }

    inline public function toArray():FloatArray {
        return this;
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

    inline public function addAll(items:FloatArray, start:Int = 0, count:Int = -1):Void {
        if (count == -1) count = items.length;
        var i = this.length;
        var len = i + items.length;
        setSize(len);
        for (item in items) {
            //this[i++] = item;
            this.unsafeSet(i++, item);
            if (--count <= 0) break;
        }
    }

    inline public function get(index:Int):Float {
        //return this[index];
        return this.unsafeGet(index);
    }

    inline public function set(index:Int, value:Float):Void {
        //this[index] = value;
        this.unsafeSet(index, value);
    }

    inline public function indexOf(value:Float, identity:Bool):Int {
        return this.indexOf(value);
    }

    inline public function removeIndex(index:Int):Float {
        var item = this[index];
        this.splice(index, 1);
        return item;
    }

}
