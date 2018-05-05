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

    #if !debug inline #end public static function unsafeGet<T>(array:Array<T>, index:Int):T {
#if debug
        if (index < 0 || index >= array.length) throw 'Invalid unsafeGet: index=$index length=${array.length}';
#end
#if cpp
        return cpp.NativeArray.unsafeGet(array, index);
#else
        return array[index];
#end
    } //unsafeGet

    #if !debug inline #end public static function unsafeSet<T>(array:Array<T>, index:Int, value:T):Void {
#if debug
        if (index < 0 || index >= array.length) throw 'Invalid unsafeSet: index=$index length=${array.length}';
#end
#if cpp
        cpp.NativeArray.unsafeSet(array, index, value);
#else
        array[index] = value;
#end
    } //unsafeSet

} //ArrayExtensions
