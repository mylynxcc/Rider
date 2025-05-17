import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:ovorideuser/core/helper/string_format_helper.dart';
import 'package:ovorideuser/presentation/packages/flutter_polyline_points/flutter_polyline_points.dart';
import 'package:ovorideuser/presentation/packages/flutter_polyline_points/src/new_route_cordinate_model.dart';

class NetworkUtil {
  static const String STATUS_OK = "ok";

  ///Get the encoded string from google directions api
  ///
  Future<List<PolylineResult>> getRouteBetweenCoordinates({
    required PolylineRequest request,
    String? googleApiKey,
    bool isOldAPI = true,
  }) async {
    List<PolylineResult> results = [];

    if (!isOldAPI) {
      var response = await http.post(
        Uri.parse("https://routes.googleapis.com/directions/v2:computeRoutes"),
        headers: {
          "content-type": "application/json",
          "X-Goog-Api-Key": 'AIzaSyBzPAOJe47juNZGx2isaFHvRpUtnH5_y3c',
          "X-Goog-FieldMask":
              "routes.distanceMeters,routes.duration,routes.polyline.encodedPolyline",
        },
        body: jsonEncode({
          "origin": {
            "location": {
              // "latLng": {"latitude": request.origin.latitude, "longitude": request.origin.longitude}
              "latLng": {"latitude": 28.66, "longitude": 77.23},
            },
          },
          "destination": {
            "location": {
              // "latLng": {"latitude": request.destination.latitude, "longitude": request.destination.latitude}
              "latLng": {"latitude": 28.79, "longitude": 77.05},
            },
          },
          "travelMode": "DRIVE",
          "routingPreference": "TRAFFIC_AWARE",
        }),
      );

      if (response.statusCode == 200) {
        NewRouteCordinateModel model = NewRouteCordinateModel.fromJson(
          jsonDecode(response.body),
        );

        //   lines.map((point) => LatLng(point.latitude, point.longitude)).toList();
        if (model.routes != null && model.routes!.isNotEmpty) {
          List<RouteCordinate> routeList = model.routes!;
          for (var route in routeList) {
            List<PointLatLng> lines = PolylinePoints().decodePolyline(
              route.polyline?.encodedPolyline ?? '',
            );
            // for (var i = 0; i < lines.length; i++) {
            //   printX("ROUTE LAT -${lines[i].latitude} LONG -${lines[i].longitude}");
            // }
            results.add(
              PolylineResult(
                // points: PolylineDecoder.run(route.polyline?.encodedPolyline ?? ''),
                points: lines,
                errorMessage: "",
                status: "OK",
                alternatives: [],
                overviewPolyline: route.polyline?.encodedPolyline,
              ),
            );
          }
          printX("routes>> ${results[0].status}");
        } else {
          throw Exception("Unable to get route: Response ---> ${500} ");
        }
      }
      return results;
    } else {
      var response = await http.get(
        request.toUri(apiKey: googleApiKey),
        headers: request.headers,
      );

      printX("url>> ${response.request?.url}");
      if (response.statusCode == 200) {
        var parsedJson = json.decode(response.body);
        printX("response of cordinate>> $parsedJson");
        if (parsedJson["status"]?.toLowerCase() == STATUS_OK &&
            parsedJson["routes"] != null &&
            parsedJson["routes"].isNotEmpty) {
          List<dynamic> routeList = parsedJson["routes"];
          for (var route in routeList) {
            results.add(
              PolylineResult(
                points: PolylineDecoder.run(
                  route["overview_polyline"]["points"],
                ),
                errorMessage: "",
                status: parsedJson["status"],
                totalDistanceValue: route['legs']
                    .map((leg) => leg['distance']['value'])
                    .reduce((v1, v2) => v1 + v2),
                distanceTexts: <String>[
                  ...route['legs'].map((leg) => leg['distance']['text']),
                ],
                distanceValues: <int>[
                  ...route['legs'].map((leg) => leg['distance']['value']),
                ],
                overviewPolyline: route["overview_polyline"]["points"],
                totalDurationValue: route['legs']
                    .map((leg) => leg['duration']['value'])
                    .reduce((v1, v2) => v1 + v2),
                durationTexts: <String>[
                  ...route['legs'].map((leg) => leg['duration']['text']),
                ],
                durationValues: <int>[
                  ...route['legs'].map((leg) => leg['duration']['value']),
                ],
                endAddress: route["legs"].last['end_address'],
                startAddress: route["legs"].first['start_address'],
              ),
            );
          }
        } else {
          throw Exception(
            "Unable to get route: Response ---> ${parsedJson["status"]} ",
          );
        }
      }
      return results;
    }
  }
}
