package spine.support.utils;

class SerializationException extends Error {

	public function new (message:String = "", ?originalError:Dynamic) {

		if (originalError != null) {
			if (message != '') {
				message += ' ' + originalError;
			} else {
				message = '' + originalError;
			}
		}

		super (message);
		name = "SerializationException";

	}
}
