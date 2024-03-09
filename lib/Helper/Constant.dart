import 'package:homely_user/Model/Section_Model.dart';
import 'package:homely_user/Model/User.dart';

final String appName = 'Eat Homely';

final String  packageName = 'com.homely.user';
final String androidLink = 'https://play.google.com/store/apps/details?id=';

final String iosPackage = 'com.homely.user';
final String iosLink = 'your ios link here';
final String appStoreId = '123456789';

final String deepLinkUrlPrefix = 'https://eshopmultivendor.page.link';
final String deepLinkName = 'Eatoz Food';

final int timeOut = 50;
const int perPage = 1000;

//final String baseUrl = 'https://vendor.eshopweb.store/app/v1/api/';
// final String baseUrl = 'https://alphawizztest.tk/Eatoz Food_Ecom/app/v1/api/';
// final String baseUrl = 'https://foodontheways.com/app/v1/api/';
//final String baseUrl = 'https://foodontheways.com/New_food/app/v1/api/';
/*final String baseUrl =
    'https://eatoz.in/app/v1/api/';*/

  final String baseUrl = "https://developmentalphawizz.com/eatoz_clone/app/v1/api/";
 //final String baseUrl = "https://developmentalphawizz.com/eatoz/app/v1/api/";
final String imageUrl = 'https://developmentalphawizz.com/';
//final String imageUrl = 'https://foodontheways.com/';
final String jwtKey = "8f40f544389363881e54c834185d09af460d0d66";
double latitudeFirst = 0;
double longitudeFirst = 0;
String zipCode = "";
List<User> addressList = [];
//List<SectionModel> cartList = [];
List<Promo> promoList = [];
//2009,3514
double totalPrice = 0, oriPrice = 0, delCharge = 0, taxPer = 0, platformFee = 0, packagingCharge = 0;
int? selectedAddress = 0;
String? selAddress, payMethod = '', selTime, selDate, promocode, schedule, immediately;
bool? isTimeSlot,
    isPromoValid = false,
    isUseWallet = false,
    isPayLayShow = true;
int? selectedTime, selectedDate, selectedMethod;

String? newSellerId;
double promoAmt = 0;
double remWalBal = 0, usedBal = 0;
bool isAvailable = true;
int newDeliveryCharge = 0;
String? razorpayId,
    paystackId,
    stripeId,
    stripeSecret,
    stripeMode = "test",
    stripeCurCode,
    stripePayId,
    paytmMerId,
    paytmMerKey;
bool payTesting = true;
List<SectionModel> sectionList = [];
List<Product> catList = [];
List<Product> popularList = [];
List<String> tagList = [];
List<Product> sellerList = [];
List<Product> topSellerList = [];
List<Product> sponsorSellerList = [];
int count = 1;
