import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/dart/element/visitor.dart';
import 'package:analyzer/dart/element/element.dart';

class ModelVisitor extends SimpleElementVisitor<void> {
  late String className;
  final fields = <String, String>{};
  final iterable = <String, bool>{};
  final map = <String, bool>{};

  @override
  void visitConstructorElement(ConstructorElement element) {
    final elementReturnType = element.type.returnType.toString();
    className = elementReturnType;
  }

  @override
  void visitFieldElement(FieldElement element) {
    final elementType = element.type.toString();
    fields[element.name] = elementType;
    iterable[element.name] = isIterable(element.type);
    map[element.name] = element.type.toString().contains('Map');
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
}



