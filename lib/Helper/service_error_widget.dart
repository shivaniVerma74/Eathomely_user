import 'package:flutter/material.dart';
import 'package:homely_user/Helper/Constant.dart';
import 'package:homely_user/generated/assets.dart';

class ServiceErrorWidget extends StatefulWidget {
  ValueChanged onResult;

  ServiceErrorWidget(this.onResult);

  @override
  State<ServiceErrorWidget> createState() => _ServiceErrorWidgetState();
}

class _ServiceErrorWidgetState extends State<ServiceErrorWidget> {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      height: MediaQuery.of(context).size.height,
      width: MediaQuery.of(context).size.width,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Image.asset(Assets.imagesError),
          Padding(
            padding: const EdgeInsets.only(left: 19, right: 10),
            child: Text(
              "“Dear Customer!! Thanks for your interest. Our services are not available in this pin code at present!! We will inform you when we start services in your area!! You can still change the address and enjoy the service from available area.",
              style: TextStyle(fontSize: 14.0, fontWeight: FontWeight.w600,decoration: TextDecoration.none),
            ),
          ),
          Text(
            "Pin code - $zipCode",
            style: TextStyle(fontSize: 14.0, fontWeight: FontWeight.w600,decoration: TextDecoration.none,color: Colors.black),
          ),
          ElevatedButton(
              onPressed: () {
                widget.onResult(true);
              },
              child: Text(
                "Change Address",
                style: TextStyle(color: Colors.white),
              ),
          ),
        ],
      ),
    );
  }
}
