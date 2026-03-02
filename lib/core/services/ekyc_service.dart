import 'package:sumple1/data/models/ekyc_result.dart';

abstract class EkycService {
  Future<EkycResult> startVerification(String uid);
  Future<EkycStatus> checkStatus(String uid);
  bool get isAvailable;
}
