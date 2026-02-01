import 'common_types.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:ffi' as ffi;
import 'package:path/path.dart' as p;


void showMessage(BuildContext context,String message)
  => ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.surfaceAlt,
        content: Text(
          message,
          style: const TextStyle(
            color: AppColors.text,
            backgroundColor: AppColors.surfaceAlt
          ),
          
        ),
      ),
    );

Future<bool?> showYesNoDialog(
  BuildContext context,
  String message,
) async {
  return await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (context) {
      return LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < 300 || constraints.maxHeight < 180) {
            return const Center(
              child: Text(
                'Window is too small',
                style: TextStyle(color: AppColors.text),
              ),
            );
          }

          return AlertDialog(
            backgroundColor: AppColors.surfaceAlt,
            title: const Text(
              'Confirmation',
              style: TextStyle(color: AppColors.text),
            ),
            content: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Text(
                message,
                style: const TextStyle(color: AppColors.text),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text(
                  'No',
                  style: TextStyle(color: AppColors.text),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text(
                  'Yes',
                  style: TextStyle(color: AppColors.text),
                ),
              ),
            ],
          );
        },
      );
    },
  );
}


Future<void> showAlertDialog(
  BuildContext context,
  String title,
  String message,
) async {
  await showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) {
      return LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < 300 || constraints.maxHeight < 160) {
            return const Center(
              child: Text(
                'Window is too small',
                style: TextStyle(color: AppColors.text),
              ),
            );
          }

          return AlertDialog(
            backgroundColor: AppColors.surfaceAlt,
            title: Text(
              title,
              style: const TextStyle(color: AppColors.text),
            ),
            content: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Text(
                message,
                style: const TextStyle(color: AppColors.text),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.accent,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.zero,
                  ),
                ),
                child: const Text("Ok"),
              ),
            ],
          );
        },
      );
    },
  );
}



ffi.DynamicLibrary openBundledLibrary(String libName) {
  final tried = <String>[];


  try {
    return ffi.DynamicLibrary.open(libName);
  } catch (e) {
    tried.add(libName);
  }

  final env = Platform.environment;

  if (env.containsKey('APPDIR')) {
    final candidate = p.join(env['APPDIR']!, 'usr', 'lib', libName);
    tried.add(candidate);
    if (File(candidate).existsSync()) {
      return ffi.DynamicLibrary.open(candidate);
    }
  }

  Directory dir = File(Platform.resolvedExecutable).parent;
  for (int i = 0; i < 6; ++i) {
    final candidate = p.join(dir.path, 'usr', 'lib', libName);
    tried.add(candidate);
    if (File(candidate).existsSync()) {
      return ffi.DynamicLibrary.open(candidate);
    }
    dir = dir.parent;
  }

  final cwdCandidate = p.join(Directory.current.path, libName);
  tried.add(cwdCandidate);
  if (File(cwdCandidate).existsSync()) {
    return ffi.DynamicLibrary.open(cwdCandidate);
  }

  throw Exception(
    'Failed to load $libName.\n'
    'Tried paths:\n  ${tried.join('\n  ')}\n'
    'Platform.resolvedExecutable=${Platform.resolvedExecutable}\n'
    'CWD=${Directory.current.path}\n'
    'ENV APPDIR=${env['APPDIR'] ?? "<none>"}'
  );
}

