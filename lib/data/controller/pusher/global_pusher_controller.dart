import 'package:ovorideuser/core/helper/shared_preference_helper.dart';
import 'package:ovorideuser/core/helper/string_format_helper.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:ovorideuser/core/route/route.dart';
import 'package:ovorideuser/core/utils/url_container.dart';
import 'package:ovorideuser/data/model/general_setting/general_setting_response_model.dart';
import 'package:ovorideuser/data/model/global/pusher/pusher_event_response_model.dart';
import 'package:ovorideuser/environment.dart';
import 'package:pusher_channels_flutter/pusher_channels_flutter.dart';
import 'package:get/get.dart';
import 'package:ovorideuser/data/services/api_service.dart';

class GlobalPusherController extends GetxController {
  ApiClient apiClient;
  GlobalPusherController({required this.apiClient});
  PusherChannelsFlutter pusher = PusherChannelsFlutter.getInstance();

  bool isPusherLoading = false;
  String appKey = '';
  String cluster = '';
  String token = '';
  String userId = '';

  PusherConfig pusherConfig = PusherConfig();

  void subscribePusher() async {
    isPusherLoading = true;
    pusherConfig = apiClient.getPushConfig();
    appKey = pusherConfig.appKey ?? '';
    cluster = pusherConfig.cluster ?? '';
    token = apiClient.sharedPreferences.getString(
          SharedPreferenceHelper.accessTokenKey,
        ) ??
        '';
    userId = apiClient.sharedPreferences.getString(
          SharedPreferenceHelper.userIdKey,
        ) ??
        '';
    update();

    printX('pusherConfig ${pusherConfig.toJson()}');
    printX('appKey $appKey');
    printX('cluster $cluster');

    configure("private-rider-user-$userId");
    isPusherLoading = false;
    update();
  }

  Future<void> configure(String channelName) async {
    loggerI(appKey);
    loggerI(cluster);
    try {
      await pusher.init(
        apiKey: appKey,
        cluster: cluster,
        onEvent: onEvent,
        onSubscriptionError: onSubscriptionError,
        onError: onError,
        onSubscriptionSucceeded: onSubscriptionSucceeded,
        onConnectionStateChange: onConnectionStateChange,
        onMemberAdded: (channelName, member) {},
        onAuthorizer: onAuthorizer,
      );

      await pusher.subscribe(channelName: channelName);
      await pusher.connect();
    } catch (e) {
      printX(e);
    }
  }

  Future<Map<String, dynamic>?> onAuthorizer(
    String channelName,
    String socketId,
    options,
  ) async {
    try {
      String authUrl =
          "${UrlContainer.baseUrl}${UrlContainer.pusherAuthenticate}$socketId/$channelName";
      printX(authUrl);
      http.Response result = await http.post(
        Uri.parse(authUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
          "dev-token": Environment.devToken,
        },
      );
      printX("result<< ${result.body}");
      if (result.statusCode == 200) {
        Map<String, dynamic> json = jsonDecode(result.body);
        printX("json ${json.toString()}");
        return json;
      } else {
        return null; // or throw an exception
      }
    } catch (e) {
      printX("error<< $e");
      return null; // or throw an exception
    }
  }

  void onConnectionStateChange(
    dynamic currentState,
    dynamic previousState,
  ) async {
    printX("on connection state change $previousState $currentState");
  }

  void onEvent(PusherEvent event) {
    try {
      loggerI("glboal pusher event ${event.eventName}");
      PusherResponseModel model = PusherResponseModel.fromJson(
        jsonDecode(event.data),
      );
      final modify = PusherResponseModel(
        eventName: event.eventName,
        channelName: event.channelName,
        data: model.data,
      );
      if (event.data == null) return;
      if (activeEventList.contains(event.eventName.toLowerCase()) &&
          !isRidePage()) {
        Get.toNamed(
          RouteHelper.rideDetailsScreen,
          arguments: model.data?.ride?.id,
        );
      }
      updateEvent(modify);
    } catch (e) {
      printX(e);
    }
  }

  void onError(String message, int? code, dynamic e) {
    printX("onError: $message");
  }

  void onSubscriptionSucceeded(String channelName, dynamic data) {}

  void onSubscriptionError(String message, dynamic e) {
    printX("onSubscriptionError: $message");
  }

  //   --------------------------------Pusher Response --------------------------------

  updateEvent(PusherResponseModel event) {
    loggerX('global pusher ${event.eventName}');
    if (activeEventList.contains(event.eventName) && !isRidePage()) {
      loggerI("event.data?.ride?.id | ${event.data?.bid?.id}");
      if (event.eventName.toString().toLowerCase() == "NEW_BID".toLowerCase()) {
        Get.toNamed(
          RouteHelper.rideDetailsScreen,
          arguments: event.data?.bid?.rideId,
        );
      } else {
        Get.toNamed(
          RouteHelper.rideDetailsScreen,
          arguments: event.data?.ride?.id,
        );
      }
    }
  }

  void closePusher() async {
    // await pusher.unsubscribe(channelName: "private-ride-$rideId");
    // await pusher.disconnect();
  }

  bool isRidePage() {
    return Get.currentRoute == RouteHelper.rideDetailsScreen;
  }

  List<String> activeEventList = [
    "NEW_RIDE_CREATED",
    "RIDE_END",
    "PICK_UP",
    "CASH_PAYMENT_RECEIVED",
    "NEW_BID",
  ];
}
