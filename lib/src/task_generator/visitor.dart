import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/dart/element/visitor.dart';
import 'package:analyzer/dart/element/element.dart';

class ModelVisitor extends SimpleElementVisitor<void> {
  late String className;
  final fields = <String, String>{};
  final methods = <MethodProperty>[];
  final retainAnnatation = <Annatation>[];
  final loggingAnnatation = <Annatation>[];
  final monitoringAnnatation = <Annatation>[];
  final networkSubscriberAnnatation = <Annatation>[];
  final networkPublisherAnnatation = <Annatation>[];

  @override
  void visitConstructorElement(ConstructorElement element) {
    final elementReturnType = element.type.returnType.toString();
    className = elementReturnType;
  }

  @override
  void visitFieldElement(FieldElement element) {
    final elementType = element.type.toString();
    fields[element.name] = elementType;

    for (var annatation in element.metadata) {
      final source = annatation.toSource();
      final constR = annatation.computeConstantValue();
      if (source.contains('Retain')) {

        final reatainValueType = constR?.getField('reatainValueType')?.toTypeValue()?.toString().replaceFirst("*", "");
        retainAnnatation.add(Annatation(element.name, {'reatainValueType': reatainValueType}));

      } else if (source.contains('Logging')) {

        loggingAnnatation.add(Annatation(element.name, {}));

      } else if (source.contains('Monitoring')) {

        final eventType = constR?.getField('eventType')?.toTypeValue()?.toString().replaceFirst("*", "");
        final eventParams = constR?.getField('eventParams')?.toListValue()?.map((e) => e.toStringValue()?.toString()).toString();
        final eventFactory = constR?.getField('eventFactory')?.toStringValue()?.toString().replaceFirst("*", "");
        monitoringAnnatation.add(Annatation(element.name, {
          'eventType': eventType,
          'eventParams': eventParams,
          'eventFactory': eventFactory,
        }));

      } else if (source.contains('NetworkSubscriber')) {

        final topic = constR?.getField('topic')?.toStringValue()?.toString().replaceFirst('*', '');
        final type = constR?.getField('type')?.getField('_name')?.toStringValue()?.toString();
        final factory = constR?.getField('factory')?.toStringValue()?.toString().replaceFirst("*", "");
        final bigEndian = constR?.getField('bigEndian')?.toBoolValue()?.toString().replaceFirst("*", '');
        networkSubscriberAnnatation.add(Annatation(element.name, {
          'topic': topic,
          'type': type,
          'factory': factory,
          'bigEndian': bigEndian,
        }));

      } else if (source.contains('NetworkPublisher')) {
        
        final topic = constR?.getField('topic')?.toStringValue()?.toString().replaceFirst('*', '');
        final type = constR?.getField('type')?.getField('_name')?.toStringValue()?.toString();
        final factory = constR?.getField('factory')?.toStringValue()?.toString().replaceFirst("*", "");
        final bigEndian = constR?.getField('bigEndian')?.toBoolValue()?.toString().replaceFirst("*", '');

        networkPublisherAnnatation.add(Annatation(element.name, {
          'topic': topic,
          'type': type,
          'factory': factory,
          'bigEndian': bigEndian,
        }));
      }
    }
  }

  Iterable<DartType> getSubTypes(DartType type) {
    final element = type.element;
    if (element is ClassElement) {
      return element.allSupertypes;
    }
    return const [];
  }

  bool isIterable(DartType type) {
    final element = type.element;
    if (element is ClassElement) {
      return element.allSupertypes.map((e) => e.toString()).contains('Iterable<E>');
    }

    return false;
  }

  @override
  void visitMethodElement(MethodElement element) {
    methods.add(MethodProperty(
      element.name,
      element.parameters.map((e) => e.type.toString()).toList(),
      element.returnType.toString(),
    ));  
  }

  List<String> getAnnatationParams(String source, String annatationType) {
    return source
      .replaceFirst('@', '')
      .replaceFirst(annatationType, '')
      .replaceFirst('(', '')
      .replaceFirst(")", '')
      .split(',')
      .map((e) => e.trim())
      .where((e) => e.isNotEmpty)
      .toList()
    ;
  }
}


class MethodProperty {
  final String name;
  final List<String> params;
  final String returnType;

  MethodProperty(this.name, this.params, this.returnType);

  @override
  String toString() {
    return {'n': name, 'p': params, 'r': returnType}.toString();
  }
}

class Annatation {
  final String fieldName;
  final Map<String, String?> annationsParam;

  Annatation(this.fieldName, this.annationsParam);

  @override
  String toString() {
    return {'n': fieldName, 'ap': annationsParam}.toString();
  }
}



