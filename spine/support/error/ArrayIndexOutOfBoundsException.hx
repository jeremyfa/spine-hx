package spine.support.error;

class ArrayIndexOutOfBoundsException extends Error {

	public function new (message:String = "") {

		super (message);
		name = "ArrayIndexOutOfBoundsException";

	}
}
