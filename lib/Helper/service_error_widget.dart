import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:homely_user/Helper/Constant.dart';
import 'package:homely_user/generated/assets.dart';
import 'package:http/http.dart' as http;
import 'String.dart';

class ServiceErrorWidget extends StatefulWidget {
  ValueChanged onResult;

  ServiceErrorWidget(this.onResult);

  @override
  State<ServiceErrorWidget> createState() => _ServiceErrorWidgetState();
}

class _ServiceErrorWidgetState extends State<ServiceErrorWidget> {
  @override
  initState() {
    super.initState();
    getSetting();
  }

  List<dynamic> pincocdeImage = [];

  getSetting() async {
    print("=========ajsdbabdnabd===========");
    var headers = {
      'Cookie': 'ci_session=165041e7253a11a37bc1155c74ed626cb632eb1b'
    };
    var request =
    http.MultipartRequest('POST', Uri.parse('${baseUrl}get_settings'));
    request.fields.addAll({'user_id': '$CUR_USERID'});
    print("get setting parameter ${request.fields}");
    request.headers.addAll(headers);
    http.StreamedResponse response = await request.send();
    print("====status code ===========${response.statusCode}===========");
    if (response.statusCode == 200) {
      print("====herer nowwww===========");
      var finalResponse = await response.stream.bytesToString();
      final jsonResponse = json.decode(finalResponse);
      pincocdeImage = jsonResponse['data']['service_image'];
      setState(() {
        pincocdeImage = jsonResponse['data']['service_image'];

      });
    } else {
      print(response.reasonPhrase);
    }
  }


  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      height: MediaQuery.of(context).size.height,
      width: MediaQuery.of(context).size.width,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Image.network(pincocdeImage.first ??'', height: 250, width: 250,),
          // Padding(
          //   padding: const EdgeInsets.only(left: 19, right: 10),
          //   child: Text(
          //     "“Dear Customer!! Thanks for your interest. Our services are not available in this pin code at present!! We will inform you when we start services in your area!! You can still change the address and enjoy the service from available area.",
          //     style: TextStyle(fontSize: 14.0, fontWeight: FontWeight.w600,decoration: TextDecoration.none),
          //   ),
          // ),
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
