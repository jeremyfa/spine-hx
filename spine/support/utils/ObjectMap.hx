package spine.support.utils;

abstract ObjectMap<K,V>(Map<K,Entry<K,V>>) {

    inline public function new() {
        this = new Map();
    }

    inline public function get(key:K):V {
        var entry = this.get(key);
        if (entry != null) return entry.value;
        return null;
    }

    inline public function entries() {
        return this.iterator();
    }

}

@:structInit
class Entry<K,V> {

    public var key:K;

    public var value:V;

    public function new(key:K, value:V) {
        this.key = key;
        this.value = value;
    }
}
