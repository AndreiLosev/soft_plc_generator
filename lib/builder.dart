import 'package:build/build.dart';
import 'package:soft_plc_generator/src/debug_generator/debug_generator.dart';
import 'package:soft_plc_generator/src/task_generator/task_generator.dart';
import 'package:source_gen/source_gen.dart';

Builder debugGenerator(BuilderOptions options) =>
    SharedPartBuilder([DebugGenerator()], 'debug_generator');

Builder taskGenerator(BuilderOptions options) =>
    SharedPartBuilder([TaskGenerator()], 'task_generator');
