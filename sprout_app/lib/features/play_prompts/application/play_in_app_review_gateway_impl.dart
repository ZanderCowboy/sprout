import 'package:in_app_review/in_app_review.dart';

import 'play_in_app_review_gateway.dart';

class PlayInAppReviewGatewayImpl implements PlayInAppReviewGateway {
  PlayInAppReviewGatewayImpl({InAppReview? inAppReview})
    : _inAppReview = inAppReview ?? InAppReview.instance;

  final InAppReview _inAppReview;

  @override
  Future<bool> isAvailable() => _inAppReview.isAvailable();

  @override
  Future<void> requestReview() => _inAppReview.requestReview();
}
