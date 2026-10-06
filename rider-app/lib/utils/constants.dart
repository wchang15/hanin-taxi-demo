// API address for IOS
//const String API_ADDRESS = 'https://localhost:7023/api/';

// API address for android
import 'dart:ui';

const String API_ADDRESS = String.fromEnvironment('API_BASE_URL',
    defaultValue: 'http://127.0.0.1:5050/api/');
const String HUB_ADDRESS = String.fromEnvironment('HUB_BASE_URL',
    defaultValue: 'http://127.0.0.1:5050/Taxi');
const bool DEMO_MODE = bool.fromEnvironment('DEMO_MODE', defaultValue: false);

const String MAPBOXAPI =
    String.fromEnvironment('MAPBOX_API_KEY', defaultValue: '');
const String STRIPEPK =
    String.fromEnvironment('STRIPE_PUBLISHABLE_KEY', defaultValue: '');
const double MAP_LOCATION_ZOOM = 17.5;
const double MAP_ROUTE_MAX_ZOOM = 16.5;
final double DEFAULT_MAP_LATITUDE =
    double.tryParse(const String.fromEnvironment(
          'DEFAULT_MAP_LATITUDE',
          defaultValue: '40.8509',
        )) ??
        40.8509;
final double DEFAULT_MAP_LONGITUDE =
    double.tryParse(const String.fromEnvironment(
          'DEFAULT_MAP_LONGITUDE',
          defaultValue: '-73.9701',
        )) ??
        -73.9701;

const String MAP_TILE_URL_TEMPLATE = String.fromEnvironment(
  'MAP_TILE_URL_TEMPLATE',
  defaultValue: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
);

//Secure Storage
const String JWT = 'jwt';
const String REFRESH = 'refresh';

//Routes
const String HOME = '/home';
const String LOGIN = '/login';
const String MAP = '/map';
const String PHOTO = '/photo';
const String CARD = '/card';
const String REGISTER = '/register';
const String PHONE = '/phone';
const String INITIAL = '/initial';
const String TRIPSETTING = '/tripsetting';
const String PAYMENTSELECT = '/paymentselect';
const String CARDADD = '/cardadd';
const String POINTADD = '/pointadd';
const String TRIP = '/trip';
const String SAVEDLOCATIONS = '/savedlocations';
const String SELECTLOCATION = '/selectlocation';
const String RATEDRIVER = '/ratedriver';
const String ADDPOINTSFROMCARD = '/addpoints';
const String DRIVERCANCEL = '/drivercancel';
const String LANGUAGE = '/language';
const String TERMS = '/terms';
const String TERM = '/term';
const String FINDIDPWD = '/findidpwd';
const String EVENT = '/event';
const String CUSTOMERSERVICE = '/customerservice';
const String TRIPHISTORY = '/triphistory';
const String PROFILE = '/profile';
const String PHONEEDIT = '/phoneedit';
const String PASSWORDEDIT = '/passwordedit';
const String SETTING = '/setting';

//Languages
const Locale KOREAN = Locale('ko', 'KR');
const Locale ENGLISH = Locale('en', 'US');
const Locale SPANISH = Locale('es', 'MX');
const String STRKOREAN = 'ko_KR';
const String STRENGLISH = 'en_US';
const String STRSPANISH = 'es_MX';

//This have to match API
const Map LANGUAGEMAP = {1: ENGLISH, 2: KOREAN, 3: SPANISH};

//Time
const int PICKUPUPDATE = 50;
const int STATUSUPDATE = 30;
const int DEBOUNCE = 300;

//TERMS

//Hub
const String HUBMATCH = "match";
const String HUBUPDATEDRIVERLOCATION = "updatedriverlocation";
const String HUBTRIPSTART = "tripstart";
const String HUBTRIPCOMPLETE = "tripcomplete";
const String HUBDRIVERCANCEL = "drivercancel";
