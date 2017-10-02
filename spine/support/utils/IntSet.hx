package spine.support.utils;

abstract IntSet(Map<Int,Bool>) {

    inline public function new() {
        this = new Map();
    }

    inline public function add(val:Int) {
        this.set(val, true);
    }

}