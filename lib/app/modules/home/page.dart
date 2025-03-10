import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lazy_indexed_stack/flutter_lazy_indexed_stack.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';

import '../../../l10n.dart';
import '../../routes/pages.dart';
import 'controller.dart';
import 'widgets/user_avatar.dart';
import 'widgets/user_drawer.dart';

class HomePage extends GetView<HomeController> {
  const HomePage({Key? key}) : super(key: key);

  PreferredSize _buildAppbar(BuildContext context) {
    double height = kTextTabBarHeight +
        MediaQuery.of(context).padding.top +
        (controller.currentIndex == 3 ? 1 : 0);

    return PreferredSize(
      preferredSize: Size.fromHeight(height),
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: Theme.of(context).canvasColor,
          border: controller.currentIndex == 3
              ? Border(
                  bottom: BorderSide(
                    color: Theme.of(context).dividerColor,
                    width: 1,
                  ),
                )
              : null,
        ),
        padding: MediaQuery.of(context).padding.copyWith(bottom: 0),
        child: Row(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(15, 7.5, 0, 7.5),
              child: InkWell(
                onTap: () {
                  controller.scaffoldKey.currentState?.openDrawer();
                },
                child: ClipOval(
                  child: UserAvatar(aspectRatio: 1),
                ),
              ),
            ),
            Expanded(
              child: GestureDetector(
                onTap: () {
                  Get.toNamed(AppRoutes.normalSearch);
                },
                child: Container(
                  alignment: Alignment.center,
                  margin:
                      const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
                  padding:
                      const EdgeInsets.symmetric(vertical: 7.5, horizontal: 15),
                  decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius:
                          const BorderRadius.all(Radius.circular(15))),
                  child: Row(
                    children: [
                      const FaIcon(
                        FontAwesomeIcons.magnifyingGlass,
                        color: Colors.grey,
                        size: 20,
                      ),
                      Padding(
                        padding: const EdgeInsets.only(left: 5),
                        child: AutoSizeText(
                          L10n.of(context).search,
                          maxLines: 1,
                          style: const TextStyle(
                            fontSize: 17.5,
                            color: Colors.grey,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      )
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(0, 7.5, 15, 7.5),
              child: InkWell(
                onTap: () {
                  if (controller.userService.accountService.isLogin) {
                    Get.toNamed(AppRoutes.conversationsPreview);
                  } else {
                    Get.toNamed(AppRoutes.login);
                  }
                },
                child: Badge(
                  isLabelVisible:
                      (controller.userService.notificationsCounts?.messages ??
                              0) >
                          0,
                  label: controller.userService.notificationsCounts == null
                      ? null
                      : Text(
                          controller.userService.notificationsCounts!.messages
                              .toString(),
                          style: const TextStyle(color: Colors.white),
                        ),
                  child: const FaIcon(
                    FontAwesomeIcons.solidEnvelope,
                    color: Colors.grey,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    controller.init(context);

    return WillPopScope(
      onWillPop: controller.onWillPop,
      child: Obx(
        () => Scaffold(
          key: controller.scaffoldKey,
          appBar: _buildAppbar(context),
          drawer: const UserDrawer(),
          bottomNavigationBar: BottomNavigationBar(
            type: BottomNavigationBarType.fixed,
            selectedItemColor: Theme.of(context).primaryColor,
            selectedFontSize: 10,
            unselectedFontSize: 10,
            currentIndex: controller.currentIndex,
            onTap: controller.onTap,
            items: controller.listBottomNavigationBarItem,
          ),
          body: LazyIndexedStack(
            index: controller.currentIndex,
            children: controller.pageList,
          ),
        ),
      ),
    );
  }
}
