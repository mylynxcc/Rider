import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ovorideuser/core/utils/my_color.dart';
import 'package:ovorideuser/core/utils/my_images.dart';
import 'package:ovorideuser/core/utils/util.dart';
import 'package:ovorideuser/data/controller/localization/localization_controller.dart';
import 'package:ovorideuser/data/controller/splash/splash_controller.dart';
import 'package:ovorideuser/data/repo/auth/general_setting_repo.dart';
import 'package:ovorideuser/data/services/api_service.dart';
import 'package:ovorideuser/presentation/components/custom_no_data_found_class.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  @override
  void initState() {
    MyUtils.splashScreen();
    Get.put(ApiClient(sharedPreferences: Get.find()));
    Get.put(GeneralSettingRepo(apiClient: Get.find()));
    Get.put(LocalizationController(sharedPreferences: Get.find()));
    final controller = Get.put(
      SplashController(repo: Get.find(), localizationController: Get.find()),
    );

    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      controller.gotoNextPage();
    });
  }

  @override
  void dispose() {
    MyUtils.allScreen();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<SplashController>(
      builder: (controller) => Scaffold(
        backgroundColor:
            controller.noInternet ? MyColor.colorWhite : MyColor.primaryColor,
        body: controller.noInternet
            ? NoDataOrInternetScreen(
                isNoInternet: true,
                onChanged: () {
                  controller.gotoNextPage();
                },
              )
            : Stack(
                children: [
                  Align(
                    alignment: Alignment.center,
                    child: Image.asset(
                      MyImages.appLogoIcon,
                      height: 100,
                      width: 100,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
