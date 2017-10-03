package spine.support.utils;

@:forward(iterator)
abstract Array<T>(std.Array<T>) from std.Array<T> to std.Array<T> {

    inline public function new(capacity:Int = 16) {
        this = [];
    }

    public var items(get,never):Array<T>;
    inline function get_items():Array<T> {
        return this;
    }

    public var size(get,never):Int;
    inline function get_size():Int {
        return this.length;
    }

    inline public function clear():Void {
        this.splice(0, this.length);
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

    inline public function get(index:Int):T {
        return this[index];
    }

    inline public function removeIndex(index:Int):Void {
        this.splice(index, 1);
    }

    inline public function ensureCapacity(size:Int):Array<T> {
        // May optimize this later?
        return this;
    }

}
