import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:ovorideuser/core/route/route.dart';
import 'package:ovorideuser/core/utils/helper.dart';
import 'package:ovorideuser/core/utils/my_color.dart';
import 'package:ovorideuser/core/utils/my_images.dart';
import 'package:ovorideuser/data/model/global/response_model/response_model.dart';
import 'package:ovorideuser/data/model/location/selected_location_info.dart';
import 'package:ovorideuser/environment.dart';
import 'package:ovorideuser/presentation/components/snack_bar/show_custom_snackbar.dart';
import 'package:ovorideuser/presentation/packages/flutter_polyline_points/flutter_polyline_points.dart';
import 'package:ovorideuser/presentation/packages/polyline_animation/polyline_animation_v1.dart';

import '../../../core/helper/string_format_helper.dart';
import '../../../core/utils/my_strings.dart';
import '../../model/location/place_details.dart';
import '../../model/location/prediction.dart';
import '../../repo/location/location_search_repo.dart';
import '../home/home_controller.dart';

class SelectLocationController extends GetxController {
  LocationSearchRepo locationSearchRepo;
  int index;
  SelectLocationController({
    required this.locationSearchRepo,
    required this.index,
  });

  changeIndex(int i) {
    index = i;
    update();
  }

  LatLng pickupLatlong = LatLng(0, 0);
  LatLng destinationLatlong = LatLng(0, 0);

  Position? currentPosition;
  final currentAddress = "".obs;
  double selectedLatitude = 0.0;
  double selectedLongitude = 0.0;

  bool isLoading = false;
  bool isLoadingFirstTime = false;

  HomeController homeController = Get.find();
  TextEditingController searchLocationController = TextEditingController(
    text: '',
  );
  TextEditingController valueOfLocation = TextEditingController(text: '');
  TextEditingController destinationController = TextEditingController(text: '');
  TextEditingController pickUpController = TextEditingController(text: '');
  FocusNode searchFocus = FocusNode();

  clearTextFiled(int index) {
    if (index == 0) {
      pickUpController.text = '';
    } else {
      destinationController.text = '';
    }
  }

  final PolylineAnimator animator = PolylineAnimator();
  void initialize() async {
    loggerX(
      "homeController.selectedLocations.length ${homeController.selectedLocations.length}",
    );
    if (homeController.selectedLocations.isNotEmpty) {
      pickupLatlong = LatLng(
        homeController.getSelectedLocationInfoAtIndex(0)?.latitude ?? 0,
        homeController.getSelectedLocationInfoAtIndex(0)?.longitude ?? 0,
      );

      pickUpController.text = homeController
              .getSelectedLocationInfoAtIndex(0)
              ?.getFullAddress(showFull: true) ??
          '';
      if (homeController.selectedLocations.length > 1) {
        destinationController.text = homeController
                .getSelectedLocationInfoAtIndex(1)
                ?.getFullAddress(showFull: true) ??
            '';
        destinationLatlong = LatLng(
          homeController.getSelectedLocationInfoAtIndex(1)?.latitude ?? 0,
          homeController.getSelectedLocationInfoAtIndex(1)?.longitude ?? 0,
        );
      }
      if (homeController.selectedLocations.length > 1) {
        getPolylinePoints().then((v) {
          generatePolyLineFromPoints(v);
          // animator.animatePolyline(
          //   v,
          //   'polyline_id',
          //   MyColor.colorYellow,
          //   MyColor.primaryColor,
          //   polylines,
          //   () {
          //     update();
          //   },
          // );
        });
      }
      await setCustomMarkerIcon();
    }
    loggerX(destinationLatlong.toJson());
    getCurrentPosition(isLoading1stTime: true, pickupLocationForIndex: index);
  }

  Future<bool> handleLocationPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      await Geolocator.openLocationSettings();
      CustomSnackBar.error(errorList: [MyStrings.locationServiceDisableMsg]);
      return Future.value(false);
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        CustomSnackBar.error(errorList: [MyStrings.locationPermissionDenied]);
        return false;
      }
    }
    if (permission == LocationPermission.deniedForever) {
      await Geolocator.openAppSettings();
      CustomSnackBar.error(
        errorList: [MyStrings.locationPermissionPermanentDenied],
      );
      return false;
    }

    return true;
  }

  int curPosCalled = 1;
  Future<void> getCurrentPosition({
    isLoading1stTime = false,
    int pickupLocationForIndex = -1,
  }) async {
    if (isLoading1stTime) {
      isLoadingFirstTime = true;
    } else {
      isLoadingFirstTime = false;
    }
    isLoading = true;

    update();

    final hasPermission = await handleLocationPermission();
    if (!hasPermission) {
      return;
    }

    var getSelectLocationData = homeController.getSelectedLocationInfoAtIndex(
      pickupLocationForIndex,
    );
    if (getSelectLocationData == null) {
      pickupLocationForIndex = -1;
    } else {
      pickupLocationForIndex = pickupLocationForIndex;
    }

    if (pickupLocationForIndex == -1) {
      // ignore: deprecated_member_use
      await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      ).then((value) {
        currentPosition = value;
      });
    }

    if (currentPosition != null && getSelectLocationData == null) {
      changeCurrentLatLongBasedOnCameraMove(
        currentPosition!.latitude,
        currentPosition!.longitude,
      );
      update();
      animateMapCameraPosition();
    } else {
      changeCurrentLatLongBasedOnCameraMove(
        getSelectLocationData!.latitude!,
        getSelectLocationData.longitude!,
      );
      update();
      animateMapCameraPosition();
    }

    isLoading = false;
    isLoadingFirstTime = false;
    update();
  }

  LatLng getInitialTargetLocationForMap({int pickupLocationForIndex = -1}) {
    var getSelectLocationData = homeController.getSelectedLocationInfoAtIndex(
      pickupLocationForIndex,
    );
    if (getSelectLocationData == null) {
      return currentPosition != null
          ? LatLng(currentPosition!.latitude, currentPosition!.longitude)
          : const LatLng(37.0902, 95.7129);
    } else {
      return LatLng(
        getSelectLocationData.latitude!,
        getSelectLocationData.longitude!,
      );
    }
  }

  Future<void> openMap(double latitude, double longitude) async {
    await placemarkFromCoordinates(latitude, longitude)
        .then((List<Placemark> placeMark) {
      Placemark placemark = placeMark[0];
      loggerX(placemark.toJson());
      currentAddress.value =
          '${placemark.street} ${placemark.subLocality ?? ''}, ${placemark.locality ?? ''}, ${placemark.subAdministrativeArea ?? ''}, ${placemark.administrativeArea ?? ''}, ${placemark.country ?? ''}';
      update();
      printX(
        "selectedAddressFromSearch.isEmpty ${selectedAddressFromSearch.isEmpty}",
      );
      if (index == 0) {
        pickUpController.text = selectedAddressFromSearch.isEmpty ||
                Get.currentRoute == RouteHelper.editLocationPickUpScreen
            ? currentAddress.value
            : selectedAddressFromSearch;
        pickupLatlong = LatLng(latitude, longitude);
      } else {
        destinationController.text = selectedAddressFromSearch.isEmpty ||
                Get.currentRoute == RouteHelper.editLocationPickUpScreen
            ? currentAddress.value
            : selectedAddressFromSearch;
        destinationLatlong = LatLng(latitude, longitude);
      }
      homeController.addLocationAtIndex(
        SelectedLocationInfo(
          latitude: latitude,
          longitude: longitude,
          fullAddress: selectedAddressFromSearch.isEmpty ||
                  Get.currentRoute == RouteHelper.editLocationPickUpScreen
              ? currentAddress.value
              : selectedAddressFromSearch,
        ),
        index,
      );
      getPolylinePoints().then((v) {
        generatePolyLineFromPoints(v);
        // animator.animatePolyline(
        //   v,
        //   'polyline_id',
        //   MyColor.colorYellow,
        //   MyColor.primaryColor,
        //   polylines,
        //   () {
        //     update();
        //   },
        // );
      });
      setCustomMarkerIcon();
    }).catchError((e) {
      printX(e.toString());
      animateMapCameraPosition();
    });
  }

  void changeCurrentLatLongBasedOnCameraMove(
    double selectedLatitude,
    double selectedLongitude,
  ) {
    this.selectedLatitude = selectedLatitude;
    this.selectedLongitude = selectedLongitude;

    update();
  }

  GoogleMapController? mapController;
  animateMapCameraPosition() {
    mapController?.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: LatLng(selectedLatitude, selectedLongitude),
          zoom: 18,
        ),
      ),
    );
  }

  Future<void> pickLocation() async {
    await openMap(selectedLatitude, selectedLongitude);
  }

  clearSearchField() {
    allPredictions = [];
    searchLocationController.clear();
    update();
  }

  //ADDRESS   search+
  String selectedAddressFromSearch = '';
  updateSelectedAddressFromSearch(String address) {
    selectedAddressFromSearch = address;
    update();
  }

  bool isSearched = false;
  List<Prediction> allPredictions = [];

  Future<void> searchYourAddress({String locationName = ''}) async {
    isSearched = true;
    update();
    try {
      ResponseModel? response;
      PlacesAutocompleteResponse? subscriptionResponse;
      if (locationName.isNotEmpty) {
        allPredictions.clear();
        response = await locationSearchRepo.searchAddressByLocationName(
          text: locationName,
        );

        subscriptionResponse = PlacesAutocompleteResponse.fromJson(
          jsonDecode(response!.responseJson),
        );
      } else {
        allPredictions.clear();
        return;
      }
      if (subscriptionResponse.predictions!.isNotEmpty) {
        allPredictions.clear();
        allPredictions.addAll(subscriptionResponse.predictions!);
      }
      isSearched = false;
      update();
    } catch (e) {
      printX(e.toString());
    }
  }

  Future<LatLng?> getLangAndLatFromMap(Prediction prediction) async {
    try {
      ResponseModel response =
          await locationSearchRepo.getPlaceDetailsFromPlaceId(prediction);
      final placeDetails = PlaceDetails.fromJson(
        jsonDecode(response.responseJson),
      );

      if (placeDetails.result == null) {
        return null;
      } else {
        prediction.lat =
            placeDetails.result!.geometry!.location!.lat.toString();
        prediction.lng =
            placeDetails.result!.geometry!.location!.lng.toString();
        changeCurrentLatLongBasedOnCameraMove(
          double.parse(prediction.lat!),
          double.parse(prediction.lng!),
        );
        // openMap(placeDetails.result!.geometry!.location!.lat ?? 0.0, placeDetails.result!.geometry!.location!.lng ?? 0.0);
        mapController?.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(
              target: LatLng(
                placeDetails.result!.geometry!.location!.lat ?? 0.0,
                placeDetails.result!.geometry!.location!.lng ?? 0.0,
              ),
              zoom: 15,
            ),
          ),
        );

        allPredictions = [];
        update();
        return LatLng(
          double.parse(prediction.lat!),
          double.parse(prediction.lng!),
        );
      }
    } catch (e) {
      printX(e.toString());
    }
    return null;
  }

  // polyline
  Map<PolylineId, Polyline> polylines = {};
  Future<List<LatLng>> getPolylinePoints() async {
    List<LatLng> polylineCoordinates = [];
    PolylinePoints polylinePoints = PolylinePoints();
    PolylineResult result = await polylinePoints.getRouteBetweenCoordinates(
      request: PolylineRequest(
        origin: PointLatLng(pickupLatlong.latitude, pickupLatlong.longitude),
        destination: PointLatLng(
          destinationLatlong.latitude,
          destinationLatlong.longitude,
        ),
        mode: TravelMode.driving,
      ),
      googleApiKey: Environment.mapKey,
    );
    if (result.points.isNotEmpty) {
      for (var point in result.points) {
        polylineCoordinates.add(LatLng(point.latitude, point.longitude));
      }
    } else {
      printX("result.errorMessage ${result.errorMessage}");
    }
    polylineCoordinates.map((e) {
      printX("e.toJson() ${e.toJson()}");
    });
    return polylineCoordinates;
  }

  void generatePolyLineFromPoints(List<LatLng> polylineCoordinates) async {
    isLoading = true;
    update();
    PolylineId id = const PolylineId("poly");
    Polyline polyline = Polyline(
      polylineId: id,
      color: MyColor.primaryColor,
      points: polylineCoordinates,
      width: 5,
    );
    polylines[id] = polyline;
    isLoading = false;
    update();
  }

  Uint8List? pickupIcon;
  Uint8List? destinationIcon;

  Set<Marker> markers = {};
  Set<Marker> getMarkers() {
    markers.addAll({
      Marker(
        markerId: MarkerId('markerId_pickup'),
        position: LatLng(pickupLatlong.latitude, pickupLatlong.longitude),
        icon: pickupIcon == null
            ? BitmapDescriptor.defaultMarker
            : BitmapDescriptor.bytes(
                pickupIcon!,
                height: 40,
                width: 40,
                bitmapScaling: MapBitmapScaling.auto,
              ),
      ),
      Marker(
        markerId: MarkerId('markerId_destination'),
        position: LatLng(
          destinationLatlong.latitude,
          destinationLatlong.longitude,
        ),
        icon: destinationIcon == null
            ? BitmapDescriptor.defaultMarker
            : BitmapDescriptor.bytes(
                destinationIcon!,
                height: 45,
                width: 45,
                bitmapScaling: MapBitmapScaling.auto,
              ),
      ),
      // Marker(
      //   markerId: MarkerId('markerId${destinationLatlong.latitude}'),
      //   position: LatLng(pickupLatlong.latitude, pickupLatlong.longitude),
      //   icon: destinationIcon == null ? BitmapDescriptor.defaultMarker : BitmapDescriptor.bytes(destinationIcon!, height: 45, width: 45, bitmapScaling: MapBitmapScaling.auto),
      // ),
    });
    return {};
  }

  Future<void> setCustomMarkerIcon({bool? isRunning}) async {
    pickupIcon = await Helper.getBytesFromAsset(MyImages.mapDriver, 80);
    destinationIcon = await Helper.getBytesFromAsset(
      MyImages.mapDestination,
      80,
    );
    update();
  }
}
