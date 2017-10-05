package spine.support.utils;

@:forward(keys)
abstract ObjectMap<K,V>(Map<K,Entry<K,V>>) {

    inline public function new() {
        this = new Map();
    }

    inline public function get(key:K, defaultValue:V = null):V {
        var entry = this.get(key);
        if (entry != null) return entry.value;
        return defaultValue;
    }

    inline public function clear():Void {
        var keys = [];
        for (key in this.keys()) keys.push(key);
        for (key in keys) this.remove(key);
    }

    public function put(key:K, value:V):Void {
        var entry = this.get(key);
        if (entry == null) {
            entry = { key: key, value: value };
            this.set(key, entry);
        } else {
            @:privateAccess entry.value = value;
        }
    }

    inline public function entries() {
        return this.iterator();
    }

}

@:structInit
class Entry<K,V> {

    public var key(default,null):K;

    public var value(default,null):V;

    public function new(key:K, value:V) {
        this.key = key;
        this.value = value;
    }
}
