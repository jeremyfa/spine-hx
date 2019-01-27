package;

import Sys.*;
import sys.FileSystem;
import sys.io.File;
import haxe.io.Path;
import haxe.Json;
import js.node.ChildProcess;

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
            command('git', ['pull', 'https://github.com/EsotericSoftware/spine-runtimes.git']);
            setCwd('..');
        }
        else {
            println('Clone official spine-runtimes repository\u2026');
            command('git', ['clone', '-b', '3.7', '--depth', '1', 'https://github.com/EsotericSoftware/spine-runtimes.git']);
        }

        // Delete previously converted files
        println('Delete previously converted files\u2026');
        deleteRecursive('spine', ['support', 'SkeletonBinary.hx']);

        // Convert
        var ctx = {
            javaDir: 'spine-runtimes/spine-libgdx/spine-libgdx/src/com/esotericsoftware/spine',
            haxeDir: 'spine',
            relativePath: '.',
            files: new Map(),
            enums: new Map(),
            types: new Map(),
            secondPass: false
        };
        convert(ctx);

        // Add import.hx
        File.saveContent('spine/import.hx', "
import spine.support.error.*;
import spine.support.utils.BooleanArray;
import spine.support.utils.Short;
import spine.support.utils.ShortArray;
import spine.support.utils.ShortArray2D;
import spine.support.utils.IntArray;
import spine.support.utils.IntArray2D;
import spine.support.utils.FloatArray;
import spine.support.utils.FloatArray2D;
import spine.support.utils.StringArray;
import spine.support.utils.StringBuilder;
import spine.support.math.MathUtils;
import spine.BlendMode;

using spine.support.extensions.StringExtensions;
using spine.support.extensions.ArrayExtensions;
using spine.support.extensions.FileExtensions;
using spine.support.extensions.SpineExtensions;
using StringTools;
");

        fixCompilerErrors(ctx);

    } //main

/// Convert

    static function convert(ctx:ConvertContext, root:Bool = true, secondPass:Bool = false) {

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
                    files: ctx.files,
                    enums: ctx.enums,
                    types: ctx.types,
                    secondPass: secondPass
                }, false, secondPass);
            }
            else if (path.endsWith('.java')) {

                // Convert java file
                //
                var javaPath = path;
                var haxePath = ctx.haxeDir + javaPath.substr(0, path.length - 5).substr(ctx.javaDir.length) + '.hx';
                var relJavaPath = javaPath.substr(ctx.javaDir.length + 1);

                if (!skippedFiles.exists(relJavaPath)) {

                    // Log
                    println('[pass ' + (secondPass ? 2 : 1) + '] ' + relJavaPath + ' -> ' + haxePath.substr(ctx.haxeDir.length + 1));

                    // Get contents
                    var java = File.getContent(javaPath);
                    var type = 'spine.' + javaPath.substring(ctx.javaDir.length + 1, javaPath.length - 5).replace('/', '.');

                    // Convert java to haxe
                    var haxe = javaToHaxe(java, javaPath.substr(ctx.javaDir.length + 1), type, ctx.haxeDir, ctx);

                    // Save file
                    if (!FileSystem.exists(Path.directory(haxePath))) {
                        FileSystem.createDirectory(Path.directory(haxePath));
                    }
                    File.saveContent(haxePath, haxe);

                    // Add file in list
                    ctx.files.set(javaPath, haxePath);
                }
            }

        }

        // Do parsing a second time, because we gathered information
        // on the previous pass that we can use now
        if (!secondPass && root) {
            ctx.secondPass = true;
            convert(ctx, true, true);
        }

    } //convert

    static function javaToHaxe(java:String, filePath:String, rootType:String, haxeDir:String, ctx:ConvertContext):String {

        if (FileSystem.exists(Path.join([haxeDir, 'support/overrides', replaceStart(rootType, 'spine.', '').replace('.','/') + '.hx']))) {
            var haxe = 'package ' + rootType.substring(0, rootType.lastIndexOf('.')) + ';' + "\n";
            haxe += "\n";
            haxe += 'typedef ' + rootType.substring(rootType.lastIndexOf('.') + 1) + ' = spine.support.overrides.' + replaceStart(rootType, 'spine.', '') + ';' + "\n";
            haxe += "\n";
            return haxe;
        }

        // To differenciate the two pools of this class.
        // That is rather hacky but it works.
        if (rootType == 'spine.utils.Triangulator') {
            java = java.replace('polygonIndicesPool = new Pool()', 'polygonIndicesPool = new Pool2()');
        }

        // Perform some replaces to facilitate parsing
        java = java.replace('ObjectMap<Key, ', 'ObjectMap<Key,');

        var haxe = '';
        var cleanedJava = cleanedCode(java);

        var cleanedHaxe = '';
        var cleanedHaxeInMultiLineComment = false;
        var cleanedHaxeInSingleLineComment = false;

        var wordReplaces = new Map<String,String>();
        wordReplaces.set('in', 'In');

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

        var controls = new Map<String,Bool>();
        controls.set('if', true);
        controls.set('else', true);
        controls.set('while', true);
        controls.set('do', true);
        controls.set('for', true);
        controls.set('switch', true);
        controls.set('case', true);
        controls.set('throw', true);
        controls.set('return', true);
        controls.set('try', true);
        controls.set('catch', true);
        controls.set('new', true);
        controls.set('continue', true);
        controls.set('true', true);
        controls.set('false', true);
        controls.set('break', true);
        
        // Stub
        var consumeExpression = function(?options:{
            ?varType:String,
            ?varModifiers:Array<String>,
            ?isVarValue:Bool,
            ?inProperties:Bool,
            ?until:String,
            ?untilWords:Array<String>
        }):String { return null; }

        var inSingleLineComment = false;
        var inMultiLineComment = false;
        var importedTypes:Map<String,TypeInfo> = new Map();
        var inClass = false;
        var inClassInfo:TypeInfo = null;
        var inSubClass = false;
        var inSubClassInfo:TypeInfo = null;
        var loopStack:Array<{
            control:String,
            label:String
        }> = [];
        var classHasConstructor = false;
        var subClassHasConstructor = false;
        var inMethod = false;
        var inSkippedMethod = false;
        var inMethodName = '';
        var inEnum = false;
        var inEnumName = '';
        var inEnumValues:Array<String> = [];
        var extraHaxe = '';
        var inInterface = false;
        var inInterfaceInfo:TypeInfo = null;
        var inFor = false;
        var inCall = false;
        var continueToLabels:Array<{
            breakCode:String,
            continueCode:String,
            depth:Int
        }> = [];
        var beforeClassBraces = 0;
        var beforeSubClassBraces = 0;
        var beforeInterfaceBraces = 0;
        var beforeEnumBraces = 0;
        var beforeMethodBraces = 0;
        var nextSwitchIndex = 0;
        var openBraces = 0;
        var openParens = 0;
        var openBrackets = 0;
        var lastSeparator = '';
        var i = 0;
        var pc = ''; // 1 prev character
        var c = ''; // 1 next character
        var cc = ''; // 2 next characters
        var word = ''; // Next word
        var after = '';
        var cleanedAfter = '';
        var len = java.length;
        var usedTypes = new Map<String,Bool>();

        function fail(message:String) {
            throw message + ' at ' + filePath + ':' + java.substr(0,i).split("\n").length;
        }

        function computeCleanedHaxe() {

            var i = cleanedHaxe.length;
            var len = haxe.length;
            var c = '';
            var cc = '';
            var after = '';

            while (i < len) {
                after = haxe.substring(i);
                c = haxe.charAt(i);
                cc = c + (i < len ? after.charAt(1) : '');
                
                if (cleanedHaxeInSingleLineComment) {
                    if (c == "\n") {
                        cleanedHaxeInSingleLineComment = false;
                    }
                    cleanedHaxe += ' ';
                    i++;
                }
                else if (cleanedHaxeInMultiLineComment) {
                    if (cc == '*/') {
                        cleanedHaxeInMultiLineComment = false;
                        cleanedHaxe += '  ';
                        i += 2;
                    } else {
                        cleanedHaxe += ' ';
                        i++;
                    }
                }
                else if (cc == '//') {
                    cleanedHaxeInSingleLineComment = true;
                    cleanedHaxe += '  ';
                    i += 2;
                }
                else if (cc == '/*') {
                    cleanedHaxeInMultiLineComment = true;
                    cleanedHaxe += '  ';
                    i += 2;
                }
                else if (c == '"' || c == '\'') {
                    if (!RE_STRING.match(after)) {
                        fail('Failed to parse string');
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

        function computeLastSeparator() {

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
            cleanedAfter = cleanedJava.substr(i);

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
                // Java cannot infer types, that's why we see Object[] at various places in the code.
                // But Haxe can, so let's just remove the explicit type and let the compiler find it :)
                case 'Object[]': '';

                case 'float': 'Float';
                case 'float[]': 'FloatArray';
                case 'float[][]': 'FloatArray2D';
                case 'Array<FloatArray>': 'FloatArray2D';
                case 'String[]': 'StringArray';
                case 'short[]': 'ShortArray';
                case 'Array<ShortArray>': 'ShortArray2D';
                case 'short': 'Short';
                case 'Event[]': 'Array<Event>';
                case 'int': 'Int';
                case 'int[]': 'IntArray';
                case 'int[][]': 'IntArray2D';
                case 'Array<IntArray>': 'IntArray2D';
                case 'void': 'Void';
                case 'boolean': 'Bool';
                case 'Object': 'Dynamic';
                case 'boolean[]': 'BooleanArray';
                case 'Array': 'Array<Dynamic>';
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

        function convertDeclExtras(inExtras:String):{interfaces:Array<String>, classes:Array<String>} {

            var extras = {
                interfaces: [],
                classes: []
            };

            if (inExtras != null) {

                var inImplements = false;
                var inExtends = false;

                inExtras = inExtras.trim();
                for (item in inExtras.replace("\t", ' ').replace(",", ' ').split(' ')) {
                    item = item.trim();
                    if (item != '') {
                        if (item == 'implements') {
                            inImplements = true;
                            inExtends = false;
                        }
                        else if (item == 'extends') {
                            inImplements = false;
                            inExtends = true;
                        }
                        else {
                            if (inImplements) {
                                extras.interfaces.push(item);
                            }
                            else if (inExtends) {
                                extras.classes.push(item);
                            }
                        }
                    }
                }
            }

            return extras;

        } //convertDeclExtras

        function consumeCommentOrString(loop:Bool = false):Bool {

            if (loop) {
                do {
                    consumeCommentOrString();
                } while (i < len && (inSingleLineComment || inMultiLineComment));
                return false;
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
                    fail('Failed to parse string');
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
                if (inSubClass && openBraces == beforeSubClassBraces) {
                    inSubClass = false;
                    ctx.types.set(rootType.substring(0, rootType.lastIndexOf('.')) + '.' + inSubClassInfo.name, inSubClassInfo);
                    if (!subClassHasConstructor) {
                        haxe = haxe.substring(0, haxe.length - 1);
                        cleanedHaxe = cleanedHaxe.substring(0, haxe.length);
                        haxe += "\n\t\t" + 'public function new() {}\n\t}';
                    }
                    var added:Map<String,Bool> = new Map();
                    var parentInfo:TypeInfo = ctx.types.get(inSubClassInfo.parent);
                    while (parentInfo != null) {
                        for (name in parentInfo.properties.keys()) {
                            var prop = parentInfo.properties.get(name);
                            if (!added.exists(name) && prop.modifiers.indexOf('static') != -1 && prop.modifiers.indexOf('inline') != -1) {
                                added.set(name, true);
                                haxe = haxe.substring(0, haxe.length - 1);
                                cleanedHaxe = cleanedHaxe.substring(0, haxe.length);
                                haxe += "\n\t\t" + prop.modifiers.join(' ') + ' var ' + name + ':' + prop.type + ' = ' + parentInfo.name + '.' + name + ';\n\t}';
                            }
                        }
                        parentInfo = parentInfo.parent != null ? ctx.types.get(parentInfo.parent) : null;
                    }
                }
                if (inInterface && openBraces == beforeInterfaceBraces) {
                    inInterface = false;
                    ctx.types.set(rootType.substring(0, rootType.lastIndexOf('.')) + '.' + inInterfaceInfo.name, inInterfaceInfo);
                }
                if (inEnum && openBraces == beforeEnumBraces) {

                    ctx.enums.set(inEnumName, {
                        rootType: rootType,
                        values: inEnumValues
                    });

                    inEnum = false;
                    extraHaxe += "\n";
                    extraHaxe += 'class ' + inEnumName + '_enum {\n\n';
                    var n = 0;
                    for (val in inEnumValues) {
                        extraHaxe += '    public inline static var ' + val + '_value = ' + n + ';\n';
                        n++;
                    }
                    extraHaxe += '\n';
                    n = 0;
                    for (val in inEnumValues) {
                        extraHaxe += '    public inline static var ' + val + '_name = "' + val + '";\n';
                        n++;
                    }
                    extraHaxe += '\n';
                    extraHaxe += '    public inline static function valueOf(value:String):' + inEnumName + ' {\n';
                    extraHaxe += '        return switch (value) {\n';
                    n = 0;
                    for (val in inEnumValues) {
                        extraHaxe += '            case "' + val + '": ' + inEnumName + '.' + val + ';\n';
                        n++;
                    }
                    extraHaxe += '            default: ' + inEnumName + '.' + inEnumValues[0] + ';\n';
                    extraHaxe += '        };\n';
                    extraHaxe += '    }\n';

                    extraHaxe += '\n}\n';

                }
                if (inClass && openBraces == beforeClassBraces) {
                    inClass = false;
                    ctx.types.set(rootType, inClassInfo);
                    if (!classHasConstructor) {
                        haxe = haxe.substring(0, haxe.length - 1);
                        cleanedHaxe = cleanedHaxe.substring(0, haxe.length);
                        haxe += "\n\t" + 'public function new() {}\n}';
                    }
                    var added:Map<String,Bool> = new Map();
                    var parentInfo:TypeInfo = ctx.types.get(inClassInfo.parent);
                    while (parentInfo != null) {
                        for (name in parentInfo.properties.keys()) {
                            var prop = parentInfo.properties.get(name);
                            if (!added.exists(name) && prop.modifiers.indexOf('static') != -1 && prop.modifiers.indexOf('inline') != -1) {
                                added.set(name, true);
                                haxe = haxe.substring(0, haxe.length - 1);
                                cleanedHaxe = cleanedHaxe.substring(0, haxe.length);
                                haxe += "\n\t" + prop.modifiers.join(' ') + ' var ' + name + ':' + prop.type + ' = ' + parentInfo.name + '.' + name + ';\n}';
                            }
                        }
                        parentInfo = parentInfo.parent != null ? ctx.types.get(parentInfo.parent) : null;
                    }
                }
                if (inMethod && openBraces == beforeMethodBraces) {
                    if (skippedNames.exists(inMethodName) || inSkippedMethod) {
                        haxe += '*/';
                    }
                    inMethod = false;
                    inSkippedMethod = false;
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
                haxe += c;
                i++;
            }
            else {
                return false;
            }

            return true;

        } //consumeParen

        function consumeBracket():Bool {

            if (c == '[') {
                openBrackets++;
                haxe += c;
                i++;
            }
            else if (c == ']') {
                openBrackets--;
                haxe += c;
                i++;
            }
            else {
                return false;
            }

            return true;

        } //consumeBracket

        function toTypePath(inType:String):String {

            if (rootType.endsWith('.' + inType)) {
                return rootType;
            }
            else {
                for (key in importedTypes.keys()) {
                    if (key.endsWith('.' + inType)) {
                        return key;
                    }
                }
            }

            return rootType.substring(0, rootType.lastIndexOf('.')) + '.' + inType;

        } //toTypePath

        consumeExpression = function(?options:{
            ?varType:String,
            ?varModifiers:Array<String>,
            ?isVarValue:Bool,
            ?inProperties:Bool,
            ?until:String,
            ?untilWords:Array<String>
        }):String {

            var openBracesStart = openBraces;
            var openParensStart = openParens;
            var openBracketsStart = openBrackets;
            var stopToken = '';
            var varType = options != null ? options.varType : null;
            var varModifiers = options != null ? options.varModifiers : null;
            var isVarValue:Bool = options != null ? options.isVarValue : false;
            var until:String = options != null ? options.until : '';
            var untilWords:Array<String> = options != null ? options.untilWords : null;
            var endOfExpression:Array<String> = [];
            var inProperties = options.inProperties != null ? options.inProperties : false;

            while (i < len) {

                nextIteration();

                if (c == ';') {
                    varType = null;
                    varModifiers = null;
                    inProperties = false;
                }

                if (consumeCommentOrString()) {
                    // Nothing to do
                }
                else if (consumeBrace()) {
                    if (openBraces < openBracesStart && until.indexOf('}') != -1) {
                        stopToken = '}';
                        break;
                    }
                }
                else if (c == '(' && RE_CAST.match(after)) {
                    var castType = convertType(RE_CAST.matched(1));

                    if (castType == 'Int') {
                        haxe += 'Std.int(' + RE_CAST.matched(2).ltrim();
                    } else {
                        haxe += 'cast(' + RE_CAST.matched(2).ltrim();
                    }
                    i += RE_CAST.matched(0).length;

                    var index = haxe.length;
                    var aStop = consumeExpression({ until: ');,' });
                    var castPart = haxe.substring(index, haxe.length - 1);

                    if (aStop == ')') openParens++;
                    i--;
                    haxe = haxe.substring(0, index);
                    cleanedHaxe = cleanedHaxe.substring(0, haxe.length);

                    if (castType == 'Int') {
                        haxe += castPart + ')';
                    } else {
                        haxe += castPart + ', ' + castType + ')';
                    }

                    /*if (aStop == ';') {
                        varType = null;
                        isVarValue = false;
                    }

                    if (aStop == ';' && until.indexOf(';') != -1 && openBraces == openBracesStart && openParens == openParensStart) {
                        stopToken = ';';
                        break;
                    }*/
                }
                else if (consumeParen()) {
                    if (isVarValue && openParens > openParensStart) {
                        consumeExpression({ until: ')' });
                    }
                    else if (openParens < openParensStart && openBraces == openBracesStart && until.indexOf(')') != -1) {
                        stopToken = ')';
                        break;
                    }
                }
                else if (consumeBracket()) {
                    if (openBrackets < openBracketsStart && until.indexOf(']') != -1) {
                        stopToken = ']';
                        break;
                    }
                }
                else if (c == ';' && until.indexOf(';') != -1 && openBraces == openBracesStart && openParens == openParensStart) {
                    varType = null;
                    varModifiers = null;
                    inProperties = false;
                    haxe += c;
                    i++;
                    stopToken = c;
                    break;
                }
                else if (isVarValue && (c == ',' || c == ';') && openParens == openParensStart) {
                    isVarValue = false;
                    haxe += ';';

                    i++;
                    if (c == ';') {
                        varType = null;
                        varModifiers = null;
                        inProperties = false;
                    }

                    if (until.indexOf(c) != -1) {
                        stopToken = c;
                        break;
                    }
                }
                else if ((c == ',' || c == ';') && openParens == openParensStart) {
                    haxe += c;
                    i++;
                    if (until.indexOf(c) != -1) {
                        stopToken = c;
                        break;
                    }
                }
                else if (word != '') {
                    if (wordReplaces.exists(word)) {
                        i += word.length;
                        haxe += wordReplaces.get(word);
                    }
                    else if (RE_NUMBER.match(after)) {
                        i += RE_NUMBER.matched(0).length;
                        haxe += RE_NUMBER.matched(1);
                    }
                    else if (RE_LABEL.match(after) && haxe.indexOf('case ', cast Math.max(0, haxe.lastIndexOf("\n"))) == -1) {
                        i += RE_LABEL.matched(0).length;
                        var flagName = '_gotoLabel_' + RE_LABEL.matched(1);
                        haxe += 'var ' + flagName + ':Int; while (true) { ' + flagName + ' = 0; ';
                        endOfExpression.unshift('if (' + flagName + ' == 0) break; }');
                        continueToLabels.unshift({
                            breakCode: 'if (' + flagName + ' >= 1) break',
                            continueCode: 'if (' + flagName + ' == 2) continue',
                            depth: 0
                        });
                    }
                    else if (RE_PARENT_CLASS_THIS.match(after)) {
                        i += RE_PARENT_CLASS_THIS.matched(0).length;
                        haxe += RE_PARENT_CLASS_THIS.matched(1) + '_this.';
                    }
                    else if (RE_CALL.match(after) && !controls.exists(RE_CALL.matched(1))) {
                        i += RE_CALL.matched(0).length;
                        haxe += RE_CALL.matched(0);
                        openParens++;
                        inCall = true;
                        consumeExpression({ until: ')' });
                        inCall = false;
                    }
                    else if (untilWords != null && untilWords.indexOf(word) != -1) {
                        stopToken = word;
                        break;
                    }
                    else if (word == 'catch' && RE_CATCH.match(after)) {
                        i += RE_CATCH.matched(0).length;
                        haxe += 'catch (' + RE_CATCH.matched(2) + ':Dynamic)';
                    }
                    else if (word == 'switch' && RE_SWITCH.match(after)) {

                        loopStack.push({
                            control: 'switch',
                            label: null
                        });

                        openParens++;
                        i += RE_SWITCH.matched(0).length;
                        var switchIndex = nextSwitchIndex++;
                        var continueAfterName = '_continueAfterSwitch' + switchIndex;
                        var switchCondName = '_switchCond' + switchIndex;
                        haxe += 'var ' + continueAfterName + ' = false; ';
                        haxe += 'while(true) { var ' + switchCondName + ' = (';

                        consumeExpression({ until: ')' });
                        haxe += ';';

                        // Until `{`
                        consumeCommentOrString(true);
                        c = java.charAt(i);
                        while (i < len && c.trim() == '') {
                            haxe += c;
                            i++;
                            c = java.charAt(i);
                        }

                        if (c != '{') {
                            fail('Failed to parse switch');
                        }

                        i++;
                        haxe += '{';
                        openBraces++;

                        var startIndex = haxe.length;
                        consumeExpression({ until: '}' });
                        var switchContent = haxe.substring(startIndex, haxe.length - 1);
                        haxe = haxe.substring(0, startIndex);
                        cleanedHaxe = cleanedHaxe.substring(0, haxe.length);

                        var parts = splitCode(' ' + switchContent, ['case', 'default']);

                        haxe += parts[0].substring(1);
                        parts.shift();

                        var cases:Array<{
                            caseVal:String,
                            fallThrough:Bool,
                            body:String
                        }> = [];

                        for (part in parts) {
                            if (!RE_CASE.match(part)) {
                                fail('Failed to parse switch case');
                            }
                            var caseVal = RE_CASE.matched(2);
                            if (caseVal == null || caseVal == '') caseVal = 'default';
                            //caseVal = caseVal.substring(5, caseVal.length - 1);
                            cases.push({
                                caseVal: caseVal,
                                body: part.substring(RE_CASE.matched(0).length),
                                fallThrough: true
                            });
                        }

                        var hasContinues = false;
                        function convertContinues(code) {
                            var parts = splitCode(code, ['continue'], true);
                            var n = 0;
                            var newCode = parts[n++];
                            while (n < parts.length) {
                                var part = parts[n];
                                var breakCode = '';
                                if (RE_CONTINUE.match(part)) {

                                    hasContinues = true;
                                    breakCode += continueAfterName + ' = true; break;';

                                    if (breakCode.split(';').length > 2) {
                                        breakCode = '{ ' + breakCode + ' }';
                                    }

                                    breakCode += part.substring(RE_CONTINUE.matched(0).length);
                                    newCode += breakCode;
                                }
                                else {
                                    fail('Failed to parse continue');
                                }
                                n++;
                            }
                            return newCode;
                        }

                        for (aCase in cases) {
                            aCase.body = convertContinues(aCase.body);
                            var cleaned = cleanedCode(aCase.body, { cleanSpaces: true }).trim();
                            var hasBrace = cleaned.startsWith('{');
                            if (RE_CASE_BREAKS.match(cleaned)) {
                                if (RE_CASE_BREAKS.matched(4) != null && RE_CASE_BREAKS.matched(4).trim() == '}') {
                                    aCase.fallThrough = !hasBrace;
                                }
                                else {
                                    aCase.fallThrough = false;
                                }
                            }
                        }

                        var n = 0;
                        for (aCase in cases) {
                            if (aCase.caseVal != 'default') {
                                if (n > 0) haxe += 'else ';
                                haxe += 'if (' + switchCondName + ' == ' + aCase.caseVal + ') ';
                            } else {
                                haxe += 'else ';
                            }
                            var hasBrace = aCase.body.ltrim().startsWith('{');
                            if (!hasBrace) {
                                haxe += '{';
                                var lastLine = haxe.substring(haxe.lastIndexOf("\n") + 1);
                                var indent = lastLine.substring(0, lastLine.length - lastLine.ltrim().length);
                                haxe += "\n" + indent + "\t";
                            }
                            haxe += aCase.body;
                            if (aCase.fallThrough) {
                                var m = 1;
                                while (n + m < cases.length) {
                                    var nextCase = cases[n + m];
                                    var nextHasBrace = nextCase.body.ltrim().startsWith('{');
                                    if (hasBrace) {
                                        var caseEnd = haxe.substring(haxe.lastIndexOf('}'));
                                        haxe = haxe.substring(0, haxe.lastIndexOf('}'));
                                        haxe += nextCase.body;
                                        haxe += caseEnd;
                                    } else if (nextHasBrace) {
                                        haxe += nextCase.body;
                                    } else {
                                        haxe += '    ' + nextCase.body;
                                    }
                                    if (!nextCase.fallThrough) break;
                                    m++;
                                }
                            }
                            if (!hasBrace) haxe += '} ';
                            n++;
                        }

                        haxe += '} break; }';

                        if (hasContinues) {
                            haxe += ' if (' + continueAfterName + ') continue;';
                        }

                        loopStack.pop();

                    }
                    else if (word == 'new') {
                        if (RE_NEW_INSTANCE.match(after)) {
                            
                            openParens++;
                            i += RE_NEW_INSTANCE.matched(0).length;

                            var typeName = RE_NEW_INSTANCE.matched(1);
                            var trailingParen = RE_NEW_INSTANCE.matched(2);
                            if (trailingParen != null && trailingParen.trim() != '') {
                                openParens--;
                            }
                            if (contextualClasses.exists(rootType + '.' + typeName) && trailingParen != null && trailingParen.trim() != '') {
                                haxe += 'null';
                            }
                            else if (inlineClassDefs.exists(rootType + '.' + typeName)) {
                                var replaces = inlineClassDefs.get(rootType + '.' + typeName);
                                haxe += 'new ' + replaces.replaceWithClass + '(';
                                if (trailingParen != null) {
                                    haxe += trailingParen;
                                }
                                else {
                                    consumeExpression({ until: ')' });
                                }
                                var startIndex = haxe.length;
                                c = cleanedJava.charAt(i);
                                while (i < len && c != '{') {
                                    i++;
                                    c = cleanedJava.charAt(i);
                                }
                                i++;
                                openBraces++;
                                consumeExpression({ until: '}' });
                                i++;
                                haxe = haxe.substring(0, startIndex);
                                cleanedHaxe = cleanedHaxe.substring(0, haxe.length);
                                haxe += ';';

                                if (until.indexOf(';') != -1) {
                                    stopToken = ';';
                                    break;
                                }
                            }
                            else {
                                haxe += RE_NEW_INSTANCE.matched(0);
                            }

                        }
                        else if (RE_NEW_ARRAY.match(after)) {

                            openBrackets++;
                            i += RE_NEW_ARRAY.matched(0).length;
                            
                            var arrayType = RE_NEW_ARRAY.matched(1).charAt(0).toUpperCase() + RE_NEW_ARRAY.matched(1).substring(1);
                            var index = haxe.length;
                            var part1:String = '';
                            var part2:String = null;
                            consumeExpression({ until: ']' });
                            part1 = haxe.substring(index, haxe.length - 1);
                            haxe = haxe.substring(0, index);
                            cleanedHaxe = cleanedHaxe.substring(0, cast Math.min(cleanedHaxe.length, haxe.length));
                            c = java.charAt(i);
                            while (c.trim() == '') {
                                haxe += c;
                                i++;
                                c = java.charAt(i);
                            }

                            if (c == '[') {
                                i++;
                                openBrackets++;
                                index = haxe.length;
                                consumeExpression({ until: ']' });
                                part2 = haxe.substring(index, haxe.length - 1);
                                haxe = haxe.substring(0, index);
                                cleanedHaxe = cleanedHaxe.substring(0, cast Math.min(cleanedHaxe.length, haxe.length));
                            }

                            if (part1 == '') part1 = '0';
                            if (part2 != null) {
                                if (part2 == '') part2 = '0';
                                haxe += 'Array.create' + arrayType + 'Array2D(' + part1 + ', ' + part2 + ')';
                            }
                            else {
                                if (arrayType == 'Float' || arrayType == 'Short' || arrayType == 'String' || arrayType == 'Int' || arrayType == 'Boolean') {
                                    haxe += arrayType + 'Array.create(' + part1 + ')';
                                }
                                else {
                                    haxe += 'Array.create(' + part1 + ')';
                                }
                            }
                        }
                        else {
                            i += word.length;
                            haxe += word;
                        }
                    }
                    else if (word == 'if' && cleanedAfter.substr(word.length).ltrim().startsWith('(')) {

                        var javaBefore = cleanedJava.substring(0, i);
                        var labelName = null;
                        if (RE_LABEL_BEFORE.match(javaBefore)) {
                            labelName = RE_LABEL_BEFORE.matched(1);
                        }

                        i += word.length;
                        haxe += word;
                        c = cleanedJava.charAt(i);
                        while (c != '(') {
                            i++;
                            haxe += c;
                            c = cleanedJava.charAt(i);
                        }
                        haxe += '(';
                        i++;
                        openParens++;

                        consumeExpression({ until: ')' });

                        // Is the rest inline?
                        var isInline = false;
                        var n = i;
                        var nc = cleanedJava.charAt(n);
                        while (n < len && nc != ';' && nc != '{') {
                            n++;
                            nc = cleanedJava.charAt(n);
                        }
                        if (nc == ';') isInline = true;

                        if (isInline) {
                            consumeExpression({ until: ';' });
                            i--;
                            haxe = haxe.substring(0, haxe.length-1);
                            cleanedHaxe = cleanedHaxe.substring(0, haxe.length);
                        }
                        else {
                            i = n + 1;
                            openBraces++;
                            haxe += ' {';
                            consumeExpression({ until: '}' });
                        }

                        // Handle labeled if
                        if (labelName != null && !isInline) {

                            while (RE_ELSE.match(cleanedJava.substring(i))) {

                                haxe += java.substring(i, i + RE_ELSE.matched(1).length);
                                i += RE_ELSE.matched(1).length;
                                haxe += 'else';
                                i += 4;

                                var ifPart = RE_ELSE.matched(2);
                                // Else followed by if (else if)
                                if (ifPart != null && ifPart.trim() != '') {
                                    haxe += RE_ELSE.matched(3) + '(';
                                    i += RE_ELSE.matched(3).length + 1;
                                    openParens++;
                                    consumeExpression({ until: ')' });
                                }

                                // Is the rest inline?
                                var isInline = false;
                                var n = i;
                                var nc = cleanedJava.charAt(n);
                                while (n < len && nc != ';' && nc != '{') {
                                    n++;
                                    nc = cleanedJava.charAt(n);
                                }
                                if (nc == ';') isInline = true;

                                if (isInline) {
                                    consumeExpression({ until: ';' });
                                    i--;
                                    haxe = haxe.substring(0, haxe.length-1);
                                    cleanedHaxe = cleanedHaxe.substring(0, haxe.length);
                                }
                                else {
                                    i = n + 1;
                                    openBraces++;
                                    haxe += ' {';
                                    consumeExpression({ until: '}' });
                                }
                            }

                            // Add label end of expression
                            var expr = endOfExpression.shift();
                            haxe += ' ' + expr;
                            continueToLabels.shift();

                        }

                    }
                    else if (word == 'do' && cleanedAfter.substr(word.length).ltrim().startsWith('{')) {

                        i += word.length;
                        c = cleanedJava.charAt(i);
                        while (c != '{') {
                            i++;
                            c = cleanedJava.charAt(i);
                        }
                        i++;
                        openBraces++;

                        haxe += 'do {';

                        consumeExpression({ until: '}' });

                        c = cleanedJava.charAt(i);
                        while (i < len && c != '(') {
                            haxe += c;
                            i++;
                            c = cleanedJava.charAt(i);
                        }
                        openParens++;
                        i++;
                        haxe += c;

                        consumeExpression({ until: ')' });
                        
                        haxe += ';';
                        i++;

                        if (continueToLabels.length > 0) {

                            for (item in continueToLabels) {
                                item.depth++;
                            }

                            cleanedHaxe = cleanedHaxe.substring(0, haxe.length);

                            for (item in continueToLabels) {
                                if (item.depth > 1) {
                                    haxe += ' ' + item.breakCode + ';';
                                }
                                else {
                                    haxe += ' ' + item.continueCode + ';';
                                    haxe += ' ' + item.breakCode + ';';
                                }
                                item.depth--;
                            }

                        }

                    }
                    else if (word == 'while' && cleanedAfter.substr(word.length).ltrim().startsWith('(')) {

                        loopStack.push({
                            control: 'while',
                            label: null
                        });

                        var javaBefore = cleanedJava.substring(0, i);
                        var labelName = null;
                        if (RE_LABEL_BEFORE.match(javaBefore)) {
                            labelName = RE_LABEL_BEFORE.matched(1);
                            loopStack[loopStack.length - 1].label = labelName;
                        }

                        i += word.length;
                        c = cleanedJava.charAt(i);
                        while (c != '(') {
                            i++;
                            c = cleanedJava.charAt(i);
                        }
                        i++;
                        openParens++;
                        haxe += 'while (';

                        consumeExpression({ until: ')' });

                        // Is the rest inline?
                        var isInline = false;
                        var n = i;
                        var nc = cleanedJava.charAt(n);
                        while (n < len && nc != ';' && nc != '{') {
                            n++;
                            nc = cleanedJava.charAt(n);
                        }
                        if (nc == ';') isInline = true;

                        for (item in continueToLabels) {
                            item.depth++;
                        }

                        if (isInline) {
                            haxe += ' {';
                            consumeExpression({ until: ';' });
                            haxe += ' }';
                        }
                        else {
                            i = n + 1;
                            openBraces++;
                            haxe += ' {';
                            consumeExpression({ until: '}' });
                        }

                        if (labelName != null) {
                            // Add label end of expression
                            var expr = endOfExpression.shift();
                            haxe += ' ' + expr;
                            continueToLabels.shift();
                        }

                        for (item in continueToLabels) {
                            if (item.depth > 1) {
                                haxe += ' ' + item.breakCode + ';';
                            }
                            else {
                                haxe += ' ' + item.continueCode + ';';
                                haxe += ' ' + item.breakCode + ';';
                            }
                            item.depth--;
                        }

                        loopStack.pop();

                    }
                    else if (word == 'for' && cleanedAfter.substr(word.length).ltrim().startsWith('(')) {

                        loopStack.push({
                            control: 'switch',
                            label: null
                        });

                        var javaBefore = cleanedJava.substring(0, i);
                        var labelName = null;
                        if (RE_LABEL_BEFORE.match(javaBefore)) {
                            labelName = RE_LABEL_BEFORE.matched(1);
                            loopStack[loopStack.length - 1].label = labelName;
                        }

                        if (RE_FOREACH.match(cleanedAfter)) {
                            // For each (for (A a : B) ...)
                            i += RE_FOREACH.matched(0).length;
                            haxe += 'for (' + RE_FOREACH.matched(2) + ' in';
                            openParens++;
                            consumeExpression({ until: ')' });

                            // Is the rest inline?
                            var isInline = false;
                            var n = i;
                            var nc = cleanedJava.charAt(n);
                            while (n < len && nc != ';' && nc != '{') {
                                n++;
                                nc = cleanedJava.charAt(n);
                            }
                            if (nc == ';') isInline = true;

                            for (item in continueToLabels) {
                                item.depth++;
                            }

                            if (isInline) {
                                haxe += ' {';
                                consumeExpression({ until: ';' });
                                haxe += ' ';
                            }
                            else {
                                i = n + 1;
                                openBraces++;
                                haxe += ' {';
                                consumeExpression({ until: '}' });
                                haxe = haxe.substring(0, haxe.length - 1);
                                cleanedHaxe = cleanedHaxe.substring(0, haxe.length);
                            }

                            haxe += '}';

                            var itemIndex = 0;
                            var stackLen = loopStack.length;
                            for (item in loopStack) {
                                if (item.label != null) {
                                    if (itemIndex == stackLen - 2) {
                                        haxe += ' if (_gotoLabel_' + item.label + ' == 2) { _gotoLabel_' + item.label + ' = 0; continue; }';
                                    } else if (itemIndex < stackLen - 2) {
                                        haxe += ' if (_gotoLabel_' + item.label + ' == 2) break;';
                                    }
                                }
                                itemIndex++;
                            }

                            if (labelName != null) {
                                // Add label end of expression
                                var expr = endOfExpression.shift();
                                haxe += ' ' + expr;
                                continueToLabels.shift();
                            }

                            for (item in continueToLabels) {
                                if (item.depth > 1) {
                                    haxe += ' ' + item.breakCode + ';';
                                }
                                else {
                                    haxe += ' ' + item.continueCode + ';';
                                    haxe += ' ' + item.breakCode + ';';
                                }
                                item.depth--;
                            }
                            
                        }
                        else {
                            i += word.length;
                            c = cleanedJava.charAt(i);
                            while (c != '(') {
                                i++;
                                c = cleanedJava.charAt(i);
                            }
                            i++;
                            openParens++;

                            // For init
                            var startIndex = haxe.length;
                            inFor = true;
                            consumeExpression({ until: ';' });
                            inFor = false;
                            var forInit = haxe.substring(startIndex, haxe.length - 1).trim().replace(',',';');
                            haxe = haxe.substring(0, startIndex);
                            cleanedHaxe = cleanedHaxe.substring(0, haxe.length);

                            // For condition
                            startIndex = haxe.length;
                            inFor = true;
                            consumeExpression({ until: ';' });
                            inFor = false;
                            var forCondition = haxe.substring(startIndex, haxe.length - 1).trim().replace(',',';');
                            haxe = haxe.substring(0, startIndex);
                            cleanedHaxe = cleanedHaxe.substring(0, haxe.length);
                            if (forCondition.trim() == '') forCondition = 'true';

                            // For increment
                            startIndex = haxe.length;
                            inFor = true;
                            consumeExpression({ until: ')' });
                            inFor = false;
                            var forIncrement = haxe.substring(startIndex, haxe.length - 1).trim().replace(',',';');
                            haxe = haxe.substring(0, startIndex);
                            cleanedHaxe = cleanedHaxe.substring(0, haxe.length);

                            var isInline = false;
                            var n = i;
                            var nc = cleanedJava.charAt(n);
                            while (n < len && nc != ';' && nc != '{') {
                                n++;
                                nc = cleanedJava.charAt(n);
                            }
                            if (nc == ';') isInline = true;

                            for (item in continueToLabels) {
                                item.depth++;
                            }

                            function convertContinuesAndBreaks() {
                                var code = haxe.substring(startIndex, haxe.length);
                                var parts = splitCode(code, ['continue', 'break'], true);
                                var n = 0;
                                var newCode = parts[n++];
                                while (n < parts.length) {
                                    var part = parts[n];
                                    var breakCode = '';
                                    if (forIncrement != null && part.startsWith('continue')) {
                                        breakCode += forIncrement + '; ';
                                    }
                                    if (RE_CONTINUE_OR_BREAK.match(part)) {

                                        var label = RE_CONTINUE_OR_BREAK.matched(2);
                                        if (label != null && label.trim() != '') {
                                            var flag = part.startsWith('continue') ? '2' : '1';
                                            breakCode += '_gotoLabel_' + RE_CONTINUE_OR_BREAK.matched(2) + ' = ' + flag + '; break;';
                                        }
                                        else {
                                            breakCode += RE_CONTINUE_OR_BREAK.matched(0).replace('continue', '__CONTINUE__');
                                        }

                                        if (breakCode.split(';').length > 2) {
                                            breakCode = '{ ' + breakCode + ' }';
                                        }

                                        breakCode += part.substring(RE_CONTINUE_OR_BREAK.matched(0).length);
                                        newCode += breakCode;
                                    }
                                    else {
                                        fail('Failed to parse continue');
                                    }
                                    n++;
                                }
                                haxe = haxe.substring(0, startIndex);
                                cleanedHaxe = haxe.substring(0, haxe.length);
                                haxe += newCode;
                            }

                            if (forInit.trim() != '') haxe += forInit + '; ';
                            haxe += 'while (' + forCondition + ')';
                            if (isInline) {
                                haxe += ' {';
                                startIndex = haxe.length;
                                consumeExpression({ until: ';' });
                                convertContinuesAndBreaks();
                                if (forIncrement.trim() != '') haxe += ' ' + forIncrement + ';';
                                haxe += ' }';
                            }
                            else {
                                i = n + 1;
                                openBraces++;
                                haxe += ' {';
                                startIndex = haxe.length;
                                consumeExpression({ until: '}' });
                                convertContinuesAndBreaks();
                                haxe = haxe.substring(0, haxe.length - 1);
                                cleanedHaxe = cleanedHaxe.substring(0, haxe.length);
                                if (forIncrement.trim() != '') {
                                    haxe += forIncrement + '; ';
                                }
                                haxe += '}';
                            }

                            var itemIndex = 0;
                            var stackLen = loopStack.length;
                            for (item in loopStack) {
                                if (item.label != null) {
                                    if (itemIndex == stackLen - 2) {
                                        haxe += ' if (_gotoLabel_' + item.label + ' == 2) { _gotoLabel_' + item.label + ' = 0; continue; }';
                                    } else if (itemIndex < stackLen - 2) {
                                        haxe += ' if (_gotoLabel_' + item.label + ' == 2) break;';
                                    }
                                }
                                itemIndex++;
                            }

                            if (labelName != null) {
                                // Add label end of expression
                                var expr = endOfExpression.shift();
                                haxe += ' ' + expr;
                                continueToLabels.shift();
                            }

                            for (item in continueToLabels) {
                                if (item.depth > 1) {
                                    haxe += ' ' + item.breakCode + ';';
                                }
                                else {
                                    haxe += ' ' + item.continueCode + ';';
                                    haxe += ' ' + item.breakCode + ';';
                                }
                                item.depth--;
                            }
                        }

                        loopStack.pop();

                    }
                    else if (controls.exists(word)) {
                        haxe += word;
                        i += word.length;
                    }
                    else if (RE_INSTANCEOF.match(after)) {
                        haxe += 'Std.is(' + RE_INSTANCEOF.matched(1) + ', ' + convertType(RE_INSTANCEOF.matched(2)) + ')';
                        i += RE_INSTANCEOF.matched(0).length;
                    }
                    else if (!controls.exists(word) && !inCall && (lastSeparator == '' || lastSeparator == ':' || lastSeparator == ';' || lastSeparator == '{' || lastSeparator == '}' || lastSeparator == ')' || inFor) && RE_VAR.match(after)) {
                        var type = null;
                        if (RE_VAR.matched(1) != null) {
                            type = convertType(RE_VAR.matched(1));
                        }
                        var skip = false;
                        if (type == null) {
                            if ((lastSeparator == ',' || lastSeparator == ';') && varType != null) {
                                type = varType;
                            }
                            else {
                                haxe += word;
                                i += word.length;
                                skip = true;
                            }
                        }
                        if (!skip) {
                            var name = RE_VAR.matched(2);

                            if (inProperties) {
                                if (inSubClass) {
                                    inSubClassInfo.properties.set(name, {
                                        modifiers: varModifiers != null ? varModifiers : [],
                                        type: type
                                    });
                                }
                                else if (inClass) {
                                    inClassInfo.properties.set(name, {
                                        modifiers: varModifiers != null ? varModifiers : [],
                                        type: type
                                    });
                                }
                            }

                            if (varType != null && varModifiers != null && varModifiers.length > 0) {
                                haxe += varModifiers.join(' ') + ' ';
                            }

                            haxe += 'var ' + name;
                            if (type != null && type != '') {
                                haxe += ':' + type;
                            }

                            var end = RE_VAR.matched(3);
                            if (end == ',' || end == ';') {
                                if (type == 'Float' || type == 'Int' || type == 'Short') {
                                    haxe += ' = 0';
                                }
                                else if (type == 'Bool') {
                                    haxe += ' = false';
                                }
                                else {
                                    haxe += ' = null';
                                }
                            }
                            if (end == ';') {
                                haxe += ';';
                                varType = null;
                                inProperties = false;
                                varModifiers = null;
                                isVarValue = false;
                            }
                            else if (end == '=') {
                                haxe += ' =';
                                varType = type;
                                isVarValue = true;
                            }
                            else if (end == ',') {
                                haxe += ';';
                                varType = type;
                                isVarValue = false;
                            }

                            i += RE_VAR.matched(0).length;

                            if (end == ';' && until.indexOf(';') != -1 && openBraces == openBracesStart && openParens == openParensStart) {
                                stopToken = ';';
                                break;
                            }
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
                }
                else {
                    haxe += c;
                    i++;
                }
            }

            if (endOfExpression.length > 0) {
                for (k in 0...endOfExpression.length) {
                    continueToLabels.shift();
                }
                if (stopToken == '}') {
                    if (RE_EXPR_RETURNS.match(haxe)) {
                        haxe = haxe.substring(0, haxe.length - RE_EXPR_RETURNS.matched(0).length);
                        cleanedHaxe = cleanedHaxe.substring(0, haxe.length);
                        haxe += RE_EXPR_RETURNS.matched(1) + ' ' + endOfExpression.join(' ') + ' ' + RE_EXPR_RETURNS.matched(2);
                    } else {
                        haxe = haxe.substring(0, haxe.length - 1);
                        cleanedHaxe = cleanedHaxe.substring(0, haxe.length);
                        haxe += endOfExpression.join(' ') + ' }';
                    }
                }
                else {
                    haxe += ' ' + endOfExpression.join(' ');
                }
            }

            return stopToken;

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
            else if (consumeBracket()) {
                // Nothing to do
            }
            // Method body
            else if (inMethod) {
                consumeExpression({ until: '}' });
            }
            // Class specifics
            else if (inClass || inInterface || inEnum) {
                // Method or property?
                if (word != '') {
                    if (inEnum && RE_ENUM_VALUE.match(cleanedAfter)) {
                        i += RE_ENUM_VALUE.matched(0).length;
                        var name = RE_ENUM_VALUE.matched(1);
                        if (name == 'in') name = 'directionIn';
                        else if (name == 'out') name = 'directionOut';
                        haxe += 'var ' + name + ' = ' + inEnumValues.length;
                        var end = RE_ENUM_VALUE.matched(4);
                        if (end == '}') {
                            haxe += ';' + RE_ENUM_VALUE.matched(3);
                            i--;
                        }
                        else {
                            haxe += RE_ENUM_VALUE.matched(3) + ';';
                        }

                        inEnumValues.push(name);
                    }
                    else if (inClass && RE_DECL.match(after)) {

                        var modifiers = convertModifiers(RE_DECL.matched(1));
                        var name = RE_DECL.matched(3);

                        var keyword = RE_DECL.matched(2);

                        var typeInfo:TypeInfo = {
                            name: name,
                            parent: null,
                            interfaces: new Map(),
                            methods: new Map(),
                            properties: new Map()
                        };

                        if (modifiers.exists('private') && keyword == 'class') {
                            haxe += 'private ';
                        }

                        if (keyword == 'class') {
                            inClass = true;
                            inSubClass = true;
                            inSubClassInfo = typeInfo;
                            subClassHasConstructor = false;
                            beforeSubClassBraces = openBraces;
                            haxe += keyword + ' ';
                        }
                        else if (keyword == 'interface') {
                            inInterface = true;
                            inInterfaceInfo = typeInfo;
                            beforeInterfaceBraces = openBraces;
                            haxe += keyword + ' ';
                        }
                        else if (keyword == 'enum') {
                            inEnum = true;
                            inEnumValues = [];
                            beforeEnumBraces = openBraces;
                            haxe += '@:enum abstract ';
                        }

                        if (keyword == 'enum') {
                            inEnumName = name;
                            haxe += name + '(Int) from Int to Int ';
                        } else {
                            haxe += name + ' ';
                        }

                        var extras = convertDeclExtras(RE_DECL.matched(4));
                        for (item in extras.classes) {
                            typeInfo.parent = toTypePath(item);
                            haxe += 'extends ' + item + ' ';
                        }
                        for (item in extras.interfaces) {
                            typeInfo.interfaces.set(toTypePath(item), true);
                            haxe += 'implements ' + item + ' ';
                        }

                        haxe += '{';

                        for (key in contextualClasses.keys()) {
                            if (key.startsWith(rootType + '.')) {
                                var subType = key.substring(rootType.length + 1);
                                if (subType == name) {
                                    haxe += "\n\t\t";
                                    haxe += 'private var ' + rootType.substring(rootType.lastIndexOf('.') + 1) + '_this:' + rootType.substring(rootType.lastIndexOf('.') + 1) + ';';
                                }
                            }
                        }

                        openBraces++;
                        i += RE_DECL.matched(0).length;
                    }
                    else if (RE_PROPERTY.match(after)) {

                        var varModifiers:Array<String> = [];

                        var name = RE_PROPERTY.matched(3);
                        var type = convertType(RE_PROPERTY.matched(2));

                        if (inSubClass) {
                            inSubClassInfo.properties.set(name, {
                                modifiers: varModifiers != null ? varModifiers : [],
                                type: type
                            });
                        }
                        else if (inClass) {
                            inClassInfo.properties.set(name, {
                                modifiers: varModifiers != null ? varModifiers : [],
                                type: type
                            });
                        }

                        if (inEnum || skippedNames.exists(name)) {
                            haxe += '//';
                        }

                        var modifiers = convertModifiers(RE_PROPERTY.matched(1));
                        
                        var hasAccessModifier = false;
                        if (modifiers.exists('final') && modifiers.exists('static') && name.toUpperCase() == name) {
                            haxe += 'inline ';
                            varModifiers.push('inline');
                        }
                        if (modifiers.exists('public')) {
                            haxe += 'public ';
                            hasAccessModifier = true;
                            varModifiers.push('public');
                        }
                        if (modifiers.exists('protected')) {
                            haxe += 'public ';
                            hasAccessModifier = true;
                            varModifiers.push('public');
                        }
                        if (modifiers.exists('private')) {
                            haxe += 'private ';
                            hasAccessModifier = true;
                            varModifiers.push('private');
                        }
                        if (!hasAccessModifier) {
                            haxe += 'public '; // Default to public
                            varModifiers.push('public');
                        }
                        if (modifiers.exists('static')) {
                            haxe += 'static ';
                            varModifiers.push('static');
                        }

                        haxe += 'var ' + name + ':' + type;
                        i += RE_PROPERTY.matched(0).length;

                        var end = RE_PROPERTY.matched(4);
                        if (end == ',' || end == ';') {
                            if (type == 'Float' || type == 'Int') {
                                haxe += ' = 0';
                            }
                            else if (type == 'Bool') {
                                haxe += ' = false';
                            }
                        }
                        if (end == ';') {
                            haxe += ';';
                        }
                        else if (end == '=') {
                            haxe += ' =';
                            consumeExpression({ until: ';', varType: type, varModifiers: varModifiers, isVarValue: true, inProperties: true });
                        }
                        else if (end == ',') {
                            haxe += ';';
                            consumeExpression({ until: ';', varType: type, varModifiers: varModifiers, inProperties: true});
                        }

                    }
                    else if (RE_CONSTRUCTOR.match(after)) {

                        var skip = false;
                        if (inEnum) {
                            skip = true;
                            haxe += '/*';
                        }
                        if (!skip) {
                            for (key in skippedConstructors.keys()) {
                                var sharpIndex = key.indexOf('#');
                                var cleanKey = key;
                                if (sharpIndex != -1) cleanKey = key.substring(0, sharpIndex);
                                if (cleanKey == rootType && cleanedCode(RE_CONSTRUCTOR.matched(3), { cleanSpaces: true }) == skippedConstructors.get(key)) {
                                    haxe += '/*';
                                    skip = true;
                                    break;
                                }
                            }
                        }

                        inSkippedMethod = skip;

                        if (!skip) {
                            if (inSubClass) {
                                subClassHasConstructor = true;
                            }
                            else if (inClass) {
                                classHasConstructor = true;
                            }
                        }

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
                        inMethodName = 'new';
                        beforeMethodBraces = openBraces;
                        openBraces++;

                        if (inClass && !inSubClass) {
                            for (key in contextualClasses.keys()) {
                                if (key.startsWith(rootType + '.')) {
                                    var subType = key.substring(rootType.length + 1);
                                    haxe += "\n\t\t";
                                    haxe += 'this.' + contextualClasses.get(key) + ' = new ' + subType + '();';
                                    haxe += "\n\t\t";
                                    haxe += '@:privateAccess this.' + contextualClasses.get(key) + '.' + rootType.substring(rootType.lastIndexOf('.') + 1) + '_this = this;';
                                }
                            }
                        }

                    }
                    else if (RE_METHOD.match(after)) {

                        var modifiers = convertModifiers(RE_METHOD.matched(1));
                        var name = RE_METHOD.matched(3);
                        var type = convertType(RE_METHOD.matched(2));
                        var args = convertArgs(RE_METHOD.matched(4));

                        if (skippedNames.exists(name) || inEnum) {
                            inSkippedMethod = true;
                            haxe += '/*';
                        }
                        else {
                            var methodModifiers = [];
                            for (key in modifiers.keys()) {
                                methodModifiers.push(key);
                            }
                            if (inSubClass) {
                                inSubClassInfo.methods.set(name, {
                                    modifiers: methodModifiers,
                                    args: args,
                                    type: type
                                });
                            }
                            else if (inInterface) {
                                inInterfaceInfo.methods.set(name, {
                                    modifiers: methodModifiers,
                                    args: args,
                                    type: type
                                });
                            }
                            else if (inClass) {
                                inClassInfo.methods.set(name, {
                                    modifiers: methodModifiers,
                                    args: args,
                                    type: type
                                });
                            }
                        }

                        if (!inInterface && !noInlineNames.exists(name)) {
                            haxe += '#if !spine_no_inline inline #end ';
                        }
                        
                        var hasAccessModifier = false;
                        if (!inInterface && modifiers.exists('public')) {
                            haxe += 'public ';
                            hasAccessModifier = true;
                        }
                        if (!inInterface && modifiers.exists('protected')) {
                            haxe += 'public ';
                            hasAccessModifier = true;
                        }
                        if (!inInterface && modifiers.exists('private')) {
                            haxe += 'private ';
                            hasAccessModifier = true;
                        }
                        if (modifiers.exists('static')) {
                            haxe += 'static ';
                        }
                        if (!hasAccessModifier) {
                            haxe += 'public '; // Default to public
                        }

                        haxe += 'function ' + name + '(';
                        var parts = [];
                        for (arg in args) {
                            parts.push(arg.name + ':' + arg.type);
                        }
                        haxe += parts.join(', ') + '):' + type + (RE_METHOD.matched(5) == ';' ? ';' : ' {');

                        i += RE_METHOD.matched(0).length;

                        if (RE_METHOD.matched(5) == '{') {
                            inMethod = true;
                            inMethodName = name;
                            beforeMethodBraces = openBraces;
                            openBraces++;
                        }

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
                    fail('Failed to parse import');
                }
                
                // Import replaces
                var pack = RE_IMPORT.matched(2);
                pack = replaceStart(pack, 'com.esotericsoftware.spine.', 'spine.');
                pack = replaceStart(pack, 'com.badlogic.gdx.graphics.g2d', 'spine.support.graphics');
                pack = replaceStart(pack, 'com.badlogic.gdx.', 'spine.support.');
                pack = replaceStart(pack, 'java.util.', 'spine.support.');

                // Compute imported types
                for (key in ctx.types.keys()) {
                    if (key == pack) {
                        importedTypes.set(key, ctx.types.get(key));
                    }
                    else if (key.startsWith(pack + '.')) {
                        importedTypes.set(key, ctx.types.get(key));
                    }
                }

                // Add import
                haxe += 'import ' + pack + ';';
                i += RE_IMPORT.matched(0).length;
            }
            // Class modifiers we don't want to keep
            else if (word != '' && RE_DECL.match(after)) {

                var modifiers = convertModifiers(RE_DECL.matched(1));
                var name = RE_DECL.matched(3);

                var typeInfo:TypeInfo = {
                    name: name,
                    parent: null,
                    interfaces: new Map(),
                    methods: new Map(),
                    properties: new Map()
                };

                var keyword = RE_DECL.matched(2);

                if (modifiers.exists('private') && keyword == 'class') {
                    haxe += 'private ';
                }

                if (keyword == 'class') {
                    inClass = true;
                    inClassInfo = typeInfo;
                    classHasConstructor = false;
                    beforeClassBraces = openBraces;
                    haxe += keyword + ' ';
                }
                else if (keyword == 'interface') {
                    inInterface = true;
                    inInterfaceInfo = typeInfo;
                    beforeInterfaceBraces = openBraces;
                    haxe += keyword + ' ';
                }
                else if (keyword == 'enum') {
                    inEnum = true;
                    inEnumValues = [];
                    beforeEnumBraces = openBraces;
                    haxe += '@:enum abstract ';
                }

                if (keyword == 'enum') {
                    inEnumName = name;
                    haxe += name + '(Int) from Int to Int ';
                } else {
                    haxe += name + ' ';
                }

                var extras = convertDeclExtras(RE_DECL.matched(4));
                for (item in extras.classes) {
                    typeInfo.parent = item;
                    haxe += 'extends ' + item + ' ';
                }
                for (item in extras.interfaces) {
                    typeInfo.interfaces.set(item, true);
                    haxe += 'implements ' + item + ' ';
                }

                haxe += '{';

                openBraces++;
                i += RE_DECL.matched(0).length;

            }
            else {
                haxe += c;
                i++;
            }
        
        }

        // Convert tabs to spaces
        haxe = haxe.replace("\t", '    ');
        haxe = haxe.replace("\r", '');

        // Convert __CONTINUE__ to continue
        haxe = haxe.replace('__CONTINUE__', 'continue');

        // Per-file patches
        if (rootType == 'spine.AnimationStateData') {
            haxe = haxe.replace('import spine.support.utils.ObjectFloatMap', 'import spine.support.utils.AnimationStateMap');
            haxe = haxe.replace('ObjectFloatMap<Key>', 'AnimationStateMap');
            haxe = haxe.replace('ObjectFloatMap', 'AnimationStateMap');
            haxe = haxe.replace('Key', 'AnimationStateDataKey');
            haxe = haxe.replace('setMix(fromName:String, toName:String, duration:Float)', 'setMixByName(fromName:String, toName:String, duration:Float)');
        }
        else if (rootType == 'spine.AnimationState') {
            haxe = haxe.replace('setAnimation(trackIndex:Int, animationName:String, loop:Bool)', 'setAnimationByName(trackIndex:Int, animationName:String, loop:Bool)');
            haxe = haxe.replace('addAnimation(trackIndex:Int, animationName:String, loop:Bool, delay:Float)', 'addAnimationByName(trackIndex:Int, animationName:String, loop:Bool, delay:Float)');
            haxe = haxe.replace('animationsChanged()', 'handleAnimationsChanged()');
        }
        else if (rootType == 'spine.Animation') {
            haxe = haxe.replace('binarySearch(values:FloatArray, target:Float, step:Int)', 'binarySearchWithStep(values:FloatArray, target:Float, step:Int)');
            haxe = haxe.replace('class Animation {', 'class Animation {\n    private var hashCode = Std.int(Math.random() * 99999999);\n');
            haxe = haxe.replace('System.arraycopy(lastVertices', 'Array.copyFloats(lastVertices');
        }
        else if (rootType == 'spine.Skeleton') {
            haxe = haxe.replace('ObjectMap<Key,Attachment>', 'AttachmentMap');
            haxe = haxe.replace('ObjectMap', 'AttachmentMap');
            haxe = haxe.replace('updateCache', 'cache');
            haxe = haxe.replace('cache()', 'updateCache()');
            haxe = haxe.replace('sortPathConstraintAttachment(skin:Skin, slotIndex:Int, slotBone:Bone)', 'sortPathConstraintAttachmentWithSkin(skin:Skin, slotIndex:Int, slotBone:Bone)');
            haxe = haxe.replace('updateWorldTransform(parent:Bone)', 'updateWorldTransformWithParent(parent:Bone)');
            haxe = haxe.replace('setSkin(skinName:String)', 'setSkinByName(skinName:String)');
            haxe = haxe.replace('getAttachment(slotName:String, attachmentName:String)', 'getAttachmentWithSlotName(slotName:String, attachmentName:String)');
            haxe = haxe.replace('sortPathConstraintAttachment(skin,', 'sortPathConstraintAttachmentWithSkin(skin,');
            haxe = haxe.replace('sortPathConstraintAttachment(data.defaultSkin,', 'sortPathConstraintAttachmentWithSkin(data.defaultSkin,');
            haxe = haxe.replace('sortPathConstraintAttachment(data.skins.', 'sortPathConstraintAttachmentWithSkin(data.skins.');
        }
        else if (rootType == 'spine.IkConstraint') {
            haxe = haxe.replace('apply(bone:Bone, targetX:Float, targetY:Float, compress:Bool, stretch:Bool, uniform:Bool, alpha:Float)', 'applyOne(bone:Bone, targetX:Float, targetY:Float, compress:Bool, stretch:Bool, uniform:Bool, alpha:Float)');
            haxe = haxe.replace('apply(parent:Bone, child:Bone, targetX:Float, targetY:Float, bendDir:Int, stretch:Bool, alpha:Float)', 'applyTwo(parent:Bone, child:Bone, targetX:Float, targetY:Float, bendDir:Int, stretch:Bool, alpha:Float)');
        }
        else if (rootType == 'spine.Bone') {
            haxe = haxe.replace('updateWorldTransform(', 'updateWorldTransformWithData(');
            haxe = haxe.replace('updateWorldTransformWithData()', 'updateWorldTransform()');
            haxe = haxe.replace('setScale(scale:Float)', 'setScale2(scale:Float)');
            haxe = haxe.replace(' cos(', ' Math.cos(');
            haxe = haxe.replace(' sin(', ' Math.sin(');
            haxe = haxe.replace('(skeleton.scaleX < 0 != skeleton.scaleY < 0)', '((skeleton.scaleX < 0) != (skeleton.scaleY < 0))');
        }
        else if (rootType == 'spine.SkeletonBounds') {
            haxe = haxe.replace('containsPoint(polygon:FloatArray, x:Float, y:Float)', 'polygonContainsPoint(polygon:FloatArray, x:Float, y:Float)');
            haxe = haxe.replace('intersectsSegment(polygon:FloatArray, x1:Float, y1:Float, x2:Float, y2:Float)', 'polygonIntersectsSegment(polygon:FloatArray, x1:Float, y1:Float, x2:Float, y2:Float)');
        }
        else if (rootType == 'spine.utils.SkeletonClipping') {
            haxe = haxe.replace('clipEnd(slot:Slot)', 'clipEndWithSlot(slot:Slot)');
            haxe = haxe.replace('cast(polygons[p], FloatArray)', 'polygons[p]');
        }
        else if (rootType == 'spine.utils.Triangulator') {
            haxe = haxe.replace('isConcave(', 'isGeometryConcave(');
            haxe = haxe.replace('winding(', 'computeWinding(');
        }
        else if (rootType == 'spine.BlendMode') {
            haxe = haxe.replace('import spine.support.graphics.GL20;', '');
        }
        else if (rootType == 'spine.Skin') {
            haxe = haxe.replace('ObjectMap<Key,Attachment>', 'AttachmentMap');
            haxe = haxe.replace('ObjectMap', 'AttachmentMap');
            haxe = haxe.replace('hashCode = 31 * (31 + name.hashCode()) + slotIndex;', 'hashCode = Std.int(31 * (31 + name.hashCode()) + slotIndex);');
        }
        else if (rootType == 'spine.attachments.VertexAttachment') {
            haxe = haxe.replace('nextID()', 'getNextID()');
        }

        // Convert enums valueOf() / name() / ordinal()
        for (enumName in ctx.enums.keys()) {
            var enumRootType = ctx.enums.get(enumName).rootType;
            var enumValues = ctx.enums.get(enumName).values;
            haxe = haxe.replace('import ' + enumRootType + '.' + enumName + ';', 'import ' + enumRootType + '.' + enumName + ';\nimport ' + enumRootType + '.' + enumName + '_enum;');
            haxe = haxe.replace(enumName + '.valueOf(', enumName + '_enum.valueOf(');
            for (val in enumValues) {
                haxe = haxe.replace(enumName + '.' + val + '.name()', enumName + '_enum.' + val + '_name');
                haxe = haxe.replace(enumName + '.' + val + '.ordinal()', enumName + '.' + val);
            }
        }

        // Replace outside-of-for break/continue outer;
        haxe = haxe.replace('break outer;', '{ _gotoLabel_outer = 1; break; }');
        haxe = haxe.replace('continue outer;', '{ _gotoLabel_outer = 1; continue; }');

        // Update world transform replaces
        haxe = haxe.replace('updateWorldTransform(', 'updateWorldTransformWithData(');
        haxe = haxe.replace('updateWorldTransformWithData()', 'updateWorldTransform()');

        // Replace some Math library calls and similar
        haxe = haxe.replace('Math.max(', 'MathUtils.max(');
        haxe = haxe.replace('Math.min(', 'MathUtils.min(');
        haxe = haxe.replace('Math.signum(', 'MathUtils.signum(');
        haxe = haxe.replace('Integer.MAX_VALUE', '999999999');
        haxe = haxe.replace('Integer.MIN_VALUE', '-999999999');
        haxe = haxe.replace('Float.MAX_VALUE', '999999999.0');
        haxe = haxe.replace('Float.MIN_VALUE', '-999999999.0');
        haxe = haxe.replace('System.arraycopy(', 'Array.copy(');
        haxe = haxe.replace('Float.isNaN(', 'Math.isNaN(');
        haxe = haxe.replace('hashCode()', 'getHashCode()');
        haxe = haxe.replace('MixDirection.In', 'MixDirection.directionIn');
        haxe = haxe.replace('MixDirection.out', 'MixDirection.directionOut');

        // Move inner declarations to top level
        haxe = moveTopLevelDecls(haxe);

        // Add inline class defs (which are not inline anymore)
        for (key in inlineClassDefs.keys()) {
            if (key.startsWith(rootType + '.')) {
                var body = inlineClassDefs.get(key).classBody;
                var lines = body.split("\n");
                var indent = lines[1].length - lines[1].ltrim().length;
                haxe += "\n";
                for (line in lines) {
                    haxe += line.substring(indent) + "\n";
                }
                haxe += "\n";
            }
        }

        // Comment skipped names
        var newLines = [];
        var lines = haxe.split("\n");
        for (line in lines) {
            var ltrimmed = line.ltrim();
            for (name in skippedNames.keys()) {
                if (ltrimmed.startsWith(name + ' =')) {
                    line = line.substring(0, line.length - ltrimmed.length) + '//' + ltrimmed;
                    break;
                }
            }
            newLines.push(line);
        }
        haxe = newLines.join("\n");

        // Add extra haxe
        if (extraHaxe.trim() != '') {
            haxe += "\n";
            haxe += extraHaxe;
        }

        return haxe;

    } //javaToHaxe

    static function moveTopLevelDecls(haxe:String):String {

        var lines = haxe.split("\n");
        var mainLines = [];
        var subLines = [];
        var inSub = false;
        var lastWasInSub = false;

        for (line in lines) {
            if (lastWasInSub && cleanedCode(line, { canBeInComment: true }).trim() == '') {
                if (line.startsWith('    ')) {
                    subLines.push(line.substring(4));
                } else {
                    subLines.push(line);
                }
            }
            else {
                lastWasInSub = false;
                if (!inSub) {
                    if (line.startsWith('    ') && RE_HAXE_DECL.match(line.substring(4))) {
                        inSub = true;
                        
                        // Check if previous lines should be in sub as well
                        var prevLines = [];
                        while (mainLines.length >= 0 && cleanedCode(mainLines[mainLines.length-1], { canBeInComment: true }).trim() == '') {
                            var l = mainLines.pop();
                            if (l.startsWith('    ')) l = l.substring(4);
                            prevLines.unshift(l);
                        }
                        if (prevLines.length > 0) {
                            subLines = subLines.concat(prevLines);
                        }

                        subLines.push(line.substring(4));
                    }
                    else {
                        mainLines.push(line);
                    }
                }
                else {
                    subLines.push(line.substring(4));
                    if (line.startsWith('    }') || line.startsWith('    ;}')) {
                        inSub = false;
                        lastWasInSub = true;
                    }
                }
            }
        }

        return mainLines.join("\n") + subLines.join("\n");

    } //moveTopLevelDecls

/// Compiler

    /** Haxe compiler is better than our custom parser to detect inconsistencies.
        Instead of making pointless assumptions, we let the compiler find the
        remaining errors and try to fix them all from the informations it gives us. */
    static function fixCompilerErrors(ctx:ConvertContext):Void {

        var pass = 1;
        var maxPass = 8;
        var filesCache:Map<String,String> = new Map();

        function getFile(path:String) {
            var data = filesCache.get(path);
            if (data == null) {
                data = File.getContent(path);
                filesCache.set(path, data);
            }
            return data;
        }
        function saveFile(path:String, data:String) {
            filesCache.set(path, data);
        }

        while (pass < maxPass) {

            println('[run haxe $pass]');

            for (path in filesCache.keys()) {
                var data = filesCache.get(path);
                data = data.replace('/*LINE*/', '\n');
                data = data.replace('/*TAB*/', '    ');
                File.saveContent(path, data);
            }
            filesCache = new Map();
            var numFixed = 0;

            // Keep track of the changes we make on the files so that
            // we can still find an error position on a modified file.
            var changes:Map<String,Array<{start:Int,end:Int,add:Int}>> = new Map();

            // Get diagnostics from haxe compiler
            // (we target a static platform to catch errors that might happen only on these)
            /*var diagnostics = parseCompilerOutput('' + ChildProcess.spawnSync('haxe', [
                '--macro', 'ImportAll.run("spine")',
                '-js main',
                '--no-output'
            ]).stderr);*/
            var diagnostics = parseCompilerOutput('' + ChildProcess.spawnSync('haxe', [
                'build-static.hxml'
            ]).stderr);

            //trace(diagnostics);

            for (item in diagnostics) {

                if (item.location == 'characters') {

                    // Take previous changes in account on the range
                    var lineChanges = changes.get(item.filePath+':'+item.line);
                    if (lineChanges == null) {
                        lineChanges = [];
                        changes.set(item.filePath+':'+item.line, lineChanges);
                    }
                    for (aChange in lineChanges) {
                        if (aChange.end <= item.start) {
                            item.start += aChange.add;
                            item.end += aChange.add;
                        }
                    }

                    if (item.message.startsWith('Float should be Int')) {
                        numFixed++;

                        var file = getFile(item.filePath);

                        var lines = file.split("\n");
                        var lineIndex = item.line - 1;
                        var line = lines[lineIndex];
                        while (lineIndex > 1 && line.trim() == '') {
                            lineIndex--;
                            line = lines[lineIndex];
                        }
                        var snippet = line.substring(item.start, item.end);

                        if (snippet.startsWith('return ')) {
                            snippet = 'return Std.int(' + snippet.substring(7) + ')';
                        }
                        else if (snippet.indexOf('= ') != -1 && snippet.endsWith(';')) {
                            snippet = snippet.substring(0, snippet.indexOf('= ') + 2) + 'Std.int(' + snippet.substring(snippet.indexOf('= ') + 2, snippet.length - 1) + ');';
                        }
                        else {
                            snippet = 'Std.int(' + snippet + ')';
                        }

                        // Add new change
                        lineChanges.push({ start: item.start, end: item.end, add: 'Std.int()'.length });

                        // Edit line
                        line = line.substring(0, item.start) + snippet + line.substring(item.end);
                        lines[lineIndex] = line;

                        // Save modified file
                        saveFile(item.filePath, lines.join("\n"));
                    }
                    else if (item.message == 'Unknown identifier : binarySearch') {
                        numFixed++;

                        var file = getFile(item.filePath);

                        var lines = file.split("\n");
                        var line = lines[item.line - 1];

                        // Add new change
                        lineChanges.push({ start: item.start, end: item.end, add: 'Animation.WithStep'.length });

                        // Edit line
                        line = line.substring(0, item.start) + 'Animation.binarySearchWithStep' + line.substring(item.end);
                        lines[item.line - 1] = line;

                        // Save modified file
                        saveFile(item.filePath, lines.join("\n"));
                    }
                    else if (item.message == 'Current class does not have a superclass') {
                        numFixed++;

                        var file = getFile(item.filePath);

                        var lines = file.split("\n");
                        var line = lines[item.line - 1];
                        
                        var newLine = line.replace('super.toString()', 'Type.getClassName(Type.getClass(this))');

                        // Add new change
                        lineChanges.push({ start: 0, end: item.end, add: newLine.length - line.length });

                        // Edit line
                        lines[item.line - 1] = newLine;

                        // Save modified file
                        saveFile(item.filePath, lines.join("\n"));
                    }
                    else if (item.message.startsWith('Unknown identifier : ')) {
                        numFixed++;

                        var file = getFile(item.filePath);

                        var lines = file.split("\n");
                        var line = lines[item.line - 1];
                        var snippet = line.substring(item.start, item.end);
                        var newSnippet = snippet;

                        if (item.filePath.endsWith('AnimationState.hx')) {
                            if (newSnippet.toUpperCase() == newSnippet) {
                                newSnippet = '@:privateAccess AnimationState.' + newSnippet;
                            } else {
                                newSnippet = 'AnimationState_this.' + newSnippet;
                            }
                        }

                        // Add new change
                        lineChanges.push({ start: item.start, end: item.end, add: newSnippet.length - snippet.length });

                        // Edit line
                        line = line.substring(0, item.start) + newSnippet + line.substring(item.end);
                        lines[item.line - 1] = line;

                        // Save modified file
                        saveFile(item.filePath, lines.join("\n"));
                    }
                    else if (item.message == 'Too many arguments' || item.message.startsWith('spine.Bone should be Float')) {
                        numFixed++;

                        var file = getFile(item.filePath);

                        var lines = file.split("\n");
                        var line = lines[item.line - 1];
                        
                        var newLine = line.replace('applyOne(', 'applyTwo(');
                        newLine = newLine.replace('apply(', 'applyOne(');
                        newLine = newLine.replace('.clear(1024)', '.clear()');
                        newLine = newLine.replace('.clear(2048)', '.clear()');
                        newLine = newLine.replace('Animation.binarySearch(', 'Animation.binarySearchWithStep(');

                        // Add new change
                        lineChanges.push({ start: 0, end: item.end, add: newLine.length - line.length });

                        // Edit line
                        lines[item.line - 1] = newLine;

                        // Save modified file
                        saveFile(item.filePath, lines.join("\n"));
                    }
                    else if (item.message == 'Not enough arguments, expected step:Int') {
                        numFixed++;

                        var file = getFile(item.filePath);

                        var lines = file.split("\n");
                        var lineIndex = item.line - 1;
                        var line = lines[lineIndex];
                        var snippet = line.substring(item.start, item.end);
                        var newSnippet = snippet.replace('Animation.binarySearchWithStep', 'Animation.binarySearch');

                        // Add new change
                        lineChanges.push({ start: item.start, end: item.end, add: newSnippet.length - snippet.length });

                        // Edit line
                        line = line.substring(0, item.start) + newSnippet + line.substring(item.end);
                        lines[lineIndex] = line;

                        // Save modified file
                        saveFile(item.filePath, lines.join("\n"));
                    }
                    else if (item.message.startsWith('On static platforms, null can\'t be used as basic type ')) {
                        numFixed++;

                        var file = getFile(item.filePath);

                        var lines = file.split("\n");
                        var lineIndex = item.line - 1;
                        var line = lines[lineIndex];
                        var snippet = line.substring(item.start, item.end);
                        var newSnippet = '0';

                        // Add new change
                        lineChanges.push({ start: item.start, end: item.end, add: newSnippet.length - snippet.length });

                        // Edit line
                        line = line.substring(0, item.start) + newSnippet + line.substring(item.end);
                        lines[lineIndex] = line;

                        // Save modified file
                        saveFile(item.filePath, lines.join("\n"));
                    }
                    else if (item.message.startsWith('spine.support.utils.FloatArray should be Float')) {
                        numFixed++;

                        var file = getFile(item.filePath);

                        var lines = file.split("\n");
                        var line = lines[item.line - 1];
                        
                        var newLine = line.replace('containsPoint(', 'polygonContainsPoint(');
                        newLine = newLine.replace('intersectsSegment(', 'polygonIntersectsSegment(');

                        // Add new change
                        lineChanges.push({ start: 0, end: item.end, add: newLine.length - line.length });

                        // Edit line
                        lines[item.line - 1] = newLine;

                        // Save modified file
                        saveFile(item.filePath, lines.join("\n"));
                    }
                    else if (item.message.startsWith('Cannot inline a not final return')) {

                        var file = getFile(item.filePath);

                        var lines = file.split("\n");
                        var lineNumber = item.line - 1;
                        while (lineNumber > 0 && lines[lineNumber].indexOf(' #if !spine_no_inline inline #end ') == -1) {
                            lineNumber--;
                        }
                        var line = lines[lineNumber];
                        if (line != null) {
                            numFixed++;

                            var newLine = line.replace(' #if !spine_no_inline inline #end ', ' ');

                            // Add new change
                            //lineChanges.push({ start: 0, end: item.end, add: newLine.length - line.length });

                            // Edit line
                            lines[lineNumber] = newLine;

                            // Save modified file
                            saveFile(item.filePath, lines.join("\n"));
                        }
                    }
                    else if (RE_ERROR_IDENTIFIER_NOT_PART.match(item.message)) {
                        numFixed++;
                        var identifier = RE_ERROR_IDENTIFIER_NOT_PART.matched(1);
                        var newIdentifier = identifier;

                        // Specific case
                        if (identifier.toLowerCase() == 'in') newIdentifier = 'directionIn';
                        else if (identifier.toLowerCase() == 'out') newIdentifier = 'directionOut';

                        var type = RE_ERROR_IDENTIFIER_NOT_PART.matched(2);

                        var file = getFile(item.filePath);

                        var lines = file.split("\n");
                        var line = lines[item.line - 1];

                        // Add new change
                        lineChanges.push({ start: item.start, end: item.end, add: type.length + 1 + newIdentifier.length - identifier.length });

                        // Edit line
                        line = line.substring(0, item.start) + type + '.' + newIdentifier + line.substring(item.end);
                        lines[item.line - 1] = line;

                        // Save modified file
                        saveFile(item.filePath, lines.join("\n"));

                    }
                    else if (RE_ERROR_SHOULD_BE.match(item.message)) {
                        numFixed++;
                        var type = RE_ERROR_SHOULD_BE.matched(1);

                        var file = getFile(item.filePath);

                        var lines = file.split("\n");
                        var line = lines[item.line - 1];
                        var snippet = line.substring(item.start, item.end);
                        var newSnippet = snippet;

                        if (type.startsWith('spine.') && snippet.indexOf(' == ') != -1) {
                            newSnippet = newSnippet.replace(' == ', ' == ' + type + '.');
                        }

                        // Add new change
                        lineChanges.push({ start: item.start, end: item.end, add: newSnippet.length - snippet.length });

                        // Edit line
                        line = line.substring(0, item.start) + newSnippet + line.substring(item.end);
                        lines[item.line - 1] = line;

                        // Save modified file
                        saveFile(item.filePath, lines.join("\n"));

                    }
                } else if (item.location == 'lines') {
                    if (RE_ERROR_FIELD_NEEDED_BY.match(item.message)) {

                        var missing = RE_ERROR_FIELD_NEEDED_BY.matched(1);
                        var parent = RE_ERROR_FIELD_NEEDED_BY.matched(2);
                        var parentInfo = ctx.types.get(parent);
                        if (parentInfo != null && parentInfo.methods.exists(missing)) {
                            numFixed++;

                            var file = getFile(item.filePath);

                            var method = parentInfo.methods.get(missing);

                            var lines = file.split("\n");
                            var line = lines[item.start - 1];

                            line += '/*LINE*//*TAB*/';
                            line += method.modifiers.join(' ') + ' function ' + missing + '(';
                            var n = 0;
                            for (arg in method.args) {
                                if (n++ > 0) line += ', ';
                                line += arg.name + ':' + arg.type;
                            }
                            line += '):' + method.type + ' { ';
                            line += switch (method.type) {
                                case 'Float', 'Int', 'Short': 'return 0;';
                                case 'Bool': 'return false;';
                                case 'Void': '';
                                default: 'return null;';
                            }
                            line += ' }';

                            // Edit line
                            lines[item.start - 1] = line;

                            // Save modified file
                            saveFile(item.filePath, lines.join("\n"));

                        }
                    }
                    else if (RE_ERROR_FIELD_OVERRIDE.match(item.message)) {
                        numFixed++;

                        var field = RE_ERROR_FIELD_OVERRIDE.matched(1);
                        var parent = RE_ERROR_FIELD_OVERRIDE.matched(2);

                        var file = getFile(item.filePath);

                        var lines = file.split("\n");
                        var line = lines[item.start - 1];

                        line = line.substring(0, line.length - line.ltrim().length) + 'override ' + line.ltrim();

                        // Edit line
                        lines[item.start - 1] = line;

                        // Save modified file
                        saveFile(item.filePath, lines.join("\n"));
                    }
                    else if (item.message.endsWith('is inlined and cannot be overridden')) {
                        numFixed++;

                        var file = getFile(item.filePath);

                        var lines = file.split("\n");
                        var line = lines[item.start - 1];

                        line = line.replace(' #if !spine_no_inline inline #end ', ' ');

                        // Edit line
                        lines[item.start - 1] = line;

                        // Save modified file
                        saveFile(item.filePath, lines.join("\n"));
                    }
                }
            }

            if (numFixed == 0) {
                if (diagnostics.length > 0) {
                    println('    -> There are still errors that could not be fixed\u2026');
                } else {
                    println('    -> Everything has been fixed!');
                }
                break;
            }
            else {
                println('    -> Fixed ' + numFixed + ' error' + (numFixed != 1 ? 's' : ''));
            }
            pass++;
        }

        for (path in filesCache.keys()) {
            var data = filesCache.get(path);
            data = data.replace('/*LINE*/', '\n');
            data = data.replace('/*TAB*/', '    ');
            File.saveContent(path, data);
        }

    } //fixCompilerErrors

    /** Parse haxe compiler output and extract info */
    public static function parseCompilerOutput(output:String, ?options:ParseCompilerOutputOptions):Array<HaxeCompilerOutputElement> {

        if (options == null) {
            options = {};
        }

        var info:Array<HaxeCompilerOutputElement> = [];
        var prevInfo = null;
        var lines = output.split("\n");
        var cwd = options.cwd;
        if (cwd == null) cwd = Sys.getCwd();
        var line, lineStr, filePath, location, start, end, message;
        var re = RE_HAXE_COMPILER_OUTPUT_LINE;

        for (i in 0...lines.length) {

            lineStr = lines[i];

            if (info.length > 0) {
                prevInfo = info[info.length - 1];
            }

            if (re.match(lineStr)) {

                filePath = re.matched(1);
                line = Std.parseInt(re.matched(2));
                location = re.matched(3);
                start = Std.parseInt(re.matched(4));
                end = Std.parseInt(re.matched(5));
                message = re.matched(6);

                if (message != null || options.allowEmptyMessage) {

                    // Make file_path absolute if possible
                    if (cwd != null && !Path.isAbsolute(filePath)) {
                        filePath = Path.join([cwd, filePath]);
                    }

                    if (message != null
                        && prevInfo != null
                        && prevInfo.message != null
                        && prevInfo.filePath == filePath
                        && prevInfo.location == location
                        && prevInfo.line == line
                        && prevInfo.start == start
                        && prevInfo.end == end) {
                        
                        // Concatenate multiline message
                        prevInfo.message += "\n" + message;
                    }
                    else {
                        info.push({
                            line: line,
                            filePath: filePath,
                            location: location,
                            start: start,
                            end: end,
                            message: message
                        });
                    }
                }
            }
        } //for lines

        // Prevent duplicate messages as this can happen, like multiple `Unexpected (` at the same location
        // We may want to remove this snippet in a newer haxe compiler version if the output is never duplicated anymore
        for (i in 0...info.length) {
            message = info[i].message;
            if (message != null) {
                var messageLines = message.split("\n");
                var allLinesAreEqual = true;
                if (messageLines.length > 1) {
                    lineStr = messageLines[0];
                    for (l in 0...messageLines.length) {
                        if (lineStr != messageLines[l]) {
                            allLinesAreEqual = false;
                            break;
                        }
                        lineStr = messageLines[l];
                    }
                    
                    // If all lines of message are equal, just keep one line
                    if (allLinesAreEqual) {
                        info[i].message = lineStr;
                    }
                }
            }
        }

        return info;

    } //parseCompilerOutput

/// Utils

    static function replaceStart(str:String, from:String, to:String):String {

        if (str.startsWith(from)) {
            return to + str.substr(from.length);
        }

        return str;

    } //replaceStart

    static function deleteRecursive(path:String, ?except:Array<String>) {

        if (!FileSystem.exists(path)) {
            return;
        }
        else if (FileSystem.isDirectory(path)) {
            var hasException = false;
            for (name in FileSystem.readDirectory(path)) {
                if (except == null || except.indexOf(name) == -1) {
                    deleteRecursive(Path.join([path, name]));
                }
                else if (except != null) {
                    hasException = true;
                }
            }
            if (!hasException) FileSystem.deleteDirectory(path);
        }
        else {
            FileSystem.deleteFile(path);
        }

    } //deleteRecursive

    static function cleanedCode(code:String, ?options: { ?cleanSpaces:Bool, ?canBeInComment:Bool }) {

        var i = 0;
        var c = '';
        var cc = '';
        var after = '';
        var len = code.length;
        var inSingleLineComment = false;
        var inMultiLineComment = false;
        var result = '';
        var cleanSpaces = options != null && options.cleanSpaces ? true : false;
        var canBeInComment = options != null && options.canBeInComment ? true : false;
        
        if (canBeInComment && code.ltrim().startsWith('*')) inMultiLineComment = true;
        else if (canBeInComment && code.rtrim().endsWith('*/')) inMultiLineComment = true;

        while (i < len) {

            after = code.substr(i);

            c = after.charAt(0);
            cc = c + (i < len ? after.charAt(1) : '');

            if (inSingleLineComment) {
                if (c == "\n") {
                    inSingleLineComment = false;
                }
                result += cleanSpaces ? '' : ' ';
                i++;
            }
            else if (inMultiLineComment) {
                if (cc == '*/') {
                    inMultiLineComment = false;
                    result += cleanSpaces ? '' : '  ';
                    i += 2;
                } else {
                    result += cleanSpaces ? '' : ' ';
                    i++;
                }
            }
            else if (cc == '//') {
                inSingleLineComment = true;
                result += cleanSpaces ? '' : '  ';
                i += 2;
            }
            else if (cc == '/*') {
                inMultiLineComment = true;
                result += cleanSpaces ? '' : '  ';
                i += 2;
            }
            else if (c == '"' || c == '\'') {
                if (!RE_STRING.match(after)) {
                    throw 'Failed to parse string when cleaning code: ' + code;
                }
                var n = 2;
                var strLen = RE_STRING.matched(0).length;
                result += c;
                while (n++ < strLen) result += cleanSpaces ? '' : ' ';
                result += c;
                i += strLen;
            }
            else if (cleanSpaces && c.trim() == '' && (result.length == 0 || RE_WORD_SEP.match(result.charAt(result.length-1)) || after.trim() == '' || RE_WORD_SEP.match(after.ltrim().charAt(0)))) {
                i++;
            }
            else {
                result += c;
                i++;
            }
        }

        return result;

    } //cleanedCode

    static function splitCode(code:String, splitTokens:Array<String>, deep:Bool = false) {

        var cleaned = cleanedCode(code);
        var i = 0;
        var c = '';
        var cc = '';
        var pc = '';
        var after = '';
        var word = '';
        var len = cleaned.length;
        var tokensMap:Map<String,Bool> = new Map();
        var parts:Array<String> = [''];
        var partIndex = 0;
        var openBraces = 0;
        var openParens = 0;
        var openBrackets = 0;

        for (token in splitTokens) {
            tokensMap.set(token, true);
        }

        while (i < len) {

            after = cleaned.substr(i);

            c = after.charAt(0);
            cc = c + (i < len ? after.charAt(1) : '');
            
            if (i > 0) {
                pc = cleaned.charAt(i - 1);
            }
            else {
                pc = '';
            }
            if (pc != '' &&
                RE_WORD_SEP.match(pc) &&
                RE_WORD.match(after)) {
                word = RE_WORD.matched(0);
            }
            else {
                word = '';
            }

            if (c == '{') {
                openBraces++;
                parts[partIndex] += code.charAt(i);
                i++;
            }
            else if (c == '}') {
                openBraces--;
                parts[partIndex] += code.charAt(i);
                i++;
            }
            if (c == '(') {
                openParens++;
                parts[partIndex] += code.charAt(i);
                i++;
            }
            else if (c == ')') {
                openParens--;
                parts[partIndex] += code.charAt(i);
                i++;
            }
            if (c == '[') {
                openBrackets++;
                parts[partIndex] += code.charAt(i);
                i++;
            }
            else if (c == ']') {
                openBrackets--;
                parts[partIndex] += code.charAt(i);
                i++;
            }
            else if ((openBraces == 0 || deep) && word != '') {
                if (tokensMap.exists(word)) {
                    parts.push('');
                    partIndex++;
                }
                parts[partIndex] += code.substr(i, word.length);
                i += word.length;
            }
            else {
                parts[partIndex] += code.charAt(i);
                i++;
            }

        }

        return parts;

    } //splitCode

/// Contextual classes info

    static var contextualClasses:Map<String,String> = [
        'spine.AnimationState.EventQueue' => 'queue'
    ];

    static var inlineClassDefs:Map<String,{replaceWithClass:String, classBody:String}> = [
        'spine.AnimationState.Pool' => {
            replaceWithClass: 'TrackEntryPool',
            classBody: "
            private class TrackEntryPool extends Pool<TrackEntry> {
                override function newObject() {
                    return new TrackEntry();
                }
            }"
        },
        'spine.Skin.Pool' => {
            replaceWithClass: 'KeyPool',
            classBody: "
            private class KeyPool extends Pool<Key> {
                override public function new(initialCapacity:Int) {
                    super(initialCapacity, 999999999);
                }
                override function newObject() {
                    return new Key();
                }
            }"
        },
        'spine.SkeletonBounds.Pool' => {
            replaceWithClass: 'PolygonPool',
            classBody: "
            private class PolygonPool extends Pool<FloatArray> {
                override function newObject() {
                    return new FloatArray();
                }
            }"
        },
        'spine.utils.Triangulator.Pool' => {
            replaceWithClass: 'PolygonPool',
            classBody: "
            private class PolygonPool extends Pool<FloatArray> {
                override function newObject() {
                    return new FloatArray(16);
                }
            }"
        },
        'spine.utils.Triangulator.Pool2' => {
            replaceWithClass: 'IndicesPool',
            classBody: "
            private class IndicesPool extends Pool<ShortArray> {
                override function newObject() {
                    return new ShortArray(16);
                }
            }"
        }
    ];

    static var skippedFiles:Map<String,Bool> = [
        'SkeletonRenderer.java' => true,
        'SkeletonRendererDebug.java' => true,
        'SkeletonBinary.java' => true,
        'utils/SkeletonActor.java' => true,
        'utils/SkeletonActorPool.java' => true,
        'utils/SkeletonDrawable.java' => true,
        'utils/TwoColorPolygonBatch.java' => true,
        'vertexeffects/JitterEffect.java' => true,
        'vertexeffects/SwirlEffect.java' => true
    ];

    static var skippedNames:Map<String,Bool> = new Map();/*[
        'hashCode' => true
    ];*/

    static var skippedConstructors:Map<String,String> = [
        'spine.AnimationState' => '', // Empty animation state
        'spine.Slot' => 'Slot slot,Bone bone', // Copy constructor
        'spine.Skeleton' => 'Skeleton skeleton', // Copy constructor
        'spine.TransformConstraint' => 'TransformConstraint constraint,Skeleton skeleton', // Copy constructor
        'spine.IkConstraint' => 'IkConstraint constraint,Skeleton skeleton', // Copy constructor
        'spine.PathConstraint' => 'PathConstraint constraint,Skeleton skeleton', // Copy constructor
        'spine.Bone' => 'Bone bone,Skeleton skeleton,Bone parent', // Copy constructor
        'spine.BoneData' => 'BoneData bone,BoneData parent', // Copy constructor
        'spine.SkeletonJson' => 'TextureAtlas atlas', // Can use new(new AtlasAttachmentLoader(atlas)) instead
        'spine.utils.SkeletonPool' => 'SkeletonData skeletonData', // Optional constructor
        'spine.utils.SkeletonPool#2' => 'SkeletonData skeletonData,int initialCapacity' // Optional constructor
    ];

    static var noInlineNames:Map<String,Bool> = [
        'apply' => true,
        'getPropertyId' => true,
        'applyDeform' => true,
        'applyMixingFrom' => true
    ];

/// Regular expressions

    static var RE_WORD_SEP = ~/^[^a-zA-Z0-9_]/;
    static var RE_WORD = ~/^[a-zA-Z0-9_]+/;
    static var RE_STRING = ~/^(?:"(?:[^"\\]*(?:\\.[^"\\]*)*)"|'(?:[^'\\]*(?:\\.[^'\\]*)*)')/;
    static var RE_IMPORT = ~/^import\s+(static\s+)?([^;\s]+)\s*;/;
    static var RE_PROPERTY = ~/^((?:(?:public|private|protected|static|final|dynamic|volatile)\s+)+)?([a-zA-Z0-9,<>\[\]_]+)\s+([a-zA-Z0-9_]+)\s*(;|=|,)/;
    static var RE_CONSTRUCTOR = ~/^((?:(?:public|private|protected|final)\s+)+)?([a-zA-Z0-9,<>\[\]_]+)\s*\(\s*([^\)]*)\s*\)\s*{/;
    static var RE_METHOD = ~/^((?:(?:public|private|protected|static|final|synchronized)\s+)+)?([a-zA-Z0-9,<>\[\]_]+)\s+([a-zA-Z0-9_]+)\s*\(\s*([^\)]*)\s*\)\s*({|;)/;
    static var RE_VAR = ~/^(?:([a-zA-Z0-9_\[\]]+(?:<[a-zA-Z0-9_,<>\[\]]*>)?)\s+)?([a-zA-Z0-9_]+)\s*(;|=|,)/;
    static var RE_DECL = ~/^((?:(?:public|private|protected|static|final|abstract)\s+)+)?(enum|interface|class)\s+([a-zA-Z0-9,<>\[\]_]+)((?:\s+(?:implements|extends)\s*(?:[a-zA-Z0-9,<>\[\]_]+)(?:\s*,\s*[a-zA-Z0-9,<>\[\]_]+)*)*)\s*{/;
    static var RE_HAXE_DECL = ~/^((?:(?:public|private|protected|static|final|abstract|@:enum)\s+)+)?(enum|interface|class|abstract)\s+([a-zA-Z0-9,<>\[\]_]+)/;
    static var RE_NEW_ARRAY = ~/^new\s+([a-zA-Z0-9_]+)\s*\[/;
    static var RE_NEW_INSTANCE = ~/^new\s+([a-zA-Z0-9_]+)\s*\((\s*\))?/;
    static var RE_SWITCH = ~/^switch\s*\(/;
    static var RE_ELSE = ~/^(\s*)else((\s+if\s*)\([^{]+\))?/;
    static var RE_CASE = ~/^(case|default)\s*(?:([^:]+)\s*)?:\s*/;
    static var RE_INSTANCEOF = ~/^([a-zA-Z0-9_\[\]]+(?:<[a-zA-Z0-9_,<>\[\]]*>)?)\s+instanceof\s+([a-zA-Z0-9_\[\]]+(?:<[a-zA-Z0-9_,<>\[\]]*>)?)/;
    static var RE_CAST = ~/^\(\s*([a-zA-Z0-9_\[\]]+(?:<[a-zA-Z0-9_,<>\[\]]*>)?)\s*\)\s*((?:[a-zA-Z0-9\[\]_]+(?:<[a-zA-Z0-9_,<>\[\]]*>)?)|(?:\([^\(\)]+\)))/;
    static var RE_CALL = ~/^([a-zA-Z0-9\[\]_]+(?:<[a-zA-Z0-9_,<>\[\]]*>)?)\s*\(/;
    static var RE_NUMBER = ~/^((?:[0-9]+)\.?(?:[0-9]+)?)(f|F|d|D)/;
    static var RE_FOREACH = ~/^for\s*\(\s*([a-zA-Z0-9,<>\[\]_ ]+)\s+([a-zA-Z0-9_]+)\s*:/;
    static var RE_CATCH = ~/^catch\s*\(\s*([a-zA-Z0-9,<>\[\]_ ]+)\s+([a-zA-Z0-9_]+)\s*\)/;
    static var RE_LABEL = ~/^(outer)\s*:/;
    static var RE_LABEL_BEFORE = ~/(outer)\s*:\s*$/;
    static var RE_CONTINUE = ~/^(continue)(\s*);/;
    static var RE_CONTINUE_OR_BREAK = ~/^(continue|break)(?:\s+(outer)\s*)?;/;
    static var RE_ENUM_VALUE = ~/^([a-zA-Z0-9_]+)(\([^\)]+\))?(\s*)((?:,\s*;)|,|;|\})/;
    static var RE_PARENT_CLASS_THIS = ~/^([a-zA-Z0-9_]+)(\s*)\.\s*this\s*\./;
    static var RE_CASE_BREAKS = ~/(;|})\s*(break|continue|return)\s*(\s[^;]+)?;\s*(\}\s*)?$/;
    static var RE_EXPR_RETURNS = ~/(;|})\s*(return\s*(\s[^;]+)?;\s*(\}\s*))$/;

    static var RE_HAXE_COMPILER_OUTPUT_LINE = ~/^\s*(.+)?(?=:[0-9]*:):([0-9]+):\s+(characters|lines)\s+([0-9]+)\-([0-9]+)(?:\s+:\s*(.*?))?\s*$/;
    static var RE_ERROR_IDENTIFIER_NOT_PART = ~/^Identifier '([^']+)' is not part of ([a-zA-Z0-9_\[\]\.]+(?:<[a-zA-Z0-9_,<>\[\]]*>)?)/;
    static var RE_ERROR_FIELD_NEEDED_BY = ~/^Field ([a-zA-Z0-9_\[\]\.]+(?:<[a-zA-Z0-9_,<>\[\]]*>)?) needed by ([a-zA-Z0-9_\[\]\.]+(?:<[a-zA-Z0-9_,<>\[\]]*>)?) is missing/;
    static var RE_ERROR_FIELD_OVERRIDE = ~/^Field ([a-zA-Z0-9_\[\]\.]+(?:<[a-zA-Z0-9_,<>\[\]]*>)?) should be declared with 'override' since it is inherited from superclass ([a-zA-Z0-9_\[\]\.]+(?:<[a-zA-Z0-9_,<>\[\]]*>)?)/;
    static var RE_ERROR_SHOULD_BE = ~/should be ([a-zA-Z0-9_\[\]\.]+(?:<[a-zA-Z0-9_,<>\[\]]*>)?)/;

} //Convert

typedef ConvertContext = {
    javaDir:String,
    haxeDir:String,
    relativePath:String,
    files:Map<String,String>,
    enums:Map<String,{
        rootType: String,
        values: Array<String>
    }>,
    types:Map<String,TypeInfo>,
    secondPass:Bool
}

typedef ParseCompilerOutputOptions = {

    @:optional var allowEmptyMessage:Bool;

    @:optional var cwd:String;
}

typedef HaxeCompilerOutputElement = {

    var line:Int;

    var filePath:String;

    var location:String;

    var start:Int;

    var end:Int;

    var message:String;

}

typedef TypeInfo = {

    var name:String;

    var parent:String;

    var interfaces:Map<String,Bool>;

    var methods:Map<String,{
        modifiers:Array<String>,
        type:String,
        args:Array<{
            type:String,
            name:String
        }>
    }>;

    var properties:Map<String,{
        modifiers:Array<String>,
        type:String
    }>;

}

