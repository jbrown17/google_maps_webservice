library google_maps_webservice.places.src;

import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart';
import 'core.dart';
import 'utils.dart';

const _placesUrl = "/place";
const _nearbySearchUrl = "/nearbysearch/json";
const _textSearchUrl = "/textsearch/json";
const _detailsSearchUrl = "/details/json";
const _autocompleteUrl = "/autocomplete/json";
const _queryAutocompleteUrl = "/queryautocomplete/json";

/// https://developers.google.com/places/web-service/
class GoogleMapsPlaces extends GoogleWebService {
  GoogleMapsPlaces({String apiKey, String baseUrl, Client httpClient})
      : super(
      apiKey: apiKey,
      baseUrl: baseUrl,
      url: _placesUrl,
      httpClient: httpClient);

  Future<PlacesSearchResponse> searchNearbyWithRadius(
      Location location, num radius,
      {String type,
        String keyword,
        String language,
        PriceLevel minprice,
        PriceLevel maxprice,
        String name}) async {
    final url = buildNearbySearchUrl(
        location: location,
        language: language,
        radius: radius,
        type: type,
        keyword: keyword,
        minprice: minprice,
        maxprice: maxprice,
        name: name);
    return _decodeSearchResponse(await doGet(url));
  }

  Future<PlacesSearchResponse> searchNearbyWithRankBy(
      Location location,
      String rankby, {
        String type,
        String keyword,
        String language,
        PriceLevel minprice,
        PriceLevel maxprice,
        String name,
      }) async {
    final url = buildNearbySearchUrl(
        location: location,
        language: language,
        type: type,
        rankby: rankby,
        keyword: keyword,
        minprice: minprice,
        maxprice: maxprice,
        name: name);
    return _decodeSearchResponse(await doGet(url));
  }

  Future<PlacesSearchResponse> searchByText(String query,
      {Location location,
        num radius,
        PriceLevel minprice,
        PriceLevel maxprice,
        bool opennow,
        String type,
        String pagetoken,
        String language}) async {
    final url = buildTextSearchUrl(
        query: query,
        location: location,
        language: language,
        type: type,
        radius: radius,
        minprice: minprice,
        maxprice: maxprice,
        pagetoken: pagetoken,
        opennow: opennow);
    return _decodeSearchResponse(await doGet(url));
  }

  Future<PlacesDetailsResponse> getDetailsByPlaceId(String placeId, {String fields, String extensions, String language}) async {
    final url = buildDetailsUrl(
        placeId: placeId,
        fields: fields,
        extensions: extensions,
        language: language
    );
    return _decodeDetailsResponse(await doGet(url));
  }

  Future<PlacesDetailsResponse> getDetailsByReference(String reference, {String fields, String extensions, String language}) async {
    final url = buildDetailsUrl(
        reference: reference,
        fields: fields,
        extensions: extensions,
        language: language
    );
    return _decodeDetailsResponse(await doGet(url));
  }

  Future<String> getDetailsJsonByPlaceId(String placeId, {String fields, String extensions, String language}) async {
    final url = buildDetailsUrl(
        placeId: placeId,
        fields: fields,
        extensions: extensions,
        language: language
    );
    var response = await doGet(url);
    return response.body;
  }

  Future<PlacesAutocompleteResponse> autocomplete(String input,
      {num offset,
        Location location,
        num radius,
        String language,
        List<String> types,
        List<Component> components,
        bool strictbounds}) async {
    final url = buildAutocompleteUrl(
        input: input,
        location: location,
        offset: offset,
        radius: radius,
        language: language,
        types: types,
        components: components,
        strictbounds: strictbounds);
    return _decodeAutocompleteResponse(await doGet(url));
  }

  Future<PlacesAutocompleteResponse> queryAutocomplete(String input,
      {num offset, Location location, num radius, String language}) async {
    final url = buildQueryAutocompleteUrl(
        input: input,
        location: location,
        offset: offset,
        radius: radius,
        language: language);
    return _decodeAutocompleteResponse(await doGet(url));
  }

  String buildNearbySearchUrl(
      {Location location,
        num radius,
        String type,
        String keyword,
        String language,
        PriceLevel minprice,
        PriceLevel maxprice,
        String name,
        String rankby,
        String pagetoken}) {
    if (radius != null && rankby != null) {
      throw new ArgumentError(
          "'rankby' must not be included if 'radius' is specified.");
    }

    if (rankby == "distance" &&
        keyword == null &&
        type == null &&
        name == null) {
      throw new ArgumentError(
          "If 'rankby=distance' is specified, then one or more of 'keyword', 'name', or 'type' is required.");
    }

    final params = {
      "location": location,
      "radius": radius,
      "language": language,
      "type": type,
      "keyword": keyword,
      "minprice": minprice?.index,
      "maxprice": maxprice?.index,
      "name": name,
      "rankby": rankby,
      "pagetoken": pagetoken
    };

    if (apiKey != null) {
      params.putIfAbsent("key", () => apiKey);
    }

    return "$url$_nearbySearchUrl?${buildQuery(params)}";
  }

  String buildTextSearchUrl(
      {String query,
        Location location,
        num radius,
        PriceLevel minprice,
        PriceLevel maxprice,
        bool opennow,
        String type,
        String pagetoken,
        String language}) {
    final params = {
      "query": query != null ? Uri.encodeComponent(query) : null,
      "language": language,
      "location": location,
      "radius": radius,
      "minprice": minprice?.index,
      "maxprice": maxprice?.index,
      "opennow": opennow,
      "type": type,
      "pagetoken": pagetoken
    };

    if (apiKey != null) {
      params.putIfAbsent("key", () => apiKey);
    }

    return "$url$_textSearchUrl?${buildQuery(params)}";
  }

  String buildDetailsUrl({String placeId, String reference, String fields, String extensions, String language}) {
    if (placeId != null && reference != null) {
      throw new ArgumentError(
          "You must supply either 'placeid' or 'reference'");
    }

    final params = {
      "placeid": placeId,
      "reference": reference,
      "language": language,
      "extensions": extensions,
      "fields": fields
    };

    if (apiKey != null) {
      params.putIfAbsent("key", () => apiKey);
    }

    return "$url$_detailsSearchUrl?${buildQuery(params)}";
  }

  String buildAutocompleteUrl(
      {String input,
        num offset,
        Location location,
        num radius,
        String language,
        List<String> types,
        List<Component> components,
        bool strictbounds}) {
    final params = {
      "input": input != null ? Uri.encodeComponent(input) : null,
      "language": language,
      "location": location,
      "radius": radius,
      "types": types,
      "components": components,
      "strictbounds": strictbounds,
      "offset": offset
    };
    if (apiKey != null) {
      params.putIfAbsent("key", () => apiKey);
    }

    return "$url$_autocompleteUrl?${buildQuery(params)}";
  }

  String buildQueryAutocompleteUrl(
      {String input,
        num offset,
        Location location,
        num radius,
        String language}) {
    final params = {
      "input": input != null ? Uri.encodeComponent(input) : null,
      "language": language,
      "location": location,
      "radius": radius,
      "offset": offset
    };

    if (apiKey != null) {
      params.putIfAbsent("key", () => apiKey);
    }

    return "$url$_queryAutocompleteUrl?${buildQuery(params)}";
  }

  PlacesSearchResponse _decodeSearchResponse(Response res) =>
      new PlacesSearchResponse.fromJson(json.decode(res.body));

  PlacesDetailsResponse _decodeDetailsResponse(Response res) =>
      new PlacesDetailsResponse.fromJson(json.decode(res.body));

  PlacesAutocompleteResponse _decodeAutocompleteResponse(Response res) =>
      new PlacesAutocompleteResponse.fromJson(json.decode(res.body));
}

class PlacesSearchResponse extends GoogleResponseList<PlacesSearchResult> {
  /// JSON html_attributions
  final List<String> htmlAttributions;

  /// JSON next_page_token
  final String nextPageToken;

  PlacesSearchResponse(
      String status,
      String errorMessage,
      List<PlacesSearchResult> results,
      this.htmlAttributions,
      this.nextPageToken)
      : super(status, errorMessage, results);

  factory PlacesSearchResponse.fromJson(Map json) => json != null
      ? new PlacesSearchResponse(
      json["status"],
      json["error_message"],
      json["results"]
          .map((r) => new PlacesSearchResult.fromJson(r))
          .toList()
          .cast<PlacesSearchResult>(),
      (json["html_attributions"] as List).cast<String>(),
      json["next_page_token"])
      : null;
}

class PlacesSearchResult {
  final String icon;
  final Geometry geometry;
  final String name;

  /// JSON opening_hours
  final OpeningHours openingHours;

  final List<Photo> photos;

  /// JSON place_id
  final String placeId;

  final String scope;

  /// JSON alt_ids
  final List<AlternativeId> altIds;

  /// JSON price_level
  final PriceLevel priceLevel;

  final num rating;

  final List<String> types;

  final String vicinity;

  /// JSON formatted_address
  final String formattedAddress;

  /// JSON permanently_closed
  final bool permanentlyClosed;

  final String id;

  final String reference;

  PlacesSearchResult(
      this.icon,
      this.geometry,
      this.name,
      this.openingHours,
      this.photos,
      this.placeId,
      this.scope,
      this.altIds,
      this.priceLevel,
      this.rating,
      this.types,
      this.vicinity,
      this.formattedAddress,
      this.permanentlyClosed,
      this.id,
      this.reference);

  factory PlacesSearchResult.fromJson(Map json) => json != null
      ? new PlacesSearchResult(
      json["icon"],
      new Geometry.fromJson(json["geometry"]),
      json["name"],
      new OpeningHours.fromJson(json["opening_hours"]),
      json["photos"]
          ?.map((p) => new Photo.fromJson(p))
          ?.toList()
          ?.cast<Photo>(),
      json["place_id"],
      json["scope"],
      json["alt_ids"]
          ?.map((a) => new AlternativeId.fromJson(a))
          ?.toList()
          ?.cast<AlternativeId>(),
      json["price_level"] != null
          ? PriceLevel.values.elementAt(json["price_level"])
          : null,
      json["rating"],
      (json["types"] as List)?.cast<String>(),
      json["vicinity"],
      json["formatted_address"],
      json["permanently_closed"],
      json["id"],
      json["reference"])
      : null;
}

class PlaceDetailsField {
  static const ADDRESS_COMPONENTS = "address_components";
  static const ADR_ADDRESS = "adr_address";
  static const FORMATTED_ADDRESS = "formatted_address";
  static const FORMATTED_PHONE_NUMBER = "formatted_phone_number";
  static const ID = "id";
  static const REFERENCE = "reference";
  static const ICON = "icon";
  static const NAME = "name";
  static const OPENING_HOURS = "opening_hours";
  static const PHOTOS = "photos";
  static const PLACE_ID = "place_id";
  static const INTERNATIONAL_PHONE_NUMBER = "international_phone_number";
  static const PRICE_LEVEL = "price_level";
  static const RATING = "rating";
  static const SCOPE = "scope";
  static const TYPES = "types";
  static const URL = "url";
  static const VICINITY = "vicinity";
  static const UTC_OFFSET = "utc_offset";
  static const WEBSITE = "website";
  static const REVIEWS = "reviews";
  static const GEOMETRY = "geometry";

//  name, permanently_closed, photo, place_id, plus_code, scope, type, url, utc_offset, vicinity
  static const BASIC_FIELDS =
      "${ADDRESS_COMPONENTS},"
      "${ADR_ADDRESS},"
      "${FORMATTED_ADDRESS},"
      "${GEOMETRY},"
      "${ICON},"
      "${ID},"
      "${NAME},"
      "${PLACE_ID},"
      "${SCOPE},"
      "${TYPES},"
      "${URL},"
      "${UTC_OFFSET},"
      "${VICINITY}";
}

class PlaceDetails {
  /// JSON address_components
  final List<AddressComponent> addressComponents;

  /// JSON adr_address
  final String adrAddress;

  /// JSON formatted_address
  final String formattedAddress;

  /// JSON formatted_phone_number
  final String formattedPhoneNumber;

  final String id;

  final String reference;

  final String icon;

  final String name;

  /// JSON opening_hours
  final OpeningHoursDetail openingHours;

  final List<Photo> photos;

  /// JSON place_id
  final String placeId;

  /// JSON international_phone_number
  final String internationalPhoneNumber;

  /// JSON price_level
  final PriceLevel priceLevel;

  final num rating;

  final String scope;

  final List<String> types;

  final String url;

  final String vicinity;

  /// JSON utc_offset
  final num utcOffset;

  final String website;

  final List<Review> reviews;

  final Geometry geometry;

  PlaceDetails(
      this.addressComponents,
      this.adrAddress,
      this.formattedAddress,
      this.formattedPhoneNumber,
      this.id,
      this.reference,
      this.icon,
      this.name,
      this.openingHours,
      this.photos,
      this.placeId,
      this.internationalPhoneNumber,
      this.priceLevel,
      this.rating,
      this.scope,
      this.types,
      this.url,
      this.vicinity,
      this.utcOffset,
      this.website,
      this.reviews,
      this.geometry);

  factory PlaceDetails.fromJson(Map json) => json != null
      ? new PlaceDetails(
      json["address_components"]
          ?.map((addr) => new AddressComponent.fromJson(addr))
          ?.toList()
          ?.cast<AddressComponent>(),
      json["adr_address"],
      json["formatted_address"],
      json["formatted_phone_number"],
      json["id"],
      json["reference"],
      json["icon"],
      json["name"],
      new OpeningHoursDetail.fromJson(json["opening_hours"]),
      json["photos"]
          ?.map((p) => new Photo.fromJson(p))
          ?.toList()
          ?.cast<Photo>(),
      json["place_id"],
      json["international_phone_number"],
      json["price_level"] != null
          ? PriceLevel.values.elementAt(json["price_level"])
          : null,
      json["rating"],
      json["scope"],
      (json["types"] as List)?.cast<String>(),
      json["url"],
      json["vicinity"],
      json["utc_offset"],
      json["website"],
      json["reviews"]
          ?.map((r) => new Review.fromJson(r))
          ?.toList()
          ?.cast<Review>(),
      new Geometry.fromJson(json["geometry"]))
      : null;
}

class OpeningHours {
  /// JSON open_now
  final bool openNow;

  OpeningHours(this.openNow);

  factory OpeningHours.fromJson(Map json) =>
      json != null ? new OpeningHours(json["open_now"]) : null;
}

class OpeningHoursDetail extends OpeningHours {
  final List<OpeningHoursPeriod> periods;
  final List<String> weekdayText;

  OpeningHoursDetail(openNow, this.periods, this.weekdayText) : super(openNow);

  factory OpeningHoursDetail.fromJson(Map<String, dynamic> json) => json != null
      ? new OpeningHoursDetail(
      json["open_now"],
      json["periods"]
          ?.map((p) => new OpeningHoursPeriod.fromJson(p))
          ?.toList()
          ?.cast<OpeningHoursPeriod>(),
      (json["weekday_text"] as List)?.cast<String>())
      : null;
}

class OpeningHoursPeriodDate extends GoogleDateTime {
  final int day;
  final String time;

  /// UTC Time
  DateTime dateTime;

  OpeningHoursPeriodDate(this.day, this.time) {
    dateTime = dayTimeToDateTime(this.day, this.time);
  }

  factory OpeningHoursPeriodDate.fromJson(Map json) =>
      json != null ? OpeningHoursPeriodDate(json["day"], json["time"]) : null;
}

class OpeningHoursPeriod extends GoogleDateTime {
  final OpeningHoursPeriodDate open;
  final OpeningHoursPeriodDate close;

  OpeningHoursPeriod(this.open, this.close);

  factory OpeningHoursPeriod.fromJson(Map json) => json != null
      ? OpeningHoursPeriod(OpeningHoursPeriodDate.fromJson(json["open"]),
      OpeningHoursPeriodDate.fromJson(json["close"]))
      : null;
}

class Photo {
  /// JSON photo_reference
  final String photoReference;
  final num height;
  final num width;

  /// JSON html_attributions
  final List<String> htmlAttributions;

  Photo(this.photoReference, this.height, this.width, this.htmlAttributions);

  factory Photo.fromJson(Map json) => json != null
      ? new Photo(json["photo_reference"], json["height"], json["width"],
      (json["html_attributions"] as List)?.cast<String>())
      : null;
}

class AlternativeId {
  /// JSON place_id
  final String placeId;

  final String scope;

  AlternativeId(this.placeId, this.scope);

  factory AlternativeId.fromJson(Map json) =>
      json != null ? new AlternativeId(json["place_id"], json["scope"]) : null;
}

enum PriceLevel { free, inexpensive, moderate, expensive, veryExpensive }

class PlacesDetailsResponse extends GoogleResponse<PlaceDetails> {
  /// JSON html_attributions
  final List<String> htmlAttributions;

  PlacesDetailsResponse(String status, String errorMessage, PlaceDetails result,
      this.htmlAttributions)
      : super(status, errorMessage, result);

  factory PlacesDetailsResponse.fromJson(Map json) => json != null
      ? new PlacesDetailsResponse(
      json["status"],
      json["error_message"],
      new PlaceDetails.fromJson(json["result"]),
      (json["html_attributions"] as List)?.cast<String>())
      : null;
}

class Review {
  /// JSON author_name
  final String authorName;

  /// JSON author_url
  final String authorUrl;

  final String language;

  /// JSON profile_photo_url
  final String profilePhotoUrl;

  final num rating;

  /// JSON relative_time_description
  final String relativeTimeDescription;

  final String text;

  final num time;

  Review(this.authorName, this.authorUrl, this.language, this.profilePhotoUrl,
      this.rating, this.relativeTimeDescription, this.text, this.time);

  factory Review.fromJson(Map json) => json != null
      ? new Review(
      json["author_name"],
      json["author_url"],
      json["language"],
      json["profile_photo_url"],
      json["rating"],
      json["relative_time_description"],
      json["text"],
      json["time"])
      : null;
}

class PlacesAutocompleteResponse extends GoogleResponseStatus {
  final List<Prediction> predictions;

  PlacesAutocompleteResponse(
      String status, String errorMessage, this.predictions)
      : super(status, errorMessage);

  factory PlacesAutocompleteResponse.fromJson(Map json) => json != null
      ? new PlacesAutocompleteResponse(
      json["status"],
      json["error_message"],
      json["predictions"]
          .map((p) => new Prediction.fromJson(p))
          .toList()
          .cast<Prediction>())
      : null;
}

class Prediction {
  final String description;
  final String id;
  final List<Term> terms;

  /// JSON place_id
  final String placeId;
  final String reference;
  final List<String> types;

  /// JSON matched_substrings
  final List<MatchedSubstring> matchedSubstrings;

  final StructuredFormatting structuredFormatting;

  Prediction(
      this.description,
      this.id,
      this.terms,
      this.placeId,
      this.reference,
      this.types,
      this.matchedSubstrings,
      this.structuredFormatting);

  factory Prediction.fromJson(Map json) => json != null
      ? new Prediction(
    json["description"],
    json["id"],
    json["terms"]
        ?.map((t) => new Term.fromJson(t))
        ?.toList()
        ?.cast<Term>(),
    json["place_id"],
    json["reference"],
    (json["types"] as List)?.cast<String>(),
    json["matched_substrings"]
        ?.map((m) => new MatchedSubstring.fromJson(m))
        ?.toList()
        ?.cast<MatchedSubstring>(),
    StructuredFormatting.fromJson(json["structured_formatting"]),
  )
      : null;
}

class Term {
  final num offset;
  final String value;

  Term(this.offset, this.value);

  factory Term.fromJson(Map json) =>
      json != null ? new Term(json["offset"], json["value"]) : null;
}

class MatchedSubstring {
  final num offset;
  final num length;

  MatchedSubstring(this.offset, this.length);

  factory MatchedSubstring.fromJson(Map json) => json != null
      ? new MatchedSubstring(json["offset"], json["length"])
      : null;
}

class StructuredFormatting {
  final String mainText;
  final List<MatchedSubstring> mainTextMatchedSubstrings;
  final String secondaryText;

  StructuredFormatting(
      this.mainText, this.mainTextMatchedSubstrings, this.secondaryText);

  factory StructuredFormatting.fromJson(Map json) => json != null
      ? new StructuredFormatting(
      json["main_text"],
      json["main_text_matched_substrings"]
          ?.map((m) => new MatchedSubstring.fromJson(m))
          ?.toList()
          ?.cast<MatchedSubstring>(),
      json["secondary_text"])
      : null;
}