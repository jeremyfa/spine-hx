package spine.support.utils;

class Pool<T> {
    /** The maximum number of objects that will be pooled. */
    public var max:Int = 0;
    /** The highest number of free objects. Can be reset any time. */
    public var peak:Int = 0;

    private var freeObjects:Array<T>;

    /** @param max The maximum number of free objects to store in this pool. */
    public function new(initialCapacity:Int = 64, max:Int = 999999999) {
        freeObjects = [];
        this.max = max;
    }
    public function free(object:T):Void {
        if (object == null) throw new IllegalArgumentException("object cannot be null.");
        if (freeObjects.length < max) {
            freeObjects.add(object);
            peak = MathUtils.max(peak, freeObjects.size);
        }
        reset(object);
    }

    /** Called when an object is freed to clear the state of the object for possible later reuse. The default implementation calls
     * {@link Poolable#reset()} if the object is {@link Poolable}. */
    public function reset(object:T):Void {
        if (Std.is(object, Poolable)) (cast(object, Poolable)).reset();
    }

    /** Puts the specified objects in the pool. Null objects within the array are silently ignored.
     * @see #free(Object) */
    public function freeAll(objects:Array<T>):Void {
        if (objects == null) throw new IllegalArgumentException("objects cannot be null.");
        var freeObjects:Array<T> = this.freeObjects;
        var max:Int = this.max;
        var i:Int = 0; while (i < objects.size) {
            var object:T = objects.get(i);
            if (object == null) { i++; continue; }
            if (freeObjects.size < max) freeObjects.add(object);
            reset(object);
        i++; }
        peak = MathUtils.max(peak, freeObjects.size);
    }

    /** Removes all free objects from this pool. */
    public function clear():Void {
        freeObjects.clear();
    }

    /** The number of objects available to be obtained. */
    public function getFree():Int {
        return freeObjects.size;
    }

    /** Puts the specified object in the pool, making it eligible to be returned by {@link #obtain()}. If the pool already contains
        * {@link #max} free objects, the specified object is reset but not added to the pool. */
    public function newObject():T {
        return null;
    }

    /** Returns an object from this pool. The object may be new (from {@link #newObject()}) or reused (previously
    * {@link #free(Object) freed}). */
    public function obtain():T {
        return freeObjects.size == 0 ? newObject() : freeObjects.pop();
    }

}

/** Objects implementing this interface will have {@link #reset()} called when passed to {@link Pool#free(Object)}. */
interface Poolable {
    /** Resets the object for reuse. Object references should be nulled and fields may be set to default values. */
    function reset():Void;
}
