package spine.support.utils;

class SerializationException extends Error {

	public function new (message:String = "") {

		super (message);
		name = "SerializationException";

	}
}
