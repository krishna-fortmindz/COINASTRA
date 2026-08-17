import '../../../end_points.dart';
import '../../api_client.dart';

class AlertsRepo {
  const AlertsRepo._();
  static const AlertsRepo instance = AlertsRepo._();

  Future<void> createAlert({
    required String symbol,
    required double entryPrice,
    required double takeProfitPrice,
    required double stopLossPrice,
    required String direction,
  }) async {
    await ApiClient.instance.post(
      EndPoints.alerts,
      data: {
        'symbol': symbol,
        'entryPrice': entryPrice,
        'takeProfitPrice': takeProfitPrice > 0 ? takeProfitPrice : null,
        'stopLossPrice': stopLossPrice > 0 ? stopLossPrice : null,
        'direction': direction,
      },
    );
  }

  Future<void> cancelAlert(String id) async {
    await ApiClient.instance.patch(EndPoints.cancelAlert(id));
  }

  Future<void> deleteAlert(String id) async {
    await ApiClient.instance.delete(EndPoints.alertById(id));
  }
}
