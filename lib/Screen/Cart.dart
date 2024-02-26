import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';

import 'package:homely_user/Helper/Constant.dart';
import 'package:homely_user/Helper/Session.dart';

import 'package:homely_user/Provider/CartProvider.dart';
import 'package:homely_user/Provider/SettingProvider.dart';
import 'package:homely_user/Provider/UserProvider.dart';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_svg/svg.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:homely_user/Screen/HomePage.dart';
import 'package:http/http.dart';
import 'package:intl/intl.dart';
import 'package:paytm/paytm.dart';
import 'package:provider/provider.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../Helper/AppBtn.dart';
import '../Helper/Color.dart';
import '../Helper/SimBtn.dart';
import '../Helper/String.dart';
import '../Helper/Stripe_Service.dart';
import '../Model/Model.dart';
import '../Model/Section_Model.dart';
import '../Model/User.dart';
import 'Add_Address.dart';
import 'Manage_Address.dart';
import 'Order_Success.dart';
import 'Payment.dart';
import 'PaypalWebviewActivity.dart';
import 'package:http/http.dart' as http;

import 'Webviewexample.dart';

class Cart extends StatefulWidget {
  final bool fromBottom;

  const Cart({Key? key, required this.fromBottom}) : super(key: key);

  @override
  State<StatefulWidget> createState() => StateCart();
}

/*String gpayEnv = "TEST",
    gpayCcode = "US",
    gpaycur = "USD",
    gpayMerId = "01234567890123456789",
    gpayMerName = "Example Merchant Name";*/

class StateCart extends State<Cart> with TickerProviderStateMixin {
  final GlobalKey<ScaffoldMessengerState> _scaffoldKey =
      new GlobalKey<ScaffoldMessengerState>();

  final GlobalKey<ScaffoldMessengerState> _checkscaffoldKey =
      new GlobalKey<ScaffoldMessengerState>();
  List<Model> deliverableList = [];
  bool _isCartLoad = true, _placeOrder = true;

  int newsum = 0;
  String cgst = "";
  String sgst = '';
  String totalTax = '';
  String? cartID;
  //HomePage? home;
  Animation? buttonSqueezeanimation;
  AnimationController? buttonController;
  bool _isNetworkAvail = true;
  bool firstUser = false;
  List<String> addonIds = [];
  List<String> addonName = [];
  var addonTotal;

  List<TextEditingController> _controller = [];

  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey =
      new GlobalKey<RefreshIndicatorState>();
  List<SectionModel> saveLaterList = [];
  String? msg;
  bool _isLoading = true;
  Razorpay? _razorpay;
  TextEditingController promoC = new TextEditingController();
  TextEditingController noteC = new TextEditingController();
  StateSetter? checkoutState;
  // final paystackPlugin = PaystackPlugin();
  bool deliverable = false;
  double checkres = 0.0;
  bool saveLater = false, addCart = false;

  //List<PaymentItem> _gpaytItems = [];
  //Pay _gpayClient;
  String finalIdss = "0";
  String finalqty = "0";

  int finalTotalValue = 0;

  removeAddon(id, varientId, cartID) async {
    var headers = {
      'Cookie': 'ci_session=9fdc5be3b49fe0b21287b3157d0d4c3450f7a6a3'
    };
    var request = http.MultipartRequest(
        'POST', Uri.parse('${baseUrl}remove_add_on_user'));
    request.fields.addAll({
      'add_on_id': '${id}',
      'cart_id': cartID,
      'product_variant_id': varientId
    });
    request.headers.addAll(headers);

    http.StreamedResponse response = await request.send();
    print('_____request.fields______${request.fields}__________');
    print("vvvvvvvvvvvvv ${response.statusCode}");
    if (response.statusCode == 200) {
      var finalResult = await response.stream.bytesToString();
      final jsonResponse = json.decode(finalResult);
      setState(() {});
      //_getCart("0");
      _refresh();
    } else {
      print(response.reasonPhrase);
    }
  }

  @override
  void initState() {
    super.initState();
    clearAll();
    getUserData();
    startCon.text = DateFormat("yyyy-MM-dd").format(DateTime.now().add(const Duration(days: 1)));
    endCon.text = DateFormat("yyyy-MM-dd").format(DateTime.now().add(const Duration(days: 1)));
    Future.delayed(Duration(milliseconds: 300), () {
      return getUserData();
    });
    _getCart("0");
    _getSaveLater("1");
    // _getAddress();
    Future.delayed(Duration(milliseconds: 300), () {
      return getSetting();
    });
    // _getAddress();
    buttonController = new AnimationController(
        duration: new Duration(milliseconds: 2000), vsync: this);
    buttonSqueezeanimation = new Tween(
      begin: deviceWidth! * 0.7,
      end: 50.0,
    ).animate(new CurvedAnimation(
      parent: buttonController!,
      curve: new Interval(
        0.0,
        0.150,
      ),
    ));
  }

  Future<Null> _refresh() {
    if (mounted)
      setState(() {
        _isCartLoad = true;
      });
    clearAll();
    getUserData();
    _getCart("0");
    return _getSaveLater("1");
  }

  String? activeStatus;

  getUserData() async {
    print("get user by id api ");
    var headers = {
      'Cookie': 'ci_session=403d7c5a97ff1b8bdb7753b4518cda08f32b0ac4'
    };
    var request =
        http.MultipartRequest('POST', Uri.parse('${baseUrl}get_users_by_id'));
    request.fields.addAll({
      'user_id': CUR_USERID.toString(),
    });
    print("get user by id parameter ${request.fields}");
    request.headers.addAll(headers);
    http.StreamedResponse response = await request.send();
    print("status code here ${response.statusCode}");
    if (response.statusCode == 200) {
      var finalResult = await response.stream.bytesToString();
      final jsonResponse = json.decode(finalResult);
      print("dataa herrrr nowwwwwww");
      print("profile data here ${jsonResponse['data']['active']}");
      print("profile namee herre ${jsonResponse['data']}");
      setState(() {
        activeStatus = jsonResponse['data']['active'].toString();
      });
      print("Active status here ${activeStatus}");
    } else {
      print(response.reasonPhrase);
    }
  }

  var gstPercent;
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
      pincocdeImage = jsonResponse['data']['logo'];
      setState(() {
        gstPercent = jsonResponse['data']['system_settings'][0]['gst_amount'].toString();
        pincocdeImage = jsonResponse['data']['logo'];
        print("pincod imageee $pincocdeImage $gstPercent");
      });
      print("gst percent here $gstPercent");
    } else {
      print(response.reasonPhrase);
    }
  }

  clearAll() {
    totalPrice = 0;
    oriPrice = 0;
    taxPer = 0;
    delCharge = 0;
    addressList.clear();
    // cartList.clear();
    WidgetsBinding.instance!.addPostFrameCallback((timeStamp) {
      context.read<CartProvider>().setCartlist([]);
      context.read<CartProvider>().setProgress(false);
    });
    promoAmt = 0;
    remWalBal = 0;
    usedBal = 0;
    payMethod = '';
    isPromoValid = false;
    isUseWallet = false;
    isPayLayShow = true;
    selectedMethod = null;
  }

  @override
  void dispose() {
    buttonController!.dispose();
    for (int i = 0; i < _controller.length; i++) _controller[i].dispose();

    if (_razorpay != null) _razorpay!.clear();
    super.dispose();
  }

  Future<Null> _playAnimation() async {
    try {
      await buttonController!.forward();
    } on TickerCanceled {}
  }

  Widget noInternet(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          noIntImage(),
          noIntText(context),
          noIntDec(context),
          AppBtn(
            title: getTranslated(context, 'TRY_AGAIN_INT_LBL'),
            btnAnim: buttonSqueezeanimation,
            btnCntrl: buttonController,
            onBtnSelected: () async {
              _playAnimation();

              Future.delayed(Duration(seconds: 2)).then((_) async {
                _isNetworkAvail = await isNetworkAvailable();
                if (_isNetworkAvail) {
                  Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                          builder: (BuildContext context) => super.widget));
                } else {
                  await buttonController!.reverse();
                  if (mounted) setState(() {});
                }
              });
            },
          )
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    deviceHeight = MediaQuery.of(context).size.height;
    deviceWidth = MediaQuery.of(context).size.width;
    return Scaffold(
        appBar: widget.fromBottom
            ? null
            : getSimpleAppBar(getTranslated(context, 'CART')!, context),
        body: _isNetworkAvail
            ? Stack(
                children: <Widget>[
                  _showContent(context),
                  Selector<CartProvider, bool>(
                    builder: (context, data, child) {
                      return showCircularProgress(data, colors.primary);
                    },
                    selector: (_, provider) => provider.isProgress,
                  ),
                ],
              )
            : noInternet(context));
  }

  Widget listItem(int index, List<SectionModel> cartList) {
    int selectedPos = 0;
    for (int i = 0;
        i < cartList[index].productList![0].prVarientList!.length;
        i++) {
      if (cartList[index].varientId ==
          cartList[index].productList![0].prVarientList![i].id) selectedPos = i;
    }
    String? offPer;
    double price = double.parse(
        cartList[index].productList![0].prVarientList![selectedPos].disPrice!);
    if (price == 0)
      price = double.parse(
          cartList[index].productList![0].prVarientList![selectedPos].price!);
    else {
      double off = (double.parse(cartList[index]
              .productList![0]
              .prVarientList![selectedPos]
              .price!)) -
          price;
      offPer = (off *
              100 /
              double.parse(cartList[index]
                  .productList![0]
                  .prVarientList![selectedPos]
                  .price!))
          .toStringAsFixed(2);
    }

    cartList[index].perItemPrice = price.toString();
    //print("qty************${cartList.contains("qty")}");
    print("cartList**avail****${cartList[index].productList![0].availability}");

    if (_controller.length < index + 1) {
      _controller.add(new TextEditingController());
    }
    if (cartList[index].productList![0].availability != "0") {
      cartList[index].perItemTotal =
          (price * double.parse(cartList[index].qty!)).toString();
      _controller[index].text = cartList[index].qty!;
    }
    List att = [], val = [];
    if (cartList[index].productList![0].prVarientList![selectedPos].attr_name !=
        null) {
      att = cartList[index]
          .productList![0]
          .prVarientList![selectedPos]
          .attr_name!
          .split(',');
      val = cartList[index]
          .productList![0]
          .prVarientList![selectedPos]
          .varient_value!
          .split(',');
    }
    addonIds.clear();
    addonName.clear();
    newsum = 0;
    for (var i = 0;
        i < cartList[index].productList![0].addOnList!.length;
        i++) {
      newsum = newsum +
          int.parse(
              cartList[index].productList![0].addOnList![i].price.toString());
    }
    addonIds.add("${cartList[index].add_on_id.toString()}");
    addonName.add("${cartList[index].add_on_qty.toString()}");

    String addOn = "";

    for (int j = 0;
        j < cartList[index].productList![0].addOnList!.length;
        j++) {
      var model = cartList[index].productList![0].addOnList![j];
      // print("dars"+model.price.toString()+ model.q );

      if (cartList[index].add_on_id.toString().split(", ").contains(model.id)) {
        if (addOn == "") {
          addOn += model.name.toString();
        } else {
          addOn += ", " + model.name.toString();
        }
      }
    }
    finalIdss = addonIds.join(',');
    finalqty = addonName.join(',');
    if (cartList[index].productList![0].availability == "0") {
      isAvailable = false;
    }
    return Padding(
        padding: const EdgeInsets.symmetric(
          vertical: 10.0,
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Card(
              elevation: 0.1,
              child: Column(
                children: [
                  Row(
                    children: <Widget>[
                      Hero(
                          tag: "$index${cartList[index].productList![0].id}",
                          child: Stack(
                            children: [
                              ClipRRect(
                                  borderRadius: BorderRadius.circular(7.0),
                                  child: Stack(children: [
                                    Card(
                                      child: Container(
                                        width: 120,
                                        height: 100,
                                        child: FadeInImage(
                                          image: CachedNetworkImageProvider(
                                              cartList[index]
                                                  .productList![0]
                                                  .image!),
                                          height: 125.0,
                                          width: 110.0,
                                          fit: BoxFit.contain,
                                          imageErrorBuilder:
                                              (context, error, stackTrace) =>
                                                  erroWidget(125),
                                          placeholder: placeHolder(125),
                                        ),
                                      ),
                                    ),
                                    Positioned.fill(
                                        child: cartList[index]
                                                    .productList![0]
                                                    .availability ==
                                                "0"
                                            ? Container(
                                                height: 55,
                                                color: Colors.white70,
                                                // width: double.maxFinite,
                                                padding: EdgeInsets.all(2),
                                                child: Center(
                                                  child: Text(
                                                    getTranslated(context,
                                                        'OUT_OF_STOCK_LBL')!,
                                                    style: Theme.of(context)
                                                        .textTheme
                                                        .caption!
                                                        .copyWith(
                                                          color: Colors.red,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                        ),
                                                    textAlign: TextAlign.center,
                                                  ),
                                                ),
                                              )
                                            : Container()),
                                  ])),
                              offPer != null
                                  ? Container(
                                      decoration: BoxDecoration(
                                          color: colors.red,
                                          borderRadius:
                                              BorderRadius.circular(10)),
                                      child: Padding(
                                        padding: const EdgeInsets.all(5.0),
                                        child: Text(
                                          offPer + "%",
                                          style: TextStyle(
                                              color: colors.whiteTemp,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 9),
                                        ),
                                      ),
                                      margin: EdgeInsets.all(5),
                                    )
                                  : Container()
                            ],
                          )),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsetsDirectional.all(8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Padding(
                                      padding: const EdgeInsetsDirectional.only(
                                          top: 5.0),
                                      child: Text(
                                        cartList[index].productList![0].name!,
                                        style: Theme.of(context)
                                            .textTheme
                                            .subtitle1!
                                            .copyWith(
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .fontColor),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ),
                                  GestureDetector(
                                    child: Padding(
                                      padding: const EdgeInsetsDirectional.only(
                                          start: 8.0, end: 8, bottom: 8),
                                      child: Icon(
                                        Icons.clear,
                                        size: 20,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .fontColor,
                                      ),
                                    ),
                                    onTap: () {
                                      print(index);
                                      print(cartList);
                                      print(selectedPos);
                                      if (context
                                              .read<CartProvider>()
                                              .isProgress ==
                                          false)
                                        removeFromCart(index, true, cartList,
                                            false, selectedPos);
                                    },
                                  )
                                ],
                              ),
                              cartList[index]
                                              .productList![0]
                                              .prVarientList![selectedPos]
                                              .attr_name !=
                                          null &&
                                      cartList[index]
                                          .productList![0]
                                          .prVarientList![selectedPos]
                                          .attr_name!
                                          .isNotEmpty
                                  ? ListView.builder(
                                      physics: NeverScrollableScrollPhysics(),
                                      shrinkWrap: true,
                                      itemCount: att.length,
                                      itemBuilder: (context, index) {
                                        return Row(children: [
                                          Flexible(
                                            child: Text(
                                              att[index].trim() + ":",
                                              overflow: TextOverflow.ellipsis,
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .subtitle2!
                                                  .copyWith(
                                                    color: Theme.of(context)
                                                        .colorScheme
                                                        .lightBlack,
                                                  ),
                                            ),
                                          ),
                                          Padding(
                                            padding: EdgeInsetsDirectional.only(
                                                start: 5.0),
                                            child: Text(
                                              val[index],
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .subtitle2!
                                                  .copyWith(
                                                      color: Theme.of(context)
                                                          .colorScheme
                                                          .lightBlack,
                                                      fontWeight:
                                                          FontWeight.bold),
                                            ),
                                          )
                                        ]);
                                      })
                                  : Container(),
                              Row(
                                children: <Widget>[
                                  Text(
                                    double.parse(cartList[index]
                                                .productList![0]
                                                .prVarientList![selectedPos]
                                                .disPrice!) !=
                                            0
                                        ? CUR_CURRENCY! +
                                            "" +
                                            cartList[index]
                                                .productList![0]
                                                .prVarientList![selectedPos]
                                                .price!
                                        : "",
                                    style: Theme.of(context)
                                        .textTheme
                                        .overline!
                                        .copyWith(
                                            decoration:
                                                TextDecoration.lineThrough,
                                            letterSpacing: 0.7),
                                  ),
                                  Text(
                                    " " +
                                        CUR_CURRENCY! +
                                        " " +
                                        price.toString(),
                                    style: TextStyle(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .fontColor,
                                        fontWeight: FontWeight.bold),
                                  ),
                                  SizedBox(
                                    width: 10,
                                  ),
                                  cartList[index].productList![0].indicator ==
                                          "1"
                                      ? Image.asset(
                                          "assets/images/vegImage.png",
                                          height: 15,
                                          width: 15,
                                        )
                                      : cartList[index]
                                                  .productList![0]
                                                  .indicator ==
                                              "2"
                                          ? Image.asset(
                                              "assets/images/non-vegImage.png",
                                              height: 15,
                                              width: 15,
                                            )
                                          : Row(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Image.asset(
                                                  "assets/images/vegImage.png",
                                                  height: 15,
                                                  width: 15,
                                                ),
                                                Image.asset(
                                                  "assets/images/non-vegImage.png",
                                                  height: 15,
                                                  width: 15,
                                                )
                                              ],
                                            )
                                ],
                              ),
                              cartList[index].productList![0].availability ==
                                          "1" ||
                                      cartList[index]
                                              .productList![0]
                                              .stockType ==
                                          "null"
                                  ? Row(
                                      children: <Widget>[
                                        Row(
                                          children: <Widget>[
                                            GestureDetector(
                                              child: Card(
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(50),
                                                ),
                                                child: Padding(
                                                  padding:
                                                      const EdgeInsets.all(8.0),
                                                  child: Icon(
                                                    Icons.remove,
                                                    size: 15,
                                                  ),
                                                ),
                                              ),
                                              onTap: () {
                                                if (context
                                                        .read<CartProvider>()
                                                        .isProgress ==
                                                    false)
                                                  removeFromCart(
                                                      index,
                                                      false,
                                                      cartList,
                                                      false,
                                                      selectedPos);
                                              },
                                            ),
                                            Container(
                                              width: 26,
                                              height: 20,
                                              child: TextField(
                                                textAlign: TextAlign.center,
                                                readOnly: true,
                                                style: TextStyle(
                                                    fontSize: 12,
                                                    color: Theme.of(context)
                                                        .colorScheme
                                                        .fontColor),
                                                controller: _controller[index],
                                                decoration: InputDecoration(
                                                  border: InputBorder.none,
                                                ),
                                              ),
                                            ), // ),
                                            GestureDetector(
                                              child: Card(
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(50),
                                                ),
                                                child: Padding(
                                                  padding:
                                                      const EdgeInsets.all(8.0),
                                                  child: Icon(
                                                    Icons.add,
                                                    size: 15,
                                                  ),
                                                ),
                                              ),
                                              onTap: () {
                                                if (context
                                                        .read<CartProvider>()
                                                        .isProgress ==
                                                    false)
                                                  addToCart(
                                                      index,
                                                      (int.parse(cartList[index]
                                                                  .qty!) +
                                                              int.parse(cartList[
                                                                      index]
                                                                  .productList![
                                                                      0]
                                                                  .qtyStepSize!))
                                                          .toString(),
                                                      cartList);
                                              },
                                            )
                                          ],
                                        ),
                                      ],
                                    )
                                  : Container(),
                            ],
                          ),
                        ),
                      )
                    ],
                  ),
                  // Column(
                  //   crossAxisAlignment: CrossAxisAlignment.start,
                  //   children: cartList[index].addOns!.length>0?
                  //   cartList[index].addOns!.map((AddOnsModel e) {
                  //     List<AddOnModel> addList = cartList[index].productList![0].addOnList!.toList();
                  //     String name = "";
                  //     print(addList.length);
                  //     print(addList.indexWhere((element) {
                  //       print(e.id);
                  //       print(element.id);
                  //       return element.id==e.id;
                  //     }));
                  //     if(addList.indexWhere((element) => e.id!.contains(element.id.toString()))!=-1){
                  //       name = addList[addList.indexWhere((element) => e.id!.contains(element.id.toString()))].name.toString();
                  //     }
                  //     print("iiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiii ${e.image}");
                  //     return   Padding(
                  //       padding: const EdgeInsets.all(5.0),
                  //       child: Column(
                  //         crossAxisAlignment: CrossAxisAlignment.start,
                  //         children: [
                  //           Padding(
                  //             padding: const EdgeInsets.only(left: 5),
                  //             child: Text("Add On",style: TextStyle(),),
                  //           ),
                  //           SizedBox(height:8),
                  //           Row(
                  //             children: [
                  //               Container(
                  //                   height: 50,
                  //                   width:50,
                  //                   child: e.image == null || e.image == "" ?  Image.asset("assets/images/placeholder.png") : Image.network("${e.image}",fit: BoxFit.fill,)),
                  //               SizedBox(width: 10,),
                  //               Column(
                  //                 crossAxisAlignment: CrossAxisAlignment.start,
                  //                 children: [
                  //                   Container(
                  //                     width: 150,
                  //                     child: Text(" "+
                  //                         e.quantity.toString()+" x "+name.toString(),
                  //                       style: Theme.of(context)
                  //                           .textTheme
                  //                           .subtitle1!
                  //                           .copyWith(
                  //                           color: Theme.of(context)
                  //                               .colorScheme
                  //                               .fontColor), maxLines: 1,
                  //                       overflow: TextOverflow.ellipsis,
                  //                     ),
                  //                   ),
                  //                   // Spacer(),
                  //                   Text(
                  //                     " " + CUR_CURRENCY! + " " + e.price.toString(),
                  //                     style: TextStyle(
                  //                         color:
                  //                         Theme.of(context).colorScheme.fontColor,
                  //                         fontWeight: FontWeight.bold),
                  //                   ),
                  //                   Text(
                  //                     "Add On Qty: "  + e.quantity.toString(),
                  //                     style: TextStyle(
                  //                         color:
                  //                         Theme.of(context).colorScheme.fontColor,
                  //                         fontWeight: FontWeight.bold),
                  //                   ),
                  //                 ],
                  //               ),
                  //             ],
                  //           ),
                  //           // SizedBox(
                  //           //   width: 10,
                  //           // ),
                  //
                  //           // Container(
                  //           //   height: 100,
                  //           //     width: double.infinity,
                  //           //     child: Image.network("${e.image}",fit: BoxFit.fill,)),
                  //
                  //
                  //           SizedBox(
                  //             width: 10,
                  //           ),
                  //         ],
                  //       ),
                  //     );
                  //   }).toList():[],
                  // ),
                  ///
                  cartList[index].productList![0].addOnList!.length == 0
                      ? SizedBox()
                      : Padding(
                          padding: const EdgeInsets.only(left: 8, top: 8),
                          child: Align(
                              alignment: Alignment.topLeft,
                              child: Text(
                                "Add On",
                                style: TextStyle(),
                                textAlign: TextAlign.start,
                              )),
                        ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: cartList[index]
                                .productList![0]
                                .addOnList!
                                .length >
                            0
                        ? cartList[index].productList![0].addOnList!.map((e) {
                            List<AddOnModel> addList = cartList[index]
                                .productList![0]
                                .addOnList!
                                .toList();
                            String name = "";
                            if (addList.indexWhere((element) =>
                                    e.id!.contains(element.id.toString())) !=
                                -1) {
                              name = addList[addList.indexWhere((element) =>
                                      e.id!.contains(element.id.toString()))]
                                  .name
                                  .toString();
                            }
                            return Padding(
                              padding: const EdgeInsets.all(5.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SizedBox(height: 8),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Container(
                                              height: 50,
                                              width: 50,
                                              child: e.image == null ||
                                                      e.image == ""
                                                  ? Image.asset(
                                                      "assets/images/placeholder.png")
                                                  : Image.network(
                                                      "${e.image}",
                                                      fit: BoxFit.fill,
                                                    )),
                                          SizedBox(
                                            width: 10,
                                          ),
                                          Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Container(
                                                //  width: 150,
                                                child: Text(
                                                  "" +
                                                      e.name.toString() +
                                                      " X " +
                                                      e.quantity.toString(),
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .subtitle1!
                                                      .copyWith(
                                                          color:
                                                              Theme.of(context)
                                                                  .colorScheme
                                                                  .fontColor),
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ),
                                              // Spacer(),
                                              Text(
                                                e.quantity.toString() +
                                                    " X " +
                                                    CUR_CURRENCY! +
                                                    e.price.toString() +
                                                    " = " +
                                                    CUR_CURRENCY! +
                                                    "" +
                                                    e.totalAmount.toString(),
                                                style: TextStyle(
                                                    color: Theme.of(context)
                                                        .colorScheme
                                                        .fontColor,
                                                    fontWeight:
                                                        FontWeight.bold),
                                              ),
                                              // Text(
                                              //   "Add On Qty: "  + "${cartList[index].add_on_qty}",
                                              //   style: TextStyle(
                                              //       color:
                                              //       Theme.of(context).colorScheme.fontColor,
                                              //       fontWeight: FontWeight.bold),
                                              // ),
                                            ],
                                          ),
                                        ],
                                      ),
                                      InkWell(
                                        onTap: () {
                                          print('____________________');
                                          print("cart id here $cartID");
                                          removeAddon(
                                              e.id.toString(),
                                              cartList[index].varientId,
                                              cartList[index].cartID);
                                        },
                                        child: Icon(
                                          Icons.clear,
                                          color: Colors.black,
                                        ),
                                      ),
                                    ],
                                  ),
                                  // SizedBox(
                                  //   width: 10,
                                  // ),

                                  // Container(
                                  //   height: 100,
                                  //     width: double.infinity,
                                  //     child: Image.network("${e.image}",fit: BoxFit.fill,)),

                                  SizedBox(
                                    width: 10,
                                  ),
                                ],
                              ),
                            );
                          }).toList()
                        : [],
                  ),
                  SizedBox(
                    height: 20,
                  ),
                ],
              ),
            ),
            // Positioned.directional(
            //     textDirection: Directionality.of(context),
            //     end: 0,
            //     bottom: -15,
            //     child: Card(
            //       elevation: 1,
            //       shape: RoundedRectangleBorder(
            //         borderRadius: BorderRadius.circular(50),
            //       ),
            //       child: InkWell(
            //         child: Padding(
            //           padding: const EdgeInsets.all(8.0),
            //           child: Icon(
            //             Icons.archive_rounded,
            //             size: 20,
            //           ),
            //         ),
            //         onTap: !saveLater &&
            //                 !context.read<CartProvider>().isProgress
            //             ? () {
            //                 setState(() {
            //                   saveLater = true;
            //                 });
            //                 saveForLater(
            //                     cartList[index].productList![0].availability ==
            //                             "0"
            //                         ? cartList[index]
            //                             .productList![0]
            //                             .prVarientList![selectedPos]
            //                             .id!
            //                         : cartList[index].varientId,
            //                     "1",
            //                     cartList[index].productList![0].availability ==
            //                             "0"
            //                         ? "1"
            //                         : cartList[index].qty,
            //                     double.parse(cartList[index].perItemTotal!),
            //                     cartList[index],
            //                     false);
            //               }
            //             : null,
            //       ),
            //     ))
          ],
        ));
  }

  TextEditingController startCon = TextEditingController();
  TextEditingController endCon = TextEditingController();
  DateTime startDate =
      DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
  Future<DateTime?> selectDate(BuildContext context,
      {DateTime? startDate}) async {
    final DateTime? picked = await showDatePicker(
        context: context,
        initialDate: startDate ?? DateTime.now(),
        firstDate: startDate ?? DateTime.now(),
        lastDate: DateTime(2030),
        keyboardType: TextInputType.none,
        initialEntryMode: DatePickerEntryMode.calendarOnly,
        builder: (BuildContext? context, Widget? child) {
          return child!;
        });
    return picked;
  }
  int days = 1;
  double daysAmount = 0;
  Widget cartItem(int index, List<SectionModel> cartList,setState) {
    int selectedPos = 0;
    for (int i = 0;
        i < cartList[index].productList![0].prVarientList!.length;
        i++) {
      if (cartList[index].varientId ==
          cartList[index].productList![0].prVarientList![i].id) selectedPos = i;
    }
    double price = double.parse(
        cartList[index].productList![0].prVarientList![selectedPos].disPrice!);
    if (price == 0)
      price = double.parse(
          cartList[index].productList![0].prVarientList![selectedPos].price!);

    cartList[index].perItemPrice = price.toString();
    cartList[index].perItemTotal =
        (price * double.parse(cartList[index].qty!)).toString();

    _controller[index].text = cartList[index].qty!;

    List att = [], val = [];
    if (cartList[index].productList![0].prVarientList![selectedPos].attr_name !=
        null) {
      att = cartList[index]
          .productList![0]
          .prVarientList![selectedPos]
          .attr_name!
          .split(',');
      val = cartList[index]
          .productList![0]
          .prVarientList![selectedPos]
          .varient_value!
          .split(',');
    }
    String perItemPackageCharge = "0";
    perItemPackageCharge = (double.parse(cartList[index].packingCharge!) *
            double.parse(cartList[index].qty.toString()))
        .toStringAsFixed(2);
    String? id, varId;
    bool? avail = false;
   // days = 0;
    double totalAmountItem = double.parse(cartList[index].perItemTotal!) +
        double.parse(perItemPackageCharge);
    if (deliverableList.length > 0) {
      id = cartList[index].id;
      varId = cartList[index].productList![0].prVarientList![selectedPos].id;

      for (int i = 0; i < deliverableList.length; i++) {
        if (id == deliverableList[i].prodId &&
            varId == deliverableList[i].varId) {
          avail = deliverableList[i].isDel;

          break;
        }
      }
    }
    return Card(
      elevation: 0.1,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            Row(
              children: <Widget>[
                Hero(
                    tag: "$index${cartList[index].productList![0].id}",
                    child: ClipRRect(
                        borderRadius: BorderRadius.circular(7.0),
                        child: FadeInImage(
                          image: CachedNetworkImageProvider(
                              cartList[index].productList![0].image!),
                          height: 80.0,
                          width: 80.0,
                          fit: BoxFit.cover,
                          imageErrorBuilder: (context, error, stackTrace) =>
                              erroWidget(80),

                          // errorWidget: (context, url, e) => placeHolder(60),
                          placeholder: placeHolder(80),
                        ))),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsetsDirectional.only(start: 8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Row(
                          children: [
                            Expanded(
                              child: Padding(
                                padding:
                                    const EdgeInsetsDirectional.only(top: 5.0),
                                child: Text(
                                  cartList[index].productList![0].name!,
                                  style: Theme.of(context)
                                      .textTheme
                                      .subtitle2!
                                      .copyWith(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .lightBlack),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                            GestureDetector(
                              child: Padding(
                                padding: const EdgeInsetsDirectional.only(
                                    start: 8.0, end: 8, bottom: 8),
                                child: Icon(
                                  Icons.clear,
                                  size: 13,
                                  color:
                                      Theme.of(context).colorScheme.fontColor,
                                ),
                              ),
                              onTap: () {
                                if (context.read<CartProvider>().isProgress ==
                                    false)
                                  removeFromCartCheckout(index, true, cartList);
                              },
                            )
                          ],
                        ),
                        cartList[index]
                                        .productList![0]
                                        .prVarientList![selectedPos]
                                        .attr_name !=
                                    null &&
                                cartList[index]
                                    .productList![0]
                                    .prVarientList![selectedPos]
                                    .attr_name!
                                    .isNotEmpty
                            ? ListView.builder(
                                physics: NeverScrollableScrollPhysics(),
                                shrinkWrap: true,
                                itemCount: att.length,
                                itemBuilder: (context, index) {
                                  return Row(children: [
                                    Flexible(
                                      child: Text(
                                        att[index].trim() + ":",
                                        overflow: TextOverflow.ellipsis,
                                        style: Theme.of(context)
                                            .textTheme
                                            .subtitle2!
                                            .copyWith(
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .lightBlack,
                                            ),
                                      ),
                                    ),
                                    Padding(
                                      padding: EdgeInsetsDirectional.only(
                                          start: 5.0),
                                      child: Text(
                                        val[index],
                                        style: Theme.of(context)
                                            .textTheme
                                            .subtitle2!
                                            .copyWith(
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .lightBlack,
                                                fontWeight: FontWeight.bold),
                                      ),
                                    )
                                  ]);
                                })
                            : Container(),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Flexible(
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: <Widget>[
                                  Flexible(
                                    child: Text(
                                      double.parse(cartList[index]
                                                  .productList![0]
                                                  .prVarientList![selectedPos]
                                                  .disPrice!) !=
                                              0
                                          ? CUR_CURRENCY! +
                                              "" +
                                              cartList[index]
                                                  .productList![0]
                                                  .prVarientList![selectedPos]
                                                  .price!
                                          : "",
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: Theme.of(context)
                                          .textTheme
                                          .overline!
                                          .copyWith(
                                              decoration:
                                                  TextDecoration.lineThrough,
                                              letterSpacing: 0.7),
                                    ),
                                  ),
                                  Text(
                                    " " +
                                        CUR_CURRENCY! +
                                        " " +
                                        price.toString(),
                                    style: TextStyle(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .fontColor,
                                        fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                            cartList[index].productList![0].availability ==
                                        "1" ||
                                    cartList[index].productList![0].stockType ==
                                        "null"
                                ? Row(
                                    children: <Widget>[
                                      Row(
                                        children: <Widget>[
                                          // GestureDetector(
                                          //   child: Card(
                                          //     shape: RoundedRectangleBorder(
                                          //       borderRadius:
                                          //       BorderRadius.circular(50),
                                          //     ),
                                          //     child: Padding(
                                          //       padding:
                                          //       const EdgeInsets.all(8.0),
                                          //       child: Icon(
                                          //         Icons.remove,
                                          //         size: 15,
                                          //       ),
                                          //     ),
                                          //   ),
                                          //   onTap: () {
                                          //     if (context
                                          //         .read<CartProvider>()
                                          //         .isProgress ==
                                          //         false)
                                          //       removeFromCartCheckout(
                                          //           index, false, cartList);
                                          //   },
                                          // ),
                                          Container(
                                            width: 26,
                                            height: 20,
                                            child: TextField(
                                              textAlign: TextAlign.center,
                                              readOnly: true,
                                              style: TextStyle(
                                                  fontSize: 12,
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .fontColor),
                                              controller: _controller[index],
                                              decoration: InputDecoration(
                                                border: InputBorder.none,
                                              ),
                                            ),
                                          ),
                                          // GestureDetector(
                                          //   child: Card(
                                          //     shape: RoundedRectangleBorder(
                                          //       borderRadius:
                                          //       BorderRadius.circular(50),
                                          //     ),
                                          //     child: Padding(
                                          //       padding:
                                          //       const EdgeInsets.all(8.0),
                                          //       child: Icon(
                                          //         Icons.add,
                                          //         size: 15,
                                          //       ),
                                          //     ),
                                          //   ),
                                          //   onTap: () {
                                          //     addToCartCheckout(
                                          //         index,
                                          //         (int.parse(cartList[index]
                                          //             .qty!) +
                                          //             int.parse(cartList[
                                          //             index]
                                          //                 .productList![0]
                                          //                 .qtyStepSize!))
                                          //             .toString(),
                                          //         cartList);
                                          //   },
                                          // )
                                        ],
                                      ),
                                    ],
                                  )
                                : Container(),
                          ],
                        ),
                        SizedBox(
                          height: 5,
                        ),
                        cartList[index].productList![0].indicator == "1"
                            ? Image.asset(
                                "assets/images/vegImage.png",
                                height: 15,
                                width: 15,
                              )
                            : cartList[index].productList![0].indicator == "2"
                                ? Image.asset(
                                    "assets/images/non-vegImage.png",
                                    height: 15,
                                    width: 15,
                                  )
                                : Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Image.asset(
                                        "assets/images/vegImage.png",
                                        height: 15,
                                        width: 15,
                                      ),
                                      Image.asset(
                                        "assets/images/non-vegImage.png",
                                        height: 15,
                                        width: 15,
                                      )
                                    ],
                                  )
                      ],
                    ),
                  ),
                )
              ],
            ),
            const SizedBox(height: 10,),
            cartList[index].subscriptionType=="1"?Row(
              children: [
                Expanded(
                  child: TextFormField(
                    style: Theme.of(context).textTheme.labelMedium!,
                    controller: startCon,
                    readOnly: true,
                    onTap: () async {
                      var date = await selectDate(context,
                          startDate: startCon.text != ""
                              ? DateTime.parse(startCon.text)
                              : null);
                      if (date != null) {
                        setState(() {
                          days = DateTime.parse(endCon.text).difference(date).inDays;
                          if(days==0){
                            days = 1;
                          }else{
                            days = days+1;
                          }
                          if(currentPrice==0){
                            currentPrice = totalPrice;
                          }
                          totalPrice = currentPrice*days;
                          print(days);
                          startCon.text = DateFormat("yyyy-MM-dd").format(date);
                        });
                      }
                    },
                    decoration: InputDecoration(
                      fillColor: Theme.of(context).primaryColor,
                      labelText: "Start Date",
                      hintText: "Select Start Date",
                      isDense: true,
                      filled: true,
                      enabledBorder: OutlineInputBorder(
                        borderSide:
                            BorderSide(color: Theme.of(context).dividerColor),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                            color: Theme.of(context).colorScheme.primary),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10,),
                Expanded(
                    child: TextFormField(
                  style: Theme.of(context).textTheme.labelMedium!,
                  controller: endCon,
                  readOnly: true,
                  onTap: () async {
                    var date = await selectDate(context,
                        startDate: startCon.text != ""
                            ? DateTime.parse(startCon.text)
                            : null);

                    if (date != null) {
                      setState(() {
                        days = date.difference(DateTime.parse(startCon.text)).inDays;
                        if(days==0){
                          days = 1;
                        }else{
                          days = days+1;
                        }
                        if(currentPrice==0){
                          currentPrice = totalPrice;
                        }
                        totalPrice = currentPrice*days;
                        print(days);
                        endCon.text = DateFormat("yyyy-MM-dd").format(date);
                      });
                    }
                  },
                  decoration: InputDecoration(
                    fillColor: Theme.of(context).primaryColor,
                    labelText: "End Date",
                    hintText: "Select End Date",
                    isDense: true,
                    filled: true,
                    enabledBorder: OutlineInputBorder(
                      borderSide:
                          BorderSide(color: Theme.of(context).dividerColor),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                          color: Theme.of(context).colorScheme.primary),
                    ),
                  ),
                ))
              ],
            ):const SizedBox(),
            const SizedBox(height: 5,),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  getTranslated(context, 'SUBTOTAL')!,
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.lightBlack2),
                ),
                Text(
                  CUR_CURRENCY! + " " + price.toString(),
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.lightBlack2),
                ),
                Text(
                  CUR_CURRENCY! + " " + cartList[index].perItemTotal!,
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.lightBlack2),
                ),
              ],
            ),
            // Row(
            //   mainAxisAlignment: MainAxisAlignment.spaceBetween,
            //   children: [
            //     Text(
            //       getTranslated(context, 'TAXPER')!,
            //       style: TextStyle(
            //           color: Theme.of(context).colorScheme.lightBlack2),
            //     ),
            //     Text(
            //       cartList[index].productList![0].tax! + "%",
            //       style: TextStyle(
            //           color: Theme.of(context).colorScheme.lightBlack2),
            //     ),
            //   ],
            // ),
            /*Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  getTranslated(context, 'ADD_ON_TOTAL') ?? "Add On Total",
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.lightBlack2),
                ),
                Text(
                  CUR_CURRENCY! + " " + price.toString(),
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.lightBlack2),
                ),
                Text(
                  CUR_CURRENCY! + " " + cartList[index].perItemTotal!,
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.lightBlack2),
                )
              ],
            ),*/
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Packaging Charge",
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.lightBlack2),
                ),
                // !avail! && deliverableList.length > 0
                //     ? Text(
                //         getTranslated(context, 'NOT_DEL')!,
                //         style: TextStyle(color: colors.red),
                //       )
                //     : Container(),
                Text(
                  CUR_CURRENCY! +
                      " " +
                      cartList[index].packingCharge.toString(),
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.lightBlack2),
                ),
                Text(
                  CUR_CURRENCY! + " " + perItemPackageCharge.toString(),
                  //+ " "+cartList[index].productList[0].taxrs,
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.lightBlack2),
                )
              ],
            ),
      cartList[index].subscriptionType=="1"&&days!=0?Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Total Days Amount",
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.lightBlack2),
                ),
                Text(
                    days.toString(),
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.lightBlack2),
                ),
                Text(
                  CUR_CURRENCY! + " " + (totalAmountItem*days).toString(),
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.lightBlack2),
                ),
              ],
            ):
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            getTranslated(context, 'TOTAL_LBL')!,
            style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.lightBlack2),
          ),
          // !avail! && deliverableList.length > 0
          //     ? Text(
          //         getTranslated(context, 'NOT_DEL')!,
          //         style: TextStyle(color: colors.red),
          //       )
          //     : Container(),
          Text(
            CUR_CURRENCY! +
                " " +
                (double.parse(cartList[index].perItemTotal!) +
                    double.parse(perItemPackageCharge))
                    .toStringAsFixed(2)
                    .toString(),
            //+ " "+cartList[index].productList[0].taxrs,
            style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.fontColor),
          )
        ],
      ),

            Divider(),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: cartList[index].productList![0].addOnList!.length > 0
                  ? cartList[index].productList![0].addOnList!.map((e) {
                      List<AddOnModel> addList =
                          cartList[index].productList![0].addOnList!.toList();
                      String name = "";
                      if (addList.indexWhere((element) =>
                              e.id!.contains(element.id.toString())) !=
                          -1) {
                        name = addList[addList.indexWhere((element) =>
                                e.id!.contains(element.id.toString()))]
                            .name
                            .toString();
                      }
                      return Padding(
                        padding: const EdgeInsets.all(5.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              //  width: 150,
                              child: Text(
                                "" +
                                    e.name.toString() +
                                    " X " +
                                    e.quantity.toString(),
                                style: Theme.of(context)
                                    .textTheme
                                    .subtitle1!
                                    .copyWith(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .fontColor),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Text(
                              e.quantity.toString() +
                                  " X " +
                                  CUR_CURRENCY! +
                                  e.price.toString() +
                                  " = " +
                                  CUR_CURRENCY! +
                                  "" +
                                  e.totalAmount.toString(),
                              style: TextStyle(
                                  color:
                                      Theme.of(context).colorScheme.fontColor,
                                  fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      );
                    }).toList()
                  : [],
            ),
          ],
        ),
      ),
    );
  }

  Widget saveLaterItem(int index) {
    int selectedPos = 0;
    for (int i = 0;
        i < saveLaterList[index].productList![0].prVarientList!.length;
        i++) {
      if (saveLaterList[index].varientId ==
          saveLaterList[index].productList![0].prVarientList![i].id)
        selectedPos = i;
    }

    double price = double.parse(saveLaterList[index]
        .productList![0]
        .prVarientList![selectedPos]
        .disPrice!);
    if (price == 0) {
      price = double.parse(saveLaterList[index]
          .productList![0]
          .prVarientList![selectedPos]
          .price!);
    }

    double off = (double.parse(saveLaterList[index]
                .productList![0]
                .prVarientList![selectedPos]
                .price!) -
            double.parse(saveLaterList[index]
                .productList![0]
                .prVarientList![selectedPos]
                .disPrice!))
        .toDouble();
    off = off *
        100 /
        double.parse(saveLaterList[index]
            .productList![0]
            .prVarientList![selectedPos]
            .price!);

    saveLaterList[index].perItemPrice = price.toString();
    if (saveLaterList[index].productList![0].availability != "0") {
      saveLaterList[index].perItemTotal =
          (price * double.parse(saveLaterList[index].qty!)).toString();
    }
    return Padding(
        padding: const EdgeInsets.symmetric(vertical: 10.0),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Card(
              elevation: 0.1,
              child: Row(
                children: <Widget>[
                  Hero(
                      tag: "$index${saveLaterList[index].productList![0].id}",
                      child: Stack(
                        children: [
                          ClipRRect(
                              borderRadius: BorderRadius.circular(7.0),
                              child: Stack(children: [
                                FadeInImage(
                                  image: CachedNetworkImageProvider(
                                      saveLaterList[index]
                                          .productList![0]
                                          .image!),
                                  height: 100.0,
                                  width: 100.0,
                                  fit: BoxFit.cover,
                                  imageErrorBuilder:
                                      (context, error, stackTrace) =>
                                          erroWidget(100),
                                  placeholder: placeHolder(100),
                                ),
                                Positioned.fill(
                                    child: saveLaterList[index]
                                                .productList![0]
                                                .availability ==
                                            "0"
                                        ? Container(
                                            height: 55,
                                            color: Colors.white70,
                                            // width: double.maxFinite,
                                            padding: EdgeInsets.all(2),
                                            child: Center(
                                              child: Text(
                                                getTranslated(context,
                                                    'OUT_OF_STOCK_LBL')!,
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .caption!
                                                    .copyWith(
                                                      color: Colors.red,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                textAlign: TextAlign.center,
                                              ),
                                            ),
                                          )
                                        : Container()),
                              ])),
                          (off != 0 || off != 0.0 || off != 0.00) &&
                                  saveLaterList[index]
                                          .productList![0]
                                          .prVarientList![selectedPos]
                                          .disPrice! !=
                                      "0"
                              ? Container(
                                  decoration: BoxDecoration(
                                      color: colors.red,
                                      borderRadius: BorderRadius.circular(10)),
                                  child: Padding(
                                    padding: const EdgeInsets.all(5.0),
                                    child: Text(
                                      off.toStringAsFixed(2) + "%",
                                      style: TextStyle(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 9),
                                    ),
                                  ),
                                  margin: EdgeInsets.all(5),
                                )
                              : Container()
                        ],
                      )),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsetsDirectional.only(start: 8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsetsDirectional.only(
                                      top: 5.0),
                                  child: Text(
                                    saveLaterList[index].productList![0].name!,
                                    style: Theme.of(context)
                                        .textTheme
                                        .subtitle1!
                                        .copyWith(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .fontColor),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                              GestureDetector(
                                child: Padding(
                                  padding: const EdgeInsetsDirectional.only(
                                      start: 8.0, end: 8, bottom: 8),
                                  child: Icon(
                                    Icons.close,
                                    size: 20,
                                    color:
                                        Theme.of(context).colorScheme.fontColor,
                                  ),
                                ),
                                onTap: () {
                                  if (context.read<CartProvider>().isProgress ==
                                      false)
                                    removeFromCart(index, true, saveLaterList,
                                        true, selectedPos);
                                },
                              )
                            ],
                          ),
                          Row(
                            children: <Widget>[
                              Text(
                                double.parse(saveLaterList[index]
                                            .productList![0]
                                            .prVarientList![selectedPos]
                                            .disPrice!) !=
                                        0
                                    ? CUR_CURRENCY! +
                                        "" +
                                        saveLaterList[index]
                                            .productList![0]
                                            .prVarientList![selectedPos]
                                            .price!
                                    : "",
                                style: Theme.of(context)
                                    .textTheme
                                    .overline!
                                    .copyWith(
                                        decoration: TextDecoration.lineThrough,
                                        letterSpacing: 0.7),
                              ),
                              Text(
                                " " + CUR_CURRENCY! + " " + price.toString(),
                                style: TextStyle(
                                    color:
                                        Theme.of(context).colorScheme.fontColor,
                                    fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  )
                ],
              ),
            ),
            saveLaterList[index].productList![0].availability == "1" ||
                    saveLaterList[index].productList![0].stockType == "null"
                ? Positioned(
                    bottom: -15,
                    right: 0,
                    child: Card(
                      elevation: 1,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(50),
                      ),
                      child: InkWell(
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Icon(
                            Icons.shopping_cart,
                            size: 20,
                          ),
                        ),
                        onTap:
                            !addCart && !context.read<CartProvider>().isProgress
                                ? () {
                                    setState(() {
                                      addCart = true;
                                    });
                                    saveForLater(
                                        saveLaterList[index].varientId,
                                        "0",
                                        saveLaterList[index].qty,
                                        double.parse(
                                            saveLaterList[index].perItemTotal!),
                                        saveLaterList[index],
                                        true);
                                  }
                                : null,
                      ),
                    ))
                : Container()
          ],
        ));
  }


  String? selfPickup;
  Future<void> _getCart(String save) async {
    _isNetworkAvail = await isNetworkAvailable();
    if (_isNetworkAvail) {
      try {
        var parameter = {USER_ID: CUR_USERID, SAVE_LATER: save};
        print("checking response here $parameter and $getCartApi");
        Response response = await post(getCartApi, body: parameter, headers: headers).timeout(Duration(seconds: timeOut));
        var getdata = json.decode(response.body);
        bool error = getdata["error"];
        String? msg = getdata["message"];
        if (!error) {
          var data = getdata["data"];
          setState(() {
            cgst = getdata['cgst'];
            sgst = getdata['sgst'];
          });
          totalTax = double.parse(getdata['tax_amount'].toString()).toStringAsFixed(2);
          // cartID = getdata[0]['cart_id'].toString();
          // print('_______cartID____${cartID}__________');
          print("nononon ${getdata[SUB_TOTAL]}");
          //firstUser = getdata['first_user']=="1"?true:false;
          if(firstUser){
            payMethod = "Free";
          }
          newDeliveryCharge = int.parse(getdata['delivery_charge'].toString());
          print("vvvvvvvvvvvv $newDeliveryCharge");
          newSellerId = data[0]['seller_id'];
          selfPickup = data[0]['self_pickup'];
          print("new Seller id here now $newSellerId $selfPickup");
          // delCharge = double.parse(newDeliveryCharge.toString());
          oriPrice = double.parse(getdata[SUB_TOTAL]);
          platformFee = double.parse(getdata['platform_fee']);
          packagingCharge = double.parse(getdata['total_packing_charge']);
          taxPer = double.parse(getdata[TAX_PER]);
          print('${delCharge}_______delCharge___');
          totalTax = ((delCharge + oriPrice + packagingCharge + platformFee)*taxPer / 100).toString();
          totalPrice =   oriPrice + double.parse(totalTax) + packagingCharge + platformFee +( !pickCustomer?0:delCharge);
          print('___________${totalPrice}____kk______');
          List<SectionModel> cartList = (data as List).map((data) => new SectionModel.fromCart(data)).toList();
          context.read<CartProvider>().setCartlist(cartList);
          if (getdata.containsKey(PROMO_CODES)) {
            var promo = getdata[PROMO_CODES];
            promoList = (promo as List).map((e) => new Promo.fromJson(e)).toList();
          }
          for (int i = 0; i < cartList.length; i++)
            _controller.add(new TextEditingController());
        } else {
          if (msg != 'Cart Is Empty !') setSnackbar(msg!, _scaffoldKey);
        }
        if (mounted)
          setState(() {
            _isCartLoad = false;
          });
        isAdreesChange ? _getAddress2() : _getAddress();
      } on TimeoutException catch (_) {
        setSnackbar(getTranslated(context, 'somethingMSg')!, _scaffoldKey);
      }
    } else {
      if (mounted)
        setState(() {
          _isNetworkAvail = false;
        });
    }
  }

  bool isAvailableDelivery = true;
  String? messageForDelivery;

  checkAddressForDelivery() async {
    var headers = {
      'Cookie': 'ci_session=3555d518752c27d3f07a9fd57cc43c5496e988ac'
    };
    var request = http.MultipartRequest(
        'POST', Uri.parse('${baseUrl}check_delivery_boy'));
    request.fields.addAll(
        {'seller_id': newSellerId ?? '236', 'address_id': selAddress ?? '121'});

    print('___________${request.fields}__________');

    request.headers.addAll(headers);

    http.StreamedResponse response = await request.send();

    if (response.statusCode == 200) {
      var result = await response.stream.bytesToString();
      var finalResult = jsonDecode(result);
      if (finalResult['error'] == false) {
        _checkOrderShouldBePlacedOrNot();
        //  getPhonpayURL();
        // ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(finalResult ['message'].toString())));
        isAvailableDelivery = false;
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(finalResult['message'].toString())));
      }
    } else {
      print(response.reasonPhrase);
    }
  }

  promoSheet() {
    showModalBottomSheet<dynamic>(
        context: context,
        isScrollControlled: true,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.only(
                topLeft: Radius.circular(25), topRight: Radius.circular(25))),
        builder: (builder) {
          return StatefulBuilder(
              builder: (BuildContext context, StateSetter setState) {
            return Padding(
              padding: MediaQuery.of(context).viewInsets,
              child: Container(
                  padding: EdgeInsets.only(left: 10, right: 10, top: 50),
                  constraints: BoxConstraints(
                      maxHeight: MediaQuery.of(context).size.height * 0.9),
                  child: ListView(shrinkWrap: true, children: <Widget>[
                    Stack(
                      alignment: Alignment.centerRight,
                      children: [
                        Container(
                            margin: const EdgeInsetsDirectional.only(end: 20),
                            decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.white,
                                borderRadius:
                                    BorderRadiusDirectional.circular(10)),
                            child: TextField(
                              controller: promoC,
                              style: Theme.of(context).textTheme.subtitle2,
                              decoration: InputDecoration(
                                contentPadding:
                                    EdgeInsets.symmetric(horizontal: 10),
                                border: InputBorder.none,
                                //isDense: true,
                                hintText:
                                    getTranslated(context, 'PROMOCODE_LBL'),
                              ),
                            )),
                        Positioned.directional(
                          textDirection: Directionality.of(context),
                          end: 0,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              (promoAmt != 0 && isPromoValid!)
                                  ? Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: InkWell(
                                        child: Icon(
                                          Icons.close,
                                          size: 15,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .fontColor,
                                        ),
                                        onTap: () {
                                          if (promoAmt != 0 && isPromoValid!) {
                                            if (mounted)
                                              setState(() {
                                                totalPrice =
                                                    totalPrice + promoAmt;
                                                promoC.text = '';
                                                isPromoValid = false;
                                                promoAmt = 0;
                                                promocode = '';
                                              });
                                          }
                                        },
                                      ),
                                    )
                                  : Container(),
                              InkWell(
                                child: Container(
                                    padding: EdgeInsets.all(11),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: colors.primary,
                                    ),
                                    child: Icon(
                                      Icons.arrow_forward,
                                      color:
                                          Theme.of(context).colorScheme.white,
                                    )),
                                onTap: () {
                                  if (promoC.text.trim().isEmpty)
                                    setSnackbar(
                                        getTranslated(context, 'ADD_PROMO')!,
                                        _checkscaffoldKey);
                                  else if (!isPromoValid!) {
                                    validatePromo(false);
                                    Navigator.pop(context);
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 18.0),
                      child: Text(
                        getTranslated(context, 'Choose_PROMO') ?? '',
                        style: Theme.of(context).textTheme.subtitle1!.copyWith(
                            color: Theme.of(context).colorScheme.fontColor),
                      ),
                    ),
                    ListView.builder(
                        physics: NeverScrollableScrollPhysics(),
                        shrinkWrap: true,
                        itemCount: promoList.length,
                        itemBuilder: (context, index) {
                          return Card(
                            elevation: 0,
                            child: Row(
                              children: [
                                Container(
                                  height: 80,
                                  width: 80,
                                  child: ClipRRect(
                                      borderRadius: BorderRadius.circular(7.0),
                                      child: Image.network(
                                        promoList[index].image!,
                                        height: 80,
                                        width: 80,
                                        fit: BoxFit.fill,
                                        errorBuilder:
                                            (context, error, stackTrace) =>
                                                erroWidget(
                                          80,
                                        ),
                                      )),
                                ),

                                //errorWidget: (context, url, e) => placeHolder(width),

                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(promoList[index].msg ?? ""),
                                        Text(promoList[index].promoCode ?? ''),
                                      ],
                                    ),
                                  ),
                                ),
                                Text(promoList[index].day ?? ''),
                                SimBtn(
                                  size: 0.3,
                                  title: getTranslated(context, "APPLY"),
                                  onBtnSelected: () {
                                    print(
                                        "promocode section here${promoList[index].promoCode} and ${isPromoValid}}");
                                    promoC.text = promoList[index].promoCode!;
                                    //if (!isPromoValid!)

                                    validatePromo(false);
                                    // _getCart("");
                                    Navigator.of(context).pop();
                                  },
                                ),
                              ],
                            ),
                          );
                        }),
                  ])),
            );
            //});
          });
        });
  }

  Future<Null> _getSaveLater(String save) async {
    _isNetworkAvail = await isNetworkAvailable();
    if (_isNetworkAvail) {
      try {
        var parameter = {USER_ID: CUR_USERID, SAVE_LATER: save};
        Response response =
            await post(getCartApi, body: parameter, headers: headers)
                .timeout(Duration(seconds: timeOut));

        var getdata = json.decode(response.body);
        bool error = getdata["error"];
        String? msg = getdata["message"];
        if (!error) {
          var data = getdata["data"];

          saveLaterList = (data as List)
              .map((data) => new SectionModel.fromCart(data))
              .toList();

          List<SectionModel> cartList = context.read<CartProvider>().cartList;
          for (int i = 0; i < cartList.length; i++)
            _controller.add(new TextEditingController());
        } else {
          if (msg != 'Cart Is Empty !') setSnackbar(msg!, _scaffoldKey);
        }
        if (mounted) setState(() {});
      } on TimeoutException catch (_) {
        setSnackbar(getTranslated(context, 'somethingMSg')!, _scaffoldKey);
      }
    } else {
      if (mounted)
        setState(() {
          _isNetworkAvail = false;
        });
    }

    return null;
  }

  Future<void> addToCart(
      int index, String qty, List<SectionModel> cartList) async {
    _isNetworkAvail = await isNetworkAvailable();

    //if (int.parse(qty) >= cartList[index].productList[0].minOrderQuntity) {
    if (_isNetworkAvail) {
      try {
        context.read<CartProvider>().setProgress(true);

        if (int.parse(qty) < cartList[index].productList![0].minOrderQuntity!) {
          qty = cartList[index].productList![0].minOrderQuntity.toString();

          setSnackbar(
              "${getTranslated(context, 'MIN_MSG')}$qty", _checkscaffoldKey);
        }
        List<String> idList = [];
        List<String> qtyList = [];
        if (cartList[index].productList![0].addOnList != null &&
            cartList[index].productList![0].addOnList!.isNotEmpty) {
          cartList[index].productList![0].addOnList!.forEach((element) {
            idList.add(element.id!);
            qtyList.add(
                (/*int.parse(element.quantity ?? "0") + */ int.parse(qty))
                    .toString());
          });
        }

        var parameter = {
          PRODUCT_VARIENT_ID: cartList[index].varientId,
          USER_ID: CUR_USERID,
          QTY: qty,
          // 'subscription_type': model.subscriptionProduct,
          'seller_id': newSellerId.toString(),
        };
        if (idList.isNotEmpty) {
          parameter['add_on_id'] = idList.join(",");
          parameter['add_on_qty'] = qtyList.join(",");
        }
        print(manageCartApi);
        print(parameter);
        Response response =
            await post(manageCartApi, body: parameter, headers: headers)
                .timeout(Duration(seconds: timeOut));

        var getdata = json.decode(response.body);
        print(getdata);
        bool error = getdata["error"];
        String? msg = getdata["message"];
        if (!error) {
          var data = getdata["data"];
          _refresh();
          String qty = data['total_quantity'];
          //CUR_CART_COUNT = data['cart_count'];

          context.read<UserProvider>().setCartCount(data['cart_count']);
          cartList[index].qty = qty;

          oriPrice = double.parse(data['sub_total']);

          _controller[index].text = qty;
          totalPrice = 0;

          var cart = getdata["cart"];
          List<SectionModel> uptcartList = (cart as List)
              .map((cart) => new SectionModel.fromCart(cart))
              .toList();
          context.read<CartProvider>().setCartlist(uptcartList);

          if (!ISFLAT_DEL) {
            if (addressList.length == 0) {
              delCharge = 0;
            } else {
              if (addressList[selectedAddress!].freeAmt == "" ||
                  addressList[selectedAddress!].freeAmt == 0.0 ||
                  addressList[selectedAddress!].freeAmt == null) {
              } else {
                if ((oriPrice) <
                    double.parse(addressList[selectedAddress!].freeAmt!))
                  delCharge = double.parse(
                      addressList[selectedAddress!].deliveryCharge!);
                else
                  delCharge = 0;
              }
            }
          } else {
            if (oriPrice < double.parse(MIN_AMT!))
              delCharge = double.parse(CUR_DEL_CHR!);
            else
              delCharge = 0;
          }
          totalPrice = delCharge + oriPrice;

          if (isPromoValid!) {
            validatePromo(false);
          } else if (isUseWallet!) {
            context.read<CartProvider>().setProgress(false);
            if (mounted)
              setState(() {
                remWalBal = 0;
                payMethod = null;
                usedBal = 0;
                isUseWallet = false;
                isPayLayShow = true;

                selectedMethod = null;
              });
          } else {
            setState(() {});
            context.read<CartProvider>().setProgress(false);
          }
        } else {
          setSnackbar(msg!, _scaffoldKey);
          context.read<CartProvider>().setProgress(false);
        }
      } on TimeoutException catch (_) {
        setSnackbar(getTranslated(context, 'somethingMSg')!, _scaffoldKey);
        context.read<CartProvider>().setProgress(false);
      }
    } else {
      if (mounted)
        setState(() {
          _isNetworkAvail = false;
        });
    }
    // } else
    // setSnackbar(
    //     "Minimum allowed quantity is ${cartList[index].productList[0].minOrderQuntity} ",
    //     _scaffoldKey);
  }

  Future<void> addToCartCheckout(
      int index, String qty, List<SectionModel> cartList) async {
    _isNetworkAvail = await isNetworkAvailable();
    if (_isNetworkAvail) {
      try {
        context.read<CartProvider>().setProgress(true);

        if (int.parse(qty) < cartList[index].productList![0].minOrderQuntity!) {
          qty = cartList[index].productList![0].minOrderQuntity.toString();

          setSnackbar(
              "${getTranslated(context, 'MIN_MSG')}$qty", _checkscaffoldKey);
        }

        var parameter = {
          PRODUCT_VARIENT_ID: cartList[index].varientId,
          USER_ID: CUR_USERID,
          QTY: qty,
          'seller_id': newSellerId.toString(),
        };

        Response response =
            await post(manageCartApi, body: parameter, headers: headers)
                .timeout(Duration(seconds: timeOut));
        if (response.statusCode == 200) {
          var getdata = json.decode(response.body);

          bool error = getdata["error"];
          String? msg = getdata["message"];
          if (!error) {
            var data = getdata["data"];

            String qty = data['total_quantity'];
            // CUR_CART_COUNT = data['cart_count'];

            context.read<UserProvider>().setCartCount(data['cart_count']);
            cartList[index].qty = qty;

            oriPrice = double.parse(data['sub_total']);
            _controller[index].text = qty;
            totalPrice = 0;

            if (!ISFLAT_DEL) {
              if ((oriPrice) <
                  double.parse(addressList[selectedAddress!].freeAmt!))
                delCharge =
                    double.parse(addressList[selectedAddress!].deliveryCharge!);
              else
                delCharge = 0;
            } else {
              if ((oriPrice) < double.parse(MIN_AMT!))
                delCharge = double.parse(CUR_DEL_CHR!);
              else
                delCharge = 0;
            }
            totalPrice = delCharge + oriPrice;

            if (isPromoValid!) {
              validatePromo(true);
            } else if (isUseWallet!) {
              if (mounted)
                checkoutState!(() {
                  remWalBal = 0;
                  payMethod = null;
                  usedBal = 0;
                  isUseWallet = false;
                  isPayLayShow = true;

                  selectedMethod = null;
                });
              setState(() {});
            } else {
              context.read<CartProvider>().setProgress(false);
              setState(() {});
              checkoutState!(() {});
            }
          } else {
            setSnackbar(msg!, _checkscaffoldKey);
            context.read<CartProvider>().setProgress(false);
          }
        }
      } on TimeoutException catch (_) {
        setSnackbar(getTranslated(context, 'somethingMSg')!, _checkscaffoldKey);
        context.read<CartProvider>().setProgress(false);
      }
    } else {
      if (mounted)
        checkoutState!(() {
          _isNetworkAvail = false;
        });
      setState(() {});
    }
  }

  saveForLater(String? id, String save, String? qty, double price,
      SectionModel curItem, bool fromSave) async {
    _isNetworkAvail = await isNetworkAvailable();
    if (_isNetworkAvail) {
      try {
        context.read<CartProvider>().setProgress(true);

        var parameter = {
          PRODUCT_VARIENT_ID: id,
          USER_ID: CUR_USERID,
          QTY: qty,
          SAVE_LATER: save,
          'seller_id': newSellerId.toString(),
        };

        print("param****save***********$parameter");

        Response response =
            await post(manageCartApi, body: parameter, headers: headers)
                .timeout(Duration(seconds: timeOut));

        var getdata = json.decode(response.body);

        bool error = getdata["error"];
        String? msg = getdata["message"];
        if (!error) {
          var data = getdata["data"];
          // CUR_CART_COUNT = data['cart_count'];
          context.read<UserProvider>().setCartCount(data['cart_count']);
          if (save == "1") {
            setSnackbar("Saved For Later", _scaffoldKey);
            saveLaterList.add(curItem);
            //cartList.removeWhere((item) => item.varientId == id);
            context.read<CartProvider>().removeCartItem(id!);
            setState(() {
              saveLater = false;
            });
            oriPrice = oriPrice - price;
          } else {
            setSnackbar("Added To Cart", _scaffoldKey);
            // cartList.add(curItem);
            context.read<CartProvider>().addCartItem(curItem);
            saveLaterList.removeWhere((item) => item.varientId == id);
            setState(() {
              addCart = false;
            });
            oriPrice = oriPrice + price;
          }

          totalPrice = 0;

          if (!ISFLAT_DEL) {
            if (addressList.length > 0 &&
                (oriPrice) <
                    double.parse(addressList[selectedAddress!].freeAmt!)) {
              delCharge =
                  double.parse(addressList[selectedAddress!].deliveryCharge!);
            } else {
              delCharge = 0;
            }
          } else {
            if ((oriPrice) < double.parse(MIN_AMT!)) {
              delCharge = double.parse(CUR_DEL_CHR!);
            } else {
              delCharge = 0;
            }
          }
          totalPrice = delCharge + oriPrice;

          if (isPromoValid!) {
            validatePromo(false);
          } else if (isUseWallet!) {
            context.read<CartProvider>().setProgress(false);
            if (mounted)
              setState(() {
                remWalBal = 0;
                payMethod = null;
                usedBal = 0;
                isUseWallet = false;
                isPayLayShow = true;
              });
          } else {
            context.read<CartProvider>().setProgress(false);
            setState(() {});
          }
        } else {
          setSnackbar(msg!, _scaffoldKey);
        }

        context.read<CartProvider>().setProgress(false);
      } on TimeoutException catch (_) {
        setSnackbar(getTranslated(context, 'somethingMSg')!, _scaffoldKey);
        context.read<CartProvider>().setProgress(false);
      }
    } else {
      if (mounted)
        setState(() {
          _isNetworkAvail = false;
        });
    }
  }

  removeFromCartCheckout(
      int index, bool remove, List<SectionModel> cartList) async {
    _isNetworkAvail = await isNetworkAvailable();

    if (!remove &&
        int.parse(cartList[index].qty!) ==
            cartList[index].productList![0].minOrderQuntity) {
      setSnackbar("${getTranslated(context, 'MIN_MSG')}${cartList[index].qty}",
          _checkscaffoldKey);
    } else {
      if (_isNetworkAvail) {
        try {
          context.read<CartProvider>().setProgress(true);

          int? qty;
          if (remove)
            qty = 0;
          else {
            qty = (int.parse(cartList[index].qty!) -
                int.parse(cartList[index].productList![0].qtyStepSize!));

            if (qty < cartList[index].productList![0].minOrderQuntity!) {
              qty = cartList[index].productList![0].minOrderQuntity;

              setSnackbar("${getTranslated(context, 'MIN_MSG')}$qty",
                  _checkscaffoldKey);
            }
          }

          var parameter = {
            PRODUCT_VARIENT_ID: cartList[index].varientId,
            USER_ID: CUR_USERID,
            QTY: qty.toString(),
            'seller_id': newSellerId.toString()
          };

          Response response =
              await post(manageCartApi, body: parameter, headers: headers)
                  .timeout(Duration(seconds: timeOut));

          if (response.statusCode == 200) {
            var getdata = json.decode(response.body);

            bool error = getdata["error"];
            String? msg = getdata["message"];
            if (!error) {
              var data = getdata["data"];

              String? qty = data['total_quantity'];
              // CUR_CART_COUNT = data['cart_count'];

              context.read<UserProvider>().setCartCount(data['cart_count']);
              if (qty == "0") remove = true;

              if (remove) {
                // cartList.removeWhere((item) => item.varientId == cartList[index].varientId);

                context
                    .read<CartProvider>()
                    .removeCartItem(cartList[index].varientId!);
              } else {
                cartList[index].qty = qty.toString();
              }

              oriPrice = double.parse(data[SUB_TOTAL]);
              print("mmmmmmmmmmmmm ${CUR_DEL_CHR}");
              if (!ISFLAT_DEL) {
                if ((oriPrice) <
                    double.parse(addressList[selectedAddress!].freeAmt!))
                  delCharge = double.parse(
                      addressList[selectedAddress!].deliveryCharge!);
                else
                  delCharge = 0;
              } else {
                if ((oriPrice) < double.parse(MIN_AMT!))
                  delCharge = double.parse(CUR_DEL_CHR!);
                else
                  delCharge = 0;
              }

              totalPrice = 0;

              totalPrice = delCharge + oriPrice;

              if (isPromoValid!) {
                validatePromo(true);
              } else if (isUseWallet!) {
                if (mounted)
                  checkoutState!(() {
                    remWalBal = 0;
                    payMethod = null;
                    usedBal = 0;
                    isPayLayShow = true;
                    isUseWallet = false;
                  });
                context.read<CartProvider>().setProgress(false);
                setState(() {});
              } else {
                context.read<CartProvider>().setProgress(false);

                checkoutState!(() {});
                setState(() {});
              }
            } else {
              setSnackbar(msg!, _checkscaffoldKey);
              context.read<CartProvider>().setProgress(false);
            }
          }
        } on TimeoutException catch (_) {
          setSnackbar(
              getTranslated(context, 'somethingMSg')!, _checkscaffoldKey);
          context.read<CartProvider>().setProgress(false);
        }
      } else {
        if (mounted)
          checkoutState!(() {
            _isNetworkAvail = false;
          });
        setState(() {});
      }
    }
  }

  removeFromCart(int index, bool remove, List<SectionModel> cartList, bool move,
      int selPos) async {
    _isNetworkAvail = await isNetworkAvailable();
    if (!remove &&
        int.parse(cartList[index].qty!) ==
            cartList[index].productList![0].minOrderQuntity) {
      setSnackbar("${getTranslated(context, 'MIN_MSG')}${cartList[index].qty}",
          _scaffoldKey);
    } else {
      if (_isNetworkAvail) {
        try {
          context.read<CartProvider>().setProgress(true);

          int qty;
          if (remove)
            qty = 0;
          else {
            qty = (int.parse(cartList[index].qty!) -
                int.parse(cartList[index].productList![0].qtyStepSize!));

            if (qty < cartList[index].productList![0].minOrderQuntity!) {
              qty = cartList[index].productList![0].minOrderQuntity ?? 0;

              setSnackbar("${getTranslated(context, 'MIN_MSG')}$qty",
                  _checkscaffoldKey);
            }
          }
          String varId;
          if (cartList[index].productList![0].availability == "0") {
            varId = cartList[index].productList![0].prVarientList![selPos].id!;
          } else {
            varId = cartList[index].varientId!;
          }
          List<String> idList = [];
          List<String> qtyList = [];
          if (cartList[index].productList![0].addOnList != null &&
              cartList[index].productList![0].addOnList!.isNotEmpty) {
            cartList[index].productList![0].addOnList!.forEach((element) {
              idList.add(element.id!);
              qtyList.add((qty).toString());
            });
          }
          print("carient**********${cartList[index].varientId}");
          var parameter = {
            PRODUCT_VARIENT_ID: varId,
            USER_ID: CUR_USERID,
            QTY: qty.toString(),
            'seller_id': newSellerId.toString()
          };
          if (idList.isNotEmpty) {
            parameter['add_on_id'] = idList.join(",");
            parameter['add_on_qty'] = qtyList.join(",");
          }
          print(manageCartApi);
          print(parameter);
          Response response =
              await post(manageCartApi, body: parameter, headers: headers)
                  .timeout(Duration(seconds: timeOut));

          var getdata = json.decode(response.body);
          print(getdata);

          bool error = getdata["error"];
          String? msg = getdata["message"];
          if (!error) {
            print("msg************$msg");
            var data = getdata["data"];
            _refresh();
            setSnackbar("$msg", _scaffoldKey);
            String? qty = data['total_quantity'];
            // CUR_CART_COUNT = data['cart_count'];

            context.read<UserProvider>().setCartCount(data['cart_count']);
            if (move == false) {
              if (qty == "0") remove = true;

              if (remove) {
                cartList.removeWhere(
                    (item) => item.varientId == cartList[index].varientId);
              } else {
                cartList[index].qty = qty.toString();
              }

              oriPrice = double.parse(data[SUB_TOTAL]);
              if (!ISFLAT_DEL) {
                try {
                  if ((oriPrice) <
                      double.parse(addressList[selectedAddress!].freeAmt!))
                    delCharge = double.parse(
                        addressList[selectedAddress!].deliveryCharge!);
                  else
                    delCharge = 0;
                } catch (e) {
                  print(e);
                }
              } else {
                if ((oriPrice) < double.parse(MIN_AMT!))
                  delCharge = double.parse(CUR_DEL_CHR!);
                else
                  delCharge = 0;
              }

              totalPrice = 0;

              totalPrice = delCharge + oriPrice;
              if (isPromoValid!) {
                validatePromo(false);
              } else if (isUseWallet!) {
                context.read<CartProvider>().setProgress(false);
                if (mounted)
                  setState(() {
                    remWalBal = 0;
                    payMethod = null;
                    usedBal = 0;
                    isPayLayShow = true;
                    isUseWallet = false;
                  });
              } else {
                context.read<CartProvider>().setProgress(false);
                setState(() {});
              }
            } else {
              if (qty == "0") remove = true;

              if (remove) {
                cartList.removeWhere(
                    (item) => item.varientId == cartList[index].varientId);
              }
            }
          } else {
            print("msg111************$msg");
            setSnackbar(msg!, _scaffoldKey);
          }
          if (mounted) setState(() {});
          context.read<CartProvider>().setProgress(false);
        } on TimeoutException catch (_) {
          setSnackbar(getTranslated(context, 'somethingMSg')!, _scaffoldKey);
          context.read<CartProvider>().setProgress(false);
        }
      } else {
        if (mounted)
          setState(() {
            _isNetworkAvail = false;
          });
      }
    }
  }



  setSnackbar(
      String msg, GlobalKey<ScaffoldMessengerState> _scaffoldMessengerKey) {
    ScaffoldMessenger.of(context).showSnackBar(new SnackBar(
      duration: Duration(seconds: 1),
      content: new Text(
        msg,
        textAlign: TextAlign.center,
        style: TextStyle(color: Theme.of(context).colorScheme.black),
      ),
      backgroundColor: Theme.of(context).colorScheme.white,
      elevation: 1.0,
    ));
  }

  _showContent(BuildContext context) {
    List<SectionModel> cartList = context.read<CartProvider>().cartList;
    print("cart list************${cartList.length}");
    return _isCartLoad
        ? shimmer(context)
        : cartList.length == 0 && saveLaterList.length == 0
            ? cartEmpty()
            : Column(
                children: <Widget>[
                  Expanded(
                    child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10.0),
                        child: RefreshIndicator(
                            color: colors.primary,
                            key: _refreshIndicatorKey,
                            onRefresh: _refresh,
                            child: SingleChildScrollView(
                              physics: const AlwaysScrollableScrollPhysics(),
                              child: Column(
                                mainAxisSize: MainAxisSize.max,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  ListView.builder(
                                    shrinkWrap: true,
                                    itemCount: cartList.length,
                                    physics: NeverScrollableScrollPhysics(),
                                    itemBuilder: (context, index) {
                                      return listItem(index, cartList);
                                    },
                                  ),
                                  saveLaterList.length > 0
                                      ? Padding(
                                          padding: const EdgeInsets.all(8.0),
                                          child: Text(
                                            getTranslated(
                                                context, 'SAVEFORLATER_BTN')!,
                                            style: Theme.of(context)
                                                .textTheme
                                                .subtitle1!
                                                .copyWith(
                                                    color: Theme.of(context)
                                                        .colorScheme
                                                        .fontColor),
                                          ),
                                        )
                                      : Container(),
                                  ListView.builder(
                                    shrinkWrap: true,
                                    itemCount: saveLaterList.length,
                                    physics: NeverScrollableScrollPhysics(),
                                    itemBuilder: (context, index) {
                                      return saveLaterItem(index);
                                    },
                                  ),
                                ],
                              ),
                            ))),
                  ),
                  Container(
                    child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          promoList.length > 0 && oriPrice > 0
                              ? Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10.0),
                                  child: InkWell(
                                    child: Stack(
                                      alignment: Alignment.centerRight,
                                      children: [
                                        Container(
                                            margin: const EdgeInsetsDirectional
                                                .only(end: 20),
                                            decoration: BoxDecoration(
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .white,
                                                borderRadius:
                                                    BorderRadiusDirectional
                                                        .circular(10)),
                                            child: TextField(
                                              textDirection:
                                                  Directionality.of(context),
                                              enabled: false,
                                              controller: promoC,
                                              readOnly: true,
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .subtitle2,
                                              decoration: InputDecoration(
                                                contentPadding:
                                                    EdgeInsets.symmetric(
                                                        horizontal: 10),
                                                border: InputBorder.none,
                                                //isDense: true,
                                                hintText: getTranslated(context,
                                                        'PROMOCODE_LBL') ??
                                                    '',
                                              ),
                                            )),
                                        Positioned.directional(
                                          textDirection:
                                              Directionality.of(context),
                                          end: 0,
                                          child: Container(
                                              padding: EdgeInsets.all(11),
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                color: colors.primary,
                                              ),
                                              child: Icon(
                                                Icons.arrow_forward,
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .white,
                                              )),
                                        ),
                                      ],
                                    ),
                                    onTap: promoSheet,
                                  ),
                                )
                              : Container(),
                          Container(
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.white,
                                borderRadius: BorderRadius.all(
                                  Radius.circular(10),
                                ),
                              ),
                              margin: EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 8),
                              padding: EdgeInsets.symmetric(
                                  vertical: 10, horizontal: 5),
                              //  width: deviceWidth! * 0.9,
                              child: Column(
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(getTranslated(
                                          context, 'TOTAL_PRICE')!),
                                      Text(
                                        CUR_CURRENCY! +
                                            " ${oriPrice.toStringAsFixed(2)}",
                                        style: Theme.of(context)
                                            .textTheme
                                            .subtitle1!
                                            .copyWith(
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .fontColor),
                                      ),
                                    ],
                                  ),
                                  isPromoValid!
                                      ? Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              getTranslated(context,
                                                  'PROMO_CODE_DIS_LBL')!,
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .caption!
                                                  .copyWith(
                                                      color: Theme.of(context)
                                                          .colorScheme
                                                          .lightBlack2),
                                            ),
                                            Text(
                                              CUR_CURRENCY! +
                                                  " " +
                                                  promoAmt.toString(),
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .caption!
                                                  .copyWith(
                                                      color: Theme.of(context)
                                                          .colorScheme
                                                          .lightBlack2),
                                            )
                                          ],
                                        )
                                      : Container(),
                                ],
                              )),
                          activeStatus == "1"
                              ? SimBtn(
                                  size: 0.9,
                                  title: getTranslated(
                                      context, 'PROCEED_CHECKOUT'),
                                  onBtnSelected: () async {
                                    if (oriPrice > 0) {
                                      FocusScope.of(context).unfocus();
                                      if (isAvailable) {
                                        checkout(cartList);
                                        finalTotalValue = totalPrice.toInt();
                                        print(
                                            "checking here final value here 11111 $finalTotalValue");
                                      } else {
                                        setSnackbar(
                                            getTranslated(context,
                                                'CART_OUT_OF_STOCK_MSG')!,
                                            _scaffoldKey);
                                      }
                                      if (mounted) setState(() {});
                                    } else
                                      setSnackbar(
                                          getTranslated(context, 'ADD_ITEM')!,
                                          _scaffoldKey);
                                  })
                              : MaterialButton(
                                  onPressed: () {},
                                  child: Text(
                                    "Can't not order, you are Inactive",
                                    style: TextStyle(color: Colors.white),
                                  ),
                                  color: colors.primary,
                                ),
                        ]),
                  ),
                ],
              );
  }

  cartEmpty() {
    return Center(
      child: SingleChildScrollView(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          noCartImage(context),
          noCartText(context),
          noCartDec(context),
          shopNow()
        ]),
      ),
    );
  }

  getAllPromo() {}

  noCartImage(BuildContext context) {
    return SvgPicture.asset(
      'assets/images/empty_cart.svg',
      fit: BoxFit.contain,
      color: colors.primary,
    );
  }

  noCartText(BuildContext context) {
    return Container(
        child: Text(getTranslated(context, 'NO_CART')!,
            style: Theme.of(context).textTheme.headline5!.copyWith(
                color: colors.primary, fontWeight: FontWeight.normal)));
  }

  noCartDec(BuildContext context) {
    return Container(
      padding: EdgeInsetsDirectional.only(top: 30.0, start: 30.0, end: 30.0),
      child: Text(getTranslated(context, 'CART_DESC')!,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headline6!.copyWith(
                color: Theme.of(context).colorScheme.lightBlack2,
                fontWeight: FontWeight.normal,
              )),
    );
  }

  shopNow() {
    return Padding(
      padding: const EdgeInsetsDirectional.only(top: 28.0),
      child: CupertinoButton(
        child: Container(
            width: deviceWidth! * 0.7,
            height: 45,
            alignment: FractionalOffset.center,
            decoration: new BoxDecoration(
              color: colors.primary,
              // gradient: LinearGradient(
              //     begin: Alignment.topLeft,
              //     end: Alignment.bottomRight,
              //     colors: [colors.grad1Color, colors.grad2Color],
              //     stops: [0, 1]),
              borderRadius: new BorderRadius.all(const Radius.circular(50.0)),
            ),
            child: Text(getTranslated(context, 'SHOP_NOW')!,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headline6!.copyWith(
                    color: Theme.of(context).colorScheme.white,
                    fontWeight: FontWeight.normal))),
        onPressed: () {
          Navigator.of(context).pushNamedAndRemoveUntil(
              '/home', (Route<dynamic> route) => false);
        },
      ),
    );
  }

  static int roundUpAbsolute(double number) {
    //return number.isNegative ? number.floor() : number.ceil();
    print('___________${number}__________');
    print('___________${number.floor()}__________');
    double decimalPart = number - number.floor();
    if (decimalPart >= 0.5) {
      return number.isNegative ? number.ceil() : number.floor() + 1;
    } else {
      return number.floor();
    }
  }
  double currentPrice = 0;
  checkout(List<SectionModel> cartList) {
    _razorpay = Razorpay();
    _razorpay!.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay!.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay!.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);

    deviceHeight = MediaQuery.of(context).size.height;
    deviceWidth = MediaQuery.of(context).size.width;

    setState(() {
      _isLoading = false;
    });
    return showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.only(
                topLeft: Radius.circular(10), topRight: Radius.circular(10))),
        builder: (builder) {
          return StatefulBuilder(
              builder: (BuildContext context, StateSetter setState) {
            checkoutState = setState;
            print('___________${cartList[0].productList![0].selfPickup}___ffgs_______');
            print('___________${selfPickup}___ffgs_______');
            totalPrice = roundUpAbsolute(totalPrice).toDouble();
            return Container(
                constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.8),
                child: Scaffold(
                  resizeToAvoidBottomInset: false,
                  key: _checkscaffoldKey,
                  body: _isNetworkAvail
                      ? cartList.length == 0
                          ? cartEmpty()
                          : _isLoading
                              ? shimmer(context)
                              : Column(
                                  children: [
                                    Expanded(
                                      child: Stack(
                                        children: <Widget>[
                                          SingleChildScrollView(
                                            child: Padding(
                                              padding:
                                                  const EdgeInsets.all(10.0),
                                              child: Column(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Text(firstUser?"Your first order is free":"",style: TextStyle(
                                                      color: Colors.green
                                                  ),),
                                                  const SizedBox(height: 5,),
                                                  address(),
                                                  payment(),
                                                  selfPickup == "1" ?
                                                  pickupCustomer(() async {
                                                    setState(() {
                                                      print(pickCustomer.toString()+"PICKUP");
                                                      if (pickCustomer) {
                                                        pickCustomer = false;
                                                        totalPrice -= (delCharge*days);
                                                      } else {
                                                        pickCustomer = true;
                                                        totalPrice += (delCharge*days);
                                                      }
                                                    });
                                                  }):
                                                  cartItems(cartList,setState),
                                                  // promo(),
                                                  orderSummary(cartList),
                                                ],
                                              ),
                                            ),
                                          ),
                                          Selector<CartProvider, bool>(
                                            builder: (context, data, child) {
                                              return showCircularProgress(data, colors.primary);
                                            },
                                            selector: (_, provider) =>
                                                provider.isProgress,
                                          ),
                                          /*   showCircularProgress(
                                              _isProgress, colors.primary),*/
                                        ],
                                      ),
                                    ),
                                    Container(
                                      color:
                                          Theme.of(context).colorScheme.white,
                                      child: Row(children: <Widget>[
                                        Padding(
                                            padding: EdgeInsetsDirectional.only(
                                                start: 15.0),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  CUR_CURRENCY! +
                                                      " ${totalPrice.toStringAsFixed(2)}",
                                                  style: TextStyle(
                                                      color: Theme.of(context)
                                                          .colorScheme
                                                          .fontColor,
                                                      fontWeight:
                                                          FontWeight.bold),
                                                ),
                                                Text(
                                                    cartList.length.toString() +
                                                        " Items"),
                                              ],
                                            )),
                                        Spacer(),
                                        SimBtn(
                                            size: 0.4,
                                            title: getTranslated(
                                                context, 'PLACE_ORDER'),
                                            onBtnSelected: _placeOrder
                                                ? () {
                                                    checkoutState!(() {
                                                      _placeOrder = false;
                                                    });

                                                    if (selAddress == null ||
                                                        selAddress!.isEmpty) {
                                                      msg = getTranslated(
                                                          context,
                                                          'addressWarning');
                                                      Navigator.pushReplacement(
                                                          context,
                                                          MaterialPageRoute(
                                                            builder: (BuildContext
                                                                    context) =>
                                                                ManageAddress(
                                                              home: false,
                                                            ),
                                                          ));
                                                      checkoutState!(() {
                                                        _placeOrder = true;
                                                      });
                                                    } else if (payMethod == null ||
                                                        payMethod!.isEmpty) {
                                                      msg = getTranslated(
                                                          context,
                                                          'payWarning');
                                                      Navigator.push(
                                                          context,
                                                          MaterialPageRoute(
                                                              builder: (BuildContext
                                                                      context) =>
                                                                  Payment(
                                                                      updateCheckout,
                                                                      msg,
                                                                      finalTotalValue)));
                                                      checkoutState!(() {
                                                        _placeOrder = true;
                                                      });
                                                    }else if(payMethod=="Free"){
                                                     confirmDialog();
                                            }else if (isTimeSlot! &&
                                                        int.parse(allowDay!) >
                                                            0 &&
                                                        (selDate == null ||
                                                            selDate!.isEmpty)) {
                                                      msg = getTranslated(
                                                          context,
                                                          'dateWarning');
                                                      if(schedule == "immediately"){
                                                        confirmDialog();
                                                      }
                                                      else{
                                                        Navigator.push(
                                                            context,
                                                            MaterialPageRoute(
                                                                builder: (BuildContext
                                                                context) =>
                                                                    Payment(
                                                                        updateCheckout,
                                                                        msg,
                                                                        finalTotalValue)));
                                                      }

                                                      checkoutState!(() {
                                                        _placeOrder = true;
                                                      });
                                                    } else if (isTimeSlot! &&
                                                        timeSlotList.length >
                                                            0 &&
                                                        (selTime == null ||
                                                            selTime!.isEmpty)) {
                                                      msg = getTranslated(
                                                          context,
                                                          'timeWarning');
                                                      if(schedule == "immediately"){
                                                        confirmDialog();
                                                      }
                                                      else{
                                                        Navigator.push(
                                                            context,
                                                            MaterialPageRoute(
                                                                builder: (BuildContext
                                                                context) =>
                                                                    Payment(
                                                                        updateCheckout,
                                                                        msg,
                                                                        finalTotalValue)));
                                                      }
                                                      checkoutState!(() {
                                                        _placeOrder = true;
                                                      });
                                                    } else if (double.parse(
                                                            MIN_ALLOW_CART_AMT!) >
                                                        oriPrice) {
                                                      setSnackbar(
                                                          getTranslated(context,
                                                              'MIN_CART_AMT')!,
                                                          _checkscaffoldKey);
                                                    } else if (payMethod ==
                                                            'dfd' &&
                                                        isAvailableDelivery) {
                                                      checkAddressForDelivery();
                                                      checkoutState!(() {
                                                        _placeOrder = true;
                                                      });
                                                    } /*else if(payMethod == 'PhonePe'&& isAvailableDelivery){
                                                      checkAddressForDelivery();
                                                      checkoutState!(() {
                                                        _placeOrder = true;
                                                      });
                                                    }*/
                                                    // else if (!deliverable) {
                                                    //   checkDeliverable();
                                                    // }
                                                    else
                                                      confirmDialog();
                                                  }
                                                : null)
                                        //}),
                                      ]),
                                    ),
                                  ],
                                )
                      : noInternet(context),
                ));
          });
        });
  }

  doPayment() {
    print("payment method here $payMethod");

    if (payMethod == getTranslated(context, 'CC_AVENUE')) {
      // placeOrder('');
      checkAddressForDelivery();
      // _checkOrderShouldBePlacedOrNot ();
    } else if (payMethod == getTranslated(context, 'PAYPAL_LBL')) {
      placeOrder('');
    } else if (payMethod == getTranslated(context, 'RAZORPAY_LBL'))
    // _checkOrderShouldBePlacedOrNot ();
    // razorpayPayment();
    // else if (payMethod == getTranslated(context, 'PAYSTACK_LBL'))
    //   paystackPayment(context);
    {
    } else if (payMethod == getTranslated(context, 'FLUTTERWAVE_LBL'))
      flutterwavePayment();
    else if (payMethod == getTranslated(context, 'STRIPE_LBL'))
      stripePayment();
    else if (payMethod == getTranslated(context, 'PAYTM_LBL'))
      paytmPayment();
    /*  else if (payMethod ==
                                                        getTranslated(
                                                            context, 'GPAY')) {
                                                      googlePayment(
                                                          "google_pay");
                                                    } else if (payMethod ==
                                                        getTranslated(context,
                                                            'APPLEPAY')) {
                                                      googlePayment(
                                                          "apple_pay");
                                                    }*/
    else if (payMethod == getTranslated(context, 'BANKTRAN'))
      bankTransfer();
    else if (payMethod == getTranslated(context, 'COD_LBL')) {
      print("cod level is ");
      placeOrder('');
    } else if (payMethod == "Wallet") {
      placeOrder('');
    }else if (payMethod == "Free") {
      placeOrder('');
    }
  }

  getDeliveryCharge() async {
    var response = await apiBaseHelper.postAPICall(
        Uri.parse("${baseUrl}get_delivery_charge_distacee"),
        {"pincode": zipCode});
    if (!response['error']) {
      for (var v in response['data']) {
        delCharge = double.parse(v['delivery_charges'].toString());
      }
      setState(() {
        //totalPrice += delCharge;
        totalTax = ((delCharge + oriPrice + packagingCharge + platformFee)*taxPer / 100).toString();
        totalPrice =   oriPrice + double.parse(totalTax) + packagingCharge + platformFee +( !pickCustomer?0:delCharge);
      });
    }
  }

  Future<void> _checkOrderShouldBePlacedOrNot() async {
    _isNetworkAvail = await isNetworkAvailable();
    if (_isNetworkAvail) {
      try {
        var parameter = {
          USER_ID: CUR_USERID,
        };
        Response response = await post(checkOrderShouldBePlacedApi, body: parameter, headers: headers).timeout(Duration(seconds: timeOut));
        if (response.statusCode == 200) {
          var getdata = json.decode(response.body);
          print('${parameter}___parametercheck_____');
          print('${response.body}___parametercheckbody_____');
          bool error = getdata["error"];
          if (!error) {
            getPhonpayURL();
            //razorpayPayment();
          } else {
            setSnackbar(getdata["message"], _checkscaffoldKey);
          }
        } else {
          setSnackbar(
              getTranslated(context, 'somethingMSg')!, _checkscaffoldKey);
          if (mounted) setState(() {});
        }
      } on TimeoutException catch (_) {}
    } else {
      if (mounted)
        setState(() {
          _isNetworkAvail = false;
        });
    }
  }

  Future<void> _getAddress() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    _isNetworkAvail = await isNetworkAvailable();
    if (_isNetworkAvail) {
      try {
        var parameter = {
          USER_ID: CUR_USERID,
        };
        Response response =
            await post(getAddressApi, body: parameter, headers: headers)
                .timeout(Duration(seconds: timeOut));

        if (response.statusCode == 200) {
          var getdata = json.decode(response.body);

          bool error = getdata["error"];
          // String msg = getdata["message"];
          if (!error) {
            var data = getdata["data"];
            totalPrice -= delCharge;
            addressList = (data as List)
                .map((data) => new User.fromAddress(data))
                .toList();

            if (addressList.length == 1) {
              selectedAddress = 0;
              selAddress = addressList[0].id;

              if (!ISFLAT_DEL) {
                //  if (totalPrice < double.parse(addressList[0].freeAmt!)) {
                delCharge = double.parse(addressList[0].deliveryCharge!);
                prefs.setDouble('delicharge', delCharge);
                print("charge 1 ${delCharge}");
                // } else {
                //   delCharge = 0;
                // }
              }
            } else {
              for (int i = 0; i < addressList.length; i++) {
                if (addressList[i].isDefault == "1") {
                  selectedAddress = i;
                  selAddress = addressList[i].id;
                  // if (!ISFLAT_DEL) {
                  //   if (addressList[i].freeAmt == "0" ||
                  //       addressList[i].freeAmt == "") {
                  //   } else {
                  //     if (totalPrice < double.parse(addressList[i].freeAmt!)) {
                  //       delCharge =
                  //           double.parse(addressList[i].deliveryCharge!);
                  //       print("ddddddd ${delCharge}");
                  //     } else
                  //       delCharge = 0;
                  //   }
                  // }
                }
              }
              double newdel = 0.0;
              delCharge =
                  double.parse(addressList[selectedAddress!].deliveryCharge!);
              print('___________${delCharge}__________');
              //prefs.setDouble('delicharge', delCharge);
              print("final del charge here ${delCharge}");
              setState(() {});
            }
            if (ISFLAT_DEL) {
              if ((oriPrice) < double.parse(MIN_AMT ?? '0.0')) {
                delCharge = double.parse(CUR_DEL_CHR!);
                print("nnnnnnnnnnnn ${delCharge}");
              } else
                delCharge = 0;
            }
            delCharge = 0; //new Added
            totalPrice += delCharge;
          } else {
            if (ISFLAT_DEL) {
              if ((oriPrice) < double.parse(MIN_AMT!)) {
                delCharge = double.parse(CUR_DEL_CHR!);
                print("xxxxxxxxxx ${delCharge}");
              } else
                delCharge = 0;
            }
            delCharge = 0; //new Added
          }
          if (mounted) {
            setState(() {
              _isLoading = false;
            });
          }
          getDeliveryCharge();
          /*if (mounted && checkoutState != null) {
            checkoutState!(() {});
          }*/
          setState(() {
            _isLoading = false;
          });
        } else {
          setSnackbar(
              getTranslated(context, 'somethingMSg')!, _checkscaffoldKey);
          if (mounted)
            setState(() {
              _isLoading = false;
            });
        }
        setState(() {
          _isLoading = false;
        });
      } on TimeoutException catch (_) {}
    } else {
      if (mounted)
        setState(() {
          _isNetworkAvail = false;
        });
    }
  }

  Future<void> _getAddress2() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    _isNetworkAvail = await isNetworkAvailable();
    if (_isNetworkAvail) {
      try {
        var parameter = {
          USER_ID: CUR_USERID,
        };
        Response response =
            await post(getAddressApi, body: parameter, headers: headers)
                .timeout(Duration(seconds: timeOut));

        if (response.statusCode == 200) {
          var getdata = json.decode(response.body);

          bool error = getdata["error"];
          // String msg = getdata["message"];
          if (!error) {
            var data = getdata["data"];
            totalPrice -= delCharge;
            addressList = (data as List)
                .map((data) => new User.fromAddress(data))
                .toList();

            if (addressList.length == 1) {
              selectedAddress = 0;
              selAddress = addressList[0].id;

              if (!ISFLAT_DEL) {
                //  if (totalPrice < double.parse(addressList[0].freeAmt!)) {
                delCharge = double.parse(addressList[0].deliveryCharge!);
                prefs.setDouble('delicharge', delCharge);
                print("charge 1 ${delCharge}");
                // } else {
                //   delCharge = 0;
                // }
              }
            } else {
              for (int i = 0; i < addressList.length; i++) {
                /*if (addressList[i].isDefault == "1") {
                  selectedAddress = i;
                  selAddress = addressList[i].id;
                  // if (!ISFLAT_DEL) {
                  //   if (addressList[i].freeAmt == "0" ||
                  //       addressList[i].freeAmt == "") {
                  //   } else {
                  //     if (totalPrice < double.parse(addressList[i].freeAmt!)) {
                  //       delCharge =
                  //           double.parse(addressList[i].deliveryCharge!);
                  //       print("ddddddd ${delCharge}");
                  //     } else
                  //       delCharge = 0;
                  //   }
                  // }
                }*/
              }
              double newdel = 0.0;
              print(
                  '___________${addressList[selectedAddress!].deliveryCharge}__________');
              delCharge = double.parse(
                  addressList[selectedAddress!].deliveryCharge ?? '0.0');
              print('___________${delCharge}__________');
              //prefs.setDouble('delicharge', delCharge);
              print("final del charge here ${delCharge}");
              setState(() {});
            }
            if (ISFLAT_DEL) {
              if ((oriPrice) < double.parse(MIN_AMT ?? '0.0')) {
                delCharge = double.parse(CUR_DEL_CHR!);
                print("nnnnnnnnnnnn $delCharge");
              } else
                delCharge = 0;
            }
            delCharge = 0; //new Added
            totalPrice += delCharge;

            totalPrice -= promoAmt != 0 ? promoAmt : 0;
            checkoutState!(() {
              _isLoading = false;
            });
            //promoAmt
          } else {
            if (ISFLAT_DEL) {
              if ((oriPrice) < double.parse(MIN_AMT!)) {
                delCharge = double.parse(CUR_DEL_CHR!);
                print("xxxxxxxxxx ${delCharge}");
              } else
                delCharge = 0;
            }
            delCharge = 0; //new Added
          }
          getDeliveryCharge();
          // validatePromo( promoC.text.isNotEmpty ? true : false);
          if (mounted) {
            setState(() {
              _isLoading = false;
            });
          }

          /*if (mounted && checkoutState != null) {
            checkoutState!(() {});
          }*/
        } else {
          setSnackbar(
              getTranslated(context, 'somethingMSg')!, _checkscaffoldKey);
          if (mounted)
            setState(() {
              _isLoading = false;
              print('___________${_isLoading}__________');
            });
        }

        checkoutState!(() {
          _isLoading = false;
        });
      } on TimeoutException catch (_) {}
    } else {
      if (mounted)
        setState(() {
          _isNetworkAvail = false;
        });
    }
  }

  bool isAdreesChange = false;

  void _handlePaymentSuccess(PaymentSuccessResponse response) {
    print(" razor pay success order");
    placeOrder(response.paymentId);
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    print("error here now for order razor pay");
    var getdata = json.decode(response.message!);
    String errorMsg = getdata["error"]["description"];
    setSnackbar(errorMsg, _checkscaffoldKey);

    if (mounted)
      checkoutState!(() {
        _placeOrder = false;
      });
    context.read<CartProvider>().setProgress(false);
  }

  void _handleExternalWallet(ExternalWalletResponse response) {}

  updateCheckout() {
    //if (mounted) checkoutState!(() {});
  }
  razorpayPayment() async {
    SettingProvider settingsProvider =
        Provider.of<SettingProvider>(this.context, listen: false);

    String? contact = settingsProvider.mobile;
    String? email = settingsProvider.email;

    String amt = ((totalPrice) * 100).toStringAsFixed(2);

    if (contact != '' && email != '') {
      context.read<CartProvider>().setProgress(true);

      checkoutState!(() {});
      var options = {
        KEY: razorpayId,
        AMOUNT: amt,
        NAME: settingsProvider.userName,
        'prefill': {CONTACT: contact, EMAIL: email},
      };

      try {
        _razorpay!.open(options);
      } catch (e) {
        debugPrint(e.toString());
      }
    } else {
      if (email == '')
        setSnackbar(getTranslated(context, 'emailWarning')!, _checkscaffoldKey);
      else if (contact == '')
        setSnackbar(getTranslated(context, 'phoneWarning')!, _checkscaffoldKey);
    }
  }

  void paytmPayment() async {
    String? paymentResponse;
    context.read<CartProvider>().setProgress(true);

    String orderId = DateTime.now().millisecondsSinceEpoch.toString();

    String callBackUrl = (payTesting
            ? 'https://securegw-stage.paytm.in'
            : 'https://securegw.paytm.in') +
        '/theia/paytmCallback?ORDER_ID=' +
        orderId;

    var parameter = {
      AMOUNT: totalPrice.toString(),
      USER_ID: CUR_USERID,
      ORDER_ID: orderId
    };

    try {
      final response = await post(
        getPytmChecsumkApi,
        body: parameter,
        headers: headers,
      );

      var getdata = json.decode(response.body);

      bool error = getdata["error"];

      if (!error) {
        String txnToken = getdata["txn_token"];

        setState(() {
          paymentResponse = txnToken;
        });
        // orderId, mId, txnToken, txnAmount, callback
        print(
            "para are $paytmMerId # $orderId # $txnToken # ${totalPrice.toString()} # $callBackUrl  $payTesting");
        var paytmResponse = Paytm.payWithPaytm(
            callBackUrl: callBackUrl,
            mId: paytmMerId!,
            orderId: orderId,
            txnToken: txnToken,
            txnAmount: totalPrice.toString(),
            staging: payTesting);
        paytmResponse.then((value) {
          print("valie is $value");
          value.forEach((key, value) {
            print("key is $key");
            print("value is $value");
          });
          context.read<CartProvider>().setProgress(false);

          _placeOrder = true;
          setState(() {});
          checkoutState!(() {
            if (value['error']) {
              paymentResponse = value['errorMessage'];

              if (value['response'] != null)
                addTransaction(value['response']['TXNID'], orderId,
                    value['response']['STATUS'] ?? '', paymentResponse, false);
            } else {
              if (value['response'] != null) {
                paymentResponse = value['response']['STATUS'];
                if (paymentResponse == "TXN_SUCCESS") {
                  print("paytm order");
                  placeOrder(value['response']['TXNID']);
                } else
                  addTransaction(
                      value['response']['TXNID'],
                      orderId,
                      value['response']['STATUS'],
                      value['errorMessage'] ?? '',
                      false);
              }
            }

            setSnackbar(paymentResponse!, _checkscaffoldKey);
          });
        });
      } else {
        checkoutState!(() {
          _placeOrder = true;
        });

        context.read<CartProvider>().setProgress(false);

        setSnackbar(getdata["message"], _checkscaffoldKey);
      }
    } catch (e) {
      print(e);
    }
  }

  Future<void> placeOrder(String? tranId) async {
    print('______newwwwwwwww_____$totalPrice ${schedule}__________');

    _isNetworkAvail = await isNetworkAvailable();
    if (_isNetworkAvail) {
      context.read<CartProvider>().setProgress(true);

      SettingProvider settingsProvider =
          Provider.of<SettingProvider>(this.context, listen: false);

      String? mob = settingsProvider.mobile;

      String? varientId, quantity, packageFee;

      List<SectionModel> cartList = context.read<CartProvider>().cartList;
      bool subscription = false;
      for (SectionModel sec in cartList) {
        varientId = varientId != null
            ? varientId + "," + sec.varientId!
            : sec.varientId;
        subscription = sec.subscriptionType=="1"?true:false;
        quantity = quantity != null ? quantity + "," + sec.qty! : sec.qty;
        packageFee = packageFee != null
            ? packageFee + "," + sec.packingCharge!
            : sec.packingCharge;
      }
      String? payVia;
      if (payMethod == getTranslated(context, 'COD_LBL'))
        payVia = "UPI";
      else if (payMethod == getTranslated(context, 'PAYPAL_LBL'))
        payVia = "PayPal";
      else if (payMethod == getTranslated(context, 'PAYUMONEY_LBL'))
        payVia = "PayUMoney";
      else if (payMethod == getTranslated(context, 'RAZORPAY_LBL'))
        payVia = "Pay Now";
      else if (payMethod == getTranslated(context, 'PAYSTACK_LBL'))
        payVia = "Paystack";
      else if (payMethod == getTranslated(context, 'FLUTTERWAVE_LBL'))
        payVia = "Flutterwave";
      else if (payMethod == getTranslated(context, 'STRIPE_LBL'))
        payVia = "Stripe";
      else if (payMethod == getTranslated(context, 'PAYTM_LBL'))
        payVia = "Paytm";
      else if (payMethod == "Wallet")
        payVia = "Wallet";
      else if (payMethod == getTranslated(context, 'BANKTRAN'))
        payVia = "bank_transfer";
      else if (payMethod == getTranslated(context, 'CC_AVENUE')) {
        payVia = "PhonePe";
      }else if(payMethod=="Free"){
        payVia = "Free";
      }
      try {
        var parameter = {
          USER_ID: CUR_USERID,
          MOBILE: mob,
          PRODUCT_VARIENT_ID: varientId,
          QUANTITY: quantity,
          TOTAL: (oriPrice*days).toString(),
          FINAL_TOTAL: payVia == 'Wallet' ? usedBal.toString() : totalPrice.toString(),
          DEL_CHARGE: !pickCustomer ? "0" : (delCharge*days).toString(),
          // TAX_AMT: taxAmt.toString(),
          TAX_PER: taxPer.toString(),
          PAYMENT_METHOD: payVia,
          ADD_ID: selAddress,
          ISWALLETBALUSED: isUseWallet! ? "1" : "0",
          WALLET_BAL_USED: usedBal.toString(),
          'urgent_delivery': schedule.toString(),
          ORDER_NOTE: noteC.text,
          'add_on_id': finalIdss,
          'seller_id': cartList[0].productList![0].seller_id,
          'add_on_qty': finalqty.toString(),
          'add_total': newsum.toString(),
          'packaging_charge': packageFee.toString(),
          'total_packing_charge': (packagingCharge*days).toString(),
          'platform_fee': (platformFee*days).toString(),
          'delivery_type': pickCustomer ? "2" : "1",
          'product_order_type': subscription?"subscription_order":"order",
          'startdate': startCon.text.toString(),
          'enddate': endCon.text.toString(),
          'totaldelivery': days.toString(),
          'selectday': days.toString(),
          // 'cgst': cgst.toString(),
          //  'sgst': sgst.toString(),
        };
        if (addressList[selectedAddress!]
            .state
            .toString()
            .toLowerCase()
            .contains("maharashtra")) {
          parameter['cgst'] = ((double.parse(totalTax) / 2)*days).round().toStringAsFixed(2);
          parameter['sgst'] = ((double.parse(totalTax) / 2)*days).round().toStringAsFixed(2);
        } else {
          parameter['igst'] = (double.parse(totalTax)*days).round().toStringAsFixed(2);
        }
        if (isTimeSlot!=null&&isTimeSlot!) {
          parameter[DELIVERY_TIME] = selTime ?? 'Anytime';
          parameter[DELIVERY_DATE] = selDate ?? '';
        }
        if (isPromoValid!) {
          parameter[PROMOCODE] = promocode;
          parameter[PROMO_DIS] = promoAmt.toString();
        }
        if (payMethod == getTranslated(context, 'PAYPAL_LBL')) {
          parameter[ACTIVE_STATUS] = WAITING;
        } else if (payMethod == getTranslated(context, 'STRIPE_LBL')) {
          if (tranId == "succeeded")
            parameter[ACTIVE_STATUS] = PLACED;
          else
            parameter[ACTIVE_STATUS] = WAITING;
        } else if (payMethod == getTranslated(context, 'BANKTRAN')) {
          parameter[ACTIVE_STATUS] = WAITING;
        }
        print(
            "place order parameterrrrrr" + parameter.toString());
        Response response = await post(placeOrderApi, body: parameter, headers: headers).timeout(Duration(seconds: timeOut));
        _placeOrder = true;
        if (response.statusCode == 200) {
          var getdata = json.decode(response.body);
          print(placeOrderApi);
          print(getdata.toString());
          bool error = getdata["error"];
          String? msg = getdata["message"];
          if (!error) {
            String orderId = getdata["order_id"].toString();
            if (payMethod == getTranslated(context, 'RAZORPAY_LBL')) {
              addTransaction(tranId, orderId, SUCCESS, msg, true);
            } else if (payMethod == getTranslated(context, 'PAYPAL_LBL')) {
              paypalPayment(orderId);
            } else if (payMethod == getTranslated(context, 'STRIPE_LBL')) {
              addTransaction(stripePayId, orderId,
                  tranId == "succeeded" ? PLACED : WAITING, msg, true);
            } else if (payMethod == getTranslated(context, 'PAYSTACK_LBL')) {
              addTransaction(tranId, orderId, SUCCESS, msg, true);
            } else if (payMethod == getTranslated(context, 'PAYTM_LBL')) {
              addTransaction(tranId, orderId, SUCCESS, msg, true);
            } /*if (payMethod == getTranslated(context, 'CC_AVENUE')){
               _initiateCcAvenuePayment(orderId, totalPrice);
             // initiatePayment();
            }*/
            else {
              context.read<UserProvider>().setCartCount("0");
              clearAll();
              Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (BuildContext context) => OrderSuccess()),
                  ModalRoute.withName('/home'));
            }
          } else {
            print("ddddddddddddddddddddddddd");
           // setSnackbar(msg!, _checkscaffoldKey);
            final snackBar = SnackBar(
              content: customSnackbarImage(msg ?? ''),
              duration: Duration(seconds: 3),
            );
            ScaffoldMessenger.of(context).showSnackBar(snackBar);
            context.read<CartProvider>().setProgress(false);
          }
        }
      } on TimeoutException catch (_) {
        if (mounted)
          checkoutState!(() {
            _placeOrder = true;
          });
        context.read<CartProvider>().setProgress(false);
      }
    } else {
      if (mounted)
        checkoutState!(() {
          _isNetworkAvail = false;
        });
    }
  }

  Future<void> paypalPayment(String orderId) async {
    try {
      var parameter = {
        USER_ID: CUR_USERID,
        ORDER_ID: orderId,
        AMOUNT: totalPrice.toString()
      };
      Response response =
          await post(paypalTransactionApi, body: parameter, headers: headers)
              .timeout(Duration(seconds: timeOut));

      var getdata = json.decode(response.body);

      bool error = getdata["error"];
      String? msg = getdata["message"];
      if (!error) {
        String? data = getdata["data"];
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (BuildContext context) => PaypalWebview(
                      url: data,
                      from: "order",
                      orderId: orderId,
                    )));
      } else {
        setSnackbar(msg!, _checkscaffoldKey);
      }
      context.read<CartProvider>().setProgress(false);
    } on TimeoutException catch (_) {
      setSnackbar(getTranslated(context, 'somethingMSg')!, _checkscaffoldKey);
    }
  }

  Future<void> addTransaction(String? tranId, String orderID, String? status,
      String? msg, bool redirect) async {
    try {
      var parameter = {
        USER_ID: CUR_USERID,
        ORDER_ID: orderID,
        TYPE: payMethod,
        TXNID: tranId,
        AMOUNT: totalPrice.toString(),
        STATUS: status,
        MSG: msg
      };
      Response response =
          await post(addTransactionApi, body: parameter, headers: headers)
              .timeout(Duration(seconds: timeOut));

      var getdata = json.decode(response.body);

      bool error = getdata["error"];
      String? msg1 = getdata["message"];
      if (!error) {
        if (redirect) {
          // CUR_CART_COUNT = "0";

          context.read<UserProvider>().setCartCount("0");
          clearAll();

          Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(
                  builder: (BuildContext context) => OrderSuccess()),
              ModalRoute.withName('/home'));
        }
      } else {
        setSnackbar(msg1!, _checkscaffoldKey);
      }
    } on TimeoutException catch (_) {
      setSnackbar(getTranslated(context, 'somethingMSg')!, _checkscaffoldKey);
    }
  }

  // paystackPayment(BuildContext context) async {
  //   context.read<CartProvider>().setProgress(true);
  //
  //   String? email = context.read<SettingProvider>().email;
  //
  //   Charge charge = Charge()
  //     ..amount = totalPrice.toInt()
  //     ..reference = _getReference()
  //     ..email = email;
  //
  //   try {
  //     CheckoutResponse response = await paystackPlugin.checkout(
  //       context,
  //       method: CheckoutMethod.card,
  //       charge: charge,
  //     );
  //     if (response.status) {
  //       placeOrder(response.reference);
  //     } else {
  //       setSnackbar(response.message, _checkscaffoldKey);
  //       if (mounted)
  //         setState(() {
  //           _placeOrder = true;
  //         });
  //       context.read<CartProvider>().setProgress(false);
  //     }
  //   } catch (e) {
  //     context.read<CartProvider>().setProgress(false);
  //     rethrow;
  //   }
  // }

Widget customSnackbarImage(String msg) {
    return Center(
      child: Column(children: [
        ClipRRect(
          // borderRadius: BorderRadius.circular(10.0),
          child: Container(
             // width: 40.0,
              height: 120.0,
              color: Colors.grey.withOpacity(0.3),
              child: Image.network(pincocdeImage.first ??'')
          ),
        ),
        Text(msg)
      ],),
    );

}

  String _getReference() {
    String platform;
    if (Platform.isIOS) {
      platform = 'iOS';
    } else {
      platform = 'Android';
    }

    return 'ChargedFrom${platform}_${DateTime.now().millisecondsSinceEpoch}';
  }

  // _initiateCcAvenuePayment(String orderId, double totalPrice) async {
  //   // OrderModel model = OrderModel(listStatus: []);
  //   try {
  //     final amount = totalPrice.toString();
  //     setState(() {
  //       // _loading = true;
  //       // errorText = "";
  //     });
  //     final response = await http.get(Uri.parse('${baseUrl}ccevenue_handler_wallet?order_id=$orderId&amount=$amount'));
  //     // .post(Uri.parse(UrlList.merchant_server_enc_url),
  //     // body: {"amount": amount});
  //     // final json = jsonDecode(response.body);
  //     // final data = PaymentData.fromJson(json);
  //     final data = response.body;
  //     var data1 =jsonDecode(data);
  //     String url = data1["message"];
  //     print('${response.body}_______dfkljd');
  //     // if (data.statusMessage == "SUCCESS") {
  //     initiatePayment(url);
  //     setState(() {
  //       // _loading = false;
  //     });
  //
  //   } catch (e) {
  //     print(e.toString());
  //     setState(() {
  //       // _loading = false;
  //     });
  //   }
  // }

  InAppWebViewController? _webViewController;

  /*void initiatePayment1(String url) {
    // Replace this with the actual PhonePe payment URL you have
   // String phonePePaymentUrl = url;
   // String callBackUrl = "https://secure.ccavenue.ae/transaction/transaction";
    String callBackUrl = "https://eatoz.in/home/ccevenue_response";
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(
            title: const Text('Payment'),
          ),
          body: InAppWebView(
            initialUrlRequest: URLRequest(url: Uri.parse(url)),
            onWebViewCreated: (controller) {
              _webViewController = controller;
            },
            onLoadStart: ((controller, url) {

            }),
            onLoadStop: (controller, url) async {
              print('___________${url}____cgf_____');

              if (url.toString().contains(callBackUrl)) {
                // Extract payment status from URL
                /// String? paymentStatus = extractPaymentStatusFromUrl(url.toString());
                ///
                //_handlePaymentStatus(url.toString());
                 print('_________swsfsff____________');


                await _webViewController?.stopLoading();

                if(await _webViewController?.canGoBack() ?? false){
                  await _webViewController?.goBack();
                }else {
                  Navigator.pop(context);
                }
                // Update payment status
                */ /*setState(() {
                  _paymentStatus = paymentStatus!;
                });*/ /*
                // Stop loading and close WebView


              }
            },
          ),
        ),
      ),
    );
  }*/

  Future<void> initiatePayment() async {
    // Replace this with the actual PhonePe payment URL you have
    String phonePePaymentUrl = '${url}';
    String calBackurl = phonePePaymentUrl + 'Eatoz';
    print("call back url ${calBackurl}");
    var data = await Navigator.push(context!, CupertinoPageRoute(
      builder: (context) {
        return WebViewExample(url: phonePePaymentUrl);
      },
    ));
    print("Payment Data${data}");
    if (data != null) {
      http.post(Uri.parse("${baseUrl}check_phonepay_status"),
          body: {"transaction_id": merchantTransactionId}).then((value) {
        print("Payment Data1${value.body}");
        Map response = jsonDecode(value.body);
        if (response['data'] != null) {
          setSnackbar("${response['data'][0]["message"]}", GlobalKey());
          print(
              '${response['data'][0]["error"].runtimeType}________________________runType');
          print(
              '${response['data'][0]["error"].runtimeType}________________________method');

          if (response['data'][0]["error"].toString() == "false") {
            placeOrder(merchantTransactionId);
          } else {}
        } else {
          setSnackbar("Payment Failed or Cancelled", GlobalKey());
        }
      });
    } else {
      setSnackbar("Payment Failed or Cancelled", GlobalKey());
    }
    /*  Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(
            title: Text('PhonePe Payment'),
          ),
          body: InAppWebView(
            initialUrlRequest: URLRequest(url: Uri.parse(phonePePaymentUrl)),

            onWebViewCreated: (controller) {
              _webViewController = controller;
            },
            onLoadStop: (controller, url) async {
              if (url.toString().contains('https://giftsbash.com/home/phonepay_success')) {
                handelPhonePaySuccess(url.toString());
                // Extract payment status from URL
                //String? paymentStatus = extractPaymentStatusFromUrl(url.toString());
                // Update payment status
              //  print("jhhhhhhhhhhhhhhhhhh ${url}");
               // setState(() {
                  //_paymentStatus = paymentStatus!;
             //   });
                await _webViewController?.stopLoading();
                if(await _webViewController?.canGoBack() ?? false){
                  await _webViewController?.goBack();
                }else {
                  print('${paymentStatuss}____________');
                  if(paymentStatuss == true){
                    placeOrder(merchantTransactionId);
                  }
                  Navigator.pop(context);
                }
                //
                // Stop loading and close WebView
              //
                //await _webViewController?.goBack();
              }
            },
          ),
        ),
      ),
    );*/
  }

  String? newStats;
  bool? paymentStatuss;

  handelPhonePaySuccess(String url) async {
    Map<String, dynamic> finalResult = await fetchPaymentStatus();
    if (finalResult['data'][0]['error'] == 'true') {
      // newStats = false;
      Fluttertoast.showToast(msg: "Payment Failed");
      paymentStatuss = false;
    } else {
      paymentStatuss = true;
      Fluttertoast.showToast(msg: "Payment Success");
    }
  }

  Future<Map<String, dynamic>> fetchPaymentStatus() async {
    var headers = {
      'Cookie': 'ci_session=2192e13e91c2acac91d03ed3ab66370064afc742'
    };
    print(url);
    var request = http.MultipartRequest(
        'POST', Uri.parse('${baseUrl}check_phonepay_status'));
    request.fields.addAll({'transaction_id': '${merchantTransactionId}'});
    print("check paymnet status ${request.fields}");
    request.headers.addAll(headers);
    http.StreamedResponse response = await request.send();
    if (response.statusCode == 200) {
      var Result = await response.stream.bytesToString();
      var finalResult = jsonDecode(Result);
      return finalResult;
    } else {
      var Result = await response.stream.bytesToString();
      var finalResult = jsonDecode(Result);
      return finalResult;
      //print(response.reasonPhrase);
    }
  }

  String? extractPaymentStatusFromUrl(String url) {
    Uri uri = Uri.parse(url);
    String? paymentStatus = uri.queryParameters['status'];
    return paymentStatus;
  }

  String url = '';
  String? merchantId;
  String? merchantTransactionId;
  String? mobile;

  Future<void> getPhonpayURL() async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    mobile = preferences.getString("mobile");
    print('___mobile_______${mobile}_________');
    String orderId = DateTime.now().millisecondsSinceEpoch.toString();
    var headers = {
      'Cookie': 'ci_session=56691520ceefd28e91e4992a486249c971156c0d'
    };
    var request = http.MultipartRequest(
        'POST', Uri.parse('${baseUrl}initiate_phone_payment'));
    request.fields.addAll({
      'user_id': '$CUR_USERID',
      'mobile': '$mobile',
      'amount': '$totalPrice'
    });
    print("initiate phone pay para${request.fields}");
    request.headers.addAll(headers);
    http.StreamedResponse response = await request.send();
    if (response.statusCode == 200) {
      var result = await response.stream.bytesToString();
      print(result);
      var finalResult = jsonDecode(result);
      url = finalResult['data']['data']['instrumentResponse']['redirectInfo']
          ['url'];
      merchantId = finalResult['data']['data']['merchantId'];
      merchantTransactionId =
          finalResult['data']['data']['merchantTransactionId'];
      print("merchante trancfags ${merchantTransactionId}");
      await initiatePayment();
    } else {
      print(response.reasonPhrase);
    }
  }

  // void initiatePayment(String url) async{
  //   // Replace this with the actual PhonePe payment URL you have
  //   String phonePePaymentUrl = '${url}';
  //   String calBackurl = phonePePaymentUrl + 'Eatoz';
  //   print("call back url ${calBackurl}");
  //   var data = await Navigator.push(context, CupertinoPageRoute(
  //     builder: (context) {
  //       return WebViewExample(
  //           url: phonePePaymentUrl);
  //     },
  //   ));
  //   print("Payment Data$data");
  // }

  stripePayment() async {
    context.read<CartProvider>().setProgress(true);

    var response = await StripeService.payWithNewCard(
        amount: (totalPrice.toInt() * 100).toString(),
        currency: stripeCurCode,
        from: "order",
        context: context);

    if (response.message == "Transaction successful") {
      print("strip order");
      placeOrder(response.status);
    } else if (response.status == 'pending' || response.status == "captured") {
      placeOrder(response.status);
    } else {
      if (mounted)
        setState(() {
          _placeOrder = true;
        });
      context.read<CartProvider>().setProgress(false);
    }
    setSnackbar(response.message!, _checkscaffoldKey);
  }

  address() {
    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(Icons.location_on),
                Padding(
                  padding: const EdgeInsetsDirectional.only(start: 8.0),
                  child: Text(
                    getTranslated(context, 'SHIPPING_DETAIL') ?? '',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.fontColor),
                  ),
                ),
              ],
            ),
            Divider(),
            addressList.length > 0
                ? Padding(
                    padding: const EdgeInsetsDirectional.only(start: 8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                                child:
                                    Text(addressList[selectedAddress!].name!)),
                            InkWell(
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 8.0),
                                child: Text(
                                  getTranslated(context, 'CHANGE')!,
                                  style: TextStyle(
                                    color: colors.primary,
                                  ),
                                ),
                              ),
                              onTap: () async {
                                // Navigator.pop(context);
                                await Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (BuildContext context) =>
                                                ManageAddress(
                                                  home: false,
                                                )))
                                    .then((value) => _isLoading = true);
                                checkoutState!(() {
                                  deliverable = false;
                                });
                                isAdreesChange = true;
                                _getCart('0');

                                /* */
                                //_getAddress();
                              },
                            ),
                          ],
                        ),
                        Text(
                          addressList[selectedAddress!].address! +
                              ", " +
                              addressList[selectedAddress!].area! +
                              ", " +
                              addressList[selectedAddress!].city! +
                              ", " +
                              addressList[selectedAddress!].state! +
                              ", " +
                              addressList[selectedAddress!].country! +
                              ", " +
                              addressList[selectedAddress!].pincode!,
                          style: Theme.of(context).textTheme.caption!.copyWith(
                              color: Theme.of(context).colorScheme.lightBlack),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 5.0),
                          child: Row(
                            children: [
                              Text(
                                addressList[selectedAddress!].mobile!,
                                style: Theme.of(context)
                                    .textTheme
                                    .caption!
                                    .copyWith(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .lightBlack),
                              ),
                            ],
                          ),
                        )
                      ],
                    ),
                  )
                : Padding(
                    padding: const EdgeInsetsDirectional.only(start: 8.0),
                    child: GestureDetector(
                      child: Text(
                        getTranslated(context, 'ADDADDRESS')!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.fontColor,
                        ),
                      ),
                      onTap: () async {
                        ScaffoldMessenger.of(context).removeCurrentSnackBar();
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => AddAddress(
                                    update: false,
                                    index: addressList.length,
                                  )),
                        );
                        if (mounted) setState(() {});
                      },
                    ),
                  )
          ],
        ),
      ),
    );
  }

  payment() {
    return Card(
      elevation: 0,
      child: InkWell(
        borderRadius: BorderRadius.circular(4),
        onTap: () async {
          ScaffoldMessenger.of(context).removeCurrentSnackBar();
          msg = '';
          await Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (BuildContext context) =>
                      Payment(updateCheckout, msg, finalTotalValue)));
          if (mounted) checkoutState!(() {});
        },
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              Row(
                children: [
                  Icon(Icons.payment),
                  Padding(
                    padding: const EdgeInsetsDirectional.only(start: 8.0),
                    child: Text(
                      //SELECT_PAYMENT,
                      getTranslated(context, 'SELECT_PAYMENT')!,
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.fontColor,
                          fontWeight: FontWeight.bold),
                    ),
                  )
                ],
              ),
              payMethod != null && payMethod != ''
                  ? Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [Divider(), Text(payMethod!)],
                      ),
                    )
                  : Container(),
            ],
          ),
        ),
      ),
    );
  }

  bool pickCustomer = false;
  Widget pickupCustomer(VoidCallback onTap) {
    return Card(
      elevation: 0,
      child: InkWell(
        borderRadius: BorderRadius.circular(4),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              Row(
                children: [
                  Icon(
                      pickCustomer
                      ? Icons.check_box : Icons.check_box_outline_blank),
                  Padding(
                    padding: const EdgeInsetsDirectional.only(start: 8.0),
                    child: Text(
                      //SELECT_PAYMENT,
                      "Delivery Service",
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.fontColor,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
  cartItems(List<SectionModel> cartList,setState) {
    return ListView.builder(
      shrinkWrap: true,
      itemCount: cartList.length,
      physics: NeverScrollableScrollPhysics(),
      itemBuilder: (context, index) {
        return cartItem(index, cartList,setState);
      },
    );
  }

  orderSummary(List<SectionModel> cartList) {
    return Card(
        elevation: 0,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                getTranslated(context, 'ORDER_SUMMARY')! +
                    " (" +
                    cartList.length.toString() +
                    " items)",
                style: TextStyle(
                    color: Theme.of(context).colorScheme.fontColor,
                    fontWeight: FontWeight.bold),
              ),
              Divider(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    getTranslated(context, 'SUBTOTAL')!,
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.lightBlack2),
                  ),
                  Text(
                    CUR_CURRENCY! + " " + (oriPrice*days).toStringAsFixed(2),
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.fontColor,
                        fontWeight: FontWeight.bold),
                  )
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Packaging Charge",
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.lightBlack2),
                  ),
                  Text(
                    CUR_CURRENCY! + " " + (packagingCharge*days).toStringAsFixed(2),
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.fontColor,
                        fontWeight: FontWeight.bold),
                  )
                ],
              ),
             /* Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Platform Fee",
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.lightBlack2),
                  ),
                  Text(
                    CUR_CURRENCY! + " " + (platformFee*days).toStringAsFixed(2),
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.fontColor,
                        fontWeight: FontWeight.bold),
                  )
                ],
              ),*/
              // Row(
              //   mainAxisAlignment: MainAxisAlignment.spaceBetween,
              //   children: [
              //     Text(
              //      "SGST",
              //       style: TextStyle(
              //           color: Theme.of(context).colorScheme.lightBlack2),
              //     ),
              //     Text(
              //       CUR_CURRENCY! + " " + "${sgst}",
              //       style: TextStyle(
              //           color: Theme.of(context).colorScheme.fontColor,
              //           fontWeight: FontWeight.bold),
              //     )
              //   ],
              // ),
              // Row(
              //   mainAxisAlignment: MainAxisAlignment.spaceBetween,
              //   children: [
              //     Text(
              //      "CGST",
              //       style: TextStyle(
              //           color: Theme.of(context).colorScheme.lightBlack2),
              //     ),
              //     Text(
              //       CUR_CURRENCY! + " " + "${cgst}",
              //       style: TextStyle(
              //           color: Theme.of(context).colorScheme.fontColor,
              //           fontWeight: FontWeight.bold),
              //     )
              //   ],
              // ),
              //
              addressList.isNotEmpty
                  ? addressList[selectedAddress!]
                          .state
                          .toString()
                          .toLowerCase()
                          .contains("maharashtra")
                      ? Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  "CGST(${taxPer / 2} %)",
                                  style: TextStyle(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .lightBlack2),
                                ),
                                Text(
                                  CUR_CURRENCY! +
                                      " " +
                                      "${((double.parse(totalTax) / 2)*days).round().toStringAsFixed(2)}",
                                  style: TextStyle(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .fontColor,
                                      fontWeight: FontWeight.bold),
                                )
                              ],
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  "SGST(${taxPer / 2} %)",
                                  style: TextStyle(
                                      color: Theme.of(context).colorScheme.lightBlack2),
                                ),
                                Text(
                                  CUR_CURRENCY! +
                                      " " +
                                      "${((double.parse(totalTax) / 2)*days).round().toStringAsFixed(2)}",
                                  style: TextStyle(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .fontColor,
                                      fontWeight: FontWeight.bold),
                                )
                              ],
                            ),
                          ],
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "IGST($taxPer %)",
                              style: TextStyle(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .lightBlack2),
                            ),
                            Text(
                              CUR_CURRENCY! + " " + "${(double.parse(totalTax)*days).round()}",
                              style: TextStyle(
                                  color: Theme.of(context).colorScheme.fontColor,
                                  fontWeight: FontWeight.bold),
                            )
                          ],
                        )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "IGST($taxPer %)",
                          style: TextStyle(
                              color: Theme.of(context).colorScheme.lightBlack2),
                        ),
                        Text(
                          CUR_CURRENCY! + " " + "${(double.parse(totalTax)*days).round()}",
                          style: TextStyle(
                              color: Theme.of(context).colorScheme.fontColor,
                              fontWeight: FontWeight.bold),
                        )
                      ],
                    ),
              pickCustomer
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          getTranslated(context, 'DELIVERY_CHARGE')!,
                          style: TextStyle(
                              color: Theme.of(context).colorScheme.lightBlack2),
                        ),
                        Text(
                          CUR_CURRENCY! + " " + (delCharge*days).toStringAsFixed(2),
                          style: TextStyle(
                              color: Theme.of(context).colorScheme.fontColor,
                              fontWeight: FontWeight.bold),
                        ),
                      ],
                    )
                  : const SizedBox(),
                  isPromoValid!
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          getTranslated(context, 'PROMO_CODE_DIS_LBL')!,
                          style: TextStyle(
                              color: Theme.of(context).colorScheme.lightBlack2),
                        ),
                        Text(
                          "-" +
                              CUR_CURRENCY! +
                              " " +
                              promoAmt.toStringAsFixed(2),
                          style: TextStyle(
                              color: Theme.of(context).colorScheme.fontColor,
                              fontWeight: FontWeight.bold),
                        )
                      ],
                    )
                  : Container(),
              isUseWallet!
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          getTranslated(context, 'WALLET_BAL')!,
                          style: TextStyle(
                              color: Theme.of(context).colorScheme.lightBlack2),
                        ),
                        Text(
                          CUR_CURRENCY! + " " + usedBal.toStringAsFixed(2),
                          style: TextStyle(
                              color: Theme.of(context).colorScheme.fontColor,
                              fontWeight: FontWeight.bold),
                        )
                      ],
                    )
                  : Container(),
            ],
          ),
        ));
  }

  Future<void> validatePromo(bool check) async {
    _isNetworkAvail = await isNetworkAvailable();
    if (_isNetworkAvail) {
      try {
        context.read<CartProvider>().setProgress(true);
        if (check) {
          if (this.mounted && checkoutState != null) checkoutState!(() {});
        }
        setState(() {});
        var parameter = {
          USER_ID: CUR_USERID,
          PROMOCODE: promoC.text,
          FINAL_TOTAL: oriPrice.toString()
        };
        Response response =
            await post(validatePromoApi, body: parameter, headers: headers)
                .timeout(Duration(seconds: timeOut));
        print("paramters here $validatePromoApi and $parameter");
        if (response.statusCode == 200) {
          var getdata = json.decode(response.body);

          bool error = getdata["error"];
          String? msg = getdata["message"];
          if (!error) {
            var data = getdata["data"][0];
            print('___________${getdata["data"]}__________');
            setState(() {
              promoAmt = 0.0;
            });
            totalPrice = double.parse(data["final_total"]) +
                delCharge +
                double.parse(totalTax);
            print("final discount is here now ${data['final_discount']}");
            promoAmt = double.parse(data["final_discount"]);
            promocode = data["promo_code"];
            print("checking promocode data here now $promocode");
            isPromoValid = true;

            if (promoAmt == "" ||
                promoAmt == null ||
                promoAmt == 0 ||
                promoAmt == 0.0) {
            } else {}

            setSnackbar(
                getTranslated(context, 'PROMO_SUCCESS')!, _checkscaffoldKey);
            // _getCart("");
          } else {
            isPromoValid = false;
            promoAmt = 0;
            promocode = null;
            promoC.clear();
            var data = getdata["data"];

            totalPrice = double.parse(data["final_total"]) + delCharge;

            setSnackbar(msg!, _checkscaffoldKey);
          }
          if (isUseWallet!) {
            remWalBal = 0;
            payMethod = null;
            usedBal = 0;
            isUseWallet = false;
            isPayLayShow = true;

            selectedMethod = null;
            context.read<CartProvider>().setProgress(false);
            if (mounted && check) checkoutState!(() {});
            setState(() {});
          } else {
            if (mounted && check) checkoutState!(() {});
            setState(() {});
            context.read<CartProvider>().setProgress(false);
          }
        }
      } on TimeoutException catch (_) {
        context.read<CartProvider>().setProgress(false);
        if (mounted && check) checkoutState!(() {});
        setState(() {});
        setSnackbar(getTranslated(context, 'somethingMSg')!, _checkscaffoldKey);
      }
    } else {
      _isNetworkAvail = false;
      if (mounted && check) checkoutState!(() {});
      setState(() {});
    }
  }

  Future<void> flutterwavePayment() async {
    _isNetworkAvail = await isNetworkAvailable();
    if (_isNetworkAvail) {
      try {
        context.read<CartProvider>().setProgress(true);

        var parameter = {
          AMOUNT: totalPrice.toString(),
          USER_ID: CUR_USERID,
        };
        Response response =
            await post(flutterwaveApi, body: parameter, headers: headers)
                .timeout(Duration(seconds: timeOut));

        if (response.statusCode == 200) {
          var getdata = json.decode(response.body);

          bool error = getdata["error"];
          String? msg = getdata["message"];
          if (!error) {
            var data = getdata["link"];
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (BuildContext context) => PaypalWebview(
                          url: data,
                          from: "order",
                        )));
          } else {
            setSnackbar(msg!, _checkscaffoldKey);
          }

          context.read<CartProvider>().setProgress(false);
        }
      } on TimeoutException catch (_) {
        context.read<CartProvider>().setProgress(false);
        setSnackbar(getTranslated(context, 'somethingMSg')!, _checkscaffoldKey);
      }
    } else {
      if (mounted)
        checkoutState!(() {
          _isNetworkAvail = false;
        });
    }
  }

  void confirmDialog() {
    showGeneralDialog(
        barrierColor: Theme.of(context).colorScheme.black.withOpacity(0.5),
        transitionBuilder: (context, a1, a2, widget) {
          return Transform.scale(
            scale: a1.value,
            child: Opacity(
                opacity: a1.value,
                child: AlertDialog(
                  contentPadding: const EdgeInsets.all(0),
                  elevation: 2.0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.all(Radius.circular(5.0))),
                  content:
                     StatefulBuilder(builder: (context, setState) {
                       return
                         Column(
                             mainAxisSize: MainAxisSize.min,
                             crossAxisAlignment: CrossAxisAlignment.start,
                             children: [
                               Padding(
                                   padding: EdgeInsets.fromLTRB(20.0, 20.0, 0, 2.0),
                                   child: Text(
                                     getTranslated(context, 'CONFIRM_ORDER')!,
                                     style: Theme.of(this.context)
                                         .textTheme
                                         .subtitle1!
                                         .copyWith(
                                         color: Theme.of(context)
                                             .colorScheme
                                             .fontColor),
                                   )),
                               Divider(
                                   color: Theme.of(context).colorScheme.lightBlack),
                               Padding(
                                 padding: EdgeInsets.fromLTRB(20.0, 0, 20.0, 0),
                                 child: Column(
                                   mainAxisSize: MainAxisSize.min,
                                   children: [
                                     Row(
                                       mainAxisAlignment:
                                       MainAxisAlignment.spaceBetween,
                                       children: [
                                         Text(
                                           getTranslated(context, 'SUBTOTAL')!,
                                           style: Theme.of(context)
                                               .textTheme
                                               .subtitle2!
                                               .copyWith(
                                               color: Theme.of(context)
                                                   .colorScheme
                                                   .lightBlack2),
                                         ),
                                         Text(
                                           CUR_CURRENCY! +
                                               " " +
                                               (oriPrice*days).toStringAsFixed(2),
                                           style: Theme.of(context)
                                               .textTheme
                                               .subtitle2!
                                               .copyWith(
                                               color: Theme.of(context)
                                                   .colorScheme
                                                   .fontColor,
                                               fontWeight: FontWeight.bold),
                                         )
                                       ],
                                     ),
                                     Row(
                                       mainAxisAlignment:
                                       MainAxisAlignment.spaceBetween,
                                       children: [
                                         Text(
                                           "Packaging Charge",
                                           style: Theme.of(context)
                                               .textTheme
                                               .subtitle2!
                                               .copyWith(
                                               color: Theme.of(context)
                                                   .colorScheme
                                                   .lightBlack2),
                                         ),
                                         Text(
                                           CUR_CURRENCY! +
                                               " " +
                                               (packagingCharge*days).toStringAsFixed(2),
                                           style: Theme.of(context)
                                               .textTheme
                                               .subtitle2!
                                               .copyWith(
                                               color: Theme.of(context)
                                                   .colorScheme
                                                   .fontColor,
                                               fontWeight: FontWeight.bold),
                                         )
                                       ],
                                     ),
                                     /* Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    "Platform Fee",
                                    style: Theme.of(context)
                                        .textTheme
                                        .subtitle2!
                                        .copyWith(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .lightBlack2),
                                  ),
                                  Text(
                                    CUR_CURRENCY! +
                                        " " +
                                        (platformFee*days).toStringAsFixed(2),
                                    style: Theme.of(context)
                                        .textTheme
                                        .subtitle2!
                                        .copyWith(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .fontColor,
                                            fontWeight: FontWeight.bold),
                                  )
                                ],
                              ),*/
                                     pickCustomer
                                         ? Row(
                                       mainAxisAlignment:
                                       MainAxisAlignment.spaceBetween,
                                       children: [
                                         Text(
                                           getTranslated(
                                               context, 'DELIVERY_CHARGE')!,
                                           style: Theme.of(context)
                                               .textTheme
                                               .subtitle2!
                                               .copyWith(
                                               color: Theme.of(context)
                                                   .colorScheme
                                                   .lightBlack2),
                                         ),
                                         Text(
                                           CUR_CURRENCY! +
                                               " " +
                                               (delCharge*days).toStringAsFixed(2),
                                           style: Theme.of(context)
                                               .textTheme
                                               .subtitle2!
                                               .copyWith(
                                               color: Theme.of(context)
                                                   .colorScheme
                                                   .fontColor,
                                               fontWeight: FontWeight.bold),
                                         )
                                       ],
                                     )
                                         : const SizedBox(),
                                     addressList[selectedAddress!]
                                         .state
                                         .toString()
                                         .toLowerCase()
                                         .contains("maharashtra")
                                         ? Column(
                                       children: [
                                         Row(
                                           mainAxisAlignment:
                                           MainAxisAlignment.spaceBetween,
                                           children: [
                                             Text(
                                               "CGST(${taxPer / 2} %)",
                                               style: TextStyle(
                                                   color: Theme.of(context)
                                                       .colorScheme
                                                       .lightBlack2),
                                             ),
                                             Text(
                                               CUR_CURRENCY! +
                                                   " " +
                                                   "${((double.parse(totalTax) / 2)*days).round().toStringAsFixed(2)}",
                                               style: TextStyle(
                                                   color: Theme.of(context)
                                                       .colorScheme
                                                       .fontColor,
                                                   fontWeight: FontWeight.bold),
                                             )
                                           ],
                                         ),
                                         Row(
                                           mainAxisAlignment:
                                           MainAxisAlignment.spaceBetween,
                                           children: [
                                             Text(
                                               "SGST(${taxPer / 2} %)",
                                               style: TextStyle(
                                                   color: Theme.of(context)
                                                       .colorScheme
                                                       .lightBlack2),
                                             ),
                                             Text(
                                               CUR_CURRENCY! +
                                                   " " +
                                                   "${((double.parse(totalTax) / 2)*days).round().toStringAsFixed(2)}",
                                               style: TextStyle(
                                                   color: Theme.of(context)
                                                       .colorScheme
                                                       .fontColor,
                                                   fontWeight: FontWeight.bold),
                                             )
                                           ],
                                         ),
                                       ],
                                     )
                                         : Row(
                                       mainAxisAlignment:
                                       MainAxisAlignment.spaceBetween,
                                       children: [
                                         Text(
                                           "IGST($taxPer %)",
                                           style: TextStyle(
                                               color: Theme.of(context)
                                                   .colorScheme
                                                   .lightBlack2),
                                         ),
                                         Text(
                                           CUR_CURRENCY! + " " + "${(double.parse(totalTax)*days).round()}",
                                           style: TextStyle(
                                               color: Theme.of(context)
                                                   .colorScheme
                                                   .fontColor,
                                               fontWeight: FontWeight.bold),
                                         )
                                       ],
                                     ),
                                     isPromoValid!
                                         ? Row(
                                       mainAxisAlignment:
                                       MainAxisAlignment.spaceBetween,
                                       children: [
                                         Text(
                                           getTranslated(
                                               context, 'PROMO_CODE_DIS_LBL')!,
                                           style: Theme.of(context)
                                               .textTheme
                                               .subtitle2!
                                               .copyWith(
                                               color: Theme.of(context)
                                                   .colorScheme
                                                   .lightBlack2),
                                         ),
                                         Text(
                                           CUR_CURRENCY! +
                                               " " +
                                               promoAmt.toStringAsFixed(2),
                                           style: Theme.of(context)
                                               .textTheme
                                               .subtitle2!
                                               .copyWith(
                                               color: Theme.of(context)
                                                   .colorScheme
                                                   .fontColor,
                                               fontWeight: FontWeight.bold),
                                         )
                                       ],
                                     )
                                         : Container(),
                                     isUseWallet!
                                         ? Row(
                                       mainAxisAlignment:
                                       MainAxisAlignment.spaceBetween,
                                       children: [
                                         Text(
                                           getTranslated(context, 'WALLET_BAL')!,
                                           style: Theme.of(context)
                                               .textTheme
                                               .subtitle2!
                                               .copyWith(
                                               color: Theme.of(context)
                                                   .colorScheme
                                                   .lightBlack2),
                                         ),
                                         Text(
                                           CUR_CURRENCY! +
                                               " " +
                                               usedBal.toStringAsFixed(2),
                                           style: Theme.of(context)
                                               .textTheme
                                               .subtitle2!
                                               .copyWith(
                                               color: Theme.of(context)
                                                   .colorScheme
                                                   .fontColor,
                                               fontWeight: FontWeight.bold),
                                         )
                                       ],
                                     )
                                         : Container(),
                                     Padding(
                                       padding:
                                       const EdgeInsets.symmetric(vertical: 8.0),
                                       child: Row(
                                         mainAxisAlignment:
                                         MainAxisAlignment.spaceBetween,
                                         children: [
                                           Text(
                                             getTranslated(context, 'TOTAL_PRICE')!,
                                             style: Theme.of(context)
                                                 .textTheme
                                                 .subtitle2!
                                                 .copyWith(
                                                 color: Theme.of(context)
                                                     .colorScheme
                                                     .lightBlack2),
                                           ),
                                           Text(
                                             CUR_CURRENCY! +
                                                 " ${totalPrice.toStringAsFixed(2)}",
                                             style: TextStyle(
                                                 color: Theme.of(context)
                                                     .colorScheme
                                                     .fontColor,
                                                 fontWeight: FontWeight.bold),
                                           ),
                                         ],
                                       ),
                                     ),
                                     Container(
                                       padding: EdgeInsets.symmetric(vertical: 10),
                                       /* decoration: BoxDecoration(
                                    color: colors.primary.withOpacity(0.1),
                                    borderRadius: BorderRadius.all(
                                      Radius.circular(10),
                                    ),
                                  ),*/
                                       child: TextField(
                                         controller: noteC,
                                         style:
                                         Theme.of(context).textTheme.subtitle2,
                                         decoration: InputDecoration(
                                           contentPadding:
                                           EdgeInsets.symmetric(horizontal: 10),
                                           border: InputBorder.none,
                                           filled: true,
                                           fillColor:
                                           colors.primary.withOpacity(0.1),
                                           //isDense: true,
                                           hintText: getTranslated(context, 'NOTE'),
                                         ),
                                       ),
                                     ),
                                     // Row(
                                     //   children: [
                                     //     Radio(
                                     //         value: "schedule",
                                     //         groupValue: choose,
                                     //         activeColor: colors.primary,
                                     //         onChanged: (val) {
                                     //           setState(() {
                                     //             choose = val;
                                     //             otpOnOff = true;
                                     //             print("selected radio is == $choose");
                                     //           });
                                     //         }),
                                     //     Text("${getTranslated(context, 'SCHEDULE')}", style: TextStyle(fontSize: 13),),
                                     //     Radio(
                                     //         value: "immediately",
                                     //         groupValue: choose,
                                     //         activeColor: colors.primary,
                                     //         onChanged: (val) {
                                     //           setState(() {
                                     //             choose = val;
                                     //             otpOnOff = false;
                                     //             print("selected radio is == $choose");
                                     //           });
                                     //         }),
                                     //     Text("${getTranslated(context, 'IMMADIATELY')}", style: TextStyle(fontSize: 13)),
                                     //   ],
                                     // )
                                   ],
                                 ),
                               ),
                             ]);
                     },),
                  actions: <Widget>[
                    new TextButton(
                        child: Text(getTranslated(context, 'CANCEL')!,
                            style: TextStyle(
                                color: Theme.of(context).colorScheme.lightBlack,
                                fontSize: 15,
                                fontWeight: FontWeight.bold)),
                        onPressed: () {
                          checkoutState!(() {
                            _placeOrder = true;
                          });
                          Navigator.pop(context);
                        }),
                    new TextButton(
                        child: Text(getTranslated(context, 'DONE')!,
                            style: TextStyle(
                                color: colors.primary,
                                fontSize: 15,
                                fontWeight: FontWeight.bold)),
                        onPressed: () {
                          Navigator.pop(context);
                          print("hgcdejhfce");
                          doPayment();
                        })
                  ],
                )),
          );
        },
        transitionDuration: Duration(milliseconds: 200),
        barrierDismissible: false,
        barrierLabel: '',
        context: context,
        pageBuilder: (context, animation1, animation2) {
          return Container();
        });
  }

  dynamic choose = "mobile";
  bool otpOnOff = true;

  void bankTransfer() {
    showGeneralDialog(
        barrierColor: Theme.of(context).colorScheme.black.withOpacity(0.5),
        transitionBuilder: (context, a1, a2, widget) {
          return Transform.scale(
            scale: a1.value,
            child: Opacity(
                opacity: a1.value,
                child: AlertDialog(
                  contentPadding: const EdgeInsets.all(0),
                  elevation: 2.0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.all(Radius.circular(5.0))),
                  content: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                            padding: EdgeInsets.fromLTRB(20.0, 20.0, 0, 2.0),
                            child: Text(
                              getTranslated(context, 'BANKTRAN')!,
                              style: Theme.of(this.context)
                                  .textTheme
                                  .subtitle1!
                                  .copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .fontColor),
                            )),
                        Divider(
                            color: Theme.of(context).colorScheme.lightBlack),
                        Padding(
                            padding: EdgeInsets.fromLTRB(20.0, 0, 20.0, 0),
                            child: Text(getTranslated(context, 'BANK_INS')!,
                                style: Theme.of(context).textTheme.caption)),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20.0, vertical: 10),
                          child: Text(
                            getTranslated(context, 'ACC_DETAIL')!,
                            style: Theme.of(context)
                                .textTheme
                                .subtitle2!
                                .copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .fontColor),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20.0,
                          ),
                          child: Text(
                            getTranslated(context, 'ACCNAME')! +
                                " : " +
                                acName!,
                            style: Theme.of(context).textTheme.subtitle2,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20.0,
                          ),
                          child: Text(
                            getTranslated(context, 'ACCNO')! + " : " + acNo!,
                            style: Theme.of(context).textTheme.subtitle2,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20.0,
                          ),
                          child: Text(
                            getTranslated(context, 'BANKNAME')! +
                                " : " +
                                bankName!,
                            style: Theme.of(context).textTheme.subtitle2,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20.0,
                          ),
                          child: Text(
                            getTranslated(context, 'BANKCODE')! +
                                " : " +
                                bankNo!,
                            style: Theme.of(context).textTheme.subtitle2,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20.0,
                          ),
                          child: Text(
                            getTranslated(context, 'EXTRADETAIL')! +
                                " : " +
                                exDetails!,
                            style: Theme.of(context).textTheme.subtitle2,
                          ),
                        )
                      ]),
                  actions: <Widget>[
                    new TextButton(
                        child: Text(getTranslated(context, 'CANCEL')!,
                            style: TextStyle(
                                color: Theme.of(context).colorScheme.lightBlack,
                                fontSize: 15,
                                fontWeight: FontWeight.bold)),
                        onPressed: () {
                          checkoutState!(() {
                            _placeOrder = true;
                          });
                          Navigator.pop(context);
                        }),
                    new TextButton(
                        child: Text(getTranslated(context, 'DONE')!,
                            style: TextStyle(
                                color: Theme.of(context).colorScheme.fontColor,
                                fontSize: 15,
                                fontWeight: FontWeight.bold)),
                        onPressed: () {
                          Navigator.pop(context);

                          context.read<CartProvider>().setProgress(true);
                          print("bnak transfer order");
                          placeOrder('');
                        })
                  ],
                )),
          );
        },
        transitionDuration: Duration(milliseconds: 200),
        barrierDismissible: false,
        barrierLabel: '',
        context: context,
        pageBuilder: (context, animation1, animation2) {
          return Container();
        });
  }

  Future<void> checkDeliverable() async {
    _isNetworkAvail = await isNetworkAvailable();
    if (_isNetworkAvail) {
      try {
        context.read<CartProvider>().setProgress(true);

        var parameter = {
          USER_ID: CUR_USERID,
          ADD_ID: selAddress,
        };

        Response response =
            await post(checkCartDelApi, body: parameter, headers: headers)
                .timeout(Duration(seconds: timeOut));

        var getdata = json.decode(response.body);

        bool error = getdata["error"];
        String? msg = getdata["message"];
        var data = getdata["data"];
        context.read<CartProvider>().setProgress(false);

        if (error) {
          deliverableList = (data as List)
              .map((data) => new Model.checkDeliverable(data))
              .toList();
          checkoutState!(() {
            deliverable = false;
            _placeOrder = true;
          });
          setSnackbar(msg!, _checkscaffoldKey);
        } else {
          deliverableList = (data as List)
              .map((data) => new Model.checkDeliverable(data))
              .toList();
          checkoutState!(() {
            deliverable = true;
          });
          confirmDialog();
        }
      } on TimeoutException catch (_) {
        setSnackbar(getTranslated(context, 'somethingMSg')!, _checkscaffoldKey);
      }
    } else {
      if (mounted)
        setState(() {
          _isNetworkAvail = false;
        });
    }
  }
}

// import 'dart:async';
// import 'dart:convert';
// import 'dart:io';
// import 'package:cached_network_image/cached_network_image.dart';
// import 'package:homely_user/Helper/Constant.dart';
// import 'package:homely_user/Helper/Session.dart';
// import 'package:homely_user/Provider/CartProvider.dart';
// import 'package:homely_user/Provider/SettingProvider.dart';
// import 'package:homely_user/Provider/UserProvider.dart';
// import 'package:flutter/cupertino.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_svg/svg.dart';
// import 'package:http/http.dart';
// import 'package:paytm/paytm.dart';
// import 'package:provider/provider.dart';
// import 'package:razorpay_flutter/razorpay_flutter.dart';
// import '../Helper/AppBtn.dart';
// import '../Helper/Color.dart';
// import '../Helper/SimBtn.dart';
// import '../Helper/String.dart';
// import '../Helper/Stripe_Service.dart';
// import '../Model/Model.dart';
// import '../Model/Section_Model.dart';
// import '../Model/User.dart';
// import 'Add_Address.dart';
// import 'Favorite.dart';
// import 'Login.dart';
// import 'Manage_Address.dart';
// import 'NotificationLIst.dart';
// import 'Order_Success.dart';
// import 'package:http/http.dart' as http;
// import 'Payment.dart';
// import 'PaypalWebviewActivity.dart';
// import 'Search.dart';
//
// class Cart extends StatefulWidget {
//   final bool fromBottom;
//
//   const Cart({Key? key, required this.fromBottom}) : super(key: key);
//
//   @override
//   State<StatefulWidget> createState() => StateCart();
// }
//
// List<User> addressList = [];
// //List<SectionModel> cartList = [];
// List<Promo> promoList = [];
// double totalPrice = 0, oriPrice = 0, delCharge = 0, taxPer = 0;
// int? selectedAddress = 0;
// String? selAddress, payMethod = '', selTime,selTimeDelivery, selTimeId, selDate, promocode;
// bool? isTimeSlot,
//     isPromoValid = false,
//     isUseWallet = false,
//     isPayLayShow = true;
// int? selectedTime, selectedDate, selectedMethod;
//
// double promoAmt = 0;
// double remWalBal = 0, usedBal = 0;
// bool isAvailable = true;
//
// String? razorpayId,
//     paystackId,
//     stripeId,
//     stripeSecret,
//     stripeMode = "test",
//     stripeCurCode,
//     stripePayId,
//     paytmMerId,
//     paytmMerKey;
// bool payTesting = true;
//
// /*String gpayEnv = "TEST",
//     gpayCcode = "US",
//     gpaycur = "USD",
//     gpayMerId = "01234567890123456789",
//     gpayMerName = "Example Merchant Name";*/
//
// class StateCart extends State<Cart> with TickerProviderStateMixin {
//   final GlobalKey<ScaffoldMessengerState> _scaffoldKey =
//   new GlobalKey<ScaffoldMessengerState>();
//
//   final GlobalKey<ScaffoldMessengerState> _checkscaffoldKey =
//   new GlobalKey<ScaffoldMessengerState>();
//   List<Model> deliverableList = [];
//   bool _isCartLoad = true, _placeOrder = true;
//
//   //HomePage? home;
//   Animation? buttonSqueezeanimation;
//   AnimationController? buttonController;
//   bool _isNetworkAvail = true;
//
//   List<TextEditingController> _controller = [];
//
//   final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey =
//   new GlobalKey<RefreshIndicatorState>();
//   List<SectionModel> saveLaterList = [];
//   String? msg;
//   String? sellerId;
//   bool _isLoading = true;
//   Razorpay? _razorpay;
//   TextEditingController promoC = new TextEditingController();
//   TextEditingController noteC = new TextEditingController();
//   StateSetter? checkoutState;
//   bool deliverable = false;
//   bool saveLater = false, addCart = false;
//   bool isOnOff = false;
//   String? totalamount;
//   String? productImage;
//
//   //List<PaymentItem> _gpaytItems = [];
//   //Pay _gpayClient;
//
//
//   @override
//   void initState() {
//     super.initState();
//     clearAll();
//     _getCart("0");
//     _getSaveLater("1");
//
//     // _getAddress();
//
//     buttonController = new AnimationController(
//         duration: new Duration(milliseconds: 2000), vsync: this);
//
//     buttonSqueezeanimation = new Tween(
//       begin: deviceWidth! * 0.7,
//       end: 50.0,
//     ).animate(new CurvedAnimation(
//       parent: buttonController!,
//       curve: new Interval(
//         0.0,
//         0.150,
//       ),
//     ));
//   }
//
//   Future<Null> _refresh() {
//     if (mounted)
//       setState(() {
//         _isCartLoad = true;
//       });
//     clearAll();
//
//     _getCart("0");
//     return _getSaveLater("1");
//   }
//
//   clearAll() {
//     totalPrice = 0;
//     oriPrice = 0;
//
//     taxPer = 0;
//     delCharge = 0;
//     addressList.clear();
//     // cartList.clear();
//     WidgetsBinding.instance!.addPostFrameCallback((timeStamp) {
//       context.read<CartProvider>().setCartlist([]);
//       context.read<CartProvider>().setProgress(false);
//     });
//
//     promoAmt = 0;
//     remWalBal = 0;
//     usedBal = 0;
//     payMethod = '';
//     isPromoValid = false;
//     isUseWallet = false;
//     isPayLayShow = true;
//     selectedMethod = null;
//   }
//
//   var deliveryAddres;
//
//   @override
//   void dispose() {
//     buttonController!.dispose();
//     for (int i = 0; i < _controller.length; i++) _controller[i].dispose();
//
//     if (_razorpay != null) _razorpay!.clear();
//     super.dispose();
//   }
//
//   Future<Null> _playAnimation() async {
//     try {
//       await buttonController!.forward();
//     } on TickerCanceled {}
//   }
//
//   Widget noInternet(BuildContext context) {
//     return Center(
//       child: SingleChildScrollView(
//         child: Column(mainAxisSize: MainAxisSize.min, children: [
//           noIntImage(),
//           noIntText(context),
//           noIntDec(context),
//           AppBtn(
//             title: getTranslated(context, 'TRY_AGAIN_INT_LBL'),
//             btnAnim: buttonSqueezeanimation,
//             btnCntrl: buttonController,
//             onBtnSelected: () async {
//               _playAnimation();
//
//               Future.delayed(Duration(seconds: 2)).then((_) async {
//                 _isNetworkAvail = await isNetworkAvailable();
//                 if (_isNetworkAvail) {
//                   Navigator.pushReplacement(
//                       context,
//                       MaterialPageRoute(
//                           builder: (BuildContext context) => super.widget));
//                 } else {
//                   await buttonController!.reverse();
//                   if (mounted) setState(() {});
//                 }
//               });
//             },
//           )
//         ]),
//       ),
//     );
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     deviceHeight = MediaQuery.of(context).size.height;
//     deviceWidth = MediaQuery.of(context).size.width;
//     print("delivery value ${deliveryAddres}");
//     return SafeArea(
//       bottom: false,
//       top: true,
//       child: Scaffold(
//           backgroundColor: colors.blackTemp,
//                   appBar: widget.fromBottom
//             ? null
//             : getSimpleAppBar(getTranslated(context, 'CART')!, context),
//
//           //    appBar: widget.fromBottom
//           //      ? null
//           //    : getSimpleAppBar(getTranslated(context, 'CART')!, context),
//           body: _isNetworkAvail
//               ? Container(
//             color: Color(0XFFF3F3F3),
//             child: Stack(
//               children: <Widget>[
//                 _showContent(context),
//                 Selector<CartProvider, bool>(
//                   builder: (context, data, child) {
//                     return showCircularProgress(data, colors.primary);
//                   },
//                   selector: (_, provider) => provider.isProgress,
//                 ),
//               ],
//             ),
//           )
//               : noInternet(context)),
//     );
//   }
//
//   Widget listItem(int index, List<SectionModel> cartList) {
//     int selectedPos = 0;
//     for (int i = 0;
//     i < cartList[index].productList![0].prVarientList!.length;
//     i++) {
//       if (cartList[index].varientId ==
//           cartList[index].productList![0].prVarientList![i].id) selectedPos = i;
//     }
//     String? offPer;
//     double price = double.parse(
//         cartList[index].productList![0].prVarientList![selectedPos].disPrice!);
//     if (price == 0)
//       price = double.parse(
//           cartList[index].productList![0].prVarientList![selectedPos].price!);
//     else {
//       double off = (double.parse(cartList[index]
//           .productList![0]
//           .prVarientList![selectedPos]
//           .price!)) -
//           price;
//       offPer = (off *
//           100 /
//           double.parse(cartList[index]
//               .productList![0]
//               .prVarientList![selectedPos]
//               .price!))
//           .toStringAsFixed(2);
//     }
//
//     cartList[index].perItemPrice = price.toString();
//     //print("qty************${cartList.contains("qty")}");
//     print("cartList**avail****${cartList[index].productList![0].availability}");
//
//     if (_controller.length < index + 1) {
//       _controller.add(new TextEditingController());
//     }
//     if (cartList[index].productList![0].availability != "0") {
//       cartList[index].perItemTotal =
//           (price * double.parse(cartList[index].qty!)).toString();
//       _controller[index].text = cartList[index].qty!;
//     }
//     List att = [], val = [];
//     if (cartList[index].productList![0].prVarientList![selectedPos].attr_name !=
//         null) {
//       att = cartList[index]
//           .productList![0]
//           .prVarientList![selectedPos]
//           .attr_name!
//           .split(',');
//       val = cartList[index]
//           .productList![0]
//           .prVarientList![selectedPos]
//           .varient_value!
//           .split(',');
//     }
//
//     String addOn = "";
//
//     for(int j=0;j<cartList[index].productList![0].addOnList!.length;j++){
//
//       var model = cartList[index].productList![0].addOnList![j];
//       print("dars"+model.price.toString()+cartList[index].qty.toString());
//
//       if(cartList[index].add_on_id.toString().split(", ").contains(model.id)){
//         if(addOn==""){
//           addOn += model.name.toString();
//         }else{
//           addOn += ", "+model.name.toString();
//         }
//       }
//     }
//     if (cartList[index].productList![0].availability == "0") {
//       isAvailable = false;
//     };
//     print("okokokokok ${cartList[index].productList![0].addOnList!.length}");
//     return Padding(
//         padding: const EdgeInsets.symmetric(
//           vertical: 10.0,
//         ),
//         child: Stack(
//           clipBehavior: Clip.none,
//           children: [
//             Card(
//               elevation: 0.1,
//               child: Column(
//                 children: [
//                   Row(
//                     children: <Widget>[
//                       Hero(
//                           tag: "$index${cartList[index].productList![0].id}",
//                           child: Stack(
//                             children: [
//                               ClipRRect(
//                                   borderRadius: BorderRadius.circular(7.0),
//                                   child: Stack(children: [
//                                     Card(
//                                       child: Container(
//                                         width: 120,
//                                         height: 100,
//                                         child: FadeInImage(
//                                           image: CachedNetworkImageProvider(
//                                               cartList[index].productList![0].image!),
//                                           height: 125.0,
//                                           width: 110.0,
//                                           fit: BoxFit.contain,
//                                           imageErrorBuilder:
//                                               (context, error, stackTrace) =>
//                                               erroWidget(125),
//                                           placeholder: placeHolder(125),
//                                         ),
//                                       ),
//                                     ),
//                                     Positioned.fill(
//                                         child: cartList[index]
//                                             .productList![0]
//                                             .availability ==
//                                             "0"
//                                             ? Container(
//                                           height: 55,
//                                           color: Colors.white70,
//                                           // width: double.maxFinite,
//                                           padding: EdgeInsets.all(2),
//                                           child: Center(
//                                             child: Text(
//                                               getTranslated(context,
//                                                   'OUT_OF_STOCK_LBL')!,
//                                               style: Theme.of(context)
//                                                   .textTheme
//                                                   .caption!
//                                                   .copyWith(
//                                                 color: Colors.red,
//                                                 fontWeight:
//                                                 FontWeight.bold,
//                                               ),
//                                               textAlign: TextAlign.center,
//                                             ),
//                                           ),
//                                         )
//                                             : Container()),
//                                   ])),
//                               offPer != null
//                                   ? Container(
//                                 decoration: BoxDecoration(
//                                     color: colors.red,
//                                     borderRadius: BorderRadius.circular(10)),
//                                 child: Padding(
//                                   padding: const EdgeInsets.all(5.0),
//                                   child: Text(
//                                     offPer + "%",
//                                     style: TextStyle(
//                                         color: colors.whiteTemp,
//                                         fontWeight: FontWeight.bold,
//                                         fontSize: 9),
//                                   ),
//                                 ),
//                                 margin: EdgeInsets.all(5),
//                               )
//                                   : Container()
//                             ],
//                           )),
//                       Expanded(
//                         child: Padding(
//                           padding: const EdgeInsetsDirectional.all(8.0),
//                           child: Column(
//                             crossAxisAlignment: CrossAxisAlignment.start,
//                             children: <Widget>[
//                               Row(
//                                 crossAxisAlignment: CrossAxisAlignment.start,
//                                 children: [
//                                   Expanded(
//                                     child: Padding(
//                                       padding: const EdgeInsetsDirectional.only(
//                                           top: 5.0),
//                                       child: Text(
//                                         cartList[index].productList![0].name!,
//                                         style: Theme.of(context)
//                                             .textTheme
//                                             .subtitle1!
//                                             .copyWith(
//                                             color: Theme.of(context)
//                                                 .colorScheme
//                                                 .fontColor),
//                                         maxLines: 2,
//                                         overflow: TextOverflow.ellipsis,
//                                       ),
//                                     ),
//                                   ),
//
//                                   GestureDetector(
//                                     child: Padding(
//                                       padding: const EdgeInsetsDirectional.only(
//                                           start: 8.0, end: 8, bottom: 8),
//                                       child: Icon(
//                                         Icons.clear,
//                                         size: 20,
//                                         color:
//                                         Theme.of(context).colorScheme.fontColor,
//                                       ),
//                                     ),
//                                     onTap: () {
//                                       print(index);
//                                       print(cartList);
//                                       print(selectedPos);
//                                       if (context.read<CartProvider>().isProgress ==
//                                           false)
//                                         removeFromCart(index, true, cartList, false,
//                                             selectedPos);
//                                     },
//                                   )
//                                 ],
//                               ),
//                               cartList[index]
//                                   .productList![0]
//                                   .prVarientList![selectedPos]
//                                   .attr_name !=
//                                   null &&
//                                   cartList[index]
//                                       .productList![0]
//                                       .prVarientList![selectedPos]
//                                       .attr_name!
//                                       .isNotEmpty
//                                   ? ListView.builder(
//                                   physics: NeverScrollableScrollPhysics(),
//                                   shrinkWrap: true,
//                                   itemCount: att.length,
//                                   itemBuilder: (context, index) {
//                                     return Row(children: [
//                                       Flexible(
//                                         child: Text(
//                                           att[index].trim() + ":",
//                                           overflow: TextOverflow.ellipsis,
//                                           style: Theme.of(context)
//                                               .textTheme
//                                               .subtitle2!
//                                               .copyWith(
//                                             color: Theme.of(context)
//                                                 .colorScheme
//                                                 .lightBlack,
//                                           ),
//                                         ),
//                                       ),
//                                       Padding(
//                                         padding: EdgeInsetsDirectional.only(
//                                             start: 5.0),
//                                         child: Text(
//                                           val[index],
//                                           style: Theme.of(context)
//                                               .textTheme
//                                               .subtitle2!
//                                               .copyWith(
//                                               color: Theme.of(context)
//                                                   .colorScheme
//                                                   .lightBlack,
//                                               fontWeight: FontWeight.bold),
//                                         ),
//                                       )
//                                     ]);
//                                   })
//                                   : Container(),
//                               Row(
//                                 children: <Widget>[
//                                   Text(
//                                     double.parse(cartList[index]
//                                         .productList![0]
//                                         .prVarientList![selectedPos]
//                                         .disPrice!) !=
//                                         0
//                                         ? CUR_CURRENCY! +
//                                         "" +
//                                         cartList[index]
//                                             .productList![0]
//                                             .prVarientList![selectedPos]
//                                             .price!
//                                         : "",
//                                     style: Theme.of(context)
//                                         .textTheme
//                                         .overline!
//                                         .copyWith(
//                                         decoration: TextDecoration.lineThrough,
//                                         letterSpacing: 0.7),
//                                   ),
//                                   Text(
//                                     " " + CUR_CURRENCY! + " " + price.toString(),
//                                     style: TextStyle(
//                                         color:
//                                         Theme.of(context).colorScheme.fontColor,
//                                         fontWeight: FontWeight.bold),
//                                   ),
//                                 ],
//                               ),
//                               Text("Qty:${cartList[index].qty}",),
//                               cartList[index].productList![0].availability == "1" ||
//                                   cartList[index].productList![0].stockType ==
//                                       "0"
//                                   ? Row(
//                                 children: <Widget>[
//                                   Row(
//                                     children: <Widget>[
//                                       GestureDetector(
//                                         child: Card(
//                                           shape: RoundedRectangleBorder(
//                                             borderRadius:
//                                             BorderRadius.circular(50),
//                                           ),
//                                           child: Padding(
//                                             padding:
//                                             const EdgeInsets.all(8.0),
//                                             child: Icon(
//                                               Icons.remove,
//                                               size: 15,
//                                             ),
//                                           ),
//                                         ),
//                                         onTap: () {
//                                           if (context
//                                               .read<CartProvider>()
//                                               .isProgress ==
//                                               false)
//                                             removeFromCart(index, false,
//                                                 cartList, false, selectedPos);
//                                         },
//                                       ),
//                                       Container(
//                                         width: 26,
//                                         height: 20,
//                                         child: Stack(
//                                           children: [
//                                             TextField(
//                                               textAlign: TextAlign.center,
//                                               readOnly: true,
//                                               style: TextStyle(
//                                                   fontSize: 12,
//                                                   color: Theme.of(context)
//                                                       .colorScheme
//                                                       .fontColor),
//                                               controller: _controller[index],
//                                               decoration: InputDecoration(
//                                                 border: InputBorder.none,
//                                               ),
//                                             ),
//                                             // PopupMenuButton<String>(
//                                             //   tooltip: '',
//                                             //   icon: const Icon(
//                                             //     Icons.arrow_drop_down,
//                                             //     size: 1,
//                                             //   ),
//                                             //   onSelected: (String value) {
//                                             //     if (context
//                                             //             .read<CartProvider>()
//                                             //             .isProgress ==
//                                             //         false)
//                                             //       addToCart(
//                                             //           index, value, cartList);
//                                             //   },
//                                             //   itemBuilder:
//                                             //       (BuildContext context) {
//                                             //     return cartList[index]
//                                             //         .productList![0]
//                                             //         .itemsCounter!
//                                             //         .map<
//                                             //                 PopupMenuItem<
//                                             //                     String>>(
//                                             //             (String value) {
//                                             //       return new PopupMenuItem(
//                                             //           child: new Text(value,
//                                             //               style: TextStyle(
//                                             //                   color: Theme.of(
//                                             //                           context)
//                                             //                       .colorScheme
//                                             //                       .fontColor)),
//                                             //           value: value);
//                                             //     }).toList();
//                                             //   },
//                                             // ),
//                                           ],
//                                         ),
//                                       ), // ),
//
//                                       GestureDetector(
//                                         child: Card(
//                                           shape: RoundedRectangleBorder(
//                                             borderRadius:
//                                             BorderRadius.circular(50),
//                                           ),
//                                           child: Padding(
//                                             padding:
//                                             const EdgeInsets.all(8.0),
//                                             child: Icon(
//                                               Icons.add,
//                                               size: 15,
//                                             ),
//                                           ),
//                                         ),
//                                         onTap: () {
//                                           print("New QUUUUUUUUUUUU_______ ${cartList[index]
//                                               .qty!}");
//                                           if (context
//                                               .read<CartProvider>()
//                                               .isProgress ==
//                                               false)
//                                             addToCart(
//                                                 index,
//                                                 (int.parse(cartList[index]
//                                                     .qty!) +
//                                                     int.parse(cartList[
//                                                     index]
//                                                         .productList![0]
//                                                         .qtyStepSize!))
//                                                     .toString(),
//                                                 cartList);
//                                         },
//                                       )
//                                     ],
//                                   ),
//                                 ],
//                               )
//                                   : Container(),
//                             ],
//                           ),
//                         ),
//                       )
//                     ],
//                   ),
//                   // Column(
//                   //     children: cartList[index].productList![0].addOnList!.length > 0 ?
//                   //         cartList[index].productList![0].addOnList!.map((e){
//                   //           List<AddOnModel> addList = cartList[index].productList![0].addOnList!.toList();
//                   //           String name = "";
//                   //           if(addList.indexWhere((element) => e.id!.contains(element.id.toString()))!=-1){
//                   //             name = addList[addList.indexWhere((element) => e.id!.contains(element.id.toString()))].name.toString();
//                   //           }
//                   //           print("ooooooooooo ${e.name}");
//                   //           return Container(
//                   //               child: Row(
//                   //                   children: [
//                   //                     Text("${e.name}")
//                   //                   ],
//                   //               ),
//                   //           );
//                   //         }).toList();
//                   // ),
//                   Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: cartList[index].productList![0].addOnList!.length>0?
//                     cartList[index].productList![0].addOnList!.map((e) {
//                       List<AddOnModel> addList = cartList[index].productList![0].addOnList!.toList();
//                       String name = "";
//                       if(addList.indexWhere((element) => e.id!.contains(element.id.toString()))!=-1){
//                         name = addList[addList.indexWhere((element) => e.id!.contains(element.id.toString()))].name.toString();
//                       }
//                       print("iiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiii ${e.image}");
//                       return  Padding(
//                         padding: const EdgeInsets.all(5.0),
//                         child: Column(
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: [
//                             Padding(
//                               padding: const EdgeInsets.only(left: 5),
//                               child: Text("Add On",style: TextStyle(),),
//                             ),
//                             SizedBox(height:8),
//                             Row(
//                               children: [
//                                 Container(
//                                     height: 50,
//                                     width:50,
//                                     child: e.image == null || e.image == "" ?  Image.asset("assets/images/placeholder.png") : Image.network("${e.image}",fit: BoxFit.fill,)),
//                                 SizedBox(width: 10,),
//                                 Column(
//                                   crossAxisAlignment: CrossAxisAlignment.start,
//                                   children: [
//                                     Container(
//                                     //  width: 150,
//                                       child: Text(" "+
//                                           e.name.toString(),
//                                         style: Theme.of(context)
//                                             .textTheme
//                                             .subtitle1!
//                                             .copyWith(
//                                             color: Theme.of(context)
//                                                 .colorScheme
//                                                 .fontColor), maxLines: 1,
//                                         overflow: TextOverflow.ellipsis,
//                                       ),
//                                     ),
//                                     // Spacer(),
//                                     Text(
//                                       " " + CUR_CURRENCY! + " " + e.price.toString(),
//                                       style: TextStyle(
//                                           color:
//                                           Theme.of(context).colorScheme.fontColor,
//                                           fontWeight: FontWeight.bold),
//                                     ),
//                                     // Text(
//                                     //   "Add On Qty: "  + e.quantity.toString(),
//                                     //   style: TextStyle(
//                                     //       color:
//                                     //       Theme.of(context).colorScheme.fontColor,
//                                     //       fontWeight: FontWeight.bold),
//                                     // ),
//                                   ],
//                                 ),
//                               ],
//                             ),
//                             // SizedBox(
//                             //   width: 10,
//                             // ),
//
//                             // Container(
//                             //   height: 100,
//                             //     width: double.infinity,
//                             //     child: Image.network("${e.image}",fit: BoxFit.fill,)),
//
//
//                             SizedBox(
//                               width: 10,
//                             ),
//                           ],
//                         ),
//                       );
//                     }).toList():[],
//                   ),
//                   SizedBox(
//                     height: 20,
//                   ),
//                 ],
//               ),
//             ),
//             Positioned.directional(
//                 textDirection: Directionality.of(context),
//                 end: 0,
//                 bottom: -15,
//                 child: Card(
//                   elevation: 1,
//                   shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(50),
//                   ),
//                   child: InkWell(
//                     child: Padding(
//                       padding: const EdgeInsets.all(8.0),
//                       child: Icon(
//                         Icons.archive_rounded,
//                         size: 20,
//                       ),
//                     ),
//                     onTap: !saveLater &&
//                         !context.read<CartProvider>().isProgress
//                         ? () {
//                       setState(() {
//                         saveLater = true;
//                       });
//                       saveForLater(
//                           cartList[index].productList![0].availability ==
//                               "0"
//                               ? cartList[index]
//                               .productList![0]
//                               .prVarientList![selectedPos]
//                               .id!
//                               : cartList[index].varientId,
//                           "1",
//                           cartList[index].productList![0].availability ==
//                               "0"
//                               ? "1"
//                               : cartList[index].qty,
//                           double.parse(cartList[index].perItemTotal!),
//                           cartList[index],
//                           false);
//                     }
//                         : null,
//                   ),
//                 ))
//           ],
//         ));
//   }
//
//   Widget cartItem(int index, List<SectionModel> cartList) {
//     int selectedPos = 0;
//     for (int i = 0;
//     i < cartList[index].productList![0].prVarientList!.length;
//     i++) {
//       if (cartList[index].varientId ==
//           cartList[index].productList![0].prVarientList![i].id) selectedPos = i;
//     }
//
//     double price = double.parse(
//         cartList[index].productList![0].prVarientList![selectedPos].disPrice!);
//     if (price == 0)
//       price = double.parse(
//           cartList[index].productList![0].prVarientList![selectedPos].price!);
//
//     cartList[index].perItemPrice = price.toString();
//     cartList[index].perItemTotal =
//         (price * double.parse(cartList[index].qty!)).toString();
//
//     _controller[index].text = cartList[index].qty!;
//
//     List att = [], val = [];
//     if (cartList[index].productList![0].prVarientList![selectedPos].attr_name !=
//         null) {
//       att = cartList[index]
//           .productList![0]
//           .prVarientList![selectedPos]
//           .attr_name!
//           .split(',');
//       val = cartList[index]
//           .productList![0]
//           .prVarientList![selectedPos]
//           .varient_value!
//           .split(',');
//     }
//
//     String? id, varId;
//     bool? avail = false;
//     if (deliverableList.length > 0) {
//       id = cartList[index].id;
//       varId = cartList[index].productList![0].prVarientList![selectedPos].id;
//
//       for (int i = 0; i < deliverableList.length; i++) {
//         if (id == deliverableList[i].prodId &&
//             varId == deliverableList[i].varId) {
//           avail = deliverableList[i].isDel;
//
//           break;
//         }
//       }
//     }
//     double addOnPrice = 0;
//     if(cartList[index].addOns!=null){
//       for(int i = 0;i<cartList[index].addOns!.length;i++){
//         addOnPrice += double.parse(cartList[index].addOns![i].totalAmount.toString());
//         //  addOnPrice += addOnPrice;
//       }
//       print("this is add on price ${addOnPrice.toString()}");
//     }
//     return Card(
//       elevation: 0.1,
//       child: Padding(
//         padding: const EdgeInsets.all(8.0),
//         child: Column(
//           children: [
//             Row(
//               children: <Widget>[
//                 Hero(
//                     tag: "$index${cartList[index].productList![0].id}",
//                     child: ClipRRect(
//                         borderRadius: BorderRadius.circular(7.0),
//                         child: FadeInImage(
//                           image: CachedNetworkImageProvider(
//                               cartList[index].productList![0].image!),
//                           height: 80.0,
//                           width: 80.0,
//                           fit: BoxFit.cover,
//                           imageErrorBuilder: (context, error, stackTrace) =>
//                               erroWidget(80),
//
//                           // errorWidget: (context, url, e) => placeHolder(60),
//                           placeholder: placeHolder(80),
//                         ))),
//                 Expanded(
//                   child: Padding(
//                     padding: const EdgeInsetsDirectional.only(start: 8.0),
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: <Widget>[
//                         Row(
//                           children: [
//                             Expanded(
//                               child: Padding(
//                                 padding:
//                                 const EdgeInsetsDirectional.only(top: 5.0),
//                                 child: Text(
//                                   cartList[index].productList![0].name!,
//                                   style: Theme.of(context)
//                                       .textTheme
//                                       .subtitle2!
//                                       .copyWith(
//                                       color: Theme.of(context)
//                                           .colorScheme
//                                           .lightBlack),
//                                   maxLines: 2,
//                                   overflow: TextOverflow.ellipsis,
//                                 ),
//                               ),
//                             ),
//                             // GestureDetector(
//                             //   child: Padding(
//                             //     padding: const EdgeInsetsDirectional.only(
//                             //         start: 8.0, end: 8, bottom: 8),
//                             //     child: Icon(
//                             //       Icons.clear,
//                             //       size: 13,
//                             //       color:
//                             //           Theme.of(context).colorScheme.fontColor,
//                             //     ),
//                             //   ),
//                             //   onTap: () {
//                             //     if (context.read<CartProvider>().isProgress ==
//                             //         false)
//                             //       removeFromCartCheckout(index, true, cartList);
//                             //   },
//                             // )
//                           ],
//                         ),
//                         cartList[index]
//                             .productList![0]
//                             .prVarientList![selectedPos]
//                             .attr_name !=
//                             null &&
//                             cartList[index]
//                                 .productList![0]
//                                 .prVarientList![selectedPos]
//                                 .attr_name!
//                                 .isNotEmpty
//                             ? ListView.builder(
//                             physics: NeverScrollableScrollPhysics(),
//                             shrinkWrap: true,
//                             itemCount: att.length,
//                             itemBuilder: (context, index) {
//                               return Row(children: [
//                                 Flexible(
//                                   child: Text(
//                                     att[index].trim() + ":",
//                                     overflow: TextOverflow.ellipsis,
//                                     style: Theme.of(context)
//                                         .textTheme
//                                         .subtitle2!
//                                         .copyWith(
//                                       color: Theme.of(context)
//                                           .colorScheme
//                                           .lightBlack,
//                                     ),
//                                   ),
//                                 ),
//                                 Padding(
//                                   padding: EdgeInsetsDirectional.only(
//                                       start: 5.0),
//                                   child: Text(
//                                     val[index],
//                                     style: Theme.of(context)
//                                         .textTheme
//                                         .subtitle2!
//                                         .copyWith(
//                                         color: Theme.of(context)
//                                             .colorScheme
//                                             .lightBlack,
//                                         fontWeight: FontWeight.bold),
//                                   ),
//                                 )
//                               ]);
//                             })
//                             : Container(),
//                         Row(
//                           mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                           children: [
//                             Flexible(
//                               child: Row(
//                                 mainAxisSize: MainAxisSize.min,
//                                 children: <Widget>[
//                                   Flexible(
//                                     child: Text(
//                                       double.parse(cartList[index]
//                                           .productList![0]
//                                           .prVarientList![selectedPos]
//                                           .disPrice!) !=
//                                           0
//                                           ? CUR_CURRENCY! +
//                                           "" +
//                                           cartList[index]
//                                               .productList![0]
//                                               .prVarientList![selectedPos]
//                                               .price!
//                                           : "",
//                                       maxLines: 1,
//                                       overflow: TextOverflow.ellipsis,
//                                       style: Theme.of(context)
//                                           .textTheme
//                                           .overline!
//                                           .copyWith(
//                                           decoration:
//                                           TextDecoration.lineThrough,
//                                           letterSpacing: 0.7),
//                                     ),
//                                   ),
//                                   Text(
//                                     " " +
//                                         CUR_CURRENCY! +
//                                         " " +
//                                         price.toString(),
//                                     style: TextStyle(
//                                         color: Theme.of(context)
//                                             .colorScheme
//                                             .fontColor,
//                                         fontWeight: FontWeight.bold),
//                                   ),
//                                 ],
//                               ),
//                             ),
//                             cartList[index].productList![0].availability ==
//                                 "1" ||
//                                 cartList[index].productList![0].stockType ==
//                                     "null"
//                                 ? Row(
//                               children: <Widget>[
//                                 Row(
//                                   children: <Widget>[
//                                     // GestureDetector(
//                                     //   child: Card(
//                                     //     shape: RoundedRectangleBorder(
//                                     //       borderRadius:
//                                     //           BorderRadius.circular(50),
//                                     //     ),
//                                     //     child: Padding(
//                                     //       padding:
//                                     //           const EdgeInsets.all(8.0),
//                                     //       child: Icon(
//                                     //         Icons.remove,
//                                     //         size: 15,
//                                     //       ),
//                                     //     ),
//                                     //   ),
//                                     //   onTap: () {
//                                     //     if (context
//                                     //             .read<CartProvider>()
//                                     //             .isProgress ==
//                                     //         false)
//                                     //       removeFromCartCheckout(
//                                     //           index, false, cartList);
//                                     //   },
//                                     // ),
//                                     Container(
//                                       width: 26,
//                                       height: 20,
//                                       child: Stack(
//                                         children: [
//                                           TextField(
//                                             textAlign: TextAlign.center,
//                                             readOnly: true,
//                                             style: TextStyle(
//                                                 fontSize: 12,
//                                                 color: Theme.of(context)
//                                                     .colorScheme
//                                                     .fontColor),
//                                             controller:
//                                             _controller[index],
//                                             decoration: InputDecoration(
//                                               border: InputBorder.none,
//                                             ),
//                                           ),
//                                           // PopupMenuButton<String>(
//                                           //   tooltip: '',
//                                           //   icon: const Icon(
//                                           //     Icons.arrow_drop_down,
//                                           //     size: 1,
//                                           //   ),
//                                           //   onSelected: (String value) {
//                                           //     addToCartCheckout(
//                                           //         index, value, cartList);
//                                           //   },
//                                           //   itemBuilder:
//                                           //       (BuildContext context) {
//                                           //     return cartList[index]
//                                           //         .productList![0]
//                                           //         .itemsCounter!
//                                           //         .map<
//                                           //                 PopupMenuItem<
//                                           //                     String>>(
//                                           //             (String value) {
//                                           //       return new PopupMenuItem(
//                                           //           child: new Text(
//                                           //             value,
//                                           //             style: TextStyle(
//                                           //                 color: Theme.of(
//                                           //                         context)
//                                           //                     .colorScheme
//                                           //                     .fontColor),
//                                           //           ),
//                                           //           value: value);
//                                           //     }).toList();
//                                           //   },
//                                           // ),
//                                         ],
//                                       ),
//                                     ),
//                                     // GestureDetector(
//                                     //   child: Card(
//                                     //     shape: RoundedRectangleBorder(
//                                     //       borderRadius:
//                                     //           BorderRadius.circular(50),
//                                     //     ),
//                                     //     child: Padding(
//                                     //       padding:
//                                     //           const EdgeInsets.all(8.0),
//                                     //       child: Icon(
//                                     //         Icons.add,
//                                     //         size: 15,
//                                     //       ),
//                                     //     ),
//                                     //   ),
//                                     //   onTap: () {
//                                     //     addToCartCheckout(
//                                     //         index,
//                                     //         (int.parse(cartList[index]
//                                     //                     .qty!) +
//                                     //                 int.parse(cartList[
//                                     //                         index]
//                                     //                     .productList![0]
//                                     //                     .qtyStepSize!))
//                                     //             .toString(),
//                                     //         cartList);
//                                     //   },
//                                     // )
//                                   ],
//                                 ),
//                               ],
//                             )
//                                 : Container(),
//                           ],
//                         ),
//                       ],
//                     ),
//                   ),
//                 )
//               ],
//             ),
//
//             Column(
//               children: cartList[index].addOns!.length>0?
//               cartList[index].addOns!.map((AddOnsModel e) {
//                 List<AddOnModel> addList = cartList[index].productList![0].addOnList!.toList();
//                 String name = "";
//                 if(addList.indexWhere((element) => e.id!.contains(element.id.toString()))!=-1){
//                   name = addList[addList.indexWhere((element) => e.id!.contains(element.id.toString()))].name.toString();
//                 }
//                 return cartList[index].addOns!.isEmpty ? Padding(
//                   padding: const EdgeInsets.all(5.0),
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Padding(
//                         padding: const EdgeInsets.only(left: 5),
//                         child: Text("Add On",style: TextStyle(),),
//                       ),
//                       SizedBox(height:8),
//                       Row(
//                         children: [
//                           Container(
//                               height: 50,
//                               width:50,
//                               child: e.image == null || e.image == "" ?  Image.asset("assets/images/placeholder.png") : Image.network("${e.image}",fit: BoxFit.fill,)),
//                           SizedBox(width: 10,),
//                           Column(
//                             crossAxisAlignment: CrossAxisAlignment.start,
//                             children: [
//                               Container(
//                                 width: 150,
//                                 child: Text(" "+
//                                     e.quantity.toString()+" x "+name.toString(),
//                                   style: Theme.of(context)
//                                       .textTheme
//                                       .subtitle1!
//                                       .copyWith(
//                                       color: Theme.of(context)
//                                           .colorScheme
//                                           .fontColor), maxLines: 1,
//                                   overflow: TextOverflow.ellipsis,
//                                 ),
//                               ),
//                               // Spacer(),
//                               Text(
//                                 " " + CUR_CURRENCY! + " " + e.price.toString(),
//                                 style: TextStyle(
//                                     color:
//                                     Theme.of(context).colorScheme.fontColor,
//                                     fontWeight: FontWeight.bold),
//                               ),
//                               Text(
//                                 "Add On Qty: "  + e.quantity.toString(),
//                                 style: TextStyle(
//                                     color:
//                                     Theme.of(context).colorScheme.fontColor,
//                                     fontWeight: FontWeight.bold),
//                               ),
//                             ],
//                           ),
//                         ],
//                       ),
//                       // SizedBox(
//                       //   width: 10,
//                       // ),
//
//                       // Container(
//                       //   height: 100,
//                       //     width: double.infinity,
//                       //     child: Image.network("${e.image}",fit: BoxFit.fill,)),
//
//
//                       SizedBox(
//                         width: 10,
//                       ),
//                     ],
//                   ),
//                 )
//                     : SizedBox.shrink();
//
//                 //   Padding(
//                 //   padding: const EdgeInsets.all(5.0),
//                 //   child: Row(
//                 //     // mainAxisAlignment: MainAxisAlignment.start,
//                 //     // crossAxisAlignment: CrossAxisAlignment.start,
//                 //     children: [
//                 //       SizedBox(
//                 //         width: 10,
//                 //       ),
//                 //       Text("Add On"),
//                 //
//                 //       Column(
//                 //           children: [
//                 //             Container(
//                 //                 height: 50,
//                 //                 width:50,
//                 //                 child: e.image == null || e.image == "" ?  Image.asset("assets/images/placeholder.png") : Image.network("${e.image}",fit: BoxFit.fill,)),
//                 //           ],
//                 //       ),
//                 //       Column(
//                 //           crossAxisAlignment: CrossAxisAlignment.start,
//                 //         children: [
//                 //           Container(
//                 //             width: 150,
//                 //             child: Text(
//                 //               e.quantity.toString()+" x "+name.toString(),
//                 //               style: Theme.of(context)
//                 //                   .textTheme
//                 //                   .subtitle1!
//                 //                   .copyWith(
//                 //                   color: Theme.of(context)
//                 //                       .colorScheme
//                 //                       .fontColor), maxLines: 1,
//                 //               overflow: TextOverflow.ellipsis,
//                 //             ),
//                 //           ),
//                 //           // Spacer(),
//                 //           Text(
//                 //             " " + CUR_CURRENCY! + " " + e.price.toString(),
//                 //             style: TextStyle(
//                 //                 color:
//                 //                 Theme.of(context).colorScheme.fontColor,
//                 //                 fontWeight: FontWeight.bold),
//                 //           ),
//                 //         ],
//                 //       ),
//                 //
//                 //
//                 //       SizedBox(
//                 //         width: 10,
//                 //       ),
//                 //     ],
//                 //   ),
//                 // );
//               }).toList():[],
//             ),
//             Divider(),
//             Row(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               children: [
//                 Text(
//                   getTranslated(context, 'SUBTOTAL')!,
//                   style: TextStyle(
//                       color: Theme.of(context).colorScheme.lightBlack2),
//                 ),
//                 Text(
//                   CUR_CURRENCY! + " " + price.toString(),
//                   style: TextStyle(
//                       color: Theme.of(context).colorScheme.lightBlack2),
//                 ),
//                 Text(
//                   CUR_CURRENCY! + " " + cartList[index].perItemTotal!,
//                   style: TextStyle(
//                       color: Theme.of(context).colorScheme.lightBlack2),
//                 )
//               ],
//             ),
//             Row(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               children: [
//                 Text(
//                   "Add On Total",
//                   style: TextStyle(
//                       color: Theme.of(context).colorScheme.lightBlack2),
//                 ),
//                 /* Text(
//                   CUR_CURRENCY! + " " + addOnPrice.toString(),
//                   style: TextStyle(
//                       color: Theme.of(context).colorScheme.lightBlack2),
//                 ),*/
//                 Text(
//                   // "${cartList[index].addOns![i].totalAmount.toString()}",
//                   "${addOnPrice.toString()}",
//                   style: TextStyle(
//                       color: Theme.of(context).colorScheme.lightBlack2),
//                 )
//               ],
//             ),
//             Row(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               children: [
//                 Text(
//                   getTranslated(context, 'TAXPER')!,
//                   style: TextStyle(
//                       color: Theme.of(context).colorScheme.lightBlack2),
//                 ),
//                 Text(
//                   cartList[index].productList![0].tax! + "%",
//                   style: TextStyle(
//                       color: Theme.of(context).colorScheme.lightBlack2),
//                 ),
//               ],
//             ),
//             Row(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               children: [
//                 Text(
//                   getTranslated(context, 'TOTAL_LBL')!,
//                   style: TextStyle(
//                       fontWeight: FontWeight.bold,
//                       color: Theme.of(context).colorScheme.lightBlack2),
//                 ),
//                 !avail! && deliverableList.length > 0
//                     ? Text(
//                   getTranslated(context, 'NOT_DEL')!,
//                   style: TextStyle(color: colors.red),
//                 )
//                     : Container(),
//                 Text(
//                   CUR_CURRENCY! +
//                       " " +
//                       (double.parse(cartList[index].perItemTotal!) + addOnPrice)
//                           .toStringAsFixed(2)
//                           .toString(),
//                   //+ " "+cartList[index].productList[0].taxrs,
//                   style: TextStyle(
//                       fontWeight: FontWeight.bold,
//                       color: Theme.of(context).colorScheme.fontColor),
//                 )
//               ],
//             )
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget saveLaterItem(int index) {
//     int selectedPos = 0;
//     for (int i = 0;
//     i < saveLaterList[index].productList![0].prVarientList!.length;
//     i++) {
//       if (saveLaterList[index].varientId ==
//           saveLaterList[index].productList![0].prVarientList![i].id)
//         selectedPos = i;
//     }
//
//     double price = double.parse(saveLaterList[index]
//         .productList![0]
//         .prVarientList![selectedPos]
//         .disPrice!);
//     if (price == 0) {
//       price = double.parse(saveLaterList[index]
//           .productList![0]
//           .prVarientList![selectedPos]
//           .price!);
//     }
//
//     double off = (double.parse(saveLaterList[index]
//         .productList![0]
//         .prVarientList![selectedPos]
//         .price!) -
//         double.parse(saveLaterList[index]
//             .productList![0]
//             .prVarientList![selectedPos]
//             .disPrice!))
//         .toDouble();
//     off = off *
//         100 /
//         double.parse(saveLaterList[index]
//             .productList![0]
//             .prVarientList![selectedPos]
//             .price!);
//
//     saveLaterList[index].perItemPrice = price.toString();
//     if (saveLaterList[index].productList![0].availability != "0") {
//       saveLaterList[index].perItemTotal =
//           (price * double.parse(saveLaterList[index].qty!)).toString();
//     }
//     return Padding(
//         padding: const EdgeInsets.symmetric(vertical: 10.0),
//         child: Stack(
//           clipBehavior: Clip.none,
//           children: [
//             Card(
//               elevation: 0.1,
//               child: Row(
//                 children: <Widget>[
//                   Hero(
//                       tag: "$index${saveLaterList[index].productList![0].id}",
//                       child: Stack(
//                         children: [
//                           ClipRRect(
//                               borderRadius: BorderRadius.circular(7.0),
//                               child: Stack(children: [
//                                 FadeInImage(
//                                   image: CachedNetworkImageProvider(
//                                       saveLaterList[index]
//                                           .productList![0]
//                                           .image!),
//                                   height: 100.0,
//                                   width: 100.0,
//                                   fit: BoxFit.cover,
//                                   imageErrorBuilder:
//                                       (context, error, stackTrace) =>
//                                       erroWidget(100),
//                                   placeholder: placeHolder(100),
//                                 ),
//                                 Positioned.fill(
//                                     child: saveLaterList[index]
//                                         .productList![0]
//                                         .availability ==
//                                         "0"
//                                         ? Container(
//                                       height: 55,
//                                       color: Colors.white70,
//                                       // width: double.maxFinite,
//                                       padding: EdgeInsets.all(2),
//                                       child: Center(
//                                         child: Text(
//                                           getTranslated(context,
//                                               'OUT_OF_STOCK_LBL')!,
//                                           style: Theme.of(context)
//                                               .textTheme
//                                               .caption!
//                                               .copyWith(
//                                             color: Colors.red,
//                                             fontWeight:
//                                             FontWeight.bold,
//                                           ),
//                                           textAlign: TextAlign.center,
//                                         ),
//                                       ),
//                                     )
//                                         : Container()),
//                               ])),
//                           (off != 0 || off != 0.0 || off != 0.00) &&
//                               saveLaterList[index]
//                                   .productList![0]
//                                   .prVarientList![selectedPos]
//                                   .disPrice! !=
//                                   "0"
//                               ? Container(
//                             decoration: BoxDecoration(
//                                 color: colors.red,
//                                 borderRadius: BorderRadius.circular(10)),
//                             child: Padding(
//                               padding: const EdgeInsets.all(5.0),
//                               child: Text(
//                                 off.toStringAsFixed(2) + "%",
//                                 style: TextStyle(
//                                     color: Theme.of(context)
//                                         .colorScheme
//                                         .white,
//                                     fontWeight: FontWeight.bold,
//                                     fontSize: 9),
//                               ),
//                             ),
//                             margin: EdgeInsets.all(5),
//                           )
//                               : Container()
//                         ],
//                       )),
//                   Expanded(
//                     child: Padding(
//                       padding: const EdgeInsetsDirectional.only(start: 8.0),
//                       child: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: <Widget>[
//                           Row(
//                             crossAxisAlignment: CrossAxisAlignment.start,
//                             children: [
//                               Padding(
//                                 padding: const EdgeInsetsDirectional.only(
//                                     top: 5.0),
//                                 child: Text(
//                                   saveLaterList[index].productList![0].name!,
//                                   style: Theme.of(context)
//                                       .textTheme
//                                       .subtitle1!
//                                       .copyWith(
//                                       color: Theme.of(context)
//                                           .colorScheme
//                                           .fontColor),
//                                   maxLines: 2,
//                                   overflow: TextOverflow.ellipsis,
//                                 ),
//                               ),
//                               GestureDetector(
//                                 child: Padding(
//                                   padding: const EdgeInsetsDirectional.only(
//                                       start: 8.0, end: 8, bottom: 8),
//                                   child: Icon(
//                                     Icons.close,
//                                     size: 20,
//                                     color:
//                                     Theme.of(context).colorScheme.fontColor,
//                                   ),
//                                 ),
//                                 onTap: () {
//                                   if (context.read<CartProvider>().isProgress ==
//                                       false)
//                                     removeFromCart(index, true, saveLaterList,
//                                         true, selectedPos);
//                                 },
//                               )
//                             ],
//                           ),
//                           Row(
//                             children: <Widget>[
//                               Text(
//                                 double.parse(saveLaterList[index]
//                                     .productList![0]
//                                     .prVarientList![selectedPos]
//                                     .disPrice!) !=
//                                     0
//                                     ? CUR_CURRENCY! +
//                                     "" +
//                                     saveLaterList[index]
//                                         .productList![0]
//                                         .prVarientList![selectedPos]
//                                         .price!
//                                     : "",
//                                 style: Theme.of(context)
//                                     .textTheme
//                                     .overline!
//                                     .copyWith(
//                                     decoration: TextDecoration.lineThrough,
//                                     letterSpacing: 0.7),
//                               ),
//                               Text(
//                                 " " + CUR_CURRENCY! + " " + price.toString(),
//                                 style: TextStyle(
//                                     color:
//                                     Theme.of(context).colorScheme.fontColor,
//                                     fontWeight: FontWeight.bold),
//                               ),
//                             ],
//                           ),
//                         ],
//                       ),
//                     ),
//                   )
//                 ],
//               ),
//             ),
//             saveLaterList[index].productList![0].availability == "1" ||
//                 saveLaterList[index].productList![0].stockType == "null"
//                 ? Positioned(
//                 bottom: -15,
//                 right: 0,
//                 child: Card(
//                   elevation: 1,
//                   shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(50),
//                   ),
//                   child: InkWell(
//                     child: Padding(
//                       padding: const EdgeInsets.all(8.0),
//                       child: Icon(
//                         Icons.shopping_cart,
//                         size: 20,
//                       ),
//                     ),
//                     onTap:
//                     !addCart && !context.read<CartProvider>().isProgress
//                         ? () {
//                       setState(() {
//                         addCart = true;
//                       });
//                       saveForLater(
//                           saveLaterList[index].varientId,
//                           "0",
//                           saveLaterList[index].qty,
//                           double.parse(
//                               saveLaterList[index].perItemTotal!),
//                           saveLaterList[index],
//                           true);
//                     }
//                         : null,
//                   ),
//                 ))
//                 : Container()
//           ],
//         ));
//   }
//   var dCharge;
//   String? overallAmount;
//   Future<void> _getCart(String save) async {
//     _isNetworkAvail = await isNetworkAvailable();
//
//     if (_isNetworkAvail) {
//       try {
//         var parameter = {
//           USER_ID: CUR_USERID,
//           SAVE_LATER: save,
//         };
//         print("parameters here "+ parameter.toString());
//         print("sfsf ${getCartApi}");
//         Response response =
//         await post(getCartApi, body: parameter, headers: headers)
//             .timeout(Duration(seconds: timeOut));
//         print(getCartApi.toString());
//         print(parameter.toString());
//
//         var getdata = json.decode(response.body);
//         bool error = getdata["error"];
//         String? msg = getdata["message"];
//         if (!error) {
//           var data = getdata["data"];
//           setState(() {
//             print("Cart nEW================> : $totalamount");
//             totalamount = getdata['overall_amount'];
//             productImage = data[0]['user_images'];
//             print("Image------------${productImage}");
//             print("Cart aMOUBT================> : $totalamount");
//             //sellerId = data[0]["product_details"][0]["seller_id"];
//           });
//           // isOnOff = onOff;
//           // var  onOff = await checkOnOff(sellerId);
//           // setState(() {
//           //   isOnOff = onOff;
//           // });
//           //print("is On off===========> : $onOff");
//           // print("Seller Id-----------> $seller_id");
//           print("Cart Data================> : $data");
//           print("ssssssssssssssssssssssss$getdata['delivery_charge']");
//           oriPrice = double.parse(getdata[SUB_TOTAL]);
//           // delCharge =getdata['delivery_charge'].toString();
//
//           double.parse(getdata['delivery_charge'].toString());
//           //  dCharge = double.parse(getdata['delivery_charge'].toString());
//
//           print(" charge here ${delCharge}");
//           taxPer = double.parse(getdata[TAX_PER]);
//
//           totalPrice = delCharge + oriPrice;
//           List<SectionModel> cartList = (data as List)
//               .map((data) => new SectionModel.fromCart(data))
//               .toList();
//           context.read<CartProvider>().setCartlist(cartList);
//           // overallAmount = cartList[0].finalTotal;
//           print("qqqqqqqqqqqqqqqqqqq---${cartList[0].addOns!.length}");
//           if (getdata.containsKey(PROMO_CODES)) {
//             var promo = getdata[PROMO_CODES];
//             promoList =
//                 (promo as List).map((e) => new Promo.fromJson(e)).toList();
//           }
//
//           for (int i = 0; i < cartList.length; i++)
//             _controller.add(new TextEditingController());
//         } else {
//           if (msg != 'Cart Is Empty !') setSnackbar(msg!, _scaffoldKey);
//         }
//         if (mounted)
//           setState(() {
//             _isCartLoad = false;
//           });
//         _getAddress();
//       } on TimeoutException catch (_) {
//         setSnackbar(getTranslated(context, 'somethingMSg')!, _scaffoldKey);
//       }
//     } else {
//       if (mounted)
//         setState(() {
//           _isNetworkAvail = false;
//         });
//     }
//   }
//
//   promoSheet() {
//     showModalBottomSheet<dynamic>(
//         context: context,
//         isScrollControlled: true,
//         shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.only(
//                 topLeft: Radius.circular(25), topRight: Radius.circular(25))),
//         builder: (builder) {
//           return StatefulBuilder(
//               builder: (BuildContext context, StateSetter setState) {
//                 return Padding(
//                   padding: MediaQuery.of(context).viewInsets,
//                   child: Container(
//                       padding: EdgeInsets.only(left: 10, right: 10, top: 50),
//                       constraints: BoxConstraints(
//                           maxHeight: MediaQuery.of(context).size.height * 0.9),
//                       child: ListView(shrinkWrap: true, children: <Widget>[
//                         Stack(
//                           alignment: Alignment.centerRight,
//                           children: [
//                             Container(
//                                 margin: const EdgeInsetsDirectional.only(end: 20),
//                                 decoration: BoxDecoration(
//                                     color: Theme.of(context).colorScheme.white,
//                                     borderRadius:
//                                     BorderRadiusDirectional.circular(10)),
//                                 child: TextField(
//                                   controller: promoC,
//                                   style: Theme.of(context).textTheme.subtitle2,
//                                   decoration: InputDecoration(
//                                     contentPadding:
//                                     EdgeInsets.symmetric(horizontal: 10),
//                                     border: InputBorder.none,
//                                     //isDense: true,
//                                     hintText:
//                                     getTranslated(context, 'PROMOCODE_LBL'),
//                                   ),
//                                 )),
//                             Positioned.directional(
//                               textDirection: Directionality.of(context),
//                               end: 0,
//                               child: Row(
//                                 mainAxisSize: MainAxisSize.min,
//                                 children: [
//                                   (promoAmt != 0 && isPromoValid!)
//                                       ? Padding(
//                                     padding: const EdgeInsets.all(8.0),
//                                     child: InkWell(
//                                       child: Icon(
//                                         Icons.close,
//                                         size: 15,
//                                         color: Theme.of(context)
//                                             .colorScheme
//                                             .fontColor,
//                                       ),
//                                       onTap: () {
//                                         if (promoAmt != 0 && isPromoValid!) {
//                                           if (mounted)
//                                             setState(() {
//                                               totalPrice =
//                                                   totalPrice + promoAmt;
//                                               promoC.text = '';
//                                               isPromoValid = false;
//                                               promoAmt = 0;
//                                               promocode = '';
//                                             });
//                                         }
//                                       },
//                                     ),
//                                   )
//                                       : Container(),
//                                   InkWell(
//                                     child: Container(
//                                         padding: EdgeInsets.all(11),
//                                         decoration: BoxDecoration(
//                                           shape: BoxShape.circle,
//                                           color: colors.primary,
//                                         ),
//                                         child: Icon(
//                                           Icons.arrow_forward,
//                                           color:
//                                           Theme.of(context).colorScheme.white,
//                                         )),
//                                     onTap: () {
//                                       if (promoC.text.trim().isEmpty)
//                                         setSnackbar(
//                                             getTranslated(context, 'ADD_PROMO')!,
//                                             _checkscaffoldKey);
//                                       else if (!isPromoValid!) {
//                                         validatePromo(false);
//                                         Navigator.pop(context);
//                                       }
//                                     },
//                                   ),
//                                 ],
//                               ),
//                             ),
//                           ],
//                         ),
//                         Padding(
//                           padding: const EdgeInsets.symmetric(vertical: 18.0),
//                           child: Text(
//                             getTranslated(context, 'Choose_PROMO') ?? '',
//                             style: Theme.of(context).textTheme.subtitle1!.copyWith(
//                                 color: Theme.of(context).colorScheme.fontColor),
//                           ),
//                         ),
//                         ListView.builder(
//                             physics: NeverScrollableScrollPhysics(),
//                             shrinkWrap: true,
//                             itemCount: promoList.length,
//                             itemBuilder: (context, index) {
//                               return Card(
//                                 elevation: 0,
//                                 child: Row(
//                                   children: [
//                                     Container(
//                                       height: 80,
//                                       width: 80,
//                                       child: ClipRRect(
//                                           borderRadius: BorderRadius.circular(7.0),
//                                           child: Image.network(
//                                             promoList[index].image!,
//                                             height: 80,
//                                             width: 80,
//                                             fit: BoxFit.fill,
//                                             errorBuilder:
//                                                 (context, error, stackTrace) =>
//                                                 erroWidget(
//                                                   80,
//                                                 ),
//                                           )),
//                                     ),
//
//                                     //errorWidget: (context, url, e) => placeHolder(width),
//
//                                     Expanded(
//                                       child: Padding(
//                                         padding: const EdgeInsets.all(8.0),
//                                         child: Column(
//                                           crossAxisAlignment:
//                                           CrossAxisAlignment.start,
//                                           children: [
//                                             Text(promoList[index].msg ?? ""),
//                                             Text(promoList[index].promoCode ?? ''),
//                                           ],
//                                         ),
//                                       ),
//                                     ),
//                                     Text(promoList[index].day ?? ''),
//                                     SimBtn(
//                                       size: 0.3,
//                                       title: getTranslated(context, "APPLY"),
//                                       onBtnSelected: () {
//                                         promoC.text = promoList[index].promoCode!;
//                                         if (!isPromoValid!) validatePromo(false);
//                                         Navigator.of(context).pop();
//                                       },
//                                     ),
//                                   ],
//                                 ),
//                               );
//                             }),
//                       ])),
//                 );
//                 //});
//               });
//         });
//   }
//
//   Future<Null> _getSaveLater(String save) async {
//     _isNetworkAvail = await isNetworkAvailable();
//     if (_isNetworkAvail) {
//       try {
//         var parameter = {USER_ID: CUR_USERID, SAVE_LATER: save,};
//         print(parameter.toString());
//         Response response =
//         await post(getCartApi, body: parameter, headers: headers)
//             .timeout(Duration(seconds: timeOut));
//         print(getCartApi.toString());
//         // print(getCartApi.toString());
//         var getdata = json.decode(response.body);
//         print(getCartApi.toString());
//         bool error = getdata["error"];
//         String? msg = getdata["message"];
//         if (!error) {
//           var data = getdata["data"];
//
//           saveLaterList = (data as List)
//               .map((data) => new SectionModel.fromCart(data))
//               .toList();
//
//           List<SectionModel> cartList = context.read<CartProvider>().cartList;
//           for (int i = 0; i < cartList.length; i++)
//             _controller.add(new TextEditingController());
//         } else {
//           if (msg != 'Cart Is Empty !') setSnackbar(msg!, _scaffoldKey);
//         }
//         if (mounted) setState(() {});
//       } on TimeoutException catch (_) {
//         setSnackbar(getTranslated(context, 'somethingMSg')!, _scaffoldKey);
//       }
//     } else {
//       if (mounted)
//         setState(() {
//           _isNetworkAvail = false;
//         });
//     }
//
//     return null;
//   }
//
//   Future<void> addToCart(
//       int index, String qty, List<SectionModel> cartList) async {
//     _isNetworkAvail = await isNetworkAvailable();
//
//     //if (int.parse(qty) >= cartList[index].productList[0].minOrderQuntity) {
//     if (_isNetworkAvail) {
//       try {
//         context.read<CartProvider>().setProgress(true);
//
//         if (int.parse(qty) < cartList[index].productList![0].minOrderQuntity!) {
//           qty = cartList[index].productList![0].minOrderQuntity.toString();
//
//           setSnackbar(
//               "${getTranslated(context, 'MIN_MSG')}$qty", _checkscaffoldKey);
//         }
//
//         var parameter = {
//           PRODUCT_VARIENT_ID: cartList[index].varientId,
//           USER_ID: CUR_USERID,
//           QTY: qty,
//           "add_on_id": cartList[index].add_on_id!=null?cartList[index].add_on_id:"",
//           "add_on_qty": cartList[index].add_on_qty!=null?cartList[index].add_on_qty:"",
//           "image":"",
//         };
//         Response response =
//         await post(manageCartApi, body: parameter, headers: headers)
//             .timeout(Duration(seconds: timeOut));
//
//         var getdata = json.decode(response.body);
//
//         bool error = getdata["error"];
//         String? msg = getdata["message"];
//         if (!error) {
//           var data = getdata["data"];
//
//           String qty = data['total_quantity'];
//           //CUR_CART_COUNT = data['cart_count'];
//
//           context.read<UserProvider>().setCartCount(data['cart_count']);
//           cartList[index].qty = qty;
//
//           oriPrice = double.parse(data['sub_total']);
//           delCharge = double.parse(getdata['delivery_charge']);
//           print(" charge here New----- ${delCharge}");
//
//           _controller[index].text = qty;
//           totalPrice = 0;
//
//           var cart = getdata["cart"];
//           List<SectionModel> uptcartList = (cart as List)
//               .map((cart) => new SectionModel.fromCart(cart))
//               .toList();
//           context.read<CartProvider>().setCartlist(uptcartList);
//
//           if (!ISFLAT_DEL) {
//             if (addressList.length == 0) {
//               delCharge = 0;
//             } else {
//               if ((oriPrice) <
//                   double.parse(addressList[selectedAddress!].freeAmt!))
//                 delCharge =
//                     double.parse(addressList[selectedAddress!].deliveryCharge!);
//               else
//                 delCharge = 0;
//             }
//           } else {
//             if (oriPrice < double.parse(MIN_AMT!))
//               delCharge = double.parse(CUR_DEL_CHR!);
//             else
//               delCharge = 0;
//           }
//           /*    double addOnPrice = 0;
//           for (int i = 0; i < uptcartList.length; i++){
//             if(uptcartList[i].productList![0].addOnList!.length>0){
//               for(int j=0;j<uptcartList[i].productList![0].addOnList!.length;j++){
//
//                 var model = uptcartList[i].productList![0].addOnList![j];
//                 print("dars"+model.price.toString()+uptcartList[i].add_on_id.toString());
//                 if(uptcartList[i].add_on_id.toString().split(", ").contains(model.id)){
//                   print("dars"+model.price.toString());
//                   addOnPrice += (double.parse(uptcartList[i].qty)*double.parse(model.price!));
//                 }
//               }
//             }
//           }
//           oriPrice+=addOnPrice;*/
//           totalPrice = delCharge + oriPrice;
//
//           if (isPromoValid!) {
//             validatePromo(false);
//           } else if (isUseWallet!) {
//             context.read<CartProvider>().setProgress(false);
//             if (mounted)
//               setState(() {
//                 remWalBal = 0;
//                 payMethod = null;
//                 usedBal = 0;
//                 isUseWallet = false;
//                 isPayLayShow = true;
//
//                 selectedMethod = null;
//               });
//           } else {
//             setState(() {});
//             context.read<CartProvider>().setProgress(false);
//           }
//         } else {
//           setSnackbar(msg!, _scaffoldKey);
//           context.read<CartProvider>().setProgress(false);
//         }
//       } on TimeoutException catch (_) {
//         setSnackbar(getTranslated(context, 'somethingMSg')!, _scaffoldKey);
//         context.read<CartProvider>().setProgress(false);
//       }
//     } else {
//       if (mounted)
//         setState(() {
//           _isNetworkAvail = false;
//         });
//     }
//     // } else
//     // setSnackbar(
//     //     "Minimum allowed quantity is ${cartList[index].productList[0].minOrderQuntity} ",
//     //     _scaffoldKey);
//   }
//
//   Future<void> addToCartCheckout(
//       int index, String qty, List<SectionModel> cartList) async {
//     _isNetworkAvail = await isNetworkAvailable();
//     if (_isNetworkAvail) {
//       try {
//         context.read<CartProvider>().setProgress(true);
//
//         if (int.parse(qty) < cartList[index].productList![0].minOrderQuntity!) {
//           qty = cartList[index].productList![0].minOrderQuntity.toString();
//
//           setSnackbar(
//               "${getTranslated(context, 'MIN_MSG')}$qty", _checkscaffoldKey);
//         }
//
//         var parameter = {
//           PRODUCT_VARIENT_ID: cartList[index].varientId,
//           USER_ID: CUR_USERID,
//           QTY: qty,
//           "image":"",
//         };
//
//         Response response =
//         await post(manageCartApi, body: parameter, headers: headers)
//             .timeout(Duration(seconds: timeOut));
//         print(manageCartApi.toString());
//         if (response.statusCode == 200) {
//           var getdata = json.decode(response.body);
//
//           bool error = getdata["error"];
//           String? msg = getdata["message"];
//           if (!error) {
//             var data = getdata["data"];
//
//             String qty = data['total_quantity'];
//             // CUR_CART_COUNT = data['cart_count'];
//
//             context.read<UserProvider>().setCartCount(data['cart_count']);
//             cartList[index].qty = qty;
//
//             oriPrice = double.parse(data['sub_total']);
//             _controller[index].text = qty;
//             totalPrice = 0;
//
//             if (!ISFLAT_DEL) {
//               if ((oriPrice) <
//                   double.parse(addressList[selectedAddress!].freeAmt!))
//                 delCharge =
//                     double.parse(addressList[selectedAddress!].deliveryCharge!);
//               else
//                 delCharge = 0;
//             } else {
//               if ((oriPrice) < double.parse(MIN_AMT!))
//                 delCharge = double.parse(CUR_DEL_CHR!);
//               else
//                 delCharge = 0;
//             }
//             totalPrice = delCharge + oriPrice;
//
//             if (isPromoValid!) {
//               validatePromo(true);
//             } else if (isUseWallet!) {
//               if (mounted)
//                 checkoutState!(() {
//                   remWalBal = 0;
//                   payMethod = null;
//                   usedBal = 0;
//                   isUseWallet = false;
//                   isPayLayShow = true;
//
//                   selectedMethod = null;
//                 });
//               setState(() {});
//             } else {
//               context.read<CartProvider>().setProgress(false);
//               setState(() {});
//               checkoutState!(() {});
//             }
//           } else {
//             setSnackbar(msg!, _checkscaffoldKey);
//             context.read<CartProvider>().setProgress(false);
//           }
//         }
//       } on TimeoutException catch (_) {
//         setSnackbar(getTranslated(context, 'somethingMSg')!, _checkscaffoldKey);
//         context.read<CartProvider>().setProgress(false);
//       }
//     } else {
//       if (mounted)
//         checkoutState!(() {
//           _isNetworkAvail = false;
//         });
//       setState(() {});
//     }
//   }
//
//   saveForLater(String? id, String save, String? qty, double price,
//       SectionModel curItem, bool fromSave) async {
//     _isNetworkAvail = await isNetworkAvailable();
//     if (_isNetworkAvail) {
//       try {
//         context.read<CartProvider>().setProgress(true);
//
//         var parameter = {
//           PRODUCT_VARIENT_ID: id,
//           USER_ID: CUR_USERID,
//           QTY: qty,
//           SAVE_LATER: save
//         };
//
//         print("param****save***********$parameter");
//
//         Response response =
//         await post(manageCartApi, body: parameter, headers: headers)
//             .timeout(Duration(seconds: timeOut));
//
//         var getdata = json.decode(response.body);
//
//         bool error = getdata["error"];
//         String? msg = getdata["message"];
//         if (!error) {
//           var data = getdata["data"];
//           // CUR_CART_COUNT = data['cart_count'];
//           context.read<UserProvider>().setCartCount(data['cart_count']);
//           if (save == "1") {
//             setSnackbar("Saved For Later", _scaffoldKey);
//             saveLaterList.add(curItem);
//             //cartList.removeWhere((item) => item.varientId == id);
//             context.read<CartProvider>().removeCartItem(id!);
//             setState(() {
//               saveLater = false;
//             });
//             oriPrice = oriPrice - price;
//           } else {
//             setSnackbar("Added To Cart", _scaffoldKey);
//             // cartList.add(curItem);
//             context.read<CartProvider>().addCartItem(curItem);
//             saveLaterList.removeWhere((item) => item.varientId == id);
//             setState(() {
//               addCart = false;
//             });
//             oriPrice = oriPrice + price;
//           }
//
//           totalPrice = 0;
//
//           // if (!ISFLAT_DEL) {
//           //   if (addressList.length > 0 &&
//           //       (oriPrice) <
//           //           double.parse(addressList[selectedAddress!].freeAmt!
//           //           )
//           //   ) {
//           //     delCharge =
//           //         double.parse(addressList[selectedAddress!].deliveryCharge!);
//           //   } else {
//           //     delCharge = 0;
//           //   }
//           // } else {
//           //   if ((oriPrice) < double.parse(MIN_AMT!)) {
//           //     delCharge = double.parse(CUR_DEL_CHR!);
//           //   } else {
//           //     delCharge = 0;
//           //   }
//           // }
//           totalPrice = delCharge + oriPrice;
//
//           if (isPromoValid!) {
//             validatePromo(false);
//           } else if (isUseWallet!) {
//             context.read<CartProvider>().setProgress(false);
//             if (mounted)
//               setState(() {
//                 remWalBal = 0;
//                 payMethod = null;
//                 usedBal = 0;
//                 isUseWallet = false;
//                 isPayLayShow = true;
//               });
//           } else {
//             context.read<CartProvider>().setProgress(false);
//             setState(() {});
//           }
//         } else {
//           setSnackbar(msg!, _scaffoldKey);
//         }
//
//         context.read<CartProvider>().setProgress(false);
//       } on TimeoutException catch (_) {
//         setSnackbar(getTranslated(context, 'somethingMSg')!, _scaffoldKey);
//         context.read<CartProvider>().setProgress(false);
//       }
//     } else {
//       if (mounted)
//         setState(() {
//           _isNetworkAvail = false;
//         });
//     }
//   }
//
//   removeFromCartCheckout(
//       int index, bool remove, List<SectionModel> cartList) async {
//     _isNetworkAvail = await isNetworkAvailable();
//
//     if (!remove &&
//         int.parse(cartList[index].qty!) ==
//             cartList[index].productList![0].minOrderQuntity) {
//       setSnackbar("${getTranslated(context, 'MIN_MSG')}${cartList[index].qty}",
//           _checkscaffoldKey);
//     } else {
//       if (_isNetworkAvail) {
//         try {
//           context.read<CartProvider>().setProgress(true);
//
//           int? qty;
//           if (remove)
//             qty = 0;
//           else {
//             qty = (int.parse(cartList[index].qty!) -
//                 int.parse(cartList[index].productList![0].qtyStepSize!));
//
//             if (qty < cartList[index].productList![0].minOrderQuntity!) {
//               qty = cartList[index].productList![0].minOrderQuntity;
//
//               setSnackbar("${getTranslated(context, 'MIN_MSG')}$qty",
//                   _checkscaffoldKey);
//             }
//           }
//
//           var parameter = {
//             PRODUCT_VARIENT_ID: cartList[index].varientId,
//             USER_ID: CUR_USERID,
//             QTY: qty.toString(),
//             "image":"",
//             "add_on_id": cartList[index].add_on_id!=null?cartList[index].add_on_id:"",
//             "add_on_qty": cartList[index].add_on_qty!=null?cartList[index].add_on_qty:"",
//           };
//
//           Response response =
//           await post(manageCartApi, body: parameter, headers: headers)
//               .timeout(Duration(seconds: timeOut));
//
//           if (response.statusCode == 200) {
//             var getdata = json.decode(response.body);
//
//             bool error = getdata["error"];
//             String? msg = getdata["message"];
//             if (!error) {
//               var data = getdata["data"];
//
//               String? qty = data['total_quantity'];
//               // CUR_CART_COUNT = data['cart_count'];
//
//               context.read<UserProvider>().setCartCount(data['cart_count']);
//               if (qty == "0") remove = true;
//
//               if (remove) {
//                 // cartList.removeWhere((item) => item.varientId == cartList[index].varientId);
//
//                 context
//                     .read<CartProvider>()
//                     .removeCartItem(cartList[index].varientId!);
//               } else {
//                 cartList[index].qty = qty.toString();
//               }
//
//               oriPrice = double.parse(data[SUB_TOTAL]);
//
//               if (!ISFLAT_DEL) {
//                 if ((oriPrice) <
//                     double.parse(addressList[selectedAddress!].freeAmt!))
//                   delCharge = double.parse(
//                       addressList[selectedAddress!].deliveryCharge!);
//                 else
//                   delCharge = 0;
//               } else {
//                 if ((oriPrice) < double.parse(MIN_AMT!))
//                   delCharge = double.parse(CUR_DEL_CHR!);
//                 else
//                   delCharge = 0;
//               }
//
//               totalPrice = 0;
//
//               totalPrice = delCharge + oriPrice;
//
//               if (isPromoValid!) {
//                 validatePromo(true);
//               } else if (isUseWallet!) {
//                 if (mounted)
//                   checkoutState!(() {
//                     remWalBal = 0;
//                     payMethod = null;
//                     usedBal = 0;
//                     isPayLayShow = true;
//                     isUseWallet = false;
//                   });
//                 context.read<CartProvider>().setProgress(false);
//                 setState(() {});
//               } else {
//                 context.read<CartProvider>().setProgress(false);
//
//                 checkoutState!(() {});
//                 setState(() {});
//               }
//             } else {
//               setSnackbar(msg!, _checkscaffoldKey);
//               context.read<CartProvider>().setProgress(false);
//             }
//           }
//         } on TimeoutException catch (_) {
//           setSnackbar(
//               getTranslated(context, 'somethingMSg')!, _checkscaffoldKey);
//           context.read<CartProvider>().setProgress(false);
//         }
//       } else {
//         if (mounted)
//           checkoutState!(() {
//             _isNetworkAvail = false;
//           });
//         setState(() {});
//       }
//     }
//   }
//
//   removeFromCart(int index, bool remove, List<SectionModel> cartList, bool move,
//       int selPos) async {
//     _isNetworkAvail = await isNetworkAvailable();
//     if (!remove &&
//         int.parse(cartList[index].qty!) ==
//             cartList[index].productList![0].minOrderQuntity) {
//       setSnackbar("${getTranslated(context, 'MIN_MSG')}${cartList[index].qty}",
//           _scaffoldKey);
//     } else {
//       if (_isNetworkAvail) {
//         try {
//           context.read<CartProvider>().setProgress(true);
//
//           int? qty;
//           if (remove)
//             qty = 0;
//           else {
//             qty = (int.parse(cartList[index].qty!) -
//                 int.parse(cartList[index].productList![0].qtyStepSize!));
//
//             if (qty < cartList[index].productList![0].minOrderQuntity!) {
//               qty = cartList[index].productList![0].minOrderQuntity;
//
//               setSnackbar("${getTranslated(context, 'MIN_MSG')}$qty",
//                   _checkscaffoldKey);
//             }
//           }
//           String varId;
//           if (cartList[index].productList![0].availability == "0") {
//             varId = cartList[index].productList![0].prVarientList![selPos].id!;
//           } else {
//             varId = cartList[index].varientId!;
//           }
//           print("carient**********${cartList[index].varientId}");
//           var parameter = {
//             PRODUCT_VARIENT_ID: varId,
//             USER_ID: CUR_USERID,
//             QTY: qty.toString(),
//             "image":"",
//             "add_on_id": cartList[index].add_on_id!=null?cartList[index].add_on_id:"",
//             "add_on_qty": cartList[index].add_on_qty!=null?cartList[index].add_on_qty:"",
//             "image":"",
//           };
//
//           Response response =
//           await post(manageCartApi, body: parameter, headers: headers)
//               .timeout(Duration(seconds: timeOut));
//
//           var getdata = json.decode(response.body);
//           print(getdata);
//
//           bool error = getdata["error"];
//           String? msg = getdata["message"];
//           if (!error) {
//             print("msg************$msg");
//             var data = getdata["data"];
//             setSnackbar("Deleted", _scaffoldKey);
//             String? qty = data['total_quantity'];
//             // CUR_CART_COUNT = data['cart_count'];
//             _getCart("0");
//
//             context.read<UserProvider>().setCartCount(data['cart_count']);
//             if (move == false) {
//               if (qty == "0") remove = true;
//
//               if (remove) {
//                 cartList.removeWhere(
//                         (item) => item.varientId == cartList[index].varientId);
//               } else {
//                 cartList[index].qty = qty.toString();
//               }
//
//               oriPrice = double.parse(data[SUB_TOTAL]);
//               if (!ISFLAT_DEL) {
//                 try {
//                   if ((oriPrice) <
//                       double.parse(addressList[selectedAddress!].freeAmt!))
//                     delCharge = double.parse(
//                         addressList[selectedAddress!].deliveryCharge!);
//                   else
//                     delCharge = 0;
//                 } catch (e) {
//                   print(e);
//                 }
//               } else {
//                 if ((oriPrice) < double.parse(MIN_AMT!))
//                   delCharge = double.parse(CUR_DEL_CHR!);
//                 else
//                   delCharge = 0;
//               }
//
//
//               totalPrice = 0;
//
//               totalPrice = delCharge + oriPrice;
//               if (isPromoValid!) {
//                 validatePromo(false);
//               } else if (isUseWallet!) {
//                 context.read<CartProvider>().setProgress(false);
//                 if (mounted)
//                   setState(() {
//                     remWalBal = 0;
//                     payMethod = null;
//                     usedBal = 0;
//                     isPayLayShow = true;
//                     isUseWallet = false;
//                   });
//               } else {
//                 context.read<CartProvider>().setProgress(false);
//                 setState(() {});
//               }
//             } else {
//               if (qty == "0") remove = true;
//
//               if (remove) {
//                 cartList.removeWhere(
//                         (item) => item.varientId == cartList[index].varientId);
//               }
//             }
//           } else {
//             print("msg111************$msg");
//             setSnackbar(msg!, _scaffoldKey);
//           }
//           if (mounted) setState(() {});
//           context.read<CartProvider>().setProgress(false);
//         } on TimeoutException catch (_) {
//           setSnackbar(getTranslated(context, 'somethingMSg')!, _scaffoldKey);
//           context.read<CartProvider>().setProgress(false);
//         }
//       } else {
//         if (mounted)
//           setState(() {
//             _isNetworkAvail = false;
//           });
//       }
//     }
//   }
//
//   setSnackbar(
//       String msg, GlobalKey<ScaffoldMessengerState> _scaffoldMessengerKey) {
//     ScaffoldMessenger.of(context).showSnackBar(new SnackBar(
//       duration: Duration(seconds: 1),
//       content: new Text(
//         msg,
//         textAlign: TextAlign.center,
//         style: TextStyle(color: Theme.of(context).colorScheme.black),
//       ),
//       backgroundColor: Theme.of(context).colorScheme.white,
//       elevation: 1.0,
//     ));
//   }
//
//   _showContent(BuildContext context) {
//     List<SectionModel> cartList = context.read<CartProvider>().cartList;
//     print("cart list************${cartList.length}");
//     return _isCartLoad
//         ? shimmer(context)
//         : cartList.length == 0 && saveLaterList.length == 0
//         ? cartEmpty()
//         : Column(
//       children: <Widget>[
//         Expanded(
//           child: Padding(
//               padding: const EdgeInsets.symmetric(horizontal: 10.0),
//               child: RefreshIndicator(
//                   color: colors.primary,
//                   key: _refreshIndicatorKey,
//                   onRefresh: _refresh,
//                   child: SingleChildScrollView(
//                     physics: const AlwaysScrollableScrollPhysics(),
//                     child: Column(
//                       mainAxisSize: MainAxisSize.max,
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         ListView.builder(
//                           shrinkWrap: true,
//                           itemCount: cartList.length,
//                           physics: NeverScrollableScrollPhysics(),
//                           itemBuilder: (context, index) {
//                             return listItem(index, cartList);
//                           },
//                         ),
//                         saveLaterList.length > 0
//                             ? Padding(
//                           padding: const EdgeInsets.all(8.0),
//                           child: Text(
//                             getTranslated(
//                                 context, 'SAVEFORLATER_BTN')!,
//                             style: Theme.of(context)
//                                 .textTheme
//                                 .subtitle1!
//                                 .copyWith(
//                                 color: Theme.of(context)
//                                     .colorScheme
//                                     .fontColor),
//                           ),
//                         )
//                             : Container(),
//                         ListView.builder(
//                           shrinkWrap: true,
//                           itemCount: saveLaterList.length,
//                           physics: NeverScrollableScrollPhysics(),
//                           itemBuilder: (context, index) {
//                             return saveLaterItem(index);
//                           },
//                         ),
//                       ],
//                     ),
//                   ))),
//         ),
//         Container(
//           child: Column(mainAxisSize: MainAxisSize.min, children: <
//               Widget>[
//             promoList.length > 0 && oriPrice > 0
//                 ? Padding(
//               padding:
//               const EdgeInsets.symmetric(horizontal: 10.0),
//               child: InkWell(
//                 child: Stack(
//                   alignment: Alignment.centerRight,
//                   children: [
//                     Container(
//                         margin:
//                         const EdgeInsetsDirectional.only(
//                             end: 20),
//                         decoration: BoxDecoration(
//                             color: Theme.of(context)
//                                 .colorScheme
//                                 .white,
//                             borderRadius:
//                             BorderRadiusDirectional
//                                 .circular(10)),
//                         child: TextField(
//                           textDirection:
//                           Directionality.of(context),
//                           enabled: false,
//                           controller: promoC,
//                           readOnly: true,
//                           style: Theme.of(context)
//                               .textTheme
//                               .subtitle2,
//                           decoration: InputDecoration(
//                             contentPadding:
//                             EdgeInsets.symmetric(
//                                 horizontal: 10),
//                             border: InputBorder.none,
//                             //isDense: true,
//                             hintText: getTranslated(
//                                 context, 'PROMOCODE_LBL') ??
//                                 '',
//                           ),
//                         )),
//                     Positioned.directional(
//                       textDirection: Directionality.of(context),
//                       end: 0,
//                       child: Container(
//                           padding: EdgeInsets.all(11),
//                           decoration: BoxDecoration(
//                             shape: BoxShape.circle,
//                             color: Theme.of(context).colorScheme.lightBlack,
//                           ),
//                           child: Icon(
//                             Icons.arrow_forward,
//                             color: Theme.of(context)
//                                 .colorScheme
//                                 .white,
//                           )),
//                     ),
//                   ],
//                 ),
//                 onTap: promoSheet,
//               ),
//             )
//                 : Container(),
//             Container(
//                 decoration: BoxDecoration(
//                   color: Theme.of(context).colorScheme.white,
//                   borderRadius: BorderRadius.all(
//                     Radius.circular(10),
//                   ),
//                 ),
//                 margin:
//                 EdgeInsets.symmetric(horizontal: 10, vertical: 8),
//                 padding:
//                 EdgeInsets.symmetric(vertical: 10, horizontal: 5),
//                 //  width: deviceWidth! * 0.9,
//                 child: Column(
//                   children: [
//                     Row(
//                       mainAxisAlignment:
//                       MainAxisAlignment.spaceBetween,
//                       children: [
//                         Text(getTranslated(context, 'TOTAL_PRICE')!),
//                         Text(
//                           CUR_CURRENCY! +
//                               " ${oriPrice.toStringAsFixed(2)}",
//                           style: Theme.of(context)
//                               .textTheme
//                               .subtitle1!
//                               .copyWith(
//                               color: Theme.of(context)
//                                   .colorScheme
//                                   .fontColor),
//                         ),
//                       ],
//                     ),
//                     isPromoValid!
//                         ? Row(
//                       mainAxisAlignment:
//                       MainAxisAlignment.spaceBetween,
//                       children: [
//                         Text(
//                           getTranslated(
//                               context, 'PROMO_CODE_DIS_LBL')!,
//                           style: Theme.of(context)
//                               .textTheme
//                               .caption!
//                               .copyWith(
//                               color: Theme.of(context)
//                                   .colorScheme
//                                   .lightBlack2),
//                         ),
//                         Text(
//                           CUR_CURRENCY! +
//                               " " +
//                               promoAmt.toString(),
//                           style: Theme.of(context)
//                               .textTheme
//                               .caption!
//                               .copyWith(
//                               color: Theme.of(context)
//                                   .colorScheme
//                                   .lightBlack2),
//                         )
//                       ],
//                     )
//                         : Container(),
//                   ],
//                 )),
//             SimBtn(
//                 size: 0.9,
//                 title: getTranslated(context, 'PROCEED_CHECKOUT'),
//                 onBtnSelected: () async {
//                   checkout(cartList);
//                   // if(isOnOff == true){
//                   //   if (oriPrice > 0) {
//                   //     FocusScope.of(context).unfocus();
//                   //     if (isAvailable) {
//                   //       checkout(cartList);
//                   //     } else {
//                   //       setSnackbar(
//                   //           getTranslated(
//                   //               context, 'CART_OUT_OF_STOCK_MSG')!,
//                   //           _scaffoldKey);
//                   //     }
//                   //     if (mounted) setState(() {});
//                   //   } else
//                   //     setSnackbar(getTranslated(context, 'ADD_ITEM')!,
//                   //         _scaffoldKey);
//                   // } else {
//                   //   showToast("Currently Store is Off");
//                   // }
//
//                 }),
//           ]),
//         ),
//       ],
//     );
//   }
//
//   cartEmpty() {
//     return Center(
//       child: SingleChildScrollView(
//         child: Column(mainAxisSize: MainAxisSize.min, children: [
//           noCartImage(context),
//           noCartText(context),
//           noCartDec(context),
//           shopNow()
//         ]),
//       ),
//     );
//   }
//
//   getAllPromo() {}
//
//   noCartImage(BuildContext context) {
//     return SvgPicture.asset(
//       'assets/images/empty_cart.svg',
//       fit: BoxFit.contain,
//       color: colors.primary,
//     );
//   }
//
//   noCartText(BuildContext context) {
//     return Container(
//         child: Text(getTranslated(context, 'NO_CART')!,
//             style: Theme.of(context).textTheme.headline5!.copyWith(
//                 color: colors.primary, fontWeight: FontWeight.normal)));
//   }
//
//   noCartDec(BuildContext context) {
//     return Container(
//       padding: EdgeInsetsDirectional.only(top: 30.0, start: 30.0, end: 30.0),
//       child: Text(getTranslated(context, 'CART_DESC')!,
//           textAlign: TextAlign.center,
//           style: Theme.of(context).textTheme.headline6!.copyWith(
//             color: Theme.of(context).colorScheme.lightBlack2,
//             fontWeight: FontWeight.normal,
//           )),
//     );
//   }
//
//   shopNow() {
//     return Padding(
//       padding: const EdgeInsetsDirectional.only(top: 28.0),
//       child: CupertinoButton(
//         child: Container(
//             width: deviceWidth! * 0.7,
//             height: 45,
//             alignment: FractionalOffset.center,
//             decoration: new BoxDecoration(
//               color: colors.primary,
//               // gradient: LinearGradient(
//               //     begin: Alignment.topLeft,
//               //     end: Alignment.bottomRight,
//               //     colors: [colors.grad1Color, colors.grad2Color],
//               //     stops: [0, 1]),
//               borderRadius: new BorderRadius.all(const Radius.circular(50.0)),
//             ),
//             child: Text(getTranslated(context, 'SHOP_NOW')!,
//                 textAlign: TextAlign.center,
//                 style: Theme.of(context).textTheme.headline6!.copyWith(
//                     color: Colors.white70))),
//         onPressed: () {
//           Navigator.of(context).pushNamedAndRemoveUntil(
//               '/home', (Route<dynamic> route) => false);
//         },
//       ),
//     );
//   }
//
//   checkout(List<SectionModel> cartList) {
//     print("nnnnnnnnnnnnnnnnnnnnn++++++${totalamount.toString()}");
//     _razorpay = Razorpay();
//     _razorpay!.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
//     _razorpay!.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
//     _razorpay!.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
//
//     deviceHeight = MediaQuery.of(context).size.height;
//     deviceWidth = MediaQuery.of(context).size.width;
//     return showModalBottomSheet(
//         context: context,
//         isScrollControlled: true,
//         shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.only(
//                 topLeft: Radius.circular(10), topRight: Radius.circular(10))),
//         builder: (builder) {
//           return StatefulBuilder(
//               builder: (BuildContext context, StateSetter setState) {
//                 checkoutState = setState;
//                 return Container(
//                     constraints: BoxConstraints(
//                         maxHeight: MediaQuery.of(context).size.height * 0.8),
//                     child: Scaffold(
//                       resizeToAvoidBottomInset: false,
//                       key: _checkscaffoldKey,
//                       body: _isNetworkAvail
//                           ? cartList.length == 0
//                           ? cartEmpty()
//                           : _isLoading
//                           ? shimmer(context)
//                           : Column(
//                         children: [
//                           Expanded(
//                             child: Stack(
//                               children: <Widget>[
//                                 SingleChildScrollView(
//                                   child: Padding(
//                                     padding:
//                                     const EdgeInsets.all(10.0),
//                                     child: Column(
//                                       mainAxisSize: MainAxisSize.min,
//                                       children: [
//                                         address(),
//                                         payment(),
//                                         cartItems(cartList),
//                                         // promo(),
//                                         orderSummary(cartList),
//                                       ],
//                                     ),
//                                   ),
//                                 ),
//                                 Selector<CartProvider, bool>(
//                                   builder: (context, data, child) {
//                                     return showCircularProgress(
//                                         data, colors.primary);
//                                   },
//                                   selector: (_, provider) =>
//                                   provider.isProgress,
//                                 ),
//                                 /*   showCircularProgress(
//                                               _isProgress, colors.primary),*/
//                               ],
//                             ),
//                           ),
//                           Container(
//                             color:
//                             Theme.of(context).colorScheme.white,
//                             child: Row(children: <Widget>[
//                               Padding(
//                                   padding: EdgeInsetsDirectional.only(
//                                       start: 15.0),
//                                   child: Column(
//                                     crossAxisAlignment:
//                                     CrossAxisAlignment.start,
//                                     children: [
//                                       Text(CUR_CURRENCY! +
//                                           "${totalamount.toString()}" != " " ?
//                                       CUR_CURRENCY! +
//                                           "${totalamount.toString()}":"",
//                                         // CUR_CURRENCY! +
//                                         //     " ${oriPrice.toStringAsFixed(2)}",
//                                         style: TextStyle(
//                                             color: Theme.of(context)
//                                                 .colorScheme
//                                                 .fontColor,
//                                             fontWeight:
//                                             FontWeight.bold),
//                                       ),
//
//                                       Text(
//                                           cartList.length.toString() +
//                                               " Items"),
//                                     ],
//                                   )),
//                               Spacer(),
//
//                               SimBtn(
//                                   size: 0.4,
//                                   title: getTranslated(
//                                       context, 'PLACE_ORDER'),
//                                   onBtnSelected: _placeOrder
//                                       ? () async {
//                                     checkoutState!(() {
//                                       _placeOrder = false;
//                                     });
//                                     // if(
//                                     // cartList[0].sellerAvailable == false)
//                                     msg = getTranslated(
//                                         context,
//                                         'Seller');
//                                     if (selAddress == null ||
//                                         selAddress!.isEmpty) {
//                                       msg = getTranslated(
//                                           context,
//                                           'addressWarning');
//                                       Navigator.pushReplacement(
//                                           context,
//                                           MaterialPageRoute(
//                                             builder: (BuildContext
//                                             context) =>
//                                                 ManageAddress(
//                                                   home: false,
//                                                 ),
//                                           ));
//                                       checkoutState!(() {
//                                         _placeOrder = true;
//                                       });
//                                     } else if (payMethod ==
//                                         null ||
//                                         payMethod!.isEmpty) {
//                                       msg = getTranslated(
//                                           context,
//                                           'payWarning');
//                                       final ResultData =  await Navigator.push(
//                                           context,
//                                           MaterialPageRoute(
//                                               builder: (BuildContext
//                                               context) =>
//                                                   Payment(
//                                                       updateCheckout,
//                                                       msg)));
//                                       print("Print---1 ${ResultData}");
//
//                                       if(ResultData != "" )
//                                         var headers = {
//                                           'Cookie': 'ci_session=5be79edf6749aa75949900769b02f16775567670'
//                                         };
//                                       var request = http.MultipartRequest('POST', Uri.parse('$baseUrl/get_delivery_charge'));
//                                       request.fields.addAll({
//                                         'time_slot_id': '${ResultData}'
//                                       });
//                                       request.headers.addAll(headers);
//                                       http.StreamedResponse response = await request.send();
//                                       print("checking delivery charge response here ${response.statusCode}");
//                                       if (response.statusCode == 200) {
//                                         var   FinalResult =   await response.stream.bytesToString();
//                                         final jsonResponse = json.decode(FinalResult);
//                                         print("New-----------${jsonResponse.toString()} and ${jsonResponse['delivery_charge'] }");
//                                         setState((){
//                                           dCharge = jsonResponse['delivery_charge'];
//                                           double ress = double.parse(totalamount.toString()) + double.parse(dCharge.toString());
//                                           print("final amount here ${ress}");
//                                           print("final amount here ${dCharge}");
//
//
//                                           totalamount = ress.toString();
//                                           print("final amount 1 here ${totalamount}");
//                                         });
//                                         print("final delivery charge here ${dCharge}");
//                                       }
//                                       else {
//                                         print(response.reasonPhrase);
//                                       }
//
//                                       checkoutState!(() {
//                                         _placeOrder = true;
//                                       });
//                                     } else if (isTimeSlot! &&
//                                         int.parse(allowDay!) >
//                                             0 &&
//                                         (selDate == null ||
//                                             selDate!.isEmpty)) {
//                                       msg = getTranslated(
//                                           context,
//                                           'dateWarning');
//                                       final ResultData =  await Navigator.push(
//                                           context,
//                                           MaterialPageRoute(
//                                               builder: (BuildContext
//                                               context) =>
//                                                   Payment(
//                                                       updateCheckout,
//                                                       msg)));
//                                       print("Print---1 ${ResultData}");
//
//                                       if(ResultData != "" )
//                                         var headers = {
//                                           'Cookie': 'ci_session=5be79edf6749aa75949900769b02f16775567670'
//                                         };
//                                       var request = http.MultipartRequest('POST', Uri.parse('$baseUrl/get_delivery_charge'));
//                                       request.fields.addAll({
//                                         'time_slot_id': '${ResultData}'
//                                       });
//                                       request.headers.addAll(headers);
//                                       http.StreamedResponse response = await request.send();
//                                       print("checking delivery charge response here ${response.statusCode}");
//                                       if (response.statusCode == 200) {
//                                         var   FinalResult =   await response.stream.bytesToString();
//                                         final jsonResponse = json.decode(FinalResult);
//                                         print("New-----------${jsonResponse.toString()} and ${jsonResponse['delivery_charge'] }");
//                                         setState((){
//                                           dCharge = jsonResponse['delivery_charge'];
//                                           double ress = double.parse(totalamount.toString()) + double.parse(dCharge.toString());
//                                           print("final amount here ${ress}");
//                                           print("final amount here ${dCharge}");
//
//
//                                           totalamount = ress.toString();
//                                           print("final amount 1 here ${totalamount}");
//                                         });
//                                         print("final delivery charge here ${dCharge}");
//                                       }
//                                       else {
//                                         print(response.reasonPhrase);
//                                       }
//
//                                       checkoutState!(() {
//                                         _placeOrder = true;
//                                       });
//                                     } else if (isTimeSlot! &&
//                                         timeSlotList.length >
//                                             0 &&
//                                         (selTime == null ||
//                                             selTime!.isEmpty)) {
//                                       msg = getTranslated(
//                                           context,
//                                           'timeWarning');
//                                       final ResultData =  await Navigator.push(
//                                           context,
//                                           MaterialPageRoute(
//                                               builder: (BuildContext
//                                               context) =>
//                                                   Payment(
//                                                       updateCheckout,
//                                                       msg)));
//                                       print("Print---1 ${ResultData}");
//
//                                       if(ResultData != "" )
//                                         var headers = {
//                                           'Cookie': 'ci_session=5be79edf6749aa75949900769b02f16775567670'
//                                         };
//                                       var request = http.MultipartRequest('POST', Uri.parse('$baseUrl/get_delivery_charge'));
//                                       request.fields.addAll({
//                                         'time_slot_id': '${ResultData}'
//                                       });
//                                       request.headers.addAll(headers);
//                                       http.StreamedResponse response = await request.send();
//                                       print("checking delivery charge response here ${response.statusCode}");
//                                       if (response.statusCode == 200) {
//                                         var   FinalResult =   await response.stream.bytesToString();
//                                         final jsonResponse = json.decode(FinalResult);
//                                         print("New-----------${jsonResponse.toString()} and ${jsonResponse['delivery_charge'] }");
//                                         setState((){
//                                           dCharge = jsonResponse['delivery_charge'];
//                                           double ress = double.parse(totalamount.toString()) + double.parse(dCharge.toString());
//                                           print("final amount here ${ress}");
//                                           print("final amount here ${dCharge}");
//
//
//                                           totalamount = ress.toString();
//                                           print("final amount 1 here ${totalamount}");
//                                         });
//                                         print("final delivery charge here ${dCharge}");
//                                       }
//                                       else {
//                                         print(response.reasonPhrase);
//                                       }
//
//                                       checkoutState!(() {
//                                         _placeOrder = true;
//                                       });
//                                       print("Print---3${ResultData}");
//                                       checkoutState!(() {
//                                         _placeOrder = true;
//                                       });
//                                     } else if (double.parse(
//                                         MIN_ALLOW_CART_AMT!) >
//                                         oriPrice) {
//                                       setSnackbar(
//                                           getTranslated(context,
//                                               'MIN_CART_AMT')!,
//                                           _checkscaffoldKey);
//                                     }
//                                     // else if (!deliverable) {
//                                     //   checkDeliverable();
//                                     // }
//                                     else
//                                       confirmDialog();
//                                   }
//                                       : null)
//                               //}),
//                             ]),
//                           ),
//                         ],
//                       )
//                           : noInternet(context),
//                     ));
//               });
//         });
//   }
//
//   doPayment() {
//     if (payMethod == getTranslated(context, 'PAYPAL_LBL')) {
//       placeOrder('');
//     }
//     else if (payMethod == getTranslated(context, 'RAZORPAY_LBL'))
//       razorpayPayment();
//     else if (payMethod == getTranslated(context, 'FLUTTERWAVE_LBL'))
//       flutterwavePayment();
//     else if (payMethod == getTranslated(context, 'STRIPE_LBL'))
//       stripePayment();
//     else if (payMethod == getTranslated(context, 'PAYTM_LBL'))
//       paytmPayment();
//     /*  else if (payMethod ==
//                                                         getTranslated(
//                                                             context, 'GPAY')) {
//                                                       googlePayment(
//                                                           "google_pay");
//                                                     } else if (payMethod ==
//                                                         getTranslated(context,
//                                                             'APPLEPAY')) {
//                                                       googlePayment(
//                                                           "apple_pay");
//                                                     }*/
//
//     else if (payMethod == getTranslated(context, 'BANKTRAN'))
//       bankTransfer();
//     else
//       placeOrder('');
//   }
//
//   Future<void> _getAddress() async {
//     _isNetworkAvail = await isNetworkAvailable();
//     if (_isNetworkAvail) {
//       try {
//         var parameter = {
//           USER_ID: CUR_USERID,
//         };
//         Response response =
//         await post(getAddressApi, body: parameter, headers: headers)
//             .timeout(Duration(seconds: timeOut));
//
//         if (response.statusCode == 200) {
//           var getdata = json.decode(response.body);
//
//           bool error = getdata["error"];
//           // String msg = getdata["message"];
//           if (!error) {
//             var data = getdata["data"];
//
//             addressList = (data as List)
//                 .map((data) => new User.fromAddress(data))
//                 .toList();
//
//             if (addressList.length == 1) {
//               selectedAddress = 0;
//               selAddress = addressList[0].id;
//               // if (ISFLAT_DEL) {
//               //   if (totalPrice < double.parse(addressList[0].freeAmt!))
//               //     delCharge = double.parse(addressList[0].deliveryCharge!);
//               //   else
//               //     delCharge = 0;
//               // }
//             } else {
//               for (int i = 0; i < addressList.length; i++) {
//                 if (addressList[i].isDefault == "1") {
//                   selectedAddress = i;
//                   selAddress = addressList[i].id;
//                   // if (!ISFLAT_DEL) {
//                   //   // if (totalPrice < double.parse(addressList[i].freeAmt!))
//                   //     delCharge = double.parse(addressList[i].deliveryCharge!);
//                   //   else
//                   //     delCharge = 0;
//                   // }
//                 }
//               }
//             }
//
//             // if (ISFLAT_DEL) {
//             //   if ((oriPrice) < double.parse(MIN_AMT!))
//             //     delCharge = double.parse(CUR_DEL_CHR!);
//             //   else
//             //     delCharge = 0;
//             // }
//             totalPrice = totalPrice + delCharge;
//           } else {
//             if (ISFLAT_DEL) {
//               if ((oriPrice) < double.parse(MIN_AMT!))
//                 delCharge = double.parse(CUR_DEL_CHR!);
//               else
//                 delCharge = 0;
//             }
//             totalPrice = totalPrice + delCharge;
//           }
//           if (mounted) {
//             setState(() {
//               _isLoading = false;
//             });
//           }
//
//           if (checkoutState != null) checkoutState!(() {});
//         } else {
//           setSnackbar(
//               getTranslated(context, 'somethingMSg')!, _checkscaffoldKey);
//           if (mounted)
//             setState(() {
//               _isLoading = false;
//             });
//         }
//       } on TimeoutException catch (_) {}
//     } else {
//       if (mounted)
//         setState(() {
//           _isNetworkAvail = false;
//         });
//     }
//   }
//
//   void _handlePaymentSuccess(PaymentSuccessResponse response) {
//     placeOrder(response.paymentId);
//   }
//
//   void _handlePaymentError(PaymentFailureResponse response) {
//     var getdata = json.decode(response.message!);
//     String errorMsg = getdata["error"]["description"];
//     setSnackbar(errorMsg, _checkscaffoldKey);
//
//     if (mounted)
//       checkoutState!(() {
//         _placeOrder = true;
//       });
//     context.read<CartProvider>().setProgress(false);
//   }
//
//   void _handleExternalWallet(ExternalWalletResponse response) {}
//
//   updateCheckout() {
//     if (mounted) checkoutState!(() {});
//   }
//
//   // razorpayPayment() async {
//   //   SettingProvider settingsProvider =
//   //   Provider.of<SettingProvider>(this.context, listen: false);
//   //
//   //   String? contact = settingsProvider.mobile;
//   //   String? email = settingsProvider.email;
//   //
//   //   String amt = ((totalPrice) * 100).toStringAsFixed(2);
//   //
//   //   if (contact != '' && email != '') {
//   //     context.read<CartProvider>().setProgress(true);
//   //
//   //     checkoutState!(() {});
//   //     var options = {
//   //       KEY: razorpayId,
//   //       AMOUNT: amt,
//   //       NAME: settingsProvider.userName,
//   //       'prefill': {CONTACT: contact, EMAIL: email},
//   //     };
//   //
//   //     try {
//   //       _razorpay!.open(options);
//   //     } catch (e) {
//   //       debugPrint(e.toString());
//   //     }
//   //   } else {
//   //     if (email == '')
//   //       setSnackbar(getTranslated(context, 'emailWarning')!, _checkscaffoldKey);
//   //     else if (contact == '')
//   //       setSnackbar(getTranslated(context, 'phoneWarning')!, _checkscaffoldKey);
//   //   }
//   // }
//   razorpayPayment() async {
//
//     SettingProvider settingsProvider =
//     Provider.of<SettingProvider>(this.context, listen: false);
//     print("Payment Email ${settingsProvider.email}");
//     print("Payment Email ${settingsProvider.mobile}");
//
//     String? contact = settingsProvider.mobile;
//     // String? email = settingsProvider.email;
//
//     String amt = ((totalPrice) * 100).toStringAsFixed(2);
//
//     if (contact != '') {
//       context.read<CartProvider>().setProgress(true);
//
//       checkoutState!(() {});
//       var options = {
//         KEY: razorpayId,
//         AMOUNT: amt,
//         NAME: settingsProvider.userName,
//         'prefill': {CONTACT: contact},
//       };
//
//       try {
//         _razorpay!.open(options);
//       } catch (e) {
//         debugPrint(e.toString());
//       }
//     } else {
//       // if (email == '')
//       //   setSnackbar(getTranslated(context, 'emailWarning')!, _checkscaffoldKey);
//       if (contact == '')
//         setSnackbar(getTranslated(context, 'phoneWarning')!, _checkscaffoldKey);
//     }
//   }
//
//   void paytmPayment() async {
//     String? paymentResponse;
//     context.read<CartProvider>().setProgress(true);
//
//     String orderId = DateTime.now().millisecondsSinceEpoch.toString();
//
//     String callBackUrl = (payTesting
//         ? 'https://securegw-stage.paytm.in'
//         : 'https://securegw.paytm.in') +
//         '/theia/paytmCallback?ORDER_ID=' +
//         orderId;
//
//     var parameter = {
//       AMOUNT: totalPrice.toString(),
//       USER_ID: CUR_USERID,
//       ORDER_ID: orderId
//     };
//
//     try {
//       final response = await post(
//         getPytmChecsumkApi,
//         body: parameter,
//         headers: headers,
//       );
//
//       var getdata = json.decode(response.body);
//
//       bool error = getdata["error"];
//
//       if (!error) {
//         String txnToken = getdata["txn_token"];
//
//         setState(() {
//           paymentResponse = txnToken;
//         });
//         // orderId, mId, txnToken, txnAmount, callback
//         print(
//             "para are $paytmMerId # $orderId # $txnToken # ${totalPrice.toString()} # $callBackUrl  $payTesting");
//         var paytmResponse = Paytm.payWithPaytm(
//             callBackUrl: callBackUrl,
//             mId: paytmMerId!,
//             orderId: orderId,
//             txnToken: txnToken,
//             txnAmount: totalPrice.toString(),
//             staging: payTesting);
//         paytmResponse.then((value) {
//           print("valie is $value");
//           value.forEach((key, value) {
//             print("key is $key");
//             print("value is $value");
//           });
//           context.read<CartProvider>().setProgress(false);
//
//           _placeOrder = true;
//           setState(() {});
//           checkoutState!(() {
//             if (value['error']) {
//               paymentResponse = value['errorMessage'];
//
//               if (value['response'] != null)
//                 addTransaction(value['response']['TXNID'], orderId,
//                     value['response']['STATUS'] ?? '', paymentResponse, false);
//             } else {
//               if (value['response'] != null) {
//                 paymentResponse = value['response']['STATUS'];
//                 if (paymentResponse == "TXN_SUCCESS")
//                   placeOrder(value['response']['TXNID']);
//                 else
//                   addTransaction(
//                       value['response']['TXNID'],
//                       orderId,
//                       value['response']['STATUS'],
//                       value['errorMessage'] ?? '',
//                       false);
//               }
//             }
//
//             setSnackbar(paymentResponse!, _checkscaffoldKey);
//           });
//         });
//       } else {
//         checkoutState!(() {
//           _placeOrder = true;
//         });
//
//
//         context.read<CartProvider>().setProgress(false);
//
//         setSnackbar(getdata["message"], _checkscaffoldKey);
//       }
//     } catch (e) {
//       print(e);
//     }
//   }
//
//   Future<void> placeOrder(String? tranId) async {
//     _isNetworkAvail = await isNetworkAvailable();
//     if (_isNetworkAvail) {
//       context.read<CartProvider>().setProgress(true);
//
//       SettingProvider settingsProvider =
//       Provider.of<SettingProvider>(this.context, listen: false);
//
//       String? mob = settingsProvider.mobile;
//
//       String? varientId, quantity;
//
//       List<SectionModel> cartList = context.read<CartProvider>().cartList;
//       for (SectionModel sec in cartList) {
//         varientId = varientId != null
//             ? varientId + "," + sec.varientId!
//             : sec.varientId;
//         quantity = quantity != null ? quantity + "," + sec.qty! : sec.qty;
//       }
//       String? payVia;
//       if (payMethod == getTranslated(context, 'COD_LBL'))
//         payVia = "COD";
//       else if (payMethod == getTranslated(context, 'PAYPAL_LBL'))
//         payVia = "PayPal";
//       else if (payMethod == getTranslated(context, 'PAYUMONEY_LBL'))
//         payVia = "PayUMoney";
//       else if (payMethod == getTranslated(context, 'RAZORPAY_LBL'))
//         payVia = "RazorPay";
//       else if (payMethod == getTranslated(context, 'PAYSTACK_LBL'))
//         payVia = "Paystack";
//       else if (payMethod == getTranslated(context, 'FLUTTERWAVE_LBL'))
//         payVia = "Flutterwave";
//       else if (payMethod == getTranslated(context, 'STRIPE_LBL'))
//         payVia = "Stripe";
//       else if (payMethod == getTranslated(context, 'PAYTM_LBL'))
//         payVia = "Paytm";
//       else if (payMethod == "Wallet")
//         payVia = "Wallet";
//       else if (payMethod == getTranslated(context, 'BANKTRAN'))
//         payVia = "bank_transfer";
//       try {
//         var parameter = {
//
//           USER_ID: CUR_USERID,
//           MOBILE: mob,
//           PRODUCT_VARIENT_ID: varientId,
//           QUANTITY: quantity,
//           TOTAL: oriPrice.toString(),
//           FINAL_TOTAL: totalPrice.toString(),
//           DEL_CHARGE: dCharge.toString(),
//           // TAX_AMT: taxAmt.toString(),
//           TAX_PER: taxPer.toString(),
//
//           PAYMENT_METHOD: payVia,
//           ADD_ID: selAddress,
//           ISWALLETBALUSED: isUseWallet! ? "1" : "0",
//           WALLET_BAL_USED: usedBal.toString(),
//           ORDER_NOTE: noteC.text,
//           "receiver_address":deliveryAddres.toString(),
//           "image": productImage.toString(),
//         };
//
//         if (isTimeSlot!) {
//           parameter[DELIVERY_TIME] = selTime ?? 'Anytime';
//           parameter[DELIVERY_DATE] = selDate ?? '';
//         }
//         if (isPromoValid!) {
//           parameter[PROMOCODE] = promocode;
//           parameter[PROMO_DIS] = promoAmt.toString();
//         }
//
//         if (payMethod == getTranslated(context, 'PAYPAL_LBL')) {
//           parameter[ACTIVE_STATUS] = WAITING;
//         } else if (payMethod == getTranslated(context, 'STRIPE_LBL')) {
//           if (tranId == "succeeded")
//             parameter[ACTIVE_STATUS] = PLACED;
//           else
//             parameter[ACTIVE_STATUS] = WAITING;
//         } else if (payMethod == getTranslated(context, 'BANKTRAN')) {
//           parameter[ACTIVE_STATUS] = WAITING;
//         }
//         print(parameter.toString());
//         print("PLACE ORDER PARAMETER====" + parameter.toString());
//
//         Response response =
//         await post(placeOrderApi, body: parameter, headers: headers)
//             .timeout(Duration(seconds: timeOut));
//         print(placeOrderApi.toString());
//         print(parameter.toString());
//         _placeOrder = true;
//         if (response.statusCode == 200) {
//           var getdata = json.decode(response.body);
//           bool error = getdata["error"];
//           String? msg = getdata["message"];
//           if (!error) {
//             String orderId = getdata["order_id"].toString();
//             if (payMethod == getTranslated(context, 'RAZORPAY_LBL')) {
//               addTransaction(tranId, orderId, SUCCESS, msg, true);
//             } else if (payMethod == getTranslated(context, 'PAYPAL_LBL')) {
//               paypalPayment(orderId);
//             } else if (payMethod == getTranslated(context, 'STRIPE_LBL')) {
//               addTransaction(stripePayId, orderId,
//                   tranId == "succeeded" ? PLACED : WAITING, msg, true);
//             } else if (payMethod == getTranslated(context, 'PAYSTACK_LBL')) {
//               addTransaction(tranId, orderId, SUCCESS, msg, true);
//             } else if (payMethod == getTranslated(context, 'PAYTM_LBL')) {
//               addTransaction(tranId, orderId, SUCCESS, msg, true);
//             } else {
//               context.read<UserProvider>().setCartCount("0");
//
//               clearAll();
//
//               Navigator.pushAndRemoveUntil(
//                   context,
//                   MaterialPageRoute(
//                       builder: (BuildContext context) => OrderSuccess()),
//                   ModalRoute.withName('/home'));
//             }
//           } else {
//             setSnackbar(msg!, _checkscaffoldKey);
//             context.read<CartProvider>().setProgress(false);
//           }
//         }
//       } on TimeoutException catch (_) {
//         if (mounted)
//           checkoutState!(() {
//             _placeOrder = true;
//           });
//         context.read<CartProvider>().setProgress(false);
//       }
//     } else {
//       if (mounted)
//         checkoutState!(() {
//           _isNetworkAvail = false;
//         });
//     }
//   }
//
//   Future<void> paypalPayment(String orderId) async {
//     try {
//       var parameter = {
//         USER_ID: CUR_USERID,
//         ORDER_ID: orderId,
//         AMOUNT: totalPrice.toString()
//       };
//       Response response =
//       await post(paypalTransactionApi, body: parameter, headers: headers)
//           .timeout(Duration(seconds: timeOut));
//
//       var getdata = json.decode(response.body);
//
//       bool error = getdata["error"];
//       String? msg = getdata["message"];
//       if (!error) {
//         String? data = getdata["data"];
//         Navigator.push(
//             context,
//             MaterialPageRoute(
//                 builder: (BuildContext context) => PaypalWebview(
//                   url: data,
//                   from: "order",
//                   orderId: orderId,
//                 )));
//       } else {
//         setSnackbar(msg!, _checkscaffoldKey);
//       }
//       context.read<CartProvider>().setProgress(false);
//     } on TimeoutException catch (_) {
//       setSnackbar(getTranslated(context, 'somethingMSg')!, _checkscaffoldKey);
//     }
//   }
//
//   Future<void> addTransaction(String? tranId, String orderID, String? status,
//       String? msg, bool redirect) async {
//     try {
//       var parameter = {
//         USER_ID: CUR_USERID,
//         ORDER_ID: orderID,
//         TYPE: payMethod,
//         TXNID: tranId,
//         AMOUNT: totalPrice.toString(),
//         STATUS: status,
//         MSG: msg
//       };
//       Response response =
//       await post(addTransactionApi, body: parameter, headers: headers)
//           .timeout(Duration(seconds: timeOut));
//
//       var getdata = json.decode(response.body);
//
//       bool error = getdata["error"];
//       String? msg1 = getdata["message"];
//       if (!error) {
//         if (redirect) {
//           // CUR_CART_COUNT = "0";
//
//           context.read<UserProvider>().setCartCount("0");
//           clearAll();
//
//           Navigator.pushAndRemoveUntil(
//               context,
//               MaterialPageRoute(
//                   builder: (BuildContext context) => OrderSuccess()),
//               ModalRoute.withName('/home'));
//         }
//       } else {
//         setSnackbar(msg1!, _checkscaffoldKey);
//       }
//     } on TimeoutException catch (_) {
//       setSnackbar(getTranslated(context, 'somethingMSg')!, _checkscaffoldKey);
//     }
//   }
//
//
//   String _getReference() {
//     String platform;
//     if (Platform.isIOS) {
//       platform = 'iOS';
//     } else {
//       platform = 'Android';
//     }
//
//     return 'ChargedFrom${platform}_${DateTime.now().millisecondsSinceEpoch}';
//   }
//
//   stripePayment() async {
//     context.read<CartProvider>().setProgress(true);
//
//     var response = await StripeService.payWithNewCard(
//         amount: (totalPrice.toInt() * 100).toString(),
//         currency: stripeCurCode,
//         from: "order",
//         context: context);
//
//     if (response.message == "Transaction successful") {
//       placeOrder(response.status);
//     } else if (response.status == 'pending' || response.status == "captured") {
//       placeOrder(response.status);
//     } else {
//       if (mounted)
//         setState(() {
//           _placeOrder = true;
//         });
//
//       context.read<CartProvider>().setProgress(false);
//     }
//     setSnackbar(response.message!, _checkscaffoldKey);
//   }
//
//   address() {
//     return Card(
//       elevation: 0,
//       child: Padding(
//         padding: const EdgeInsets.all(8.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             Row(
//               children: [
//                 Icon(Icons.location_on),
//                 Padding(
//                     padding: const EdgeInsetsDirectional.only(start: 8.0),
//                     child: Text("Recipients Details"
//                         // getTranslated(context, 'SHIPPING_DETAIL')
//                         ?? '',
//                       style: TextStyle(
//                           fontWeight: FontWeight.bold,
//                           color: Theme.of(context).colorScheme.fontColor),
//                     )),
//               ],
//             ),
//             Divider(),
//             addressList.length > 0
//                 ? Padding(
//               padding: const EdgeInsetsDirectional.only(start: 8.0),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Row(
//                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                     children: [
//                       Text(addressList[selectedAddress!].name!),
//                       InkWell(
//                         child: Padding(
//                           padding:
//                           const EdgeInsets.symmetric(horizontal: 8.0),
//                           child: Text(
//                             getTranslated(context, 'CHANGE')!,
//                             style: TextStyle(
//                               color: colors.primary,
//                             ),
//                           ),
//                         ),
//                         onTap: () async {
//                           await Navigator.push(
//                               context,
//                               MaterialPageRoute(
//                                   builder: (BuildContext context) =>
//                                       ManageAddress(
//                                         home: false,
//                                       )));
//
//                           checkoutState!(() {
//                             deliverable = false;
//                           });
//                         },
//                       ),
//                     ],
//                   ),
//                   Text(
//                     addressList[selectedAddress!].address! +
//                         ", " +
//                         // addressList[selectedAddress!].area! +
//                         ", " +
//                         addressList[selectedAddress!].city! +
//                         ", " +
//                         addressList[selectedAddress!].state! +
//                         ", " +
//                         addressList[selectedAddress!].country! +
//                         ", " +
//                         addressList[selectedAddress!].pincode!,
//                     style: Theme.of(context).textTheme.caption!.copyWith(
//                         color: Theme.of(context).colorScheme.lightBlack),
//                   ),
//                   Padding(
//                     padding: const EdgeInsets.symmetric(vertical: 5.0),
//                     child: Row(
//                       children: [
//                         Text(
//                           addressList[selectedAddress!].mobile!,
//                           style: Theme.of(context)
//                               .textTheme
//                               .caption!
//                               .copyWith(
//                               color: Theme.of(context)
//                                   .colorScheme
//                                   .lightBlack),
//                         ),
//                       ],
//                     ),
//                   )
//                 ],
//               ),
//             )
//                 : Padding(
//               padding: const EdgeInsetsDirectional.only(start: 8.0),
//               child: GestureDetector(
//                 child: Text(
//                   getTranslated(context, 'ADDADDRESS')!,
//                   style: TextStyle(
//                     color: Theme.of(context).colorScheme.fontColor,
//                   ),
//                 ),
//                 onTap: () async {
//                   ScaffoldMessenger.of(context).removeCurrentSnackBar();
//                   Navigator.push(
//                     context,
//                     MaterialPageRoute(
//                         builder: (context) => AddAddress(
//                           update: false,
//                           index: addressList.length,
//                         )),
//                   );
//                   if (mounted) setState(() {});
//                 },
//               ),
//             ),
//             Divider(),
//             deliveryAddres == null || deliveryAddres == ""  ? SizedBox.shrink() :
//             Row(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               children: [
//                 Padding(
//                   padding: const EdgeInsets.only(left: 8.0),
//                   child: Text("Sender Details : "),
//                 ),
//                 // Padding(
//                 //   padding: const EdgeInsets.only(right: 10),
//                 //   child: InkWell(
//                 //       onTap: (){
//                 //         Navigator.push(context, MaterialPageRoute(builder: (context)=>DeliverToPage()));
//                 //       },
//                 //       child: Text("Change",style: TextStyle(color: Colors.deepOrangeAccent),)),
//                 // ),
//               ],
//             ),
//
//
//             SizedBox(height: 10,),
//
//             deliveryAddres == null || deliveryAddres == ""  ? SizedBox.shrink():
//             Padding(
//               padding: const EdgeInsets.only(left: 8.0),
//               child: Text("${deliveryAddres['name']}\n${deliveryAddres['mobile1']}"),
//             )
//           ],
//         ),
//       ),
//     );
//   }
//
//   payment() {
//     return Card(
//       elevation: 0,
//       child: InkWell(
//         borderRadius: BorderRadius.circular(4),
//         onTap: () async {
//           ScaffoldMessenger.of(context).removeCurrentSnackBar();
//           msg = '';
//           await Navigator.push(
//               context,
//               MaterialPageRoute(
//                   builder: (BuildContext context) =>
//                       Payment(updateCheckout, msg)));
//           if (mounted) checkoutState!(() {});
//         },
//         child: Padding(
//           padding: const EdgeInsets.all(8.0),
//           child: Column(
//             children: [
//               Row(
//                 children: [
//                   Icon(Icons.payment),
//                   Padding(
//                     padding: const EdgeInsetsDirectional.only(start: 8.0),
//                     child: Text(
//                       //SELECT_PAYMENT,
//                       getTranslated(context, 'SELECT_PAYMENT')!,
//                       style: TextStyle(
//                           color: Theme.of(context).colorScheme.fontColor,
//                           fontWeight: FontWeight.bold),
//                     ),
//                   )
//                 ],
//               ),
//               payMethod != null && payMethod != ''
//                   ? Padding(
//                 padding: const EdgeInsets.symmetric(horizontal: 8.0),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [Divider(), Text(payMethod!)],
//                 ),
//               )
//                   : Container(),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
//
//   cartItems(List<SectionModel> cartList) {
//     return ListView.builder(
//       shrinkWrap: true,
//       itemCount: cartList.length,
//       physics: NeverScrollableScrollPhysics(),
//       itemBuilder: (context, index) {
//         return cartItem(index, cartList);
//       },
//     );
//   }
//
//   orderSummary(List<SectionModel> cartList) {
//     return Card(
//         elevation: 0,
//         child: Padding(
//           padding: const EdgeInsets.all(8.0),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Text(
//                 getTranslated(context, 'ORDER_SUMMARY')! +
//                     " (" +
//                     cartList.length.toString() +
//                     " items)",
//                 style: TextStyle(
//                     color: Theme.of(context).colorScheme.fontColor,
//                     fontWeight: FontWeight.bold),
//               ),
//               Divider(),
//               Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                 children: [
//                   Text(
//                     getTranslated(context, 'SUBTOTAL')!,
//                     style: TextStyle(
//                         color: Theme.of(context).colorScheme.lightBlack2),
//                   ),
//                   Text(
//                     CUR_CURRENCY! + " " + oriPrice.toStringAsFixed(2),
//                     style: TextStyle(
//                         color: Theme.of(context).colorScheme.fontColor,
//                         fontWeight: FontWeight.bold),
//                   )
//                 ],
//               ),
//               Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                 children: [
//                   Text(
//                     getTranslated(context, 'DELIVERY_CHARGE')!,
//                     style: TextStyle(
//                         color: Theme.of(context).colorScheme.lightBlack2),
//                   ),
//                   dCharge == null ? Text(
//                     CUR_CURRENCY.toString() + " " + "0",
//                     style: TextStyle(
//                         color: Theme.of(context).colorScheme.fontColor,
//                         fontWeight: FontWeight.bold),
//                   ) :   Text(
//                     CUR_CURRENCY.toString() + " " + dCharge.toString(),
//                     style: TextStyle(
//                         color: Theme.of(context).colorScheme.fontColor,
//                         fontWeight: FontWeight.bold),
//                   )
//                 ],
//               ),
//               isPromoValid!
//                   ? Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                 children: [
//                   Text(
//                     getTranslated(context, 'PROMO_CODE_DIS_LBL')!,
//                     style: TextStyle(
//                         color: Theme.of(context).colorScheme.lightBlack2),
//                   ),
//                   Text(
//                     CUR_CURRENCY! + " " + promoAmt.toStringAsFixed(2),
//                     style: TextStyle(
//                         color: Theme.of(context).colorScheme.fontColor,
//                         fontWeight: FontWeight.bold),
//                   )
//                 ],
//               )
//                   : Container(),
//               isUseWallet!
//                   ? Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                 children: [
//                   Text(
//                     getTranslated(context, 'WALLET_BAL')!,
//                     style: TextStyle(
//                         color: Theme.of(context).colorScheme.lightBlack2),
//                   ),
//                   Text(
//                     CUR_CURRENCY! + " " + usedBal.toStringAsFixed(2),
//                     style: TextStyle(
//                         color: Theme.of(context).colorScheme.fontColor,
//                         fontWeight: FontWeight.bold),
//                   )
//                 ],
//               )
//                   : Container(),
//             ],
//           ),
//         ));
//   }
//
//   Future<void> validatePromo(bool check) async {
//     _isNetworkAvail = await isNetworkAvailable();
//     if (_isNetworkAvail) {
//       try {
//         context.read<CartProvider>().setProgress(true);
//         if (check) {
//           if (this.mounted && checkoutState != null) checkoutState!(() {});
//         }
//         setState(() {});
//         var parameter = {
//           USER_ID: CUR_USERID,
//           PROMOCODE: promoC.text,
//           FINAL_TOTAL: oriPrice.toString()
//         };
//         Response response =
//         await post(validatePromoApi, body: parameter, headers: headers)
//             .timeout(Duration(seconds: timeOut));
//
//         if (response.statusCode == 200) {
//           var getdata = json.decode(response.body);
//
//           bool error = getdata["error"];
//           String? msg = getdata["message"];
//           if (!error) {
//             var data = getdata["data"][0];
//
//             totalPrice = double.parse(data["final_total"]) + delCharge;
//
//             promoAmt = double.parse(data["final_discount"]);
//             promocode = data["promo_code"];
//             isPromoValid = true;
//             setSnackbar(
//                 getTranslated(context, 'PROMO_SUCCESS')!, _checkscaffoldKey);
//           } else {
//             isPromoValid = false;
//             promoAmt = 0;
//             promocode = null;
//             promoC.clear();
//             var data = getdata["data"];
//
//             totalPrice = double.parse(data["final_total"]) + delCharge;
//
//             setSnackbar(msg!, _checkscaffoldKey);
//           }
//           if (isUseWallet!) {
//             remWalBal = 0;
//             payMethod = null;
//             usedBal = 0;
//             isUseWallet = false;
//             isPayLayShow = true;
//
//             selectedMethod = null;
//             context.read<CartProvider>().setProgress(false);
//             if (mounted && check) checkoutState!(() {});
//             setState(() {});
//           } else {
//             if (mounted && check) checkoutState!(() {});
//             setState(() {});
//             context.read<CartProvider>().setProgress(false);
//           }
//         }
//       } on TimeoutException catch (_) {
//         context.read<CartProvider>().setProgress(false);
//         if (mounted && check) checkoutState!(() {});
//         setState(() {});
//         setSnackbar(getTranslated(context, 'somethingMSg')!, _checkscaffoldKey);
//       }
//     } else {
//       _isNetworkAvail = false;
//       if (mounted && check) checkoutState!(() {});
//       setState(() {});
//     }
//   }
//
//   Future<void> flutterwavePayment() async {
//     _isNetworkAvail = await isNetworkAvailable();
//     if (_isNetworkAvail) {
//       try {
//         context.read<CartProvider>().setProgress(true);
//
//         var parameter = {
//           AMOUNT: totalPrice.toString(),
//           USER_ID: CUR_USERID,
//         };
//         Response response =
//         await post(flutterwaveApi, body: parameter, headers: headers)
//             .timeout(Duration(seconds: timeOut));
//
//         if (response.statusCode == 200) {
//           var getdata = json.decode(response.body);
//
//           bool error = getdata["error"];
//           String? msg = getdata["message"];
//           if (!error) {
//             var data = getdata["link"];
//             Navigator.push(
//                 context,
//                 MaterialPageRoute(
//                     builder: (BuildContext context) => PaypalWebview(
//                       url: data,
//                       from: "order",
//                     )));
//           } else {
//             setSnackbar(msg!, _checkscaffoldKey);
//           }
//
//           context.read<CartProvider>().setProgress(false);
//         }
//       } on TimeoutException catch (_) {
//         context.read<CartProvider>().setProgress(false);
//         setSnackbar(getTranslated(context, 'somethingMSg')!, _checkscaffoldKey);
//       }
//     } else {
//       if (mounted)
//         checkoutState!(() {
//           _isNetworkAvail = false;
//         });
//     }
//   }
//
//   void confirmDialog() {
//     showGeneralDialog(
//         barrierColor: Theme.of(context).colorScheme.black.withOpacity(0.5),
//         transitionBuilder: (context, a1, a2, widget) {
//           return Transform.scale(
//             scale: a1.value,
//             child: Opacity(
//                 opacity: a1.value,
//                 child: AlertDialog(
//                   contentPadding: const EdgeInsets.all(0),
//                   elevation: 2.0,
//                   shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.all(Radius.circular(5.0))),
//                   content: Column(
//                       mainAxisSize: MainAxisSize.min,
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         Padding(
//                             padding: EdgeInsets.fromLTRB(20.0, 20.0, 0, 2.0),
//                             child: Text(
//                               getTranslated(context, 'CONFIRM_ORDER')!,
//                               style: Theme.of(this.context)
//                                   .textTheme
//                                   .subtitle1!
//                                   .copyWith(
//                                   color: Theme.of(context)
//                                       .colorScheme
//                                       .fontColor),
//                             )),
//                         Divider(
//                             color: Theme.of(context).colorScheme.lightBlack),
//                         Padding(
//                           padding: EdgeInsets.fromLTRB(20.0, 0, 20.0, 0),
//                           child: Column(
//                             mainAxisSize: MainAxisSize.min,
//                             children: [
//                               Row(
//                                 mainAxisAlignment:
//                                 MainAxisAlignment.spaceBetween,
//                                 children: [
//                                   Text(
//                                     getTranslated(context, 'SUBTOTAL')!,
//                                     style: Theme.of(context)
//                                         .textTheme
//                                         .subtitle2!
//                                         .copyWith(
//                                         color: Theme.of(context)
//                                             .colorScheme
//                                             .lightBlack2),
//                                   ),
//                                   Text(
//                                     CUR_CURRENCY! +
//                                         " " +
//                                         oriPrice.toStringAsFixed(2),
//                                     style: Theme.of(context)
//                                         .textTheme
//                                         .subtitle2!
//                                         .copyWith(
//                                         color: Theme.of(context)
//                                             .colorScheme
//                                             .fontColor,
//                                         fontWeight: FontWeight.bold),
//                                   )
//                                 ],
//                               ),
//                               Row(
//                                 mainAxisAlignment:
//                                 MainAxisAlignment.spaceBetween,
//                                 children: [
//                                   Text(
//                                     getTranslated(context, 'DELIVERY_CHARGE')!,
//                                     style: Theme.of(context)
//                                         .textTheme
//                                         .subtitle2!
//                                         .copyWith(
//                                         color: Theme.of(context)
//                                             .colorScheme
//                                             .lightBlack2),
//                                   ),
//                                   Text(
//                                     CUR_CURRENCY! +
//                                         " " +
//                                         dCharge.toString(),
//
//                                     style: Theme.of(context)
//                                         .textTheme
//                                         .subtitle2!
//                                         .copyWith(
//                                         color: Theme.of(context)
//                                             .colorScheme
//                                             .fontColor,
//                                         fontWeight: FontWeight.bold),
//                                   )
//                                 ],
//                               ),
//                               isPromoValid!
//                                   ? Row(
//                                 mainAxisAlignment:
//                                 MainAxisAlignment.spaceBetween,
//                                 children: [
//                                   Text(
//                                     getTranslated(
//                                         context, 'PROMO_CODE_DIS_LBL')!,
//                                     style: Theme.of(context)
//                                         .textTheme
//                                         .subtitle2!
//                                         .copyWith(
//                                         color: Theme.of(context)
//                                             .colorScheme
//                                             .lightBlack2),
//                                   ),
//                                   Text(
//                                     CUR_CURRENCY! +
//                                         " " +
//                                         promoAmt.toStringAsFixed(2),
//                                     style: Theme.of(context)
//                                         .textTheme
//                                         .subtitle2!
//                                         .copyWith(
//                                         color: Theme.of(context)
//                                             .colorScheme
//                                             .fontColor,
//                                         fontWeight: FontWeight.bold),
//                                   )
//                                 ],
//                               )
//                                   : Container(),
//                               isUseWallet!
//                                   ? Row(
//                                 mainAxisAlignment:
//                                 MainAxisAlignment.spaceBetween,
//                                 children: [
//                                   Text(
//                                     getTranslated(context, 'WALLET_BAL')!,
//                                     style: Theme.of(context)
//                                         .textTheme
//                                         .subtitle2!
//                                         .copyWith(
//                                         color: Theme.of(context)
//                                             .colorScheme
//                                             .lightBlack2),
//                                   ),
//                                   Text(
//                                     CUR_CURRENCY! +
//                                         " " +
//                                         usedBal.toStringAsFixed(2),
//                                     style: Theme.of(context)
//                                         .textTheme
//                                         .subtitle2!
//                                         .copyWith(
//                                         color: Theme.of(context)
//                                             .colorScheme
//                                             .fontColor,
//                                         fontWeight: FontWeight.bold),
//                                   )
//                                 ],
//                               )
//                                   : Container(),
//                               Padding(
//                                 padding:
//                                 const EdgeInsets.symmetric(vertical: 8.0),
//                                 child: Row(
//                                   mainAxisAlignment:
//                                   MainAxisAlignment.spaceBetween,
//                                   children: [
//                                     Text(
//                                       getTranslated(context, 'TOTAL_PRICE')!,
//                                       style: Theme.of(context)
//                                           .textTheme
//                                           .subtitle2!
//                                           .copyWith(
//                                           color: Theme.of(context)
//                                               .colorScheme
//                                               .lightBlack2),
//                                     ),
//                                     Text(
//                                       "$CUR_CURRENCY ${totalamount.toString()}",
//                                       //   "$CUR_CURRENCY  +${totalPrice.toStringAsFixed(2)}",
//                                       style: TextStyle(
//                                           color: Theme.of(context)
//                                               .colorScheme
//                                               .fontColor,
//                                           fontWeight: FontWeight.bold),
//                                     ),
//                                   ],
//                                 ),
//                               ),
//                               Container(
//                                   padding: EdgeInsets.symmetric(vertical: 10),
//                                   /* decoration: BoxDecoration(
//                                     color: colors.primary.withOpacity(0.1),
//                                     borderRadius: BorderRadius.all(
//                                       Radius.circular(10),
//                                     ),
//                                   ),*/
//                                   child: TextField(
//                                     controller: noteC,
//                                     style:
//                                     Theme.of(context).textTheme.subtitle2,
//                                     decoration: InputDecoration(
//                                       contentPadding:
//                                       EdgeInsets.symmetric(horizontal: 10),
//                                       border: InputBorder.none,
//                                       filled: true,
//                                       fillColor:
//                                       colors.primary.withOpacity(0.1),
//                                       //isDense: true,
//                                       hintText: getTranslated(context, 'NOTE'),
//                                     ),
//                                   )),
//                             ],
//                           ),
//                         ),
//                       ]),
//                   actions: <Widget>[
//                     new TextButton(
//                         child: Text(getTranslated(context, 'CANCEL')!,
//                             style: TextStyle(
//                                 color: Theme.of(context).colorScheme.lightBlack,
//                                 fontSize: 15,
//                                 fontWeight: FontWeight.bold)),
//                         onPressed: () {
//                           checkoutState!(() {
//                             _placeOrder = true;
//                           });
//                           Navigator.pop(context);
//                         }),
//                     new TextButton(
//                         child: Text(getTranslated(context, 'DONE')!,
//                             style: TextStyle(
//                                 color: colors.primary,
//                                 fontSize: 15,
//                                 fontWeight: FontWeight.bold)),
//                         onPressed: () {
//                           Navigator.pop(context);
//
//                           doPayment();
//                         })
//                   ],
//                 )),
//           );
//         },
//         transitionDuration: Duration(milliseconds: 200),
//         barrierDismissible: false,
//         barrierLabel: '',
//         context: context,
//         pageBuilder: (context, animation1, animation2) {
//           return Container();
//         });
//   }
//
//   void bankTransfer() {
//     showGeneralDialog(
//         barrierColor: Theme.of(context).colorScheme.black.withOpacity(0.5),
//         transitionBuilder: (context, a1, a2, widget) {
//           return Transform.scale(
//             scale: a1.value,
//             child: Opacity(
//                 opacity: a1.value,
//                 child: AlertDialog(
//                   contentPadding: const EdgeInsets.all(0),
//                   elevation: 2.0,
//                   shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.all(Radius.circular(5.0))),
//                   content: Column(
//                       mainAxisSize: MainAxisSize.min,
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         Padding(
//                             padding: EdgeInsets.fromLTRB(20.0, 20.0, 0, 2.0),
//                             child: Text(
//                               getTranslated(context, 'BANKTRAN')!,
//                               style: Theme.of(this.context)
//                                   .textTheme
//                                   .subtitle1!
//                                   .copyWith(
//                                   color: Theme.of(context)
//                                       .colorScheme
//                                       .fontColor),
//                             )),
//                         Divider(
//                             color: Theme.of(context).colorScheme.lightBlack),
//                         Padding(
//                             padding: EdgeInsets.fromLTRB(20.0, 0, 20.0, 0),
//                             child: Text(getTranslated(context, 'BANK_INS')!,
//                                 style: Theme.of(context).textTheme.caption)),
//                         Padding(
//                           padding: const EdgeInsets.symmetric(
//                               horizontal: 20.0, vertical: 10),
//                           child: Text(
//                             getTranslated(context, 'ACC_DETAIL')!,
//                             style: Theme.of(context)
//                                 .textTheme
//                                 .subtitle2!
//                                 .copyWith(
//                                 color: Theme.of(context)
//                                     .colorScheme
//                                     .fontColor),
//                           ),
//                         ),
//                         Padding(
//                           padding: const EdgeInsets.symmetric(
//                             horizontal: 20.0,
//                           ),
//                           child: Text(
//                             getTranslated(context, 'ACCNAME')! +
//                                 " : " +
//                                 acName!,
//                             style: Theme.of(context).textTheme.subtitle2,
//                           ),
//                         ),
//                         Padding(
//                           padding: const EdgeInsets.symmetric(
//                             horizontal: 20.0,
//                           ),
//                           child: Text(
//                             getTranslated(context, 'ACCNO')! + " : " + acNo!,
//                             style: Theme.of(context).textTheme.subtitle2,
//                           ),
//                         ),
//                         Padding(
//                           padding: const EdgeInsets.symmetric(
//                             horizontal: 20.0,
//                           ),
//                           child: Text(
//                             getTranslated(context, 'BANKNAME')! +
//                                 " : " +
//                                 bankName!,
//                             style: Theme.of(context).textTheme.subtitle2,
//                           ),
//                         ),
//                         Padding(
//                           padding: const EdgeInsets.symmetric(
//                             horizontal: 20.0,
//                           ),
//                           child: Text(
//                             getTranslated(context, 'BANKCODE')! +
//                                 " : " +
//                                 bankNo!,
//                             style: Theme.of(context).textTheme.subtitle2,
//                           ),
//                         ),
//                         Padding(
//                           padding: const EdgeInsets.symmetric(
//                             horizontal: 20.0,
//                           ),
//                           child: Text(
//                             getTranslated(context, 'EXTRADETAIL')! +
//                                 " : " +
//                                 exDetails!,
//                             style: Theme.of(context).textTheme.subtitle2,
//                           ),
//                         )
//                       ]),
//                   actions: <Widget>[
//                     new TextButton(
//                         child: Text(getTranslated(context, 'CANCEL')!,
//                             style: TextStyle(
//                                 color: Theme.of(context).colorScheme.lightBlack,
//                                 fontSize: 15,
//                                 fontWeight: FontWeight.bold)),
//                         onPressed: () {
//                           checkoutState!(() {
//                             _placeOrder = true;
//                           });
//                           Navigator.pop(context);
//                         }),
//                     new TextButton(
//                         child: Text(getTranslated(context, 'DONE')!,
//                             style: TextStyle(
//                                 color: Theme.of(context).colorScheme.fontColor,
//                                 fontSize: 15,
//                                 fontWeight: FontWeight.bold)),
//                         onPressed: () {
//                           Navigator.pop(context);
//
//                           context.read<CartProvider>().setProgress(true);
//
//                           placeOrder('');
//                         })
//                   ],
//                 )),
//           );
//         },
//         transitionDuration: Duration(milliseconds: 200),
//         barrierDismissible: false,
//         barrierLabel: '',
//         context: context,
//         pageBuilder: (context, animation1, animation2) {
//           return Container();
//         });
//   }
//
//   Future<void> checkDeliverable() async {
//     _isNetworkAvail = await isNetworkAvailable();
//     if (_isNetworkAvail) {
//       try {
//         context.read<CartProvider>().setProgress(true);
//
//         var parameter = {
//           USER_ID: CUR_USERID,
//           ADD_ID: selAddress,
//         };
//         print(parameter.toString());
//
//         Response response =
//         await post(checkCartDelApi, body: parameter, headers: headers)
//             .timeout(Duration(seconds: timeOut));
//         print(checkCartDelApi.toString());
//
//         var getdata = json.decode(response.body);
//
//         bool error = getdata["error"];
//         String? msg = getdata["message"];
//         var data = getdata["data"];
//         context.read<CartProvider>().setProgress(false);
//
//         if (error) {
//           deliverableList = (data as List)
//               .map((data) => new Model.checkDeliverable(data))
//               .toList();
//
//           checkoutState!(() {
//             deliverable = false;
//             _placeOrder = true;
//           });
//
//           setSnackbar(msg!, _checkscaffoldKey);
//         } else {
//           deliverableList = (data as List)
//               .map((data) => new Model.checkDeliverable(data))
//               .toList();
//
//           checkoutState!(() {
//             deliverable = true;
//           });
//           confirmDialog();
//         }
//       } on TimeoutException catch (_) {
//         setSnackbar(getTranslated(context, 'somethingMSg')!, _checkscaffoldKey);
//       }
//     } else {
//       if (mounted)
//         setState(() {
//           _isNetworkAvail = false;
//         });
//     }
//   }
//
//
// }
