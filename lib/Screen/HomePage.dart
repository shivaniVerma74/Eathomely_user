import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:carousel_slider/carousel_slider.dart';


import 'package:cached_network_image/cached_network_image.dart';
import 'package:homely_user/Helper/ApiBaseHelper.dart';
import 'package:homely_user/Helper/AppBtn.dart';
import 'package:homely_user/Helper/Color.dart';
import 'package:homely_user/Helper/Constant.dart';
import 'package:homely_user/Helper/Session.dart';
import 'package:homely_user/Helper/SimBtn.dart';
import 'package:homely_user/Helper/String.dart';
import 'package:homely_user/Helper/app_assets.dart';
import 'package:homely_user/Model/Model.dart';
import 'package:homely_user/Model/Section_Model.dart';
import 'package:homely_user/Provider/CartProvider.dart';
import 'package:homely_user/Provider/CategoryProvider.dart';
import 'package:homely_user/Provider/FavoriteProvider.dart';
import 'package:homely_user/Provider/HomeProvider.dart';
import 'package:homely_user/Provider/SettingProvider.dart';
import 'package:homely_user/Provider/UserProvider.dart';
import 'package:homely_user/Screen/SellerList.dart';
import 'package:homely_user/Screen/SubCategory.dart';

import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart';
import 'package:package_info/package_info.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:version/version.dart';

import 'Login.dart';
import 'Manage_Address.dart';
import 'ProductList.dart';
import 'Product_Detail.dart';

import 'SectionList.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

ApiBaseHelper apiBaseHelper = ApiBaseHelper();

class _HomePageState extends State<HomePage>
    with AutomaticKeepAliveClientMixin<HomePage>, TickerProviderStateMixin {
  bool _isNetworkAvail = true;
  List<Product> todayCatList = [];
  List<Model> homeSliderList = [];
  List<Widget> pages = [];

  final _controller = PageController();
  late Animation buttonSqueezeanimation;
  late AnimationController buttonController;
  final GlobalKey<FormState> _formkey = GlobalKey<FormState>();
  List<Model> offerImages = [];
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey =
      new GlobalKey<RefreshIndicatorState>();
  var pinController = TextEditingController();
  var currentAddress = TextEditingController();
  var latitude;
  var longitude;
  int currentindex = 0;
  Future<void> getCurrentLoc() async {
    LocationPermission permission;
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      print("checking permission here ${permission}");
      if (permission == LocationPermission.deniedForever) {
        return Future.error('Location Not Available');
      }
    }
    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
    var loc = Provider.of<LocationProvider>(context, listen: false);

    latitude = position.latitude.toString();
    longitude = position.longitude.toString();
    List<Placemark> placemark = await placemarkFromCoordinates(
        double.parse(latitude!), double.parse(longitude!),
        localeIdentifier: "en");

    pinController.text = placemark[0].postalCode!;
    if (mounted) {
      setState(() {
        pinController.text = placemark[0].postalCode!;
        zipCode = placemark[0].postalCode!;
        currentAddress.text =
            "${placemark[0].street}, ${placemark[0].subLocality}, ${placemark[0].locality}";
        latitude = position.latitude.toString();
        longitude = position.longitude.toString();
        loc.lng = position.longitude.toString();
        loc.lat = position.latitude.toString();
        checkServiceAvailable();
      });
    }
  }
  bool checkService = false;
  checkServiceAvailable()async{
    UserProvider user = Provider.of<UserProvider>(context, listen: false);
    SettingProvider setting =
    Provider.of<SettingProvider>(context, listen: false);
    user.setUserId(setting.userId);
    CUR_USERID = context.read<SettingProvider>().userId;
    var response = await apiBaseHelper.postAPICall(Uri.parse("${baseUrl}check_availabily"), {});
      if(!response['error']){
        checkService = true;
          _refresh();
      }else{
        setState(() {
          checkService = false;
        });
        getSetting();
        showServiceScreen(context,(result)async{
                  if(result!=null){
                    var data = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (BuildContext context) => ManageAddress(
                            home: false,
                            fromBar: true,
                          ),
                        ));
                    if(data==null){
                      checkServiceAvailable();
                    }else{
                      setState(() {
                        print("checking address data here now ${data}");
                        currentAddress.text = data['address'].toString();
                      });
                      latitude = data['lati'].toString();
                      longitude = data['longi'].toString();
                      zipCode = data['zipcode'].toString();
                      var loc = Provider.of<LocationProvider>(context, listen: false);
                      loc.lat = latitude ;
                      loc.lng = longitude ;
                      checkServiceAvailable();
                    }

                  }
                });
      }
  }

  bool _isLoading = true;
  String sortBy = 'p.id', orderBy = "DESC";
  String minPrice = "0", maxPrice = "0";
  List<Product> tempList = [];
  bool _isFirstLoad = true;
  var filterList;
  bool isLoadingmore = true;
  List<Product> productList = [];
  RangeValues? _currentRangeValues;
  void getProduct(String top, String id) {
    print("sub cat id here ${id}");
    //_currentRangeValues.start.round().toString(),
    // _currentRangeValues.end.round().toString(),
    Map parameter = {
      SORT: sortBy,
      ORDER: orderBy,
      SUB_CAT_ID: id,
      LIMIT: perPage.toString(),
      OFFSET: "0",
      'type': "1",
      TOP_RETAED: top,
      //'indicator': fType == "null" || fType == null ? "0" : fType.toString()
    };

    parameter["seller_id"] = "";

    if (CUR_USERID != null) parameter[USER_ID] = CUR_USERID!;

    parameter[DISCOUNT] = "";
    print("new paremters here $parameter and $getProductApi");
    apiBaseHelper.postAPICall(getProductApi, parameter).then((getdata) {
      bool error = getdata["error"];
      String? msg = getdata["message"];
      setState(() {
        tempList.clear();
      });
      if (error == false) {
        total = int.parse(getdata["total"]);

        if (_isFirstLoad) {
          filterList = getdata["filters"];

          minPrice = getdata[MINPRICE];
          maxPrice = getdata[MAXPRICE];
          _currentRangeValues =
              RangeValues(double.parse(minPrice), double.parse(maxPrice));
          _isFirstLoad = false;
        }

        //   if ((offset) < total) {

        setState(() {});
        tempList.clear();
        var data = getdata["data"];
        tempList = (data as List).map((data) => new Product.fromJson(data)).toList();
        if (getdata.containsKey(TAG)) {
          List<String> tempList = List<String>.from(getdata[TAG]);
          if (tempList != null && tempList.length > 0) tagList = tempList;
        }

        getAvailVarient();

        offset = offset + perPage;
        // } else {
        //   if (msg != "Products Not Found !") setSnackbar(msg!, context);
        //   isLoadingmore = false;
        // }
      } else {
        setState(() {
          tempList.clear();
        });
        // getAvailVarient();
        isLoadingmore = false;
        if (msg != "Products Not Found !") setSnackbar(msg!, context);
      }

      setState(() {
        _isLoading = false;
      });
      // context.read<ProductListProvider>().setProductLoading(false);
    }, onError: (error) {
      setSnackbar(error.toString(), context);
      setState(() {
        _isLoading = false;
      });
      //context.read<ProductListProvider>().setProductLoading(false);
    });
  }
  void getAvailVarient() {
    productList.clear();
    print("variant data here now ");
    for (int j = 0; j < tempList.length; j++) {
      if (tempList[j].stockType == "2") {
        for (int i = 0; i < tempList[j].prVarientList!.length; i++) {
          if (tempList[j].prVarientList![i].availability == "1") {
            tempList[j].selVarient = i;
            break;
          }
        }
      }
    }
    productList.addAll(tempList);
    print(
        "checking product list here now ${productList.length} and ${productList[0].desc}");
  }

  //String? curPin;

  topRatedRestaurent() async {
    topSellerList.clear();
    Map parameter = {
      "lat": "$latitude",
      "lang": "$longitude",
    };
    print(parameter);
    // if (pin != '') {
    //   parameter = {
    //     "lat":"$latitude",
    //     "lang":"$longitude"
    //   };
    //   print(latitude);
    //   print(longitude);
    // }

    apiBaseHelper.postAPICall(getTopRatedSeller, parameter).then((getdata) {
      bool error = getdata["error"];
      String? msg = getdata["message"];
      print(getSellerApi);
      print(parameter.toString());
      if (!error) {
        var data = getdata["data"];
        topSellerList =
            (data as List).map((data) => new Product.fromSeller(data)).toList();
        setState(() {
          topSellerList.sort((a, b) => b.online!.compareTo(a.online!));
        });
      } else {
        // setSnackbar(msg!, context);
      }

      context.read<HomeProvider>().setSellerLoading(false);
    }, onError: (error) {
      //  setSnackbar(error.toString(), context);
      context.read<HomeProvider>().setSellerLoading(false);
    });
  }

  sponsorRestaurants() async {
    sponsorSellerList.clear();
    Map parameter = {
      "lat": "$latitude",
      "lang": "$longitude",
      "type": "sponser"
    };
    print(parameter);
    // if (pin != '') {
    //   parameter = {
    //     "lat":"$latitude",
    //     "lang":"$longitude"
    //   };
    //   print(latitude);
    //   print(longitude);
    // }

    apiBaseHelper.postAPICall(getTopRatedSeller, parameter).then((getdata) {
      bool error = getdata["error"];
      String? msg = getdata["message"];
      print(getSellerApi);
      print(parameter.toString());
      if (!error) {
        var data = getdata["data"];
        sponsorSellerList =
            (data as List).map((data) => new Product.fromSeller(data)).toList();
        setState(() {
          sponsorSellerList.sort((a, b) => b.online!.compareTo(a.online!));
        });
      } else {
        //  setSnackbar(msg!, context);
      }

      context.read<HomeProvider>().setSellerLoading(false);
    }, onError: (error) {
      // setSnackbar(error.toString(), context);
      context.read<HomeProvider>().setSellerLoading(false);
    });
  }

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    getCurrentLoc();
    getTodayCat();
    buttonController = new AnimationController(duration: new Duration(milliseconds: 2000), vsync: this);
    buttonSqueezeanimation = new Tween(
      begin: deviceWidth! * 0.7,
      end: 50.0,
    ).animate(
      new CurvedAnimation(
        parent: buttonController,
        curve: new Interval(
          0.0,
          0.150,
        ),
      ),
    );
    WidgetsBinding.instance!.addPostFrameCallback((_) => _animateSlider());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isNetworkAvail
          ? RefreshIndicator(
              color: colors.primary,
              key: _refreshIndicatorKey,
              onRefresh: _refresh,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: EdgeInsets.only(top: 10, left: 10, right: 10),
                      child: _deliverPincode(),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(
                          left: 8, right: 8, top: 10, bottom: 0),
                      child: _slider(),
                    ),
                    // Padding(
                    //   padding: EdgeInsets.only(left: 10),
                    //   child: Text(
                    //     "Categories",
                    //     style: TextStyle(
                    //         color: Colors.black,
                    //         fontSize: 15,
                    //         fontWeight: FontWeight.w600),
                    //   ),
                    // ),
                    _catList(),
                     //// Today Special Section ////////////////////
                    ///
                    Padding(
                      padding: const EdgeInsets.only(left: 12, top: 16, bottom: 10),
                      child: Text(
                        "Today Special",
                        style: TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w600),
                      ),
                    ),
                    todayCatWidget(),
                    _seller(),
                    _topSeller(),
                    /*Padding(
                      padding:
                      const EdgeInsets.only(left: 12, top: 10, bottom: 10),
                      child: Text(
                        "Subscription",
                        style: TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w600),
                      ),
                    ),
                    Container(
                      height: 190,
                      width: MediaQuery.of(context).size.width,
                      child: productList == null
                          ? Center(
                        child: CircularProgressIndicator(),
                      )
                          : ListView.builder(
                          padding: EdgeInsets.symmetric(horizontal: 12),
                          shrinkWrap: true,
                          itemCount: productList.length,
                          scrollDirection: Axis.horizontal,
                          itemBuilder: (c, i) {
                            return InkWell(
                              onTap: () {
                                Product model = productList[i];
                                Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) => ProductDetail(
                                          model: model,
                                          sellerId: productList[i]
                                              .seller_id
                                              .toString(),
                                          index: i,
                                          preQty: 1,
                                          secPos: 0,
                                          list: true,
                                        )));
                              },
                              child: Container(
                                margin: EdgeInsets.only(right: 10),
                                decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(8)),
                                child: Column(
                                  crossAxisAlignment:
                                  CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                        decoration: BoxDecoration(
                                            borderRadius:
                                            BorderRadius.circular(8)),
                                        height: 120,
                                        width: MediaQuery.of(context)
                                            .size
                                            .width /
                                            2,
                                        child: ClipRRect(
                                          borderRadius:
                                          BorderRadius.circular(8),
                                          child: Image.network(
                                            "${productList[i].image}",
                                            fit: BoxFit.cover,
                                          ),
                                        )),
                                    Padding(
                                      padding: EdgeInsets.only(
                                          left: 5, right: 3, top: 2),
                                      child: Text(
                                        "${productList[i].name}",
                                        style: TextStyle(
                                            fontWeight: FontWeight.w600),
                                      ),
                                    ),
                                    Padding(
                                      padding: EdgeInsets.only(
                                          left: 5, right: 3, top: 2),
                                      child: Text(
                                        "${productList[i].store_name}",
                                        style: TextStyle(fontSize: 12),
                                      ),
                                    ),
                                    SizedBox(
                                      height: 5,
                                    ),
                                    Padding(
                                      padding: EdgeInsets.only(
                                          left: 5, right: 5),
                                      child: productList[i]
                                          .prVarientList![0]
                                          .disPrice ==
                                          "0" ||
                                          productList[i]
                                              .prVarientList![0]
                                              .disPrice ==
                                              0 ||
                                          productList[i]
                                              .prVarientList![0]
                                              .disPrice ==
                                              ""
                                          ? Text(
                                        "\u{20B9} ${productList[i].prVarientList![0].price}",
                                        style: TextStyle(
                                            fontWeight:
                                            FontWeight.w600),
                                      )
                                          : Row(
                                        children: [
                                          Text(
                                            "\u{20B9} ${productList[i].prVarientList![0].price}",
                                            style: TextStyle(
                                                decoration:
                                                TextDecoration
                                                    .lineThrough,
                                                fontWeight:
                                                FontWeight.w500),
                                          ),
                                          SizedBox(
                                            width: 10,
                                          ),
                                          Text(
                                            "\u{20B9} ${productList[i].prVarientList![0].disPrice}",
                                            style: TextStyle(
                                                color: Colors.black,
                                                fontWeight:
                                                FontWeight.bold),
                                          ),
                                        ],
                                      ),
                                    )
                                  ],
                                ),
                              ),
                            );
                          }),
                    ),*/
                    // _sponsorSeller(),
                    // _section(),
                  ],
                ),
              ),
            )
          : noInternet(context),
    );
  }

  Future<Null> _refresh() {
    context.read<HomeProvider>().setCatLoading(true);
    context.read<HomeProvider>().setSecLoading(true);
    context.read<HomeProvider>().setSliderLoading(true);
    CUR_USERID = context.read<SettingProvider>().userId;
    return callApi();
  }

  // Widget _slider() {
  //   double height = deviceWidth! / 2.2;

  //   return Selector<HomeProvider, bool>(
  //     builder: (context, data, child) {
  //       return data
  //           ? sliderLoading()
  //           : Card(
  //               elevation: 5,
  //               shape: RoundedRectangleBorder(
  //                   borderRadius: BorderRadius.circular(15)),
  //               child: ClipRRect(
  //                 borderRadius: BorderRadius.circular(15),
  //                 child: Stack(
  //                   children: [
  //                     Container(
  //                       height: height,
  //                       width: double.infinity,
  //                       // margin: EdgeInsetsDirectional.only(top: 10),
  //                       child: PageView.builder(
  //                         reverse: false,
  //                         itemCount: homeSliderList.length,
  //                         scrollDirection: Axis.horizontal,
  //                         controller: _controller,
  //                         physics: AlwaysScrollableScrollPhysics(),
  //                         onPageChanged: (index) {
  //                           context.read<HomeProvider>().setCurSlider(index);
  //                         },
  //                         itemBuilder: (BuildContext context, int index) {
  //                           return pages[index];
  //                         },
  //                       ),
  //                     ),
  //                     Positioned(
  //                       bottom: 0,
  //                       height: 40,
  //                       left: 0,
  //                       width: deviceWidth,
  //                       child: Row(
  //                         mainAxisSize: MainAxisSize.max,
  //                         mainAxisAlignment: MainAxisAlignment.center,
  //                         children: map<Widget>(
  //                           homeSliderList,
  //                           (index, url) {
  //                             return Container(
  //                                 width: 8.0,
  //                                 height: 8.0,
  //                                 margin: EdgeInsets.symmetric(
  //                                     vertical: 10.0, horizontal: 2.0),
  //                                 decoration: BoxDecoration(
  //                                   shape: BoxShape.circle,
  //                                   color: context
  //                                               .read<HomeProvider>()
  //                                               .curSlider ==
  //                                           index
  //                                       ? Colors.grey
  //                                       : Theme.of(context)
  //                                           .colorScheme
  //                                           .lightBlack,
  //                                 ));
  //                           },
  //                         ),
  //                       ),
  //                     ),
  //                   ],
  //                 ),
  //               ),
  //             );
  //     },
  //     selector: (_, homeProvider) => homeProvider.sliderLoading,
  //   );
  // }

  Widget _slider() {
    double height = deviceWidth! / 2.2;
    return Selector<HomeProvider, bool>(
      builder: (context, data, child) {
        return data
            ? sliderLoading()
            : ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: Column(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(15)),
                      height: height,
                      width: double.infinity,
                      child: CarouselSlider(
                        options: CarouselOptions(
                          viewportFraction: 1,
                          initialPage: 0,
                          enableInfiniteScroll: true,
                          reverse: false,
                          autoPlay: true,
                          autoPlayInterval: Duration(seconds: 3),
                          autoPlayAnimationDuration:
                              Duration(milliseconds: 1200),
                          autoPlayCurve: Curves.fastOutSlowIn,
                          enlargeCenterPage: true,
                          scrollDirection: Axis.horizontal,
                          height: height,
                          onPageChanged: (position, reason) {
                            setState(() {
                              currentindex = position;
                            });
                            print(reason);
                            print(CarouselPageChangedReason.controller);
                          },
                        ),
                        items: homeSliderList.map((val) {
                          return InkWell(
                            onTap: () {
                              print("sfsfsfsfsfsfsfs ${val.type}");
                              int curSlider =
                                  context.read<HomeProvider>().curSlider;
                              print(
                                  "working here now on the first here ${homeSliderList[curSlider].type}");

                              if (homeSliderList[curSlider].type ==
                                  "products") {
                                Product? item = homeSliderList[curSlider].list;

                                Navigator.push(
                                  context,
                                  PageRouteBuilder(
                                      pageBuilder: (_, __, ___) =>
                                          ProductDetail(
                                              model: item,
                                              secPos: 0,
                                              index: 0,
                                              list: true)),
                                );
                              } else if (homeSliderList[curSlider].type ==
                                  "categories") {
                                Product item = homeSliderList[curSlider].list;
                                if (item.subList == null ||
                                    item.subList!.length == 0) {
                                  Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => ProductList(
                                          name: item.name,
                                          id: item.id,
                                          tag: false,
                                          fromSeller: false,
                                        ),
                                      ));
                                } else {
                                  Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => SubCategory(
                                          fromSearch: false,
                                          title: item.name!,
                                        ),
                                      ));
                                }
                              }
                              // if (homeSliderList[currentindex].type ==
                              //     "restaurants") {
                              //   print(homeSliderList[currentindex].list);
                              //   if (homeSliderList[currentindex].list!=null) {
                              //     var item =
                              //         homeSliderList[currentindex].list;
                              //     // Navigator.push(
                              //     //     context,
                              //     //     MaterialPageRoute(
                              //     //         builder: (context) => SellerProfile(
                              //     //           title: item.store_name.toString(),
                              //     //           sellerID: item.seller_id.toString(),
                              //     //           sellerId: item.seller_id.toString(),
                              //     //           sellerData: item,
                              //     //           userLocation: currentAddress.text,
                              //     //           // catId: widget.catId,
                              //     //           shop: false,
                              //     //         )));
                              //     /*Navigator.push(
                              //             context,
                              //             PageRouteBuilder(
                              //                 pageBuilder: (, _, ___) =>
                              //                     ProductDetail(
                              //                         model: item,
                              //                         secPos: 0,
                              //                         index: 0,
                              //                         list: true)),
                              //           );*/
                              //   }
                              // } else if (homeSliderList[currentindex].type ==
                              //     "categories") {
                              //   var item = homeSliderList[currentindex].list;
                              //   Navigator.push(
                              //       context,
                              //       MaterialPageRoute(
                              //           builder: (context) => SellerList(
                              //             catId: item.categoryId,
                              //             catName: item.name,
                              //             userLocation:
                              //             currentAddress.text,
                              //             getByLocation: true,
                              //           )));
                              // }
                            },
                            child: Container(
                              width: MediaQuery.of(context).size.width,
                              child: ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: Image.network(
                                    "${val.image}",
                                    fit: BoxFit.fill,
                                  )),
                            ),
                          );
                        }).toList(),
                      ),
                      // margin: EdgeInsetsDirectional.only(top: 10),
                      // child: PageView.builder(
                      //   itemCount: homeSliderList.length,
                      //   scrollDirection: Axis.horizontal,
                      //   controller: _controller,
                      //   pageSnapping: true,
                      //   physics: AlwaysScrollableScrollPhysics(),
                      //   onPageChanged: (index) {
                      //     context.read<HomeProvider>().setCurSlider(index);
                      //   },
                      //   itemBuilder: (BuildContext context, int index) {
                      //     return pages[index];
                      //   },
                      // ),
                    ),
                    Row(
                        mainAxisSize: MainAxisSize.max,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: homeSliderList.map((e) {
                          int index = homeSliderList.indexOf(e);
                          return Container(
                              width: 8.0,
                              height: 8.0,
                              margin: EdgeInsets.symmetric(
                                  vertical: 10.0, horizontal: 2.0),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: currentindex == index
                                    ? Theme.of(context).colorScheme.fontColor
                                    : Theme.of(context).colorScheme.lightBlack,
                              ));
                        }).toList()),
                  ],
                ),
              );
      },
      selector: (_, homeProvider) => homeProvider.sliderLoading,
    );
  }

  void _animateSlider() {
    Future.delayed(Duration(seconds: 5)).then(
      (_) {
        if (mounted) {
          int nextPage = _controller.hasClients
              ? _controller.page!.round() + 1
              : _controller.initialPage;

          if (nextPage == homeSliderList.length) {
            nextPage = 0;
          }
          if (_controller.hasClients)
            _controller
                .animateToPage(nextPage,
                    duration: Duration(milliseconds: 500), curve: Curves.linear)
                .then((_) => _animateSlider());
        }
      },
    );
  }

  _singleSection(int index) {
    Color back;
    int pos = index % 5;
    if (pos == 0)
      back = Theme.of(context).colorScheme.back1;
    else if (pos == 1)
      back = Theme.of(context).colorScheme.back2;
    else if (pos == 2)
      back = Theme.of(context).colorScheme.back3;
    else if (pos == 3)
      back = Theme.of(context).colorScheme.back4;
    else
      back = Theme.of(context).colorScheme.back5;

    return sectionList[index].productList!.length > 0
        ? Container(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.only(top: 0.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      _getHeading(sectionList[index].title ?? "", index),
                      _getSection(index),
                    ],
                  ),
                ),
                offerImages.length > index
                    ? _getOfferImage(index)
                    : Container(),
              ],
            ),
          )
        : Container();
  }

  _getHeading(String title, int index) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Padding(
        //   padding: const EdgeInsets.only(right: 20.0),
        //   child: Stack(
        //     clipBehavior: Clip.none,
        //     alignment: Alignment.centerRight,
        //     children: <Widget>[
        //       Container(
        //         decoration: BoxDecoration(
        //           borderRadius: BorderRadius.only(
        //             topLeft: Radius.circular(20),
        //             topRight: Radius.circular(20),
        //           ),
        //           color: colors.yellow,
        //         ),
        //         padding: EdgeInsetsDirectional.only(
        //             start: 10, bottom: 3, top: 3, end: 10),
        //         child: Text(
        //           "${title}sssds",
        //           style: Theme.of(context)
        //               .textTheme
        //               .subtitle2!
        //               .copyWith(color: colors.blackTemp),
        //           maxLines: 1,
        //           overflow: TextOverflow.ellipsis,
        //         ),
        //       ),
        //       /*   Positioned(
        //           // clipBehavior: Clip.hardEdge,
        //           // margin: EdgeInsets.symmetric(horizontal: 20),

        //           right: -14,
        //           child: SvgPicture.asset("assets/images/eshop.svg"))*/
        //     ],
        //   ),
        // ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 0.0, horizontal: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(sectionList[index].shortDesc ?? "",
                    style: Theme.of(context).textTheme.subtitle1!.copyWith(
                        color: Theme.of(context).colorScheme.fontColor)),
              ),
              TextButton(
                style: TextButton.styleFrom(
                    minimumSize: Size.zero, // <
                    backgroundColor: (Theme.of(context).colorScheme.white),
                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5)),
                child: Text(
                  getTranslated(context, 'SHOP_NOW')!,
                  style: Theme.of(context).textTheme.caption!.copyWith(
                      color: Theme.of(context).colorScheme.fontColor,
                      fontWeight: FontWeight.bold),
                ),
                onPressed: () {
                  SectionModel model = sectionList[index];
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => SectionList(
                        index: index,
                        section_model: model,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  _getOfferImage(index) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10.0),
      child: InkWell(
        child: FadeInImage(
            fadeInDuration: Duration(milliseconds: 150),
            image: CachedNetworkImageProvider(offerImages[index].image!),
            width: double.maxFinite,
            imageErrorBuilder: (context, error, stackTrace) => erroWidget(50),

            // errorWidget: (context, url, e) => placeHolder(50),
            placeholder: AssetImage(
              "assets/images/sliderph.png",
            )),
        onTap: () {
          if (offerImages[index].type == "products") {
            Product? item = offerImages[index].list;

            Navigator.push(
              context,
              PageRouteBuilder(
                  //transitionDuration: Duration(seconds: 1),
                  pageBuilder: (_, __, ___) =>
                      ProductDetail(model: item, secPos: 0, index: 0, list: true
                          //  title: sectionList[secPos].title,
                          )),
            );
          } else if (offerImages[index].type == "categories") {
            Product item = offerImages[index].list;
            if (item.subList == null || item.subList!.length == 0) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ProductList(
                    name: item.name,
                    id: item.id,
                    tag: false,
                    fromSeller: false,
                  ),
                ),
              );
            } else {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SubCategory(
                    fromSearch: false,
                    title: item.name!,
                    // sellerId: item
                  ),
                ),
              );
            }
          }
        },
      ),
    );
  }

  _getSection(int i) {
    var orient = MediaQuery.of(context).orientation;

    return sectionList[i].style == DEFAULT
        ? Padding(
            padding: const EdgeInsets.all(15.0),
            child: GridView.count(
              // mainAxisSpacing: 12,
              // crossAxisSpacing: 12,
              padding: EdgeInsetsDirectional.only(top: 5),
              crossAxisCount: 2,
              shrinkWrap: true,
              childAspectRatio: 0.750,

              //  childAspectRatio: 1.0,
              physics: NeverScrollableScrollPhysics(),
              children:
                  //  [
                  //   Container(height: 500, width: 1200, color: Colors.red),
                  //   Text("hello"),
                  //   Container(height: 10, width: 50, color: Colors.green),
                  // ]
                  List.generate(
                sectionList[i].productList!.length < 4
                    ? sectionList[i].productList!.length
                    : 4,
                (index) {
                  // return Container(
                  //   width: 600,
                  //   height: 50,
                  //   color: Colors.red,
                  // );

                  return productItem(i, index, index % 2 == 0 ? true : false);
                },
              ),
            ),
          )
        : sectionList[i].style == STYLE1
            ? sectionList[i].productList!.length > 0
                ? Padding(
                    padding: const EdgeInsets.all(15.0),
                    child: Row(
                      children: [
                        Flexible(
                            flex: 3,
                            fit: FlexFit.loose,
                            child: Container(
                                height: orient == Orientation.portrait
                                    ? deviceHeight! * 0.4
                                    : deviceHeight!,
                                child: productItem(i, 0, true))),
                        Flexible(
                          flex: 2,
                          fit: FlexFit.loose,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                  height: orient == Orientation.portrait
                                      ? deviceHeight! * 0.2
                                      : deviceHeight! * 0.5,
                                  child: productItem(i, 1, false)),
                              Container(
                                  height: orient == Orientation.portrait
                                      ? deviceHeight! * 0.2
                                      : deviceHeight! * 0.5,
                                  child: productItem(i, 2, false)),
                            ],
                          ),
                        ),
                      ],
                    ))
                : Container()
            : sectionList[i].style == STYLE2
                ? Padding(
                    padding: const EdgeInsets.all(15.0),
                    child: Row(
                      children: [
                        Flexible(
                          flex: 2,
                          fit: FlexFit.loose,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                  height: orient == Orientation.portrait
                                      ? deviceHeight! * 0.2
                                      : deviceHeight! * 0.5,
                                  child: productItem(i, 0, true)),
                              Container(
                                  height: orient == Orientation.portrait
                                      ? deviceHeight! * 0.2
                                      : deviceHeight! * 0.5,
                                  child: productItem(i, 1, true)),
                            ],
                          ),
                        ),
                        Flexible(
                            flex: 3,
                            fit: FlexFit.loose,
                            child: Container(
                                height: orient == Orientation.portrait
                                    ? deviceHeight! * 0.4
                                    : deviceHeight,
                                child: productItem(i, 2, false))),
                      ],
                    ))
                : sectionList[i].style == STYLE3
                    ? Padding(
                        padding: const EdgeInsets.all(15.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Flexible(
                                flex: 1,
                                fit: FlexFit.loose,
                                child: Container(
                                    height: orient == Orientation.portrait
                                        ? deviceHeight! * 0.3
                                        : deviceHeight! * 0.6,
                                    child: productItem(i, 0, false))),
                            Container(
                              height: orient == Orientation.portrait
                                  ? deviceHeight! * 0.2
                                  : deviceHeight! * 0.5,
                              child: Row(
                                children: [
                                  Flexible(
                                      flex: 1,
                                      fit: FlexFit.loose,
                                      child: productItem(i, 1, true)),
                                  Flexible(
                                      flex: 1,
                                      fit: FlexFit.loose,
                                      child: productItem(i, 2, true)),
                                  Flexible(
                                      flex: 1,
                                      fit: FlexFit.loose,
                                      child: productItem(i, 3, false)),
                                ],
                              ),
                            ),
                          ],
                        ))
                    : sectionList[i].style == STYLE4
                        ? Padding(
                            padding: const EdgeInsets.all(15.0),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Flexible(
                                    flex: 1,
                                    fit: FlexFit.loose,
                                    child: Container(
                                        height: orient == Orientation.portrait
                                            ? deviceHeight! * 0.25
                                            : deviceHeight! * 0.5,
                                        child: productItem(i, 0, false))),
                                Container(
                                  height: orient == Orientation.portrait
                                      ? deviceHeight! * 0.2
                                      : deviceHeight! * 0.5,
                                  child: Row(
                                    children: [
                                      Flexible(
                                          flex: 1,
                                          fit: FlexFit.loose,
                                          child: productItem(i, 1, true)),
                                      Flexible(
                                          flex: 1,
                                          fit: FlexFit.loose,
                                          child: productItem(i, 2, false)),
                                    ],
                                  ),
                                ),
                              ],
                            ))
                        : Padding(
                            padding: const EdgeInsets.all(15.0),
                            child: GridView.count(
                                padding: EdgeInsetsDirectional.only(top: 5),
                                crossAxisCount: 2,
                                shrinkWrap: true,
                                childAspectRatio: 1.2,
                                physics: NeverScrollableScrollPhysics(),
                                mainAxisSpacing: 0,
                                crossAxisSpacing: 0,
                                children: List.generate(
                                  sectionList[i].productList!.length < 6
                                      ? sectionList[i].productList!.length
                                      : 6,
                                  (index) {
                                    return productItem(i, index,
                                        index % 2 == 0 ? true : false);
                                  },
                                )));
  }

  Widget productItem(int secPos, int index, bool pad) {
    if (sectionList[secPos].productList!.length > index) {
      String? offPer;
      double price = double.parse(
          sectionList[secPos].productList![index].prVarientList![0].disPrice!);
      if (price == 0) {
        price = double.parse(
            sectionList[secPos].productList![index].prVarientList![0].price!);
      } else {
        double off = double.parse(sectionList[secPos]
                .productList![index]
                .prVarientList![0]
                .price!) -
            price;
        offPer = ((off * 100) /
                double.parse(sectionList[secPos]
                    .productList![index]
                    .prVarientList![0]
                    .price!))
            .toStringAsFixed(2);
      }

      double width = deviceWidth! * 0.5;

      return Card(
        elevation: 0.0,

        margin: EdgeInsetsDirectional.only(bottom: 2, end: 2),
        //end: pad ? 5 : 0),
        child: InkWell(
          borderRadius: BorderRadius.circular(4),
          child: Container(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Expanded(
                  /*       child: ClipRRect(
                      borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(5),
                          topRight: Radius.circular(5)),
                      child: Hero(
                        tag:
                        "${sectionList[secPos].productList![index].id}$secPos$index",
                        child: FadeInImage(
                          fadeInDuration: Duration(milliseconds: 150),
                          image: NetworkImage(
                              sectionList[secPos].productList![index].image!),
                          height: double.maxFinite,
                          width: double.maxFinite,
                          fit: extendImg ? BoxFit.fill : BoxFit.contain,
                          imageErrorBuilder: (context, error, stackTrace) =>
                              erroWidget(width),

                          // errorWidget: (context, url, e) => placeHolder(width),
                          placeholder: placeHolder(width),
                        ),
                      )),*/
                  child: Stack(
                    alignment: Alignment.topRight,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(5),
                            topRight: Radius.circular(5)),
                        child: Hero(
                          transitionOnUserGestures: true,
                          tag:
                              "${sectionList[secPos].productList![index].id}$secPos$index",
                          child: FadeInImage(
                            fadeInDuration: Duration(milliseconds: 150),
                            image: CachedNetworkImageProvider(
                                sectionList[secPos].productList![index].image!),
                            height: double.maxFinite,
                            width: double.maxFinite,
                            imageErrorBuilder: (context, error, stackTrace) =>
                                erroWidget(double.maxFinite),
                            fit: BoxFit.cover,
                            placeholder: placeHolder(width),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsetsDirectional.only(
                    start: 5.0,
                    top: 3,
                  ),
                  child: Text(
                    sectionList[secPos].productList![index].name!,
                    style: Theme.of(context).textTheme.caption!.copyWith(
                        color: Theme.of(context).colorScheme.lightBlack),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  " " + CUR_CURRENCY! + " " + price.toString(),
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.fontColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Padding(
                  padding: const EdgeInsetsDirectional.only(
                      start: 5.0, bottom: 5, top: 3),
                  child: double.parse(sectionList[secPos]
                              .productList![index]
                              .prVarientList![0]
                              .disPrice!) !=
                          0
                      ? Row(
                          children: <Widget>[
                            Text(
                              double.parse(sectionList[secPos]
                                          .productList![index]
                                          .prVarientList![0]
                                          .disPrice!) !=
                                      0
                                  ? CUR_CURRENCY! +
                                      "" +
                                      sectionList[secPos]
                                          .productList![index]
                                          .prVarientList![0]
                                          .price!
                                  : "",
                              style: Theme.of(context)
                                  .textTheme
                                  .overline!
                                  .copyWith(
                                      decoration: TextDecoration.lineThrough,
                                      letterSpacing: 0),
                            ),
                            Flexible(
                              child: Text(" | " + "-$offPer%",
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context)
                                      .textTheme
                                      .overline!
                                      .copyWith(
                                          color: colors.primary,
                                          letterSpacing: 0)),
                            ),
                          ],
                        )
                      : Container(
                          height: 5,
                        ),
                )
              ],
            ),
          ),
          onTap: () {
            Product model = sectionList[secPos].productList![index];
            print(
                "final seller id checking here ${model.seller_id.toString()}");
            Navigator.push(
              context,
              PageRouteBuilder(
                // transitionDuration: Duration(milliseconds: 150),
                pageBuilder: (_, __, ___) => ProductDetail(
                    sellerId: model.seller_id.toString(),
                    model: model,
                    secPos: secPos,
                    index: index,
                    list: false
                    //  title: sectionList[secPos].title,
                    ),
              ),
            );
          },
        ),
      );
    } else
      return Container();
  }

  _section() {
    return Selector<HomeProvider, bool>(
      builder: (context, data, child) {
        return data
            ? Container(
                width: double.infinity,
                child: Shimmer.fromColors(
                  baseColor: Theme.of(context).colorScheme.simmerBase,
                  highlightColor: Theme.of(context).colorScheme.simmerHigh,
                  child: sectionLoading(),
                ),
              )
            : ListView.builder(
                padding: EdgeInsets.all(0),
                itemCount: sectionList.length,
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                itemBuilder: (context, index) {
                  print("here");
                  return _singleSection(index);
                },
              );
      },
      selector: (_, homeProvider) => homeProvider.secLoading,
    );
  }

  todayCatWidget() {
    return Selector<HomeProvider, bool>(
      builder: (context, data, child) {
        return data
            ? Container(
            width: double.infinity,
            child: Shimmer.fromColors(
                baseColor: Theme.of(context).colorScheme.simmerBase,
                highlightColor: Theme.of(context).colorScheme.simmerHigh,
                child: catLoading(),
             ),
            ) :
            todayCatList.length == 0
            ? Container(
           height: 120,
           width: double.infinity,
              child: Center(
              child: Text("No Today Special To Show"),
             ),
            ):
         Container(
          height: 150,
          padding: const EdgeInsets.only( left: 10),
          child: ListView.builder(
            itemCount: todayCatList.length,
            scrollDirection: Axis.horizontal,
            shrinkWrap: true,
            physics: AlwaysScrollableScrollPhysics(),
            itemBuilder: (context, index) {
              // if (index == 0)
              //   return Container();
              // else
              return GestureDetector(
                onTap: () async {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => SellerList(
                            catId: todayCatList[index].id,
                            catName: todayCatList[index].name,
                            subId: todayCatList[index].subList,
                            getByLocation: false,
                            fromSpecial:true,
                          )));
                },
                child: Container(
                  width: 120,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  padding: const EdgeInsets.all(8.0),
                  margin: const EdgeInsetsDirectional.only(end: 10),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Padding(
                        padding: const EdgeInsetsDirectional.only(
                            bottom: 5.0),
                        child: new ClipRRect(
                          borderRadius: BorderRadius.circular(8.0),
                          child: new FadeInImage(
                            fadeInDuration: Duration(milliseconds: 150),
                            image: CachedNetworkImageProvider(
                              todayCatList[index].image!,
                            ),
                            height: 100.0,
                            width: 100.0,
                            fit: BoxFit.cover,
                            imageErrorBuilder: (context, error, stackTrace) => erroWidget(50),
                            placeholder: placeHolder(50),
                          ),
                        ),
                      ),
                      Container(
                        width: 60,
                        alignment: Alignment.center,
                        child: Text(
                          todayCatList[index].name!,
                          style: Theme.of(context).textTheme.caption!.copyWith(color: Theme.of(context).colorScheme.fontColor,
                              fontWeight: FontWeight.w600, fontSize: 10), maxLines: 2, textAlign: TextAlign.center,
                        ),
                        // width: 50,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
      selector: (_, homeProvider) => homeProvider.catLoading,
    );
  }
  _catList() {
    return Selector<HomeProvider, bool>(
      builder: (context, data, child) {
        print("checking data here $data");
        return data
            ? Container(
                width: double.infinity,
                child: Shimmer.fromColors(
                    baseColor: Theme.of(context).colorScheme.simmerBase,
                    highlightColor: Theme.of(context).colorScheme.simmerHigh,
                    child: catLoading()))
            : Container(
                height: 110,
                padding: const EdgeInsets.only(top: 10, left: 10),
                child: ListView.builder(
                  itemCount: catList.length,
                  scrollDirection: Axis.horizontal,
                  shrinkWrap: true,
                  physics: AlwaysScrollableScrollPhysics(),
                  itemBuilder: (context, index) {
                    // if (index == 0)
                    //   return Container();
                    // else
                    return Padding(
                      padding: const EdgeInsetsDirectional.only(end: 10),
                      child: GestureDetector(
                        onTap: () async {
                          // if (catList[index].subList == null ||
                          //     catList[index].subList!.length == 0) {
                          //   await Navigator.push(
                          //       context,
                          //       MaterialPageRoute(
                          //         builder: (context) => ProductList(
                          //           name: catList[index].name,
                          //           id: catList[index].id,
                          //           tag: false,
                          //           fromSeller: false,
                          //         ),
                          //       ));
                          // } else {
                          //   await Navigator.push(
                          //       context,
                          //       MaterialPageRoute(
                          //         builder: (context) => SubCategory(
                          //           title: catList[index].name!,
                          //           subList: catList[index].subList,
                          //         ),
                          //       ));
                          // }
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => SellerList(
                                        catId: catList[index].id,
                                        catName: catList[index].name,
                                        subId: catList[index].subList,
                                        getByLocation: false,
                                      )));
                        },
                        child: Container(
                          width: 60,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              Padding(
                                padding: const EdgeInsetsDirectional.only(
                                    bottom: 5.0),
                                child: new ClipRRect(
                                  borderRadius: BorderRadius.circular(100.0),
                                  child: new FadeInImage(
                                    fadeInDuration: Duration(milliseconds: 150),
                                    image: CachedNetworkImageProvider(
                                      catList[index].image!,
                                    ),
                                    height: 60.0,
                                    width: 60.0,
                                    fit: BoxFit.cover,
                                    imageErrorBuilder:
                                        (context, error, stackTrace) =>
                                            erroWidget(50),
                                    placeholder: placeHolder(50),
                                  ),
                                ),
                              ),
                              Container(
                                width: 60,
                                alignment: Alignment.center,
                                child: Text(
                                  catList[index].name!,
                                  style: Theme.of(context)
                                      .textTheme
                                      .caption!
                                      .copyWith(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .fontColor,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 12),
                                  maxLines: 2,
                                  textAlign: TextAlign.center,
                                ),
                                // width: 50,
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              );
      },
      selector: (_, homeProvider) => homeProvider.catLoading,
    );
  }

  List<T> map<T>(List list, Function handler) {
    List<T> result = [];
    for (var i = 0; i < list.length; i++) {
      result.add(handler(i, list[i]));
    }

    return result;
  }

  Future<Null> callApi() async {
    _isNetworkAvail = await isNetworkAvailable();
    if (_isNetworkAvail) {
      getSetting();
      getSlider();
      getCat();
      getTodayCat();
      getSeller();
      topRatedRestaurent();
      sponsorRestaurants();
      // getSection();
     // getProduct("", "");
       //todaySpecial();
      getOfferImages();
    } else {
      if (mounted)
        setState(() {
          _isNetworkAvail = false;
        });
    }
    return null;
  }

  Future _getFav() async {
    _isNetworkAvail = await isNetworkAvailable();
    if (_isNetworkAvail) {
      if (CUR_USERID != null) {
        Map parameter = {
          USER_ID: CUR_USERID,
        };
        apiBaseHelper.postAPICall(getFavApi, parameter).then((getdata) {
          bool error = getdata["error"];
          String? msg = getdata["message"];
          if (!error) {
            var data = getdata["data"];

            List<Product> tempList = (data as List)
                .map((data) => new Product.fromJson(data))
                .toList();

            context.read<FavoriteProvider>().setFavlist(tempList);
          } else {
            if (msg != 'No Favourite(s) Product Are Added')
              setSnackbar(msg!, context);
          }

          context.read<FavoriteProvider>().setLoading(false);
        }, onError: (error) {
          setSnackbar(error.toString(), context);
          context.read<FavoriteProvider>().setLoading(false);
        });
      } else {
        context.read<FavoriteProvider>().setLoading(false);
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => Login()),
        );
      }
    } else {
      if (mounted)
        setState(() {
          _isNetworkAvail = false;
        });
    }
  }

  void getOfferImages() {
    Map parameter = Map();
    print("get offer image here ${getOfferImageApi} and ${parameter}");
    apiBaseHelper.postAPICall(getOfferImageApi, parameter).then((getdata) {
      bool error = getdata["error"];
      String? msg = getdata["message"];
      if (!error) {
        var data = getdata["data"];
        offerImages.clear();
        offerImages =
            (data as List).map((data) => new Model.fromSlider(data)).toList();
      } else {
        setSnackbar(msg!, context);
      }

      context.read<HomeProvider>().setOfferLoading(false);
    }, onError: (error) {
      setSnackbar(error.toString(), context);
      context.read<HomeProvider>().setOfferLoading(false);
    });
  }

  void getSection() {
    print("section>>>>>>>>>>>>>>>>>>>>>>>>>");
    Map parameter = {PRODUCT_LIMIT: "6", PRODUCT_OFFSET: "10"};

    if (CUR_USERID != null) parameter[USER_ID] = CUR_USERID!;
    String curPin = context.read<UserProvider>().curPincode;
    if (curPin != '') parameter[ZIPCODE] = curPin;
    print("get section api here ${getSectionApi} and ${parameter}");
    apiBaseHelper.postAPICall(getSectionApi, parameter).then((getdata) {
      bool error = getdata["error"];
      String? msg = getdata["message"];
      sectionList.clear();
      if (!error) {
        var data = getdata["data"];

        sectionList = (data as List)
            .map((data) => new SectionModel.fromJson(data))
            .toList();
      } else {
        if (curPin != '') context.read<UserProvider>().setPincode('');
        setSnackbar(msg!, context);
      }

      context.read<HomeProvider>().setSecLoading(false);
    }, onError: (error) {
      setSnackbar(error.toString(), context);
      context.read<HomeProvider>().setSecLoading(false);
    });
  }

  void getSetting() {

    //print("")
    Map parameter = Map();
    if (CUR_USERID != null) parameter = {USER_ID: CUR_USERID};

    apiBaseHelper.postAPICall(getSettingApi, parameter).then((getdata) async {
      bool error = getdata["error"];
      String? msg = getdata["message"];

      if (!error) {
        var data = getdata["data"]["system_settings"][0];
        print(data);
        cartBtnList = data["cart_btn_on_list"] == "1" ? true : false;
        refer = data["is_refer_earn_on"] == "1" ? true : false;
        CUR_CURRENCY = data["currency"];
        RETURN_DAYS = data['max_product_return_days'];
        MAX_ITEMS = data["max_items_cart"];
        MIN_AMT = data['min_amount'];
        CUR_DEL_CHR = data['delivery_charge'];
        String? isVerion = data['is_version_system_on'];
        extendImg = data["expand_product_images"] == "1" ? true : false;
        String? del = data["area_wise_delivery_charge"];
        MIN_ALLOW_CART_AMT = data[MIN_CART_AMT];

        if (del == "0")
          ISFLAT_DEL = true;
        else
          ISFLAT_DEL = false;

        if (CUR_USERID != null) {
          REFER_CODE = getdata['data']['user_data'][0]['referral_code'];

          context
              .read<UserProvider>()
              .setPincode(getdata["data"]["user_data"][0][PINCODE]);

          if (REFER_CODE == null || REFER_CODE == '' || REFER_CODE!.isEmpty)
            generateReferral();

          context.read<UserProvider>().setCartCount(
              getdata["data"]["user_data"][0]["cart_total_items"].toString());
          context.read<UserProvider>().setBalance(
              getdata["data"]["user_data"][0]["balance"].toString());

          _getFav();
          _getCart("0");
        }

        UserProvider user = Provider.of<UserProvider>(context, listen: false);
        SettingProvider setting =
            Provider.of<SettingProvider>(context, listen: false);
        user.setMobile(setting.mobile);
        user.setName(setting.userName);
        user.setEmail(setting.email);
        user.setProfilePic(setting.profileUrl);

        Map<String, dynamic> tempData = getdata["data"];
        if (tempData.containsKey(TAG))
          tagList = List<String>.from(getdata["data"][TAG]);

        if (isVerion == "1") {
          String? verionAnd = data['current_version'];
          String? verionIOS = data['current_version_ios'];

          PackageInfo packageInfo = await PackageInfo.fromPlatform();

          String version = packageInfo.version;

          final Version currentVersion = Version.parse(version);
          final Version latestVersionAnd = Version.parse(verionAnd);
          final Version latestVersionIos = Version.parse(verionIOS);

          if ((Platform.isAndroid && latestVersionAnd > currentVersion) ||
              (Platform.isIOS && latestVersionIos > currentVersion))
            updateDailog();
        }
      } else {
        setSnackbar(msg!, context);
      }
    }, onError: (error) {
      setSnackbar(error.toString(), context);
    });
  }

  Future<void> _getCart(String save) async {
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

          List<SectionModel> cartList = (data as List)
              .map((data) => new SectionModel.fromCart(data))
              .toList();
          context.read<CartProvider>().setCartlist(cartList);
        }
      } on TimeoutException catch (_) {}
    } else {
      if (mounted)
        setState(() {
          _isNetworkAvail = false;
        });
    }
  }

  final _chars =
      'AaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSsTtUuVvWwXxYyZz1234567890';
  Random _rnd = Random();

  String getRandomString(int length) => String.fromCharCodes(Iterable.generate(
      length, (_) => _chars.codeUnitAt(_rnd.nextInt(_chars.length))));

  Future<Null> generateReferral() async {
    String refer = getRandomString(8);

    //////

    Map parameter = {
      REFERCODE: refer,
    };

    apiBaseHelper.postAPICall(validateReferalApi, parameter).then((getdata) {
      bool error = getdata["error"];
      String? msg = getdata["message"];
      if (!error) {
        REFER_CODE = refer;
        Map parameter = {
          USER_ID: CUR_USERID,
          REFERCODE: refer,
        };
        apiBaseHelper.postAPICall(getUpdateUserApi, parameter);
      } else {
        if (count < 5) generateReferral();
        count++;
      }
      context.read<HomeProvider>().setSecLoading(false);
    }, onError: (error) {
      setSnackbar(error.toString(), context);
      context.read<HomeProvider>().setSecLoading(false);
    });
  }

  updateDailog() async {
    await dialogAnimate(context,
        StatefulBuilder(builder: (BuildContext context, StateSetter setStater) {
      return AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(5.0))),
        title: Text(getTranslated(context, 'UPDATE_APP')!),
        content: Text(
          getTranslated(context, 'UPDATE_AVAIL')!,
          style: Theme.of(this.context)
              .textTheme
              .subtitle1!
              .copyWith(color: Theme.of(context).colorScheme.fontColor),
        ),
        actions: <Widget>[
          new TextButton(
              child: Text(
                getTranslated(context, 'NO')!,
                style: Theme.of(this.context).textTheme.subtitle2!.copyWith(
                    color: Theme.of(context).colorScheme.lightBlack,
                    fontWeight: FontWeight.bold),
              ),
              onPressed: () {
                Navigator.of(context).pop(false);
              }),
          new TextButton(
              child: Text(
                getTranslated(context, 'YES')!,
                style: Theme.of(this.context).textTheme.subtitle2!.copyWith(
                    color: Theme.of(context).colorScheme.fontColor,
                    fontWeight: FontWeight.bold),
              ),
              onPressed: () async {
                Navigator.of(context).pop(false);

                String _url = '';
                if (Platform.isAndroid) {
                  _url = androidLink + packageName;
                } else if (Platform.isIOS) {
                  _url = iosLink;
                }

                if (await canLaunch(_url)) {
                  await launch(_url);
                } else {
                  throw 'Could not launch $_url';
                }
              })
        ],
      );
    }));
  }

  Widget homeShimmer() {
    return Container(
      width: double.infinity,
      child: Shimmer.fromColors(
        baseColor: Theme.of(context).colorScheme.simmerBase,
        highlightColor: Theme.of(context).colorScheme.simmerHigh,
        child: SingleChildScrollView(
            child: Column(
          children: [
            catLoading(),
            sliderLoading(),
            sectionLoading(),
          ],
        )),
      ),
    );
  }

  Widget sliderLoading() {
    double width = deviceWidth!;
    double height = width / 2;
    return Shimmer.fromColors(
        baseColor: Theme.of(context).colorScheme.simmerBase,
        highlightColor: Theme.of(context).colorScheme.simmerHigh,
        child: Container(
          margin: EdgeInsets.symmetric(vertical: 10),
          width: double.infinity,
          height: height,
          color: Theme.of(context).colorScheme.white,
        ));
  }

  Widget _buildImagePageItem(Model slider) {
    double height = deviceWidth! / 0.5;

    return GestureDetector(
      child: FadeInImage(
          fadeInDuration: Duration(milliseconds: 150),
          image: CachedNetworkImageProvider(slider.image!),
          height: height,
          width: double.maxFinite,
          fit: BoxFit.fill,
          imageErrorBuilder: (context, error, stackTrace) => Image.asset(
                "assets/images/sliderph.png",
                fit: BoxFit.fill,
                height: height,
                color: colors.primary,
              ),
          placeholderErrorBuilder: (context, error, stackTrace) => Image.asset(
                MyAssets.slider_loding,
                fit: BoxFit.fill,
                height: height,
                color: colors.primary,
              ),
          placeholder: AssetImage(MyAssets.slider_loding)),
      onTap: () async {
        int curSlider = context.read<HomeProvider>().curSlider;

        if (homeSliderList[curSlider].type == "products") {
          Product? item = homeSliderList[curSlider].list;

          Navigator.push(
            context,
            PageRouteBuilder(
                pageBuilder: (_, __, ___) => ProductDetail(
                    model: item, secPos: 0, index: 0, list: true)),
          );
        } else if (homeSliderList[curSlider].type == "categories") {
          Product item = homeSliderList[curSlider].list;
          if (item.subList == null || item.subList!.length == 0) {
            Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ProductList(
                    name: item.name,
                    id: item.id,
                    tag: false,
                    fromSeller: false,
                  ),
                ));
          } else {
            Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SubCategory(
                    fromSearch: false,
                    title: item.name!,
                  ),
                ));
          }
        }
      },
    );
  }

  Widget deliverLoading() {
    return Shimmer.fromColors(
        baseColor: Theme.of(context).colorScheme.simmerBase,
        highlightColor: Theme.of(context).colorScheme.simmerHigh,
        child: Container(
          margin: EdgeInsets.symmetric(horizontal: 20, vertical: 5),
          width: double.infinity,
          height: 18.0,
          color: Theme.of(context).colorScheme.white,
        ));
  }

  Widget catLoading() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 10),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
                children: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9]
                    .map((_) => Container(
                          margin: EdgeInsets.symmetric(horizontal: 10),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.white,
                            shape: BoxShape.circle,
                          ),
                          width: 50.0,
                          height: 50.0,
                        ))
                    .toList()),
          ),
        ),
        Container(
          margin: EdgeInsets.symmetric(horizontal: 20, vertical: 5),
          width: double.infinity,
          height: 18.0,
          color: Theme.of(context).colorScheme.white,
        ),
      ],
    );
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
              context.read<HomeProvider>().setCatLoading(true);
              context.read<HomeProvider>().setSecLoading(true);
              context.read<HomeProvider>().setSliderLoading(true);
              _playAnimation();

              Future.delayed(Duration(seconds: 2)).then((_) async {
                _isNetworkAvail = await isNetworkAvailable();
                if (_isNetworkAvail) {
                  if (mounted)
                    setState(() {
                      _isNetworkAvail = true;
                    });
                  callApi();
                } else {
                  await buttonController.reverse();
                  if (mounted) setState(() {});
                }
              });
            },
          )
        ]),
      ),
    );
  }

  _deliverPincode() {
    var loc = Provider.of<LocationProvider>(context, listen: false);
    String curpin = context.read<UserProvider>().curPincode;
    return GestureDetector(
      child: Card(
        elevation: 5,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        child: ListTile(
          dense: true,
          minLeadingWidth: 10,
          leading: Icon(
            Icons.location_pin,
            color: colors.primary,
          ),
          title: Selector<UserProvider, String>(
            builder: (context, data, child) {
              return Text(
                currentAddress.text == ""
                    ? getTranslated(context, 'SELOC')!
                    : getTranslated(context, 'DELIVERTO')! +
                        currentAddress.text.toString(),
                style: TextStyle(color: Theme.of(context).colorScheme.fontColor),
              );
            },
            selector: (_, provider) => provider.curPincode,
          ),
          trailing: Icon(Icons.keyboard_arrow_right),
        ),
      ),
      // onTap: _pincodeCheck,
      onTap: () async {
        // List<dynamic> data = await Navigator.push(context,
        //     MaterialPageRoute(builder: (context) => SearchLocationPage()));
        var data = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (BuildContext context) => ManageAddress(
                home: false,
                fromBar: true,
              ),
            ));
        if(data==null){
          checkServiceAvailable();
        }else{
          setState(() {
            print("checking address data here now ${data}");
            currentAddress.text = data['address'].toString();
          });
          latitude = data['lati'].toString();
          longitude = data['longi'].toString();
          zipCode = data['zipcode'].toString();
          var loc = Provider.of<LocationProvider>(context, listen: false);
          loc.lat = latitude ;
          loc.lng = longitude ;
          checkServiceAvailable();
        }

        // if (data.isNotEmpty) {
        //   List<Placemark> place = data[0];
        //   setState(() {
        //     pinController.text = place[0].postalCode.toString();
        //     curpin = place[0].postalCode.toString();
        //     currentAddress.text =
        //         "${place[0].subLocality} , ${place[0].locality}";
        //     latitude = data[1];
        //     longitude = data[2];
        //     loc.lat = data[1];
        //     loc.lng = data[2];
        //     print(latitude);
        //     sellerList.clear();
        //     print(longitude);
        //     getSeller();
        //   });
        // }
      },
    );
  }
  void _pincodeCheck() {
    showModalBottomSheet<dynamic>(
        context: context,
        isScrollControlled: true,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.only(
                topLeft: Radius.circular(25), topRight: Radius.circular(25))),
        builder: (builder) {
          return StatefulBuilder(
              builder: (BuildContext context, StateSetter setState) {
            return Container(
              constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.9),
              child: ListView(shrinkWrap: true, children: [
                Padding(
                    padding: const EdgeInsets.only(
                        left: 20.0, right: 20, bottom: 40, top: 30),
                    child: Padding(
                      padding: EdgeInsets.only(
                          bottom: MediaQuery.of(context).viewInsets.bottom),
                      child: Form(
                          key: _formkey,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Align(
                                alignment: Alignment.topRight,
                                child: InkWell(
                                  onTap: () {
                                    Navigator.pop(context);
                                  },
                                  child: Icon(Icons.close),
                                ),
                              ),
                              TextFormField(
                                keyboardType: TextInputType.text,
                                controller: pinController,
                                textCapitalization: TextCapitalization.words,
                                validator: (val) => validatePincode(val!,
                                    getTranslated(context, 'PIN_REQUIRED')),
                                onSaved: (String? value) {
                                  context
                                      .read<UserProvider>()
                                      .setPincode(value!);
                                },
                                style: Theme.of(context)
                                    .textTheme
                                    .subtitle2!
                                    .copyWith(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .fontColor),
                                decoration: InputDecoration(
                                  isDense: true,
                                  prefixIcon: Icon(Icons.location_on),
                                  hintText:
                                      getTranslated(context, 'PINCODEHINT_LBL'),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Row(
                                  children: [
                                    Container(
                                      margin:
                                          EdgeInsetsDirectional.only(start: 20),
                                      width: deviceWidth! * 0.35,
                                      child: OutlinedButton(
                                        onPressed: () {
                                          context
                                              .read<UserProvider>()
                                              .setPincode('');

                                          context
                                              .read<HomeProvider>()
                                              .setSecLoading(true);
                                          getSection();
                                          Navigator.pop(context);
                                        },
                                        child: Text(
                                            getTranslated(context, 'All')!),
                                      ),
                                    ),
                                    Spacer(),
                                    SimBtn(
                                        size: 0.35,
                                        title: getTranslated(context, 'APPLY'),
                                        onBtnSelected: () async {
                                          if (validateAndSave()) {
                                            // validatePin(curPin);
                                            context
                                                .read<HomeProvider>()
                                                .setSecLoading(true);
                                            getSection();

                                            context
                                                .read<HomeProvider>()
                                                .setSellerLoading(true);
                                            getSeller();

                                            Navigator.pop(context);
                                          }
                                        }),
                                  ],
                                ),
                              ),
                            ],
                          )),
                    ))
              ]),
            );
            //});
          });
        });
  }

  bool validateAndSave() {
    final form = _formkey.currentState!;

    form.save();
    if (form.validate()) {
      return true;
    }
    return false;
  }

  Future<Null> _playAnimation() async {
    try {
      await buttonController.forward();
    } on TickerCanceled {}
  }

  void getSlider() {
    Map map = Map();

    apiBaseHelper.postAPICall(getSliderApi, map).then((getdata) {
      bool error = getdata["error"];
      String? msg = getdata["message"];
      if (!error) {
        var data = getdata["data"];

        homeSliderList =
            (data as List).map((data) => new Model.fromSlider(data)).toList();

        pages = homeSliderList.map((slider) {
          return _buildImagePageItem(slider);
        }).toList();
      } else {
        setSnackbar(msg!, context);
      }

      context.read<HomeProvider>().setSliderLoading(false);
    }, onError: (error) {
      setSnackbar(error.toString(), context);
      context.read<HomeProvider>().setSliderLoading(false);
    });
  }
  void getTodayCat() {
    Map parameter = {
      CAT_FILTER: "false",
    };
    print("tdy special parameter $parameter");
    apiBaseHelper.postAPICall(getTodayCatApi, parameter).then((getdata) {
      print("wok=rkinggggg");
      bool error = getdata["error"];
      String? msg = getdata["message"];
      print("message and error $error $msg");
      if (!error) {
        var data = getdata["data"];
        todayCatList =
            (data as List).map((data) => new Product.fromCat(data)).toList();
        print("responsss hereer $getdata $todayCatList");
      } else {
        setSnackbar(msg!, context);
      }
      context.read<HomeProvider>().setCatLoading(false);
    }, onError: (error) {
      setSnackbar(error.toString(), context);
      context.read<HomeProvider>().setCatLoading(false);
    });
  }

  void getCat() {
    Map parameter = {
      CAT_FILTER: "false",
    };
    print("========get categoriess=======$parameter===========");
    apiBaseHelper.postAPICall(getCatApi, parameter).then((getdata) {
      bool error = getdata["error"];
      String? msg = getdata["message"];
      if (!error) {
        var data = getdata["data"];
        catList =
            (data as List).map((data) => new Product.fromCat(data)).toList();
        if (getdata.containsKey("popular_categories")) {
          var data = getdata["popular_categories"];
          popularList = (data as List).map((data) => new Product.fromCat(data)).toList();
          if (popularList.length > 0) {
            Product pop = new Product.popular("Popular", imagePath + "popular.svg");
            catList.insert(0, pop);
            context.read<CategoryProvider>().setSubList(popularList);
          }
        }
      } else {
        setSnackbar(msg!, context);
      }
      context.read<HomeProvider>().setCatLoading(false);
    }, onError: (error) {
      setSnackbar(error.toString(), context);
      context.read<HomeProvider>().setCatLoading(false);
    });
  }

  sectionLoading() {
    return Column(
        children: [0, 1, 2, 3, 4]
            .map((_) => Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Stack(
                        children: [
                          Positioned.fill(
                            child: Container(
                              margin: EdgeInsets.only(bottom: 40),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.white,
                                borderRadius: BorderRadius.only(
                                  topLeft: Radius.circular(20),
                                  topRight: Radius.circular(20),
                                ),
                              ),
                            ),
                          ),
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              Container(
                                margin: EdgeInsets.symmetric(
                                    horizontal: 20, vertical: 5),
                                width: double.infinity,
                                height: 18.0,
                                color: Theme.of(context).colorScheme.white,
                              ),
                              GridView.count(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 20, vertical: 10),
                                crossAxisCount: 2,
                                shrinkWrap: true,
                                childAspectRatio: 1.0,
                                physics: NeverScrollableScrollPhysics(),
                                mainAxisSpacing: 5,
                                crossAxisSpacing: 5,
                                children: List.generate(
                                  4,
                                  (index) {
                                    return Container(
                                      width: double.infinity,
                                      height: double.infinity,
                                      color:
                                          Theme.of(context).colorScheme.white,
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    sliderLoading()
                    //offerImages.length > index ? _getOfferImage(index) : Container(),
                  ],
                ))
            .toList());
  }

  void getSeller() {
    String pin = context.read<UserProvider>().curPincode;
    Map parameter = {"lat": "$latitude", "lang": "$longitude"};
    print(parameter);
    // if (pin != '') {
    //   parameter = {
    //     "lat":"$latitude",
    //     "lang":"$longitude"
    //   };
    //   print(latitude);
    //   print(longitude);
    // }
    print("ssssssssssss ${getSellerApi} and ${parameter}");
    apiBaseHelper.postAPICall(getSellerApi, parameter).then((getdata) {
      sellerList.clear();
      bool error = getdata["error"];
      String? msg = getdata["message"];
      print(getSellerApi);
      print(parameter.toString());
      if (!error) {
        var data = getdata["data"];



        sellerList =
            (data as List).map((data) => new Product.fromSeller(data)).toList();

        print('___________${sellerList.length}___kfjsdljgdlsjs_______');
        sellerList.forEach((element) {
          print('___________${element.online}___abcdefgh_______');});
        setState(() {
          sellerList.sort((a, b) => b.online!.compareTo(a.online!));
        });

      } else {
        // setSnackbar(msg!, context);
      }

      context.read<HomeProvider>().setSellerLoading(false);
    }, onError: (error) {
      // setSnackbar(error.toString(), context);
      context.read<HomeProvider>().setSellerLoading(false);
    });
  }

  _seller() {
    return Selector<HomeProvider, bool>(
      builder: (context, data, child) {
        return data
            ? Container(
                width: double.infinity,
                child: Shimmer.fromColors(
                    baseColor: Theme.of(context).colorScheme.simmerBase,
                    highlightColor: Theme.of(context).colorScheme.simmerHigh,
                    child: catLoading()))
            : Padding(
                padding: EdgeInsets.only(bottom: 10),
                child: Container(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Padding(
                            padding:
                                EdgeInsets.only(left: 14, top: 10, bottom: 5),
                            child: Text("All Nearby Home Kitchens",
                                style: TextStyle(
                                    color:
                                        Theme.of(context).colorScheme.fontColor,
                                    fontWeight: FontWeight.bold)),
                          ),
                          Padding(
                            padding:
                                EdgeInsets.only(right: 14, top: 10, bottom: 5),
                            child: InkWell(
                              onTap: () {
                                Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) => SellerList(
                                              getByLocation: true,
                                            )));
                              },
                              child: Text("View All",
                                  style: TextStyle(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .fontColor,
                                      fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ],
                      ),
                      // trailing: TextButton(
                      //   onPressed: () {
                      //     Navigator.push(
                      //         context,
                      //         MaterialPageRoute(
                      //             builder: (context) => SellerList(
                      //                   getByLocation: true,
                      //                 )));
                      //   },
                      //   child: Text(
                      //     getTranslated(context, 'VIEW_ALL')!,
                      //     style: TextStyle(fontWeight: FontWeight.w600),
                      //   ),
                      // ),

                      ///
                      SizedBox(
                        height: 5,
                      ),
                      Container(
                        // height: sellerList.length > 2 ? 550 : 180,
                        padding: EdgeInsets.symmetric(horizontal: 12),
                        child: sellerList.length == 0
                            ? Center(
                                child: Text("No HomeKitchen to show"),
                              )
                            : GridView.builder(
                          shrinkWrap: true,
                                gridDelegate:
                                    SliverGridDelegateWithFixedCrossAxisCount(
                                        childAspectRatio: 3 / 3.3,
                                        crossAxisCount: 2),
                                itemCount: sellerList.length,
                                physics: NeverScrollableScrollPhysics(),
                                scrollDirection: Axis.vertical,
                                itemBuilder: (c, index) {
                                  print('___________${sellerList.length}__________');
                                  return InkWell(
                                    onTap: () {
                                      if (sellerList[index].online == "1") {
                                        Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                                builder: (context) =>
                                                    SubCategory(
                                                      fromSearch: false,
                                                      title: sellerList[index]
                                                          .store_name
                                                          .toString(),
                                                      sellerId:
                                                          sellerList[index]
                                                              .seller_id
                                                              .toString(),
                                                      sellerData:
                                                          sellerList[index],
                                                    )));
                                      } else {
                                        setSnackbar(
                                            "Restaurant is Close!!", context);
                                      }
                                    },
                                    child: Container(
                                      width: 170,
                                      child: Card(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Container(
                                              height: 100,
                                              width: 170,
                                              // height: 110,
                                              // width: 160,
                                              child: ClipRRect(
                                                borderRadius: BorderRadius.only(
                                                    topLeft:
                                                        Radius.circular(10),
                                                    topRight:
                                                        Radius.circular(10)),
                                                child: FadeInImage(
                                                  fadeInDuration: Duration(
                                                      milliseconds: 150),
                                                  image:
                                                      CachedNetworkImageProvider(
                                                    sellerList[index]
                                                        .seller_profile!,
                                                  ),
                                                  fit: BoxFit.fill,
                                                  imageErrorBuilder: (context,
                                                          error, stackTrace) =>
                                                      erroWidget(50),
                                                  placeholder: placeHolder(50),
                                                ),
                                              ),
                                            ),
                                            SizedBox(
                                              height: 5,
                                            ),
                                            Padding(
                                              padding: EdgeInsets.only(
                                                  left: 5, right: 5),
                                              child: Text(
                                                "${sellerList[index].store_name!}",
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .caption!
                                                    .copyWith(
                                                      color: Theme.of(context)
                                                          .colorScheme
                                                          .fontColor,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                                maxLines: 2,
                                              ),
                                            ),
                                            Container(
                                              width: 160,
                                              padding: EdgeInsets.symmetric(
                                                  horizontal: 5),
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .spaceBetween,
                                                    children: [
                                                      sellerList[index]
                                                                  .online ==
                                                              "1"
                                                          ? Text(
                                                              "Open",
                                                              style: TextStyle(
                                                                  color: Colors
                                                                      .green),
                                                            )
                                                          : StreamBuilder<
                                                                  Object>(
                                                              stream: null,
                                                              builder: (context,
                                                                  snapshot) {
                                                                return Padding(
                                                                  padding: EdgeInsets
                                                                      .only(
                                                                          left:
                                                                              5),
                                                                  child: Text(
                                                                    "Close",
                                                                    style: TextStyle(
                                                                        color: Colors
                                                                            .red),
                                                                  ),
                                                                );
                                                              }),
                                                      Container(
                                                        child: Row(
                                                          children: [
                                                            Icon(
                                                              Icons
                                                                  .star_rounded,
                                                              color:
                                                                  Colors.amber,
                                                              size: 15,
                                                            ),
                                                            Text(
                                                              "${sellerList[index].seller_rating!}",
                                                              style: Theme.of(
                                                                      context)
                                                                  .textTheme
                                                                  .caption!
                                                                  .copyWith(
                                                                      color: Theme.of(
                                                                              context)
                                                                          .colorScheme
                                                                          .fontColor,
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .w600,
                                                                      fontSize:
                                                                          14),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  SizedBox(
                                                    height: 3,
                                                  ),
                                                  sellerList[index]
                                                              .storeIndicator ==
                                                          "1"
                                                      ? Image.asset(
                                                          "assets/images/vegImage.png",
                                                          height: 15,
                                                          width: 15,
                                                        )
                                                      : sellerList[index]
                                                                  .storeIndicator ==
                                                              "2"
                                                          ? Image.asset(
                                                              "assets/images/non-vegImage.png",
                                                              height: 15,
                                                              width: 15,
                                                            )
                                                          : Row(
                                                              crossAxisAlignment:
                                                                  CrossAxisAlignment
                                                                      .start,
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
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                }),
                      ),

                      // Container(
                      //   // height: 200,
                      //   child: ListView.builder(
                      //     itemCount: sellerList.length,
                      //     scrollDirection: Axis.vertical,
                      //     physics: ClampingScrollPhysics(),
                      //     itemBuilder: (context, index) {
                      //       return Padding(
                      //         padding: const EdgeInsets.symmetric(
                      //             horizontal: 12, vertical: 1),
                      //         child: GestureDetector(
                      //           onTap: () {
                      //             // Navigator.push(
                      //             //     context,
                      //             //     MaterialPageRoute(
                      //             //         builder: (context) => SellerProfile(
                      //             //               sellerStoreName: sellerList[index]
                      //             //                       .store_name ??
                      //             //                   "",
                      //             //               sellerRating: sellerList[index]
                      //             //                       .seller_rating ??
                      //             //                   "",
                      //             //               sellerImage: sellerList[index]
                      //             //                       .seller_profile ??
                      //             //                   "",
                      //             //               sellerName: sellerList[index]
                      //             //                       .seller_name ??
                      //             //                   "",
                      //             //               sellerID:
                      //             //                   sellerList[index].seller_id,
                      //             //               storeDesc: sellerList[index]
                      //             //                   .store_description,
                      //             //             )));
                      //             if(sellerList[index].online == "1"){
                      //               Navigator.push(
                      //                   context,
                      //                   MaterialPageRoute(
                      //                       builder: (context) => SubCategory(
                      //                         fromSearch: false,
                      //                         title: sellerList[index]
                      //                             .store_name
                      //                             .toString(),
                      //                         sellerId: sellerList[index]
                      //                             .seller_id
                      //                             .toString(),
                      //                         sellerData: sellerList[index],
                      //                       )));
                      //             } else {
                      //               setSnackbar("Store is Close!!", context);
                      //             }
                      //           },
                      //           child: Column(
                      //             mainAxisAlignment:
                      //                 MainAxisAlignment.spaceAround,
                      //             mainAxisSize: MainAxisSize.min,
                      //             crossAxisAlignment: CrossAxisAlignment.start,
                      //             children: <Widget>[
                      //               Card(
                      //                 elevation: 2,
                      //                 shape: RoundedRectangleBorder(
                      //                     borderRadius:
                      //                         BorderRadius.circular(10)),
                      //                 child: Container(
                      //                   // decoration: BoxDecoration(
                      //                   //     borderRadius:
                      //                   //         BorderRadius.circular(10),
                      //                   //     image: DecorationImage(
                      //                   //         fit: BoxFit.cover,
                      //                   //         // opacity: .05,
                      //                   //         image: NetworkImage(
                      //                   //             sellerList[index]
                      //                   //                 .seller_profile!))),
                      //                   child: Row(
                      //                     children: [
                      //                       Container(
                      //                         height: 120,
                      //                         width: 110,
                      //                         padding: EdgeInsets.only(left: 10,top: 5,bottom: 5),
                      //                         child: ClipRRect(
                      //                           borderRadius:
                      //                               BorderRadius.circular(8),
                      //                           child: FadeInImage(
                      //                             fadeInDuration:
                      //                                 Duration(milliseconds: 150),
                      //                             image:
                      //                                 CachedNetworkImageProvider(
                      //                               sellerList[index]
                      //                                   .seller_profile!,
                      //                             ),
                      //                             fit: BoxFit.cover,
                      //                             imageErrorBuilder: (context,
                      //                                     error, stackTrace) =>
                      //                                 erroWidget(50),
                      //                             placeholder: placeHolder(50),
                      //                           ),
                      //                         ),
                      //                       ),
                      //                       Expanded(
                      //                         child: Column(
                      //                           children: [
                      //                             ListTile(
                      //                               dense: true,
                      //                               title: Text(
                      //                                   "${sellerList[index].store_name!}",
                      //                                 style: Theme.of(
                      //                                     context)
                      //                                     .textTheme
                      //                                     .caption!
                      //                                     .copyWith(
                      //                                     color: Theme.of(
                      //                                         context)
                      //                                         .colorScheme
                      //                                         .fontColor,
                      //                                     fontWeight:
                      //                                     FontWeight
                      //                                         .w600,
                      //                                 ),
                      //                               ),
                      //                               subtitle: Text(
                      //                                 "${sellerList[index].store_description!}",
                      //                                 maxLines: 2,
                      //                                 style: Theme.of(
                      //                                     context)
                      //                                     .textTheme
                      //                                     .caption!
                      //                                     .copyWith(
                      //                                   color: Theme.of(
                      //                                       context)
                      //                                       .colorScheme
                      //                                       .fontColor,
                      //                                   fontWeight:
                      //                                   FontWeight
                      //                                       .w600,
                      //                                 ),
                      //                               ),
                      //                               trailing: Column(
                      //                                 crossAxisAlignment: CrossAxisAlignment.end,
                      //                                 children: [
                      //                                   sellerList[index].online == "1"
                      //                                       ? Text("Open",
                      //                                     style: TextStyle(
                      //                                         color: Colors.green
                      //                                     ),
                      //                                   )
                      //                                       : Text("Close",
                      //                                     style: TextStyle(
                      //                                         color: Colors.red
                      //                                     ),
                      //                                   ),
                      //                                   sellerList[index].storeIndicator == "1" ? Image.asset("assets/images/vegImage.png",height: 15,width: 15,): sellerList[index].storeIndicator == "2" ? Image.asset("assets/images/non-vegImage.png",height: 15,width: 15,) : Row(
                      //                                     crossAxisAlignment: CrossAxisAlignment.start,
                      //                                     children: [
                      //                                       Image.asset("assets/images/vegImage.png",height: 15,width: 15,),
                      //                                       Image.asset("assets/images/non-vegImage.png",height: 15,width: 15,)
                      //                                     ],
                      //                                   )
                      //                                 ],
                      //                               ),
                      //                             ),
                      //                             Divider(
                      //                               height: 0,
                      //                             ),
                      //                             Padding(
                      //                               padding:
                      //                                   const EdgeInsets.all(8.0),
                      //                               child: Row(
                      //                                 mainAxisAlignment:
                      //                                     MainAxisAlignment
                      //                                         .spaceBetween,
                      //                                 children: [
                      //                                   FittedBox(
                      //                                     child: Row(
                      //                                       children: [
                      //                                         Icon(
                      //                                           Icons
                      //                                               .star_rounded,
                      //                                           color:
                      //                                               Colors.amber,
                      //                                           size: 15,
                      //                                         ),
                      //                                         Text(
                      //                                           "${sellerList[index].seller_rating!}",
                      //                                           style: Theme.of(
                      //                                                   context)
                      //                                               .textTheme
                      //                                               .caption!
                      //                                               .copyWith(
                      //                                                   color: Theme.of(
                      //                                                           context)
                      //                                                       .colorScheme
                      //                                                       .fontColor,
                      //                                                   fontWeight:
                      //                                                       FontWeight
                      //                                                           .w600,
                      //                                                   fontSize:
                      //                                                       14),
                      //                                         ),
                      //                                       ],
                      //                                     ),
                      //                                   ),
                      //                                   sellerList[index]
                      //                                               .estimated_time !=
                      //                                           ""
                      //                                       ? FittedBox(
                      //                                           child: Container(
                      //                                               child: Center(
                      //                                             child: Padding(
                      //                                               padding: const EdgeInsets
                      //                                                       .symmetric(
                      //                                                   horizontal:
                      //                                                       5,
                      //                                                   vertical:
                      //                                                       2),
                      //                                               child: Text(
                      //                                                 "${sellerList[index].estimated_time}",
                      //                                                 style: TextStyle(
                      //                                                     fontSize:
                      //                                                         14),
                      //                                               ),
                      //                                             ),
                      //                                           )),
                      //                                         )
                      //                                       : Container(),
                      //                                   // sellerList[index]
                      //                                   //             .food_person !=
                      //                                   //         ""
                      //                                   //     ? FittedBox(
                      //                                   //         child: Container(
                      //                                   //             child:
                      //                                   //                 Padding(
                      //                                   //           padding: const EdgeInsets
                      //                                   //                   .symmetric(
                      //                                   //               horizontal:
                      //                                   //                   5,
                      //                                   //               vertical:
                      //                                   //                   1),
                      //                                   //           child: Text(
                      //                                   //             "${sellerList[index].food_person}",
                      //                                   //             style: TextStyle(
                      //                                   //                 fontSize:
                      //                                   //                     14),
                      //                                   //           ),
                      //                                   //         )),
                      //                                   //       )
                      //                                   //     : Container(),
                      //                                 ],
                      //                               ),
                      //                             ),
                      //                           ],
                      //                         ),
                      //                       )
                      //                     ],
                      //                   ),
                      //                 ),
                      //               ),
                      //             ],
                      //           ),
                      //         ),
                      //       );
                      //     },
                      //   ),
                      // ),

                      // Container(
                      //   height: 180,
                      //   padding: EdgeInsets.symmetric(horizontal: 12),
                      //   child: ListView.builder(
                      //       itemCount: sellerList.length,
                      //       physics: ScrollPhysics(),
                      //       scrollDirection: Axis.horizontal,
                      //       itemBuilder: (c, index) {
                      //         return InkWell(
                      //           onTap: (){
                      //             if(sellerList[index].online == "1"){
                      //               Navigator.push(
                      //                   context,
                      //                   MaterialPageRoute(
                      //                       builder: (context) => SubCategory(
                      //                         title: sellerList[index]
                      //                             .store_name
                      //                             .toString(),
                      //                         sellerId: sellerList[index]
                      //                             .seller_id
                      //                             .toString(),
                      //                         sellerData: sellerList[index],
                      //                       )));
                      //             } else {
                      //               setSnackbar("Store is Close!!", context);
                      //             }
                      //           },
                      //           child: Container(
                      //             width: 170,
                      //             child: Card(
                      //               child: Column(
                      //                 crossAxisAlignment:
                      //                     CrossAxisAlignment.start,
                      //                 children: [
                      //                   Container(
                      //                     height: 110,
                      //                     width: 160,
                      //                     child: ClipRRect(
                      //                       borderRadius: BorderRadius.only(
                      //                           topLeft: Radius.circular(10),
                      //                           topRight: Radius.circular(10)),
                      //                       child: FadeInImage(
                      //                         fadeInDuration:
                      //                             Duration(milliseconds: 150),
                      //                         image: CachedNetworkImageProvider(
                      //                           sellerList[index].seller_profile!,
                      //                         ),
                      //                         fit: BoxFit.fill,
                      //                         imageErrorBuilder:
                      //                             (context, error, stackTrace) =>
                      //                                 erroWidget(50),
                      //                         placeholder: placeHolder(50),
                      //                       ),
                      //                     ),
                      //                   ),
                      //                   SizedBox(height: 5,),
                      //                   Padding(
                      //                     padding: EdgeInsets.only(left: 5,right: 5),
                      //                     child: Text(
                      //                       "${sellerList[index].store_name!}",
                      //                       style: Theme.of(context)
                      //                           .textTheme
                      //                           .caption!
                      //                           .copyWith(
                      //                             color: Theme.of(context)
                      //                                 .colorScheme
                      //                                 .fontColor,
                      //                             fontWeight: FontWeight.w600,
                      //                           ),
                      //                       maxLines: 2,
                      //                     ),
                      //                   ),
                      //                Container(
                      //                  width: 160,
                      //                  padding: EdgeInsets.symmetric(horizontal: 5),
                      //                  child: Row(
                      //                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      //                    children: [
                      //                      sellerList[index].online == "1"
                      //                          ? Text("Open",
                      //                            style: TextStyle(
                      //                                color: Colors.green
                      //                            ),
                      //                          )
                      //                          : StreamBuilder<Object>(
                      //                            stream: null,
                      //                            builder: (context, snapshot) {
                      //                              return Padding(
                      //                        padding: EdgeInsets.only(left: 5),
                      //                        child: Text("Close",
                      //                              style: TextStyle(
                      //                                  color: Colors.red
                      //                              ),
                      //                        ),
                      //                      );
                      //                            }
                      //                          ) ,
                      //
                      //                      Container(
                      //                        child: Row(
                      //                          children: [
                      //                            Icon(
                      //                              Icons
                      //                                  .star_rounded,
                      //                              color:
                      //                              Colors.amber,
                      //                              size: 15,
                      //                            ),
                      //                            Text(
                      //                              "${sellerList[index].seller_rating!}",
                      //                              style: Theme.of(
                      //                                  context)
                      //                                  .textTheme
                      //                                  .caption!
                      //                                  .copyWith(
                      //                                  color: Theme.of(
                      //                                      context)
                      //                                      .colorScheme
                      //                                      .fontColor,
                      //                                  fontWeight:
                      //                                  FontWeight
                      //                                      .w600,
                      //                                  fontSize:
                      //                                  14),
                      //                            ),
                      //                          ],
                      //                        ),
                      //                      ),
                      //                    ],
                      //                  ),
                      //                ),
                      //                 ],
                      //               ),
                      //             ),
                      //           ),
                      //         );
                      //       }),
                      // ),
                    ],
                  ),
                ),
              );
      },
      selector: (_, homeProvider) => homeProvider.sellerLoading,
    );
  }

  _topSeller() {
    return Selector<HomeProvider, bool>(
      builder: (context, data, child) {
        return data
            ? Container(
                width: double.infinity,
                child: Shimmer.fromColors(
                    baseColor: Theme.of(context).colorScheme.simmerBase,
                    highlightColor: Theme.of(context).colorScheme.simmerHigh,
                    child: catLoading()))
            : Container(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: EdgeInsets.only(top: 10, left: 12, bottom: 8),
                      child: Text('Top Rated Home Kitchens',
                          style: TextStyle(
                              color: Theme.of(context).colorScheme.fontColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 14)),
                    ),
                    // trailing: TextButton(
                    //   onPressed: () {
                    //     Navigator.push(
                    //         context,
                    //         MaterialPageRoute(
                    //             builder: (context) => SellerList(
                    //                   getByLocation: true,
                    //                 )));
                    //   },
                    //   child: Text(
                    //     getTranslated(context, 'VIEW_ALL')!,
                    //     style: TextStyle(fontWeight: FontWeight.w600),
                    //   ),
                    // ),

                    ///
                    // ListView.builder(
                    //   itemCount: topSellerList.length,
                    //   scrollDirection: Axis.vertical,
                    //   shrinkWrap: true,
                    //   physics: ClampingScrollPhysics(),
                    //   itemBuilder: (context, index) {
                    //     return Padding(
                    //       padding: const EdgeInsets.symmetric(
                    //           horizontal: 12, vertical: 1),
                    //       child: GestureDetector(
                    //         onTap: () {
                    //           // Navigator.push(
                    //           //     context,
                    //           //     MaterialPageRoute(
                    //           //         builder: (context) => SellerProfile(
                    //           //               sellerStoreName: sellerList[index]
                    //           //                       .store_name ??
                    //           //                   "",
                    //           //               sellerRating: sellerList[index]
                    //           //                       .seller_rating ??
                    //           //                   "",
                    //           //               sellerImage: sellerList[index]
                    //           //                       .seller_profile ??
                    //           //                   "",
                    //           //               sellerName: sellerList[index]
                    //           //                       .seller_name ??
                    //           //                   "",
                    //           //               sellerID:
                    //           //                   sellerList[index].seller_id,
                    //           //               storeDesc: sellerList[index]
                    //           //                   .store_description,
                    //           //             )));
                    //           if(topSellerList[index].online == "1"){
                    //             Navigator.push(
                    //                 context,
                    //                 MaterialPageRoute(
                    //                     builder: (context) => SubCategory(
                    //                       title: topSellerList[index]
                    //                           .store_name
                    //                           .toString(),
                    //                       sellerId: topSellerList[index]
                    //                           .seller_id
                    //                           .toString(),
                    //                       sellerData: topSellerList[index],
                    //                     )));
                    //           } else {
                    //             setSnackbar("Store is Close!!", context);
                    //           }
                    //         },
                    //         child: Column(
                    //           mainAxisAlignment:
                    //           MainAxisAlignment.spaceAround,
                    //           mainAxisSize: MainAxisSize.min,
                    //           crossAxisAlignment: CrossAxisAlignment.start,
                    //           children: <Widget>[
                    //             Card(
                    //               elevation: 2,
                    //               shape: RoundedRectangleBorder(
                    //                   borderRadius:
                    //                   BorderRadius.circular(10)),
                    //               child: Container(
                    //                 // decoration: BoxDecoration(
                    //                 //     borderRadius:
                    //                 //         BorderRadius.circular(10),
                    //                 //     image: DecorationImage(
                    //                 //         fit: BoxFit.cover,
                    //                 //         // opacity: .05,
                    //                 //         image: NetworkImage(
                    //                 //             sellerList[index]
                    //                 //                 .seller_profile!))),
                    //                 child: Row(
                    //                   children: [
                    //                     Container(
                    //                       height: 120,
                    //                       width: 110,
                    //                       padding: EdgeInsets.only(left: 10,top: 5,bottom: 5),
                    //                       child: ClipRRect(
                    //                         borderRadius:
                    //                         BorderRadius.circular(8),
                    //                         child: FadeInImage(
                    //                           fadeInDuration:
                    //                           Duration(milliseconds: 150),
                    //                           image:
                    //                           CachedNetworkImageProvider(
                    //                             topSellerList[index]
                    //                                 .seller_profile!,
                    //                           ),
                    //                           fit: BoxFit.cover,
                    //                           imageErrorBuilder: (context,
                    //                               error, stackTrace) =>
                    //                               erroWidget(50),
                    //                           placeholder: placeHolder(50),
                    //                         ),
                    //                       ),
                    //                     ),
                    //                     Expanded(
                    //                       child: Column(
                    //                         children: [
                    //                           ListTile(
                    //                             dense: true,
                    //                             title: Text(
                    //                               "${topSellerList[index].store_name!}",
                    //                               style: Theme.of(
                    //                                   context)
                    //                                   .textTheme
                    //                                   .caption!
                    //                                   .copyWith(
                    //                                 color: Theme.of(
                    //                                     context)
                    //                                     .colorScheme
                    //                                     .fontColor,
                    //                                 fontWeight:
                    //                                 FontWeight
                    //                                     .w600,
                    //                               ),
                    //                             ),
                    //                             subtitle: Text(
                    //                               "${topSellerList[index].store_description!}",
                    //                               maxLines: 2,
                    //                               style: Theme.of(
                    //                                   context)
                    //                                   .textTheme
                    //                                   .caption!
                    //                                   .copyWith(
                    //                                 color: Theme.of(
                    //                                     context)
                    //                                     .colorScheme
                    //                                     .fontColor,
                    //                                 fontWeight:
                    //                                 FontWeight
                    //                                     .w600,
                    //                               ),
                    //                             ),
                    //                             trailing: topSellerList[index].online == "1"
                    //                                 ? Text("Open",
                    //                               style: TextStyle(
                    //                                   color: Colors.green
                    //                               ),
                    //                             )
                    //                                 : Text("Close",
                    //                               style: TextStyle(
                    //                                   color: Colors.red
                    //                               ),
                    //                             ),
                    //                           ),
                    //                           Divider(
                    //                             height: 0,
                    //                           ),
                    //                           Padding(
                    //                             padding:
                    //                             const EdgeInsets.all(8.0),
                    //                             child: Row(
                    //                               mainAxisAlignment:
                    //                               MainAxisAlignment
                    //                                   .spaceBetween,
                    //                               children: [
                    //                                 FittedBox(
                    //                                   child: Row(
                    //                                     children: [
                    //                                       Icon(
                    //                                         Icons
                    //                                             .star_rounded,
                    //                                         color:
                    //                                         Colors.amber,
                    //                                         size: 15,
                    //                                       ),
                    //                                       Text(
                    //                                         "${topSellerList[index].seller_rating!}",
                    //                                         style: Theme.of(
                    //                                             context)
                    //                                             .textTheme
                    //                                             .caption!
                    //                                             .copyWith(
                    //                                             color: Theme.of(
                    //                                                 context)
                    //                                                 .colorScheme
                    //                                                 .fontColor,
                    //                                             fontWeight:
                    //                                             FontWeight
                    //                                                 .w600,
                    //                                             fontSize:
                    //                                             14),
                    //                                       ),
                    //                                     ],
                    //                                   ),
                    //                                 ),
                    //                                 topSellerList[index]
                    //                                     .estimated_time !=
                    //                                     ""
                    //                                     ? FittedBox(
                    //                                   child: Container(
                    //                                       child: Center(
                    //                                         child: Padding(
                    //                                           padding: const EdgeInsets
                    //                                               .symmetric(
                    //                                               horizontal:
                    //                                               5,
                    //                                               vertical:
                    //                                               2),
                    //                                           child: Text(
                    //                                             "${topSellerList[index].estimated_time}",
                    //                                             style: TextStyle(
                    //                                                 fontSize:
                    //                                                 14),
                    //                                           ),
                    //                                         ),
                    //                                       )),
                    //                                 )
                    //                                     : Container(),
                    //                                 // sellerList[index]
                    //                                 //             .food_person !=
                    //                                 //         ""
                    //                                 //     ? FittedBox(
                    //                                 //         child: Container(
                    //                                 //             child:
                    //                                 //                 Padding(
                    //                                 //           padding: const EdgeInsets
                    //                                 //                   .symmetric(
                    //                                 //               horizontal:
                    //                                 //                   5,
                    //                                 //               vertical:
                    //                                 //                   1),
                    //                                 //           child: Text(
                    //                                 //             "${sellerList[index].food_person}",
                    //                                 //             style: TextStyle(
                    //                                 //                 fontSize:
                    //                                 //                     14),
                    //                                 //           ),
                    //                                 //         )),
                    //                                 //       )
                    //                                 //     : Container(),
                    //                               ],
                    //                             ),
                    //                           ),
                    //                         ],
                    //                       ),
                    //                     )
                    //                   ],
                    //                 ),
                    //               ),
                    //             ),
                    //           ],
                    //         ),
                    //       ),
                    //     );
                    //   },
                    // ),

                    Container(
                      height: 190,
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      child: topSellerList.length == 0
                          ? Center(
                              child: Text("No HomeKitchen to show"),
                            )
                          : ListView.builder(
                              itemCount: topSellerList.length,
                              physics: ScrollPhysics(),
                              scrollDirection: Axis.horizontal,
                              itemBuilder: (c, index) {
                                return InkWell(
                                  onTap: () {
                                    if (topSellerList[index].online == "1") {
                                      Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                              builder: (context) => SubCategory(
                                                    fromSearch: false,
                                                    title: topSellerList[index]
                                                        .store_name
                                                        .toString(),
                                                    sellerId:
                                                        topSellerList[index]
                                                            .seller_id
                                                            .toString(),
                                                    sellerData:
                                                        topSellerList[index],
                                                  )));
                                    } else {
                                      setSnackbar(
                                          "Restaurant is Close!!", context);
                                    }
                                  },
                                  child: Container(
                                    width: 170,
                                    child: Card(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Container(
                                            height: 110,
                                            width: 160,
                                            child: ClipRRect(
                                              borderRadius: BorderRadius.only(
                                                  topLeft: Radius.circular(10),
                                                  topRight:
                                                      Radius.circular(10)),
                                              child: FadeInImage(
                                                fadeInDuration:
                                                    Duration(milliseconds: 150),
                                                image:
                                                    CachedNetworkImageProvider(
                                                  topSellerList[index]
                                                      .seller_profile!,
                                                ),
                                                fit: BoxFit.fill,
                                                imageErrorBuilder: (context,
                                                        error, stackTrace) =>
                                                    erroWidget(50),
                                                placeholder: placeHolder(50),
                                              ),
                                            ),
                                          ),
                                          SizedBox(
                                            height: 5,
                                          ),
                                          Padding(
                                            padding: EdgeInsets.only(
                                                left: 5, right: 5),
                                            child: Text(
                                              "${topSellerList[index].store_name!}",
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .caption!
                                                  .copyWith(
                                                    color: Theme.of(context)
                                                        .colorScheme
                                                        .fontColor,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                              maxLines: 2,
                                            ),
                                          ),
                                          Container(
                                            width: 160,
                                            padding: EdgeInsets.symmetric(
                                                horizontal: 5),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment
                                                          .spaceBetween,
                                                  children: [
                                                    topSellerList[index]
                                                                .online ==
                                                            "1"
                                                        ? Text(
                                                            "Open",
                                                            style: TextStyle(
                                                                color: Colors
                                                                    .green),
                                                          )
                                                        : StreamBuilder<Object>(
                                                            stream: null,
                                                            builder: (context,
                                                                snapshot) {
                                                              return Padding(
                                                                padding: EdgeInsets
                                                                    .only(
                                                                        left:
                                                                            5),
                                                                child: Text(
                                                                  "Close",
                                                                  style: TextStyle(
                                                                      color: Colors
                                                                          .red),
                                                                ),
                                                              );
                                                            }),
                                                    Container(
                                                      child: Row(
                                                        children: [
                                                          Icon(
                                                            Icons.star_rounded,
                                                            color: Colors.amber,
                                                            size: 15,
                                                          ),
                                                          Text(
                                                            "${topSellerList[index].seller_rating!}",
                                                            style: Theme.of(
                                                                    context)
                                                                .textTheme
                                                                .caption!
                                                                .copyWith(
                                                                    color: Theme.of(
                                                                            context)
                                                                        .colorScheme
                                                                        .fontColor,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .w600,
                                                                    fontSize:
                                                                        14),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                topSellerList[index]
                                                            .storeIndicator ==
                                                        "1"
                                                    ? Image.asset(
                                                        "assets/images/vegImage.png",
                                                        height: 15,
                                                        width: 15,
                                                      )
                                                    : topSellerList[index]
                                                                .storeIndicator ==
                                                            "2"
                                                        ? Image.asset(
                                                            "assets/images/non-vegImage.png",
                                                            height: 15,
                                                            width: 15,
                                                          )
                                                        : Row(
                                                            crossAxisAlignment:
                                                                CrossAxisAlignment
                                                                    .start,
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
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              }),
                    ),
                  ],
                ),
              );
      },
      selector: (_, homeProvider) => homeProvider.sellerLoading,
    );
  }

  _sponsorSeller() {
    return Selector<HomeProvider, bool>(
      builder: (context, data, child) {
        return data
            ? Container(
                width: double.infinity,
                child: Shimmer.fromColors(
                    baseColor: Theme.of(context).colorScheme.simmerBase,
                    highlightColor: Theme.of(context).colorScheme.simmerHigh,
                    child: catLoading()))
            : Container(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: EdgeInsets.only(top: 10, left: 12, bottom: 8),
                      child: Text('Sponsored HomeKitchen',
                          style: TextStyle(
                              color: Theme.of(context).colorScheme.fontColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 14)),
                    ),
                    // trailing: TextButton(
                    //   onPressed: () {
                    //     Navigator.push(
                    //         context,
                    //         MaterialPageRoute(
                    //             builder: (context) => SellerList(
                    //                   getByLocation: true,
                    //                 )));
                    //   },
                    //   child: Text(
                    //     getTranslated(context, 'VIEW_ALL')!,
                    //     style: TextStyle(fontWeight: FontWeight.w600),
                    //   ),
                    // ),

                    ///
                    // ListView.builder(
                    //   itemCount: topSellerList.length,
                    //   scrollDirection: Axis.vertical,
                    //   shrinkWrap: true,
                    //   physics: ClampingScrollPhysics(),
                    //   itemBuilder: (context, index) {
                    //     return Padding(
                    //       padding: const EdgeInsets.symmetric(
                    //           horizontal: 12, vertical: 1),
                    //       child: GestureDetector(
                    //         onTap: () {
                    //           // Navigator.push(
                    //           //     context,
                    //           //     MaterialPageRoute(
                    //           //         builder: (context) => SellerProfile(
                    //           //               sellerStoreName: sellerList[index]
                    //           //                       .store_name ??
                    //           //                   "",
                    //           //               sellerRating: sellerList[index]
                    //           //                       .seller_rating ??
                    //           //                   "",
                    //           //               sellerImage: sellerList[index]
                    //           //                       .seller_profile ??
                    //           //                   "",
                    //           //               sellerName: sellerList[index]
                    //           //                       .seller_name ??
                    //           //                   "",
                    //           //               sellerID:
                    //           //                   sellerList[index].seller_id,
                    //           //               storeDesc: sellerList[index]
                    //           //                   .store_description,
                    //           //             )));
                    //           if(topSellerList[index].online == "1"){
                    //             Navigator.push(
                    //                 context,
                    //                 MaterialPageRoute(
                    //                     builder: (context) => SubCategory(
                    //                       title: topSellerList[index]
                    //                           .store_name
                    //                           .toString(),
                    //                       sellerId: topSellerList[index]
                    //                           .seller_id
                    //                           .toString(),
                    //                       sellerData: topSellerList[index],
                    //                     )));
                    //           } else {
                    //             setSnackbar("Store is Close!!", context);
                    //           }
                    //         },
                    //         child: Column(
                    //           mainAxisAlignment:
                    //           MainAxisAlignment.spaceAround,
                    //           mainAxisSize: MainAxisSize.min,
                    //           crossAxisAlignment: CrossAxisAlignment.start,
                    //           children: <Widget>[
                    //             Card(
                    //               elevation: 2,
                    //               shape: RoundedRectangleBorder(
                    //                   borderRadius:
                    //                   BorderRadius.circular(10)),
                    //               child: Container(
                    //                 // decoration: BoxDecoration(
                    //                 //     borderRadius:
                    //                 //         BorderRadius.circular(10),
                    //                 //     image: DecorationImage(
                    //                 //         fit: BoxFit.cover,
                    //                 //         // opacity: .05,
                    //                 //         image: NetworkImage(
                    //                 //             sellerList[index]
                    //                 //                 .seller_profile!))),
                    //                 child: Row(
                    //                   children: [
                    //                     Container(
                    //                       height: 120,
                    //                       width: 110,
                    //                       padding: EdgeInsets.only(left: 10,top: 5,bottom: 5),
                    //                       child: ClipRRect(
                    //                         borderRadius:
                    //                         BorderRadius.circular(8),
                    //                         child: FadeInImage(
                    //                           fadeInDuration:
                    //                           Duration(milliseconds: 150),
                    //                           image:
                    //                           CachedNetworkImageProvider(
                    //                             topSellerList[index]
                    //                                 .seller_profile!,
                    //                           ),
                    //                           fit: BoxFit.cover,
                    //                           imageErrorBuilder: (context,
                    //                               error, stackTrace) =>
                    //                               erroWidget(50),
                    //                           placeholder: placeHolder(50),
                    //                         ),
                    //                       ),
                    //                     ),
                    //                     Expanded(
                    //                       child: Column(
                    //                         children: [
                    //                           ListTile(
                    //                             dense: true,
                    //                             title: Text(
                    //                               "${topSellerList[index].store_name!}",
                    //                               style: Theme.of(
                    //                                   context)
                    //                                   .textTheme
                    //                                   .caption!
                    //                                   .copyWith(
                    //                                 color: Theme.of(
                    //                                     context)
                    //                                     .colorScheme
                    //                                     .fontColor,
                    //                                 fontWeight:
                    //                                 FontWeight
                    //                                     .w600,
                    //                               ),
                    //                             ),
                    //                             subtitle: Text(
                    //                               "${topSellerList[index].store_description!}",
                    //                               maxLines: 2,
                    //                               style: Theme.of(
                    //                                   context)
                    //                                   .textTheme
                    //                                   .caption!
                    //                                   .copyWith(
                    //                                 color: Theme.of(
                    //                                     context)
                    //                                     .colorScheme
                    //                                     .fontColor,
                    //                                 fontWeight:
                    //                                 FontWeight
                    //                                     .w600,
                    //                               ),
                    //                             ),
                    //                             trailing: topSellerList[index].online == "1"
                    //                                 ? Text("Open",
                    //                               style: TextStyle(
                    //                                   color: Colors.green
                    //                               ),
                    //                             )
                    //                                 : Text("Close",
                    //                               style: TextStyle(
                    //                                   color: Colors.red
                    //                               ),
                    //                             ),
                    //                           ),
                    //                           Divider(
                    //                             height: 0,
                    //                           ),
                    //                           Padding(
                    //                             padding:
                    //                             const EdgeInsets.all(8.0),
                    //                             child: Row(
                    //                               mainAxisAlignment:
                    //                               MainAxisAlignment
                    //                                   .spaceBetween,
                    //                               children: [
                    //                                 FittedBox(
                    //                                   child: Row(
                    //                                     children: [
                    //                                       Icon(
                    //                                         Icons
                    //                                             .star_rounded,
                    //                                         color:
                    //                                         Colors.amber,
                    //                                         size: 15,
                    //                                       ),
                    //                                       Text(
                    //                                         "${topSellerList[index].seller_rating!}",
                    //                                         style: Theme.of(
                    //                                             context)
                    //                                             .textTheme
                    //                                             .caption!
                    //                                             .copyWith(
                    //                                             color: Theme.of(
                    //                                                 context)
                    //                                                 .colorScheme
                    //                                                 .fontColor,
                    //                                             fontWeight:
                    //                                             FontWeight
                    //                                                 .w600,
                    //                                             fontSize:
                    //                                             14),
                    //                                       ),
                    //                                     ],
                    //                                   ),
                    //                                 ),
                    //                                 topSellerList[index]
                    //                                     .estimated_time !=
                    //                                     ""
                    //                                     ? FittedBox(
                    //                                   child: Container(
                    //                                       child: Center(
                    //                                         child: Padding(
                    //                                           padding: const EdgeInsets
                    //                                               .symmetric(
                    //                                               horizontal:
                    //                                               5,
                    //                                               vertical:
                    //                                               2),
                    //                                           child: Text(
                    //                                             "${topSellerList[index].estimated_time}",
                    //                                             style: TextStyle(
                    //                                                 fontSize:
                    //                                                 14),
                    //                                           ),
                    //                                         ),
                    //                                       )),
                    //                                 )
                    //                                     : Container(),
                    //                                 // sellerList[index]
                    //                                 //             .food_person !=
                    //                                 //         ""
                    //                                 //     ? FittedBox(
                    //                                 //         child: Container(
                    //                                 //             child:
                    //                                 //                 Padding(
                    //                                 //           padding: const EdgeInsets
                    //                                 //                   .symmetric(
                    //                                 //               horizontal:
                    //                                 //                   5,
                    //                                 //               vertical:
                    //                                 //                   1),
                    //                                 //           child: Text(
                    //                                 //             "${sellerList[index].food_person}",
                    //                                 //             style: TextStyle(
                    //                                 //                 fontSize:
                    //                                 //                     14),
                    //                                 //           ),
                    //                                 //         )),
                    //                                 //       )
                    //                                 //     : Container(),
                    //                               ],
                    //                             ),
                    //                           ),
                    //                         ],
                    //                       ),
                    //                     )
                    //                   ],
                    //                 ),
                    //               ),
                    //             ),
                    //           ],
                    //         ),
                    //       ),
                    //     );
                    //   },
                    // ),

                    Container(
                      height: 180,
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      child: sponsorSellerList.length == 0
                          ? Center(
                              child: Text("No HomeKitchen to show"),
                            )
                          : ListView.builder(
                              itemCount: sponsorSellerList.length,
                              physics: ScrollPhysics(),
                              scrollDirection: Axis.horizontal,
                              itemBuilder: (c, index) {
                                return InkWell(
                                  onTap: () {
                                    if (sponsorSellerList[index].online ==
                                        "1") {
                                      Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                              builder: (context) => SubCategory(
                                                    fromSearch: false,
                                                    title:
                                                        sponsorSellerList[index]
                                                            .store_name
                                                            .toString(),
                                                    sellerId:
                                                        sponsorSellerList[index]
                                                            .seller_id
                                                            .toString(),
                                                    sellerData:
                                                        sponsorSellerList[
                                                            index],
                                                  )));
                                    } else {
                                      setSnackbar(
                                          "Restaurant is Close!!", context);
                                    }
                                  },
                                  child: Container(
                                    width: 170,
                                    child: Card(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Container(
                                            height: 110,
                                            width: 160,
                                            child: ClipRRect(
                                              borderRadius: BorderRadius.only(
                                                  topLeft: Radius.circular(10),
                                                  topRight:
                                                      Radius.circular(10)),
                                              child: FadeInImage(
                                                fadeInDuration:
                                                    Duration(milliseconds: 150),
                                                image:
                                                    CachedNetworkImageProvider(
                                                  sponsorSellerList[index]
                                                      .seller_profile!,
                                                ),
                                                fit: BoxFit.fill,
                                                imageErrorBuilder: (context,
                                                        error, stackTrace) =>
                                                    erroWidget(50),
                                                placeholder: placeHolder(50),
                                              ),
                                            ),
                                          ),
                                          SizedBox(
                                            height: 5,
                                          ),
                                          Padding(
                                            padding: EdgeInsets.only(
                                                left: 5, right: 5),
                                            child: Text(
                                              "${sponsorSellerList[index].store_name!}",
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .caption!
                                                  .copyWith(
                                                    color: Theme.of(context)
                                                        .colorScheme
                                                        .fontColor,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                              maxLines: 2,
                                            ),
                                          ),
                                          Container(
                                            width: 160,
                                            padding: EdgeInsets.symmetric(
                                                horizontal: 5),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment
                                                          .spaceBetween,
                                                  children: [
                                                    sponsorSellerList[index]
                                                                .online ==
                                                            "1"
                                                        ? Text(
                                                            "Open",
                                                            style: TextStyle(
                                                                color: Colors
                                                                    .green),
                                                          )
                                                        : StreamBuilder<Object>(
                                                            stream: null,
                                                            builder: (context,
                                                                snapshot) {
                                                              return Padding(
                                                                padding: EdgeInsets
                                                                    .only(
                                                                        left:
                                                                            5),
                                                                child: Text(
                                                                  "Close",
                                                                  style: TextStyle(
                                                                      color: Colors
                                                                          .red),
                                                                ),
                                                              );
                                                            }),
                                                    Container(
                                                      child: Row(
                                                        children: [
                                                          Icon(
                                                            Icons.star_rounded,
                                                            color: Colors.amber,
                                                            size: 15,
                                                          ),
                                                          Text(
                                                            "${sponsorSellerList[index].seller_rating!}",
                                                            style: Theme.of(
                                                                    context)
                                                                .textTheme
                                                                .caption!
                                                                .copyWith(
                                                                    color: Theme.of(
                                                                            context)
                                                                        .colorScheme
                                                                        .fontColor,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .w600,
                                                                    fontSize:
                                                                        14),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                sponsorSellerList[index]
                                                            .storeIndicator ==
                                                        "1"
                                                    ? Image.asset(
                                                        "assets/images/vegImage.png",
                                                        height: 15,
                                                        width: 15,
                                                      )
                                                    : sponsorSellerList[index]
                                                                .storeIndicator ==
                                                            "2"
                                                        ? Image.asset(
                                                            "assets/images/non-vegImage.png",
                                                            height: 15,
                                                            width: 15,
                                                          )
                                                        : Row(
                                                            crossAxisAlignment:
                                                                CrossAxisAlignment
                                                                    .start,
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
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              }),
                    ),
                  ],
                ),
              );
      },
      selector: (_, homeProvider) => homeProvider.sellerLoading,
    );
  }
}
