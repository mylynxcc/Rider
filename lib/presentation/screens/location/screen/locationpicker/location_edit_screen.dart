import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:ovorideuser/core/helper/string_format_helper.dart';
import 'package:ovorideuser/core/utils/my_icons.dart';
import 'package:ovorideuser/core/utils/style.dart';
import 'package:ovorideuser/environment.dart';
import 'package:ovorideuser/presentation/components/buttons/rounded_button.dart';
import '../../../../../core/utils/dimensions.dart';
import '../../../../../core/utils/helper.dart';
import '../../../../../core/utils/my_color.dart';
import '../../../../../core/utils/my_strings.dart';
import '../../../../../data/controller/location/select_location_controller.dart';

class EditLocationPickerScreen extends StatefulWidget {
  const EditLocationPickerScreen({super.key});

  @override
  State<EditLocationPickerScreen> createState() =>
      _EditLocationPickerScreenState();
}

class _EditLocationPickerScreenState extends State<EditLocationPickerScreen> {
  TextEditingController searchLocationController = TextEditingController(
    text: '',
  );

  Uint8List? bytes;
  bool isSearching = false;
  bool isFirsTime = true;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      function();
    });
  }

  function() async {
    searchLocationController.text = '';
    bytes = await Helper.getBytesFromAsset(MyIcons.mapMarkerIcon, 150);
  }

  double? _previousZoom;
  bool _isZooming = false;
  LatLng? _currentCameraPosition;
  bool isZoomChanged = false;
  double currentZoom = Environment.mapDefaultZoom;
  bool showMarker = true;
  bool isDragging = false;
  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarBrightness: Brightness.light,
        statusBarIconBrightness: Brightness.dark,
      ),
      child: GetBuilder<SelectLocationController>(
        builder: (controller) {
          return Scaffold(
            extendBody: true,
            extendBodyBehindAppBar: true,
            backgroundColor: MyColor.screenBgColor,
            resizeToAvoidBottomInset: true,
            body: Stack(
              clipBehavior: Clip.none,
              children: [
                if (controller.isLoading == true &&
                    controller.isLoadingFirstTime == true)
                  const SizedBox(
                    width: double.infinity,
                    height: double.infinity,
                  )
                else ...[
                  Stack(
                    children: [
                      SizedBox(
                        height: context.height * .6,
                        child: GoogleMap(
                          scrollGesturesEnabled: isZoomChanged ? false : true,
                          trafficEnabled: false,
                          indoorViewEnabled: false,
                          zoomGesturesEnabled: true,
                          myLocationEnabled: true,
                          tiltGesturesEnabled: false,
                          mapType: MapType.normal,
                          minMaxZoomPreference: const MinMaxZoomPreference(
                            0,
                            100,
                          ),
                          markers: showMarker
                              ? {
                                  Marker(
                                    markerId: const MarkerId(
                                      "selected_location",
                                    ),
                                    position: LatLng(
                                      controller.selectedLatitude,
                                      controller.selectedLongitude,
                                    ),
                                    icon: bytes == null
                                        ? BitmapDescriptor.defaultMarker
                                        : BitmapDescriptor.bytes(
                                            bytes!,
                                            height: 45,
                                            width: 45,
                                          ),
                                  ),
                                }
                              : <Marker>{},
                          initialCameraPosition: CameraPosition(
                            target: controller.getInitialTargetLocationForMap(
                              pickupLocationForIndex: controller.index,
                            ),
                            zoom: currentZoom,
                            bearing: 20,
                            tilt: 0,
                          ),
                          onMapCreated: (googleMapController) {
                            controller.mapController = googleMapController;
                          },
                          onCameraMoveStarted: () {},
                          onCameraMove: (CameraPosition? position) async {
                            if (_previousZoom != null &&
                                position?.zoom != _previousZoom) {
                              if (!_isZooming) {
                                setState(() {
                                  _isZooming = true;
                                });
                                printX("Started Zooming...");
                              }
                            }
                            _previousZoom = position?.zoom;

                            setState(() {
                              isDragging = true;
                              showMarker = false; // hide marker when dragging
                              _currentCameraPosition = position?.target;
                            });
                          },
                          onCameraIdle: () {
                            if (isDragging &&
                                !_isZooming &&
                                _currentCameraPosition != null) {
                              controller.changeCurrentLatLongBasedOnCameraMove(
                                _currentCameraPosition!.latitude,
                                _currentCameraPosition!.longitude,
                              );
                              controller.pickLocation();
                            }

                            setState(() {
                              isDragging = false;
                              _isZooming = false;
                              showMarker = true; // show marker again after done
                            });
                          },
                          onTap: (argument) {
                            // For direct taps, we always update position
                            // controller.changeCurrentLatLongBasedOnCameraMove(argument.latitude, argument.longitude);
                            // controller.openMap(argument.latitude, argument.longitude);
                          },
                        ),
                      ),
                      if (isDragging && !_isZooming && bytes != null)
                        Positioned(
                          bottom: 45,
                          top: 0,
                          left: 0,
                          right: 0,
                          child: Align(
                            alignment: Alignment.center,
                            child: Image.memory(bytes!, width: 45),
                          ),
                        ),
                    ],
                  ),
                ],
                Align(
                  alignment: Alignment.center,
                  child: controller.isLoading
                      ? CircularProgressIndicator(
                          color: MyColor.getPrimaryColor(),
                        )
                      : const SizedBox.shrink(),
                ),
                Positioned(
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: Dimensions.space12,
                      ),
                      child: IconButton(
                        style: IconButton.styleFrom(
                          backgroundColor: MyColor.colorWhite,
                        ),
                        color: MyColor.colorBlack,
                        onPressed: () {
                          Get.back(result: true);
                        },
                        icon: const Icon(Icons.arrow_back_ios_new_rounded),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            bottomNavigationBar: buildConfirmDestination(),
          );
        },
      ),
    );
  }

  Widget buildConfirmDestination() {
    return GetBuilder<SelectLocationController>(
      builder: (controller) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 600),
          height: context.height * .4,
          padding: EdgeInsets.symmetric(
            vertical: Dimensions.space10,
            horizontal: 20,
          ),
          decoration: BoxDecoration(
            color: MyColor.colorWhite,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(30),
              topRight: Radius.circular(30),
            ),
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Align(
                  alignment: Alignment.topCenter,
                  child: Container(
                    height: 5,
                    width: 50,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: MyColor.colorGrey.withValues(alpha: 0.2),
                    ),
                  ),
                ),
                SizedBox(height: Dimensions.space20),
                Text(
                  "Set Your Location Perfectly",
                  style: boldDefault.copyWith(fontSize: 20),
                ),
                Text(
                  "Zoom in to set the exact location",
                  style: lightDefault.copyWith(color: MyColor.bodyText),
                ),
                SizedBox(height: Dimensions.space30),
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(
                    horizontal: Dimensions.space15,
                    vertical: Dimensions.space10,
                  ),
                  decoration: BoxDecoration(
                    color: MyColor.colorGrey2,
                    borderRadius: BorderRadius.circular(Dimensions.largeRadius),
                  ),
                  child: Text(
                    controller.currentAddress.value.isNotEmpty
                        ? controller.currentAddress.value
                        : controller.homeController
                                .getSelectedLocationInfoAtIndex(
                                  controller.index,
                                )
                                ?.fullAddress ??
                            "",
                    style: lightDefault.copyWith(color: MyColor.bodyText),
                    textAlign: TextAlign.center,
                  ),
                ),
                SizedBox(height: Dimensions.space40),
                //Confirm
                RoundedButton(
                  text: MyStrings.confirm,
                  verticalPadding: 20,
                  press: () {
                    // Get.back(result: 'true');
                    printX(
                      "controller.pickupLatlong.latitude ${controller.pickupLatlong.latitude} | ${controller.pickupLatlong.longitude}",
                    );
                    printX(
                      "controller.homeController.getSelectedLocationInfoAtIndex(0)?.latitude ${controller.homeController.getSelectedLocationInfoAtIndex(0)?.latitude} |  ${controller.homeController.getSelectedLocationInfoAtIndex(0)?.longitude}",
                    );
                    Get.back();
                  },
                  isOutlined: false,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
