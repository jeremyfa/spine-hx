
package spine;

/** The base class for all constraint datas. */
class ConstraintData {
    public var name:String;
    public var order:Int = 0;
    public var skinRequired:Bool = false;

    public function new(name:String) {
        if (name == null) throw new IllegalArgumentException("name cannot be null.");
        this.name = name;
    }

    /** The constraint's name, which is unique across all constraints in the skeleton of the same type. */
    #if !spine_no_inline inline #end public function getName():String {
        return name;
    }

    /** The ordinal of this constraint for the order a skeleton's constraints will be applied by
     * {@link Skeleton#updateWorldTransform()}. */
    #if !spine_no_inline inline #end public function getOrder():Int {
        return order;
    }

    #if !spine_no_inline inline #end public function setOrder(order:Int):Void {
        this.order = order;
    }

    /** When true, {@link Skeleton#updateWorldTransform()} only updates this constraint if the {@link Skeleton#getSkin()} contains
     * this constraint.
     * @see Skin#getConstraints() */
    #if !spine_no_inline inline #end public function getSkinRequired():Bool {
        return skinRequired;
    }

    #if !spine_no_inline inline #end public function setSkinRequired(skinRequired:Bool):Void {
        this.skinRequired = skinRequired;
    }

    #if !spine_no_inline inline #end public function toString():String {
        return name;
    }
}
