

import 'package:analyzer/dart/element/element.dart';
import 'package:build/src/builder/build_step.dart';
import 'package:soft_plc_generator/src/debug_generator/visitor.dart';
import 'package:source_gen/source_gen.dart';
import 'package:soft_plc/soft_plc.dart';

class DebugGenerator extends GeneratorForAnnotation<Debug> {

  final buffer = StringBuffer();

  @override
  generateForAnnotatedElement(Element element, ConstantReader annotation, BuildStep buildStep) {
    final visitor = ModelVisitor();
    element.visitChildren(visitor);

    
    buffer.writeln('extension ${visitor.className}Debug on ${visitor.className} {');
    buffer.writeln('String getDebugValue() {');
    buffer.writeln("final \$c = JsonEncoder.withIndent('  ');");
    buffer.writeln('return \$c.convert({"${visitor.className}": {');

    for (final field in visitor.fields.keys) {
      buffer.writeln("'$field': $field.getDebugValue(),");
    }

    buffer.writeln('},');
    buffer.writeln('});');
    buffer.writeln('}');
    buffer.writeln('');
   
    buffer.writeln('void setDebugValue(String name, String value) {');
    buffer.writeln('switch (name) {');
    
    for (final field in visitor.fields.entries) {
      buffer.writeln('case "${field.key}"  :');
        if (visitor.iterable[field.key] ?? false) {
          handlerIterable(field);
        } else if (visitor.map[field.key] ?? false) {
          handlerMap(field);
        } else {
          buffer.writeln('${field.key} = jsonDecode(value);');
        }
    }

    buffer.writeln("}");
    buffer.writeln("}");

    buffer.writeln('}');

    return buffer.toString();
  }

  void handlerIterable(MapEntry<String, String> field) {
    buffer.writeln("final vArr = value.split(':');");
    buffer.writeln("switch (vArr[0]) {");
    buffer.writeln('case "add":');
    buffer.writeln('${field.key}.add(jsonDecode(vArr[1]));');
    buffer.writeln('case "addAll":');
    buffer.writeln('${field.key}.addAll(jsonDecode(vArr[1]));');
    buffer.writeln('case "remove":');
    buffer.writeln('${field.key}.remove(jsonDecode(vArr[1]));');
    buffer.writeln('default:');
    buffer.writeln("${field.key}[int.parse(vArr[0])] = jsonDecode(vArr[1]);");
    buffer.writeln('}');
  }

  void handlerMap(MapEntry<String, String> field) {
    buffer.writeln("final vArr = value.split(':');");
    buffer.writeln("switch (vArr[0]) {");
    buffer.writeln('case "addAll":');
    buffer.writeln('${field.key}.addAll(jsonDecode(vArr[1]));');
    buffer.writeln('case "remove":');
    buffer.writeln('${field.key}.remove(jsonDecode(vArr[1]));');
    buffer.writeln('default:');
    buffer.writeln("${field.key}[vArr[0]] = jsonDecode(vArr[1]);");
    buffer.writeln('}');
  }
}

