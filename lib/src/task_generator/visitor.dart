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

      if (source.contains('Retain')) {
        final params = getAnnatationParams(source, 'Retain');
        retainAnnatation.add(Annatation(element.name, params));
      } else if (source.contains('Logging')) {
        final params = getAnnatationParams(source, 'Logging');
        loggingAnnatation.add(Annatation(element.name, params));
      } else if (source.contains('Monitoring')) {
        final params = getAnnatationParams(source, 'Monitoring');
        monitoringAnnatation.add(Annatation(element.name, params));
      } else if (source.contains('NetworkSubscriber')) {
        final params = getAnnatationParams(source, 'NetworkSubscriber');
        networkSubscriberAnnatation.add(Annatation(element.name, params));
      } else if (source.contains('NetworkPublisher')) {
        final params = getAnnatationParams(source, 'NetworkPublisher');
        networkPublisherAnnatation.add(Annatation(element.name, params));
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
  final List<String> annationsParam;

  Annatation(this.fieldName, this.annationsParam);

  @override
  String toString() {
    return {'n': fieldName, 'ap': annationsParam}.toString();
  }
}



