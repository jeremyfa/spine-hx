package spine.support.error;

class RuntimeException extends Error {

	public function new (message:String = "") {

		super (message);
		name = "RuntimeException";

	}
}
