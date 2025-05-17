// To parse this JSON data, do
//
//     final newRouteCordinateModel = newRouteCordinateModelFromJson(jsonString);

class NewRouteCordinateModel {
  final List<RouteCordinate>? routes;

  NewRouteCordinateModel({this.routes});

  factory NewRouteCordinateModel.fromJson(Map<String, dynamic> json) =>
      NewRouteCordinateModel(
        routes: json["routes"] == null
            ? []
            : List<RouteCordinate>.from(
                json["routes"]!.map((x) => RouteCordinate.fromJson(x)),
              ),
      );

  Map<String, dynamic> toJson() => {
        "routes": routes == null
            ? []
            : List<dynamic>.from(routes!.map((x) => x.toJson())),
      };
}

class RouteCordinate {
  final int? distanceMeters;
  final String? duration;
  final Polyline? polyline;

  RouteCordinate({this.distanceMeters, this.duration, this.polyline});

  factory RouteCordinate.fromJson(Map<String, dynamic> json) => RouteCordinate(
        distanceMeters: json["distanceMeters"],
        duration: json["duration"],
        polyline: json["polyline"] == null
            ? null
            : Polyline.fromJson(json["polyline"]),
      );

  Map<String, dynamic> toJson() => {
        "distanceMeters": distanceMeters,
        "duration": duration,
        "polyline": polyline?.toJson(),
      };
}

class Polyline {
  final String? encodedPolyline;

  Polyline({this.encodedPolyline});

  factory Polyline.fromJson(Map<String, dynamic> json) =>
      Polyline(encodedPolyline: json["encodedPolyline"]);

  Map<String, dynamic> toJson() => {"encodedPolyline": encodedPolyline};
}
