import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:ovorideuser/core/helper/shared_preference_helper.dart';
import 'package:ovorideuser/core/helper/string_format_helper.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:ovorideuser/core/route/route.dart';
import 'package:ovorideuser/core/utils/app_status.dart';
import 'package:ovorideuser/core/utils/audio_utils.dart';
import 'package:ovorideuser/core/utils/url_container.dart';
import 'package:ovorideuser/core/utils/util.dart';
import 'package:ovorideuser/data/controller/ride/ride_details/ride_details_controller.dart';
import 'package:ovorideuser/data/model/general_setting/general_setting_response_model.dart';
import 'package:ovorideuser/data/model/global/pusher/pusher_event_response_model.dart';
import 'package:ovorideuser/environment.dart';
import 'package:ovorideuser/presentation/components/snack_bar/show_custom_bid_toast.dart';
import 'package:pusher_channels_flutter/pusher_channels_flutter.dart';
import 'package:get/get.dart';
import 'package:ovorideuser/data/controller/ride/ride_meassage/ride_meassage_controller.dart';
import 'package:ovorideuser/data/services/api_service.dart';

class PusherRideController extends GetxController {
  ApiClient apiClient;
  RideMessageController controller;
  RideDetailsController detailsController;

  PusherRideController({
    required this.apiClient,
    required this.controller,
    required this.detailsController,
  });
  PusherChannelsFlutter pusher = PusherChannelsFlutter.getInstance();

  bool isPusherLoading = false;
  String appKey = '';
  String cluster = '';
  String token = '';
  String userId = '';
  String rideId = '';

  PusherConfig pusherConfig = PusherConfig();

  final events = [
    "pickup_ride", // (start ride)
    "message", // (for message)
    "live_location", // (update location)-> user/driver both
    "payment_complete", // (payment complete)
    "ride_end", // (ride end)
  ];

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
    rideId = rideId;
    update();

    printX('appKey ${pusherConfig.toJson()}');
    printX('appKey $appKey');
    printX('appKey $cluster');

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
      loggerX(e);
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
      loggerX("7787878778 $authUrl");
      http.Response result = await http.post(
        Uri.parse(authUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
          "dev-token": Environment.devToken,
        },
      );
      if (result.statusCode == 200) {
        Map<String, dynamic> json = jsonDecode(result.body);
        loggerX(json);
        return json;
      } else {
        return null; // or throw an exception
      }
    } catch (e) {
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
      loggerX(event.channelName);
      loggerX(event.eventName);
      if (event.data == null) return;
      PusherResponseModel model = PusherResponseModel.fromJson(
        jsonDecode(event.data),
      );
      final modify = PusherResponseModel(
        eventName: event.eventName,
        channelName: event.channelName,
        data: model.data,
      );
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
    printX('event.eventName ${event.eventName}');
    if (event.eventName.toString().toLowerCase() ==
        "ONLINE_PAYMENT_RECEIVED".toLowerCase()) {
      printX('event.eventName ${event.data?.rideId}');
      Get.offAndToNamed(
        RouteHelper.rideReviewScreen,
        arguments: event.data?.rideId ?? '',
      );
    } else if (event.eventName.toString().toLowerCase() ==
        "MESSAGE_RECEIVED".toLowerCase()) {
      if (event.data?.message != null) {
        loggerX('update msg <<<<< ${event.data?.rideId ?? ''}');
        controller.addEventMessage(event.data!.message!);
      }
    } else if (event.eventName.toString().toLowerCase() ==
        "LIVE_LOCATION".toLowerCase()) {
      if (detailsController.ride.status == AppStatus.RIDE_ACTIVE.toString()) {
        detailsController.mapController.updateDriverLocation(
          latLng: LatLng(
            Converter.formatDouble(
              event.data?.driverLatitude ?? '0',
              precision: 10,
            ),
            Converter.formatDouble(
              event.data?.driverLongitude ?? '0',
              precision: 10,
            ),
          ),
          isRunning: false,
        );
      }
    } else if (event.eventName.toString().toLowerCase() ==
        "NEW_BID".toLowerCase()) {
      if (event.data?.bid != null) {
        AudioUtils.playAudio(apiClient.getNotificationAudio());
        MyUtils.vibrate();
        CustomBidToast.newBid(
          bid: event.data!.bid!,
          currency: detailsController.currencySym,
          driverImagePath:
              '${detailsController.driverImagePath}/${event.data?.bid?.driver?.avatar}',
          serviceImagePath:
              '${detailsController.serviceImagePath}/${event.data?.service?.image}',
          totalRideCompleted: event.data?.driverTotalRide ?? '0',
          accepted: () {
            detailsController.acceptBid(event.data?.bid?.id ?? '');
          },
        );
      }
      detailsController.updateBidCount(false);
    } else if (event.eventName.toString().toLowerCase() ==
        "BID_REJECT".toLowerCase()) {
      detailsController.updateBidCount(true);
    } else if (event.eventName.toString().toLowerCase() ==
        "CASH_PAYMENT_RECEIVED".toLowerCase()) {
      detailsController.updatePaymentRequested(isRequested: false);
      if (event.data?.ride != null) {
        detailsController.updateRide(event.data!.ride!);
      }
    } else if (event.eventName.toString().toLowerCase() ==
            "PICK_UP".toLowerCase() ||
        event.eventName.toString().toLowerCase() == "RIDE_END".toLowerCase() ||
        event.eventName.toString().toLowerCase() ==
            "BID_ACCEPT".toLowerCase()) {
      if (event.data?.ride != null) {
        detailsController.updateRide(event.data!.ride!);
      }
    } else {
      if (event.data?.ride != null) {
        detailsController.updateRide(event.data!.ride!);
      }
    }
  }

  void clearData() {
    //   closePusher();
  }

  void closePusher() async {
    // await pusher.unsubscribe(channelName: "private-ride-$rideId");
    // await pusher.disconnect();
  }

  List<String> activeEventList = [
    "NEW_RIDE_CREATED",
    "RIDE_END",
    "NEW_BID",
    "PICK_UP",
  ];
}
