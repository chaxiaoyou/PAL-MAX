// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'stored_alert.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetStoredAlertCollection on Isar {
  IsarCollection<StoredAlert> get storedAlerts => this.collection();
}

const StoredAlertSchema = CollectionSchema(
  name: r'StoredAlert',
  id: 995610891563834783,
  properties: {
    r'createdAt': PropertySchema(
      id: 0,
      name: r'createdAt',
      type: IsarType.dateTime,
    ),
    r'enabled': PropertySchema(id: 1, name: r'enabled', type: IsarType.bool),
    r'kindCode': PropertySchema(
      id: 2,
      name: r'kindCode',
      type: IsarType.string,
    ),
    r'note': PropertySchema(id: 3, name: r'note', type: IsarType.string),
    r'symbol': PropertySchema(id: 4, name: r'symbol', type: IsarType.string),
    r'threshold': PropertySchema(
      id: 5,
      name: r'threshold',
      type: IsarType.double,
    ),
    r'triggeredAt': PropertySchema(
      id: 6,
      name: r'triggeredAt',
      type: IsarType.dateTime,
    ),
    r'uid': PropertySchema(id: 7, name: r'uid', type: IsarType.string),
  },

  estimateSize: _storedAlertEstimateSize,
  serialize: _storedAlertSerialize,
  deserialize: _storedAlertDeserialize,
  deserializeProp: _storedAlertDeserializeProp,
  idName: r'id',
  indexes: {},
  links: {},
  embeddedSchemas: {},

  getId: _storedAlertGetId,
  getLinks: _storedAlertGetLinks,
  attach: _storedAlertAttach,
  version: '3.3.2',
);

int _storedAlertEstimateSize(
  StoredAlert object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.kindCode.length * 3;
  bytesCount += 3 + object.note.length * 3;
  bytesCount += 3 + object.symbol.length * 3;
  bytesCount += 3 + object.uid.length * 3;
  return bytesCount;
}

void _storedAlertSerialize(
  StoredAlert object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeDateTime(offsets[0], object.createdAt);
  writer.writeBool(offsets[1], object.enabled);
  writer.writeString(offsets[2], object.kindCode);
  writer.writeString(offsets[3], object.note);
  writer.writeString(offsets[4], object.symbol);
  writer.writeDouble(offsets[5], object.threshold);
  writer.writeDateTime(offsets[6], object.triggeredAt);
  writer.writeString(offsets[7], object.uid);
}

StoredAlert _storedAlertDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = StoredAlert();
  object.createdAt = reader.readDateTime(offsets[0]);
  object.enabled = reader.readBool(offsets[1]);
  object.id = id;
  object.kindCode = reader.readString(offsets[2]);
  object.note = reader.readString(offsets[3]);
  object.symbol = reader.readString(offsets[4]);
  object.threshold = reader.readDouble(offsets[5]);
  object.triggeredAt = reader.readDateTimeOrNull(offsets[6]);
  object.uid = reader.readString(offsets[7]);
  return object;
}

P _storedAlertDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readDateTime(offset)) as P;
    case 1:
      return (reader.readBool(offset)) as P;
    case 2:
      return (reader.readString(offset)) as P;
    case 3:
      return (reader.readString(offset)) as P;
    case 4:
      return (reader.readString(offset)) as P;
    case 5:
      return (reader.readDouble(offset)) as P;
    case 6:
      return (reader.readDateTimeOrNull(offset)) as P;
    case 7:
      return (reader.readString(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _storedAlertGetId(StoredAlert object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _storedAlertGetLinks(StoredAlert object) {
  return [];
}

void _storedAlertAttach(
  IsarCollection<dynamic> col,
  Id id,
  StoredAlert object,
) {
  object.id = id;
}

extension StoredAlertQueryWhereSort
    on QueryBuilder<StoredAlert, StoredAlert, QWhere> {
  QueryBuilder<StoredAlert, StoredAlert, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension StoredAlertQueryWhere
    on QueryBuilder<StoredAlert, StoredAlert, QWhereClause> {
  QueryBuilder<StoredAlert, StoredAlert, QAfterWhereClause> idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(lower: id, upper: id));
    });
  }

  QueryBuilder<StoredAlert, StoredAlert, QAfterWhereClause> idNotEqualTo(
    Id id,
  ) {
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

  QueryBuilder<StoredAlert, StoredAlert, QAfterWhereClause> idGreaterThan(
    Id id, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<StoredAlert, StoredAlert, QAfterWhereClause> idLessThan(
    Id id, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<StoredAlert, StoredAlert, QAfterWhereClause> idBetween(
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

extension StoredAlertQueryFilter
    on QueryBuilder<StoredAlert, StoredAlert, QFilterCondition> {
  QueryBuilder<StoredAlert, StoredAlert, QAfterFilterCondition>
  createdAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'createdAt', value: value),
      );
    });
  }

  QueryBuilder<StoredAlert, StoredAlert, QAfterFilterCondition>
  createdAtGreaterThan(DateTime value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'createdAt',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<StoredAlert, StoredAlert, QAfterFilterCondition>
  createdAtLessThan(DateTime value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'createdAt',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<StoredAlert, StoredAlert, QAfterFilterCondition>
  createdAtBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'createdAt',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<StoredAlert, StoredAlert, QAfterFilterCondition> enabledEqualTo(
    bool value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'enabled', value: value),
      );
    });
  }

  QueryBuilder<StoredAlert, StoredAlert, QAfterFilterCondition> idEqualTo(
    Id value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'id', value: value),
      );
    });
  }

  QueryBuilder<StoredAlert, StoredAlert, QAfterFilterCondition> idGreaterThan(
    Id value, {
    bool include = false,
  }) {
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

  QueryBuilder<StoredAlert, StoredAlert, QAfterFilterCondition> idLessThan(
    Id value, {
    bool include = false,
  }) {
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

  QueryBuilder<StoredAlert, StoredAlert, QAfterFilterCondition> idBetween(
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

  QueryBuilder<StoredAlert, StoredAlert, QAfterFilterCondition> kindCodeEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'kindCode',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<StoredAlert, StoredAlert, QAfterFilterCondition>
  kindCodeGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'kindCode',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<StoredAlert, StoredAlert, QAfterFilterCondition>
  kindCodeLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'kindCode',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<StoredAlert, StoredAlert, QAfterFilterCondition> kindCodeBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'kindCode',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<StoredAlert, StoredAlert, QAfterFilterCondition>
  kindCodeStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'kindCode',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<StoredAlert, StoredAlert, QAfterFilterCondition>
  kindCodeEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'kindCode',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<StoredAlert, StoredAlert, QAfterFilterCondition>
  kindCodeContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'kindCode',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<StoredAlert, StoredAlert, QAfterFilterCondition> kindCodeMatches(
    String pattern, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'kindCode',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<StoredAlert, StoredAlert, QAfterFilterCondition>
  kindCodeIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'kindCode', value: ''),
      );
    });
  }

  QueryBuilder<StoredAlert, StoredAlert, QAfterFilterCondition>
  kindCodeIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'kindCode', value: ''),
      );
    });
  }

  QueryBuilder<StoredAlert, StoredAlert, QAfterFilterCondition> noteEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
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

  QueryBuilder<StoredAlert, StoredAlert, QAfterFilterCondition> noteGreaterThan(
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

  QueryBuilder<StoredAlert, StoredAlert, QAfterFilterCondition> noteLessThan(
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

  QueryBuilder<StoredAlert, StoredAlert, QAfterFilterCondition> noteBetween(
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

  QueryBuilder<StoredAlert, StoredAlert, QAfterFilterCondition> noteStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
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

  QueryBuilder<StoredAlert, StoredAlert, QAfterFilterCondition> noteEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
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

  QueryBuilder<StoredAlert, StoredAlert, QAfterFilterCondition> noteContains(
    String value, {
    bool caseSensitive = true,
  }) {
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

  QueryBuilder<StoredAlert, StoredAlert, QAfterFilterCondition> noteMatches(
    String pattern, {
    bool caseSensitive = true,
  }) {
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

  QueryBuilder<StoredAlert, StoredAlert, QAfterFilterCondition> noteIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'note', value: ''),
      );
    });
  }

  QueryBuilder<StoredAlert, StoredAlert, QAfterFilterCondition>
  noteIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'note', value: ''),
      );
    });
  }

  QueryBuilder<StoredAlert, StoredAlert, QAfterFilterCondition> symbolEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
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

  QueryBuilder<StoredAlert, StoredAlert, QAfterFilterCondition>
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

  QueryBuilder<StoredAlert, StoredAlert, QAfterFilterCondition> symbolLessThan(
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

  QueryBuilder<StoredAlert, StoredAlert, QAfterFilterCondition> symbolBetween(
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

  QueryBuilder<StoredAlert, StoredAlert, QAfterFilterCondition>
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

  QueryBuilder<StoredAlert, StoredAlert, QAfterFilterCondition> symbolEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
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

  QueryBuilder<StoredAlert, StoredAlert, QAfterFilterCondition> symbolContains(
    String value, {
    bool caseSensitive = true,
  }) {
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

  QueryBuilder<StoredAlert, StoredAlert, QAfterFilterCondition> symbolMatches(
    String pattern, {
    bool caseSensitive = true,
  }) {
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

  QueryBuilder<StoredAlert, StoredAlert, QAfterFilterCondition>
  symbolIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'symbol', value: ''),
      );
    });
  }

  QueryBuilder<StoredAlert, StoredAlert, QAfterFilterCondition>
  symbolIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'symbol', value: ''),
      );
    });
  }

  QueryBuilder<StoredAlert, StoredAlert, QAfterFilterCondition>
  thresholdEqualTo(double value, {double epsilon = Query.epsilon}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'threshold',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<StoredAlert, StoredAlert, QAfterFilterCondition>
  thresholdGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'threshold',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<StoredAlert, StoredAlert, QAfterFilterCondition>
  thresholdLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'threshold',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<StoredAlert, StoredAlert, QAfterFilterCondition>
  thresholdBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'threshold',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<StoredAlert, StoredAlert, QAfterFilterCondition>
  triggeredAtIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'triggeredAt'),
      );
    });
  }

  QueryBuilder<StoredAlert, StoredAlert, QAfterFilterCondition>
  triggeredAtIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'triggeredAt'),
      );
    });
  }

  QueryBuilder<StoredAlert, StoredAlert, QAfterFilterCondition>
  triggeredAtEqualTo(DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'triggeredAt', value: value),
      );
    });
  }

  QueryBuilder<StoredAlert, StoredAlert, QAfterFilterCondition>
  triggeredAtGreaterThan(DateTime? value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'triggeredAt',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<StoredAlert, StoredAlert, QAfterFilterCondition>
  triggeredAtLessThan(DateTime? value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'triggeredAt',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<StoredAlert, StoredAlert, QAfterFilterCondition>
  triggeredAtBetween(
    DateTime? lower,
    DateTime? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'triggeredAt',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<StoredAlert, StoredAlert, QAfterFilterCondition> uidEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
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

  QueryBuilder<StoredAlert, StoredAlert, QAfterFilterCondition> uidGreaterThan(
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

  QueryBuilder<StoredAlert, StoredAlert, QAfterFilterCondition> uidLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
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

  QueryBuilder<StoredAlert, StoredAlert, QAfterFilterCondition> uidBetween(
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

  QueryBuilder<StoredAlert, StoredAlert, QAfterFilterCondition> uidStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
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

  QueryBuilder<StoredAlert, StoredAlert, QAfterFilterCondition> uidEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
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

  QueryBuilder<StoredAlert, StoredAlert, QAfterFilterCondition> uidContains(
    String value, {
    bool caseSensitive = true,
  }) {
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

  QueryBuilder<StoredAlert, StoredAlert, QAfterFilterCondition> uidMatches(
    String pattern, {
    bool caseSensitive = true,
  }) {
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

  QueryBuilder<StoredAlert, StoredAlert, QAfterFilterCondition> uidIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'uid', value: ''),
      );
    });
  }

  QueryBuilder<StoredAlert, StoredAlert, QAfterFilterCondition>
  uidIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'uid', value: ''),
      );
    });
  }
}

extension StoredAlertQueryObject
    on QueryBuilder<StoredAlert, StoredAlert, QFilterCondition> {}

extension StoredAlertQueryLinks
    on QueryBuilder<StoredAlert, StoredAlert, QFilterCondition> {}

extension StoredAlertQuerySortBy
    on QueryBuilder<StoredAlert, StoredAlert, QSortBy> {
  QueryBuilder<StoredAlert, StoredAlert, QAfterSortBy> sortByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<StoredAlert, StoredAlert, QAfterSortBy> sortByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<StoredAlert, StoredAlert, QAfterSortBy> sortByEnabled() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'enabled', Sort.asc);
    });
  }

  QueryBuilder<StoredAlert, StoredAlert, QAfterSortBy> sortByEnabledDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'enabled', Sort.desc);
    });
  }

  QueryBuilder<StoredAlert, StoredAlert, QAfterSortBy> sortByKindCode() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'kindCode', Sort.asc);
    });
  }

  QueryBuilder<StoredAlert, StoredAlert, QAfterSortBy> sortByKindCodeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'kindCode', Sort.desc);
    });
  }

  QueryBuilder<StoredAlert, StoredAlert, QAfterSortBy> sortByNote() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'note', Sort.asc);
    });
  }

  QueryBuilder<StoredAlert, StoredAlert, QAfterSortBy> sortByNoteDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'note', Sort.desc);
    });
  }

  QueryBuilder<StoredAlert, StoredAlert, QAfterSortBy> sortBySymbol() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'symbol', Sort.asc);
    });
  }

  QueryBuilder<StoredAlert, StoredAlert, QAfterSortBy> sortBySymbolDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'symbol', Sort.desc);
    });
  }

  QueryBuilder<StoredAlert, StoredAlert, QAfterSortBy> sortByThreshold() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'threshold', Sort.asc);
    });
  }

  QueryBuilder<StoredAlert, StoredAlert, QAfterSortBy> sortByThresholdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'threshold', Sort.desc);
    });
  }

  QueryBuilder<StoredAlert, StoredAlert, QAfterSortBy> sortByTriggeredAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'triggeredAt', Sort.asc);
    });
  }

  QueryBuilder<StoredAlert, StoredAlert, QAfterSortBy> sortByTriggeredAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'triggeredAt', Sort.desc);
    });
  }

  QueryBuilder<StoredAlert, StoredAlert, QAfterSortBy> sortByUid() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'uid', Sort.asc);
    });
  }

  QueryBuilder<StoredAlert, StoredAlert, QAfterSortBy> sortByUidDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'uid', Sort.desc);
    });
  }
}

extension StoredAlertQuerySortThenBy
    on QueryBuilder<StoredAlert, StoredAlert, QSortThenBy> {
  QueryBuilder<StoredAlert, StoredAlert, QAfterSortBy> thenByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<StoredAlert, StoredAlert, QAfterSortBy> thenByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<StoredAlert, StoredAlert, QAfterSortBy> thenByEnabled() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'enabled', Sort.asc);
    });
  }

  QueryBuilder<StoredAlert, StoredAlert, QAfterSortBy> thenByEnabledDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'enabled', Sort.desc);
    });
  }

  QueryBuilder<StoredAlert, StoredAlert, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<StoredAlert, StoredAlert, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<StoredAlert, StoredAlert, QAfterSortBy> thenByKindCode() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'kindCode', Sort.asc);
    });
  }

  QueryBuilder<StoredAlert, StoredAlert, QAfterSortBy> thenByKindCodeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'kindCode', Sort.desc);
    });
  }

  QueryBuilder<StoredAlert, StoredAlert, QAfterSortBy> thenByNote() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'note', Sort.asc);
    });
  }

  QueryBuilder<StoredAlert, StoredAlert, QAfterSortBy> thenByNoteDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'note', Sort.desc);
    });
  }

  QueryBuilder<StoredAlert, StoredAlert, QAfterSortBy> thenBySymbol() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'symbol', Sort.asc);
    });
  }

  QueryBuilder<StoredAlert, StoredAlert, QAfterSortBy> thenBySymbolDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'symbol', Sort.desc);
    });
  }

  QueryBuilder<StoredAlert, StoredAlert, QAfterSortBy> thenByThreshold() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'threshold', Sort.asc);
    });
  }

  QueryBuilder<StoredAlert, StoredAlert, QAfterSortBy> thenByThresholdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'threshold', Sort.desc);
    });
  }

  QueryBuilder<StoredAlert, StoredAlert, QAfterSortBy> thenByTriggeredAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'triggeredAt', Sort.asc);
    });
  }

  QueryBuilder<StoredAlert, StoredAlert, QAfterSortBy> thenByTriggeredAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'triggeredAt', Sort.desc);
    });
  }

  QueryBuilder<StoredAlert, StoredAlert, QAfterSortBy> thenByUid() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'uid', Sort.asc);
    });
  }

  QueryBuilder<StoredAlert, StoredAlert, QAfterSortBy> thenByUidDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'uid', Sort.desc);
    });
  }
}

extension StoredAlertQueryWhereDistinct
    on QueryBuilder<StoredAlert, StoredAlert, QDistinct> {
  QueryBuilder<StoredAlert, StoredAlert, QDistinct> distinctByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'createdAt');
    });
  }

  QueryBuilder<StoredAlert, StoredAlert, QDistinct> distinctByEnabled() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'enabled');
    });
  }

  QueryBuilder<StoredAlert, StoredAlert, QDistinct> distinctByKindCode({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'kindCode', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<StoredAlert, StoredAlert, QDistinct> distinctByNote({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'note', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<StoredAlert, StoredAlert, QDistinct> distinctBySymbol({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'symbol', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<StoredAlert, StoredAlert, QDistinct> distinctByThreshold() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'threshold');
    });
  }

  QueryBuilder<StoredAlert, StoredAlert, QDistinct> distinctByTriggeredAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'triggeredAt');
    });
  }

  QueryBuilder<StoredAlert, StoredAlert, QDistinct> distinctByUid({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'uid', caseSensitive: caseSensitive);
    });
  }
}

extension StoredAlertQueryProperty
    on QueryBuilder<StoredAlert, StoredAlert, QQueryProperty> {
  QueryBuilder<StoredAlert, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<StoredAlert, DateTime, QQueryOperations> createdAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'createdAt');
    });
  }

  QueryBuilder<StoredAlert, bool, QQueryOperations> enabledProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'enabled');
    });
  }

  QueryBuilder<StoredAlert, String, QQueryOperations> kindCodeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'kindCode');
    });
  }

  QueryBuilder<StoredAlert, String, QQueryOperations> noteProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'note');
    });
  }

  QueryBuilder<StoredAlert, String, QQueryOperations> symbolProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'symbol');
    });
  }

  QueryBuilder<StoredAlert, double, QQueryOperations> thresholdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'threshold');
    });
  }

  QueryBuilder<StoredAlert, DateTime?, QQueryOperations> triggeredAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'triggeredAt');
    });
  }

  QueryBuilder<StoredAlert, String, QQueryOperations> uidProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'uid');
    });
  }
}
