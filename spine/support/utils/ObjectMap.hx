package spine.support.utils;

abstract ObjectMap<K,V>(Map<Int,Array<Entry<K,V>>>) {

    inline public function new() {
        this = new Map();
    }

    public function get(key:K, defaultValue:V = null):V {
        var dKey:Dynamic = key;
        var entries = this.get(dKey.getHashCode());
        if (entries != null) {
            for (entry in entries) {
                var dEntryKey:Dynamic = entry.key;
                if (dEntryKey.equals(key)) {
                    return entry.value;
                }
            }
        }
        return defaultValue;
    }

    inline public function clear():Void {
        var keys = [];
        for (key in this.keys()) keys.push(key);
        for (key in keys) this.remove(key);
    }

    public function put(key:K, value:V):Void {
        var dKey:Dynamic = key;
        var hashCode = dKey.getHashCode();
        var entries = this.get(hashCode);
        if (entries == null) {
            entries = [];
            this.set(hashCode, entries);
        }
        var i = 0;
        var didSet = false;
        for (entry in entries) {
            var dEntryKey:Dynamic = entry.key;
            if (dEntryKey.equals(key)) {
                entries[i].key = key;
                entries[i].value = value;
                didSet = true;
                break;
            }
            i++;
        }
        if (!didSet) {
            entries.push(new Entry(key, value));
        }
    }

    public function entries() {
        var entries = [];
        for (entryList in this) {
            if (entryList != null) { // Not sure why we need to check this in js :(
                for (entry in entryList) {
                    entries.push(entry);
                }
            }
        }
        return entries;
    }

    public function keys() {
        var keys = [];
        for (entryList in this) {
            for (entry in entryList) {
                keys.push(entry.key);
            }
        }
        return keys;
    }

}

@:allow(spine.support.utils.ObjectMap)
@:structInit
class Entry<K,V> {

    public var key(default,null):K;

    public var value(default,null):V;

    public function new(key:K, value:V) {
        this.key = key;
        this.value = value;
    }
}
