
using KoreanTaxi.Models;
using KoreanTaxi.Models.Enums;
using Newtonsoft.Json;

namespace KoreanTaxi.Services
{
    public class GoogleService : IGoogleService
    {

        private readonly HttpClient httpClient;
        private readonly string apiKey;
        private readonly bool demoMode;

        public GoogleService(IConfiguration configuration, HttpClient httpClient)
        {
            this.httpClient = httpClient;
            apiKey = configuration["Mapbox:SecretToken"] ?? configuration["ConnectionStrings:mapBoxKey"] ?? string.Empty;
            demoMode = configuration.GetValue<bool>("DemoMode");
        }

        public async Task<List<GoogleLocation>> GetAutoComplete(string str)
        {
            var ret = new List<GoogleLocation>();

            if (demoMode)
            {
                return GetDemoLocations(str);
            }

            if (string.IsNullOrWhiteSpace(apiKey))
            {
                return ret;
            }

            var encodedSearch = Uri.EscapeDataString(str);
            var response = await httpClient.GetAsync($"https://api.mapbox.com/geocoding/v5/mapbox.places/{encodedSearch}.json?country=us&proximity=ip&types=poi%2Caddress%2Cplace&language=en&access_token={apiKey}");

            if (!response.IsSuccessStatusCode)
            {
                return ret;
            }

            var result = await response.Content.ReadAsStringAsync();

            var jsonObj = JsonConvert.DeserializeObject<dynamic>(result);

            try
            {
                foreach (var feature in jsonObj.features)
                {
                    string id = $"{feature.id}";
                    var type = GetType(id);
                    var gl = new GoogleLocation()
                    {
                        Name = type == MapBoxType.poi ? $"{feature.text}, {feature.properties.address}" : type == MapBoxType.address ? $"{feature.address} {feature.text}" : feature.text,
                        Address = feature.place_name,
                        Latitude = feature.geometry.coordinates[1],
                        Longitude = feature.geometry.coordinates[0],
                        LocationType = type == MapBoxType.poi ? GetLocationType($"{feature.properties.category}") : EnumLocationType.OTHER,

                    };
                    ModifyAddress(gl, type);


                    ret.Add(gl);
                }
            }
            catch (Exception ex)
            {
                
            }

            return ret;
        }

        //public List<GoogleLocation> GetAutoComplete1(string str)
        //{
        //    var ret = new List<GoogleLocation>();

        //    var req = new PlacesAutoCompleteRequest
        //    {
        //        Key = apiKey,
        //        Input = str,
        //        LocationTypes = new List<PlaceLocationType>() { PlaceLocationType.Geocode, PlaceLocationType.Establishment },
        //        Components = new Dictionary<Component, string>() { { Component.Country, "us" } },
        //        Language = Language.English,
        //    };

        //    var res = GooglePlaces.AutoComplete.Query(req);

        //    var predictions = res.Predictions.ToList();

        //    foreach (var prediction in predictions)
        //    {
        //        var gLocation = new GoogleLocation()
        //        {
        //            Name = prediction.StructuredFormatting.MainText,
        //            Address = GetAddress(prediction.StructuredFormatting.SecondaryText, prediction),
        //            Latitude = 0,
        //            Longitude = 0,
        //            LocationType = GetLocationType(prediction.Types.ToList())
        //        };
        //        ret.Add(gLocation);
        //    }

        //    return ret;
        //}

        /// <summary>
        /// Get the location type of the place. This is used to show icons, as well as to get correct fees for airport.
        /// </summary>
        /// <param name="types"></param>
        /// <returns></returns>
        private EnumLocationType GetLocationType(string types)
        {
            if (types.Contains("airport")) return EnumLocationType.AIRPORT;
            else if (types.Contains("restaurant")) return EnumLocationType.RESTAURANT;
            else if (types.Contains("store")) return EnumLocationType.STORE;
            else if (types.Contains("park")) return EnumLocationType.PARK;
            else if (types.Contains("school")) return EnumLocationType.SCHOOL;
            else if (types.Contains("hospital")) return EnumLocationType.HOSPITAL;
            return EnumLocationType.OTHER;
        }

        private MapBoxType GetType(string str)
        {
            if (str.Contains("poi")) return MapBoxType.poi;
            if (str.Contains("address")) return MapBoxType.address;
            if (str.Contains("place")) return MapBoxType.place;
            return MapBoxType.address;
        }

        private void ModifyAddress(GoogleLocation gl, MapBoxType type)
        {
            if (type == MapBoxType.poi || type == MapBoxType.address) 
            {
                var newAddress = gl.Address.Replace(gl.Name, "");
                newAddress = newAddress.TrimStart(' ', ',');
                gl.Address = newAddress;
            }
            if (type == MapBoxType.place) { } //Do Nothing 
            gl.Address = gl.Address.Replace(", United States", "");
        }

        private static List<GoogleLocation> GetDemoLocations(string search)
        {
            if (string.IsNullOrWhiteSpace(search)) return new List<GoogleLocation>();

            var locations = new List<GoogleLocation>
            {
                new()
                {
                    Name = "Hanin Taxi Demo Office",
                    Address = "100 Main St, Fort Lee, NJ 07024",
                    Latitude = 40.8509,
                    Longitude = -73.9701,
                    State = EnumState.NJ,
                    LocationType = EnumLocationType.OTHER,
                },
                new()
                {
                    Name = "Times Square",
                    Address = "Manhattan, New York, NY 10036",
                    Latitude = 40.7580,
                    Longitude = -73.9855,
                    State = EnumState.NYC,
                    LocationType = EnumLocationType.OTHER,
                },
                new()
                {
                    Name = "John F. Kennedy International Airport",
                    Address = "Queens, NY 11430",
                    Latitude = 40.6413,
                    Longitude = -73.7781,
                    State = EnumState.NYC,
                    LocationType = EnumLocationType.AIRPORT,
                },
                new()
                {
                    Name = "LaGuardia Airport",
                    Address = "Queens, NY 11371",
                    Latitude = 40.7769,
                    Longitude = -73.8740,
                    State = EnumState.NYC,
                    LocationType = EnumLocationType.AIRPORT,
                },
                new()
                {
                    Name = "Newark Liberty International Airport",
                    Address = "Newark, NJ 07114",
                    Latitude = 40.6895,
                    Longitude = -74.1745,
                    State = EnumState.NJ,
                    LocationType = EnumLocationType.AIRPORT,
                },
            };

            return locations
                .Where(location => location.Name.Contains(search, StringComparison.OrdinalIgnoreCase)
                    || location.Address.Contains(search, StringComparison.OrdinalIgnoreCase))
                .ToList();
        }

        ///// <summary>
        ///// When the MainText is Korean (only Korean) the secondary text becomes backwards with not abbreviation.
        ///// When the Secondary text is backwards, use terms to reconstruct it with the correct abbreviations.
        ///// </summary>
        ///// <param name="address"></param>
        ///// <param name="prediction"></param>
        ///// <returns></returns>
        //private string GetAddress(string address, Prediction prediction)
        //{

        //    if (address.StartsWith("United States,"))
        //    {
        //        var terms = prediction.Terms.Select(x => x.Value.ToString()).ToList();
        //        if (terms[^1] == "United States") terms[^1] = "USA";
        //        terms[^2] = GetStateByName(terms[^2]);

        //        var fullAddress = string.Join(", ", terms);
        //        var regex = new Regex(Regex.Escape(prediction.StructuredFormatting.MainText));
        //        var ret = regex.Replace(fullAddress, "", 1); // Remove main text for dup
        //        if (ret.StartsWith(", ")) ret = ret[2..];
        //        return ret;
        //    }
        //    return address;
        //}

        /// <summary>
        /// Given the full state name, return the abbreviated state name
        /// If cannot be found, return the param name
        /// </summary>
        /// <param name="name"></param>
        /// <returns></returns>
        //private string GetStateByName(string name)
        //{
        //    switch (name.ToUpper())
        //    {
        //        case "ALABAMA":
        //            return "AL";

        //        case "ALASKA":
        //            return "AK";

        //        case "AMERICAN SAMOA":
        //            return "AS";

        //        case "ARIZONA":
        //            return "AZ";

        //        case "ARKANSAS":
        //            return "AR";

        //        case "CALIFORNIA":
        //            return "CA";

        //        case "COLORADO":
        //            return "CO";

        //        case "CONNECTICUT":
        //            return "CT";

        //        case "DELAWARE":
        //            return "DE";

        //        case "DISTRICT OF COLUMBIA":
        //            return "DC";

        //        case "FEDERATED STATES OF MICRONESIA":
        //            return "FM";

        //        case "FLORIDA":
        //            return "FL";

        //        case "GEORGIA":
        //            return "GA";

        //        case "GUAM":
        //            return "GU";

        //        case "HAWAII":
        //            return "HI";

        //        case "IDAHO":
        //            return "ID";

        //        case "ILLINOIS":
        //            return "IL";

        //        case "INDIANA":
        //            return "IN";

        //        case "IOWA":
        //            return "IA";

        //        case "KANSAS":
        //            return "KS";

        //        case "KENTUCKY":
        //            return "KY";

        //        case "LOUISIANA":
        //            return "LA";

        //        case "MAINE":
        //            return "ME";

        //        case "MARSHALL ISLANDS":
        //            return "MH";

        //        case "MARYLAND":
        //            return "MD";

        //        case "MASSACHUSETTS":
        //            return "MA";

        //        case "MICHIGAN":
        //            return "MI";

        //        case "MINNESOTA":
        //            return "MN";

        //        case "MISSISSIPPI":
        //            return "MS";

        //        case "MISSOURI":
        //            return "MO";

        //        case "MONTANA":
        //            return "MT";

        //        case "NEBRASKA":
        //            return "NE";

        //        case "NEVADA":
        //            return "NV";

        //        case "NEW HAMPSHIRE":
        //            return "NH";

        //        case "NEW JERSEY":
        //            return "NJ";

        //        case "NEW MEXICO":
        //            return "NM";

        //        case "NEW YORK":
        //            return "NY";

        //        case "NORTH CAROLINA":
        //            return "NC";

        //        case "NORTH DAKOTA":
        //            return "ND";

        //        case "NORTHERN MARIANA ISLANDS":
        //            return "MP";

        //        case "OHIO":
        //            return "OH";

        //        case "OKLAHOMA":
        //            return "OK";

        //        case "OREGON":
        //            return "OR";

        //        case "PALAU":
        //            return "PW";

        //        case "PENNSYLVANIA":
        //            return "PA";

        //        case "PUERTO RICO":
        //            return "PR";

        //        case "RHODE ISLAND":
        //            return "RI";

        //        case "SOUTH CAROLINA":
        //            return "SC";

        //        case "SOUTH DAKOTA":
        //            return "SD";

        //        case "TENNESSEE":
        //            return "TN";

        //        case "TEXAS":
        //            return "TX";

        //        case "UTAH":
        //            return "UT";

        //        case "VERMONT":
        //            return "VT";

        //        case "VIRGIN ISLANDS":
        //            return "VI";

        //        case "VIRGINIA":
        //            return "VA";

        //        case "WASHINGTON":
        //            return "WA";

        //        case "WEST VIRGINIA":
        //            return "WV";

        //        case "WISCONSIN":
        //            return "WI";

        //        case "WYOMING":
        //            return "WY";

        //        default:
        //            return name;
        //    }
        //}
    }
}
