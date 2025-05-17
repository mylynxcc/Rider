import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ovorideuser/core/helper/string_format_helper.dart';
import 'package:ovorideuser/core/utils/dimensions.dart';
import 'package:ovorideuser/core/utils/my_color.dart';
import 'package:ovorideuser/core/utils/my_strings.dart';
import 'package:ovorideuser/core/utils/util.dart';
import 'package:ovorideuser/data/controller/ride/ride_details/ride_details_controller.dart';
import 'package:ovorideuser/presentation/components/bottom-sheet/bottom_sheet_header_row.dart';
import 'package:ovorideuser/presentation/components/buttons/rounded_button.dart';
import 'package:ovorideuser/presentation/components/snack_bar/show_custom_snackbar.dart';
import 'package:ovorideuser/presentation/components/text-form-field/custom_text_field.dart';

class RideDetailsSosBottomSheetBody extends StatelessWidget {
  RideDetailsController controller;
  String id;
  RideDetailsSosBottomSheetBody({
    super.key,
    required this.controller,
    required this.id,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const BottomSheetHeaderRow(),
        const SizedBox(height: Dimensions.space10),
        CustomTextField(
          onChanged: (v) {},
          animatedLabel: false,
          needOutlineBorder: true,
          labelText: MyStrings.message.toTitleCase(),
          hintText: 'Driver is very bad.',
          maxLines: 5,
          controller: controller.sosMsgController,
        ),
        const SizedBox(height: Dimensions.space20),
        RoundedButton(
          text: MyStrings.submit,
          color: MyColor.redCancelTextColor,
          press: () async {
            if (await MyUtils.handleLocationPermission() &&
                controller.sosMsgController.text.isNotEmpty) {
              Get.back();
              controller.sos(id);
            }
            if (controller.sosMsgController.text.isEmpty) {
              CustomSnackBar.error(errorList: ['Please Enter Message']);
            }
          },
        ),
        const SizedBox(height: Dimensions.space10),
      ],
    );
  }
}
