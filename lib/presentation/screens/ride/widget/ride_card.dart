import 'package:ovorideuser/core/helper/string_format_helper.dart';
import 'package:ovorideuser/core/route/route.dart';
import 'package:ovorideuser/core/utils/app_status.dart';
import 'package:ovorideuser/core/utils/dimensions.dart';
import 'package:ovorideuser/core/utils/my_color.dart';
import 'package:ovorideuser/core/utils/my_strings.dart';
import 'package:ovorideuser/core/utils/style.dart';
import 'package:ovorideuser/core/utils/url_container.dart';
import 'package:ovorideuser/core/utils/util.dart';
import 'package:ovorideuser/data/controller/ride/active_ride/ride_history_controller.dart';
import 'package:ovorideuser/data/model/global/app/ride_model.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ovorideuser/data/services/download_service.dart';
import 'package:ovorideuser/environment.dart';
import 'package:ovorideuser/presentation/components/buttons/rounded_button.dart';
import '../../../components/divider/custom_spacer.dart';
import '../../../components/timeline/custom_timeLine.dart';

class RideCard extends StatefulWidget {
  String currency;
  RideModel ride;
  RideCard({super.key, required this.currency, required this.ride});

  @override
  State<RideCard> createState() => _RideCardState();
}

class _RideCardState extends State<RideCard> {
  bool isDownLoadLoading = false;

  @override
  Widget build(BuildContext context) {
    return GetBuilder<RideHistoryController>(
      builder: (controller) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: MyColor.getCardBgColor(),
            borderRadius: BorderRadius.circular(Dimensions.mediumRadius),
            boxShadow: MyUtils.getCardShadow(),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: Dimensions.space5,
                      vertical: Dimensions.space2,
                    ),
                    decoration: BoxDecoration(
                      color: MyUtils.getRideStatusColor(
                        widget.ride.status ?? '9',
                      ).withValues(alpha: 0.01),
                      borderRadius: BorderRadius.circular(
                        Dimensions.defaultRadius,
                      ),
                      border: Border.all(
                        color: MyUtils.getRideStatusColor(
                          widget.ride.status ?? '9',
                        ),
                      ),
                    ),
                    child: Text(
                      MyUtils.getRideStatus(widget.ride.status ?? '9').tr,
                      style: regularDefault.copyWith(
                        fontSize: 16,
                        color: MyUtils.getRideStatusColor(
                          widget.ride.status ?? '9',
                        ),
                      ),
                    ),
                  ),
                  Column(
                    children: [
                      Text(
                        "${widget.currency}${Converter.formatNumber(widget.ride.offerAmount.toString())}",
                        style: boldLarge.copyWith(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: MyColor.rideTitle,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: Dimensions.space20),
              GestureDetector(
                onTap: () {
                  Get.toNamed(
                    RouteHelper.rideDetailsScreen,
                    arguments: widget.ride.id.toString(),
                  );
                },
                child: CustomTimeLine(
                  indicatorPosition: 0.1,
                  dashColor: MyColor.colorYellow,
                  firstWidget: Padding(
                    padding: const EdgeInsets.only(left: 8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Align(
                          alignment: Alignment.topLeft,
                          child: Text(
                            MyStrings.pickUpLocation.tr,
                            style: boldLarge.copyWith(
                              color: MyColor.rideTitle,
                              fontSize: Dimensions.fontLarge - 1,
                              fontWeight: FontWeight.w700,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        spaceDown(Dimensions.space5),
                        Text(
                          widget.ride.pickupLocation ?? '',
                          style: regularDefault.copyWith(
                            color: MyColor.getRideSubTitleColor(),
                            fontSize: Dimensions.fontSmall,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        spaceDown(Dimensions.space8),
                        Text(
                          widget.ride.startTime ?? '',
                          style: regularDefault.copyWith(
                            color: MyColor.getRideSubTitleColor(),
                            fontSize: Dimensions.fontSmall,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        spaceDown(Dimensions.space15),
                      ],
                    ),
                  ),
                  secondWidget: Padding(
                    padding: const EdgeInsets.only(left: 8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Align(
                          alignment: Alignment.topLeft,
                          child: Text(
                            MyStrings.destination.tr,
                            style: boldLarge.copyWith(
                              color: MyColor.rideTitle,
                              fontSize: Dimensions.fontLarge - 1,
                              fontWeight: FontWeight.w700,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(height: Dimensions.space5 - 1),
                        Text(
                          widget.ride.destination ?? '',
                          style: regularDefault.copyWith(
                            color: MyColor.getRideSubTitleColor(),
                            fontSize: Dimensions.fontSmall,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        spaceDown(Dimensions.space8),
                        Text(
                          widget.ride.endTime ?? '',
                          style: regularDefault.copyWith(
                            color: MyColor.getRideSubTitleColor(),
                            fontSize: Dimensions.fontSmall,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: Dimensions.space15),
              if (widget.ride.status == AppStatus.RIDE_COMPLETED) ...[
                RoundedButton(
                  text: MyStrings.receipt,
                  isLoading: isDownLoadLoading,
                  press: () {
                    setState(() {
                      isDownLoadLoading = true;
                    });
                    printX(isDownLoadLoading);
                    DownloadService.downloadPDF(
                      url: "${UrlContainer.rideReceipt}/${widget.ride.id}",
                      fileName:
                          "${Environment.appName}_recipt_${widget.ride.id}.pdf",
                    );
                    Future.delayed(const Duration(seconds: 1), () {}).then((_) {
                      setState(() {
                        isDownLoadLoading = false;
                      });
                    });

                    printX(isDownLoadLoading);
                  },
                  textColor: MyColor.getRideTitleColor(),
                  textStyle: regularDefault.copyWith(
                    color: MyColor.colorWhite,
                    fontSize: Dimensions.fontLarge,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
