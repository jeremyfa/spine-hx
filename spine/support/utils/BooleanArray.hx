package spine.support.utils;

@:forward(iterator, length, push, pop, shift, unshift, splice)
abstract BooleanArray(std.Array<Bool>) from std.Array<Bool> to std.Array<Bool> {

    public inline static function create(length:Float = 0):BooleanArray {
        var len = Std.int(length);
        var array = new BooleanArray(len != 0 ? len : 16);
        if (length != 0) {
            array.setSize(len);
        }
        return array;
    }

    inline public function new(capacity:Int = 16) {
        this = [];
    }

    public var items(get,never):BooleanArray;
    inline function get_items():BooleanArray {
        return this;
    }

    public var size(get,never):Int;
    inline function get_size():Int {
        return this.length;
    }

    inline public function shrink():BooleanArray {
        return this;
    }

    inline public function toArray():BooleanArray {
        return this;
    }

    inline public function clear():Void {
        this.splice(0, this.length);
    }

    inline public function setSize(size:Int):BooleanArray {
        var len = this.length;
        if (len > size) {
            this.splice(size, size - len);
        }
        else if (len < size) {
            while (len < size) {
                this.push(false);
                len++;
            }
        }
        return this;
    }

    inline public function add(item:Bool):Void {
        this.push(item);
    }

    inline public function addAll(items:BooleanArray, start:Int = 0, count:Int = -1):Void {
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

    inline public function get(index:Int):Bool {
        //return this[index];
        return this.unsafeGet(index);
    }

    inline public function set(index:Int, value:Bool):Void {
        //this[index] = value;
        this.unsafeSet(index, value);
    }

    inline public function indexOf(value:Bool, identity:Bool):Int {
        return this.indexOf(value);
    }

    inline public function removeIndex(index:Int):Bool {
        //var item = this[index];
        var item = this.unsafeGet(index);
        this.splice(index, 1);
        return item;
    }

}
