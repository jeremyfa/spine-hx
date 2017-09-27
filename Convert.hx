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
        //deleteRecursive('spine');

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

        var cleanedHaxe = '';
        var cleanedHaxeInMultiLineComment = false;
        var cleanedHaxeInSingleLineComment = false;

        var separators = new Map<String,Bool>();
        separators.set('{', true);
        separators.set('}', true);
        separators.set(',', true);
        separators.set('(', true);
        separators.set(')', true);
        separators.set(':', true);
        separators.set('?', true);
        separators.set(';', true);
        separators.set('.', true);
        separators.set('<', true);
        separators.set('>', true);
        separators.set('=', true);
        separators.set('-', true);
        separators.set('+', true);
        separators.set('*', true);
        separators.set('/', true);
        separators.set('%', true);
        separators.set('&', true);
        separators.set('|', true);
        
        // Stub
        var consumeExpression = function(until:String, ?options:{
            ?varType:String,
            ?isValue:Bool
        }):String { return null; }

        var inSingleLineComment = false;
        var inMultiLineComment = false;
        var inClass = false;
        var inMethod = false;
        var beforeClassBraces = 0;
        var beforeMethodBraces = 0;
        var inFor1 = false;
        var inFor2 = false;
        var inFor3 = false;
        var inFor1Body = false;
        var inFor2Body = false;
        var inFor3Body = false;
        var inFor1Splits:Array<Int> = [];
        var inFor2Splits:Array<Int> = [];
        var inFor3Splits:Array<Int> = [];
        var beforeFor1Parens = 0;
        var beforeFor2Parens = 0;
        var beforeFor3Parens = 0;
        var openBraces = 0;
        var openParens = 0;
        var lastSeparator = '';
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
        var RE_PROPERTY = ~/^((?:public|private|protected|static|final|dynamic)\s+)*([a-zA-Z0-9,<>\[\]_]+)\s+([a-zA-Z0-9_]+)\s*(;|=|,)/;
        var RE_CONSTRUCTOR = ~/^((?:public|private|protected|final)\s+)*([a-zA-Z0-9,<>\[\]_]+)\s*\(\s*([^\)]*)\s*\)\s*{/;
        var RE_METHOD = ~/^((?:public|private|protected|static|final)\s+)*([a-zA-Z0-9,<>\[\]_]+)\s+([a-zA-Z0-9_]+)\s*\(\s*([^\)]*)\s*\)\s*{/;
        var RE_VAR = ~/^(?:([a-zA-Z0-9,<>\[\]_]+)\s+)?([a-zA-Z0-9_]+)\s*(;|=|,)/;

        inline function computeCleanedHaxe() {

            var i = cleanedHaxe.length;
            var len = haxe.length;
            var c = '';
            var cc = '';

            while (i < len) {
                c = haxe.charAt(i);
                cc = c + (i < len ? after.charAt(1) : '');
                
                if (cleanedHaxeInSingleLineComment) {
                    if (c == "\n") {
                        cleanedHaxeInSingleLineComment = false;
                    }
                    cleanedHaxe += c;
                    i++;
                }
                else if (cleanedHaxeInMultiLineComment) {
                    if (cc == '*/') {
                        cleanedHaxeInMultiLineComment = false;
                        cleanedHaxe += cc;
                        i += 2;
                    } else {
                        cleanedHaxe += c;
                        i++;
                    }
                }
                else if (cc == '//') {
                    cleanedHaxeInSingleLineComment = true;
                    cleanedHaxe += cc;
                    i += 2;
                }
                else if (cc == '/*') {
                    cleanedHaxeInMultiLineComment = true;
                    cleanedHaxe += cc;
                    i += 2;
                }
                else if (c == '"' || c == '\'') {
                    if (!RE_STRING.match(after)) {
                        throw 'Failed to parse string at line ' + java.substr(0,i).split("\n").length;
                    }
                    var n = 2;
                    var strLen = RE_STRING.matched(0).length;
                    cleanedHaxe += c;
                    while (n++ < strLen) cleanedHaxe += ' ';
                    cleanedHaxe += c;
                    i += strLen;
                }
                else {
                    cleanedHaxe += c;
                    i++;
                }
            }

        } //computeCleanedHaxe

        inline function computeLastSeparator() {

            if (cleanedHaxeInSingleLineComment || cleanedHaxeInMultiLineComment) return;

            var i = cleanedHaxe.length - 1;
            var c = '';

            while (i >= 0) {
                c = cleanedHaxe.charAt(i);

                if (separators.exists(c)) {
                    lastSeparator = c;
                    break;
                }

                i--;
            }

        } //computeLastSeparator

        function nextIteration() {

            computeCleanedHaxe();
            computeLastSeparator();

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

        } //nextIteration

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
                case 'float[]': 'FloatArray';
                case 'float[][]': 'FloatArray2D';
                case 'void': 'Void';
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

        function convertArgs(inArgs:String):Array<{name:String, type:String}> {

            var args = [];

            var ltOpen = 0;
            var i = 0;
            var len = inArgs.length;
            var rawType = '';
            var c = '';

            while (i < len) {

                c = inArgs.charAt(i);

                if (c.trim() == '' && ltOpen == 0) {
                    var type = convertType(rawType.trim());
                    while (c.trim() == '') {
                        i++;
                        c = inArgs.charAt(i);
                    }
                    var name = '';
                    while (c != ',' && c != ')' && c.trim() != '') {
                        name += c;
                        i++;
                        c = inArgs.charAt(i);
                    }
                    args.push({
                        name: name,
                        type: type
                    });
                    i++;
                    c = inArgs.charAt(i);
                    while (c.trim() == '' && i < len) {
                        i++;
                        c = inArgs.charAt(i);
                    }
                    rawType = '';
                }
                else if (c == '<') {
                    ltOpen++;
                    i++;
                    rawType += c;
                }
                else if (c == '>') {
                    ltOpen--;
                    i++;
                    rawType += c;
                }
                else if (c.trim() != '') {
                    i++;
                    rawType += c;
                }
                else {
                    i++;
                }

            }

            return args;

        } //convertArgs

        function consumeCommentOrString():Bool {

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
            else {
                return false;
            }

            return true;

        } //consumeCommentOrString

        function consumeBrace():Bool {

            if (c == '{') {
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
            else {
                return false;
            }

            return true;

        } //consumeBrace

        function consumeParen():Bool {

            if (c == '(') {
                openParens++;
                haxe += c;
                i++;
            }
            else if (c == ')') {
                openParens--;
                i++;
                var forSplits = null;
                if (inFor3 && openParens == beforeFor3Parens) {
                    inFor3 = false;
                    inFor3Body = true;
                    forSplits = inFor3Splits;
                }
                else if (inFor2 && openParens == beforeFor2Parens) {
                    inFor2 = false;
                    inFor2Body = true;
                    forSplits = inFor2Splits;
                }
                else if (inFor1 && openParens == beforeFor1Parens) {
                    inFor1 = false;
                    inFor1Body = true;
                    forSplits = inFor1Splits;
                }
                else {
                    haxe += c;
                }

                if (forSplits != null) {
                    // Extract for parts
                    var forInit = haxe.substring(forSplits[0], forSplits[1]).trim();
                    var forCondition = haxe.substring(forSplits[1], forSplits[2]).trim();
                    var forIncrement = haxe.substring(forSplits[2]).trim();

                    // Rewind and write while loop
                    haxe = haxe.substring(0, forSplits[1]);
                    haxe += ' while (' + forCondition.substring(0, forCondition.length - 1) + ') {';
                    
                    // Detect if the loop body is inline or not
                    consumeCommentOrString();

                    c = java.charAt(i);
                    while (i < len && c.trim() == '') {
                        i++;
                        haxe += c;
                        c = java.charAt(i);
                    }

                    if (c != '{') {
                        consumeExpression(';');
                        haxe += ' ' + forIncrement + ' }';
                    }
                    else {
                        openBraces++;
                        consumeExpression('}');
                        haxe = haxe.substring(0, haxe.length - 1);
                        haxe += forIncrement + ' }';
                    }
                }
            }
            else {
                return false;
            }

            return true;

        } //consumeParen

        consumeExpression = function(until:String, ?options:{
            ?varType:String,
            ?isValue:Bool
        }):String {

            var openBracesStart = openBraces;
            var openParensStart = openParens;
            var stopChar = '';
            var varType = options != null ? options.varType : null;
            var isValue:Bool = options != null ? options.isValue : false;

            while (i < len) {

                nextIteration();

                if (consumeCommentOrString()) {
                    // Nothing to do
                }
                else if (consumeBrace()) {
                    if (openBraces < openBracesStart && until.indexOf('}') != -1) {
                        stopChar = '}';
                        break;
                    }
                }
                else if (consumeParen()) {
                    if (openParens < openParensStart && until.indexOf(')') != -1) {
                        stopChar = ')';
                        break;
                    }
                }
                else if (c == ';' && until.indexOf(';') != -1 && openBraces == openBracesStart && openParens == openParensStart) {
                    haxe += c;
                    i++;
                    stopChar = c;
                        
                    if (inFor3) {
                        inFor3Splits.push(haxe.length);
                    }
                    else if (inFor2) {
                        inFor2Splits.push(haxe.length);
                    }
                    else if (inFor1) {
                        inFor1Splits.push(haxe.length);
                    }

                    break;
                }
                else if (isValue) {
                    if (c == ',' || c == ';') {
                        isValue = false;
                        haxe += ';';
                        
                        if (c == ';') {
                            if (inFor3) {
                                inFor3Splits.push(haxe.length);
                            }
                            else if (inFor2) {
                                inFor2Splits.push(haxe.length);
                            }
                            else if (inFor1) {
                                inFor1Splits.push(haxe.length);
                            }
                        }

                        i++;
                    }
                    else {
                        haxe += c;
                        i++;
                    }
                }
                else if (word != '') {
                    if (word == 'return' || word == 'throw') {
                        isValue = true;
                        haxe += word;
                        i += word.length;
                    }
                    else if (word == 'for' && after.substr(word.length).ltrim().startsWith('(')) {
                        i += word.length;
                        c = java.charAt(i);
                        while (c != '(') {
                            i++;
                            c = java.charAt(i);
                        }
                        i++;
                        if (!inFor1 && !inFor1Body) {
                            inFor1 = true;
                            inFor1Splits = [haxe.length];
                            beforeFor1Parens = openParens;
                        }
                        else if (!inFor2 && !inFor2Body) {
                            inFor2 = true;
                            inFor2Splits = [haxe.length];
                            beforeFor2Parens = openParens;
                        }
                        else if (!inFor3 && !inFor3Body) {
                            inFor3 = true;
                            inFor3Splits = [haxe.length];
                            beforeFor3Parens = openParens;
                        }
                        openParens++;
                    }
                    else if ((lastSeparator == '' || lastSeparator == ';' || lastSeparator == '{' || lastSeparator == '}' || ((inFor1 || inFor2 || inFor3) && lastSeparator == '(')) && RE_VAR.match(after)) {
                        var type = varType;
                        if (RE_VAR.matched(1) != null) {
                            type = convertType(RE_VAR.matched(1));
                        }
                        var name = RE_VAR.matched(2);

                        haxe += 'var ' + name;
                        if (type != null) {
                            haxe += ':' + type;
                        }

                        var end = RE_VAR.matched(3);
                        if (end == ';') {
                            haxe += ';';
                        }
                        else if (end == '=') {
                            haxe += ' =';
                            isValue = true;
                        }
                        else if (end == ',') {
                            haxe += ', ';
                            varType = type;
                        }

                        i += RE_VAR.matched(0).length;

                        if (inFor3 && end == ';') {
                            inFor3Splits.push(haxe.length);
                        }
                        else if (inFor2 && end == ';') {
                            inFor2Splits.push(haxe.length);
                        }
                        else if (inFor1 && end == ';') {
                            inFor1Splits.push(haxe.length);
                        }

                        if (end == ';' && until.indexOf(';') != -1) {
                            stopChar = ';';
                            break;
                        }
                    }
                    else {
                        haxe += c;
                        i++;
                    }
                }
                else if (c == ';') {
                    haxe += c;
                    i++;
                    if (inFor3) {
                        inFor3Splits.push(haxe.length);
                    }
                    else if (inFor2) {
                        inFor2Splits.push(haxe.length);
                    }
                    else if (inFor1) {
                        inFor1Splits.push(haxe.length);
                    }
                }
                else {
                    haxe += c;
                    i++;
                }
            }

            return stopChar;

        } //consumeExpression

        while (i < java.length) {

            nextIteration();

            if (consumeCommentOrString()) {
                // Nothing to do
            }
            else if (consumeBrace()) {
                // Nothing to do
            }
            else if (consumeParen()) {
                // Nothing to do
            }
            // Method body
            else if (inMethod) {
                consumeExpression('}');
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

                        haxe += 'var ' + name + ':' + type;
                        i += RE_PROPERTY.matched(0).length;

                        var end = RE_PROPERTY.matched(4);
                        if (end == ';') {
                            haxe += ';';
                        }
                        else if (end == '=') {
                            haxe += ' =';
                            consumeExpression(',;', {varType: type, isValue: true});
                        }
                        else if (end == ',') {
                            haxe += ',';
                            consumeExpression(',;', {varType: type});
                        }

                    }
                    else if (RE_CONSTRUCTOR.match(after)) {

                        println('CONSTRUCTOR: ' + RE_CONSTRUCTOR.matched(0));

                        var modifiers = convertModifiers(RE_CONSTRUCTOR.matched(1));
                        
                        if (modifiers.exists('public')) {
                            haxe += 'public ';
                        }
                        if (modifiers.exists('protected')) {
                            haxe += 'public ';
                        }
                        if (modifiers.exists('private')) {
                            haxe += 'private ';
                        }

                        var args = convertArgs(RE_CONSTRUCTOR.matched(3));

                        haxe += 'function new(';
                        var parts = [];
                        for (arg in args) {
                            parts.push(arg.name + ':' + arg.type);
                        }
                        haxe += parts.join(', ') + ') {';

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
                        var args = convertArgs(RE_METHOD.matched(4));

                        haxe += 'function ' + name + '(';
                        var parts = [];
                        for (arg in args) {
                            parts.push(arg.name + ':' + arg.type);
                        }
                        haxe += parts.join(', ') + '):' + type + ' {';

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
            else if (word == 'public' || word == 'static' || word == 'abstract') {
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
