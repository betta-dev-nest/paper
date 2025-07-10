import 'package:flutter/widgets.dart';

abstract class Controller<T extends State<StatefulWidget>>
    extends LabeledGlobalKey<T> {
  Controller({String? debugLabel}) : super(debugLabel);

  bool get isAlive => currentState != null;
}
