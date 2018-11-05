package spine.support.utils;

@:forward(iterator, length, push, pop, shift, unshift, splice)
abstract Array<T>(std.Array<T>) from std.Array<T> to std.Array<T> {

    public static function copy<T>(src:std.Array<T>, srcPos:Int, dest:std.Array<T>, destPos:Int, length:Int) {
        var val;
        var srcIndex = srcPos;
        var destIndex = destPos;
        var end = length + srcPos;
        while (srcIndex < end) {
            //dest[i + destPos] = src[i + srcPos];
            val = src.unsafeGet(srcIndex);
            dest.unsafeSet(destIndex, val);
            srcIndex++;
            destIndex++;
        }
    }

    public static function copyFloats(src:std.Array<Float>, srcPos:Int, dest:std.Array<Float>, destPos:Int, length:Int) {
        var val:Float;
        var srcIndex = srcPos;
        var destIndex = destPos;
        var end = length + srcPos;
        while (srcIndex < end) {
            //dest[i + destPos] = src[i + srcPos];
            val = src.unsafeGet(srcIndex);
            dest.unsafeSet(destIndex, val);
            srcIndex++;
            destIndex++;
        }
    }

    public inline static function create(length:Float = 0):Dynamic {
        var len = Std.int(length);
        var array = new Array<Dynamic>(len != 0 ? len : 16);
        if (length != 0) {
            array.setSize(len);
        }
        return array;
    }

    public inline static function createFloatArray2D(length:Float = 0, length2:Float = 0):FloatArray2D {
        var len = Std.int(length);
        var len2 = Std.int(length2);
        var array = new FloatArray2D(len != 0 ? len : 16);
        if (length > 0) {
            array.setSize(len);
        }
        for (i in 0...len2) {
            //array[i] = FloatArray.create(length2);
            array.unsafeSet(i, FloatArray.create(length2));
        }
        return array;
    }

    public inline static function createIntArray2D(length:Float = 0, length2:Float = 0):IntArray2D {
        var len = Std.int(length);
        var len2 = Std.int(length2);
        var array = new IntArray2D(len != 0 ? len : 16);
        if (length > 0) {
            array.setSize(len);
        }
        for (i in 0...len2) {
            //array[i] = IntArray.create(length2);
            array.unsafeSet(i, IntArray.create(length2));
        }
        return array;
    }

    inline public function new(capacity:Int = 16) {
        this = [];
    }

    public var items(get,never):Array<T>;
    inline function get_items():Array<T> {
        return this;
    }

    public var size(get,set):Int;
    inline function get_size():Int { return this.length; }
    inline function set_size(size:Int):Int {
        setSize(size);
        return this.length;
    }

    inline public function shrink():Array<T> {
        return this;
    }

    inline public function clear():Void {
        #if cpp
        untyped this.__SetSize(0);
        #else
        this.splice(0, this.length);
        #end
    }

    inline public function first():T {
        return (this.length > 0 ? this[0] : null);
    }

    inline public function peek():T {
        return (this.length == 0 ? null : this[this.length - 1]);
    }

    inline public function contains(value:T, identity:Bool):Bool {
        return this.indexOf(value) != -1;
    }

    inline public function removeValue(value:T, identity:Bool):Bool {
        var index = this.indexOf(value);
        if (index == -1) return false;
        this.splice(index, 1);
        return true;
    }

    inline public function setSize(size:Int):Array<T> {
        var len = this.length;
        if (len > size) {
            this.splice(size, size - len);
        }
        else if (len < size) {
            this[size - 1] = null;
        }
        return this;
    }

    inline public function add(item:T):Void {
        this.push(item);
    }

    inline public function addAll(items:Array<T>, start:Int = 0, count:Int = -1):Void {
        if (count == -1) count = items.length;
        var i = this.length;
        var len = i + items.length;
        setSize(len);
        var val;
        for (j in 0...items.length) {
            //this[i++] = item;
            val = items.unsafeGet(j);
            this.unsafeSet(i++, val);
            if (--count <= 0) break;
        }
    }

    inline public function get(index:Int):T {
        //return this[index];
        return this.unsafeGet(index);
    }

    inline public function set(index:Int, value:T):Void {
        //this[index] = value;
        this.unsafeSet(index, value);
    }

    inline public function indexOf(value:T, ?identity:Bool):Int {
        return this.indexOf(value);
    }

    inline public function removeIndex(index:Int):T {
        //var item = this[index];
        var item = this.unsafeGet(index);
        this.splice(index, 1);
        return item;
    }

    inline public function ensureCapacity(size:Int):Array<T> {
        // May optimize this later?
        return this;
    }

}
