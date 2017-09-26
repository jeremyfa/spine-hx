package;

import Sys.*;
import sys.FileSystem;
import sys.io.File;
import haxe.io.Path;

using StringTools;

class Convert {

/// Convert script

    public static function main() {

        // Get better source map support
        js.Node.require('source-map-support').install();

        // Clone or update official runtime files
        if (FileSystem.exists('./spine-runtimes/.git')) {
            println('Update official spine-runtimes repository\u2026');
            setCwd('spine-runtimes');
            //command('git', ['pull', 'https://github.com/EsotericSoftware/spine-runtimes.git']);
            setCwd('..');
        }
        else {
            println('Clone official spine-runtimes repository\u2026');
            //command('git', ['clone', 'https://github.com/EsotericSoftware/spine-runtimes.git']);
        }

        // Delete previously converted files
        println('Delete previously converted files\u2026');
        deleteRecursive('spine');

        // Convert
        var ctx = {
            javaDir: 'spine-runtimes/spine-libgdx/spine-libgdx/src/com/esotericsoftware/spine',
            haxeDir: 'spine',
            relativePath: '.',
            files: new Map()
        };
        convert(ctx);

    } //main

    static function convert(ctx:{
        javaDir:String,
        haxeDir:String,
        relativePath:String,
        files:Map<String,String>
    }) {

        var fullJavaDir = Path.join([ctx.javaDir, ctx.relativePath]);
        var fullHaxeDir = Path.join([ctx.haxeDir, ctx.relativePath]);

        for (name in FileSystem.readDirectory(fullJavaDir)) {

            var path = Path.join([fullJavaDir, name]);

            if (FileSystem.isDirectory(path)) {

                // Handle sub directory
                //
                convert({
                    javaDir: ctx.javaDir,
                    haxeDir: ctx.haxeDir,
                    relativePath: Path.join([ctx.relativePath, name]),
                    files: ctx.files
                });
            }
            else if (path.endsWith('.java')) {

                // Convert java file
                //
                var javaPath = path;
                var haxePath = ctx.haxeDir + javaPath.substr(0, path.length - 5).substr(ctx.javaDir.length) + '.hx';

                // Log
                println(javaPath.substr(ctx.javaDir.length + 1) + ' -> ' + haxePath.substr(ctx.haxeDir.length + 1));

                // Get contents
                var java = File.getContent(javaPath);

                // Convert java to haxe
                var haxe = javaToHaxe(java);

                // Save file
                if (!FileSystem.exists(Path.directory(haxePath))) {
                    FileSystem.createDirectory(Path.directory(haxePath));
                }
                File.saveContent(haxePath, haxe);
                
                js.Node.process.exit(0);

                // Add file in list
                ctx.files.set(javaPath, haxePath);
            }

        }

    } //convert

    static function javaToHaxe(java:String):String {

        var haxe = '';
        
        var inSingleLineComment = false;
        var inMultiLineComment = false;
        var inClass = false;
        var inMethod = false;
        var inClassName = '';
        var beforeClassBraces = 0;
        var beforeMethodBraces = 0;
        var openBraces = 0;
        var i = 0;
        var pc = ''; // 1 prev character
        var c = ''; // 1 next character
        var cc = ''; // 2 next characters
        var word = ''; // Next word
        var after = '';
        var len = java.length;
        var usedTypes = new Map<String,Bool>();

        var RE_WORD_SEP = ~/[^a-zA-Z0-9_]/;
        var RE_WORD = ~/^[a-zA-Z0-9_]+/;
        var RE_STRING = ~/^(?:"(?:[^"\\]*(?:\\.[^"\\]*)*)"|'(?:[^'\\]*(?:\\.[^'\\]*)*)')/;
        var RE_IMPORT = ~/^import\s+(static\s+)?([^;\s]+)\s*;/;
        var RE_PROPERTY = ~/^((?:public|private|protected|static|final|dynamic)\s+)*([a-zA-Z0-9,<>\[\]]+)\s+([a-zA-Z0-9]+)\s*;/;
        var RE_CONSTRUCTOR = ~/^((?:public|private|protected|final)\s+)*([a-zA-Z0-9,<>\[\]]+)\s*\(\s*([^\)]*)\s*\)\s*{/;
        var RE_METHOD = ~/^((?:public|private|protected|static|final)\s+)*([a-zA-Z0-9,<>\[\]]+)\s+([a-zA-Z0-9]+)\s*\(\s*([^\)]*)\s*\)\s*{/;

        function convertArgs(inArgs:String):Array<{name:String, type:String}> {

            var result = [];

            var ltOpen = 0;
            var i = 0;

            return result;

        } //convertArgs

        function convertModifiers(inModifiers:String):Map<String,Bool> {

            var modifiers = new Map<String,Bool>();

            if (inModifiers != null) {
                for (item in inModifiers.replace("\t", ' ').split(' ')) {
                    item = item.trim();
                    if (item != '') {
                        modifiers.set(item, true);
                    }
                }
            }

            return modifiers;

        } //convertModifiers

        function convertType(inType:String):String {

            var type = switch (inType) {
                case 'float': 'Float';
                case 'int': 'Int';
                case 'boolean': 'Bool';
                default: null;
            }
            if (type == null) {
                // Handle more complex cases if needed
                type = inType;
            }
            usedTypes.set(type, true);
            return type;

        } //convertType

        while (i < java.length) {

            after = java.substr(i);
            c = after.charAt(0);
            cc = c + (i < len ? after.charAt(1) : '');
            
            if (i > 0) {
                pc = java.charAt(i - 1);
            }
            else {
                pc = '';
            }
            if (pc != '' &&
                !inSingleLineComment &&
                !inMultiLineComment &&
                RE_WORD_SEP.match(pc) &&
                RE_WORD.match(after)) {
                word = RE_WORD.matched(0);
            }
            else {
                word = '';
            }

            if (inSingleLineComment) {
                if (c == "\n") {
                    inSingleLineComment = false;
                }
                haxe += c;
                i++;
            }
            else if (inMultiLineComment) {
                if (cc == '*/') {
                    inMultiLineComment = false;
                    haxe += cc;
                    i += 2;
                } else {
                    haxe += c;
                    i++;
                }
            }
            else if (cc == '//') {
                inSingleLineComment = true;
                haxe += cc;
                i += 2;
            }
            else if (cc == '/*') {
                inMultiLineComment = true;
                haxe += cc;
                i += 2;
            }
            else if (c == '"' || c == '\'') {
                if (!RE_STRING.match(after)) {
                    throw 'Failed to parse string at line ' + java.substr(0,i).split("\n").length;
                }
                haxe += RE_STRING.matched(0);
                i += RE_STRING.matched(0).length;
            }
            else if (c == '{') {
                openBraces++;
                haxe += c;
                i++;
            }
            else if (c == '}') {
                openBraces--;
                haxe += c;
                i++;
                if (inClass && openBraces == beforeClassBraces) {
                    inClass = false;
                }
                if (inMethod && openBraces == beforeMethodBraces) {
                    inMethod = false;
                }
            }
            // Method body
            else if (inMethod) {
                haxe += c;
                i++;
            }
            // Class specifics
            else if (inClass) {
                // Method or property?
                if (word != '') {
                    if (RE_PROPERTY.match(after)) {

                        println('PROPERTY: ' + RE_PROPERTY.matched(0));

                        var modifiers = convertModifiers(RE_PROPERTY.matched(1));
                        
                        if (modifiers.exists('public')) {
                            haxe += 'public ';
                        }
                        if (modifiers.exists('protected')) {
                            haxe += 'public ';
                        }
                        if (modifiers.exists('private')) {
                            haxe += 'private ';
                        }
                        if (modifiers.exists('static')) {
                            haxe += 'static ';
                        }

                        var type = convertType(RE_PROPERTY.matched(2));
                        var name = RE_PROPERTY.matched(3);

                        haxe += 'var ' + name + ':' + type + ';';
                        i += RE_PROPERTY.matched(0).length;

                    }
                    else if (RE_CONSTRUCTOR.match(after)) {

                        println('CONSTRUCTOR: ' + RE_CONSTRUCTOR.matched(0));

                        haxe += RE_CONSTRUCTOR.matched(0);
                        i += RE_CONSTRUCTOR.matched(0).length;
                        inMethod = true;
                        beforeMethodBraces = openBraces;
                        openBraces++;

                    }
                    else if (RE_METHOD.match(after)) {

                        println('METHOD: ' + RE_METHOD.matched(0));

                        var modifiers = convertModifiers(RE_METHOD.matched(1));
                        
                        if (modifiers.exists('public')) {
                            haxe += 'public ';
                        }
                        if (modifiers.exists('protected')) {
                            haxe += 'public ';
                        }
                        if (modifiers.exists('private')) {
                            haxe += 'private ';
                        }
                        if (modifiers.exists('static')) {
                            haxe += 'static ';
                        }

                        var type = convertType(RE_METHOD.matched(2));
                        var name = RE_METHOD.matched(3);

                        var args = RE_METHOD.matched(4);
                        println('  ARGS: ' + args);

                        haxe += RE_METHOD.matched(0);
                        i += RE_METHOD.matched(0).length;
                        inMethod = true;
                        beforeMethodBraces = openBraces;
                        openBraces++;

                        

                    }
                    else {
                        haxe += c;
                        i++;
                    }
                }
                else {
                    haxe += c;
                    i++;
                }
            }
            // Package
            else if (word == 'package') {
                haxe += word;
                i += word.length;
                var pack = '';
                c = java.charAt(i);
                while (c != ';') {
                    pack += c;
                    i++;
                    c = java.charAt(i);
                }

                // Package replaces
                pack = pack.replace('com.esotericsoftware.spine', 'spine');

                // Add package
                haxe += pack;
            }
            // Import
            else if (word == 'import') {
                if (!RE_IMPORT.match(after)) {
                    throw 'Failed to parse import at line ' + java.substr(0,i).split("\n").length;
                }
                
                // Import replaces
                var pack = RE_IMPORT.matched(2);
                pack = replaceStart(pack, 'com.esotericsoftware.spine.', 'spine.');
                pack = replaceStart(pack, 'com.badlogic.gdx.', 'spine.support.');

                // Add import
                haxe += 'import ' + pack + ';';
                i += RE_IMPORT.matched(0).length;
            }
            // Class modifiers we don't want to keep
            else if (word == 'public' || word == 'static') {
                // Remove it as it's invalid in haxe
                i += word.length;
                c = java.charAt(i);
                while (c == ' ') {
                    i++;
                    c = java.charAt(i);
                }
            }
            // Class public modifier
            else if (word == 'class') {
                inClass = true;
                haxe += word;
                i += word.length;
            }
            // Just add code as is
            else {
                haxe += c;
                i++;
            }
        
        }

        return haxe;

    } //javaToHaxe

/// Utils

    static function replaceStart(str:String, from:String, to:String):String {

        if (str.startsWith(from)) {
            return to + str.substr(from.length);
        }

        return str;

    } //replaceStart

    static function deleteRecursive(path:String) {

        if (!FileSystem.exists(path)) {
            return;
        }
        else if (FileSystem.isDirectory(path)) {
            for (name in FileSystem.readDirectory(path)) {
                deleteRecursive(Path.join([path, name]));
            }
            FileSystem.deleteDirectory(path);
        }
        else {
            FileSystem.deleteFile(path);
        }

    } //deleteRecursive

} //Convert
