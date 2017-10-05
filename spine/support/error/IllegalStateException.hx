package spine.support.error;

class IllegalStateException extends Error {

	public function new (message:String = "") {

		super (message);
		name = "IllegalStateException";

	}
}
