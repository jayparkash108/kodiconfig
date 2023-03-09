import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

class uiHelper {

  static void showAlertDialog(BuildContext context, {required String title, body}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Center(
          child: SingleChildScrollView(
            child: AlertDialog(
              title: Text(title),
              content: Text(body),
              actions: [
                TextButton(
                  child: Text("OK"),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              ],
            )
          ),
        );
      },
    );
  }

  static void showLoadingDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Center(
          child: SingleChildScrollView(
            child: AlertDialog(
              alignment: Alignment.center,
              content: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Row(
                  children: <Widget>[
                    SpinKitFadingCube(color: Colors.blue),
                    SizedBox(width: 20.0),
                    Text("Loading..."),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  static void showCustomLoadingDialog(
    BuildContext context, {
    required String text,
    required Color backgroundColor,
    required Widget loaderSpin,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Center(
          child: SingleChildScrollView(
            child: AlertDialog(
              backgroundColor: Colors.transparent,
              alignment: Alignment.center,
              content: Container(
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    color: backgroundColor
                  // gradient: LinearGradient(
                  //   colors: [
                  //     HexColor("#FF5287"),
                  //     HexColor("#FE95B6")
                  //   ]
                  // ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(30.0),
                  child: Row(
                    children: <Widget>[
                      loaderSpin,
                      SizedBox(width: 20.0),
                      Text(text),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}



