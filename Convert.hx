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
            command('git', ['clone', 'https://github.com/EsotericSoftware/spine-runtimes.git']);
        }

        // Delete previously converted files
        println('Delete previously converted files\u2026');
        //deleteRecursive('spine', 'support');

        // Convert
        var ctx = {
            javaDir: 'spine-runtimes/spine-libgdx/spine-libgdx/src/com/esotericsoftware/spine',
            haxeDir: 'spine',
            relativePath: '.',
            files: new Map()
        };
        convert(ctx);

        // Add import.hx
        File.saveContent('spine/import.hx', "
import spine.support.error.*;
import spine.support.utils.ShortArray;
import spine.support.utils.IntArray;
import spine.support.utils.IntArray2D;
import spine.support.utils.FloatArray;
import spine.support.utils.FloatArray2D;
import spine.support.utils.StringArray;

using spine.support.extensions.StringExtensions;
using StringTools;
");

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
                var relJavaPath = javaPath.substr(ctx.javaDir.length + 1);

                if (!skippedFiles.exists(relJavaPath)) {

                    // Log
                    println(relJavaPath + ' -> ' + haxePath.substr(ctx.haxeDir.length + 1));

                    // Get contents
                    var java = File.getContent(javaPath);
                    var type = 'spine.' + javaPath.substring(ctx.javaDir.length + 1, javaPath.length - 5).replace('/', '.');

                    // Convert java to haxe
                    var haxe = javaToHaxe(java, javaPath.substr(ctx.javaDir.length + 1), type, ctx.haxeDir);

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

    } //convert

    static function javaToHaxe(java:String, filePath:String, rootType:String, haxeDir:String):String {

        if (FileSystem.exists(Path.join([haxeDir, 'support/overrides', replaceStart(rootType, 'spine.', '').replace('.','/') + '.hx']))) {
            var haxe = 'package ' + rootType.substring(0, rootType.lastIndexOf('.')) + ';' + "\n";
            haxe += "\n";
            haxe += 'typedef ' + rootType.substring(rootType.lastIndexOf('.') + 1) + ' = spine.support.overrides.' + replaceStart(rootType, 'spine.', '') + ';' + "\n";
            haxe += "\n";
            return haxe;
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
            ?isVarValue:Bool,
            ?until:String,
            ?untilWords:Array<String>
        }):String { return null; }

        var inSingleLineComment = false;
        var inMultiLineComment = false;
        var inClass = false;
        var inSubClass = false;
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
                case 'float': 'Float';
                case 'float[]': 'FloatArray';
                case 'float[][]': 'FloatArray2D';
                case 'String[]': 'StringArray';
                case 'short[]': 'ShortArray';
                case 'Event[]': 'Array<Event>';
                case 'Object[]': 'Array<Dynamic>';
                case 'int': 'Int';
                case 'int[]': 'IntArray';
                case 'int[][]': 'IntArray2D';
                case 'void': 'Void';
                case 'boolean': 'Bool';
                case 'Object': 'Dynamic';
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
                    /*if (!subClassHasConstructor) {
                        haxe = haxe.substring(0, haxe.length - 1);
                        cleanedHaxe = cleanedHaxe.substring(0, haxe.length);
                        haxe += "\n\t" + 'public function new() {}\n}';
                    }*/
                }
                if (inInterface && openBraces == beforeInterfaceBraces) {
                    inInterface = false;
                }
                if (inEnum && openBraces == beforeEnumBraces) {
                    inEnum = false;
                }
                if (inClass && openBraces == beforeClassBraces) {
                    inClass = false;
                    /*if (!classHasConstructor) {
                        haxe = haxe.substring(0, haxe.length - 1);
                        cleanedHaxe = cleanedHaxe.substring(0, haxe.length);
                        haxe += "\n\t\t" + 'public function new() {}\n\t}';
                    }*/
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

        consumeExpression = function(?options:{
            ?varType:String,
            ?isVarValue:Bool,
            ?until:String,
            ?untilWords:Array<String>
        }):String {

            var openBracesStart = openBraces;
            var openParensStart = openParens;
            var openBracketsStart = openBrackets;
            var stopToken = '';
            var varType = options != null ? options.varType : null;
            var isVarValue:Bool = options != null ? options.isVarValue : false;
            var until:String = options != null ? options.until : '';
            var untilWords:Array<String> = options != null ? options.untilWords : null;
            var endOfExpression:Array<String> = [];

            while (i < len) {

                nextIteration();

                if (c == ';') {
                    varType = null;
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
                    haxe += 'cast(' + RE_CAST.matched(2).ltrim();
                    i += RE_CAST.matched(0).length;
                    var castType = RE_CAST.matched(1);

                    var index = haxe.length;
                    var aStop = consumeExpression({ until: ');,' });
                    var castPart = haxe.substring(index);

                    haxe = haxe.substring(0, index);
                    cleanedHaxe = cleanedHaxe.substring(0, haxe.length);
                    haxe += castPart.substring(0, castPart.length - 1) + ', ' + convertType(castType) + ')' + castPart.substring(castPart.length - 1);

                    if (aStop == ';') {
                        varType = null;
                        isVarValue = false;
                    }

                    if (aStop == ';' && until.indexOf(';') != -1 && openBraces == openBracesStart && openParens == openParensStart) {
                        stopToken = ';';
                        break;
                    }
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
                        haxe += 'var ' + flagName + ':Bool; while (true) { ' + flagName + ' = false; ';
                        endOfExpression.unshift('if (!' + flagName + ') break; }');
                        continueToLabels.unshift({
                            breakCode: 'if (' + flagName + ') break',
                            continueCode: 'if (' + flagName + ') continue',
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
                    else if (word == 'switch' && RE_SWITCH.match(after)) {

                        openParens++;
                        i += RE_SWITCH.matched(0).length;
                        var switchCondName = '_switchCond' + (nextSwitchIndex++);
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

                        for (aCase in cases) {
                            var cleaned = cleanedCode(aCase.body, { cleanSpaces: true }).trim();
                            if (cleaned.endsWith(';break;') || cleaned.endsWith('}break;') || cleaned.endsWith('}return;') || cleaned.endsWith('}return;') || cleaned.endsWith(';return;}') || cleaned.endsWith('}return;}') || cleaned.endsWith(';break;}') || cleaned.endsWith('}break;}')) {
                                aCase.fallThrough = false;
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
                            if (!hasBrace) haxe += '{';
                            haxe += aCase.body;
                            if (aCase.fallThrough) {
                                var m = 1;
                                while (n + m < cases.length) {
                                    var nextCase = cases[n + m];
                                    haxe += '    ' + nextCase.body;
                                    if (!nextCase.fallThrough) break;
                                    m++;
                                }
                            }
                            if (!hasBrace) haxe += '} ';
                            n++;
                        }

                        haxe += '} break; }';

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
                                haxe += arrayType + 'Array2D.create(' + part1 + ', ' + part2 + ')';
                            }
                            else {
                                haxe += arrayType + 'Array.create(' + part1 + ')';
                            }
                        }
                        else {
                            i += word.length;
                            haxe += word;
                        }
                    }
                    else if (word == 'if' && cleanedAfter.substr(word.length).ltrim().startsWith('(')) {
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
                        //consumeExpression({ until: ')' });
                    }
                    else if (word == 'while' && cleanedAfter.substr(word.length).ltrim().startsWith('(')) {

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

                        if (continueToLabels.length > 0) {

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

                            for (item in continueToLabels) {
                                if (item.depth > 1) {
                                    haxe += ' ' + item.breakCode + ';';
                                }
                                else {
                                    haxe += ' ' + item.continueCode + ';';
                                }
                                item.depth--;
                            }

                        }

                    }
                    else if (word == 'for' && cleanedAfter.substr(word.length).ltrim().startsWith('(')) {

                        if (RE_FOREACH.match(cleanedAfter)) {
                            // For each (for (A a : B) ...)
                            i += RE_FOREACH.matched(0).length;
                            haxe += 'for (' + RE_FOREACH.matched(2) + ' in';
                            openParens++;
                            consumeExpression({ until: ')' });

                            if (continueToLabels.length > 0) {

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
                                    haxe = haxe.substring(0, haxe.length - 1);
                                    cleanedHaxe = cleanedHaxe.substring(0, haxe.length);
                                    haxe += '}';
                                }

                                for (item in continueToLabels) {
                                    if (item.depth > 1) {
                                        haxe += ' ' + item.breakCode + ';';
                                    }
                                    else {
                                        haxe += ' ' + item.continueCode + ';';
                                    }
                                    item.depth--;
                                }

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
                                            breakCode += '_goToLabel_' + RE_CONTINUE_OR_BREAK.matched(2) + ' = true; break;';
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
                                if (forIncrement.trim() != '') haxe += ' ' + forIncrement + '; }';
                                else haxe += ' }';
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
                                    haxe += forIncrement + '; }';
                                }
                                else {
                                    haxe += '}';
                                }
                            }

                            for (item in continueToLabels) {
                                if (item.depth > 1) {
                                    haxe += ' ' + item.breakCode + ';';
                                }
                                else {
                                    haxe += ' ' + item.continueCode + ';';
                                }
                                item.depth--;
                            }
                        }

                        /*println('inline: ' + isInline);
                        println('init: ' + forInit);
                        println('cond: ' + forCondition);
                        println('incr: ' + forIncrement);*/
                        //exit(0);

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

                            haxe += 'var ' + name;
                            if (type != null) {
                                haxe += ':' + type;
                            }

                            var end = RE_VAR.matched(3);
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
                                varType = null;
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
                    haxe = haxe.substring(0, haxe.length - 1);
                    haxe += endOfExpression.join(' ') + ' }';
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
                    if (inEnum && RE_ENUM_VALUE.match(after)) {
                        i += RE_ENUM_VALUE.matched(0).length;
                        var name = RE_ENUM_VALUE.matched(1);
                        name = name.charAt(0).toUpperCase() + name.substring(1);
                        haxe += 'var ' + name + ' = ' + inEnumValues.length;
                        var end = RE_ENUM_VALUE.matched(3);
                        if (end == '}') {
                            haxe += ';' + RE_ENUM_VALUE.matched(2);
                            i--;
                        }
                        else {
                            haxe += RE_ENUM_VALUE.matched(2) + ';';
                        }

                        inEnumValues.push(name);
                    }
                    else if (inClass && RE_DECL.match(after)) {

                        var modifiers = convertModifiers(RE_DECL.matched(1));

                        var keyword = RE_DECL.matched(2);

                        if (modifiers.exists('private') && keyword == 'class') {
                            haxe += 'private ';
                        }

                        if (keyword == 'class') {
                            inClass = true;
                            inSubClass = true;
                            subClassHasConstructor = false;
                            beforeSubClassBraces = openBraces;
                            haxe += keyword + ' ';
                        }
                        else if (keyword == 'interface') {
                            inInterface = true;
                            beforeInterfaceBraces = openBraces;
                            haxe += keyword + ' ';
                        }
                        else if (keyword == 'enum') {
                            inEnum = true;
                            inEnumValues = [];
                            beforeEnumBraces = openBraces;
                            haxe += '@:enum abstract ';
                        }

                        //println(keyword.toUpperCase() + ': ' + RE_DECL.matched(0));

                        var name = RE_DECL.matched(3);
                        if (keyword == 'enum') {
                            inEnumName = name;
                            haxe += name + '(Int) from Int to Int ';
                        } else {
                            haxe += name + ' ';
                        }

                        var extras = convertDeclExtras(RE_DECL.matched(4));
                        for (item in extras.classes) {
                            haxe += 'extends ' + item + ' ';
                        }
                        for (item in extras.interfaces) {
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

                        //println('PROPERTY: ' + RE_PROPERTY.matched(0));
                        var name = RE_PROPERTY.matched(3);

                        if (inEnum || skippedNames.exists(name)) {
                            haxe += '//';
                        }

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
                            consumeExpression({ until: ';', varType: type, isVarValue: true});
                        }
                        else if (end == ',') {
                            haxe += ';';
                            consumeExpression({ until: ';', varType: type});
                        }

                    }
                    else if (RE_CONSTRUCTOR.match(after)) {

                        //println('CONSTRUCTOR: ' + RE_CONSTRUCTOR.matched(0));

                        var skip = false;
                        for (key in skippedConstructors.keys()) {
                            if (key == rootType && cleanedCode(RE_CONSTRUCTOR.matched(3), { cleanSpaces: true }) == skippedConstructors.get(key)) {
                                haxe += '/*';
                                skip = true;
                                break;
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

                        //println('METHOD: ' + RE_METHOD.matched(0));

                        var modifiers = convertModifiers(RE_METHOD.matched(1));
                        var name = RE_METHOD.matched(3);

                        if (skippedNames.exists(name)) {
                            haxe += '/*';
                        }
                        
                        if (!inInterface && modifiers.exists('public')) {
                            haxe += 'public ';
                        }
                        if (!inInterface && modifiers.exists('protected')) {
                            haxe += 'public ';
                        }
                        if (!inInterface && modifiers.exists('private')) {
                            haxe += 'private ';
                        }
                        if (modifiers.exists('static')) {
                            haxe += 'static ';
                        }

                        var type = convertType(RE_METHOD.matched(2));
                        var args = convertArgs(RE_METHOD.matched(4));

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

                // Add import
                haxe += 'import ' + pack + ';';
                i += RE_IMPORT.matched(0).length;
            }
            // Class modifiers we don't want to keep
            else if (word != '' && RE_DECL.match(after)) {

                var modifiers = convertModifiers(RE_DECL.matched(1));

                var keyword = RE_DECL.matched(2);

                if (modifiers.exists('private') && keyword == 'class') {
                    haxe += 'private ';
                }

                if (keyword == 'class') {
                    inClass = true;
                    classHasConstructor = false;
                    beforeClassBraces = openBraces;
                    haxe += keyword + ' ';
                }
                else if (keyword == 'interface') {
                    inInterface = true;
                    beforeInterfaceBraces = openBraces;
                    haxe += keyword + ' ';
                }
                else if (keyword == 'enum') {
                    inEnum = true;
                    inEnumValues = [];
                    beforeEnumBraces = openBraces;
                    haxe += '@:enum abstract ';
                }

                //println(keyword.toUpperCase() + ': ' + RE_DECL.matched(0));

                var name = RE_DECL.matched(3);
                if (keyword == 'enum') {
                    inEnumName = name;
                    haxe += name + '(Int) from Int to Int ';
                } else {
                    haxe += name + ' ';
                }

                var extras = convertDeclExtras(RE_DECL.matched(4));
                for (item in extras.classes) {
                    haxe += 'extends ' + item + ' ';
                }
                for (item in extras.interfaces) {
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

        // Convert __CONTINUE__ to continue
        haxe = haxe.replace('__CONTINUE__', 'continue');

        // Convert catches
        haxe = haxe.replace('catch (Exception ex)', 'catch (ex:Dynamic)');

        // Per-file patches
        if (rootType == 'spine.AnimationStateData') {
            haxe = haxe.replace('class Key {', 'private class Key {');
            haxe = haxe.replace('setMix(fromName:String, toName:String, duration:Float)', 'setMixByName(fromName:String, toName:String, duration:Float)');
        }
        else if (rootType == 'spine.AnimationState') {
            haxe = haxe.replace('setAnimation(trackIndex:Int, animationName:String, loop:Bool)', 'setAnimationByName(trackIndex:Int, animationName:String, loop:Bool)');
            haxe = haxe.replace('addAnimation(trackIndex:Int, animationName:String, loop:Bool, delay:Float)', 'addAnimationByName(trackIndex:Int, animationName:String, loop:Bool, delay:Float)');
            haxe = haxe.replace('animationsChanged()', 'handleAnimationsChanged()');
        }
        else if (rootType == 'spine.Animation') {
            haxe = haxe.replace('binarySearch(values:FloatArray, target:Float, step:Int)', 'binarySearchWithStep(values:FloatArray, target:Float, step:Int)');
        }
        else if (rootType == 'spine.Skeleton') {
            haxe = haxe.replace('updateCache', 'cache');
            haxe = haxe.replace('cache()', 'updateCache()');
            haxe = haxe.replace('sortPathConstraintAttachment(skin:Skin, slotIndex:Int, slotBone:Bone)', 'sortPathConstraintAttachmentWithSkin(skin:Skin, slotIndex:Int, slotBone:Bone)');
            haxe = haxe.replace('updateWorldTransform(parent:Bone)', 'updateWorldTransformWithParent(parent:Bone)');
            haxe = haxe.replace('setSkin(skinName:String)', 'setSkinByName(skinName:String)');
            haxe = haxe.replace('getAttachment(slotName:String, attachmentName:String)', 'getAttachmentWithSlotName(slotName:String, attachmentName:String)');
        }
        else if (rootType == 'spine.IkConstraint') {
            haxe = haxe.replace('apply(bone:Bone, targetX:Float, targetY:Float, alpha:Float)', 'applyOne(bone:Bone, targetX:Float, targetY:Float, alpha:Float)');
            haxe = haxe.replace('apply(parent:Bone, child:Bone, targetX:Float, targetY:Float, bendDir:Int, alpha:Float)', 'applyTwo(parent:Bone, child:Bone, targetX:Float, targetY:Float, bendDir:Int, alpha:Float)');
        }
        else if (rootType == 'spine.Bone') {
            haxe = haxe.replace('updateWorldTransform(', 'updateWorldTransformWithData(');
            haxe = haxe.replace('updateWorldTransformWithData()', 'updateWorldTransform()');
            haxe = haxe.replace('setScale(scale:Float)', 'setScale2(scale:Float)');
        }
        else if (rootType == 'spine.SkeletonBounds') {
            haxe = haxe.replace('containsPoint(polygon:FloatArray, x:Float, y:Float)', 'polygonContainsPoint(polygon:FloatArray, x:Float, y:Float)');
            haxe = haxe.replace('intersectsSegment(polygon:FloatArray, x1:Float, y1:Float, x2:Float, y2:Float)', 'polygonIntersectsSegment(polygon:FloatArray, x1:Float, y1:Float, x2:Float, y2:Float)');
        }

        // Replace outside-of-for break outer;
        haxe = haxe.replace('break outer;', '{ _gotoLabel_outer = true; continue; }');

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
                subLines.push(line);
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

/// Utils

    static function replaceStart(str:String, from:String, to:String):String {

        if (str.startsWith(from)) {
            return to + str.substr(from.length);
        }

        return str;

    } //replaceStart

    static function deleteRecursive(path:String, ?except:String) {

        if (!FileSystem.exists(path)) {
            return;
        }
        else if (FileSystem.isDirectory(path)) {
            var hasException = false;
            for (name in FileSystem.readDirectory(path)) {
                if (except == null || name != except) {
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
        var result = '';
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
            private class KeyPool extends Pool<TrackEntry> {
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
        }
    ];

    static var skippedFiles:Map<String,Bool> = [
        'SkeletonRenderer.java' => true,
        'SkeletonBinary.java' => true,
        'utils/SkeletonActor.java' => true,
        'utils/SkeletonActorPool.java' => true
    ];

    static var skippedNames:Map<String,Bool> = [
        'hashCode' => true
    ];

    static var skippedConstructors:Map<String,String> = [
        'spine.AnimationState' => '', // Empty animation state
        'spine.Slot' => 'Slot slot,Bone bone', // Copy constructor
        'spine.Skeleton' => 'Skeleton skeleton', // Copy constructor
        'spine.TransformConstraint' => 'TransformConstraint constraint,Skeleton skeleton', // Copy constructor
        'spine.IkConstraint' => 'IkConstraint constraint,Skeleton skeleton', // Copy constructor
        'spine.PathConstraint' => 'PathConstraint constraint,Skeleton skeleton', // Copy constructor
        'spine.Bone' => 'Bone bone,Skeleton skeleton,Bone parent', // Copy constructor
        'spine.BoneData' => 'BoneData bone,BoneData parent' // Copy constructor
    ];

/// Regular expressions

    static var RE_WORD_SEP = ~/^[^a-zA-Z0-9_]/;
    static var RE_WORD = ~/^[a-zA-Z0-9_]+/;
    static var RE_STRING = ~/^(?:"(?:[^"\\]*(?:\\.[^"\\]*)*)"|'(?:[^'\\]*(?:\\.[^'\\]*)*)')/;
    static var RE_IMPORT = ~/^import\s+(static\s+)?([^;\s]+)\s*;/;
    static var RE_PROPERTY = ~/^((?:(?:public|private|protected|static|final|dynamic)\s+)+)?([a-zA-Z0-9,<>\[\]_]+)\s+([a-zA-Z0-9_]+)\s*(;|=|,)/;
    static var RE_CONSTRUCTOR = ~/^((?:(?:public|private|protected|final)\s+)+)?([a-zA-Z0-9,<>\[\]_]+)\s*\(\s*([^\)]*)\s*\)\s*{/;
    static var RE_METHOD = ~/^((?:(?:public|private|protected|static|final)\s+)+)?([a-zA-Z0-9,<>\[\]_]+)\s+([a-zA-Z0-9_]+)\s*\(\s*([^\)]*)\s*\)\s*({|;)/;
    static var RE_VAR = ~/^(?:([a-zA-Z0-9_\[\]]+(?:<[a-zA-Z0-9_,<>\[\]]*>)?)\s+)?([a-zA-Z0-9_]+)\s*(;|=|,)/;
    static var RE_DECL = ~/^((?:(?:public|private|protected|static|final|abstract)\s+)+)?(enum|interface|class)\s+([a-zA-Z0-9,<>\[\]_]+)((?:\s+(?:implements|extends)\s*(?:[a-zA-Z0-9,<>\[\]_]+)(?:\s*,\s*[a-zA-Z0-9,<>\[\]_]+)*)*)\s*{/;
    static var RE_HAXE_DECL = ~/^((?:(?:public|private|protected|static|final|abstract|@:enum)\s+)+)?(enum|interface|class|abstract)\s+([a-zA-Z0-9,<>\[\]_]+)/;
    static var RE_NEW_ARRAY = ~/^new\s+([a-zA-Z0-9_]+)\s*\[/;
    static var RE_NEW_INSTANCE = ~/^new\s+([a-zA-Z0-9_]+)\s*\((\s*\))?/;
    static var RE_SWITCH = ~/^switch\s*\(/;
    static var RE_CASE = ~/^(case|default)\s*(?:([^:]+)\s*)?:\s*/;
    static var RE_INSTANCEOF = ~/^([a-zA-Z0-9,<>\[\]_]+)\s+instanceof\s+([a-zA-Z0-9,<>\[\]_]+)/;
    static var RE_CAST = ~/^\(\s*([a-zA-Z0-9,<>\[\]_]+)\s*\)\s*([a-zA-Z0-9\[\]_]+(?:<[a-zA-Z0-9_,<>\[\]]*>)?)/;
    static var RE_CALL = ~/^([a-zA-Z0-9,<>\[\]_\.]+)\s*\(/;
    static var RE_NUMBER = ~/^((?:[0-9]+)\.?(?:[0-9]+)?)(f|F|d|D)/;
    static var RE_FOREACH = ~/^for\s*\(\s*([a-zA-Z0-9,<>\[\]_ ]+)\s+([a-zA-Z0-9_]+)\s*:/;
    static var RE_LABEL = ~/^(outer)\s*:/;
    static var RE_CONTINUE_OR_BREAK = ~/^(continue|break)(?:\s+(outer)\s*)?;/;
    static var RE_ENUM_VALUE = ~/^([a-zA-Z0-9_]+)(\s*)(,|;|\})/;
    static var RE_PARENT_CLASS_THIS = ~/^([a-zA-Z0-9_]+)(\s*)\.\s*this\s*\./;

} //Convert
