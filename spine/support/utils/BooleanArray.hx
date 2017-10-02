package spine.support.utils;

abstract BooleanArray(Array<Bool>) from Array<Bool> to Array<Bool> {

    inline public function new(capacity:Int = 16) {
        return new Array();
    }

    public var items(get,never):BooleanArray;
    inline function get_items():BooleanArray {
        return this;
    }

    public var size(get,never):Int;
    inline function get_size():Int {
        return this.length;
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

    inline public function removeIndex(index:Int):Void {
        this.splice(index, 1);
    }

}
