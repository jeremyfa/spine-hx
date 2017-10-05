package spine.support.utils;

abstract IntSet(Map<Int,Bool>) {

    inline public function new() {
        this = new Map();
    }

    inline public function add(val:Int) {
        if (this.exists(val)) return false;
        this.set(val, true);
        return true;
    }

    inline public function clear() {
        var keys = [];
        for (key in this.keys()) keys.push(key);
        for (key in keys) this.remove(key);
    }

}