import 'dart:async';

import 'package:flutter/widgets.dart';

import '../protocols.dart';
import '../utilities/assert_failure.dart';
import 'tree_layout_registry.dart';

final network = EventOperatorNetwork(
  memberRegistry: TreeLayoutRegistry<Unique, Member>(),
);

/// The infrastructure will maintain and operate a tree of member.
class EventOperatorNetwork implements MemberOperating {
  EventOperatorNetwork({required this.memberRegistry});

  /// The registry for managing and controlling the relationship as well as hierarchy of all members.
  final TreeLayoutRegistry<Unique, Member> memberRegistry;

  /// The indication used for determining whether [buildRootMember] has been called
  /// and a root member has been successfully constructed.
  ///
  /// If it is true, calling [buildRootMember] will do nothing.
  var _hasBuildRootObject = false;

  /// The api used for [EventOperatorNetwork]'s clients to start building the network with a root components via [builder].
  ///
  /// After successfully building the root object, [processRootMember] should be called to process the root with an [Event].
  ///
  /// [_hasBuildRootObject] will be verified to ensure [buildRootMember] has not been called before.
  /// if [_hasBuildRootObject] is true, the method will do nothing.
  Future<void> buildRootMember(MemberBuilder builder) async {
    if (_hasBuildRootObject) return;
    final member = builder.createMember();
    memberRegistry.saveRoot(builder.key, member);
    member.operator = this;
    await member.init();
    _hasBuildRootObject = true;
    member.lifeState = MemberLife.init;
  }

  /// The api used for [EventOperatorNetwork]'s clients to command the root member react with [event] or process it.
  ///
  /// This is usually called after [buildRootMember].
  ///
  /// Note that because the [buildRootMember] is asynchronous, it have to be awaited to be completed before calling [processRootMember]
  /// to ensure the root member is successfully constructed into the network and available to refer to. Otherwise [HasNotBuiltRootMember] will be thrown.
  Future<void> processRootMember(Event event) {
    final member = memberRegistry.root;
    assert(() {
      if (member == null) {
        throw HasNotBuiltRootMember();
      }
      return true;
    }());
    return member!.handle(event, null);
  }

  /// The indication used for determining whether [buildRootWidget] has been called
  /// and a root widget has been inflated by Flutter framework.
  ///
  /// If it is true, calling [buildRootWidget] will do nothing.
  var _hasBuildRootWidget = false;

  /// Derived from [MemberOperating]
  ///
  /// The api used for building a widget as a root.
  ///
  /// Basically, this method will cal [runApp] with input [widget] for the Flutter framework to inflate the [widget].
  ///
  /// If [_hasBuildRootWidget] is true, call [buildRootWidget] will do nothing to avoid the new root widget to be inflated.
  /// Please note there will no error or some thing wrong with calling [runApp] multiple times during app lifecycle.
  /// It is just to be avoided in this pattern because [buildRootWidget] or [runApp] might be called in any component of the network,
  /// which is not recommended following the rule of the pattern.
  /// For example, if behavior is allowed and a button widget call this api, a new root widget will be inflated in to widget tree (refer document of [runApp])
  /// That means a button is commanding the above component to do something, which is generally prohibited in this pattern.
  ///
  /// If there is need for the root widget to change its state similar to trigger [runApp], it should be operated by the root widget by itself, not by others.
  @override
  Future<void> buildRootWidget(Widget widget) {
    if (_hasBuildRootWidget == true) return Future(() {});

    final completer = Completer<void>();
    WidgetsFlutterBinding.ensureInitialized();

    /// [buildRootWidget] is counted as completed as the end of the frame finished.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _hasBuildRootWidget = true;
      completer.complete();
    });
    runApp(widget);
    return completer.future;
  }

  /// Derived from [MemberOperating]
  ///
  /// The api used for synchronously building a member via [builder] and assign it as a child of [source].
  ///
  /// The operation will execute the [Member.init] synchronously. Ensure desired member's [Member.init] is also synchronous to avoid concurrency issue.
  ///
  /// This api is primarily for building widget, which is has asynchronous-prohibited [State.initState] operation.
  /// In addition, the widget or render-related component will need to be synchronously constructed and inflated into screen.
  ///
  /// After the member is successfully constructed, the framework will change its [Member.lifeState] to [MemberLife.init].
  /// Because this is synchronous operation, there is no point of changing [Member.lifeState] to [MemberLife.initializing] like it does in [buildMemberAsync].
  @override
  void buildMemberSync(Member source, MemberBuilder builder) {
    final member = _createMember(source, builder);
    member.init();
    member.lifeState = MemberLife.init;
  }

  /// Derived from [MemberOperating]
  ///
  /// The api used for asynchronously building a member via [builder] and assign it as a child of [source].
  ///
  /// The operation will execute the [Member.init] asynchronously.
  ///
  /// This api is usually for non-widget-relate member in order to avoid blocking rendering processing of Flutter framework in case [Member.init] contains heavy computation.
  ///
  /// Before starting to build member, member's [Member.lifeState] will changed to [MemberLife.initializing] to reflect the correct state of life.
  /// After the member is successfully constructed, the framework will change its [Member.lifeState] to [MemberLife.init].
  @override
  Future<void> buildMemberAsync(Member source, MemberBuilder builder) async {
    final member = _createMember(source, builder);
    member.lifeState = MemberLife.initializing;
    await member.init();
    member.lifeState = MemberLife.init;
  }

  /// Derived from [MemberOperating]
  ///
  /// The api used for remove and dispose member who has corresponding [key].
  ///
  /// [includeChildren] indicates whether the framework should remove all children or descendants of the removed member.
  /// This is because when removing widget member, all its descendants will be disposed by Flutter framework as well.
  /// Therefore, it is the [State.dispose] will trigger [disposeMember] to the dispose the widget member itself.
  @override
  void disposeMember(Unique key) {
    memberRegistry.removeByKey(
      key,
      onObjectRemoved: requestMemberDispose,
    );
  }

  /// Derived from [MemberOperating]
  ///
  /// The api used by the members to send signal to the framework, indicating that they are in need to process the [event]
  /// due to some arise of reactions to changes of members' components themselves
  ///
  /// [member] argument is the member that want to process [event].
  ///
  /// [cause] argument indicates the source of changes. It tell [member] what components cause this reaction.
  ///
  /// An assertion error will thrown if [member] cannot by found in the [memberRegistry].
  /// It also means the [member] has not been constructed and registered.
  ///
  /// The [member] will be triggered to process [event] with [cause] by the framework.
  /// After that, a chain of reaction occurs after that via [EventLine] (refer to [EventLine] documents for the operations explanation).
  /// In general, the framework will look up the direct parent of [member] and trigger them process the [event] that [member] has process successfully via [Member.handleReport].
  /// The progress will repeat after the parent has successfully process the [event].
  @override
  void notifyEvent(Member member, Event event, dynamic cause) {
    assert(
      memberRegistry.containsObject(member),
      AssertFailure.infraError(
        object: runtimeType.toString(),
        member: 'notifyEvent',
        message:
            'The [member] has not been registered or been removed from the network.',
      ),
    );
    EventLine(_getParentOf).start(member, event, cause);
  }

  /// Derived from [MemberOperating]
  ///
  /// The api used by the [parent] to command its [child] to process [event].
  ///
  /// An assertion error will thrown if [parent] cannot by found in the [memberRegistry].
  /// It also means the [parent] has not been constructed and registered.
  @override
  Future<void> processMember(Member parent, Unique child, Event event) {
    final member = memberRegistry.objectOf(child);

    assert(
      member != null,
      AssertFailure.infraError(
        object: runtimeType.toString(),
        member: 'processMember',
        message:
            'The [child] has not been registered or been removed from the network.',
      ),
    );

    return member!.handle(event, null);
  }

  /// Derived from [MemberOperating]
  ///
  /// The api used by the [member] to ask its [child] to provide event type [E] as a report.
  @override
  FutureOr<Event?> acquireEvent<E extends Event>(Unique child) {
    return memberRegistry.objectOf(child)?.report<E>() ?? Future.value(null);
  }

  Member _createMember(Member parent, MemberBuilder builder) {
    final member = builder.createMember();
    memberRegistry.save(builder.key, member, under: parent);
    member.operator = this;
    return member;
  }

  void requestMemberDispose(Member member) {
    member.dispose();
    member.lifeState = MemberLife.absence;
  }

  Member? _getParentOf(Member member) {
    return memberRegistry.parentOf(member);
  }
}

class EventLine {
  EventLine(this.getParent);

  final Member? Function(Member member) getParent;

  Member? _member;
  Event? _event;

  void start(Member member, Event event, dynamic cause) {
    member.handle(event, cause).then((_) {
      _member = member;
      _event = event;
      Future(transferToParentBy);
    });
  }

  void transferToParentBy() {
    assert(() {
      if (_member == null || _event == null) {
        throw EventLineError(
          member: 'transferToParentBy',
          message:
              'The _member or _event are null or has not be assigned after completing a processing event',
        );
      }
      return true;
    }());

    // Stop the line when there is no more parent.
    final parent = getParent(_member!);
    if (parent == null) {
      _member = _event = null;
      return;
    }
    final key = _member!.key;
    _member = parent;
    parent.handleReport(_event!, key).then(onCompleteHandleReport);
  }

  void onCompleteHandleReport(Event? event) {
    if (event == null) {
      _member = _event = null;
      return;
    }
    _event = event;
    Future(transferToParentBy);
  }
}

class HasNotBuiltRootMember implements Exception {
  @override
  String toString() {
    return '''A root object has been constructed yet.
To avoid this error, ensure to build and inject a root object into the network via [EventOperatorNetwork.buildRootMember].
Remember to await the [buildRootMember] to complete before operating everything else.''';
  }
}

class EventLineError extends Error {
  final String member;
  final String message;

  EventLineError({required this.member, required this.message});

  @override
  String toString() {
    return Error.safeToString(
      AssertFailure.infraError(
        object: 'EventLine',
        member: member,
        message: message,
      ),
    );
  }
}
