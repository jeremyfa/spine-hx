package spine.support.utils;

import spine.Skin.SkinEntry;

abstract AttachmentSet(Map<Int,Array<SkinEntry>>) {

    inline public function new() {
        this = new Map();
    }

    #if !spine_no_inline inline #end public function get(key:SkinEntry, defaultValue:SkinEntry = null):SkinEntry {
        var entries = this.get(key.getHashCode());
        var result:SkinEntry = defaultValue;
        if (entries != null) {
            for (i in 0...entries.length) {
                var entry = entries.unsafeGet(i);
                if (entry.equals(key)) {
                    result = entry;
                    break;
                }
            }
        }
        return result;
    }

    static var _keys:Array<Int> = [];

    #if !spine_no_inline inline #end public function clear():Void {
        #if (haxe_ver >= 4.0)
        this.clear();
        #else
        var len = 0;
        for (key in this.keys()) {
            _keys[len] = key;
            len++;
        }
        for (i in 0...len) {
            var key = _keys.unsafeGet(i);
            this.remove(key);
        }
        #end
    }

    public function add(key:SkinEntry):Bool {
        var prevValue = null;
        var hashCode = key.getHashCode();
        var entries = this.get(hashCode);
        if (entries == null) {
            entries = [];
            this.set(hashCode, entries);
        }
        else {
            for (i in 0...entries.length) {
                var entry = entries.unsafeGet(i);
                if (entry.equals(key)) {
                    prevValue = entry;
                    break;
                }
            }
        }
        var i = 0;
        var didSet = false;
        for (entry in entries) {
            if (entry.equals(key)) {
                entries[i] = key;
                didSet = true;
                break;
            }
            i++;
        }
        if (!didSet) {
            entries.push(key);
        }
        return prevValue == null;
    }

    public function remove(key:SkinEntry):Void {
        var hashCode = key.getHashCode();
        var entries = this.get(hashCode);
        if (entries != null) {
            var len = entries.length;
            var toRemove = null;
            for (i in 0...len) {
                var entry = entries.unsafeGet(i);
                if (entry.equals(key)) {
                    toRemove = entry;
                    break;
                }
            }
            if (toRemove != null) {
                if (len == 1) {
                    this.remove(hashCode);
                }
                else {
                    entries.remove(toRemove);
                }
            }
        }
    }

    public function orderedItems():Array<SkinEntry> {
        var entries = [];
        for (entryList in this) {
            for (i in 0...entryList.length) {
                entries.push(entryList[i]);
            }
        }
        return entries;
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

@:allow(spine.support.utils.AttachmentSet)
@:structInit
class AttachmentSetEntry<K,V> {

    public var key(default,null):K;

    public var value(default,null):V;

    public function new(key:K, value:V) {
        this.key = key;
        this.value = value;
    }
}
