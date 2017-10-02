package spine.support.utils;

abstract IntArray(Array<Int>) from Array<Int> to Array<Int> {

    inline public function new(capacity:Int = 16) {
        return new Array();
    }

    public var items(get,never):IntArray;
    inline function get_items():IntArray {
        return this;
    }

    public var size(get,never):Int;
    inline function get_size():Int {
        return this.length;
    }

    inline public function clear():Void {
        this.splice(0, this.length);
    }

    inline public function setSize(size:Int):IntArray {
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

    inline public function add(item:Int):Void {
        this.push(item);
    }

    inline public function removeIndex(index:Int):Void {
        this.splice(index, 1);
    }

    inline public function ensureCapacity(size:Int):IntArray {
        // May optimize this later?
        return this;
    }

}
