package spine.support.utils;

class SnapshotArray<T> {

    var snapshotIndex = -1;

    var snapshots:std.Array<Array<T>> = [];

    var array:Array<T>;

    public var size(get,never):Int;
    inline function get_size():Int {
        return array.length;
    } 

    public function new() {
        array = new Array();
    }

    public function begin() {

        snapshotIndex++;
        var snapshot = snapshots[snapshotIndex];
        if (snapshot == null) {
            snapshot = [].concat(array);
            snapshots[snapshotIndex] = snapshot;
        }
        else {
            snapshot.setSize(array.length);
            for (i in 0...array.length) {
                snapshot.unsafeSet(i, array.unsafeGet(i));
            }
        }
        return snapshot;

    }

    public function end() {

        var snapshot = snapshots[snapshotIndex];
        snapshotIndex--;
        var dynSnapshot:Array<Dynamic> = snapshot;
        for (i in 0...dynSnapshot.length) {
            dynSnapshot.unsafeSet(i, null);
        }

    }

    inline public function removeValue(value:T, identity:Bool):Bool {
        return array.removeValue(value, identity);
    }

    inline public function add(item:T):Void {
        array.add(item);
    }

    inline public function clear():Void {
        array.clear();
    }

}
