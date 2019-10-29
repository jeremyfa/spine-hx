package spine.support.utils;

import spine.Skin.SkinEntry;

abstract SkinEntryMap(Map<Int,Array<SkinEntryMapEntry<SkinEntry,SkinEntry>>>) {

    inline public function new() {
        this = new Map();
    }

    #if !spine_no_inline inline #end public function get(key:SkinEntry, defaultValue:SkinEntry = null):SkinEntry {
        var entries = this.get(key.getHashCode());
        var result:SkinEntry = defaultValue;
        if (entries != null) {
            for (i in 0...entries.length) {
                var entry = entries.unsafeGet(i);
                if (entry.key.equals(key)) {
                    result = entry.value;
                    break;
                }
            }
        }
        return result;
    }

    #if !spine_no_inline inline #end public function clear():Void {
        var keys = [];
        for (key in this.keys()) keys.push(key);
        for (key in keys) this.remove(key);
    }

    public function put(key:SkinEntry, value:SkinEntry):Void {
        var hashCode = key.getHashCode();
        var entries = this.get(hashCode);
        if (entries == null) {
            entries = [];
            this.set(hashCode, entries);
        }
        var i = 0;
        var didSet = false;
        for (entry in entries) {
            if (entry.key.equals(key)) {
                entries[i].key = key;
                entries[i].value = value;
                didSet = true;
                break;
            }
            i++;
        }
        if (!didSet) {
            entries.push(new SkinEntryMapEntry(key, value));
        }
    }

    inline public function remove(key:SkinEntry):Void {
        this.remove(key.getHashCode());
    }

    public function entries() {
        var entries = [];
        for (entryList in this) {
            for (i in 0...entryList.length) {
                entries.push(entryList[i]);
            }
        }
        return entries;
    }

    public function keys() {
        var keys = [];
        for (entryList in this) {
            for (i in 0...entryList.length) {
                keys.push(entryList[i].key);
            }
        }
        return keys;
    }

    public function values() {
        var values = [];
        for (entryList in this) {
            for (i in 0...entryList.length) {
                values.push(entryList[i].value);
            }
        }
        return values;
    }

    public var size(get,never):Int;
    function get_size():Int {
        var numEntries = 0;
        for (entryList in this) {
            for (i in 0...entryList.length) {
                numEntries++;
            }
        }
        return numEntries;
    }

}

@:allow(spine.support.utils.SkinEntryMap)
@:structInit
class SkinEntryMapEntry<K,V> {

    public var key(default,null):K;

    public var value(default,null):V;

    public function new(key:K, value:V) {
        this.key = key;
        this.value = value;
    }
}
