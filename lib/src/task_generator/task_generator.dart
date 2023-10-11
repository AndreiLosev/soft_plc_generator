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
    buffer.writeln("// ${visitor.className}");
    buffer.writeln("// ${visitor.fields}");

    buffer.writeln("// ${visitor.methods}");
    buffer.writeln("// retain: ${visitor.retainAnnatation}");
    buffer.writeln("// logging: ${visitor.loggingAnnatation}");
    buffer.writeln("// monitoring: ${visitor.monitoringAnnatation}");
    buffer.writeln("// network: ${visitor.networkPublisherAnnatation}");
    buffer.writeln("// ${visitor.networkPublisherAnnatation}");

    return buffer.toString();
  }
}
