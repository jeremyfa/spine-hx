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
