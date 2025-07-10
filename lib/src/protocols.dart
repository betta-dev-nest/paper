import 'dart:async';

import 'package:flutter/widgets.dart';

enum MemberLife { init, initializing, absence }

abstract class Event {
  Event();
}

abstract class MemberBuilder {
  Unique get key;

  Member createMember();
}

abstract class Unique {
  Unique();
}

abstract class Member {
  Unique get key;

  MemberLife get lifeState;

  set lifeState(MemberLife state);

  MemberOperating? operator;

  FutureOr<void> init();

  FutureOr<void> dispose();

  Future<void> handle(Event event, dynamic cause);

  Future<Event?> handleReport(Event event, Unique child);

  FutureOr<Event?> report<E extends Event>();
}

abstract class MemberOperating {
  Future<void> buildRootWidget(Widget widget);

  void buildMemberSync(Member source, MemberBuilder builder);

  Future<void> buildMemberAsync(Member source, MemberBuilder builder);

  void disposeMember(Unique keys);

  void notifyEvent(Member member, Event event, dynamic cause);

  Future<void> processMember(Member source, Unique child, Event event);

  FutureOr<Event?> acquireEvent<E extends Event>(Unique child);
}
