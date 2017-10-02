package spine.support.error;

class IllegalArgumentException extends Error {

	public function new (message:String = "") {

		super (message);
		name = "IllegalArgumentException";

	}
}
