import '../../core/errors.dart';
import '../../core/result.dart';
import '../entities/card.dart';
import '../entities/card_enums.dart';

abstract interface class CardRepository {
  Stream<List<BankCard>> watchAll();

  Stream<List<BankCard>> watchByAccount(String accountId);

  Future<Result<BankCard, AppError>> findById(String id);

  /// 新建卡片。参数 [plainCardNo] 和 [plainCvv] 为可选明文，data 层会：
  /// - 用字段级 AES-GCM 加密后写入 ciphertext 列
  /// - [cardNoMasked] 必须由调用方预先计算（通常取后 4 位）
  Future<Result<BankCard, AppError>> create({
    required BankCard card,
    String? plainCardNo,
    String? plainCvv,
  });

  /// 全量更新卡片字段。若传入 [plainCardNo] / [plainCvv] 则重新加密覆盖
  /// 对应 ciphertext；若传入 `null` 则沿用 `card` 上已有的 ciphertext 值。
  /// 调用方应在修改卡号时同步计算好 [BankCard.cardNoMasked]。
  Future<Result<BankCard, AppError>> update({
    required BankCard card,
    String? plainCardNo,
    String? plainCvv,
  });

  Future<Result<void, AppError>> updateStatus(String id, CardStatus status);

  Future<Result<void, AppError>> delete(String id);

  Future<Result<void, AppError>> reorder(List<String> cardIds);

  /// 按需解密返回卡号明文，仅在"查看真实卡号"场景调用。
  Future<Result<String, AppError>> decryptCardNo(String id);

  /// 按需解密返回 CVV 明文。
  Future<Result<String, AppError>> decryptCvv(String id);
}
