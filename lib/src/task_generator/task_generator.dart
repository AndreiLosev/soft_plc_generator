import 'dart:math';

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

    buffer.writeln("class \$${visitor.className} extends ${visitor.className} ${getInterfaces(visitor)} {");

    _generateRetainProperty(visitor);
    _generateLoggingProperty(visitor);
    _generateMonitoringProperty(visitor);

    buffer.write("}");

    return buffer.toString();
  }

  String getInterfaces(ModelVisitor visitor) {
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


  void _generateMonitoringProperty(ModelVisitor visitor) {
    if (visitor.monitoringAnnatation.isEmpty) {
      return;
    }

    final eventIds = <String, String>{};

    buffer.writeln("@override");
    buffer.writeln("Event getEventById(String id) {");
    buffer.writeln("return switch (id) {");

    for (var item in visitor.monitoringAnnatation) {
      final eventType = item.annationsParam['eventType'];
      final eventParams = item.annationsParam['eventParams'];
      final eventFactory = item.annationsParam['eventFactory'];

      if (eventParams != null && eventFactory != null) {
        throw Exception("use eventFactory xor eventParams for  ${visitor.className}::${item.fieldName}");
      }

      final eventId = "\"${visitor.className}::${item.fieldName}_${Random().nextInt(9999)}\"";
      eventIds[item.fieldName] = eventId;

      if (eventFactory != null) {
        final method = visitor.methods.firstWhere(
          (e) => e.name == eventFactory, 
          orElse: () => throw Exception(
            "if use eventFactory, class:  ${visitor.className} mast be have method $eventFactory",
          ), 
        );

        if (method.returnType != eventType) {
          throw Exception(
            "method ${visitor.className}::$eventFactory must be return type $eventType",
          );
        }

        buffer.writeln("$eventId => $eventFactory(),");
        continue;
      }

      if (eventParams != null) {
        buffer.writeln("$eventId => $eventType$eventParams,");
        continue;
      }

      buffer.writeln("$eventId => $eventType($item.fieldName),");        
    }

    buffer.writeln("_ => throw Exception('This is not possible, for ${visitor.className}::getEventById(String id)')");

    buffer.writeln("};");
    buffer.writeln("}");

    buffer.writeln("@override");
    buffer.writeln("List<(String, Object)> getEventValues() {");
    buffer.writeln("return [");

    for (var item in visitor.monitoringAnnatation) {

      final eventId = eventIds[item.fieldName];
      buffer.writeln("($eventId, ${item.fieldName}),");
    }

    buffer.writeln("];");
    buffer.writeln("}");
  }

  void _generateRetainProperty(ModelVisitor visitor) {
    if (visitor.retainAnnatation.isEmpty) {
      return;
    }

    buffer.writeln('@override');
    buffer.writeln("Map<String, ReatainValue> getRetainProperty() {");
    buffer.writeln("return {");

    for (var item in visitor.retainAnnatation) {
        final retainValue = switch (item.annationsParam['reatainValueType']) {
          null => _standartRetainValue(visitor.fields[item.fieldName]!, item.fieldName),
          _ => item.annationsParam['reatainValueType'],
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

  void _generateLoggingProperty(ModelVisitor visitor) {
    if (visitor.loggingAnnatation.isEmpty) {
      return;
    }

    buffer.writeln('@override');
    buffer.writeln("Map<String, Object> getLoggingProperty() {");
    buffer.writeln("return {");

    for (var item in visitor.loggingAnnatation) {
      buffer.writeln("\"${visitor.className}::${item.fieldName}\": ${item.fieldName},");
    }

    buffer.writeln("};");
    buffer.writeln("}");

  }

  String _standartRetainValue(String type, String field) {
    final result = switch (type) {
      'bool' => 'ReatainBoolValue',
      'int' || 'float' => 'ReatainNumValue',
      'String' => 'ReatainStringValue',
      'List' => 'ReatainListValue<Object>',
      'Map' => 'ReatainValue<Map<String, Object>>',
      _ => throw Exception('''***   ***   ***   ***   ***   ***   ***
          Retain value "$type $field" must be bool, int, float, List,
          Map or must be has custom ReatainValue class
    ***   ***   ***   ***   ***   ***   ***  ***   ***'''),
    };

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
