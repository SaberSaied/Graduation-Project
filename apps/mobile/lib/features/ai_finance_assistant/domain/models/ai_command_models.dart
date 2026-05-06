class AICommandAction {
  final String type;
  final Map<String, dynamic> data;

  AICommandAction({required this.type, required this.data});

  factory AICommandAction.fromJson(Map<String, dynamic> json) {
    return AICommandAction(
      type: json['type'],
      data: json['data'],
    );
  }

  Map<String, dynamic> toJson() => {
    'type': type,
    'data': data,
  };
}

class AICommandResponse {
  final List<AICommandAction> actions;
  final String summary;

  AICommandResponse({required this.actions, required this.summary});

  factory AICommandResponse.fromJson(Map<String, dynamic> json) {
    return AICommandResponse(
      actions: (json['actions'] as List)
          .map((a) => AICommandAction.fromJson(a))
          .toList(),
      summary: json['summary'],
    );
  }
}
