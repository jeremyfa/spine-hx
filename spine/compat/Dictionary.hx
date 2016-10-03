package spine.compat; #if ((!openfl && !flash) || display)


import haxe.ds.StringMap;
import haxe.ds.IntMap;
import haxe.ds.HashMap;
import haxe.ds.ObjectMap;
import haxe.ds.WeakMap;
import haxe.ds.EnumValueMap;
import haxe.Constraints.IMap;

@:multiType(K)


abstract Dictionary<K, V> (IMap<K, V>) {


	public function new (weakKeys:Bool = false);


	@:arrayAccess public inline function get (key:K):V {

		return this.get (key);

	}


	@:arrayAccess public inline function set (key:K, value:V):V {

		this.set (key, value);
		return value;

	}


	public inline function iterator ():Iterator<K> {

		return this.keys ();

	}


	@:to static inline function toStringMap<K:String, V> (t:IMap<K, V>, weakKeys:Bool):StringMap<V> {

		return new StringMap<V> ();

	}


	@:to static inline function toIntMap<K:Int, V> (t:IMap<K, V>, weakKeys:Bool):IntMap<V> {

		return new IntMap<V> ();

	}


	@:to static inline function toEnumValueMapMap<K:EnumValue, V> (t:IMap<K, V>, weakKeys:Bool):EnumValueMap<K, V> {

		return new EnumValueMap<K, V> ();

	}


	@:to static inline function toObjectMap<K:{},V> (t:IMap<K, V>, weakKeys:Bool):ObjectMap<K, V> {

		return new ObjectMap<K, V> ();

	}


	@:from static inline function fromStringMap<V> (map:StringMap<V>):Dictionary<String, V> {

		return cast map;

	}


	@:from static inline function fromIntMap<V> (map:IntMap<V>):Dictionary<Int, V> {

		return cast map;

	}


	@:from static inline function fromObjectMap<K:{}, V> (map:ObjectMap<K, V>):Dictionary<K, V> {

		return cast map;

	}


}


#elseif openfl


typedef Dictionary<K,V> = openfl.utils.Dictionary<K,V>;


#else


typedef Dictionary<K,V> = flash.utils.Dictionary<K,V>;


#end
