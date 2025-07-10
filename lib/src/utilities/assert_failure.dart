class AssertFailure {
  static String infraError({
    required String object,
    required String member,
    required String message,
  }) {
    return 
'''Level:    Infrastructure
Object:   $object
Member:   $member
Message:  $message
This is an error caused by the framework, which is not supposed to get caught under application development.
Please create issue report to our Github.''';
  }
}
