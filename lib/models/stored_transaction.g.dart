// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'stored_transaction.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetStoredTransactionCollection on Isar {
  IsarCollection<StoredTransaction> get storedTransactions => this.collection();
}

const StoredTransactionSchema = CollectionSchema(
  name: r'StoredTransaction',
  id: 5444790860770582979,
  properties: {
    r'executedAt': PropertySchema(
      id: 0,
      name: r'executedAt',
      type: IsarType.dateTime,
    ),
    r'fees': PropertySchema(id: 1, name: r'fees', type: IsarType.double),
    r'note': PropertySchema(id: 2, name: r'note', type: IsarType.string),
    r'price': PropertySchema(id: 3, name: r'price', type: IsarType.double),
    r'quantity': PropertySchema(
      id: 4,
      name: r'quantity',
      type: IsarType.double,
    ),
    r'sideCode': PropertySchema(
      id: 5,
      name: r'sideCode',
      type: IsarType.string,
    ),
    r'symbol': PropertySchema(id: 6, name: r'symbol', type: IsarType.string),
    r'uid': PropertySchema(id: 7, name: r'uid', type: IsarType.string),
  },

  estimateSize: _storedTransactionEstimateSize,
  serialize: _storedTransactionSerialize,
  deserialize: _storedTransactionDeserialize,
  deserializeProp: _storedTransactionDeserializeProp,
  idName: r'id',
  indexes: {},
  links: {},
  embeddedSchemas: {},

  getId: _storedTransactionGetId,
  getLinks: _storedTransactionGetLinks,
  attach: _storedTransactionAttach,
  version: '3.3.2',
);

int _storedTransactionEstimateSize(
  StoredTransaction object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.note.length * 3;
  bytesCount += 3 + object.sideCode.length * 3;
  bytesCount += 3 + object.symbol.length * 3;
  bytesCount += 3 + object.uid.length * 3;
  return bytesCount;
}

void _storedTransactionSerialize(
  StoredTransaction object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeDateTime(offsets[0], object.executedAt);
  writer.writeDouble(offsets[1], object.fees);
  writer.writeString(offsets[2], object.note);
  writer.writeDouble(offsets[3], object.price);
  writer.writeDouble(offsets[4], object.quantity);
  writer.writeString(offsets[5], object.sideCode);
  writer.writeString(offsets[6], object.symbol);
  writer.writeString(offsets[7], object.uid);
}

StoredTransaction _storedTransactionDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = StoredTransaction();
  object.executedAt = reader.readDateTime(offsets[0]);
  object.fees = reader.readDouble(offsets[1]);
  object.id = id;
  object.note = reader.readString(offsets[2]);
  object.price = reader.readDouble(offsets[3]);
  object.quantity = reader.readDouble(offsets[4]);
  object.sideCode = reader.readString(offsets[5]);
  object.symbol = reader.readString(offsets[6]);
  object.uid = reader.readString(offsets[7]);
  return object;
}

P _storedTransactionDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readDateTime(offset)) as P;
    case 1:
      return (reader.readDouble(offset)) as P;
    case 2:
      return (reader.readString(offset)) as P;
    case 3:
      return (reader.readDouble(offset)) as P;
    case 4:
      return (reader.readDouble(offset)) as P;
    case 5:
      return (reader.readString(offset)) as P;
    case 6:
      return (reader.readString(offset)) as P;
    case 7:
      return (reader.readString(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _storedTransactionGetId(StoredTransaction object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _storedTransactionGetLinks(
  StoredTransaction object,
) {
  return [];
}

void _storedTransactionAttach(
  IsarCollection<dynamic> col,
  Id id,
  StoredTransaction object,
) {
  object.id = id;
}

extension StoredTransactionQueryWhereSort
    on QueryBuilder<StoredTransaction, StoredTransaction, QWhere> {
  QueryBuilder<StoredTransaction, StoredTransaction, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension StoredTransactionQueryWhere
    on QueryBuilder<StoredTransaction, StoredTransaction, QWhereClause> {
  QueryBuilder<StoredTransaction, StoredTransaction, QAfterWhereClause>
  idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(lower: id, upper: id));
    });
  }

  QueryBuilder<StoredTransaction, StoredTransaction, QAfterWhereClause>
  idNotEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            )
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            );
      } else {
        return query
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            )
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            );
      }
    });
  }

  QueryBuilder<StoredTransaction, StoredTransaction, QAfterWhereClause>
  idGreaterThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<StoredTransaction, StoredTransaction, QAfterWhereClause>
  idLessThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<StoredTransaction, StoredTransaction, QAfterWhereClause>
  idBetween(
    Id lowerId,
    Id upperId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.between(
          lower: lowerId,
          includeLower: includeLower,
          upper: upperId,
          includeUpper: includeUpper,
        ),
      );
    });
  }
}

extension StoredTransactionQueryFilter
    on QueryBuilder<StoredTransaction, StoredTransaction, QFilterCondition> {
  QueryBuilder<StoredTransaction, StoredTransaction, QAfterFilterCondition>
  executedAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'executedAt', value: value),
      );
    });
  }

  QueryBuilder<StoredTransaction, StoredTransaction, QAfterFilterCondition>
  executedAtGreaterThan(DateTime value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'executedAt',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<StoredTransaction, StoredTransaction, QAfterFilterCondition>
  executedAtLessThan(DateTime value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'executedAt',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<StoredTransaction, StoredTransaction, QAfterFilterCondition>
  executedAtBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'executedAt',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<StoredTransaction, StoredTransaction, QAfterFilterCondition>
  feesEqualTo(double value, {double epsilon = Query.epsilon}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'fees',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<StoredTransaction, StoredTransaction, QAfterFilterCondition>
  feesGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'fees',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<StoredTransaction, StoredTransaction, QAfterFilterCondition>
  feesLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'fees',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<StoredTransaction, StoredTransaction, QAfterFilterCondition>
  feesBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'fees',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<StoredTransaction, StoredTransaction, QAfterFilterCondition>
  idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'id', value: value),
      );
    });
  }

  QueryBuilder<StoredTransaction, StoredTransaction, QAfterFilterCondition>
  idGreaterThan(Id value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'id',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<StoredTransaction, StoredTransaction, QAfterFilterCondition>
  idLessThan(Id value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'id',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<StoredTransaction, StoredTransaction, QAfterFilterCondition>
  idBetween(
    Id lower,
    Id upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'id',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<StoredTransaction, StoredTransaction, QAfterFilterCondition>
  noteEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'note',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<StoredTransaction, StoredTransaction, QAfterFilterCondition>
  noteGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'note',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<StoredTransaction, StoredTransaction, QAfterFilterCondition>
  noteLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'note',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<StoredTransaction, StoredTransaction, QAfterFilterCondition>
  noteBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'note',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<StoredTransaction, StoredTransaction, QAfterFilterCondition>
  noteStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'note',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<StoredTransaction, StoredTransaction, QAfterFilterCondition>
  noteEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'note',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<StoredTransaction, StoredTransaction, QAfterFilterCondition>
  noteContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'note',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<StoredTransaction, StoredTransaction, QAfterFilterCondition>
  noteMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'note',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<StoredTransaction, StoredTransaction, QAfterFilterCondition>
  noteIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'note', value: ''),
      );
    });
  }

  QueryBuilder<StoredTransaction, StoredTransaction, QAfterFilterCondition>
  noteIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'note', value: ''),
      );
    });
  }

  QueryBuilder<StoredTransaction, StoredTransaction, QAfterFilterCondition>
  priceEqualTo(double value, {double epsilon = Query.epsilon}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'price',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<StoredTransaction, StoredTransaction, QAfterFilterCondition>
  priceGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'price',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<StoredTransaction, StoredTransaction, QAfterFilterCondition>
  priceLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'price',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<StoredTransaction, StoredTransaction, QAfterFilterCondition>
  priceBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'price',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<StoredTransaction, StoredTransaction, QAfterFilterCondition>
  quantityEqualTo(double value, {double epsilon = Query.epsilon}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'quantity',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<StoredTransaction, StoredTransaction, QAfterFilterCondition>
  quantityGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'quantity',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<StoredTransaction, StoredTransaction, QAfterFilterCondition>
  quantityLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'quantity',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<StoredTransaction, StoredTransaction, QAfterFilterCondition>
  quantityBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'quantity',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<StoredTransaction, StoredTransaction, QAfterFilterCondition>
  sideCodeEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'sideCode',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<StoredTransaction, StoredTransaction, QAfterFilterCondition>
  sideCodeGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'sideCode',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<StoredTransaction, StoredTransaction, QAfterFilterCondition>
  sideCodeLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'sideCode',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<StoredTransaction, StoredTransaction, QAfterFilterCondition>
  sideCodeBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'sideCode',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<StoredTransaction, StoredTransaction, QAfterFilterCondition>
  sideCodeStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'sideCode',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<StoredTransaction, StoredTransaction, QAfterFilterCondition>
  sideCodeEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'sideCode',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<StoredTransaction, StoredTransaction, QAfterFilterCondition>
  sideCodeContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'sideCode',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<StoredTransaction, StoredTransaction, QAfterFilterCondition>
  sideCodeMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'sideCode',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<StoredTransaction, StoredTransaction, QAfterFilterCondition>
  sideCodeIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'sideCode', value: ''),
      );
    });
  }

  QueryBuilder<StoredTransaction, StoredTransaction, QAfterFilterCondition>
  sideCodeIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'sideCode', value: ''),
      );
    });
  }

  QueryBuilder<StoredTransaction, StoredTransaction, QAfterFilterCondition>
  symbolEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'symbol',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<StoredTransaction, StoredTransaction, QAfterFilterCondition>
  symbolGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'symbol',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<StoredTransaction, StoredTransaction, QAfterFilterCondition>
  symbolLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'symbol',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<StoredTransaction, StoredTransaction, QAfterFilterCondition>
  symbolBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'symbol',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<StoredTransaction, StoredTransaction, QAfterFilterCondition>
  symbolStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'symbol',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<StoredTransaction, StoredTransaction, QAfterFilterCondition>
  symbolEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'symbol',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<StoredTransaction, StoredTransaction, QAfterFilterCondition>
  symbolContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'symbol',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<StoredTransaction, StoredTransaction, QAfterFilterCondition>
  symbolMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'symbol',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<StoredTransaction, StoredTransaction, QAfterFilterCondition>
  symbolIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'symbol', value: ''),
      );
    });
  }

  QueryBuilder<StoredTransaction, StoredTransaction, QAfterFilterCondition>
  symbolIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'symbol', value: ''),
      );
    });
  }

  QueryBuilder<StoredTransaction, StoredTransaction, QAfterFilterCondition>
  uidEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'uid',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<StoredTransaction, StoredTransaction, QAfterFilterCondition>
  uidGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'uid',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<StoredTransaction, StoredTransaction, QAfterFilterCondition>
  uidLessThan(String value, {bool include = false, bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'uid',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<StoredTransaction, StoredTransaction, QAfterFilterCondition>
  uidBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'uid',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<StoredTransaction, StoredTransaction, QAfterFilterCondition>
  uidStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'uid',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<StoredTransaction, StoredTransaction, QAfterFilterCondition>
  uidEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'uid',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<StoredTransaction, StoredTransaction, QAfterFilterCondition>
  uidContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'uid',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<StoredTransaction, StoredTransaction, QAfterFilterCondition>
  uidMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'uid',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<StoredTransaction, StoredTransaction, QAfterFilterCondition>
  uidIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'uid', value: ''),
      );
    });
  }

  QueryBuilder<StoredTransaction, StoredTransaction, QAfterFilterCondition>
  uidIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'uid', value: ''),
      );
    });
  }
}

extension StoredTransactionQueryObject
    on QueryBuilder<StoredTransaction, StoredTransaction, QFilterCondition> {}

extension StoredTransactionQueryLinks
    on QueryBuilder<StoredTransaction, StoredTransaction, QFilterCondition> {}

extension StoredTransactionQuerySortBy
    on QueryBuilder<StoredTransaction, StoredTransaction, QSortBy> {
  QueryBuilder<StoredTransaction, StoredTransaction, QAfterSortBy>
  sortByExecutedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'executedAt', Sort.asc);
    });
  }

  QueryBuilder<StoredTransaction, StoredTransaction, QAfterSortBy>
  sortByExecutedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'executedAt', Sort.desc);
    });
  }

  QueryBuilder<StoredTransaction, StoredTransaction, QAfterSortBy>
  sortByFees() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fees', Sort.asc);
    });
  }

  QueryBuilder<StoredTransaction, StoredTransaction, QAfterSortBy>
  sortByFeesDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fees', Sort.desc);
    });
  }

  QueryBuilder<StoredTransaction, StoredTransaction, QAfterSortBy>
  sortByNote() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'note', Sort.asc);
    });
  }

  QueryBuilder<StoredTransaction, StoredTransaction, QAfterSortBy>
  sortByNoteDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'note', Sort.desc);
    });
  }

  QueryBuilder<StoredTransaction, StoredTransaction, QAfterSortBy>
  sortByPrice() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'price', Sort.asc);
    });
  }

  QueryBuilder<StoredTransaction, StoredTransaction, QAfterSortBy>
  sortByPriceDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'price', Sort.desc);
    });
  }

  QueryBuilder<StoredTransaction, StoredTransaction, QAfterSortBy>
  sortByQuantity() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'quantity', Sort.asc);
    });
  }

  QueryBuilder<StoredTransaction, StoredTransaction, QAfterSortBy>
  sortByQuantityDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'quantity', Sort.desc);
    });
  }

  QueryBuilder<StoredTransaction, StoredTransaction, QAfterSortBy>
  sortBySideCode() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sideCode', Sort.asc);
    });
  }

  QueryBuilder<StoredTransaction, StoredTransaction, QAfterSortBy>
  sortBySideCodeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sideCode', Sort.desc);
    });
  }

  QueryBuilder<StoredTransaction, StoredTransaction, QAfterSortBy>
  sortBySymbol() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'symbol', Sort.asc);
    });
  }

  QueryBuilder<StoredTransaction, StoredTransaction, QAfterSortBy>
  sortBySymbolDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'symbol', Sort.desc);
    });
  }

  QueryBuilder<StoredTransaction, StoredTransaction, QAfterSortBy> sortByUid() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'uid', Sort.asc);
    });
  }

  QueryBuilder<StoredTransaction, StoredTransaction, QAfterSortBy>
  sortByUidDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'uid', Sort.desc);
    });
  }
}

extension StoredTransactionQuerySortThenBy
    on QueryBuilder<StoredTransaction, StoredTransaction, QSortThenBy> {
  QueryBuilder<StoredTransaction, StoredTransaction, QAfterSortBy>
  thenByExecutedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'executedAt', Sort.asc);
    });
  }

  QueryBuilder<StoredTransaction, StoredTransaction, QAfterSortBy>
  thenByExecutedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'executedAt', Sort.desc);
    });
  }

  QueryBuilder<StoredTransaction, StoredTransaction, QAfterSortBy>
  thenByFees() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fees', Sort.asc);
    });
  }

  QueryBuilder<StoredTransaction, StoredTransaction, QAfterSortBy>
  thenByFeesDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fees', Sort.desc);
    });
  }

  QueryBuilder<StoredTransaction, StoredTransaction, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<StoredTransaction, StoredTransaction, QAfterSortBy>
  thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<StoredTransaction, StoredTransaction, QAfterSortBy>
  thenByNote() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'note', Sort.asc);
    });
  }

  QueryBuilder<StoredTransaction, StoredTransaction, QAfterSortBy>
  thenByNoteDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'note', Sort.desc);
    });
  }

  QueryBuilder<StoredTransaction, StoredTransaction, QAfterSortBy>
  thenByPrice() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'price', Sort.asc);
    });
  }

  QueryBuilder<StoredTransaction, StoredTransaction, QAfterSortBy>
  thenByPriceDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'price', Sort.desc);
    });
  }

  QueryBuilder<StoredTransaction, StoredTransaction, QAfterSortBy>
  thenByQuantity() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'quantity', Sort.asc);
    });
  }

  QueryBuilder<StoredTransaction, StoredTransaction, QAfterSortBy>
  thenByQuantityDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'quantity', Sort.desc);
    });
  }

  QueryBuilder<StoredTransaction, StoredTransaction, QAfterSortBy>
  thenBySideCode() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sideCode', Sort.asc);
    });
  }

  QueryBuilder<StoredTransaction, StoredTransaction, QAfterSortBy>
  thenBySideCodeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sideCode', Sort.desc);
    });
  }

  QueryBuilder<StoredTransaction, StoredTransaction, QAfterSortBy>
  thenBySymbol() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'symbol', Sort.asc);
    });
  }

  QueryBuilder<StoredTransaction, StoredTransaction, QAfterSortBy>
  thenBySymbolDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'symbol', Sort.desc);
    });
  }

  QueryBuilder<StoredTransaction, StoredTransaction, QAfterSortBy> thenByUid() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'uid', Sort.asc);
    });
  }

  QueryBuilder<StoredTransaction, StoredTransaction, QAfterSortBy>
  thenByUidDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'uid', Sort.desc);
    });
  }
}

extension StoredTransactionQueryWhereDistinct
    on QueryBuilder<StoredTransaction, StoredTransaction, QDistinct> {
  QueryBuilder<StoredTransaction, StoredTransaction, QDistinct>
  distinctByExecutedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'executedAt');
    });
  }

  QueryBuilder<StoredTransaction, StoredTransaction, QDistinct>
  distinctByFees() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'fees');
    });
  }

  QueryBuilder<StoredTransaction, StoredTransaction, QDistinct> distinctByNote({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'note', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<StoredTransaction, StoredTransaction, QDistinct>
  distinctByPrice() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'price');
    });
  }

  QueryBuilder<StoredTransaction, StoredTransaction, QDistinct>
  distinctByQuantity() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'quantity');
    });
  }

  QueryBuilder<StoredTransaction, StoredTransaction, QDistinct>
  distinctBySideCode({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'sideCode', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<StoredTransaction, StoredTransaction, QDistinct>
  distinctBySymbol({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'symbol', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<StoredTransaction, StoredTransaction, QDistinct> distinctByUid({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'uid', caseSensitive: caseSensitive);
    });
  }
}

extension StoredTransactionQueryProperty
    on QueryBuilder<StoredTransaction, StoredTransaction, QQueryProperty> {
  QueryBuilder<StoredTransaction, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<StoredTransaction, DateTime, QQueryOperations>
  executedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'executedAt');
    });
  }

  QueryBuilder<StoredTransaction, double, QQueryOperations> feesProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'fees');
    });
  }

  QueryBuilder<StoredTransaction, String, QQueryOperations> noteProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'note');
    });
  }

  QueryBuilder<StoredTransaction, double, QQueryOperations> priceProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'price');
    });
  }

  QueryBuilder<StoredTransaction, double, QQueryOperations> quantityProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'quantity');
    });
  }

  QueryBuilder<StoredTransaction, String, QQueryOperations> sideCodeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'sideCode');
    });
  }

  QueryBuilder<StoredTransaction, String, QQueryOperations> symbolProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'symbol');
    });
  }

  QueryBuilder<StoredTransaction, String, QQueryOperations> uidProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'uid');
    });
  }
}
