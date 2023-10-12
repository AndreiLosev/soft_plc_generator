import 'package:analyzer/dart/element/element.dart';
import 'package:build/src/builder/build_step.dart';
import 'package:soft_plc_generator/src/task_generator/visitor.dart';
import 'package:source_gen/source_gen.dart';
import 'package:soft_plc/soft_plc.dart';

class TaskGenerator extends GeneratorForAnnotation<Task> {

  final buffer = StringBuffer();

  @override
  generateForAnnotatedElement(Element element, ConstantReader annotation, BuildStep buildStep) {
    final visitor = ModelVisitor();
    element.visitChildren(visitor);

    buffer.writeln("class \$${visitor.className} extends ${visitor.className} ${_getInterfaces(visitor)} {");

    _generateRetainProperty(visitor);

    buffer.write("}");

    // void setRetainProperties(Map<String, ReatainValue> properties);

    

    return buffer.toString();
  }

  void _generateRetainProperty(ModelVisitor visitor) {
    if (visitor.retainAnnatation.isEmpty) {
      return;
    }

    buffer.writeln('@override');
    buffer.writeln("Map<String, ReatainValue> getRetainProperty() {");
    buffer.writeln("return {");

    for (var item in visitor.retainAnnatation) {
        final retainValue = switch (item.annationsParam.isNotEmpty) {
          true => item.annationsParam.first,
          false => _standartRetainValue(visitor.fields[item.fieldName]!, item.fieldName),
        };

      buffer.writeln("\"${visitor.className}::${item.fieldName}\": $retainValue(${item.fieldName}),");
    }

    buffer.writeln("};");
    buffer.writeln("}");
    
    buffer.writeln('@override');
    buffer.writeln("void setRetainProperties(Map<String, ReatainValue> properties) {");
    buffer.writeln("for (final prop in properties.entries) {");
    buffer.writeln("switch (prop.key) {");

    for (var item in visitor.retainAnnatation) {
      buffer.writeln("case \"${visitor.className}::${item.fieldName}\":");
      buffer.writeln("${item.fieldName} = prop.value.value as ${visitor.fields[item.fieldName]};");
    }

    buffer.writeln("}\n}\n}");
  }

  String _getInterfaces(ModelVisitor visitor) {
    final interfaces = <String  >[];

    if (visitor.retainAnnatation.isNotEmpty) {
      interfaces.add("IRetainProperty");
    }

    if (visitor.loggingAnnatation.isNotEmpty) {
      interfaces.add("ILoggingProperty");
    }

    if (visitor.monitoringAnnatation.isNotEmpty) {
      interfaces.add("IMonitoringProperty");
    }

    if (visitor.networkSubscriberAnnatation.isNotEmpty) {
      interfaces.add("INetworkSubscriber");
    }

    if (visitor.networkPublisherAnnatation.isNotEmpty) {
      interfaces.add("INetworkPublisher");
    }

    if (interfaces.isEmpty) {
      return "";
    }

    return "implements ${interfaces.join(', ')}";
  }

  String _standartRetainValue(String type, String field) {
    print(type);
    final result = switch (type) {
      'bool' => 'ReatainBoolValue',
      'int' || 'float' => 'ReatainNumValue',
      'String' => 'ReatainStringValue',
      'List' => 'ReatainListValue<Object>',
      'Map' => 'ReatainValue<Map<String, Object>>',
      _ => throw Exception('''Retain value "$type $field" must be bool, int, float, List,
          Map or must be has custom ReatainValue class'''),
    };

    print([1, result]);

    if (result.startsWith('List')) {
      final generic = type.replaceFirst('List', '');
      return "$result$generic";
    }

    if (result.startsWith('Map')) {
      final generic = type.replaceFirst('Map', '');
      return "$result$generic";
    }

    return result;
  }
}
