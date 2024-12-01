import 'package:flutter/material.dart';
import 'package:fitness/common/colo_extension.dart';
import 'package:fitness/common_widget/tab_button.dart';
import 'package:fitness/view/home/blank_view.dart';
import 'package:fitness/view/main_tab/select_view.dart';
import 'package:provider/provider.dart'; // Import Provider
import '../home/home_view.dart';
import '../photo_progress/photo_progress_view.dart';
import '../profile/profile_view.dart';
import '../workout_tracker/workout_tracker_view.dart';
import 'package:fitness/common/theme_provider.dart'; 

class MainTabView extends StatefulWidget {
  final VoidCallback onThemeToggle;

  const MainTabView({super.key, required this.onThemeToggle});

  @override
  State<MainTabView> createState() => _MainTabViewState();
}

class _MainTabViewState extends State<MainTabView> {
  int selectedTab = 0; // Keeps track of the selected tab
  final PageStorageBucket pageBucket = PageStorageBucket(); // For saving state
  final List<Widget> pages = [
    const HomeView(),
    const SelectView(),
    const PhotoProgressView(),
    const ProfileView(),
  ]; // List of pages for tabs

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return Scaffold(
          backgroundColor: themeProvider.themeMode == ThemeMode.light
              ? TColor.white
              : TColor.nightBlack,
          body: PageStorage(
            bucket: pageBucket,
            child: pages[selectedTab],
          ),
          floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
          floatingActionButton: SizedBox(
            width: 70,
            height: 70,
            child: InkWell(
              onTap: widget.onThemeToggle, // Calls the toggle theme method
              child: Container(
                width: 65,
                height: 65,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: TColor.primaryG),
                  borderRadius: BorderRadius.circular(35),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 2,
                    )
                  ],
                ),
                child: Icon(
                  themeProvider.themeMode == ThemeMode.light
                      ? Icons.dark_mode
                      : Icons.light_mode,
                  color: TColor.white,
                  size: 35,
                ),
              ),
            ),
          ),
          bottomNavigationBar: BottomAppBar(
            child: Container(
              decoration: BoxDecoration(
                color: themeProvider.themeMode == ThemeMode.light
                    ? TColor.white
                    : TColor.nightBlack,
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 2,
                    offset: Offset(0, -2),
                  )
                ],
              ),
              height: kToolbarHeight,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  TabButton(
                    icon: "assets/img/home_tab.png",
                    selectIcon: "assets/img/home_tab_select.png",
                    isActive: selectedTab == 0,
                    onTap: () {
                      setState(() {
                        selectedTab = 0;
                      });
                    },
                  ),
                  TabButton(
                    icon: "assets/img/activity_tab.png",
                    selectIcon: "assets/img/activity_tab_select.png",
                    isActive: selectedTab == 1,
                    onTap: () {
                      setState(() {
                        selectedTab = 1;
                      });
                    },
                  ),
                  const SizedBox(width: 40), // Space for the floating button
                  TabButton(
                    icon: "assets/img/camera_tab.png",
                    selectIcon: "assets/img/camera_tab_select.png",
                    isActive: selectedTab == 2,
                    onTap: () {
                      setState(() {
                        selectedTab = 2;
                      });
                    },
                  ),
                  TabButton(
                    icon: "assets/img/profile_tab.png",
                    selectIcon: "assets/img/profile_tab_select.png",
                    isActive: selectedTab == 3,
                    onTap: () {
                      setState(() {
                        selectedTab = 3;
                      });
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
