package spine.support.extensions;

class ArrayExtensions<T> {

    inline static public function setSize<T>(array:Array<T>, size:Int, currentLength:Int):Array<T> {
        if (currentLength > size) {
            array.splice(size, size - currentLength);
        }
        else if (currentLength < size) {
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

    #if !spine_debug_unsafe inline #end public static function unsafeGet<T>(array:Array<T>, index:Int):T {
#if spine_debug_unsafe
        if (index < 0 || index >= array.length) throw 'Invalid unsafeGet: index=$index length=${array.length}';
#end
#if cpp
        #if app_cpp_nativearray_unsafe
        return cpp.NativeArray.unsafeGet(array, index);
        #else
        return untyped array.__unsafe_get(index);
        #end
#else
        return array[index];
#end
    }

    #if !spine_debug_unsafe inline #end public static function unsafeSet<T>(array:Array<T>, index:Int, value:T):Void {
#if spine_debug_unsafe
        if (index < 0 || index >= array.length) throw 'Invalid unsafeSet: index=$index length=${array.length}';
#end
#if cpp
        #if app_cpp_nativearray_unsafe
        cpp.NativeArray.unsafeSet(array, index, value);
        #else
        untyped array.__unsafe_set(index, value);
        #end
#else
        array[index] = value;
#end
    }

}
