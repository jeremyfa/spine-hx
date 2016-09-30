package spine.compat;

// From OpenFl: https://github.com/openfl/openfl/blob/openfl3/openfl/errors/ArgumentError.hx

class ArgumentError extends Error {

	public function new (message:String = "") {

		super (message);

		name = "ArgumentError";

	}

}
