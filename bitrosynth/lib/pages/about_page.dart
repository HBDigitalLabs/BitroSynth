import 'package:flutter/material.dart';
import "../common_types.dart";

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});


  static const String _aboutText =
      "Version: v3.0.0\n"
      "Developed by: Hüseyin Berke - HBDigitalLabs\n\n"
      "This application is open-source software.\n"
      "License information for this application and its third-party\n"
      "dependencies can be found in the LICENSES directory.\n\n"
      "Licensed under the Apache 2.0 License.";

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < 300 || constraints.maxHeight < 250) {
            return const Padding(
              padding: EdgeInsets.all(20),
              child: Text(
                'Window is too small',
                style: TextStyle(color: AppColors.text),
              ),
            );
          }

          return ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: 400,
              maxHeight: 400,
            ),
            child: Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: Container(
                    height: 70,
                    width: double.infinity,
                    color: AppColors.surface,
                    child: const Center(
                      child: Text(
                        "BitroSynth",
                        style: TextStyle(
                          color: AppColors.text,
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ),
                  ),
                ),

                // content
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10.0),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12.0),
                      color: AppColors.surface,
                      child: const Text(
                            _aboutText,
                            style: TextStyle(
                              color: AppColors.text,
                              fontSize: 14,
                              height: 1.5,
                            ),
                          
                      ),
                    ),
                  ),
                ),

                // Close button
                Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.accent,
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.zero,
                        ),
                      ),
                      onPressed: () => Navigator.pop(context),
                      child: const Text("CLOSE"),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
