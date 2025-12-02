class SlideOptionDTO {
  final int index;
  final String? text;
  final String? mediaUrl;

  SlideOptionDTO({required this.index, this.text, this.mediaUrl});
}

class SlideDTO {
  final String slideId;
  final String questionText;
  final String questionType;
  final int timeLimitSeconds;
  final String? mediaUrl;
  final List<SlideOptionDTO> options;

  SlideDTO({
    required this.slideId,
    required this.questionText,
    required this.questionType,
    required this.timeLimitSeconds,
    required this.options,
    this.mediaUrl,
  });
}
