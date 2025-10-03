// lib/providers/supplier_reviews_provider.dart
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../core/api_service.dart';
import '../core/api_paths.dart';
import '../models/offer_review.dart';
import '../models/offer_comment.dart';

@immutable
class ReviewFilters {
  final int? offerId;
  final int? rating; // 1..5
  const ReviewFilters({this.offerId, this.rating});

  Map<String, dynamic> toQuery() {
    final m = <String, dynamic>{};
    if (offerId != null) m['offer'] = offerId.toString();
    if (rating != null) m['rating'] = rating.toString();
    return m;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is ReviewFilters &&
              other.offerId == offerId &&
              other.rating == rating;

  @override
  int get hashCode => Object.hash(offerId, rating);
}

List _extractList(dynamic data) {
  if (data is List) return data;
  if (data is Map && data['results'] is List) return data['results'] as List;
  return const [];
}

/// Utilitaire : rendre un message d'erreur lisible pour l’utilisateur
String friendlyError(Object error) {
  if (error is DioException) {
    final res = error.response;
    final data = res?.data;

    // 1) Payload DRF {field: ["msg"]} ou {"detail": "..."} ou string
    if (data is Map) {
      // Priorité au champ "detail"
      if (data['detail'] is String && (data['detail'] as String).trim().isNotEmpty) {
        return data['detail'] as String;
      }
      // Aplatissement des listes de validations
      final parts = <String>[];
      data.forEach((k, v) {
        if (v is List) {
          parts.add('$k: ${v.map((e) => e.toString()).join(", ")}');
        } else {
          parts.add('$k: ${v.toString()}');
        }
      });
      if (parts.isNotEmpty) return parts.join('\n');
    }
    if (data is List && data.isNotEmpty) {
      return data.map((e) => e.toString()).join('\n');
    }
    if (data is String && data.trim().isNotEmpty) {
      return data;
    }

    // 2) Sinon, message HTTP générique
    final code = res?.statusCode;
    final reason = res?.statusMessage;
    if (code != null) return 'Erreur $code${reason != null ? " - $reason" : ""}';
    // 3) Erreur réseau/timeout
    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.sendTimeout) {
      return "Délai dépassé. Vérifiez votre connexion et réessayez.";
    }
    return "Une erreur s’est produite. Réessayez.";
  }
  // Non-Dio
  return error.toString();
}

/// Avis d'une offre (ou tous si offerId null)
final supplierReviewsProvider =
FutureProvider.autoDispose.family<List<OfferReview>, ReviewFilters>((ref, filters) async {
  try {
    final res = await ApiService.instance.dio.get(
      ApiPaths.supplierReviews,
      queryParameters: filters.toQuery(),
    );
    final list = _extractList(res.data);
    return list
        .whereType<Map<String, dynamic>>()
        .map((j) => OfferReview.fromJson(j))
        .toList();
  } catch (e) {
    // Rejeter avec un message propre
    throw Exception(friendlyError(e));
  }
});

/// Commentaires liés à une offre
final offerCommentsProvider =
FutureProvider.autoDispose.family<List<OfferComment>, int>((ref, offerId) async {
  try {
    final res = await ApiService.instance.dio.get(
      ApiPaths.supplierComments,
      queryParameters: {'offer': offerId.toString()},
    );
    final list = _extractList(res.data);
    return list
        .whereType<Map<String, dynamic>>()
        .map((j) => OfferComment.fromJson(j))
        .toList();
  } catch (e) {
    throw Exception(friendlyError(e));
  }
});

/// Edition de commentaires
class OfferCommentEditor extends StateNotifier<AsyncValue<void>> {
  OfferCommentEditor(this.ref) : super(const AsyncValue.data(null));
  final Ref ref;

  // Dernier message d'erreur lisible (utile à l’UI)
  String? lastError;

  Future<bool> create({
    required int offerId,
    required String content,
    required bool isPublic,
  }) async {
    try {
      lastError = null;
      state = const AsyncValue.loading();
      await ApiService.instance.dio.post(
        ApiPaths.supplierComments,
        data: {
          'offer': offerId,
          'content': content,
          'is_public': isPublic,
        },
      );
      state = const AsyncValue.data(null);
      ref.invalidate(offerCommentsProvider(offerId));
      return true;
    } catch (e, st) {
      lastError = friendlyError(e);
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<bool> update({
    required int offerId,
    required int commentId,
    required String content,
  }) async {
    try {
      lastError = null;
      state = const AsyncValue.loading();
      await ApiService.instance.dio.patch(
        '${ApiPaths.supplierComments}$commentId/',
        data: {'content': content},
      );
      state = const AsyncValue.data(null);
      ref.invalidate(offerCommentsProvider(offerId));
      return true;
    } catch (e, st) {
      lastError = friendlyError(e);
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<bool> delete({
    required int offerId,
    required int commentId,
  }) async {
    try {
      lastError = null;
      state = const AsyncValue.loading();
      await ApiService.instance.dio.delete(
        '${ApiPaths.supplierComments}$commentId/',
      );
      state = const AsyncValue.data(null);
      ref.invalidate(offerCommentsProvider(offerId));
      return true;
    } catch (e, st) {
      lastError = friendlyError(e);
      state = AsyncValue.error(e, st);
      return false;
    }
  }
}

final offerCommentEditorProvider =
StateNotifierProvider<OfferCommentEditor, AsyncValue<void>>(
      (ref) => OfferCommentEditor(ref),
);
