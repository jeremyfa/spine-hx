package spine.support.utils;

@:forward(toString)
abstract StringBuilder(StringBuf) {

    inline public function new(capacity:Int) {
        this = new StringBuf();
    }

    inline public function length() {
        return this.length;
    }

    inline public function append(str:String) {
        this.add(str);
    }

}
