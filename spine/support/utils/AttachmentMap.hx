package spine.support.utils;

import spine.Skin.Key;
import spine.attachments.Attachment;

abstract AttachmentMap(Map<Int,Array<Entry<Key,Attachment>>>) {

    inline public function new() {
        this = new Map();
    }

    #if !spine_no_inline inline #end public function get(key:Key, defaultValue:Attachment = null):Attachment {
        var entries = this.get(key.getHashCode());
        var result:Attachment = defaultValue;
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

    public function put(key:Key, value:Attachment):Void {
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
            entries.push(new Entry(key, value));
        }
    }

    inline public function remove(key:Key):Void {
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

@:allow(spine.support.utils.AttachmentMap)
@:structInit
class Entry<Key,Attachment> {

    public var key(default,null):Key;

    public var value(default,null):Attachment;

    public function new(key:Key, value:Attachment) {
        this.key = key;
        this.value = value;
    }
}
