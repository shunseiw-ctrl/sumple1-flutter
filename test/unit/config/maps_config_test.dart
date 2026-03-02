import 'package:flutter_test/flutter_test.dart';
import 'package:sumple1/core/config/maps_config.dart';

void main() {
  group('MapsConfig', () {
    test('defaultLat/defaultLngが有効座標', () {
      expect(MapsConfig.defaultLat, greaterThanOrEqualTo(-90));
      expect(MapsConfig.defaultLat, lessThanOrEqualTo(90));
      expect(MapsConfig.defaultLng, greaterThanOrEqualTo(-180));
      expect(MapsConfig.defaultLng, lessThanOrEqualTo(180));
    });

    test('defaultZoomが正の値', () {
      expect(MapsConfig.defaultZoom, greaterThan(0));
    });

    test('markerZoom > defaultZoom', () {
      expect(MapsConfig.markerZoom, greaterThan(MapsConfig.defaultZoom));
    });
  });
}
