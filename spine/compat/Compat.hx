package spine.compat;

// From HaxeFoundation/as3hx, edited for spine runtime

import Type;
import haxe.macro.Expr;
import haxe.macro.Context;

/**
 * Collection of functions that just have no real way to be compatible in Haxe
 */
class Compat {

#if !macro
    /**
     * According to Adobe:
     * The result is limited to six possible string values:
     *      boolean, function, number, object, string, and xml.
     * If you apply this operator to an instance of a user-defined class,
     * the result is the string object.
     *
     * TODO: TUnknown returns "undefined" on top of this. Not positive on this
     */
    public static function typeof(v:Dynamic) : String {
        return switch(Type.typeof(v)) {
            case TUnknown: "undefined";
            case TObject: "object";
            case TNull: "object";
            case TInt: "number";
            case TFunction: "function";
            case TFloat: "number";
            case TEnum(e): "object";
            case TClass(c):
                switch(Type.getClassName(c)) {
                    case "String": "string";
                    case "Xml": "xml";
                    case "haxe.xml.Fast": "xml";
                    default: "object";
                }
            case TBool: "boolean";
        };
    }

    public static inline function setArrayLength<T>(a:Array<Null<T>>, length:Int) {
        if (a.length > length) a.splice(length, a.length - length);
        else a[length - 1] = null;
    }

#end

    /**
     * Converts a typed expression into a Float.
     */
    macro public static function parseFloat(e:Expr) : Expr {
        var _ = function (e:ExprDef) return { expr: e, pos: Context.currentPos() };
        switch (Context.typeof(e)) {
            case TInst(t,params):
                var castToFloat = _(ECast(e, TPath({name:"Float", pack:[], params:[], sub:null})));
                if (t.get().pack.length == 0)
                    switch (t.get().name) {
                        case "Int": return castToFloat;
                        case "Float": return castToFloat;
                        default:
                    }
            default:
        }
        return _(ECall( _(EField( _(EConst(CIdent("Std"))), "parseFloat")), [_(ECall( _(EField( _(EConst(CIdent("Std"))), "string")), [e]))]));
    }

    /**
     * Converts a typed expression into an Int.
     */
    macro public static function parseInt(e:Expr) : Expr {
        var _ = function (e:ExprDef) return { expr: e, pos: Context.currentPos() };
        switch (Context.typeof(e)) {
            case TInst(t,params):
                if (t.get().pack.length == 0)
                    switch (t.get().name) {
                        case "Int": return _(ECast(e, TPath({name:"Int", pack:[], params:[], sub:null})));
                        case "Float": return _(ECall( _(EField( _(EConst(CIdent("Std"))), "int")), [_(ECast(e, TPath({name:"Float", pack:[], params:[], sub:null})))]));
                        default:
                    }
            default:
        }
        return _(ECall( _(EField( _(EConst(CIdent("Std"))), "parseInt")), [_(ECall( _(EField( _(EConst(CIdent("Std"))), "string")), [e]))]));
    }

#if !macro

    /**
     * Runtime value of FLOAT_MAX depends on target platform
     */
    public static var FLOAT_MAX(get, never):Float;
    static inline function get_FLOAT_MAX():Float {
        #if flash
        return untyped __global__['Number'].MAX_VALUE;
        #elseif js
        return untyped __js__('Number.MAX_VALUE');
        #elseif cs
        return untyped __cs__('double.MaxValue');
        #elseif java
        return untyped __java__('Double.MAX_VALUE');
        #elseif cpp
        return 3.402823e+38;
        #elseif python
        return PythonSysAdapter.float_info.max;
        #else
        return 1.79e+308;
        #end
    }

    /**
     * Runtime value of FLOAT_MIN depends on target platform
     */
    public static var FLOAT_MIN(get, never):Float;
    static inline function get_FLOAT_MIN():Float {
        #if flash
        return untyped __global__['Number'].MIN_VALUE;
        #elseif js
        return untyped __js__('Number.MIN_VALUE');
        #elseif cs
        return untyped __cs__('double.MinValue');
        #elseif java
        return untyped __java__('Double.MIN_VALUE');
        #elseif cpp
        return 2.2250738585072e-308;
        #elseif python
        return PythonSysAdapter.float_info.min;
        #else
        return -1.79E+308;
        #end
    }

    /**
     * Runtime value of INT_MAX depends on target platform
     */
    public static var INT_MAX(get, never):Int;
    static inline function get_INT_MAX():Int {
        #if flash
        return untyped __global__['int'].MAX_VALUE;
        #elseif js
        return untyped __js__('Number.MAX_SAFE_INTEGER');
        #elseif cs
        return untyped __cs__('int.MaxValue');
        #elseif java
        return untyped __java__('Integer.MAX_VALUE');
        #elseif cpp
        return 2147483647;
        #elseif python
        return PythonSysAdapter.maxint;
        #elseif php
        return untyped __php__('PHP_INT_MAX');
        #else
        return 2^31-1;
        #end
    }

    /**
     * Runtime value of INT_MIN depends on target platform
     */
    public static var INT_MIN(get, never):Int;
    static inline function get_INT_MIN():Int {
        #if flash
        return untyped __global__['int'].MIN_VALUE;
        #elseif js
        return untyped __js__('Number.MIN_SAFE_INTEGER');
        #elseif cs
        return untyped __cs__('int.MinValue');
        #elseif java
        return untyped __java__('Integer.MIN_VALUE');
        #elseif cpp
        return -2147483648;
        #elseif python
        return -PythonSysAdapter.maxint - 1;
        #elseif php
        return untyped __php__('PHP_INT_MIN');
        #else
        return -2^31;
        #end
    }

    #end
}
