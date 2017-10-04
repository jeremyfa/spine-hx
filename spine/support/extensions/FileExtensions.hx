package spine.support.extensions;

import spine.support.files.FileHandle;

class FileExtensions {

    public static function nameWithoutExtension(file:FileHandle):String {
        var name = file.path;
        var slashIndex = name.lastIndexOf('/');
        if (slashIndex != -1) name = name.substring(slashIndex);
        var dotIndex = name.lastIndexOf('.');
        if (dotIndex != -1) name = name.substring(0, dotIndex);
        return name;
    }

}