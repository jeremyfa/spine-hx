package spine.support.utils;

class SerializationException extends Error {

	public function new (message:String = "", ?originalError:Dynamic) {

		super (message);
		name = "SerializationException";

	}
}
