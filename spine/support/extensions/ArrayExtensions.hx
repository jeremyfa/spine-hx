package spine.support.extensions;

class ArrayExtensions<T> {

    inline static public function setSize<T>(array:Array<T>, size:Int):Array<T> {
        var len = array.length;
        if (len > size) {
            array.splice(size, size - len);
        }
        else if (len < size) {
            var dArray:Array<Dynamic> = array;
            dArray[size - 1] = null;
        }
        return array;
    }

    inline static public function add<T>(array:Array<T>, item:T):Void {
        array.push(item);
    }

    inline static public function removeIndex<T>(array:Array<T>, index:Int):Void {
        array.splice(index, 1);
    }

} //ArrayExtensions
