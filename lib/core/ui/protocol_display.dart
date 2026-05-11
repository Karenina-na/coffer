import '../../domain/entities/dict_entry.dart';

typedef ProtocolIndex = Map<String, DictEntry>;

String protocolDisplayName(ProtocolIndex index, String code) {
  return index[code]?.name ?? code;
}

String protocolDisplayLabel(ProtocolIndex index, String code) {
  final entry = index[code];
  if (entry == null) return code;
  return '${entry.name}（${entry.code}）';
}
