class UVModel {
  final double uv;

  UVModel({
    required this.uv,
  });

  factory UVModel.fromJson(Map<String, dynamic> json) {
    return UVModel(
      uv: (json['current']['uvi'] as num).toDouble(),
    );
  }

  String get level {
    if (uv <= 2) return "Low";
    if (uv <= 5) return "Moderate";
    if (uv <= 7) return "High";
    if (uv <= 10) return "Very High";
    return "Extreme";
  }
}