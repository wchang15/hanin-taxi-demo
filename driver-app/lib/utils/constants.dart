// API address for IOS
//const String API_ADDRESS = 'https://localhost:7023/api/';

// API address for android
import 'dart:ui';

const String API_ADDRESS = String.fromEnvironment('API_BASE_URL',
    defaultValue: 'http://127.0.0.1:5050/api/');
const String HUB_ADDRESS = String.fromEnvironment('HUB_BASE_URL',
    defaultValue: 'http://127.0.0.1:5050/Taxi');

//Secure Storage
const String JWT = 'jwt';
const String REFRESH = 'refresh';

//Routes
const String HOME = '/home';
const String LOGIN = '/login';
const String INITIAL = '/initial';
const String TRIP = '/trip';
const String TRIPHISTORY = '/triphistory';
const String SELECTLOCATION = '/selectlocation';

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
const int STATUSUPDATE = 30;
const int POLLINGTIMER = 5;
const int DEBOUNCE = 300;
const int MATCHTIMER = 15;
const int DOUBLECLICKDEBOUNCE = 200;

//Hub
const String HUBMATCH = "match";
const String HUBCUSTOMERCANCEL = "customercancel";
const String HUBCOMPANYCANCEL = "companycancel";
const String PRICEUPDATE = "priceupdate";
const String NOTEUPDATE = "noteupdate";
const String ALCOHOLDRIVERMATCH = "alcoholdrivermatch";
const String TRIPSTART = "tripstart";
