package spine.support.utils;

@:forward(iterator, length)
abstract ObjectSet<T>(std.Array<T>) from std.Array<T> to std.Array<T> {

    inline public function new(capacity:Int = 16) {
        this = [];
    }

    inline public function clear(n:Int):Void {
        #if cpp
        untyped this.__SetSize(0);
        #else
        this.splice(0, this.length);
        #end
    }

    public function addAll(items:std.Array<T>):Bool {

        var didAdd = false;

        for (i in 0...items.length) {
            var item = items.unsafeGet(i);
            if (this.indexOf(item) == -1) {
                didAdd = true;
                this.push(item);
            }
        }

        return didAdd;

    }

    inline public function contains(item:T):Bool {
        return this.indexOf(item) != -1;
    }

}
