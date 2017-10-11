package spine.support.utils;

import spine.support.files.FileHandle;
import spine.support.utils.JsonValue;
import haxe.Json;

class JsonReader {

    public function new() {}

    public function parse(file:FileHandle):JsonValue {

        return new JsonDynamic(Json.parse(file.getContent()));

    } //parse

} //JsonReader
