import 'dart:async';
import 'dart:convert';

import 'package:homely_user/Helper/Color.dart';
import 'package:homely_user/Helper/Constant.dart';
import 'package:homely_user/Helper/app_assets.dart';
import 'package:homely_user/Helper/cropped_container.dart';
import 'package:homely_user/Provider/SettingProvider.dart';
import 'package:homely_user/Provider/UserProvider.dart';
import 'package:homely_user/Screen/NewLocationPage.dart';
import 'package:homely_user/Screen/Set_Password.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sms_autofill/sms_autofill.dart';

import '../Helper/AppBtn.dart';
import '../Helper/Session.dart';
import '../Helper/String.dart';
import 'SignUp.dart';

class VerifyOtp extends StatefulWidget {
  final String? mobileNumber, countryCode, title;
  final signUp, otp;

  VerifyOtp(
      {Key? key,
      required String this.mobileNumber,
      this.countryCode,
      this.title, this.signUp, this.otp})
      : assert(mobileNumber != null),
        super(key: key);

  @override
  _MobileOTPState createState() => _MobileOTPState();
}

class _MobileOTPState extends State<VerifyOtp> with TickerProviderStateMixin {
  final dataKey = GlobalKey();
  String? password;
  String? otp;
  bool isCodeSent = false;
  late String _verificationId;
  String signature = "";
  bool _isClickable = false;
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  String? mobile,
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

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  setPrefrenceBool(String key, bool value) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }
  Animation? buttonSqueezeanimation;
  AnimationController? buttonController;

  @override
  void initState() {
    super.initState();
    getUserDetails();
    getSingature();
    // _onVerifyCode();
    Future.delayed(Duration(seconds: 60)).then((_) {
      _isClickable = true;
    });
    buttonController = AnimationController(
        duration: Duration(milliseconds: 2000), vsync: this);
    buttonSqueezeanimation = Tween(
      begin: deviceWidth! * 0.7,
      end: 50.0,
    ).animate(CurvedAnimation(
      parent: buttonController!,
      curve: Interval(
      0.0,
        0.150,
      ),
    ));
  }

  Future<void> getSingature() async {
    signature = await SmsAutoFill().getAppSignature;
    await SmsAutoFill().listenForCode;
  }

  getUserDetails() async {
    SettingProvider settingsProvider =
        Provider.of<SettingProvider>(context, listen: false);
    if (mounted) setState(() {});
  }





  Future<void> checkNetworkOtp() async {
    bool avail = await isNetworkAvailable();
    if (avail) {
      if (_isClickable) {
        // _onVerifyCode();
        getVerifyUser();
      } else {
        setSnackbar(getTranslated(context, 'OTPWR')!);
      }
    } else {
      if (mounted) setState(() {});

      Future.delayed(Duration(seconds: 60)).then((_) async {
        bool avail = await isNetworkAvailable();
        if (avail) {
          if (_isClickable)
            // _onVerifyCode();
            getVerifyUser();
          else {
            setSnackbar(getTranslated(context, 'OTPWR')!);
          }
        } else {
          await buttonController!.reverse();
          setSnackbar(getTranslated(context, 'somethingMSg')!);
        }
      });
    }
  }

  Widget verifyBtn() {
    return AppBtn(
        title: getTranslated(context, 'VERIFY_AND_PROCEED'),
        btnAnim: buttonSqueezeanimation,
        btnCntrl: buttonController,
        onBtnSelected: () async {
          // widget.signUp?
          // _onFormSubmitted()
               getOtpVerified();
        });
  }

  setSnackbar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(
        msg,
        textAlign: TextAlign.center,
        style: TextStyle(color: Theme.of(context).colorScheme.fontColor),
      ),
      backgroundColor: Theme.of(context).colorScheme.lightWhite,
      elevation: 1.0,
    ));
  }

  void _onVerifyCode() async {
    if (mounted)
      setState(() {
        isCodeSent = true;
      });
    final PhoneVerificationCompleted verificationCompleted =
        (AuthCredential phoneAuthCredential) {
      _firebaseAuth
          .signInWithCredential(phoneAuthCredential)
          .then((UserCredential value) {
        if (value.user != null) {
          SettingProvider settingsProvider =
              Provider.of<SettingProvider>(context, listen: false);
          setSnackbar(getTranslated(context, 'OTPMSG')!);
          settingsProvider.setPrefrence(MOBILE, widget.mobileNumber!);
          settingsProvider.setPrefrence(COUNTRY_CODE, widget.countryCode!);
          if (widget.title == getTranslated(context, 'SEND_OTP_TITLE')) {
            Future.delayed(Duration(seconds: 2)).then((_) {
              Navigator.pushReplacement(
                  context, MaterialPageRoute(builder: (context) => SignUp()));
            });
          } else if (widget.title ==
              getTranslated(context, 'FORGOT_PASS_TITLE')) {
            Future.delayed(Duration(seconds: 2)).then((_) {
              Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                      builder: (context) =>
                          SetPass(mobileNumber: widget.mobileNumber!)));
            });
          }
        } else {
          setSnackbar(getTranslated(context, 'OTPERROR')!);
        }
      }).catchError((error) {
        setSnackbar("OTP is not correct");
        setSnackbar(error.toString());
      });
    };
    final PhoneVerificationFailed verificationFailed =
        (FirebaseAuthException authException) {
      setSnackbar("OTP is not correct");
      if (mounted)
        setState(() {
          isCodeSent = false;
        });
    };

    final PhoneCodeSent codeSent =
        (String verificationId, [int? forceResendingToken]) async {
      _verificationId = verificationId;
      if (mounted)
        setState(() {
          _verificationId = verificationId;
        });
    };
    final PhoneCodeAutoRetrievalTimeout codeAutoRetrievalTimeout =
        (String verificationId) {
      _verificationId = verificationId;
      if (mounted)
        setState(() {
          _isClickable = true;
          _verificationId = verificationId;
        });
    };

    await _firebaseAuth.verifyPhoneNumber(
        phoneNumber: "+${widget.countryCode}${widget.mobileNumber}",
        timeout: const Duration(seconds: 60),
        verificationCompleted: verificationCompleted,
        verificationFailed: verificationFailed,
        codeSent: codeSent,
        codeAutoRetrievalTimeout: codeAutoRetrievalTimeout);
  }

  void getOtpVerified(){
    if (otp == widget.otp.toString()) {
      SettingProvider settingsProvider =
      Provider.of<SettingProvider>(context, listen: false);
      setSnackbar(getTranslated(context, 'OTPMSG')!);
      settingsProvider.setPrefrence(MOBILE, widget.mobileNumber!);
      // settingsProvider.setPrefrence(COUNTRY_CODE, widget.countryCode!);
      if (widget.title == getTranslated(context, 'SEND_OTP_TITLE')) {
        Future.delayed(Duration(seconds: 2)).then((_) {
          Navigator.pushReplacement(
              context, MaterialPageRoute(builder: (context) => SignUp(
            mobile: widget.mobileNumber,
            countryCode: widget.countryCode,
          )));
        });
      } else if (widget.title ==
          getTranslated(context, 'FORGOT_PASS_TITLE')) {
        Future.delayed(Duration(seconds: 2)).then((_) {
          Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                  builder: (context) =>
                      SetPass(mobileNumber: widget.mobileNumber!)));
        });
      } else if (widget.title == getTranslated(context, 'SIGNIN_LBL')) {
        Future.delayed(Duration(seconds: 2)).then((_) {
         // Navigator.pushNamedAndRemoveUntil(context, "/home", (r) => false);
          Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (Context) => NewLocationPage()), (route) => false);
        });
      }
    }else{
      setSnackbar('Please Enter Valid OTP');
    }
  }
  Future<void> getVerifyUser() async {
    try {
      var data = {MOBILE: widget.mobileNumber,};
      Response response =
      await post(getVerifyUserApi, body: data, headers: headers)
          .timeout(Duration(seconds: timeOut));

      var getdata = json.decode(response.body);
      print("lofin" + getdata.toString());
      bool? error = getdata["error"];
      String? msg = getdata["message"];
      await buttonController!.reverse();

      SettingProvider settingsProvider =
      Provider.of<SettingProvider>(context, listen: false);

      if (widget.title == getTranslated(context, 'SEND_OTP_TITLE')) {
        if (!error!) {
          setSnackbar(msg!);

          // settingsProvider.setPrefrence(MOBILE, mobile!);
          // settingsProvider.setPrefrence(COUNTRY_CODE, countrycode!);
          if (widget.mobileNumber!.length == 10) {
            Future.delayed(Duration(seconds: 1)).then((_) {
              Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                      builder: (context) => VerifyOtp(
                        mobileNumber: widget.mobileNumber!,
                        countryCode: widget.countryCode,
                        otp: "${getdata['data']['otp']}",
                        title: getTranslated(context, 'SEND_OTP_TITLE'),
                      )));
              print('___otp________${otp}__________');
            });
          }else{
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(
                "Please enter valid mobile number!",
                textAlign: TextAlign.center,
                style: TextStyle(color: Theme.of(context).colorScheme.fontColor),
              ),
              backgroundColor: Theme.of(context).colorScheme.lightWhite,
              elevation: 1.0,
            ));
          }
        } else {
          setSnackbar("OTP is not correct");
          setSnackbar(msg!);
        }
      }
      if (widget.title == getTranslated(context, 'FORGOT_PASS_TITLE')) {
        if (!error!) {
           int otp = getdata["data"]["otp"];
          settingsProvider.setPrefrence(MOBILE, widget.mobileNumber!);
          settingsProvider.setPrefrence(COUNTRY_CODE, widget.countryCode!);
          Future.delayed(Duration(seconds: 1)).then((_) {
            Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                    builder: (context) => VerifyOtp(
                      mobileNumber: widget.mobileNumber!,
                      countryCode: widget.countryCode ,
                      otp: "${getdata['data']['otp']}",
                      title: getTranslated(context, 'FORGOT_PASS_TITLE'),
                    )));
          });
        } else {
          setSnackbar("OTP is not correct");
          setSnackbar(getTranslated(context, 'FIRSTSIGNUP_MSG')!);
        }
      }
    } on TimeoutException catch (_) {
      setSnackbar(getTranslated(context, 'somethingMSg')!);
      await buttonController!.reverse();
    }
  }

  otpCheck ()async {
    if (widget.otp.toString() == otp.toString()) {
      SettingProvider settingsProvider =
      Provider.of<SettingProvider>(context, listen: false);

      setSnackbar(getTranslated(context, 'OTPMSG')!);
      settingsProvider.setPrefrence(MOBILE, widget.mobileNumber!);
      settingsProvider.setPrefrence(COUNTRY_CODE, widget.countryCode!);
      if (widget.title == getTranslated(context, 'SEND_OTP_TITLE')) {
        Future.delayed(Duration(seconds: 2)).then((_) {
          Navigator.pushReplacement(
              context, MaterialPageRoute(builder: (context) => SignUp()));
        });
      } else if (widget.title ==
          getTranslated(context, 'FORGOT_PASS_TITLE')) {
        Future.delayed(Duration(seconds: 2)).then((_) {
          Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                  builder: (context) =>
                      SetPass(mobileNumber: widget.mobileNumber!)));
        });
      }
    }else{

    }
  }

  /*Future<void> getOtpVerified() async {
    var data = {MOBILE: widget.mobileNumber, OTP: otp};
    Response response = await post(getOtpVerify, body: data, headers: headers)
        .timeout(Duration(seconds: timeOut));
    var getdata = json.decode(response.body);
    print(getdata);
    bool error = getdata["error"];
    String? msg = getdata["message"];
    await buttonController!.reverse();
    if (error == true) {
      var i = getdata["data"];
      id = i[ID];
      email = i[EMAIL];
      if(email == ""){
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
        setPrefrenceBool(ISFIRSTTIME, true);
        Navigator.pushNamedAndRemoveUntil(context, "/home", (r) => false);
      } else {
        Navigator.push(context, MaterialPageRoute(builder: (context) => SignUp(mobile: widget.mobileNumber, countryCode: widget.countryCode)));
      }

      // Navigator.push(context, MaterialPageRoute(builder: (context)=> VerifyOtp(mobileNumber: mobile.toString())));
    } else {
      setSnackbar(msg!);
    }
  }*/

  void _onFormSubmitted() async {
    String code = otp!.trim();

    if (code.length == 6) {
      _playAnimation();
      AuthCredential _authCredential = PhoneAuthProvider.credential(
          verificationId: _verificationId, smsCode: code);
      _firebaseAuth
          .signInWithCredential(_authCredential)
          .then((UserCredential value) async {
        if (value.user != null) {
          SettingProvider settingsProvider =
              Provider.of<SettingProvider>(context, listen: false);
          await buttonController!.reverse();
          setSnackbar(getTranslated(context, 'OTPMSG')!);
          settingsProvider.setPrefrence(MOBILE, widget.mobileNumber!);
          settingsProvider.setPrefrence(COUNTRY_CODE, widget.countryCode!);
          if (widget.title == getTranslated(context, 'SEND_OTP_TITLE')) {
            Future.delayed(Duration(seconds: 2)).then((_) {
              Navigator.pushReplacement(
                  context, MaterialPageRoute(builder: (context) => SignUp()));
            });
          } else if (widget.title ==
              getTranslated(context, 'FORGOT_PASS_TITLE')) {
            Future.delayed(Duration(seconds: 2)).then((_) {
              Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                      builder: (context) =>
                          SetPass(mobileNumber: widget.mobileNumber!)));
            });
          }
        } else {
          setSnackbar(getTranslated(context, 'OTPERROR')!);
          await buttonController!.reverse();
        }
      }).catchError((error) async {
        setSnackbar(getTranslated(context, 'WRONGOTP')!);
        await buttonController!.reverse();
      });
    } else {
      setSnackbar(getTranslated(context, 'ENTEROTP')!);
    }
  }

  Future<Null> _playAnimation() async {
    try {
      await buttonController!.forward();
    } on TickerCanceled {}
  }

  getImage() {
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

  @override
  void dispose() {
    buttonController!.dispose();
    super.dispose();
  }

  monoVarifyText() {
    return Padding(
        padding: EdgeInsetsDirectional.only(
          top: 20.0,
        ),
        child: Center(
          child: Text(getTranslated(context, 'MOBILE_NUMBER_VARIFICATION')!,
              style: Theme.of(context).textTheme.subtitle1!.copyWith(
                  color: colors.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 25)),
        ));
  }

  otpText() {
    return Padding(
        padding: EdgeInsetsDirectional.only(top: 30.0, start: 20.0, end: 20.0),
        child: Center(
          child: Text(getTranslated(context, 'SENT_VERIFY_CODE_TO_NO_LBL')!,
              style: Theme.of(context).textTheme.subtitle2!.copyWith(
                  color: Theme.of(context).colorScheme.fontColor,
                  fontWeight: FontWeight.normal)),
        ),
    );
  }

  mobText() {
    return Padding(
      padding: EdgeInsetsDirectional.only(
          bottom: 10.0, start: 20.0, end: 20.0, top: 10.0),
      child: Column(
        children: [
          Center(
            child: Text("+91-${widget.mobileNumber}",
                style: Theme.of(context).textTheme.subtitle1!.copyWith(
                    color: Theme.of(context).colorScheme.fontColor,
                    fontWeight: FontWeight.normal)),
          ),
          SizedBox(height: 5,),
          Text("OTP: ${widget.otp}",
              style: Theme.of(context).textTheme.subtitle1!.copyWith(
                  color: Theme.of(context).colorScheme.fontColor,
                  fontWeight: FontWeight.normal)),
        ],
      ),
    );
  }

  Widget otpLayout() {
    return Padding(
        padding: EdgeInsetsDirectional.only(
          start: 50.0,
          end: 50.0,
        ),
        child: Center(
            child: PinFieldAutoFill(
                decoration: UnderlineDecoration(
                  textStyle: TextStyle(
                      fontSize: 20,
                      color: Theme.of(context).colorScheme.fontColor),
                  colorBuilder: FixedColorBuilder(colors.primary),
                ),
                currentCode: otp,
                codeLength: 6,
                onCodeChanged: (String? code) {
                  otp = code;
                },
                onCodeSubmitted: (String code) {
                  otp = code;
                })));
  }

  Widget resendText() {
    return Padding(
      padding: EdgeInsetsDirectional.only(
          bottom: 30.0, start: 25.0, end: 25.0, top: 10.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            getTranslated(context, 'DIDNT_GET_THE_CODE')!,
            style: Theme.of(context).textTheme.caption!.copyWith(
                color: Theme.of(context).colorScheme.fontColor,
                fontWeight: FontWeight.normal),
          ),
          InkWell(
              onTap: () async {
                await buttonController!.reverse();
                checkNetworkOtp();
              },
              child: Text(
                getTranslated(context, 'RESEND_OTP')!,
                style: Theme.of(context).textTheme.caption!.copyWith(
                    color: Theme.of(context).colorScheme.fontColor,
                    decoration: TextDecoration.underline,
                    fontWeight: FontWeight.normal),
              ))
        ],
      ),
    );
  }

  expandedBottomView() {
    return Expanded(
      flex: 6,
      child: Container(
        alignment: Alignment.bottomCenter,
        child: ScrollConfiguration(
            behavior: MyBehavior(),
            child: SingleChildScrollView(
              child: Card(
                elevation: 0.5,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                margin: EdgeInsetsDirectional.only(start: 20.0, end: 20.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    monoVarifyText(),
                    otpText(),
                    mobText(),
                    // Text("wsfs"),
                    otpLayout(),
                    verifyBtn(),
                    resendText(),
                  ],
                ),
              ),
            )),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        resizeToAvoidBottomInset: false,
        key: _scaffoldKey,
        body: Stack(
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
        ));
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
              bottom: MediaQuery.of(context).viewInsets.bottom * 0.6),
          height: MediaQuery.of(context).size.height * 0.7,
          width: MediaQuery.of(context).size.width * 0.95,
          color: Theme.of(context).colorScheme.white,
          child: Form(
            // key: _formkey,
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
                      monoVarifyText(),
                      otpText(),
                      mobText(),
                      //Text("${widget.otp}"),
                      otpLayout(),
                      verifyBtn(),
                      resendText(),
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
}
