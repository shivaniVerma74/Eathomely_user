import 'dart:async';
import 'dart:convert';
import 'package:homely_user/Screen/NewLocationPage.dart';
import 'package:http/http.dart' as http;
import 'package:homely_user/Helper/String.dart';
import 'package:homely_user/Helper/app_assets.dart';
import 'package:homely_user/Helper/cropped_container.dart';
import 'package:homely_user/Provider/SettingProvider.dart';
import 'package:homely_user/Provider/UserProvider.dart';
import 'package:homely_user/Screen/HomePage.dart';
import 'package:homely_user/Screen/SendOtp.dart';
import 'package:homely_user/Screen/Verify_Otp.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart';
import 'package:provider/provider.dart';

import '../Helper/AppBtn.dart';
import '../Helper/Color.dart';
import '../Helper/Constant.dart';
import '../Helper/Session.dart';
import '../Model/SocialLoginModel.dart';
import 'Dashboard.dart';

class Login extends StatefulWidget {
  @override
  _LoginPageState createState() => new _LoginPageState();
}

class _LoginPageState extends State<Login> with TickerProviderStateMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();
  final mobileController = TextEditingController();
  final passwordController = TextEditingController();
  final emailController = TextEditingController();
  String? countryName;
  FocusNode? passFocus, monoFocus = FocusNode();

  bool showPassword = false;

  final GlobalKey<FormState> _formkey = GlobalKey<FormState>();
  bool visible = false;
  String? password,
      mobile,
      username,
      email,
      id,
      mobileno,
      city,
      area,
      pincode,
      address,
      latitude,
      longitude,
      image;
  bool _isNetworkAvail = true;
  Animation? buttonSqueezeanimation;

  AnimationController? buttonController;
  String? token;

  dynamic choose = "pass";

  bool otpOnOff = true;

  getToken() async {
    token = await FirebaseMessaging.instance.getToken();
  }

  @override
  void initState() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual,
        overlays: [SystemUiOverlay.top]);
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));
    super.initState();
    getToken();
    getSetting();
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

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual,
        overlays: SystemUiOverlay.values);
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ));
    buttonController!.dispose();
    super.dispose();
  }

  Future<Null> _playAnimation() async {
    try {
      await buttonController!.forward();
    } on TickerCanceled {}
  }

  void validateAndSubmit() async {
    if (validateAndSave()) {
      _playAnimation();
      checkNetwork();
    }
  }

  Future<void> checkNetwork() async {
    _isNetworkAvail = await isNetworkAvailable();
    if (_isNetworkAvail) {
      choose == "otp" ? getLoginUser() : getLoginPass();
    } else {
      Future.delayed(Duration(seconds: 2)).then((_) async {
        await buttonController!.reverse();
        if (mounted)
          setState(() {
            _isNetworkAvail = false;
          });
      });
    }
  }

  bool validateAndSave() {
    final form = _formkey.currentState!;
    form.save();
    if (form.validate()) {
      return true;
    }
    return false;
  }

  setSnackbar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(new SnackBar(
      content: new Text(
        msg,
        textAlign: TextAlign.center,
        style: TextStyle(color: Theme.of(context).colorScheme.fontColor),
      ),
      backgroundColor: Theme.of(context).colorScheme.lightWhite,
      elevation: 1.0,
    ));
  }

  Widget noInternet(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: EdgeInsetsDirectional.only(top: kToolbarHeight),
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

  Future<void> getLoginUser() async {
    var data = {MOBILE: mobile, FCM_ID: token};
    Response response =
        await post(getUserLoginApi, body: data, headers: headers)
            .timeout(Duration(seconds: timeOut));
    print("respose here of login  ${getUserLoginApi} and ${data}");
    var getdata = json.decode(response.body);
    print(getUserLoginApi);
    print(data);
    print(getdata);
    bool error = getdata["error"];
    String? msg = getdata["message"];
    String? otp = getdata["otp"];
    dynamic getData = getdata["data"];
    await buttonController!.reverse();
    setSnackbar(msg.toString());
    if (error == true) {
      print(getdata);
      var i = getdata["data"][0];
      id = i[ID];
      username = i[USERNAME];
      email = i[EMAIL];
      mobile = i[MOBILE];
      city = i[CITY];
      area = i[AREA];
      address = i[ADDRESS];
      pincode = i[PINCODE];
      latitude = i[LATITUDE];
      longitude = i[LONGITUDE];
      image = i[IMAGE];

      CUR_USERID = id;
      // CUR_USERNAME = username;

      UserProvider userProvider =
          Provider.of<UserProvider>(this.context, listen: false);
      userProvider.setName(username ?? "");
      userProvider.setEmail(email ?? "");
      userProvider.setProfilePic(image ?? "");

      SettingProvider settingProvider =
          Provider.of<SettingProvider>(context, listen: false);

      settingProvider.saveUserDetail(id!, username, email, mobile, city, area,
          address, pincode, latitude, longitude, image, context);

      // Navigator.pushNamedAndRemoveUntil(context, "/home", (r) => false);
      Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => VerifyOtp(
                  title: getTranslated(context, 'SIGNIN_LBL')!,
                  otp: otp,
                  signUp: false,
                  countryCode: countryName,
                  mobileNumber: mobile.toString())));
    } else {
      setSnackbar(msg!);
    }
  }

  Future<void> getLoginPass() async {
    var data = {EMAIL: emailController.text, PASSWORD: password, FCM_ID: token};
    Response response =
        await post(getUserLoginPassApi, body: data, headers: headers)
            .timeout(Duration(seconds: timeOut));
    var getdata = json.decode(response.body);
    print(getdata);
    bool error = getdata["error"];
    String? msg = getdata["message"];
    await buttonController!.reverse();

    if (error == false) {
      var i = getdata["data"][0];
      id = i[ID];
      username = i[USERNAME];
      email = i[EMAIL];
      mobile = i[MOBILE];
      city = i[CITY];
      area = i[AREA];
      address = i[ADDRESS];
      pincode = i[PINCODE];
      latitude = i[LATITUDE];
      longitude = i[LONGITUDE];
      image = i[IMAGE];

      CUR_USERID = id;
      // CUR_USERNAME = username;

      UserProvider userProvider =
          Provider.of<UserProvider>(this.context, listen: false);
      userProvider.setName(username ?? "");
      userProvider.setEmail(email ?? "");
      userProvider.setProfilePic(image ?? "");

      SettingProvider settingProvider =
          Provider.of<SettingProvider>(context, listen: false);

      settingProvider.saveUserDetail(id!, username, email, mobile, city, area,
          address, pincode, latitude, longitude, image, context);

      Navigator.pushNamedAndRemoveUntil(context, "/home", (r) => false);

      // Navigator.push(
      //     context,
      //     MaterialPageRoute(
      //         builder: (context) =>
      //             VerifyOtp(mobileNumber: mobile.toString())));
    } else {
      setSnackbar(msg!);
    }
  }

  Widget chooseType() {
    return Row(
      children: [
        otpOnOff
            ? Row(
                children: [
                  Radio(
                      value: "otp",
                      groupValue: choose,
                      onChanged: (val) {
                        setState(() {
                          choose = val;
                          otpOnOff = true;
                        });
                      }),
                  Text("OTP"),
                ],
              )
            : Container(),
        Row(
          children: [
            Radio(
                value: "pass",
                groupValue: choose,
                onChanged: (val) {
                  setState(() {
                    choose = val;
                  });
                }),
            Text("Password"),
          ],
        ),
      ],
    );
  }

  _subLogo() {
    return Expanded(
      flex: 4,
      child: Center(
        child: Image.asset(
          'assets/images/homelogo.png',
          scale: 4,
        ),
      ),
    );
  }

  signInTxt() {
    return Padding(
        padding: EdgeInsetsDirectional.only(
          top: 30.0,
        ),
        child: Align(
          alignment: Alignment.center,
          child: new Text(
            getTranslated(context, 'SIGNIN_LBL')!,
            style: Theme.of(context).textTheme.subtitle1!.copyWith(
                color: Theme.of(context).colorScheme.fontColor,
                fontWeight: FontWeight.bold),
          ),
        ));
  }

  setMobileNo() {
    return Container(
      width: MediaQuery.of(context).size.width * 0.85,
      padding: EdgeInsets.only(
        top: 30.0,
      ),
      child: TextFormField(
        maxLength: 10,
        onTap: () {
          setState(() {
            otpOnOff = true;
          });
        },
        onFieldSubmitted: (v) {
          FocusScope.of(context).requestFocus(passFocus);
        },
        keyboardType: TextInputType.number,
        controller: mobileController,
        style: TextStyle(
          color: Theme.of(context).colorScheme.fontColor,
          fontWeight: FontWeight.normal,
        ),
        focusNode: monoFocus,
        textInputAction: TextInputAction.next,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        validator: (val) => validateMob(
            val!,
            getTranslated(context, 'MOB_REQUIRED'),
            getTranslated(context, 'VALID_MOB')),
        onSaved: (String? value) {
          mobile = value;
        },
        decoration: InputDecoration(
          prefixIcon: Icon(
            Icons.phone_android,
            color: Theme.of(context).colorScheme.fontColor,
            size: 20,
          ),
          hintText: "Mobile Number",
          counterText: "",
          hintStyle: Theme.of(this.context).textTheme.subtitle2!.copyWith(
              color: Theme.of(context).colorScheme.fontColor,
              fontWeight: FontWeight.normal),
          filled: true,
          fillColor: Theme.of(context).colorScheme.white,
          contentPadding: EdgeInsets.symmetric(
            horizontal: 10,
            vertical: 5,
          ),
          focusedBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: colors.primary),
            borderRadius: BorderRadius.circular(7.0),
          ),
          prefixIconConstraints: BoxConstraints(
            minWidth: 40,
            maxHeight: 20,
          ),
          enabledBorder: UnderlineInputBorder(
            borderSide:
                BorderSide(color: Theme.of(context).colorScheme.lightBlack2),
            borderRadius: BorderRadius.circular(7.0),
          ),
        ),
      ),
    );

    // return Container(
    //   width: deviceWidth! * 0.7,
    //   padding: EdgeInsetsDirectional.only(
    //     top: 30.0,
    //   ),
    //   child: TextFormField(
    //     onFieldSubmitted: (v) {
    //       FocusScope.of(context).requestFocus(passFocus);
    //     },
    //     keyboardType: TextInputType.number,
    //     controller: mobileController,
    //     style: TextStyle(
    //         color: Theme.of(context).colorScheme.fontColor,
    //         fontWeight: FontWeight.normal),
    //     focusNode: monoFocus,
    //     textInputAction: TextInputAction.next,
    //     inputFormatters: [FilteringTextInputFormatter.digitsOnly],
    //     validator: (val) => validateMob(
    //         val!,
    //         getTranslated(context, 'MOB_REQUIRED'),
    //         getTranslated(context, 'VALID_MOB')),
    //     onSaved: (String? value) {
    //       mobile = value;
    //     },
    //     decoration: InputDecoration(
    //       prefixIcon: Icon(
    //         Icons.call_outlined,
    //         color: Theme.of(context).colorScheme.fontColor,
    //         size: 17,
    //       ),
    //       hintText: getTranslated(context, 'MOBILEHINT_LBL'),
    //       hintStyle: Theme.of(this.context).textTheme.subtitle2!.copyWith(
    //           color: Theme.of(context).colorScheme.fontColor,
    //           fontWeight: FontWeight.normal),
    //       filled: true,
    //       fillColor: Theme.of(context).colorScheme.lightWhite,
    //       contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    //       prefixIconConstraints: BoxConstraints(minWidth: 40, maxHeight: 20),
    //       focusedBorder: OutlineInputBorder(
    //         borderSide:
    //             BorderSide(color: Theme.of(context).colorScheme.fontColor),
    //         borderRadius: BorderRadius.circular(7.0),
    //       ),
    //       enabledBorder: UnderlineInputBorder(
    //         borderSide:
    //             BorderSide(color: Theme.of(context).colorScheme.lightWhite),
    //         borderRadius: BorderRadius.circular(7.0),
    //       ),
    //     ),
    //   ),
    // );
  }

  setEmailId() {
    return Container(
      width: MediaQuery.of(context).size.width * 0.85,
      padding: EdgeInsets.only(
        top: 30.0,
      ),
      child: TextFormField(
        onTap: () {
          setState(() {
            otpOnOff = true;
          });
        },
        onFieldSubmitted: (v) {
          FocusScope.of(context).requestFocus(passFocus);
        },
        keyboardType: TextInputType.emailAddress,
        controller: emailController,
        style: TextStyle(
          color: Theme.of(context).colorScheme.fontColor,
          fontWeight: FontWeight.normal,
        ),
        focusNode: monoFocus,
        textInputAction: TextInputAction.next,
        validator: (val) =>
            validateEmail(val!, "Email is required", "Enter a valid email"),
        onSaved: (String? value) {
          email = value;
        },
        decoration: InputDecoration(
          prefixIcon: Icon(
            Icons.email_outlined,
            color: Theme.of(context).colorScheme.fontColor,
            size: 20,
          ),
          hintText: "Email",
          counterText: "",
          hintStyle: Theme.of(this.context).textTheme.subtitle2!.copyWith(
              color: Theme.of(context).colorScheme.fontColor,
              fontWeight: FontWeight.normal),
          filled: true,
          fillColor: Theme.of(context).colorScheme.white,
          contentPadding: EdgeInsets.symmetric(
            horizontal: 10,
            vertical: 5,
          ),
          focusedBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: colors.primary),
            borderRadius: BorderRadius.circular(7.0),
          ),
          prefixIconConstraints: BoxConstraints(
            minWidth: 40,
            maxHeight: 20,
          ),
          enabledBorder: UnderlineInputBorder(
            borderSide:
                BorderSide(color: Theme.of(context).colorScheme.lightBlack2),
            borderRadius: BorderRadius.circular(7.0),
          ),
        ),
      ),
    );

    // return Container(
    //   width: deviceWidth! * 0.7,
    //   padding: EdgeInsetsDirectional.only(
    //     top: 30.0,
    //   ),
    //   child: TextFormField(
    //     onFieldSubmitted: (v) {
    //       FocusScope.of(context).requestFocus(passFocus);
    //     },
    //     keyboardType: TextInputType.number,
    //     controller: mobileController,
    //     style: TextStyle(
    //         color: Theme.of(context).colorScheme.fontColor,
    //         fontWeight: FontWeight.normal),
    //     focusNode: monoFocus,
    //     textInputAction: TextInputAction.next,
    //     inputFormatters: [FilteringTextInputFormatter.digitsOnly],
    //     validator: (val) => validateMob(
    //         val!,
    //         getTranslated(context, 'MOB_REQUIRED'),
    //         getTranslated(context, 'VALID_MOB')),
    //     onSaved: (String? value) {
    //       mobile = value;
    //     },
    //     decoration: InputDecoration(
    //       prefixIcon: Icon(
    //         Icons.call_outlined,
    //         color: Theme.of(context).colorScheme.fontColor,
    //         size: 17,
    //       ),
    //       hintText: getTranslated(context, 'MOBILEHINT_LBL'),
    //       hintStyle: Theme.of(this.context).textTheme.subtitle2!.copyWith(
    //           color: Theme.of(context).colorScheme.fontColor,
    //           fontWeight: FontWeight.normal),
    //       filled: true,
    //       fillColor: Theme.of(context).colorScheme.lightWhite,
    //       contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    //       prefixIconConstraints: BoxConstraints(minWidth: 40, maxHeight: 20),
    //       focusedBorder: OutlineInputBorder(
    //         borderSide:
    //         BorderSide(color: Theme.of(context).colorScheme.fontColor),
    //         borderRadius: BorderRadius.circular(7.0),
    //       ),
    //       enabledBorder: UnderlineInputBorder(
    //         borderSide:
    //         BorderSide(color: Theme.of(context).colorScheme.lightWhite),
    //         borderRadius: BorderRadius.circular(7.0),
    //       ),
    //     ),
    //   ),
    // );
  }

  setPass() {
    return Container(
      width: MediaQuery.of(context).size.width * 0.85,
      padding: EdgeInsets.only(
        top: 15.0,
      ),
      child: TextFormField(
        onFieldSubmitted: (v) {
          FocusScope.of(context).requestFocus(passFocus);
        },
        keyboardType: TextInputType.text,
        obscureText: showPassword == true ? false : true,
        controller: passwordController,
        style: TextStyle(
            color: Theme.of(context).colorScheme.fontColor,
            fontWeight: FontWeight.normal),
        focusNode: passFocus,
        textInputAction: TextInputAction.next,
        validator: (val) => validatePass(
            val!,
            getTranslated(context, 'PWD_REQUIRED'),
            getTranslated(context, 'PWD_LENGTH')),
        onSaved: (String? value) {
          password = value;
        },
        decoration: InputDecoration(
          suffixIcon: InkWell(
              onTap: () {
                // SettingProvider settingsProvider =
                // Provider.of<SettingProvider>(this.context, listen: false);
                //
                // settingsProvider.setPrefrence(ID, id!);
                // settingsProvider.setPrefrence(MOBILE, mobile!);

                // Navigator.push(
                //     context,
                //     MaterialPageRoute(
                //         builder: (context) => SendOtp(
                //               title:
                //                   getTranslated(context, 'FORGOT_PASS_TITLE'),
                //             )));

                setState(() {
                  showPassword = !showPassword;
                });
              },
              child: showPassword == true
                  ? Icon(Icons.visibility)
                  : Icon(Icons.visibility_off)),
          hintText: getTranslated(context, "PASSHINT_LBL")!,
          hintStyle: Theme.of(this.context).textTheme.subtitle2!.copyWith(
              color: Theme.of(context).colorScheme.fontColor,
              fontWeight: FontWeight.normal),
          //filled: true,
          fillColor: Theme.of(context).colorScheme.white,
          contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          suffixIconConstraints: BoxConstraints(minWidth: 40, maxHeight: 20),
          prefixIconConstraints: BoxConstraints(minWidth: 40, maxHeight: 20),
          // focusedBorder: OutlineInputBorder(
          //     //   borderSide: BorderSide(color: fontColor),
          //     // borderRadius: BorderRadius.circular(7.0),
          //     ),
          focusedBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: colors.primary),
            borderRadius: BorderRadius.circular(7.0),
          ),
          enabledBorder: UnderlineInputBorder(
            borderSide:
                BorderSide(color: Theme.of(context).colorScheme.lightBlack2),
            borderRadius: BorderRadius.circular(7.0),
          ),
        ),
      ),
    );
  }

  forgetPass() {
    return Padding(
        padding: EdgeInsetsDirectional.only(start: 25.0, end: 25.0, top: 10.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: <Widget>[
            InkWell(
              onTap: () {
                SettingProvider settingsProvider =
                    Provider.of<SettingProvider>(this.context, listen: false);

                settingsProvider.setPrefrence(ID, id!);
                settingsProvider.setPrefrence(MOBILE, mobile!);

                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => SendOtp(
                              title:
                                  getTranslated(context, 'FORGOT_PASS_TITLE'),
                            )));
              },
              child: Text(getTranslated(context, 'FORGOT_PASSWORD_LBL')!,
                  style: Theme.of(context).textTheme.subtitle2!.copyWith(
                      color: Theme.of(context).colorScheme.fontColor,
                      fontWeight: FontWeight.normal)),
            ),
          ],
        ));
  }

  termAndPolicyTxt() {
    return Padding(
      padding: const EdgeInsetsDirectional.only(
          bottom: 20.0, start: 25.0, end: 25.0, top: 10.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Text(getTranslated(context, 'DONT_HAVE_AN_ACC')!,
              style: Theme.of(context).textTheme.caption!.copyWith(
                  color: Theme.of(context).colorScheme.fontColor,
                  fontWeight: FontWeight.normal)),
          InkWell(
              onTap: () {
                Navigator.of(context).push(MaterialPageRoute(
                  builder: (BuildContext context) => SendOtp(
                    title: getTranslated(context, 'SEND_OTP_TITLE'),
                  ),
                ));
              },
              child: Text(
                getTranslated(context, 'SIGN_UP_LBL')!,
                style: Theme.of(context).textTheme.caption!.copyWith(
                    color: Theme.of(context).colorScheme.fontColor,
                    decoration: TextDecoration.underline,
                    fontWeight: FontWeight.normal),
              ))
        ],
      ),
    );
  }

  loginBtn() {
    return AppBtn(
      title: choose == "otp"
          ? getTranslated(context, 'SEND_OTP_TITLE')
          : getTranslated(context, 'LOGIN'),
      btnAnim: buttonSqueezeanimation,
      btnCntrl: buttonController,
      onBtnSelected: () async {
        validateAndSubmit();
      },
    );
  }

  _expandedBottomView() {
    return Expanded(
      flex: 6,
      child: Container(
        alignment: Alignment.bottomCenter,
        child: ScrollConfiguration(
            behavior: MyBehavior(),
            child: SingleChildScrollView(
              child: Form(
                key: _formkey,
                child: Card(
                  elevation: 0.5,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  margin: EdgeInsetsDirectional.only(
                      start: 20.0, end: 20.0, top: 20.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      signInTxt(),

                      choose == "pass" ? setEmailId() : setMobileNo(),
                      // setPass(),
                      forgetPass(),
                      loginBtn(),
                      termAndPolicyTxt(),
                    ],
                  ),
                ),
              ),
            )),
      ),
    );
  }

  final FirebaseAuth auth = FirebaseAuth.instance;
  String? firebaseGmail, firebaseUser;

  socialLogin() async {
    // Trigger the authentication flow
    final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
    // Obtain the auth details from the request
    final GoogleSignInAuthentication? googleAuth =
        await googleUser?.authentication;
    // Create a new credential
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth?.accessToken,
      idToken: googleAuth?.idToken,
    );
    // Once signed in, return the UserCredential
    final result = await FirebaseAuth.instance.signInWithCredential(credential);
    print("google result ${result}");
    setState(() {
      firebaseGmail = result.user!.email;
      firebaseUser = result.user!.displayName;
    });
    //  confirmDialog();
    socialLoginApi();
    print(
        "firebase data here ${result.user!.uid} ${result.user!.email} and ${result.user!.displayName}");
    // if(result != null){
    //   showDialog(context: context, builder: (context){
    //     return CustomDialog(textData: "Signing in... please wait",);
    //   });
    //   firebaseGmailLogin(result.user!.email.toString(), result.user!.displayName.toString());
    // }
  }

  socialLoginApi() async {
    var headers = {
      'Cookie': 'ci_session=fc3ca560626d2fb7c98ac81b81562908594a8d24'
    };
    var request =
        http.MultipartRequest('POST', Uri.parse(baseUrl + 'social_login'));
    request.fields.addAll(
        {'email': '${firebaseGmail}', 'name': '${firebaseUser}', 'mobile': ""});
    request.headers.addAll(headers);
    print(
        "checking response here now ${request.fields} and ${baseUrl}social_login");
    http.StreamedResponse response = await request.send();
    if (response.statusCode == 200) {
      var finalResult = await response.stream.bytesToString();
      final jsonResponse = SocialLoginModel.fromJson(json.decode(finalResult));
      print("cheking response here ${jsonResponse.data}");
      var i = jsonResponse.data![0];
      print("SRSRSRSRSRSRSR${i.mobile.toString()}");
      // print("${baseUrl+social_login}");
      id = i.id.toString();
      username = i.username.toString();
      email = i.email.toString();
      mobile = "";
      city = i.city.toString();
      area = i.area.toString();
      address = i.address.toString();
      pincode = i.pincode.toString();
      latitude = i.latitude.toString();
      longitude = i.longitude.toString();
      image = i.image.toString();
      CUR_USERID = id;
      // CUR_USERNAME = username;

      UserProvider userProvider =
          Provider.of<UserProvider>(this.context, listen: false);
      print("google login here ${username}");
      userProvider.setName(username ?? "");
      userProvider.setEmail(email ?? "");
      SettingProvider settingProvider =
          Provider.of<SettingProvider>(context, listen: false);

      settingProvider.saveUserDetail(id!, username, email, mobile, city, area,
          address, pincode, latitude, longitude, image, context);
      print("LLLLLLLLLLLLLLLLLLLL${settingProvider.mobile}");
      Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => NewLocationPage()),
          (route) => false);
      //Fluttertoast.showToast(msg: "Please add Mobile Number",);
      showDialog(
          context: context,
          builder: (context) {
            return StatefulBuilder(builder: (context, setState) {
              return AlertDialog(
                content: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text("Add your mobile number and update profile"),
                    SizedBox(
                      height: 15,
                    ),
                    InkWell(
                      onTap: () {
                        Navigator.pop(context);
                      },
                      child: Container(
                        height: 45,
                        width: 50,
                        decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(6),
                            color: colors.primary),
                        alignment: Alignment.center,
                        child: Text(
                          "Ok",
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w500),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            });
          });
    } else {
      print(response.reasonPhrase);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        resizeToAvoidBottomInset: false,
        key: _scaffoldKey,
        body: _isNetworkAvail
            ? Stack(
                children: [
                  Container(
                    width: double.infinity,
                    height: double.infinity,
                    decoration: back(),
                  ),
                  Image.asset(
                    'assets/images/doodle.png',
                    color: colors.primary,
                    fit: BoxFit.fill,
                    width: double.infinity,
                    height: double.infinity,
                  ),
                  getLoginContainer(),
                  getLogo(),
                ],
              )
            : noInternet(context));
  }

  getLoginContainer() {
    return Positioned.directional(
      start: MediaQuery.of(context).size.width * 0.025,
      // end: width * 0.025,
      // top: width * 0.45,
      top: MediaQuery.of(context).size.height * 0.2, //original
      //    bottom: height * 0.1,
      textDirection: Directionality.of(context),
      child: ClipPath(
        clipper: ContainerClipper(),
        child: Container(
          alignment: Alignment.center,
          padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom * 0.8),
          height: MediaQuery.of(context).size.height * 0.7,
          width: MediaQuery.of(context).size.width * 0.95,
          color: Theme.of(context).colorScheme.white,
          child: Form(
            key: _formkey,
            child: ScrollConfiguration(
              behavior: MyBehavior(),
              child: SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 2,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        height: MediaQuery.of(context).size.height * 0.10,
                      ),
                      setSignInLabel(),
                      chooseType(),
                      choose == "pass" ? setEmailId() : setMobileNo(),

                      choose == "pass" ? setPass() : Container(),
                      InkWell(
                        onTap: () {
                          // SettingProvider settingsProvider =
                          // Provider.of<SettingProvider>(this.context, listen: false);
                          //
                          // settingsProvider.setPrefrence(ID, id!);
                          // settingsProvider.setPrefrence(MOBILE, mobile!);

                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => SendOtp(
                                        title: getTranslated(
                                            context, 'FORGOT_PASS_TITLE'),
                                      )));
                        },
                        child: Container(
                          padding: EdgeInsets.only(right: 15, top: 10),
                          width: MediaQuery.of(context).size.width,
                          alignment: Alignment.centerRight,
                          child: Text(
                            getTranslated(context, "FORGOT_LBL")!,
                            style: TextStyle(
                              color: colors.primary,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      loginBtn(),
                      // termAndPolicyTxt(),
                      signUpLink(),
                      InkWell(
                          onTap: () {
                            socialLogin();
                          },
                          child: Container(
                            child: Card(
                                elevation: 2,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(100)),
                                child: Padding(
                                  padding: EdgeInsets.all(8.0),
                                  child: Image.asset(
                                      "assets/images/googleIcon.png"),
                                )),
                          )
                          // Container(
                          //   height: 45,
                          //   width: MediaQuery.of(context).size.width/2,
                          //   alignment: Alignment.center,
                          //   decoration: BoxDecoration(
                          //     color: colors.primary,
                          //     borderRadius: BorderRadius.circular(12),
                          //   ),
                          //   child: Text("SignIn with Google",style: TextStyle(color: Colors.white,fontSize: 14),),
                          // ),
                          ),
                      SizedBox(
                        height: MediaQuery.of(context).size.height * 0.10,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget getLogo() {
    return Positioned(
      // textDirection: Directionality.of(context),
      left: (MediaQuery.of(context).size.width / 2) - 50,
      // right: ((MediaQuery.of(context).size.width /2)-55),

      top: (MediaQuery.of(context).size.height * 0.2) - 50,
      //  bottom: height * 0.1,
      child: SizedBox(
        width: 100,
        height: 100,
        child: Image.asset(
          MyAssets.login_logo,
        ),
      ),
    );
  }

  Widget setSignInLabel() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      child: Align(
        alignment: Alignment.topLeft,
        child: Text(
          getTranslated(context, 'SIGNIN_LBL')!,
          style: const TextStyle(
            color: colors.primary,
            fontSize: 30,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget signUpLink() {
    return TextButton(
        onPressed: () {
          Navigator.of(context).push(
              MaterialPageRoute(
            builder: (BuildContext context) => SendOtp(
              title: getTranslated(context, 'SEND_OTP_TITLE'),
            ),
          ));
        },
        child: Text(
          "Create Account",
          style: TextStyle(color: colors.primary),
        ));
  }

  void getSetting() {
    CUR_USERID = context.read<SettingProvider>().userId;
    //print("")
    Map parameter = Map();
    if (CUR_USERID != null) parameter = {USER_ID: CUR_USERID};

    apiBaseHelper.postAPICall(getOtpSetting, parameter).then((getdata) async {
      bool error = getdata["error"];
      String? msg = getdata["message"];

      if (!error) {
        print(getdata);
        var data = getdata["date"][0]["value"];

        otpOnOff = data == "off" ? false : true;
      } else {}
    }, onError: (error) {});
  }
}
