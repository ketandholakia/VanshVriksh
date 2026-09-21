// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $GenealogyPersonsTable extends GenealogyPersons
    with TableInfo<$GenealogyPersonsTable, GenealogyPerson> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $GenealogyPersonsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _firstNameMeta = const VerificationMeta(
    'firstName',
  );
  @override
  late final GeneratedColumn<String> firstName = GeneratedColumn<String>(
    'first_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _middleNameMeta = const VerificationMeta(
    'middleName',
  );
  @override
  late final GeneratedColumn<String> middleName = GeneratedColumn<String>(
    'middle_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lastNameMeta = const VerificationMeta(
    'lastName',
  );
  @override
  late final GeneratedColumn<String> lastName = GeneratedColumn<String>(
    'last_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _birthSurnameMeta = const VerificationMeta(
    'birthSurname',
  );
  @override
  late final GeneratedColumn<String> birthSurname = GeneratedColumn<String>(
    'birth_surname',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _marriedSurnameMeta = const VerificationMeta(
    'marriedSurname',
  );
  @override
  late final GeneratedColumn<String> marriedSurname = GeneratedColumn<String>(
    'married_surname',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _suffixMeta = const VerificationMeta('suffix');
  @override
  late final GeneratedColumn<String> suffix = GeneratedColumn<String>(
    'suffix',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _prefixMeta = const VerificationMeta('prefix');
  @override
  late final GeneratedColumn<String> prefix = GeneratedColumn<String>(
    'prefix',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _nicknameMeta = const VerificationMeta(
    'nickname',
  );
  @override
  late final GeneratedColumn<String> nickname = GeneratedColumn<String>(
    'nickname',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _displayNameFormatMeta = const VerificationMeta(
    'displayNameFormat',
  );
  @override
  late final GeneratedColumn<String> displayNameFormat =
      GeneratedColumn<String>(
        'display_name_format',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: const Constant('birth_married'),
      );
  static const VerificationMeta _customDisplayNameMeta = const VerificationMeta(
    'customDisplayName',
  );
  @override
  late final GeneratedColumn<String> customDisplayName =
      GeneratedColumn<String>(
        'custom_display_name',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _genderMeta = const VerificationMeta('gender');
  @override
  late final GeneratedColumn<String> gender = GeneratedColumn<String>(
    'gender',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _birthDateMeta = const VerificationMeta(
    'birthDate',
  );
  @override
  late final GeneratedColumn<DateTime> birthDate = GeneratedColumn<DateTime>(
    'birth_date',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _birthDateQualifierMeta =
      const VerificationMeta('birthDateQualifier');
  @override
  late final GeneratedColumn<String> birthDateQualifier =
      GeneratedColumn<String>(
        'birth_date_qualifier',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _birthPlaceMeta = const VerificationMeta(
    'birthPlace',
  );
  @override
  late final GeneratedColumn<String> birthPlace = GeneratedColumn<String>(
    'birth_place',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _birthPlaceLatMeta = const VerificationMeta(
    'birthPlaceLat',
  );
  @override
  late final GeneratedColumn<double> birthPlaceLat = GeneratedColumn<double>(
    'birth_place_lat',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _birthPlaceLngMeta = const VerificationMeta(
    'birthPlaceLng',
  );
  @override
  late final GeneratedColumn<double> birthPlaceLng = GeneratedColumn<double>(
    'birth_place_lng',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _deathDateMeta = const VerificationMeta(
    'deathDate',
  );
  @override
  late final GeneratedColumn<DateTime> deathDate = GeneratedColumn<DateTime>(
    'death_date',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _deathDateQualifierMeta =
      const VerificationMeta('deathDateQualifier');
  @override
  late final GeneratedColumn<String> deathDateQualifier =
      GeneratedColumn<String>(
        'death_date_qualifier',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _deathPlaceMeta = const VerificationMeta(
    'deathPlace',
  );
  @override
  late final GeneratedColumn<String> deathPlace = GeneratedColumn<String>(
    'death_place',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _deathPlaceLatMeta = const VerificationMeta(
    'deathPlaceLat',
  );
  @override
  late final GeneratedColumn<double> deathPlaceLat = GeneratedColumn<double>(
    'death_place_lat',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _deathPlaceLngMeta = const VerificationMeta(
    'deathPlaceLng',
  );
  @override
  late final GeneratedColumn<double> deathPlaceLng = GeneratedColumn<double>(
    'death_place_lng',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _currentPlaceMeta = const VerificationMeta(
    'currentPlace',
  );
  @override
  late final GeneratedColumn<String> currentPlace = GeneratedColumn<String>(
    'current_place',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isLivingMeta = const VerificationMeta(
    'isLiving',
  );
  @override
  late final GeneratedColumn<bool> isLiving = GeneratedColumn<bool>(
    'is_living',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_living" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _profilePhotoPathMeta = const VerificationMeta(
    'profilePhotoPath',
  );
  @override
  late final GeneratedColumn<String> profilePhotoPath = GeneratedColumn<String>(
    'profile_photo_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _biographyMeta = const VerificationMeta(
    'biography',
  );
  @override
  late final GeneratedColumn<String> biography = GeneratedColumn<String>(
    'biography',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _occupationMeta = const VerificationMeta(
    'occupation',
  );
  @override
  late final GeneratedColumn<String> occupation = GeneratedColumn<String>(
    'occupation',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _religionMeta = const VerificationMeta(
    'religion',
  );
  @override
  late final GeneratedColumn<String> religion = GeneratedColumn<String>(
    'religion',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _ethnicityMeta = const VerificationMeta(
    'ethnicity',
  );
  @override
  late final GeneratedColumn<String> ethnicity = GeneratedColumn<String>(
    'ethnicity',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isPrivateMeta = const VerificationMeta(
    'isPrivate',
  );
  @override
  late final GeneratedColumn<bool> isPrivate = GeneratedColumn<bool>(
    'is_private',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_private" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _privacyLevelMeta = const VerificationMeta(
    'privacyLevel',
  );
  @override
  late final GeneratedColumn<int> privacyLevel = GeneratedColumn<int>(
    'privacy_level',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _treeIdMeta = const VerificationMeta('treeId');
  @override
  late final GeneratedColumn<String> treeId = GeneratedColumn<String>(
    'tree_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _uuidMeta = const VerificationMeta('uuid');
  @override
  late final GeneratedColumn<String> uuid = GeneratedColumn<String>(
    'uuid',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _isDeletedMeta = const VerificationMeta(
    'isDeleted',
  );
  @override
  late final GeneratedColumn<bool> isDeleted = GeneratedColumn<bool>(
    'is_deleted',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_deleted" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _mergedIntoIdMeta = const VerificationMeta(
    'mergedIntoId',
  );
  @override
  late final GeneratedColumn<String> mergedIntoId = GeneratedColumn<String>(
    'merged_into_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES genealogy_persons (id) ON DELETE SET NULL',
    ),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    firstName,
    middleName,
    lastName,
    birthSurname,
    marriedSurname,
    suffix,
    prefix,
    nickname,
    displayNameFormat,
    customDisplayName,
    gender,
    birthDate,
    birthDateQualifier,
    birthPlace,
    birthPlaceLat,
    birthPlaceLng,
    deathDate,
    deathDateQualifier,
    deathPlace,
    deathPlaceLat,
    deathPlaceLng,
    currentPlace,
    isLiving,
    profilePhotoPath,
    biography,
    notes,
    occupation,
    religion,
    ethnicity,
    isPrivate,
    privacyLevel,
    treeId,
    uuid,
    isDeleted,
    createdAt,
    updatedAt,
    mergedIntoId,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'genealogy_persons';
  @override
  VerificationContext validateIntegrity(
    Insertable<GenealogyPerson> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('first_name')) {
      context.handle(
        _firstNameMeta,
        firstName.isAcceptableOrUnknown(data['first_name']!, _firstNameMeta),
      );
    } else if (isInserting) {
      context.missing(_firstNameMeta);
    }
    if (data.containsKey('middle_name')) {
      context.handle(
        _middleNameMeta,
        middleName.isAcceptableOrUnknown(data['middle_name']!, _middleNameMeta),
      );
    }
    if (data.containsKey('last_name')) {
      context.handle(
        _lastNameMeta,
        lastName.isAcceptableOrUnknown(data['last_name']!, _lastNameMeta),
      );
    }
    if (data.containsKey('birth_surname')) {
      context.handle(
        _birthSurnameMeta,
        birthSurname.isAcceptableOrUnknown(
          data['birth_surname']!,
          _birthSurnameMeta,
        ),
      );
    }
    if (data.containsKey('married_surname')) {
      context.handle(
        _marriedSurnameMeta,
        marriedSurname.isAcceptableOrUnknown(
          data['married_surname']!,
          _marriedSurnameMeta,
        ),
      );
    }
    if (data.containsKey('suffix')) {
      context.handle(
        _suffixMeta,
        suffix.isAcceptableOrUnknown(data['suffix']!, _suffixMeta),
      );
    }
    if (data.containsKey('prefix')) {
      context.handle(
        _prefixMeta,
        prefix.isAcceptableOrUnknown(data['prefix']!, _prefixMeta),
      );
    }
    if (data.containsKey('nickname')) {
      context.handle(
        _nicknameMeta,
        nickname.isAcceptableOrUnknown(data['nickname']!, _nicknameMeta),
      );
    }
    if (data.containsKey('display_name_format')) {
      context.handle(
        _displayNameFormatMeta,
        displayNameFormat.isAcceptableOrUnknown(
          data['display_name_format']!,
          _displayNameFormatMeta,
        ),
      );
    }
    if (data.containsKey('custom_display_name')) {
      context.handle(
        _customDisplayNameMeta,
        customDisplayName.isAcceptableOrUnknown(
          data['custom_display_name']!,
          _customDisplayNameMeta,
        ),
      );
    }
    if (data.containsKey('gender')) {
      context.handle(
        _genderMeta,
        gender.isAcceptableOrUnknown(data['gender']!, _genderMeta),
      );
    } else if (isInserting) {
      context.missing(_genderMeta);
    }
    if (data.containsKey('birth_date')) {
      context.handle(
        _birthDateMeta,
        birthDate.isAcceptableOrUnknown(data['birth_date']!, _birthDateMeta),
      );
    }
    if (data.containsKey('birth_date_qualifier')) {
      context.handle(
        _birthDateQualifierMeta,
        birthDateQualifier.isAcceptableOrUnknown(
          data['birth_date_qualifier']!,
          _birthDateQualifierMeta,
        ),
      );
    }
    if (data.containsKey('birth_place')) {
      context.handle(
        _birthPlaceMeta,
        birthPlace.isAcceptableOrUnknown(data['birth_place']!, _birthPlaceMeta),
      );
    }
    if (data.containsKey('birth_place_lat')) {
      context.handle(
        _birthPlaceLatMeta,
        birthPlaceLat.isAcceptableOrUnknown(
          data['birth_place_lat']!,
          _birthPlaceLatMeta,
        ),
      );
    }
    if (data.containsKey('birth_place_lng')) {
      context.handle(
        _birthPlaceLngMeta,
        birthPlaceLng.isAcceptableOrUnknown(
          data['birth_place_lng']!,
          _birthPlaceLngMeta,
        ),
      );
    }
    if (data.containsKey('death_date')) {
      context.handle(
        _deathDateMeta,
        deathDate.isAcceptableOrUnknown(data['death_date']!, _deathDateMeta),
      );
    }
    if (data.containsKey('death_date_qualifier')) {
      context.handle(
        _deathDateQualifierMeta,
        deathDateQualifier.isAcceptableOrUnknown(
          data['death_date_qualifier']!,
          _deathDateQualifierMeta,
        ),
      );
    }
    if (data.containsKey('death_place')) {
      context.handle(
        _deathPlaceMeta,
        deathPlace.isAcceptableOrUnknown(data['death_place']!, _deathPlaceMeta),
      );
    }
    if (data.containsKey('death_place_lat')) {
      context.handle(
        _deathPlaceLatMeta,
        deathPlaceLat.isAcceptableOrUnknown(
          data['death_place_lat']!,
          _deathPlaceLatMeta,
        ),
      );
    }
    if (data.containsKey('death_place_lng')) {
      context.handle(
        _deathPlaceLngMeta,
        deathPlaceLng.isAcceptableOrUnknown(
          data['death_place_lng']!,
          _deathPlaceLngMeta,
        ),
      );
    }
    if (data.containsKey('current_place')) {
      context.handle(
        _currentPlaceMeta,
        currentPlace.isAcceptableOrUnknown(
          data['current_place']!,
          _currentPlaceMeta,
        ),
      );
    }
    if (data.containsKey('is_living')) {
      context.handle(
        _isLivingMeta,
        isLiving.isAcceptableOrUnknown(data['is_living']!, _isLivingMeta),
      );
    }
    if (data.containsKey('profile_photo_path')) {
      context.handle(
        _profilePhotoPathMeta,
        profilePhotoPath.isAcceptableOrUnknown(
          data['profile_photo_path']!,
          _profilePhotoPathMeta,
        ),
      );
    }
    if (data.containsKey('biography')) {
      context.handle(
        _biographyMeta,
        biography.isAcceptableOrUnknown(data['biography']!, _biographyMeta),
      );
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    if (data.containsKey('occupation')) {
      context.handle(
        _occupationMeta,
        occupation.isAcceptableOrUnknown(data['occupation']!, _occupationMeta),
      );
    }
    if (data.containsKey('religion')) {
      context.handle(
        _religionMeta,
        religion.isAcceptableOrUnknown(data['religion']!, _religionMeta),
      );
    }
    if (data.containsKey('ethnicity')) {
      context.handle(
        _ethnicityMeta,
        ethnicity.isAcceptableOrUnknown(data['ethnicity']!, _ethnicityMeta),
      );
    }
    if (data.containsKey('is_private')) {
      context.handle(
        _isPrivateMeta,
        isPrivate.isAcceptableOrUnknown(data['is_private']!, _isPrivateMeta),
      );
    }
    if (data.containsKey('privacy_level')) {
      context.handle(
        _privacyLevelMeta,
        privacyLevel.isAcceptableOrUnknown(
          data['privacy_level']!,
          _privacyLevelMeta,
        ),
      );
    }
    if (data.containsKey('tree_id')) {
      context.handle(
        _treeIdMeta,
        treeId.isAcceptableOrUnknown(data['tree_id']!, _treeIdMeta),
      );
    } else if (isInserting) {
      context.missing(_treeIdMeta);
    }
    if (data.containsKey('uuid')) {
      context.handle(
        _uuidMeta,
        uuid.isAcceptableOrUnknown(data['uuid']!, _uuidMeta),
      );
    } else if (isInserting) {
      context.missing(_uuidMeta);
    }
    if (data.containsKey('is_deleted')) {
      context.handle(
        _isDeletedMeta,
        isDeleted.isAcceptableOrUnknown(data['is_deleted']!, _isDeletedMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    if (data.containsKey('merged_into_id')) {
      context.handle(
        _mergedIntoIdMeta,
        mergedIntoId.isAcceptableOrUnknown(
          data['merged_into_id']!,
          _mergedIntoIdMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  GenealogyPerson map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return GenealogyPerson(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      firstName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}first_name'],
      )!,
      middleName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}middle_name'],
      ),
      lastName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_name'],
      ),
      birthSurname: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}birth_surname'],
      ),
      marriedSurname: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}married_surname'],
      ),
      suffix: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}suffix'],
      ),
      prefix: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}prefix'],
      ),
      nickname: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}nickname'],
      ),
      displayNameFormat: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}display_name_format'],
      )!,
      customDisplayName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}custom_display_name'],
      ),
      gender: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}gender'],
      )!,
      birthDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}birth_date'],
      ),
      birthDateQualifier: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}birth_date_qualifier'],
      ),
      birthPlace: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}birth_place'],
      ),
      birthPlaceLat: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}birth_place_lat'],
      ),
      birthPlaceLng: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}birth_place_lng'],
      ),
      deathDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}death_date'],
      ),
      deathDateQualifier: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}death_date_qualifier'],
      ),
      deathPlace: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}death_place'],
      ),
      deathPlaceLat: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}death_place_lat'],
      ),
      deathPlaceLng: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}death_place_lng'],
      ),
      currentPlace: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}current_place'],
      ),
      isLiving: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_living'],
      )!,
      profilePhotoPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}profile_photo_path'],
      ),
      biography: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}biography'],
      ),
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
      occupation: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}occupation'],
      ),
      religion: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}religion'],
      ),
      ethnicity: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}ethnicity'],
      ),
      isPrivate: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_private'],
      )!,
      privacyLevel: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}privacy_level'],
      )!,
      treeId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tree_id'],
      )!,
      uuid: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}uuid'],
      )!,
      isDeleted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_deleted'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      mergedIntoId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}merged_into_id'],
      ),
    );
  }

  @override
  $GenealogyPersonsTable createAlias(String alias) {
    return $GenealogyPersonsTable(attachedDatabase, alias);
  }
}

class GenealogyPerson extends DataClass implements Insertable<GenealogyPerson> {
  final String id;
  final String firstName;
  final String? middleName;
  final String? lastName;
  final String? birthSurname;
  final String? marriedSurname;
  final String? suffix;
  final String? prefix;
  final String? nickname;
  final String displayNameFormat;
  final String? customDisplayName;
  final String gender;
  final DateTime? birthDate;
  final String? birthDateQualifier;
  final String? birthPlace;
  final double? birthPlaceLat;
  final double? birthPlaceLng;
  final DateTime? deathDate;
  final String? deathDateQualifier;
  final String? deathPlace;
  final double? deathPlaceLat;
  final double? deathPlaceLng;
  final String? currentPlace;
  final bool isLiving;
  final String? profilePhotoPath;
  final String? biography;
  final String? notes;
  final String? occupation;
  final String? religion;
  final String? ethnicity;
  final bool isPrivate;
  final int privacyLevel;

  /// Owning tree. Mandatory, integrity checked.
  ///
  /// Declared as a raw table constraint rather than with `.references()`:
  /// `family_trees.root_person_id` points back at this table, and when drift sees
  /// that cycle it silently drops one of the two references — historically the
  /// one it dropped was *this* mandatory ownership key, leaving `tree_id`
  /// unconstrained. A table constraint keeps both directions enforced.
  final String treeId;

  /// Stable external identity.
  final String uuid;
  final bool isDeleted;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// Set when this person was merged into another person.
  final String? mergedIntoId;
  const GenealogyPerson({
    required this.id,
    required this.firstName,
    this.middleName,
    this.lastName,
    this.birthSurname,
    this.marriedSurname,
    this.suffix,
    this.prefix,
    this.nickname,
    required this.displayNameFormat,
    this.customDisplayName,
    required this.gender,
    this.birthDate,
    this.birthDateQualifier,
    this.birthPlace,
    this.birthPlaceLat,
    this.birthPlaceLng,
    this.deathDate,
    this.deathDateQualifier,
    this.deathPlace,
    this.deathPlaceLat,
    this.deathPlaceLng,
    this.currentPlace,
    required this.isLiving,
    this.profilePhotoPath,
    this.biography,
    this.notes,
    this.occupation,
    this.religion,
    this.ethnicity,
    required this.isPrivate,
    required this.privacyLevel,
    required this.treeId,
    required this.uuid,
    required this.isDeleted,
    required this.createdAt,
    required this.updatedAt,
    this.mergedIntoId,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['first_name'] = Variable<String>(firstName);
    if (!nullToAbsent || middleName != null) {
      map['middle_name'] = Variable<String>(middleName);
    }
    if (!nullToAbsent || lastName != null) {
      map['last_name'] = Variable<String>(lastName);
    }
    if (!nullToAbsent || birthSurname != null) {
      map['birth_surname'] = Variable<String>(birthSurname);
    }
    if (!nullToAbsent || marriedSurname != null) {
      map['married_surname'] = Variable<String>(marriedSurname);
    }
    if (!nullToAbsent || suffix != null) {
      map['suffix'] = Variable<String>(suffix);
    }
    if (!nullToAbsent || prefix != null) {
      map['prefix'] = Variable<String>(prefix);
    }
    if (!nullToAbsent || nickname != null) {
      map['nickname'] = Variable<String>(nickname);
    }
    map['display_name_format'] = Variable<String>(displayNameFormat);
    if (!nullToAbsent || customDisplayName != null) {
      map['custom_display_name'] = Variable<String>(customDisplayName);
    }
    map['gender'] = Variable<String>(gender);
    if (!nullToAbsent || birthDate != null) {
      map['birth_date'] = Variable<DateTime>(birthDate);
    }
    if (!nullToAbsent || birthDateQualifier != null) {
      map['birth_date_qualifier'] = Variable<String>(birthDateQualifier);
    }
    if (!nullToAbsent || birthPlace != null) {
      map['birth_place'] = Variable<String>(birthPlace);
    }
    if (!nullToAbsent || birthPlaceLat != null) {
      map['birth_place_lat'] = Variable<double>(birthPlaceLat);
    }
    if (!nullToAbsent || birthPlaceLng != null) {
      map['birth_place_lng'] = Variable<double>(birthPlaceLng);
    }
    if (!nullToAbsent || deathDate != null) {
      map['death_date'] = Variable<DateTime>(deathDate);
    }
    if (!nullToAbsent || deathDateQualifier != null) {
      map['death_date_qualifier'] = Variable<String>(deathDateQualifier);
    }
    if (!nullToAbsent || deathPlace != null) {
      map['death_place'] = Variable<String>(deathPlace);
    }
    if (!nullToAbsent || deathPlaceLat != null) {
      map['death_place_lat'] = Variable<double>(deathPlaceLat);
    }
    if (!nullToAbsent || deathPlaceLng != null) {
      map['death_place_lng'] = Variable<double>(deathPlaceLng);
    }
    if (!nullToAbsent || currentPlace != null) {
      map['current_place'] = Variable<String>(currentPlace);
    }
    map['is_living'] = Variable<bool>(isLiving);
    if (!nullToAbsent || profilePhotoPath != null) {
      map['profile_photo_path'] = Variable<String>(profilePhotoPath);
    }
    if (!nullToAbsent || biography != null) {
      map['biography'] = Variable<String>(biography);
    }
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    if (!nullToAbsent || occupation != null) {
      map['occupation'] = Variable<String>(occupation);
    }
    if (!nullToAbsent || religion != null) {
      map['religion'] = Variable<String>(religion);
    }
    if (!nullToAbsent || ethnicity != null) {
      map['ethnicity'] = Variable<String>(ethnicity);
    }
    map['is_private'] = Variable<bool>(isPrivate);
    map['privacy_level'] = Variable<int>(privacyLevel);
    map['tree_id'] = Variable<String>(treeId);
    map['uuid'] = Variable<String>(uuid);
    map['is_deleted'] = Variable<bool>(isDeleted);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || mergedIntoId != null) {
      map['merged_into_id'] = Variable<String>(mergedIntoId);
    }
    return map;
  }

  GenealogyPersonsCompanion toCompanion(bool nullToAbsent) {
    return GenealogyPersonsCompanion(
      id: Value(id),
      firstName: Value(firstName),
      middleName: middleName == null && nullToAbsent
          ? const Value.absent()
          : Value(middleName),
      lastName: lastName == null && nullToAbsent
          ? const Value.absent()
          : Value(lastName),
      birthSurname: birthSurname == null && nullToAbsent
          ? const Value.absent()
          : Value(birthSurname),
      marriedSurname: marriedSurname == null && nullToAbsent
          ? const Value.absent()
          : Value(marriedSurname),
      suffix: suffix == null && nullToAbsent
          ? const Value.absent()
          : Value(suffix),
      prefix: prefix == null && nullToAbsent
          ? const Value.absent()
          : Value(prefix),
      nickname: nickname == null && nullToAbsent
          ? const Value.absent()
          : Value(nickname),
      displayNameFormat: Value(displayNameFormat),
      customDisplayName: customDisplayName == null && nullToAbsent
          ? const Value.absent()
          : Value(customDisplayName),
      gender: Value(gender),
      birthDate: birthDate == null && nullToAbsent
          ? const Value.absent()
          : Value(birthDate),
      birthDateQualifier: birthDateQualifier == null && nullToAbsent
          ? const Value.absent()
          : Value(birthDateQualifier),
      birthPlace: birthPlace == null && nullToAbsent
          ? const Value.absent()
          : Value(birthPlace),
      birthPlaceLat: birthPlaceLat == null && nullToAbsent
          ? const Value.absent()
          : Value(birthPlaceLat),
      birthPlaceLng: birthPlaceLng == null && nullToAbsent
          ? const Value.absent()
          : Value(birthPlaceLng),
      deathDate: deathDate == null && nullToAbsent
          ? const Value.absent()
          : Value(deathDate),
      deathDateQualifier: deathDateQualifier == null && nullToAbsent
          ? const Value.absent()
          : Value(deathDateQualifier),
      deathPlace: deathPlace == null && nullToAbsent
          ? const Value.absent()
          : Value(deathPlace),
      deathPlaceLat: deathPlaceLat == null && nullToAbsent
          ? const Value.absent()
          : Value(deathPlaceLat),
      deathPlaceLng: deathPlaceLng == null && nullToAbsent
          ? const Value.absent()
          : Value(deathPlaceLng),
      currentPlace: currentPlace == null && nullToAbsent
          ? const Value.absent()
          : Value(currentPlace),
      isLiving: Value(isLiving),
      profilePhotoPath: profilePhotoPath == null && nullToAbsent
          ? const Value.absent()
          : Value(profilePhotoPath),
      biography: biography == null && nullToAbsent
          ? const Value.absent()
          : Value(biography),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
          : Value(notes),
      occupation: occupation == null && nullToAbsent
          ? const Value.absent()
          : Value(occupation),
      religion: religion == null && nullToAbsent
          ? const Value.absent()
          : Value(religion),
      ethnicity: ethnicity == null && nullToAbsent
          ? const Value.absent()
          : Value(ethnicity),
      isPrivate: Value(isPrivate),
      privacyLevel: Value(privacyLevel),
      treeId: Value(treeId),
      uuid: Value(uuid),
      isDeleted: Value(isDeleted),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      mergedIntoId: mergedIntoId == null && nullToAbsent
          ? const Value.absent()
          : Value(mergedIntoId),
    );
  }

  factory GenealogyPerson.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return GenealogyPerson(
      id: serializer.fromJson<String>(json['id']),
      firstName: serializer.fromJson<String>(json['firstName']),
      middleName: serializer.fromJson<String?>(json['middleName']),
      lastName: serializer.fromJson<String?>(json['lastName']),
      birthSurname: serializer.fromJson<String?>(json['birthSurname']),
      marriedSurname: serializer.fromJson<String?>(json['marriedSurname']),
      suffix: serializer.fromJson<String?>(json['suffix']),
      prefix: serializer.fromJson<String?>(json['prefix']),
      nickname: serializer.fromJson<String?>(json['nickname']),
      displayNameFormat: serializer.fromJson<String>(json['displayNameFormat']),
      customDisplayName: serializer.fromJson<String?>(
        json['customDisplayName'],
      ),
      gender: serializer.fromJson<String>(json['gender']),
      birthDate: serializer.fromJson<DateTime?>(json['birthDate']),
      birthDateQualifier: serializer.fromJson<String?>(
        json['birthDateQualifier'],
      ),
      birthPlace: serializer.fromJson<String?>(json['birthPlace']),
      birthPlaceLat: serializer.fromJson<double?>(json['birthPlaceLat']),
      birthPlaceLng: serializer.fromJson<double?>(json['birthPlaceLng']),
      deathDate: serializer.fromJson<DateTime?>(json['deathDate']),
      deathDateQualifier: serializer.fromJson<String?>(
        json['deathDateQualifier'],
      ),
      deathPlace: serializer.fromJson<String?>(json['deathPlace']),
      deathPlaceLat: serializer.fromJson<double?>(json['deathPlaceLat']),
      deathPlaceLng: serializer.fromJson<double?>(json['deathPlaceLng']),
      currentPlace: serializer.fromJson<String?>(json['currentPlace']),
      isLiving: serializer.fromJson<bool>(json['isLiving']),
      profilePhotoPath: serializer.fromJson<String?>(json['profilePhotoPath']),
      biography: serializer.fromJson<String?>(json['biography']),
      notes: serializer.fromJson<String?>(json['notes']),
      occupation: serializer.fromJson<String?>(json['occupation']),
      religion: serializer.fromJson<String?>(json['religion']),
      ethnicity: serializer.fromJson<String?>(json['ethnicity']),
      isPrivate: serializer.fromJson<bool>(json['isPrivate']),
      privacyLevel: serializer.fromJson<int>(json['privacyLevel']),
      treeId: serializer.fromJson<String>(json['treeId']),
      uuid: serializer.fromJson<String>(json['uuid']),
      isDeleted: serializer.fromJson<bool>(json['isDeleted']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      mergedIntoId: serializer.fromJson<String?>(json['mergedIntoId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'firstName': serializer.toJson<String>(firstName),
      'middleName': serializer.toJson<String?>(middleName),
      'lastName': serializer.toJson<String?>(lastName),
      'birthSurname': serializer.toJson<String?>(birthSurname),
      'marriedSurname': serializer.toJson<String?>(marriedSurname),
      'suffix': serializer.toJson<String?>(suffix),
      'prefix': serializer.toJson<String?>(prefix),
      'nickname': serializer.toJson<String?>(nickname),
      'displayNameFormat': serializer.toJson<String>(displayNameFormat),
      'customDisplayName': serializer.toJson<String?>(customDisplayName),
      'gender': serializer.toJson<String>(gender),
      'birthDate': serializer.toJson<DateTime?>(birthDate),
      'birthDateQualifier': serializer.toJson<String?>(birthDateQualifier),
      'birthPlace': serializer.toJson<String?>(birthPlace),
      'birthPlaceLat': serializer.toJson<double?>(birthPlaceLat),
      'birthPlaceLng': serializer.toJson<double?>(birthPlaceLng),
      'deathDate': serializer.toJson<DateTime?>(deathDate),
      'deathDateQualifier': serializer.toJson<String?>(deathDateQualifier),
      'deathPlace': serializer.toJson<String?>(deathPlace),
      'deathPlaceLat': serializer.toJson<double?>(deathPlaceLat),
      'deathPlaceLng': serializer.toJson<double?>(deathPlaceLng),
      'currentPlace': serializer.toJson<String?>(currentPlace),
      'isLiving': serializer.toJson<bool>(isLiving),
      'profilePhotoPath': serializer.toJson<String?>(profilePhotoPath),
      'biography': serializer.toJson<String?>(biography),
      'notes': serializer.toJson<String?>(notes),
      'occupation': serializer.toJson<String?>(occupation),
      'religion': serializer.toJson<String?>(religion),
      'ethnicity': serializer.toJson<String?>(ethnicity),
      'isPrivate': serializer.toJson<bool>(isPrivate),
      'privacyLevel': serializer.toJson<int>(privacyLevel),
      'treeId': serializer.toJson<String>(treeId),
      'uuid': serializer.toJson<String>(uuid),
      'isDeleted': serializer.toJson<bool>(isDeleted),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'mergedIntoId': serializer.toJson<String?>(mergedIntoId),
    };
  }

  GenealogyPerson copyWith({
    String? id,
    String? firstName,
    Value<String?> middleName = const Value.absent(),
    Value<String?> lastName = const Value.absent(),
    Value<String?> birthSurname = const Value.absent(),
    Value<String?> marriedSurname = const Value.absent(),
    Value<String?> suffix = const Value.absent(),
    Value<String?> prefix = const Value.absent(),
    Value<String?> nickname = const Value.absent(),
    String? displayNameFormat,
    Value<String?> customDisplayName = const Value.absent(),
    String? gender,
    Value<DateTime?> birthDate = const Value.absent(),
    Value<String?> birthDateQualifier = const Value.absent(),
    Value<String?> birthPlace = const Value.absent(),
    Value<double?> birthPlaceLat = const Value.absent(),
    Value<double?> birthPlaceLng = const Value.absent(),
    Value<DateTime?> deathDate = const Value.absent(),
    Value<String?> deathDateQualifier = const Value.absent(),
    Value<String?> deathPlace = const Value.absent(),
    Value<double?> deathPlaceLat = const Value.absent(),
    Value<double?> deathPlaceLng = const Value.absent(),
    Value<String?> currentPlace = const Value.absent(),
    bool? isLiving,
    Value<String?> profilePhotoPath = const Value.absent(),
    Value<String?> biography = const Value.absent(),
    Value<String?> notes = const Value.absent(),
    Value<String?> occupation = const Value.absent(),
    Value<String?> religion = const Value.absent(),
    Value<String?> ethnicity = const Value.absent(),
    bool? isPrivate,
    int? privacyLevel,
    String? treeId,
    String? uuid,
    bool? isDeleted,
    DateTime? createdAt,
    DateTime? updatedAt,
    Value<String?> mergedIntoId = const Value.absent(),
  }) => GenealogyPerson(
    id: id ?? this.id,
    firstName: firstName ?? this.firstName,
    middleName: middleName.present ? middleName.value : this.middleName,
    lastName: lastName.present ? lastName.value : this.lastName,
    birthSurname: birthSurname.present ? birthSurname.value : this.birthSurname,
    marriedSurname: marriedSurname.present
        ? marriedSurname.value
        : this.marriedSurname,
    suffix: suffix.present ? suffix.value : this.suffix,
    prefix: prefix.present ? prefix.value : this.prefix,
    nickname: nickname.present ? nickname.value : this.nickname,
    displayNameFormat: displayNameFormat ?? this.displayNameFormat,
    customDisplayName: customDisplayName.present
        ? customDisplayName.value
        : this.customDisplayName,
    gender: gender ?? this.gender,
    birthDate: birthDate.present ? birthDate.value : this.birthDate,
    birthDateQualifier: birthDateQualifier.present
        ? birthDateQualifier.value
        : this.birthDateQualifier,
    birthPlace: birthPlace.present ? birthPlace.value : this.birthPlace,
    birthPlaceLat: birthPlaceLat.present
        ? birthPlaceLat.value
        : this.birthPlaceLat,
    birthPlaceLng: birthPlaceLng.present
        ? birthPlaceLng.value
        : this.birthPlaceLng,
    deathDate: deathDate.present ? deathDate.value : this.deathDate,
    deathDateQualifier: deathDateQualifier.present
        ? deathDateQualifier.value
        : this.deathDateQualifier,
    deathPlace: deathPlace.present ? deathPlace.value : this.deathPlace,
    deathPlaceLat: deathPlaceLat.present
        ? deathPlaceLat.value
        : this.deathPlaceLat,
    deathPlaceLng: deathPlaceLng.present
        ? deathPlaceLng.value
        : this.deathPlaceLng,
    currentPlace: currentPlace.present ? currentPlace.value : this.currentPlace,
    isLiving: isLiving ?? this.isLiving,
    profilePhotoPath: profilePhotoPath.present
        ? profilePhotoPath.value
        : this.profilePhotoPath,
    biography: biography.present ? biography.value : this.biography,
    notes: notes.present ? notes.value : this.notes,
    occupation: occupation.present ? occupation.value : this.occupation,
    religion: religion.present ? religion.value : this.religion,
    ethnicity: ethnicity.present ? ethnicity.value : this.ethnicity,
    isPrivate: isPrivate ?? this.isPrivate,
    privacyLevel: privacyLevel ?? this.privacyLevel,
    treeId: treeId ?? this.treeId,
    uuid: uuid ?? this.uuid,
    isDeleted: isDeleted ?? this.isDeleted,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    mergedIntoId: mergedIntoId.present ? mergedIntoId.value : this.mergedIntoId,
  );
  GenealogyPerson copyWithCompanion(GenealogyPersonsCompanion data) {
    return GenealogyPerson(
      id: data.id.present ? data.id.value : this.id,
      firstName: data.firstName.present ? data.firstName.value : this.firstName,
      middleName: data.middleName.present
          ? data.middleName.value
          : this.middleName,
      lastName: data.lastName.present ? data.lastName.value : this.lastName,
      birthSurname: data.birthSurname.present
          ? data.birthSurname.value
          : this.birthSurname,
      marriedSurname: data.marriedSurname.present
          ? data.marriedSurname.value
          : this.marriedSurname,
      suffix: data.suffix.present ? data.suffix.value : this.suffix,
      prefix: data.prefix.present ? data.prefix.value : this.prefix,
      nickname: data.nickname.present ? data.nickname.value : this.nickname,
      displayNameFormat: data.displayNameFormat.present
          ? data.displayNameFormat.value
          : this.displayNameFormat,
      customDisplayName: data.customDisplayName.present
          ? data.customDisplayName.value
          : this.customDisplayName,
      gender: data.gender.present ? data.gender.value : this.gender,
      birthDate: data.birthDate.present ? data.birthDate.value : this.birthDate,
      birthDateQualifier: data.birthDateQualifier.present
          ? data.birthDateQualifier.value
          : this.birthDateQualifier,
      birthPlace: data.birthPlace.present
          ? data.birthPlace.value
          : this.birthPlace,
      birthPlaceLat: data.birthPlaceLat.present
          ? data.birthPlaceLat.value
          : this.birthPlaceLat,
      birthPlaceLng: data.birthPlaceLng.present
          ? data.birthPlaceLng.value
          : this.birthPlaceLng,
      deathDate: data.deathDate.present ? data.deathDate.value : this.deathDate,
      deathDateQualifier: data.deathDateQualifier.present
          ? data.deathDateQualifier.value
          : this.deathDateQualifier,
      deathPlace: data.deathPlace.present
          ? data.deathPlace.value
          : this.deathPlace,
      deathPlaceLat: data.deathPlaceLat.present
          ? data.deathPlaceLat.value
          : this.deathPlaceLat,
      deathPlaceLng: data.deathPlaceLng.present
          ? data.deathPlaceLng.value
          : this.deathPlaceLng,
      currentPlace: data.currentPlace.present
          ? data.currentPlace.value
          : this.currentPlace,
      isLiving: data.isLiving.present ? data.isLiving.value : this.isLiving,
      profilePhotoPath: data.profilePhotoPath.present
          ? data.profilePhotoPath.value
          : this.profilePhotoPath,
      biography: data.biography.present ? data.biography.value : this.biography,
      notes: data.notes.present ? data.notes.value : this.notes,
      occupation: data.occupation.present
          ? data.occupation.value
          : this.occupation,
      religion: data.religion.present ? data.religion.value : this.religion,
      ethnicity: data.ethnicity.present ? data.ethnicity.value : this.ethnicity,
      isPrivate: data.isPrivate.present ? data.isPrivate.value : this.isPrivate,
      privacyLevel: data.privacyLevel.present
          ? data.privacyLevel.value
          : this.privacyLevel,
      treeId: data.treeId.present ? data.treeId.value : this.treeId,
      uuid: data.uuid.present ? data.uuid.value : this.uuid,
      isDeleted: data.isDeleted.present ? data.isDeleted.value : this.isDeleted,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      mergedIntoId: data.mergedIntoId.present
          ? data.mergedIntoId.value
          : this.mergedIntoId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('GenealogyPerson(')
          ..write('id: $id, ')
          ..write('firstName: $firstName, ')
          ..write('middleName: $middleName, ')
          ..write('lastName: $lastName, ')
          ..write('birthSurname: $birthSurname, ')
          ..write('marriedSurname: $marriedSurname, ')
          ..write('suffix: $suffix, ')
          ..write('prefix: $prefix, ')
          ..write('nickname: $nickname, ')
          ..write('displayNameFormat: $displayNameFormat, ')
          ..write('customDisplayName: $customDisplayName, ')
          ..write('gender: $gender, ')
          ..write('birthDate: $birthDate, ')
          ..write('birthDateQualifier: $birthDateQualifier, ')
          ..write('birthPlace: $birthPlace, ')
          ..write('birthPlaceLat: $birthPlaceLat, ')
          ..write('birthPlaceLng: $birthPlaceLng, ')
          ..write('deathDate: $deathDate, ')
          ..write('deathDateQualifier: $deathDateQualifier, ')
          ..write('deathPlace: $deathPlace, ')
          ..write('deathPlaceLat: $deathPlaceLat, ')
          ..write('deathPlaceLng: $deathPlaceLng, ')
          ..write('currentPlace: $currentPlace, ')
          ..write('isLiving: $isLiving, ')
          ..write('profilePhotoPath: $profilePhotoPath, ')
          ..write('biography: $biography, ')
          ..write('notes: $notes, ')
          ..write('occupation: $occupation, ')
          ..write('religion: $religion, ')
          ..write('ethnicity: $ethnicity, ')
          ..write('isPrivate: $isPrivate, ')
          ..write('privacyLevel: $privacyLevel, ')
          ..write('treeId: $treeId, ')
          ..write('uuid: $uuid, ')
          ..write('isDeleted: $isDeleted, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('mergedIntoId: $mergedIntoId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
    id,
    firstName,
    middleName,
    lastName,
    birthSurname,
    marriedSurname,
    suffix,
    prefix,
    nickname,
    displayNameFormat,
    customDisplayName,
    gender,
    birthDate,
    birthDateQualifier,
    birthPlace,
    birthPlaceLat,
    birthPlaceLng,
    deathDate,
    deathDateQualifier,
    deathPlace,
    deathPlaceLat,
    deathPlaceLng,
    currentPlace,
    isLiving,
    profilePhotoPath,
    biography,
    notes,
    occupation,
    religion,
    ethnicity,
    isPrivate,
    privacyLevel,
    treeId,
    uuid,
    isDeleted,
    createdAt,
    updatedAt,
    mergedIntoId,
  ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is GenealogyPerson &&
          other.id == this.id &&
          other.firstName == this.firstName &&
          other.middleName == this.middleName &&
          other.lastName == this.lastName &&
          other.birthSurname == this.birthSurname &&
          other.marriedSurname == this.marriedSurname &&
          other.suffix == this.suffix &&
          other.prefix == this.prefix &&
          other.nickname == this.nickname &&
          other.displayNameFormat == this.displayNameFormat &&
          other.customDisplayName == this.customDisplayName &&
          other.gender == this.gender &&
          other.birthDate == this.birthDate &&
          other.birthDateQualifier == this.birthDateQualifier &&
          other.birthPlace == this.birthPlace &&
          other.birthPlaceLat == this.birthPlaceLat &&
          other.birthPlaceLng == this.birthPlaceLng &&
          other.deathDate == this.deathDate &&
          other.deathDateQualifier == this.deathDateQualifier &&
          other.deathPlace == this.deathPlace &&
          other.deathPlaceLat == this.deathPlaceLat &&
          other.deathPlaceLng == this.deathPlaceLng &&
          other.currentPlace == this.currentPlace &&
          other.isLiving == this.isLiving &&
          other.profilePhotoPath == this.profilePhotoPath &&
          other.biography == this.biography &&
          other.notes == this.notes &&
          other.occupation == this.occupation &&
          other.religion == this.religion &&
          other.ethnicity == this.ethnicity &&
          other.isPrivate == this.isPrivate &&
          other.privacyLevel == this.privacyLevel &&
          other.treeId == this.treeId &&
          other.uuid == this.uuid &&
          other.isDeleted == this.isDeleted &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.mergedIntoId == this.mergedIntoId);
}

class GenealogyPersonsCompanion extends UpdateCompanion<GenealogyPerson> {
  final Value<String> id;
  final Value<String> firstName;
  final Value<String?> middleName;
  final Value<String?> lastName;
  final Value<String?> birthSurname;
  final Value<String?> marriedSurname;
  final Value<String?> suffix;
  final Value<String?> prefix;
  final Value<String?> nickname;
  final Value<String> displayNameFormat;
  final Value<String?> customDisplayName;
  final Value<String> gender;
  final Value<DateTime?> birthDate;
  final Value<String?> birthDateQualifier;
  final Value<String?> birthPlace;
  final Value<double?> birthPlaceLat;
  final Value<double?> birthPlaceLng;
  final Value<DateTime?> deathDate;
  final Value<String?> deathDateQualifier;
  final Value<String?> deathPlace;
  final Value<double?> deathPlaceLat;
  final Value<double?> deathPlaceLng;
  final Value<String?> currentPlace;
  final Value<bool> isLiving;
  final Value<String?> profilePhotoPath;
  final Value<String?> biography;
  final Value<String?> notes;
  final Value<String?> occupation;
  final Value<String?> religion;
  final Value<String?> ethnicity;
  final Value<bool> isPrivate;
  final Value<int> privacyLevel;
  final Value<String> treeId;
  final Value<String> uuid;
  final Value<bool> isDeleted;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<String?> mergedIntoId;
  final Value<int> rowid;
  const GenealogyPersonsCompanion({
    this.id = const Value.absent(),
    this.firstName = const Value.absent(),
    this.middleName = const Value.absent(),
    this.lastName = const Value.absent(),
    this.birthSurname = const Value.absent(),
    this.marriedSurname = const Value.absent(),
    this.suffix = const Value.absent(),
    this.prefix = const Value.absent(),
    this.nickname = const Value.absent(),
    this.displayNameFormat = const Value.absent(),
    this.customDisplayName = const Value.absent(),
    this.gender = const Value.absent(),
    this.birthDate = const Value.absent(),
    this.birthDateQualifier = const Value.absent(),
    this.birthPlace = const Value.absent(),
    this.birthPlaceLat = const Value.absent(),
    this.birthPlaceLng = const Value.absent(),
    this.deathDate = const Value.absent(),
    this.deathDateQualifier = const Value.absent(),
    this.deathPlace = const Value.absent(),
    this.deathPlaceLat = const Value.absent(),
    this.deathPlaceLng = const Value.absent(),
    this.currentPlace = const Value.absent(),
    this.isLiving = const Value.absent(),
    this.profilePhotoPath = const Value.absent(),
    this.biography = const Value.absent(),
    this.notes = const Value.absent(),
    this.occupation = const Value.absent(),
    this.religion = const Value.absent(),
    this.ethnicity = const Value.absent(),
    this.isPrivate = const Value.absent(),
    this.privacyLevel = const Value.absent(),
    this.treeId = const Value.absent(),
    this.uuid = const Value.absent(),
    this.isDeleted = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.mergedIntoId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  GenealogyPersonsCompanion.insert({
    required String id,
    required String firstName,
    this.middleName = const Value.absent(),
    this.lastName = const Value.absent(),
    this.birthSurname = const Value.absent(),
    this.marriedSurname = const Value.absent(),
    this.suffix = const Value.absent(),
    this.prefix = const Value.absent(),
    this.nickname = const Value.absent(),
    this.displayNameFormat = const Value.absent(),
    this.customDisplayName = const Value.absent(),
    required String gender,
    this.birthDate = const Value.absent(),
    this.birthDateQualifier = const Value.absent(),
    this.birthPlace = const Value.absent(),
    this.birthPlaceLat = const Value.absent(),
    this.birthPlaceLng = const Value.absent(),
    this.deathDate = const Value.absent(),
    this.deathDateQualifier = const Value.absent(),
    this.deathPlace = const Value.absent(),
    this.deathPlaceLat = const Value.absent(),
    this.deathPlaceLng = const Value.absent(),
    this.currentPlace = const Value.absent(),
    this.isLiving = const Value.absent(),
    this.profilePhotoPath = const Value.absent(),
    this.biography = const Value.absent(),
    this.notes = const Value.absent(),
    this.occupation = const Value.absent(),
    this.religion = const Value.absent(),
    this.ethnicity = const Value.absent(),
    this.isPrivate = const Value.absent(),
    this.privacyLevel = const Value.absent(),
    required String treeId,
    required String uuid,
    this.isDeleted = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.mergedIntoId = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       firstName = Value(firstName),
       gender = Value(gender),
       treeId = Value(treeId),
       uuid = Value(uuid);
  static Insertable<GenealogyPerson> custom({
    Expression<String>? id,
    Expression<String>? firstName,
    Expression<String>? middleName,
    Expression<String>? lastName,
    Expression<String>? birthSurname,
    Expression<String>? marriedSurname,
    Expression<String>? suffix,
    Expression<String>? prefix,
    Expression<String>? nickname,
    Expression<String>? displayNameFormat,
    Expression<String>? customDisplayName,
    Expression<String>? gender,
    Expression<DateTime>? birthDate,
    Expression<String>? birthDateQualifier,
    Expression<String>? birthPlace,
    Expression<double>? birthPlaceLat,
    Expression<double>? birthPlaceLng,
    Expression<DateTime>? deathDate,
    Expression<String>? deathDateQualifier,
    Expression<String>? deathPlace,
    Expression<double>? deathPlaceLat,
    Expression<double>? deathPlaceLng,
    Expression<String>? currentPlace,
    Expression<bool>? isLiving,
    Expression<String>? profilePhotoPath,
    Expression<String>? biography,
    Expression<String>? notes,
    Expression<String>? occupation,
    Expression<String>? religion,
    Expression<String>? ethnicity,
    Expression<bool>? isPrivate,
    Expression<int>? privacyLevel,
    Expression<String>? treeId,
    Expression<String>? uuid,
    Expression<bool>? isDeleted,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<String>? mergedIntoId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (firstName != null) 'first_name': firstName,
      if (middleName != null) 'middle_name': middleName,
      if (lastName != null) 'last_name': lastName,
      if (birthSurname != null) 'birth_surname': birthSurname,
      if (marriedSurname != null) 'married_surname': marriedSurname,
      if (suffix != null) 'suffix': suffix,
      if (prefix != null) 'prefix': prefix,
      if (nickname != null) 'nickname': nickname,
      if (displayNameFormat != null) 'display_name_format': displayNameFormat,
      if (customDisplayName != null) 'custom_display_name': customDisplayName,
      if (gender != null) 'gender': gender,
      if (birthDate != null) 'birth_date': birthDate,
      if (birthDateQualifier != null)
        'birth_date_qualifier': birthDateQualifier,
      if (birthPlace != null) 'birth_place': birthPlace,
      if (birthPlaceLat != null) 'birth_place_lat': birthPlaceLat,
      if (birthPlaceLng != null) 'birth_place_lng': birthPlaceLng,
      if (deathDate != null) 'death_date': deathDate,
      if (deathDateQualifier != null)
        'death_date_qualifier': deathDateQualifier,
      if (deathPlace != null) 'death_place': deathPlace,
      if (deathPlaceLat != null) 'death_place_lat': deathPlaceLat,
      if (deathPlaceLng != null) 'death_place_lng': deathPlaceLng,
      if (currentPlace != null) 'current_place': currentPlace,
      if (isLiving != null) 'is_living': isLiving,
      if (profilePhotoPath != null) 'profile_photo_path': profilePhotoPath,
      if (biography != null) 'biography': biography,
      if (notes != null) 'notes': notes,
      if (occupation != null) 'occupation': occupation,
      if (religion != null) 'religion': religion,
      if (ethnicity != null) 'ethnicity': ethnicity,
      if (isPrivate != null) 'is_private': isPrivate,
      if (privacyLevel != null) 'privacy_level': privacyLevel,
      if (treeId != null) 'tree_id': treeId,
      if (uuid != null) 'uuid': uuid,
      if (isDeleted != null) 'is_deleted': isDeleted,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (mergedIntoId != null) 'merged_into_id': mergedIntoId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  GenealogyPersonsCompanion copyWith({
    Value<String>? id,
    Value<String>? firstName,
    Value<String?>? middleName,
    Value<String?>? lastName,
    Value<String?>? birthSurname,
    Value<String?>? marriedSurname,
    Value<String?>? suffix,
    Value<String?>? prefix,
    Value<String?>? nickname,
    Value<String>? displayNameFormat,
    Value<String?>? customDisplayName,
    Value<String>? gender,
    Value<DateTime?>? birthDate,
    Value<String?>? birthDateQualifier,
    Value<String?>? birthPlace,
    Value<double?>? birthPlaceLat,
    Value<double?>? birthPlaceLng,
    Value<DateTime?>? deathDate,
    Value<String?>? deathDateQualifier,
    Value<String?>? deathPlace,
    Value<double?>? deathPlaceLat,
    Value<double?>? deathPlaceLng,
    Value<String?>? currentPlace,
    Value<bool>? isLiving,
    Value<String?>? profilePhotoPath,
    Value<String?>? biography,
    Value<String?>? notes,
    Value<String?>? occupation,
    Value<String?>? religion,
    Value<String?>? ethnicity,
    Value<bool>? isPrivate,
    Value<int>? privacyLevel,
    Value<String>? treeId,
    Value<String>? uuid,
    Value<bool>? isDeleted,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<String?>? mergedIntoId,
    Value<int>? rowid,
  }) {
    return GenealogyPersonsCompanion(
      id: id ?? this.id,
      firstName: firstName ?? this.firstName,
      middleName: middleName ?? this.middleName,
      lastName: lastName ?? this.lastName,
      birthSurname: birthSurname ?? this.birthSurname,
      marriedSurname: marriedSurname ?? this.marriedSurname,
      suffix: suffix ?? this.suffix,
      prefix: prefix ?? this.prefix,
      nickname: nickname ?? this.nickname,
      displayNameFormat: displayNameFormat ?? this.displayNameFormat,
      customDisplayName: customDisplayName ?? this.customDisplayName,
      gender: gender ?? this.gender,
      birthDate: birthDate ?? this.birthDate,
      birthDateQualifier: birthDateQualifier ?? this.birthDateQualifier,
      birthPlace: birthPlace ?? this.birthPlace,
      birthPlaceLat: birthPlaceLat ?? this.birthPlaceLat,
      birthPlaceLng: birthPlaceLng ?? this.birthPlaceLng,
      deathDate: deathDate ?? this.deathDate,
      deathDateQualifier: deathDateQualifier ?? this.deathDateQualifier,
      deathPlace: deathPlace ?? this.deathPlace,
      deathPlaceLat: deathPlaceLat ?? this.deathPlaceLat,
      deathPlaceLng: deathPlaceLng ?? this.deathPlaceLng,
      currentPlace: currentPlace ?? this.currentPlace,
      isLiving: isLiving ?? this.isLiving,
      profilePhotoPath: profilePhotoPath ?? this.profilePhotoPath,
      biography: biography ?? this.biography,
      notes: notes ?? this.notes,
      occupation: occupation ?? this.occupation,
      religion: religion ?? this.religion,
      ethnicity: ethnicity ?? this.ethnicity,
      isPrivate: isPrivate ?? this.isPrivate,
      privacyLevel: privacyLevel ?? this.privacyLevel,
      treeId: treeId ?? this.treeId,
      uuid: uuid ?? this.uuid,
      isDeleted: isDeleted ?? this.isDeleted,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      mergedIntoId: mergedIntoId ?? this.mergedIntoId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (firstName.present) {
      map['first_name'] = Variable<String>(firstName.value);
    }
    if (middleName.present) {
      map['middle_name'] = Variable<String>(middleName.value);
    }
    if (lastName.present) {
      map['last_name'] = Variable<String>(lastName.value);
    }
    if (birthSurname.present) {
      map['birth_surname'] = Variable<String>(birthSurname.value);
    }
    if (marriedSurname.present) {
      map['married_surname'] = Variable<String>(marriedSurname.value);
    }
    if (suffix.present) {
      map['suffix'] = Variable<String>(suffix.value);
    }
    if (prefix.present) {
      map['prefix'] = Variable<String>(prefix.value);
    }
    if (nickname.present) {
      map['nickname'] = Variable<String>(nickname.value);
    }
    if (displayNameFormat.present) {
      map['display_name_format'] = Variable<String>(displayNameFormat.value);
    }
    if (customDisplayName.present) {
      map['custom_display_name'] = Variable<String>(customDisplayName.value);
    }
    if (gender.present) {
      map['gender'] = Variable<String>(gender.value);
    }
    if (birthDate.present) {
      map['birth_date'] = Variable<DateTime>(birthDate.value);
    }
    if (birthDateQualifier.present) {
      map['birth_date_qualifier'] = Variable<String>(birthDateQualifier.value);
    }
    if (birthPlace.present) {
      map['birth_place'] = Variable<String>(birthPlace.value);
    }
    if (birthPlaceLat.present) {
      map['birth_place_lat'] = Variable<double>(birthPlaceLat.value);
    }
    if (birthPlaceLng.present) {
      map['birth_place_lng'] = Variable<double>(birthPlaceLng.value);
    }
    if (deathDate.present) {
      map['death_date'] = Variable<DateTime>(deathDate.value);
    }
    if (deathDateQualifier.present) {
      map['death_date_qualifier'] = Variable<String>(deathDateQualifier.value);
    }
    if (deathPlace.present) {
      map['death_place'] = Variable<String>(deathPlace.value);
    }
    if (deathPlaceLat.present) {
      map['death_place_lat'] = Variable<double>(deathPlaceLat.value);
    }
    if (deathPlaceLng.present) {
      map['death_place_lng'] = Variable<double>(deathPlaceLng.value);
    }
    if (currentPlace.present) {
      map['current_place'] = Variable<String>(currentPlace.value);
    }
    if (isLiving.present) {
      map['is_living'] = Variable<bool>(isLiving.value);
    }
    if (profilePhotoPath.present) {
      map['profile_photo_path'] = Variable<String>(profilePhotoPath.value);
    }
    if (biography.present) {
      map['biography'] = Variable<String>(biography.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (occupation.present) {
      map['occupation'] = Variable<String>(occupation.value);
    }
    if (religion.present) {
      map['religion'] = Variable<String>(religion.value);
    }
    if (ethnicity.present) {
      map['ethnicity'] = Variable<String>(ethnicity.value);
    }
    if (isPrivate.present) {
      map['is_private'] = Variable<bool>(isPrivate.value);
    }
    if (privacyLevel.present) {
      map['privacy_level'] = Variable<int>(privacyLevel.value);
    }
    if (treeId.present) {
      map['tree_id'] = Variable<String>(treeId.value);
    }
    if (uuid.present) {
      map['uuid'] = Variable<String>(uuid.value);
    }
    if (isDeleted.present) {
      map['is_deleted'] = Variable<bool>(isDeleted.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (mergedIntoId.present) {
      map['merged_into_id'] = Variable<String>(mergedIntoId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('GenealogyPersonsCompanion(')
          ..write('id: $id, ')
          ..write('firstName: $firstName, ')
          ..write('middleName: $middleName, ')
          ..write('lastName: $lastName, ')
          ..write('birthSurname: $birthSurname, ')
          ..write('marriedSurname: $marriedSurname, ')
          ..write('suffix: $suffix, ')
          ..write('prefix: $prefix, ')
          ..write('nickname: $nickname, ')
          ..write('displayNameFormat: $displayNameFormat, ')
          ..write('customDisplayName: $customDisplayName, ')
          ..write('gender: $gender, ')
          ..write('birthDate: $birthDate, ')
          ..write('birthDateQualifier: $birthDateQualifier, ')
          ..write('birthPlace: $birthPlace, ')
          ..write('birthPlaceLat: $birthPlaceLat, ')
          ..write('birthPlaceLng: $birthPlaceLng, ')
          ..write('deathDate: $deathDate, ')
          ..write('deathDateQualifier: $deathDateQualifier, ')
          ..write('deathPlace: $deathPlace, ')
          ..write('deathPlaceLat: $deathPlaceLat, ')
          ..write('deathPlaceLng: $deathPlaceLng, ')
          ..write('currentPlace: $currentPlace, ')
          ..write('isLiving: $isLiving, ')
          ..write('profilePhotoPath: $profilePhotoPath, ')
          ..write('biography: $biography, ')
          ..write('notes: $notes, ')
          ..write('occupation: $occupation, ')
          ..write('religion: $religion, ')
          ..write('ethnicity: $ethnicity, ')
          ..write('isPrivate: $isPrivate, ')
          ..write('privacyLevel: $privacyLevel, ')
          ..write('treeId: $treeId, ')
          ..write('uuid: $uuid, ')
          ..write('isDeleted: $isDeleted, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('mergedIntoId: $mergedIntoId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $FamilyTreesTable extends FamilyTrees
    with TableInfo<$FamilyTreesTable, FamilyTree> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FamilyTreesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _treeNameMeta = const VerificationMeta(
    'treeName',
  );
  @override
  late final GeneratedColumn<String> treeName = GeneratedColumn<String>(
    'tree_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _rootPersonIdMeta = const VerificationMeta(
    'rootPersonId',
  );
  @override
  late final GeneratedColumn<String> rootPersonId = GeneratedColumn<String>(
    'root_person_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES genealogy_persons (id) ON DELETE SET NULL',
    ),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    treeName,
    description,
    rootPersonId,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'family_trees';
  @override
  VerificationContext validateIntegrity(
    Insertable<FamilyTree> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('tree_name')) {
      context.handle(
        _treeNameMeta,
        treeName.isAcceptableOrUnknown(data['tree_name']!, _treeNameMeta),
      );
    } else if (isInserting) {
      context.missing(_treeNameMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    }
    if (data.containsKey('root_person_id')) {
      context.handle(
        _rootPersonIdMeta,
        rootPersonId.isAcceptableOrUnknown(
          data['root_person_id']!,
          _rootPersonIdMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  FamilyTree map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return FamilyTree(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      treeName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tree_name'],
      )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      ),
      rootPersonId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}root_person_id'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $FamilyTreesTable createAlias(String alias) {
    return $FamilyTreesTable(attachedDatabase, alias);
  }
}

class FamilyTree extends DataClass implements Insertable<FamilyTree> {
  final String id;
  final String treeName;
  final String? description;

  /// The person the tree is conceptually rooted at.
  ///
  /// Integrity checked and cleared on delete (`SET NULL`): if the person row is
  /// ever hard-deleted the root is emptied rather than left dangling.
  ///
  /// This reference points back at `genealogy_persons` from `family_trees`, the
  /// same pair of tables the mandatory ownership key on people points across. The
  /// two together form a cycle, and drift drops one reference when it sees a
  /// cycle — so the ownership key is declared as a raw table constraint instead
  /// (see `genealogy_persons_table.dart`). Both are enforced; neither is dropped.
  final String? rootPersonId;
  final DateTime createdAt;
  final DateTime updatedAt;
  const FamilyTree({
    required this.id,
    required this.treeName,
    this.description,
    this.rootPersonId,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['tree_name'] = Variable<String>(treeName);
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    if (!nullToAbsent || rootPersonId != null) {
      map['root_person_id'] = Variable<String>(rootPersonId);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  FamilyTreesCompanion toCompanion(bool nullToAbsent) {
    return FamilyTreesCompanion(
      id: Value(id),
      treeName: Value(treeName),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      rootPersonId: rootPersonId == null && nullToAbsent
          ? const Value.absent()
          : Value(rootPersonId),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory FamilyTree.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return FamilyTree(
      id: serializer.fromJson<String>(json['id']),
      treeName: serializer.fromJson<String>(json['treeName']),
      description: serializer.fromJson<String?>(json['description']),
      rootPersonId: serializer.fromJson<String?>(json['rootPersonId']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'treeName': serializer.toJson<String>(treeName),
      'description': serializer.toJson<String?>(description),
      'rootPersonId': serializer.toJson<String?>(rootPersonId),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  FamilyTree copyWith({
    String? id,
    String? treeName,
    Value<String?> description = const Value.absent(),
    Value<String?> rootPersonId = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => FamilyTree(
    id: id ?? this.id,
    treeName: treeName ?? this.treeName,
    description: description.present ? description.value : this.description,
    rootPersonId: rootPersonId.present ? rootPersonId.value : this.rootPersonId,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  FamilyTree copyWithCompanion(FamilyTreesCompanion data) {
    return FamilyTree(
      id: data.id.present ? data.id.value : this.id,
      treeName: data.treeName.present ? data.treeName.value : this.treeName,
      description: data.description.present
          ? data.description.value
          : this.description,
      rootPersonId: data.rootPersonId.present
          ? data.rootPersonId.value
          : this.rootPersonId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('FamilyTree(')
          ..write('id: $id, ')
          ..write('treeName: $treeName, ')
          ..write('description: $description, ')
          ..write('rootPersonId: $rootPersonId, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    treeName,
    description,
    rootPersonId,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FamilyTree &&
          other.id == this.id &&
          other.treeName == this.treeName &&
          other.description == this.description &&
          other.rootPersonId == this.rootPersonId &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class FamilyTreesCompanion extends UpdateCompanion<FamilyTree> {
  final Value<String> id;
  final Value<String> treeName;
  final Value<String?> description;
  final Value<String?> rootPersonId;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const FamilyTreesCompanion({
    this.id = const Value.absent(),
    this.treeName = const Value.absent(),
    this.description = const Value.absent(),
    this.rootPersonId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  FamilyTreesCompanion.insert({
    required String id,
    required String treeName,
    this.description = const Value.absent(),
    this.rootPersonId = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       treeName = Value(treeName),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<FamilyTree> custom({
    Expression<String>? id,
    Expression<String>? treeName,
    Expression<String>? description,
    Expression<String>? rootPersonId,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (treeName != null) 'tree_name': treeName,
      if (description != null) 'description': description,
      if (rootPersonId != null) 'root_person_id': rootPersonId,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  FamilyTreesCompanion copyWith({
    Value<String>? id,
    Value<String>? treeName,
    Value<String?>? description,
    Value<String?>? rootPersonId,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return FamilyTreesCompanion(
      id: id ?? this.id,
      treeName: treeName ?? this.treeName,
      description: description ?? this.description,
      rootPersonId: rootPersonId ?? this.rootPersonId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (treeName.present) {
      map['tree_name'] = Variable<String>(treeName.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (rootPersonId.present) {
      map['root_person_id'] = Variable<String>(rootPersonId.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FamilyTreesCompanion(')
          ..write('id: $id, ')
          ..write('treeName: $treeName, ')
          ..write('description: $description, ')
          ..write('rootPersonId: $rootPersonId, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $EventsTable extends Events with TableInfo<$EventsTable, Event> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $EventsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _personIdMeta = const VerificationMeta(
    'personId',
  );
  @override
  late final GeneratedColumn<String> personId = GeneratedColumn<String>(
    'person_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES genealogy_persons (id) ON DELETE RESTRICT',
    ),
  );
  static const VerificationMeta _eventTypeMeta = const VerificationMeta(
    'eventType',
  );
  @override
  late final GeneratedColumn<String> eventType = GeneratedColumn<String>(
    'event_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dateSortMeta = const VerificationMeta(
    'dateSort',
  );
  @override
  late final GeneratedColumn<double> dateSort = GeneratedColumn<double>(
    'date_sort',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _dateDisplayMeta = const VerificationMeta(
    'dateDisplay',
  );
  @override
  late final GeneratedColumn<String> dateDisplay = GeneratedColumn<String>(
    'date_display',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _placeMeta = const VerificationMeta('place');
  @override
  late final GeneratedColumn<String> place = GeneratedColumn<String>(
    'place',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isPrimaryMeta = const VerificationMeta(
    'isPrimary',
  );
  @override
  late final GeneratedColumn<bool> isPrimary = GeneratedColumn<bool>(
    'is_primary',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_primary" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _latitudeMeta = const VerificationMeta(
    'latitude',
  );
  @override
  late final GeneratedColumn<double> latitude = GeneratedColumn<double>(
    'latitude',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _longitudeMeta = const VerificationMeta(
    'longitude',
  );
  @override
  late final GeneratedColumn<double> longitude = GeneratedColumn<double>(
    'longitude',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    personId,
    eventType,
    dateSort,
    dateDisplay,
    place,
    description,
    isPrimary,
    latitude,
    longitude,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'events';
  @override
  VerificationContext validateIntegrity(
    Insertable<Event> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('person_id')) {
      context.handle(
        _personIdMeta,
        personId.isAcceptableOrUnknown(data['person_id']!, _personIdMeta),
      );
    } else if (isInserting) {
      context.missing(_personIdMeta);
    }
    if (data.containsKey('event_type')) {
      context.handle(
        _eventTypeMeta,
        eventType.isAcceptableOrUnknown(data['event_type']!, _eventTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_eventTypeMeta);
    }
    if (data.containsKey('date_sort')) {
      context.handle(
        _dateSortMeta,
        dateSort.isAcceptableOrUnknown(data['date_sort']!, _dateSortMeta),
      );
    }
    if (data.containsKey('date_display')) {
      context.handle(
        _dateDisplayMeta,
        dateDisplay.isAcceptableOrUnknown(
          data['date_display']!,
          _dateDisplayMeta,
        ),
      );
    }
    if (data.containsKey('place')) {
      context.handle(
        _placeMeta,
        place.isAcceptableOrUnknown(data['place']!, _placeMeta),
      );
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    }
    if (data.containsKey('is_primary')) {
      context.handle(
        _isPrimaryMeta,
        isPrimary.isAcceptableOrUnknown(data['is_primary']!, _isPrimaryMeta),
      );
    }
    if (data.containsKey('latitude')) {
      context.handle(
        _latitudeMeta,
        latitude.isAcceptableOrUnknown(data['latitude']!, _latitudeMeta),
      );
    }
    if (data.containsKey('longitude')) {
      context.handle(
        _longitudeMeta,
        longitude.isAcceptableOrUnknown(data['longitude']!, _longitudeMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Event map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Event(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      personId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}person_id'],
      )!,
      eventType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}event_type'],
      )!,
      dateSort: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}date_sort'],
      ),
      dateDisplay: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}date_display'],
      ),
      place: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}place'],
      ),
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      ),
      isPrimary: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_primary'],
      )!,
      latitude: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}latitude'],
      ),
      longitude: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}longitude'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $EventsTable createAlias(String alias) {
    return $EventsTable(attachedDatabase, alias);
  }
}

class Event extends DataClass implements Insertable<Event> {
  final String id;
  final String personId;
  final String eventType;
  final double? dateSort;
  final String? dateDisplay;
  final String? place;
  final String? description;
  final bool isPrimary;
  final double? latitude;
  final double? longitude;
  final DateTime createdAt;
  final DateTime updatedAt;
  const Event({
    required this.id,
    required this.personId,
    required this.eventType,
    this.dateSort,
    this.dateDisplay,
    this.place,
    this.description,
    required this.isPrimary,
    this.latitude,
    this.longitude,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['person_id'] = Variable<String>(personId);
    map['event_type'] = Variable<String>(eventType);
    if (!nullToAbsent || dateSort != null) {
      map['date_sort'] = Variable<double>(dateSort);
    }
    if (!nullToAbsent || dateDisplay != null) {
      map['date_display'] = Variable<String>(dateDisplay);
    }
    if (!nullToAbsent || place != null) {
      map['place'] = Variable<String>(place);
    }
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    map['is_primary'] = Variable<bool>(isPrimary);
    if (!nullToAbsent || latitude != null) {
      map['latitude'] = Variable<double>(latitude);
    }
    if (!nullToAbsent || longitude != null) {
      map['longitude'] = Variable<double>(longitude);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  EventsCompanion toCompanion(bool nullToAbsent) {
    return EventsCompanion(
      id: Value(id),
      personId: Value(personId),
      eventType: Value(eventType),
      dateSort: dateSort == null && nullToAbsent
          ? const Value.absent()
          : Value(dateSort),
      dateDisplay: dateDisplay == null && nullToAbsent
          ? const Value.absent()
          : Value(dateDisplay),
      place: place == null && nullToAbsent
          ? const Value.absent()
          : Value(place),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      isPrimary: Value(isPrimary),
      latitude: latitude == null && nullToAbsent
          ? const Value.absent()
          : Value(latitude),
      longitude: longitude == null && nullToAbsent
          ? const Value.absent()
          : Value(longitude),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory Event.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Event(
      id: serializer.fromJson<String>(json['id']),
      personId: serializer.fromJson<String>(json['personId']),
      eventType: serializer.fromJson<String>(json['eventType']),
      dateSort: serializer.fromJson<double?>(json['dateSort']),
      dateDisplay: serializer.fromJson<String?>(json['dateDisplay']),
      place: serializer.fromJson<String?>(json['place']),
      description: serializer.fromJson<String?>(json['description']),
      isPrimary: serializer.fromJson<bool>(json['isPrimary']),
      latitude: serializer.fromJson<double?>(json['latitude']),
      longitude: serializer.fromJson<double?>(json['longitude']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'personId': serializer.toJson<String>(personId),
      'eventType': serializer.toJson<String>(eventType),
      'dateSort': serializer.toJson<double?>(dateSort),
      'dateDisplay': serializer.toJson<String?>(dateDisplay),
      'place': serializer.toJson<String?>(place),
      'description': serializer.toJson<String?>(description),
      'isPrimary': serializer.toJson<bool>(isPrimary),
      'latitude': serializer.toJson<double?>(latitude),
      'longitude': serializer.toJson<double?>(longitude),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  Event copyWith({
    String? id,
    String? personId,
    String? eventType,
    Value<double?> dateSort = const Value.absent(),
    Value<String?> dateDisplay = const Value.absent(),
    Value<String?> place = const Value.absent(),
    Value<String?> description = const Value.absent(),
    bool? isPrimary,
    Value<double?> latitude = const Value.absent(),
    Value<double?> longitude = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => Event(
    id: id ?? this.id,
    personId: personId ?? this.personId,
    eventType: eventType ?? this.eventType,
    dateSort: dateSort.present ? dateSort.value : this.dateSort,
    dateDisplay: dateDisplay.present ? dateDisplay.value : this.dateDisplay,
    place: place.present ? place.value : this.place,
    description: description.present ? description.value : this.description,
    isPrimary: isPrimary ?? this.isPrimary,
    latitude: latitude.present ? latitude.value : this.latitude,
    longitude: longitude.present ? longitude.value : this.longitude,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  Event copyWithCompanion(EventsCompanion data) {
    return Event(
      id: data.id.present ? data.id.value : this.id,
      personId: data.personId.present ? data.personId.value : this.personId,
      eventType: data.eventType.present ? data.eventType.value : this.eventType,
      dateSort: data.dateSort.present ? data.dateSort.value : this.dateSort,
      dateDisplay: data.dateDisplay.present
          ? data.dateDisplay.value
          : this.dateDisplay,
      place: data.place.present ? data.place.value : this.place,
      description: data.description.present
          ? data.description.value
          : this.description,
      isPrimary: data.isPrimary.present ? data.isPrimary.value : this.isPrimary,
      latitude: data.latitude.present ? data.latitude.value : this.latitude,
      longitude: data.longitude.present ? data.longitude.value : this.longitude,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Event(')
          ..write('id: $id, ')
          ..write('personId: $personId, ')
          ..write('eventType: $eventType, ')
          ..write('dateSort: $dateSort, ')
          ..write('dateDisplay: $dateDisplay, ')
          ..write('place: $place, ')
          ..write('description: $description, ')
          ..write('isPrimary: $isPrimary, ')
          ..write('latitude: $latitude, ')
          ..write('longitude: $longitude, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    personId,
    eventType,
    dateSort,
    dateDisplay,
    place,
    description,
    isPrimary,
    latitude,
    longitude,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Event &&
          other.id == this.id &&
          other.personId == this.personId &&
          other.eventType == this.eventType &&
          other.dateSort == this.dateSort &&
          other.dateDisplay == this.dateDisplay &&
          other.place == this.place &&
          other.description == this.description &&
          other.isPrimary == this.isPrimary &&
          other.latitude == this.latitude &&
          other.longitude == this.longitude &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class EventsCompanion extends UpdateCompanion<Event> {
  final Value<String> id;
  final Value<String> personId;
  final Value<String> eventType;
  final Value<double?> dateSort;
  final Value<String?> dateDisplay;
  final Value<String?> place;
  final Value<String?> description;
  final Value<bool> isPrimary;
  final Value<double?> latitude;
  final Value<double?> longitude;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const EventsCompanion({
    this.id = const Value.absent(),
    this.personId = const Value.absent(),
    this.eventType = const Value.absent(),
    this.dateSort = const Value.absent(),
    this.dateDisplay = const Value.absent(),
    this.place = const Value.absent(),
    this.description = const Value.absent(),
    this.isPrimary = const Value.absent(),
    this.latitude = const Value.absent(),
    this.longitude = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  EventsCompanion.insert({
    required String id,
    required String personId,
    required String eventType,
    this.dateSort = const Value.absent(),
    this.dateDisplay = const Value.absent(),
    this.place = const Value.absent(),
    this.description = const Value.absent(),
    this.isPrimary = const Value.absent(),
    this.latitude = const Value.absent(),
    this.longitude = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       personId = Value(personId),
       eventType = Value(eventType),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<Event> custom({
    Expression<String>? id,
    Expression<String>? personId,
    Expression<String>? eventType,
    Expression<double>? dateSort,
    Expression<String>? dateDisplay,
    Expression<String>? place,
    Expression<String>? description,
    Expression<bool>? isPrimary,
    Expression<double>? latitude,
    Expression<double>? longitude,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (personId != null) 'person_id': personId,
      if (eventType != null) 'event_type': eventType,
      if (dateSort != null) 'date_sort': dateSort,
      if (dateDisplay != null) 'date_display': dateDisplay,
      if (place != null) 'place': place,
      if (description != null) 'description': description,
      if (isPrimary != null) 'is_primary': isPrimary,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  EventsCompanion copyWith({
    Value<String>? id,
    Value<String>? personId,
    Value<String>? eventType,
    Value<double?>? dateSort,
    Value<String?>? dateDisplay,
    Value<String?>? place,
    Value<String?>? description,
    Value<bool>? isPrimary,
    Value<double?>? latitude,
    Value<double?>? longitude,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return EventsCompanion(
      id: id ?? this.id,
      personId: personId ?? this.personId,
      eventType: eventType ?? this.eventType,
      dateSort: dateSort ?? this.dateSort,
      dateDisplay: dateDisplay ?? this.dateDisplay,
      place: place ?? this.place,
      description: description ?? this.description,
      isPrimary: isPrimary ?? this.isPrimary,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (personId.present) {
      map['person_id'] = Variable<String>(personId.value);
    }
    if (eventType.present) {
      map['event_type'] = Variable<String>(eventType.value);
    }
    if (dateSort.present) {
      map['date_sort'] = Variable<double>(dateSort.value);
    }
    if (dateDisplay.present) {
      map['date_display'] = Variable<String>(dateDisplay.value);
    }
    if (place.present) {
      map['place'] = Variable<String>(place.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (isPrimary.present) {
      map['is_primary'] = Variable<bool>(isPrimary.value);
    }
    if (latitude.present) {
      map['latitude'] = Variable<double>(latitude.value);
    }
    if (longitude.present) {
      map['longitude'] = Variable<double>(longitude.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('EventsCompanion(')
          ..write('id: $id, ')
          ..write('personId: $personId, ')
          ..write('eventType: $eventType, ')
          ..write('dateSort: $dateSort, ')
          ..write('dateDisplay: $dateDisplay, ')
          ..write('place: $place, ')
          ..write('description: $description, ')
          ..write('isPrimary: $isPrimary, ')
          ..write('latitude: $latitude, ')
          ..write('longitude: $longitude, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SurnameEventsTable extends SurnameEvents
    with TableInfo<$SurnameEventsTable, SurnameEvent> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SurnameEventsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _personIdMeta = const VerificationMeta(
    'personId',
  );
  @override
  late final GeneratedColumn<String> personId = GeneratedColumn<String>(
    'person_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES genealogy_persons (id) ON DELETE RESTRICT',
    ),
  );
  static const VerificationMeta _surnameMeta = const VerificationMeta(
    'surname',
  );
  @override
  late final GeneratedColumn<String> surname = GeneratedColumn<String>(
    'surname',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _surnameTypeMeta = const VerificationMeta(
    'surnameType',
  );
  @override
  late final GeneratedColumn<String> surnameType = GeneratedColumn<String>(
    'surname_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _startDateMeta = const VerificationMeta(
    'startDate',
  );
  @override
  late final GeneratedColumn<String> startDate = GeneratedColumn<String>(
    'start_date',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _startDateQualifierMeta =
      const VerificationMeta('startDateQualifier');
  @override
  late final GeneratedColumn<String> startDateQualifier =
      GeneratedColumn<String>(
        'start_date_qualifier',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _endDateMeta = const VerificationMeta(
    'endDate',
  );
  @override
  late final GeneratedColumn<String> endDate = GeneratedColumn<String>(
    'end_date',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _endDateQualifierMeta = const VerificationMeta(
    'endDateQualifier',
  );
  @override
  late final GeneratedColumn<String> endDateQualifier = GeneratedColumn<String>(
    'end_date_qualifier',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _relatedPersonIdMeta = const VerificationMeta(
    'relatedPersonId',
  );
  @override
  late final GeneratedColumn<String> relatedPersonId = GeneratedColumn<String>(
    'related_person_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES genealogy_persons (id) ON DELETE SET NULL',
    ),
  );
  static const VerificationMeta _relatedEventIdMeta = const VerificationMeta(
    'relatedEventId',
  );
  @override
  late final GeneratedColumn<String> relatedEventId = GeneratedColumn<String>(
    'related_event_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES events (id) ON DELETE SET NULL',
    ),
  );
  static const VerificationMeta _locationMeta = const VerificationMeta(
    'location',
  );
  @override
  late final GeneratedColumn<String> location = GeneratedColumn<String>(
    'location',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _legalDocumentMeta = const VerificationMeta(
    'legalDocument',
  );
  @override
  late final GeneratedColumn<String> legalDocument = GeneratedColumn<String>(
    'legal_document',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sortOrderMeta = const VerificationMeta(
    'sortOrder',
  );
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
    'sort_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _isPrimaryMeta = const VerificationMeta(
    'isPrimary',
  );
  @override
  late final GeneratedColumn<bool> isPrimary = GeneratedColumn<bool>(
    'is_primary',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_primary" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    personId,
    surname,
    surnameType,
    startDate,
    startDateQualifier,
    endDate,
    endDateQualifier,
    relatedPersonId,
    relatedEventId,
    location,
    legalDocument,
    notes,
    sortOrder,
    isPrimary,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'surname_events';
  @override
  VerificationContext validateIntegrity(
    Insertable<SurnameEvent> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('person_id')) {
      context.handle(
        _personIdMeta,
        personId.isAcceptableOrUnknown(data['person_id']!, _personIdMeta),
      );
    } else if (isInserting) {
      context.missing(_personIdMeta);
    }
    if (data.containsKey('surname')) {
      context.handle(
        _surnameMeta,
        surname.isAcceptableOrUnknown(data['surname']!, _surnameMeta),
      );
    } else if (isInserting) {
      context.missing(_surnameMeta);
    }
    if (data.containsKey('surname_type')) {
      context.handle(
        _surnameTypeMeta,
        surnameType.isAcceptableOrUnknown(
          data['surname_type']!,
          _surnameTypeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_surnameTypeMeta);
    }
    if (data.containsKey('start_date')) {
      context.handle(
        _startDateMeta,
        startDate.isAcceptableOrUnknown(data['start_date']!, _startDateMeta),
      );
    }
    if (data.containsKey('start_date_qualifier')) {
      context.handle(
        _startDateQualifierMeta,
        startDateQualifier.isAcceptableOrUnknown(
          data['start_date_qualifier']!,
          _startDateQualifierMeta,
        ),
      );
    }
    if (data.containsKey('end_date')) {
      context.handle(
        _endDateMeta,
        endDate.isAcceptableOrUnknown(data['end_date']!, _endDateMeta),
      );
    }
    if (data.containsKey('end_date_qualifier')) {
      context.handle(
        _endDateQualifierMeta,
        endDateQualifier.isAcceptableOrUnknown(
          data['end_date_qualifier']!,
          _endDateQualifierMeta,
        ),
      );
    }
    if (data.containsKey('related_person_id')) {
      context.handle(
        _relatedPersonIdMeta,
        relatedPersonId.isAcceptableOrUnknown(
          data['related_person_id']!,
          _relatedPersonIdMeta,
        ),
      );
    }
    if (data.containsKey('related_event_id')) {
      context.handle(
        _relatedEventIdMeta,
        relatedEventId.isAcceptableOrUnknown(
          data['related_event_id']!,
          _relatedEventIdMeta,
        ),
      );
    }
    if (data.containsKey('location')) {
      context.handle(
        _locationMeta,
        location.isAcceptableOrUnknown(data['location']!, _locationMeta),
      );
    }
    if (data.containsKey('legal_document')) {
      context.handle(
        _legalDocumentMeta,
        legalDocument.isAcceptableOrUnknown(
          data['legal_document']!,
          _legalDocumentMeta,
        ),
      );
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
    }
    if (data.containsKey('is_primary')) {
      context.handle(
        _isPrimaryMeta,
        isPrimary.isAcceptableOrUnknown(data['is_primary']!, _isPrimaryMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SurnameEvent map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SurnameEvent(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      personId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}person_id'],
      )!,
      surname: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}surname'],
      )!,
      surnameType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}surname_type'],
      )!,
      startDate: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}start_date'],
      ),
      startDateQualifier: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}start_date_qualifier'],
      ),
      endDate: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}end_date'],
      ),
      endDateQualifier: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}end_date_qualifier'],
      ),
      relatedPersonId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}related_person_id'],
      ),
      relatedEventId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}related_event_id'],
      ),
      location: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}location'],
      ),
      legalDocument: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}legal_document'],
      ),
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      )!,
      isPrimary: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_primary'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $SurnameEventsTable createAlias(String alias) {
    return $SurnameEventsTable(attachedDatabase, alias);
  }
}

class SurnameEvent extends DataClass implements Insertable<SurnameEvent> {
  final String id;
  final String personId;
  final String surname;
  final String surnameType;
  final String? startDate;
  final String? startDateQualifier;
  final String? endDate;
  final String? endDateQualifier;
  final String? relatedPersonId;
  final String? relatedEventId;
  final String? location;
  final String? legalDocument;
  final String? notes;
  final int sortOrder;
  final bool isPrimary;
  final DateTime createdAt;
  final DateTime updatedAt;
  const SurnameEvent({
    required this.id,
    required this.personId,
    required this.surname,
    required this.surnameType,
    this.startDate,
    this.startDateQualifier,
    this.endDate,
    this.endDateQualifier,
    this.relatedPersonId,
    this.relatedEventId,
    this.location,
    this.legalDocument,
    this.notes,
    required this.sortOrder,
    required this.isPrimary,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['person_id'] = Variable<String>(personId);
    map['surname'] = Variable<String>(surname);
    map['surname_type'] = Variable<String>(surnameType);
    if (!nullToAbsent || startDate != null) {
      map['start_date'] = Variable<String>(startDate);
    }
    if (!nullToAbsent || startDateQualifier != null) {
      map['start_date_qualifier'] = Variable<String>(startDateQualifier);
    }
    if (!nullToAbsent || endDate != null) {
      map['end_date'] = Variable<String>(endDate);
    }
    if (!nullToAbsent || endDateQualifier != null) {
      map['end_date_qualifier'] = Variable<String>(endDateQualifier);
    }
    if (!nullToAbsent || relatedPersonId != null) {
      map['related_person_id'] = Variable<String>(relatedPersonId);
    }
    if (!nullToAbsent || relatedEventId != null) {
      map['related_event_id'] = Variable<String>(relatedEventId);
    }
    if (!nullToAbsent || location != null) {
      map['location'] = Variable<String>(location);
    }
    if (!nullToAbsent || legalDocument != null) {
      map['legal_document'] = Variable<String>(legalDocument);
    }
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    map['sort_order'] = Variable<int>(sortOrder);
    map['is_primary'] = Variable<bool>(isPrimary);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  SurnameEventsCompanion toCompanion(bool nullToAbsent) {
    return SurnameEventsCompanion(
      id: Value(id),
      personId: Value(personId),
      surname: Value(surname),
      surnameType: Value(surnameType),
      startDate: startDate == null && nullToAbsent
          ? const Value.absent()
          : Value(startDate),
      startDateQualifier: startDateQualifier == null && nullToAbsent
          ? const Value.absent()
          : Value(startDateQualifier),
      endDate: endDate == null && nullToAbsent
          ? const Value.absent()
          : Value(endDate),
      endDateQualifier: endDateQualifier == null && nullToAbsent
          ? const Value.absent()
          : Value(endDateQualifier),
      relatedPersonId: relatedPersonId == null && nullToAbsent
          ? const Value.absent()
          : Value(relatedPersonId),
      relatedEventId: relatedEventId == null && nullToAbsent
          ? const Value.absent()
          : Value(relatedEventId),
      location: location == null && nullToAbsent
          ? const Value.absent()
          : Value(location),
      legalDocument: legalDocument == null && nullToAbsent
          ? const Value.absent()
          : Value(legalDocument),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
          : Value(notes),
      sortOrder: Value(sortOrder),
      isPrimary: Value(isPrimary),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory SurnameEvent.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SurnameEvent(
      id: serializer.fromJson<String>(json['id']),
      personId: serializer.fromJson<String>(json['personId']),
      surname: serializer.fromJson<String>(json['surname']),
      surnameType: serializer.fromJson<String>(json['surnameType']),
      startDate: serializer.fromJson<String?>(json['startDate']),
      startDateQualifier: serializer.fromJson<String?>(
        json['startDateQualifier'],
      ),
      endDate: serializer.fromJson<String?>(json['endDate']),
      endDateQualifier: serializer.fromJson<String?>(json['endDateQualifier']),
      relatedPersonId: serializer.fromJson<String?>(json['relatedPersonId']),
      relatedEventId: serializer.fromJson<String?>(json['relatedEventId']),
      location: serializer.fromJson<String?>(json['location']),
      legalDocument: serializer.fromJson<String?>(json['legalDocument']),
      notes: serializer.fromJson<String?>(json['notes']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
      isPrimary: serializer.fromJson<bool>(json['isPrimary']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'personId': serializer.toJson<String>(personId),
      'surname': serializer.toJson<String>(surname),
      'surnameType': serializer.toJson<String>(surnameType),
      'startDate': serializer.toJson<String?>(startDate),
      'startDateQualifier': serializer.toJson<String?>(startDateQualifier),
      'endDate': serializer.toJson<String?>(endDate),
      'endDateQualifier': serializer.toJson<String?>(endDateQualifier),
      'relatedPersonId': serializer.toJson<String?>(relatedPersonId),
      'relatedEventId': serializer.toJson<String?>(relatedEventId),
      'location': serializer.toJson<String?>(location),
      'legalDocument': serializer.toJson<String?>(legalDocument),
      'notes': serializer.toJson<String?>(notes),
      'sortOrder': serializer.toJson<int>(sortOrder),
      'isPrimary': serializer.toJson<bool>(isPrimary),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  SurnameEvent copyWith({
    String? id,
    String? personId,
    String? surname,
    String? surnameType,
    Value<String?> startDate = const Value.absent(),
    Value<String?> startDateQualifier = const Value.absent(),
    Value<String?> endDate = const Value.absent(),
    Value<String?> endDateQualifier = const Value.absent(),
    Value<String?> relatedPersonId = const Value.absent(),
    Value<String?> relatedEventId = const Value.absent(),
    Value<String?> location = const Value.absent(),
    Value<String?> legalDocument = const Value.absent(),
    Value<String?> notes = const Value.absent(),
    int? sortOrder,
    bool? isPrimary,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => SurnameEvent(
    id: id ?? this.id,
    personId: personId ?? this.personId,
    surname: surname ?? this.surname,
    surnameType: surnameType ?? this.surnameType,
    startDate: startDate.present ? startDate.value : this.startDate,
    startDateQualifier: startDateQualifier.present
        ? startDateQualifier.value
        : this.startDateQualifier,
    endDate: endDate.present ? endDate.value : this.endDate,
    endDateQualifier: endDateQualifier.present
        ? endDateQualifier.value
        : this.endDateQualifier,
    relatedPersonId: relatedPersonId.present
        ? relatedPersonId.value
        : this.relatedPersonId,
    relatedEventId: relatedEventId.present
        ? relatedEventId.value
        : this.relatedEventId,
    location: location.present ? location.value : this.location,
    legalDocument: legalDocument.present
        ? legalDocument.value
        : this.legalDocument,
    notes: notes.present ? notes.value : this.notes,
    sortOrder: sortOrder ?? this.sortOrder,
    isPrimary: isPrimary ?? this.isPrimary,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  SurnameEvent copyWithCompanion(SurnameEventsCompanion data) {
    return SurnameEvent(
      id: data.id.present ? data.id.value : this.id,
      personId: data.personId.present ? data.personId.value : this.personId,
      surname: data.surname.present ? data.surname.value : this.surname,
      surnameType: data.surnameType.present
          ? data.surnameType.value
          : this.surnameType,
      startDate: data.startDate.present ? data.startDate.value : this.startDate,
      startDateQualifier: data.startDateQualifier.present
          ? data.startDateQualifier.value
          : this.startDateQualifier,
      endDate: data.endDate.present ? data.endDate.value : this.endDate,
      endDateQualifier: data.endDateQualifier.present
          ? data.endDateQualifier.value
          : this.endDateQualifier,
      relatedPersonId: data.relatedPersonId.present
          ? data.relatedPersonId.value
          : this.relatedPersonId,
      relatedEventId: data.relatedEventId.present
          ? data.relatedEventId.value
          : this.relatedEventId,
      location: data.location.present ? data.location.value : this.location,
      legalDocument: data.legalDocument.present
          ? data.legalDocument.value
          : this.legalDocument,
      notes: data.notes.present ? data.notes.value : this.notes,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
      isPrimary: data.isPrimary.present ? data.isPrimary.value : this.isPrimary,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SurnameEvent(')
          ..write('id: $id, ')
          ..write('personId: $personId, ')
          ..write('surname: $surname, ')
          ..write('surnameType: $surnameType, ')
          ..write('startDate: $startDate, ')
          ..write('startDateQualifier: $startDateQualifier, ')
          ..write('endDate: $endDate, ')
          ..write('endDateQualifier: $endDateQualifier, ')
          ..write('relatedPersonId: $relatedPersonId, ')
          ..write('relatedEventId: $relatedEventId, ')
          ..write('location: $location, ')
          ..write('legalDocument: $legalDocument, ')
          ..write('notes: $notes, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('isPrimary: $isPrimary, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    personId,
    surname,
    surnameType,
    startDate,
    startDateQualifier,
    endDate,
    endDateQualifier,
    relatedPersonId,
    relatedEventId,
    location,
    legalDocument,
    notes,
    sortOrder,
    isPrimary,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SurnameEvent &&
          other.id == this.id &&
          other.personId == this.personId &&
          other.surname == this.surname &&
          other.surnameType == this.surnameType &&
          other.startDate == this.startDate &&
          other.startDateQualifier == this.startDateQualifier &&
          other.endDate == this.endDate &&
          other.endDateQualifier == this.endDateQualifier &&
          other.relatedPersonId == this.relatedPersonId &&
          other.relatedEventId == this.relatedEventId &&
          other.location == this.location &&
          other.legalDocument == this.legalDocument &&
          other.notes == this.notes &&
          other.sortOrder == this.sortOrder &&
          other.isPrimary == this.isPrimary &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class SurnameEventsCompanion extends UpdateCompanion<SurnameEvent> {
  final Value<String> id;
  final Value<String> personId;
  final Value<String> surname;
  final Value<String> surnameType;
  final Value<String?> startDate;
  final Value<String?> startDateQualifier;
  final Value<String?> endDate;
  final Value<String?> endDateQualifier;
  final Value<String?> relatedPersonId;
  final Value<String?> relatedEventId;
  final Value<String?> location;
  final Value<String?> legalDocument;
  final Value<String?> notes;
  final Value<int> sortOrder;
  final Value<bool> isPrimary;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const SurnameEventsCompanion({
    this.id = const Value.absent(),
    this.personId = const Value.absent(),
    this.surname = const Value.absent(),
    this.surnameType = const Value.absent(),
    this.startDate = const Value.absent(),
    this.startDateQualifier = const Value.absent(),
    this.endDate = const Value.absent(),
    this.endDateQualifier = const Value.absent(),
    this.relatedPersonId = const Value.absent(),
    this.relatedEventId = const Value.absent(),
    this.location = const Value.absent(),
    this.legalDocument = const Value.absent(),
    this.notes = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.isPrimary = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SurnameEventsCompanion.insert({
    required String id,
    required String personId,
    required String surname,
    required String surnameType,
    this.startDate = const Value.absent(),
    this.startDateQualifier = const Value.absent(),
    this.endDate = const Value.absent(),
    this.endDateQualifier = const Value.absent(),
    this.relatedPersonId = const Value.absent(),
    this.relatedEventId = const Value.absent(),
    this.location = const Value.absent(),
    this.legalDocument = const Value.absent(),
    this.notes = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.isPrimary = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       personId = Value(personId),
       surname = Value(surname),
       surnameType = Value(surnameType);
  static Insertable<SurnameEvent> custom({
    Expression<String>? id,
    Expression<String>? personId,
    Expression<String>? surname,
    Expression<String>? surnameType,
    Expression<String>? startDate,
    Expression<String>? startDateQualifier,
    Expression<String>? endDate,
    Expression<String>? endDateQualifier,
    Expression<String>? relatedPersonId,
    Expression<String>? relatedEventId,
    Expression<String>? location,
    Expression<String>? legalDocument,
    Expression<String>? notes,
    Expression<int>? sortOrder,
    Expression<bool>? isPrimary,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (personId != null) 'person_id': personId,
      if (surname != null) 'surname': surname,
      if (surnameType != null) 'surname_type': surnameType,
      if (startDate != null) 'start_date': startDate,
      if (startDateQualifier != null)
        'start_date_qualifier': startDateQualifier,
      if (endDate != null) 'end_date': endDate,
      if (endDateQualifier != null) 'end_date_qualifier': endDateQualifier,
      if (relatedPersonId != null) 'related_person_id': relatedPersonId,
      if (relatedEventId != null) 'related_event_id': relatedEventId,
      if (location != null) 'location': location,
      if (legalDocument != null) 'legal_document': legalDocument,
      if (notes != null) 'notes': notes,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (isPrimary != null) 'is_primary': isPrimary,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SurnameEventsCompanion copyWith({
    Value<String>? id,
    Value<String>? personId,
    Value<String>? surname,
    Value<String>? surnameType,
    Value<String?>? startDate,
    Value<String?>? startDateQualifier,
    Value<String?>? endDate,
    Value<String?>? endDateQualifier,
    Value<String?>? relatedPersonId,
    Value<String?>? relatedEventId,
    Value<String?>? location,
    Value<String?>? legalDocument,
    Value<String?>? notes,
    Value<int>? sortOrder,
    Value<bool>? isPrimary,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return SurnameEventsCompanion(
      id: id ?? this.id,
      personId: personId ?? this.personId,
      surname: surname ?? this.surname,
      surnameType: surnameType ?? this.surnameType,
      startDate: startDate ?? this.startDate,
      startDateQualifier: startDateQualifier ?? this.startDateQualifier,
      endDate: endDate ?? this.endDate,
      endDateQualifier: endDateQualifier ?? this.endDateQualifier,
      relatedPersonId: relatedPersonId ?? this.relatedPersonId,
      relatedEventId: relatedEventId ?? this.relatedEventId,
      location: location ?? this.location,
      legalDocument: legalDocument ?? this.legalDocument,
      notes: notes ?? this.notes,
      sortOrder: sortOrder ?? this.sortOrder,
      isPrimary: isPrimary ?? this.isPrimary,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (personId.present) {
      map['person_id'] = Variable<String>(personId.value);
    }
    if (surname.present) {
      map['surname'] = Variable<String>(surname.value);
    }
    if (surnameType.present) {
      map['surname_type'] = Variable<String>(surnameType.value);
    }
    if (startDate.present) {
      map['start_date'] = Variable<String>(startDate.value);
    }
    if (startDateQualifier.present) {
      map['start_date_qualifier'] = Variable<String>(startDateQualifier.value);
    }
    if (endDate.present) {
      map['end_date'] = Variable<String>(endDate.value);
    }
    if (endDateQualifier.present) {
      map['end_date_qualifier'] = Variable<String>(endDateQualifier.value);
    }
    if (relatedPersonId.present) {
      map['related_person_id'] = Variable<String>(relatedPersonId.value);
    }
    if (relatedEventId.present) {
      map['related_event_id'] = Variable<String>(relatedEventId.value);
    }
    if (location.present) {
      map['location'] = Variable<String>(location.value);
    }
    if (legalDocument.present) {
      map['legal_document'] = Variable<String>(legalDocument.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (isPrimary.present) {
      map['is_primary'] = Variable<bool>(isPrimary.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SurnameEventsCompanion(')
          ..write('id: $id, ')
          ..write('personId: $personId, ')
          ..write('surname: $surname, ')
          ..write('surnameType: $surnameType, ')
          ..write('startDate: $startDate, ')
          ..write('startDateQualifier: $startDateQualifier, ')
          ..write('endDate: $endDate, ')
          ..write('endDateQualifier: $endDateQualifier, ')
          ..write('relatedPersonId: $relatedPersonId, ')
          ..write('relatedEventId: $relatedEventId, ')
          ..write('location: $location, ')
          ..write('legalDocument: $legalDocument, ')
          ..write('notes: $notes, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('isPrimary: $isPrimary, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $FamiliesV2Table extends FamiliesV2
    with TableInfo<$FamiliesV2Table, FamiliesV2Data> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FamiliesV2Table(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _treeIdMeta = const VerificationMeta('treeId');
  @override
  late final GeneratedColumn<String> treeId = GeneratedColumn<String>(
    'tree_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES family_trees (id) ON DELETE RESTRICT',
    ),
  );
  static const VerificationMeta _husbandIdMeta = const VerificationMeta(
    'husbandId',
  );
  @override
  late final GeneratedColumn<String> husbandId = GeneratedColumn<String>(
    'husband_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES genealogy_persons (id) ON DELETE RESTRICT',
    ),
  );
  static const VerificationMeta _wifeIdMeta = const VerificationMeta('wifeId');
  @override
  late final GeneratedColumn<String> wifeId = GeneratedColumn<String>(
    'wife_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES genealogy_persons (id) ON DELETE RESTRICT',
    ),
  );
  static const VerificationMeta _marriageDateMeta = const VerificationMeta(
    'marriageDate',
  );
  @override
  late final GeneratedColumn<DateTime> marriageDate = GeneratedColumn<DateTime>(
    'marriage_date',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _marriageDateQualifierMeta =
      const VerificationMeta('marriageDateQualifier');
  @override
  late final GeneratedColumn<String> marriageDateQualifier =
      GeneratedColumn<String>(
        'marriage_date_qualifier',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _marriagePlaceMeta = const VerificationMeta(
    'marriagePlace',
  );
  @override
  late final GeneratedColumn<String> marriagePlace = GeneratedColumn<String>(
    'marriage_place',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _marriagePlaceLatMeta = const VerificationMeta(
    'marriagePlaceLat',
  );
  @override
  late final GeneratedColumn<double> marriagePlaceLat = GeneratedColumn<double>(
    'marriage_place_lat',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _marriagePlaceLngMeta = const VerificationMeta(
    'marriagePlaceLng',
  );
  @override
  late final GeneratedColumn<double> marriagePlaceLng = GeneratedColumn<double>(
    'marriage_place_lng',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _wifeTookHusbandNameMeta =
      const VerificationMeta('wifeTookHusbandName');
  @override
  late final GeneratedColumn<bool> wifeTookHusbandName = GeneratedColumn<bool>(
    'wife_took_husband_name',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("wife_took_husband_name" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _husbandTookWifeNameMeta =
      const VerificationMeta('husbandTookWifeName');
  @override
  late final GeneratedColumn<bool> husbandTookWifeName = GeneratedColumn<bool>(
    'husband_took_wife_name',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("husband_took_wife_name" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _hyphenatedSurnameMeta = const VerificationMeta(
    'hyphenatedSurname',
  );
  @override
  late final GeneratedColumn<bool> hyphenatedSurname = GeneratedColumn<bool>(
    'hyphenated_surname',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("hyphenated_surname" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _noNameChangeMeta = const VerificationMeta(
    'noNameChange',
  );
  @override
  late final GeneratedColumn<bool> noNameChange = GeneratedColumn<bool>(
    'no_name_change',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("no_name_change" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _customSurnameChangeMeta =
      const VerificationMeta('customSurnameChange');
  @override
  late final GeneratedColumn<String> customSurnameChange =
      GeneratedColumn<String>(
        'custom_surname_change',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _wifeMarriedSurnameMeta =
      const VerificationMeta('wifeMarriedSurname');
  @override
  late final GeneratedColumn<String> wifeMarriedSurname =
      GeneratedColumn<String>(
        'wife_married_surname',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _wifeNameChangeTypeMeta =
      const VerificationMeta('wifeNameChangeType');
  @override
  late final GeneratedColumn<String> wifeNameChangeType =
      GeneratedColumn<String>(
        'wife_name_change_type',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _husbandMarriedSurnameMeta =
      const VerificationMeta('husbandMarriedSurname');
  @override
  late final GeneratedColumn<String> husbandMarriedSurname =
      GeneratedColumn<String>(
        'husband_married_surname',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _husbandNameChangeTypeMeta =
      const VerificationMeta('husbandNameChangeType');
  @override
  late final GeneratedColumn<String> husbandNameChangeType =
      GeneratedColumn<String>(
        'husband_name_change_type',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _divorceDateMeta = const VerificationMeta(
    'divorceDate',
  );
  @override
  late final GeneratedColumn<DateTime> divorceDate = GeneratedColumn<DateTime>(
    'divorce_date',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _divorceDateQualifierMeta =
      const VerificationMeta('divorceDateQualifier');
  @override
  late final GeneratedColumn<String> divorceDateQualifier =
      GeneratedColumn<String>(
        'divorce_date_qualifier',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _divorcePlaceMeta = const VerificationMeta(
    'divorcePlace',
  );
  @override
  late final GeneratedColumn<String> divorcePlace = GeneratedColumn<String>(
    'divorce_place',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _wifeRevertedToMaidenMeta =
      const VerificationMeta('wifeRevertedToMaiden');
  @override
  late final GeneratedColumn<bool> wifeRevertedToMaiden = GeneratedColumn<bool>(
    'wife_reverted_to_maiden',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("wife_reverted_to_maiden" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _husbandRevertedNameMeta =
      const VerificationMeta('husbandRevertedName');
  @override
  late final GeneratedColumn<bool> husbandRevertedName = GeneratedColumn<bool>(
    'husband_reverted_name',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("husband_reverted_name" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _relationshipTypeMeta = const VerificationMeta(
    'relationshipType',
  );
  @override
  late final GeneratedColumn<String> relationshipType = GeneratedColumn<String>(
    'relationship_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('marriage'),
  );
  static const VerificationMeta _isPrimaryMarriageMeta = const VerificationMeta(
    'isPrimaryMarriage',
  );
  @override
  late final GeneratedColumn<bool> isPrimaryMarriage = GeneratedColumn<bool>(
    'is_primary_marriage',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_primary_marriage" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _privateNotesMeta = const VerificationMeta(
    'privateNotes',
  );
  @override
  late final GeneratedColumn<String> privateNotes = GeneratedColumn<String>(
    'private_notes',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isDeletedMeta = const VerificationMeta(
    'isDeleted',
  );
  @override
  late final GeneratedColumn<bool> isDeleted = GeneratedColumn<bool>(
    'is_deleted',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_deleted" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    treeId,
    husbandId,
    wifeId,
    marriageDate,
    marriageDateQualifier,
    marriagePlace,
    marriagePlaceLat,
    marriagePlaceLng,
    wifeTookHusbandName,
    husbandTookWifeName,
    hyphenatedSurname,
    noNameChange,
    customSurnameChange,
    wifeMarriedSurname,
    wifeNameChangeType,
    husbandMarriedSurname,
    husbandNameChangeType,
    divorceDate,
    divorceDateQualifier,
    divorcePlace,
    wifeRevertedToMaiden,
    husbandRevertedName,
    relationshipType,
    isPrimaryMarriage,
    notes,
    privateNotes,
    isDeleted,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'families_v2';
  @override
  VerificationContext validateIntegrity(
    Insertable<FamiliesV2Data> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('tree_id')) {
      context.handle(
        _treeIdMeta,
        treeId.isAcceptableOrUnknown(data['tree_id']!, _treeIdMeta),
      );
    } else if (isInserting) {
      context.missing(_treeIdMeta);
    }
    if (data.containsKey('husband_id')) {
      context.handle(
        _husbandIdMeta,
        husbandId.isAcceptableOrUnknown(data['husband_id']!, _husbandIdMeta),
      );
    }
    if (data.containsKey('wife_id')) {
      context.handle(
        _wifeIdMeta,
        wifeId.isAcceptableOrUnknown(data['wife_id']!, _wifeIdMeta),
      );
    }
    if (data.containsKey('marriage_date')) {
      context.handle(
        _marriageDateMeta,
        marriageDate.isAcceptableOrUnknown(
          data['marriage_date']!,
          _marriageDateMeta,
        ),
      );
    }
    if (data.containsKey('marriage_date_qualifier')) {
      context.handle(
        _marriageDateQualifierMeta,
        marriageDateQualifier.isAcceptableOrUnknown(
          data['marriage_date_qualifier']!,
          _marriageDateQualifierMeta,
        ),
      );
    }
    if (data.containsKey('marriage_place')) {
      context.handle(
        _marriagePlaceMeta,
        marriagePlace.isAcceptableOrUnknown(
          data['marriage_place']!,
          _marriagePlaceMeta,
        ),
      );
    }
    if (data.containsKey('marriage_place_lat')) {
      context.handle(
        _marriagePlaceLatMeta,
        marriagePlaceLat.isAcceptableOrUnknown(
          data['marriage_place_lat']!,
          _marriagePlaceLatMeta,
        ),
      );
    }
    if (data.containsKey('marriage_place_lng')) {
      context.handle(
        _marriagePlaceLngMeta,
        marriagePlaceLng.isAcceptableOrUnknown(
          data['marriage_place_lng']!,
          _marriagePlaceLngMeta,
        ),
      );
    }
    if (data.containsKey('wife_took_husband_name')) {
      context.handle(
        _wifeTookHusbandNameMeta,
        wifeTookHusbandName.isAcceptableOrUnknown(
          data['wife_took_husband_name']!,
          _wifeTookHusbandNameMeta,
        ),
      );
    }
    if (data.containsKey('husband_took_wife_name')) {
      context.handle(
        _husbandTookWifeNameMeta,
        husbandTookWifeName.isAcceptableOrUnknown(
          data['husband_took_wife_name']!,
          _husbandTookWifeNameMeta,
        ),
      );
    }
    if (data.containsKey('hyphenated_surname')) {
      context.handle(
        _hyphenatedSurnameMeta,
        hyphenatedSurname.isAcceptableOrUnknown(
          data['hyphenated_surname']!,
          _hyphenatedSurnameMeta,
        ),
      );
    }
    if (data.containsKey('no_name_change')) {
      context.handle(
        _noNameChangeMeta,
        noNameChange.isAcceptableOrUnknown(
          data['no_name_change']!,
          _noNameChangeMeta,
        ),
      );
    }
    if (data.containsKey('custom_surname_change')) {
      context.handle(
        _customSurnameChangeMeta,
        customSurnameChange.isAcceptableOrUnknown(
          data['custom_surname_change']!,
          _customSurnameChangeMeta,
        ),
      );
    }
    if (data.containsKey('wife_married_surname')) {
      context.handle(
        _wifeMarriedSurnameMeta,
        wifeMarriedSurname.isAcceptableOrUnknown(
          data['wife_married_surname']!,
          _wifeMarriedSurnameMeta,
        ),
      );
    }
    if (data.containsKey('wife_name_change_type')) {
      context.handle(
        _wifeNameChangeTypeMeta,
        wifeNameChangeType.isAcceptableOrUnknown(
          data['wife_name_change_type']!,
          _wifeNameChangeTypeMeta,
        ),
      );
    }
    if (data.containsKey('husband_married_surname')) {
      context.handle(
        _husbandMarriedSurnameMeta,
        husbandMarriedSurname.isAcceptableOrUnknown(
          data['husband_married_surname']!,
          _husbandMarriedSurnameMeta,
        ),
      );
    }
    if (data.containsKey('husband_name_change_type')) {
      context.handle(
        _husbandNameChangeTypeMeta,
        husbandNameChangeType.isAcceptableOrUnknown(
          data['husband_name_change_type']!,
          _husbandNameChangeTypeMeta,
        ),
      );
    }
    if (data.containsKey('divorce_date')) {
      context.handle(
        _divorceDateMeta,
        divorceDate.isAcceptableOrUnknown(
          data['divorce_date']!,
          _divorceDateMeta,
        ),
      );
    }
    if (data.containsKey('divorce_date_qualifier')) {
      context.handle(
        _divorceDateQualifierMeta,
        divorceDateQualifier.isAcceptableOrUnknown(
          data['divorce_date_qualifier']!,
          _divorceDateQualifierMeta,
        ),
      );
    }
    if (data.containsKey('divorce_place')) {
      context.handle(
        _divorcePlaceMeta,
        divorcePlace.isAcceptableOrUnknown(
          data['divorce_place']!,
          _divorcePlaceMeta,
        ),
      );
    }
    if (data.containsKey('wife_reverted_to_maiden')) {
      context.handle(
        _wifeRevertedToMaidenMeta,
        wifeRevertedToMaiden.isAcceptableOrUnknown(
          data['wife_reverted_to_maiden']!,
          _wifeRevertedToMaidenMeta,
        ),
      );
    }
    if (data.containsKey('husband_reverted_name')) {
      context.handle(
        _husbandRevertedNameMeta,
        husbandRevertedName.isAcceptableOrUnknown(
          data['husband_reverted_name']!,
          _husbandRevertedNameMeta,
        ),
      );
    }
    if (data.containsKey('relationship_type')) {
      context.handle(
        _relationshipTypeMeta,
        relationshipType.isAcceptableOrUnknown(
          data['relationship_type']!,
          _relationshipTypeMeta,
        ),
      );
    }
    if (data.containsKey('is_primary_marriage')) {
      context.handle(
        _isPrimaryMarriageMeta,
        isPrimaryMarriage.isAcceptableOrUnknown(
          data['is_primary_marriage']!,
          _isPrimaryMarriageMeta,
        ),
      );
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    if (data.containsKey('private_notes')) {
      context.handle(
        _privateNotesMeta,
        privateNotes.isAcceptableOrUnknown(
          data['private_notes']!,
          _privateNotesMeta,
        ),
      );
    }
    if (data.containsKey('is_deleted')) {
      context.handle(
        _isDeletedMeta,
        isDeleted.isAcceptableOrUnknown(data['is_deleted']!, _isDeletedMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  FamiliesV2Data map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return FamiliesV2Data(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      treeId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tree_id'],
      )!,
      husbandId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}husband_id'],
      ),
      wifeId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}wife_id'],
      ),
      marriageDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}marriage_date'],
      ),
      marriageDateQualifier: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}marriage_date_qualifier'],
      ),
      marriagePlace: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}marriage_place'],
      ),
      marriagePlaceLat: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}marriage_place_lat'],
      ),
      marriagePlaceLng: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}marriage_place_lng'],
      ),
      wifeTookHusbandName: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}wife_took_husband_name'],
      )!,
      husbandTookWifeName: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}husband_took_wife_name'],
      )!,
      hyphenatedSurname: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}hyphenated_surname'],
      )!,
      noNameChange: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}no_name_change'],
      )!,
      customSurnameChange: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}custom_surname_change'],
      ),
      wifeMarriedSurname: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}wife_married_surname'],
      ),
      wifeNameChangeType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}wife_name_change_type'],
      ),
      husbandMarriedSurname: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}husband_married_surname'],
      ),
      husbandNameChangeType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}husband_name_change_type'],
      ),
      divorceDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}divorce_date'],
      ),
      divorceDateQualifier: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}divorce_date_qualifier'],
      ),
      divorcePlace: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}divorce_place'],
      ),
      wifeRevertedToMaiden: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}wife_reverted_to_maiden'],
      )!,
      husbandRevertedName: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}husband_reverted_name'],
      )!,
      relationshipType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}relationship_type'],
      )!,
      isPrimaryMarriage: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_primary_marriage'],
      )!,
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
      privateNotes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}private_notes'],
      ),
      isDeleted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_deleted'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $FamiliesV2Table createAlias(String alias) {
    return $FamiliesV2Table(attachedDatabase, alias);
  }
}

class FamiliesV2Data extends DataClass implements Insertable<FamiliesV2Data> {
  final String id;
  final String treeId;
  final String? husbandId;
  final String? wifeId;
  final DateTime? marriageDate;
  final String? marriageDateQualifier;
  final String? marriagePlace;
  final double? marriagePlaceLat;
  final double? marriagePlaceLng;
  final bool wifeTookHusbandName;
  final bool husbandTookWifeName;
  final bool hyphenatedSurname;
  final bool noNameChange;
  final String? customSurnameChange;
  final String? wifeMarriedSurname;
  final String? wifeNameChangeType;
  final String? husbandMarriedSurname;
  final String? husbandNameChangeType;
  final DateTime? divorceDate;
  final String? divorceDateQualifier;
  final String? divorcePlace;
  final bool wifeRevertedToMaiden;
  final bool husbandRevertedName;

  /// Partnership kind. Reserved for distinguishing marriage / partnership /
  /// cohabitation; currently always the default.
  final String relationshipType;
  final bool isPrimaryMarriage;
  final String? notes;
  final String? privateNotes;
  final bool isDeleted;
  final DateTime createdAt;
  final DateTime updatedAt;
  const FamiliesV2Data({
    required this.id,
    required this.treeId,
    this.husbandId,
    this.wifeId,
    this.marriageDate,
    this.marriageDateQualifier,
    this.marriagePlace,
    this.marriagePlaceLat,
    this.marriagePlaceLng,
    required this.wifeTookHusbandName,
    required this.husbandTookWifeName,
    required this.hyphenatedSurname,
    required this.noNameChange,
    this.customSurnameChange,
    this.wifeMarriedSurname,
    this.wifeNameChangeType,
    this.husbandMarriedSurname,
    this.husbandNameChangeType,
    this.divorceDate,
    this.divorceDateQualifier,
    this.divorcePlace,
    required this.wifeRevertedToMaiden,
    required this.husbandRevertedName,
    required this.relationshipType,
    required this.isPrimaryMarriage,
    this.notes,
    this.privateNotes,
    required this.isDeleted,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['tree_id'] = Variable<String>(treeId);
    if (!nullToAbsent || husbandId != null) {
      map['husband_id'] = Variable<String>(husbandId);
    }
    if (!nullToAbsent || wifeId != null) {
      map['wife_id'] = Variable<String>(wifeId);
    }
    if (!nullToAbsent || marriageDate != null) {
      map['marriage_date'] = Variable<DateTime>(marriageDate);
    }
    if (!nullToAbsent || marriageDateQualifier != null) {
      map['marriage_date_qualifier'] = Variable<String>(marriageDateQualifier);
    }
    if (!nullToAbsent || marriagePlace != null) {
      map['marriage_place'] = Variable<String>(marriagePlace);
    }
    if (!nullToAbsent || marriagePlaceLat != null) {
      map['marriage_place_lat'] = Variable<double>(marriagePlaceLat);
    }
    if (!nullToAbsent || marriagePlaceLng != null) {
      map['marriage_place_lng'] = Variable<double>(marriagePlaceLng);
    }
    map['wife_took_husband_name'] = Variable<bool>(wifeTookHusbandName);
    map['husband_took_wife_name'] = Variable<bool>(husbandTookWifeName);
    map['hyphenated_surname'] = Variable<bool>(hyphenatedSurname);
    map['no_name_change'] = Variable<bool>(noNameChange);
    if (!nullToAbsent || customSurnameChange != null) {
      map['custom_surname_change'] = Variable<String>(customSurnameChange);
    }
    if (!nullToAbsent || wifeMarriedSurname != null) {
      map['wife_married_surname'] = Variable<String>(wifeMarriedSurname);
    }
    if (!nullToAbsent || wifeNameChangeType != null) {
      map['wife_name_change_type'] = Variable<String>(wifeNameChangeType);
    }
    if (!nullToAbsent || husbandMarriedSurname != null) {
      map['husband_married_surname'] = Variable<String>(husbandMarriedSurname);
    }
    if (!nullToAbsent || husbandNameChangeType != null) {
      map['husband_name_change_type'] = Variable<String>(husbandNameChangeType);
    }
    if (!nullToAbsent || divorceDate != null) {
      map['divorce_date'] = Variable<DateTime>(divorceDate);
    }
    if (!nullToAbsent || divorceDateQualifier != null) {
      map['divorce_date_qualifier'] = Variable<String>(divorceDateQualifier);
    }
    if (!nullToAbsent || divorcePlace != null) {
      map['divorce_place'] = Variable<String>(divorcePlace);
    }
    map['wife_reverted_to_maiden'] = Variable<bool>(wifeRevertedToMaiden);
    map['husband_reverted_name'] = Variable<bool>(husbandRevertedName);
    map['relationship_type'] = Variable<String>(relationshipType);
    map['is_primary_marriage'] = Variable<bool>(isPrimaryMarriage);
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    if (!nullToAbsent || privateNotes != null) {
      map['private_notes'] = Variable<String>(privateNotes);
    }
    map['is_deleted'] = Variable<bool>(isDeleted);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  FamiliesV2Companion toCompanion(bool nullToAbsent) {
    return FamiliesV2Companion(
      id: Value(id),
      treeId: Value(treeId),
      husbandId: husbandId == null && nullToAbsent
          ? const Value.absent()
          : Value(husbandId),
      wifeId: wifeId == null && nullToAbsent
          ? const Value.absent()
          : Value(wifeId),
      marriageDate: marriageDate == null && nullToAbsent
          ? const Value.absent()
          : Value(marriageDate),
      marriageDateQualifier: marriageDateQualifier == null && nullToAbsent
          ? const Value.absent()
          : Value(marriageDateQualifier),
      marriagePlace: marriagePlace == null && nullToAbsent
          ? const Value.absent()
          : Value(marriagePlace),
      marriagePlaceLat: marriagePlaceLat == null && nullToAbsent
          ? const Value.absent()
          : Value(marriagePlaceLat),
      marriagePlaceLng: marriagePlaceLng == null && nullToAbsent
          ? const Value.absent()
          : Value(marriagePlaceLng),
      wifeTookHusbandName: Value(wifeTookHusbandName),
      husbandTookWifeName: Value(husbandTookWifeName),
      hyphenatedSurname: Value(hyphenatedSurname),
      noNameChange: Value(noNameChange),
      customSurnameChange: customSurnameChange == null && nullToAbsent
          ? const Value.absent()
          : Value(customSurnameChange),
      wifeMarriedSurname: wifeMarriedSurname == null && nullToAbsent
          ? const Value.absent()
          : Value(wifeMarriedSurname),
      wifeNameChangeType: wifeNameChangeType == null && nullToAbsent
          ? const Value.absent()
          : Value(wifeNameChangeType),
      husbandMarriedSurname: husbandMarriedSurname == null && nullToAbsent
          ? const Value.absent()
          : Value(husbandMarriedSurname),
      husbandNameChangeType: husbandNameChangeType == null && nullToAbsent
          ? const Value.absent()
          : Value(husbandNameChangeType),
      divorceDate: divorceDate == null && nullToAbsent
          ? const Value.absent()
          : Value(divorceDate),
      divorceDateQualifier: divorceDateQualifier == null && nullToAbsent
          ? const Value.absent()
          : Value(divorceDateQualifier),
      divorcePlace: divorcePlace == null && nullToAbsent
          ? const Value.absent()
          : Value(divorcePlace),
      wifeRevertedToMaiden: Value(wifeRevertedToMaiden),
      husbandRevertedName: Value(husbandRevertedName),
      relationshipType: Value(relationshipType),
      isPrimaryMarriage: Value(isPrimaryMarriage),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
          : Value(notes),
      privateNotes: privateNotes == null && nullToAbsent
          ? const Value.absent()
          : Value(privateNotes),
      isDeleted: Value(isDeleted),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory FamiliesV2Data.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return FamiliesV2Data(
      id: serializer.fromJson<String>(json['id']),
      treeId: serializer.fromJson<String>(json['treeId']),
      husbandId: serializer.fromJson<String?>(json['husbandId']),
      wifeId: serializer.fromJson<String?>(json['wifeId']),
      marriageDate: serializer.fromJson<DateTime?>(json['marriageDate']),
      marriageDateQualifier: serializer.fromJson<String?>(
        json['marriageDateQualifier'],
      ),
      marriagePlace: serializer.fromJson<String?>(json['marriagePlace']),
      marriagePlaceLat: serializer.fromJson<double?>(json['marriagePlaceLat']),
      marriagePlaceLng: serializer.fromJson<double?>(json['marriagePlaceLng']),
      wifeTookHusbandName: serializer.fromJson<bool>(
        json['wifeTookHusbandName'],
      ),
      husbandTookWifeName: serializer.fromJson<bool>(
        json['husbandTookWifeName'],
      ),
      hyphenatedSurname: serializer.fromJson<bool>(json['hyphenatedSurname']),
      noNameChange: serializer.fromJson<bool>(json['noNameChange']),
      customSurnameChange: serializer.fromJson<String?>(
        json['customSurnameChange'],
      ),
      wifeMarriedSurname: serializer.fromJson<String?>(
        json['wifeMarriedSurname'],
      ),
      wifeNameChangeType: serializer.fromJson<String?>(
        json['wifeNameChangeType'],
      ),
      husbandMarriedSurname: serializer.fromJson<String?>(
        json['husbandMarriedSurname'],
      ),
      husbandNameChangeType: serializer.fromJson<String?>(
        json['husbandNameChangeType'],
      ),
      divorceDate: serializer.fromJson<DateTime?>(json['divorceDate']),
      divorceDateQualifier: serializer.fromJson<String?>(
        json['divorceDateQualifier'],
      ),
      divorcePlace: serializer.fromJson<String?>(json['divorcePlace']),
      wifeRevertedToMaiden: serializer.fromJson<bool>(
        json['wifeRevertedToMaiden'],
      ),
      husbandRevertedName: serializer.fromJson<bool>(
        json['husbandRevertedName'],
      ),
      relationshipType: serializer.fromJson<String>(json['relationshipType']),
      isPrimaryMarriage: serializer.fromJson<bool>(json['isPrimaryMarriage']),
      notes: serializer.fromJson<String?>(json['notes']),
      privateNotes: serializer.fromJson<String?>(json['privateNotes']),
      isDeleted: serializer.fromJson<bool>(json['isDeleted']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'treeId': serializer.toJson<String>(treeId),
      'husbandId': serializer.toJson<String?>(husbandId),
      'wifeId': serializer.toJson<String?>(wifeId),
      'marriageDate': serializer.toJson<DateTime?>(marriageDate),
      'marriageDateQualifier': serializer.toJson<String?>(
        marriageDateQualifier,
      ),
      'marriagePlace': serializer.toJson<String?>(marriagePlace),
      'marriagePlaceLat': serializer.toJson<double?>(marriagePlaceLat),
      'marriagePlaceLng': serializer.toJson<double?>(marriagePlaceLng),
      'wifeTookHusbandName': serializer.toJson<bool>(wifeTookHusbandName),
      'husbandTookWifeName': serializer.toJson<bool>(husbandTookWifeName),
      'hyphenatedSurname': serializer.toJson<bool>(hyphenatedSurname),
      'noNameChange': serializer.toJson<bool>(noNameChange),
      'customSurnameChange': serializer.toJson<String?>(customSurnameChange),
      'wifeMarriedSurname': serializer.toJson<String?>(wifeMarriedSurname),
      'wifeNameChangeType': serializer.toJson<String?>(wifeNameChangeType),
      'husbandMarriedSurname': serializer.toJson<String?>(
        husbandMarriedSurname,
      ),
      'husbandNameChangeType': serializer.toJson<String?>(
        husbandNameChangeType,
      ),
      'divorceDate': serializer.toJson<DateTime?>(divorceDate),
      'divorceDateQualifier': serializer.toJson<String?>(divorceDateQualifier),
      'divorcePlace': serializer.toJson<String?>(divorcePlace),
      'wifeRevertedToMaiden': serializer.toJson<bool>(wifeRevertedToMaiden),
      'husbandRevertedName': serializer.toJson<bool>(husbandRevertedName),
      'relationshipType': serializer.toJson<String>(relationshipType),
      'isPrimaryMarriage': serializer.toJson<bool>(isPrimaryMarriage),
      'notes': serializer.toJson<String?>(notes),
      'privateNotes': serializer.toJson<String?>(privateNotes),
      'isDeleted': serializer.toJson<bool>(isDeleted),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  FamiliesV2Data copyWith({
    String? id,
    String? treeId,
    Value<String?> husbandId = const Value.absent(),
    Value<String?> wifeId = const Value.absent(),
    Value<DateTime?> marriageDate = const Value.absent(),
    Value<String?> marriageDateQualifier = const Value.absent(),
    Value<String?> marriagePlace = const Value.absent(),
    Value<double?> marriagePlaceLat = const Value.absent(),
    Value<double?> marriagePlaceLng = const Value.absent(),
    bool? wifeTookHusbandName,
    bool? husbandTookWifeName,
    bool? hyphenatedSurname,
    bool? noNameChange,
    Value<String?> customSurnameChange = const Value.absent(),
    Value<String?> wifeMarriedSurname = const Value.absent(),
    Value<String?> wifeNameChangeType = const Value.absent(),
    Value<String?> husbandMarriedSurname = const Value.absent(),
    Value<String?> husbandNameChangeType = const Value.absent(),
    Value<DateTime?> divorceDate = const Value.absent(),
    Value<String?> divorceDateQualifier = const Value.absent(),
    Value<String?> divorcePlace = const Value.absent(),
    bool? wifeRevertedToMaiden,
    bool? husbandRevertedName,
    String? relationshipType,
    bool? isPrimaryMarriage,
    Value<String?> notes = const Value.absent(),
    Value<String?> privateNotes = const Value.absent(),
    bool? isDeleted,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => FamiliesV2Data(
    id: id ?? this.id,
    treeId: treeId ?? this.treeId,
    husbandId: husbandId.present ? husbandId.value : this.husbandId,
    wifeId: wifeId.present ? wifeId.value : this.wifeId,
    marriageDate: marriageDate.present ? marriageDate.value : this.marriageDate,
    marriageDateQualifier: marriageDateQualifier.present
        ? marriageDateQualifier.value
        : this.marriageDateQualifier,
    marriagePlace: marriagePlace.present
        ? marriagePlace.value
        : this.marriagePlace,
    marriagePlaceLat: marriagePlaceLat.present
        ? marriagePlaceLat.value
        : this.marriagePlaceLat,
    marriagePlaceLng: marriagePlaceLng.present
        ? marriagePlaceLng.value
        : this.marriagePlaceLng,
    wifeTookHusbandName: wifeTookHusbandName ?? this.wifeTookHusbandName,
    husbandTookWifeName: husbandTookWifeName ?? this.husbandTookWifeName,
    hyphenatedSurname: hyphenatedSurname ?? this.hyphenatedSurname,
    noNameChange: noNameChange ?? this.noNameChange,
    customSurnameChange: customSurnameChange.present
        ? customSurnameChange.value
        : this.customSurnameChange,
    wifeMarriedSurname: wifeMarriedSurname.present
        ? wifeMarriedSurname.value
        : this.wifeMarriedSurname,
    wifeNameChangeType: wifeNameChangeType.present
        ? wifeNameChangeType.value
        : this.wifeNameChangeType,
    husbandMarriedSurname: husbandMarriedSurname.present
        ? husbandMarriedSurname.value
        : this.husbandMarriedSurname,
    husbandNameChangeType: husbandNameChangeType.present
        ? husbandNameChangeType.value
        : this.husbandNameChangeType,
    divorceDate: divorceDate.present ? divorceDate.value : this.divorceDate,
    divorceDateQualifier: divorceDateQualifier.present
        ? divorceDateQualifier.value
        : this.divorceDateQualifier,
    divorcePlace: divorcePlace.present ? divorcePlace.value : this.divorcePlace,
    wifeRevertedToMaiden: wifeRevertedToMaiden ?? this.wifeRevertedToMaiden,
    husbandRevertedName: husbandRevertedName ?? this.husbandRevertedName,
    relationshipType: relationshipType ?? this.relationshipType,
    isPrimaryMarriage: isPrimaryMarriage ?? this.isPrimaryMarriage,
    notes: notes.present ? notes.value : this.notes,
    privateNotes: privateNotes.present ? privateNotes.value : this.privateNotes,
    isDeleted: isDeleted ?? this.isDeleted,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  FamiliesV2Data copyWithCompanion(FamiliesV2Companion data) {
    return FamiliesV2Data(
      id: data.id.present ? data.id.value : this.id,
      treeId: data.treeId.present ? data.treeId.value : this.treeId,
      husbandId: data.husbandId.present ? data.husbandId.value : this.husbandId,
      wifeId: data.wifeId.present ? data.wifeId.value : this.wifeId,
      marriageDate: data.marriageDate.present
          ? data.marriageDate.value
          : this.marriageDate,
      marriageDateQualifier: data.marriageDateQualifier.present
          ? data.marriageDateQualifier.value
          : this.marriageDateQualifier,
      marriagePlace: data.marriagePlace.present
          ? data.marriagePlace.value
          : this.marriagePlace,
      marriagePlaceLat: data.marriagePlaceLat.present
          ? data.marriagePlaceLat.value
          : this.marriagePlaceLat,
      marriagePlaceLng: data.marriagePlaceLng.present
          ? data.marriagePlaceLng.value
          : this.marriagePlaceLng,
      wifeTookHusbandName: data.wifeTookHusbandName.present
          ? data.wifeTookHusbandName.value
          : this.wifeTookHusbandName,
      husbandTookWifeName: data.husbandTookWifeName.present
          ? data.husbandTookWifeName.value
          : this.husbandTookWifeName,
      hyphenatedSurname: data.hyphenatedSurname.present
          ? data.hyphenatedSurname.value
          : this.hyphenatedSurname,
      noNameChange: data.noNameChange.present
          ? data.noNameChange.value
          : this.noNameChange,
      customSurnameChange: data.customSurnameChange.present
          ? data.customSurnameChange.value
          : this.customSurnameChange,
      wifeMarriedSurname: data.wifeMarriedSurname.present
          ? data.wifeMarriedSurname.value
          : this.wifeMarriedSurname,
      wifeNameChangeType: data.wifeNameChangeType.present
          ? data.wifeNameChangeType.value
          : this.wifeNameChangeType,
      husbandMarriedSurname: data.husbandMarriedSurname.present
          ? data.husbandMarriedSurname.value
          : this.husbandMarriedSurname,
      husbandNameChangeType: data.husbandNameChangeType.present
          ? data.husbandNameChangeType.value
          : this.husbandNameChangeType,
      divorceDate: data.divorceDate.present
          ? data.divorceDate.value
          : this.divorceDate,
      divorceDateQualifier: data.divorceDateQualifier.present
          ? data.divorceDateQualifier.value
          : this.divorceDateQualifier,
      divorcePlace: data.divorcePlace.present
          ? data.divorcePlace.value
          : this.divorcePlace,
      wifeRevertedToMaiden: data.wifeRevertedToMaiden.present
          ? data.wifeRevertedToMaiden.value
          : this.wifeRevertedToMaiden,
      husbandRevertedName: data.husbandRevertedName.present
          ? data.husbandRevertedName.value
          : this.husbandRevertedName,
      relationshipType: data.relationshipType.present
          ? data.relationshipType.value
          : this.relationshipType,
      isPrimaryMarriage: data.isPrimaryMarriage.present
          ? data.isPrimaryMarriage.value
          : this.isPrimaryMarriage,
      notes: data.notes.present ? data.notes.value : this.notes,
      privateNotes: data.privateNotes.present
          ? data.privateNotes.value
          : this.privateNotes,
      isDeleted: data.isDeleted.present ? data.isDeleted.value : this.isDeleted,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('FamiliesV2Data(')
          ..write('id: $id, ')
          ..write('treeId: $treeId, ')
          ..write('husbandId: $husbandId, ')
          ..write('wifeId: $wifeId, ')
          ..write('marriageDate: $marriageDate, ')
          ..write('marriageDateQualifier: $marriageDateQualifier, ')
          ..write('marriagePlace: $marriagePlace, ')
          ..write('marriagePlaceLat: $marriagePlaceLat, ')
          ..write('marriagePlaceLng: $marriagePlaceLng, ')
          ..write('wifeTookHusbandName: $wifeTookHusbandName, ')
          ..write('husbandTookWifeName: $husbandTookWifeName, ')
          ..write('hyphenatedSurname: $hyphenatedSurname, ')
          ..write('noNameChange: $noNameChange, ')
          ..write('customSurnameChange: $customSurnameChange, ')
          ..write('wifeMarriedSurname: $wifeMarriedSurname, ')
          ..write('wifeNameChangeType: $wifeNameChangeType, ')
          ..write('husbandMarriedSurname: $husbandMarriedSurname, ')
          ..write('husbandNameChangeType: $husbandNameChangeType, ')
          ..write('divorceDate: $divorceDate, ')
          ..write('divorceDateQualifier: $divorceDateQualifier, ')
          ..write('divorcePlace: $divorcePlace, ')
          ..write('wifeRevertedToMaiden: $wifeRevertedToMaiden, ')
          ..write('husbandRevertedName: $husbandRevertedName, ')
          ..write('relationshipType: $relationshipType, ')
          ..write('isPrimaryMarriage: $isPrimaryMarriage, ')
          ..write('notes: $notes, ')
          ..write('privateNotes: $privateNotes, ')
          ..write('isDeleted: $isDeleted, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
    id,
    treeId,
    husbandId,
    wifeId,
    marriageDate,
    marriageDateQualifier,
    marriagePlace,
    marriagePlaceLat,
    marriagePlaceLng,
    wifeTookHusbandName,
    husbandTookWifeName,
    hyphenatedSurname,
    noNameChange,
    customSurnameChange,
    wifeMarriedSurname,
    wifeNameChangeType,
    husbandMarriedSurname,
    husbandNameChangeType,
    divorceDate,
    divorceDateQualifier,
    divorcePlace,
    wifeRevertedToMaiden,
    husbandRevertedName,
    relationshipType,
    isPrimaryMarriage,
    notes,
    privateNotes,
    isDeleted,
    createdAt,
    updatedAt,
  ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FamiliesV2Data &&
          other.id == this.id &&
          other.treeId == this.treeId &&
          other.husbandId == this.husbandId &&
          other.wifeId == this.wifeId &&
          other.marriageDate == this.marriageDate &&
          other.marriageDateQualifier == this.marriageDateQualifier &&
          other.marriagePlace == this.marriagePlace &&
          other.marriagePlaceLat == this.marriagePlaceLat &&
          other.marriagePlaceLng == this.marriagePlaceLng &&
          other.wifeTookHusbandName == this.wifeTookHusbandName &&
          other.husbandTookWifeName == this.husbandTookWifeName &&
          other.hyphenatedSurname == this.hyphenatedSurname &&
          other.noNameChange == this.noNameChange &&
          other.customSurnameChange == this.customSurnameChange &&
          other.wifeMarriedSurname == this.wifeMarriedSurname &&
          other.wifeNameChangeType == this.wifeNameChangeType &&
          other.husbandMarriedSurname == this.husbandMarriedSurname &&
          other.husbandNameChangeType == this.husbandNameChangeType &&
          other.divorceDate == this.divorceDate &&
          other.divorceDateQualifier == this.divorceDateQualifier &&
          other.divorcePlace == this.divorcePlace &&
          other.wifeRevertedToMaiden == this.wifeRevertedToMaiden &&
          other.husbandRevertedName == this.husbandRevertedName &&
          other.relationshipType == this.relationshipType &&
          other.isPrimaryMarriage == this.isPrimaryMarriage &&
          other.notes == this.notes &&
          other.privateNotes == this.privateNotes &&
          other.isDeleted == this.isDeleted &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class FamiliesV2Companion extends UpdateCompanion<FamiliesV2Data> {
  final Value<String> id;
  final Value<String> treeId;
  final Value<String?> husbandId;
  final Value<String?> wifeId;
  final Value<DateTime?> marriageDate;
  final Value<String?> marriageDateQualifier;
  final Value<String?> marriagePlace;
  final Value<double?> marriagePlaceLat;
  final Value<double?> marriagePlaceLng;
  final Value<bool> wifeTookHusbandName;
  final Value<bool> husbandTookWifeName;
  final Value<bool> hyphenatedSurname;
  final Value<bool> noNameChange;
  final Value<String?> customSurnameChange;
  final Value<String?> wifeMarriedSurname;
  final Value<String?> wifeNameChangeType;
  final Value<String?> husbandMarriedSurname;
  final Value<String?> husbandNameChangeType;
  final Value<DateTime?> divorceDate;
  final Value<String?> divorceDateQualifier;
  final Value<String?> divorcePlace;
  final Value<bool> wifeRevertedToMaiden;
  final Value<bool> husbandRevertedName;
  final Value<String> relationshipType;
  final Value<bool> isPrimaryMarriage;
  final Value<String?> notes;
  final Value<String?> privateNotes;
  final Value<bool> isDeleted;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const FamiliesV2Companion({
    this.id = const Value.absent(),
    this.treeId = const Value.absent(),
    this.husbandId = const Value.absent(),
    this.wifeId = const Value.absent(),
    this.marriageDate = const Value.absent(),
    this.marriageDateQualifier = const Value.absent(),
    this.marriagePlace = const Value.absent(),
    this.marriagePlaceLat = const Value.absent(),
    this.marriagePlaceLng = const Value.absent(),
    this.wifeTookHusbandName = const Value.absent(),
    this.husbandTookWifeName = const Value.absent(),
    this.hyphenatedSurname = const Value.absent(),
    this.noNameChange = const Value.absent(),
    this.customSurnameChange = const Value.absent(),
    this.wifeMarriedSurname = const Value.absent(),
    this.wifeNameChangeType = const Value.absent(),
    this.husbandMarriedSurname = const Value.absent(),
    this.husbandNameChangeType = const Value.absent(),
    this.divorceDate = const Value.absent(),
    this.divorceDateQualifier = const Value.absent(),
    this.divorcePlace = const Value.absent(),
    this.wifeRevertedToMaiden = const Value.absent(),
    this.husbandRevertedName = const Value.absent(),
    this.relationshipType = const Value.absent(),
    this.isPrimaryMarriage = const Value.absent(),
    this.notes = const Value.absent(),
    this.privateNotes = const Value.absent(),
    this.isDeleted = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  FamiliesV2Companion.insert({
    required String id,
    required String treeId,
    this.husbandId = const Value.absent(),
    this.wifeId = const Value.absent(),
    this.marriageDate = const Value.absent(),
    this.marriageDateQualifier = const Value.absent(),
    this.marriagePlace = const Value.absent(),
    this.marriagePlaceLat = const Value.absent(),
    this.marriagePlaceLng = const Value.absent(),
    this.wifeTookHusbandName = const Value.absent(),
    this.husbandTookWifeName = const Value.absent(),
    this.hyphenatedSurname = const Value.absent(),
    this.noNameChange = const Value.absent(),
    this.customSurnameChange = const Value.absent(),
    this.wifeMarriedSurname = const Value.absent(),
    this.wifeNameChangeType = const Value.absent(),
    this.husbandMarriedSurname = const Value.absent(),
    this.husbandNameChangeType = const Value.absent(),
    this.divorceDate = const Value.absent(),
    this.divorceDateQualifier = const Value.absent(),
    this.divorcePlace = const Value.absent(),
    this.wifeRevertedToMaiden = const Value.absent(),
    this.husbandRevertedName = const Value.absent(),
    this.relationshipType = const Value.absent(),
    this.isPrimaryMarriage = const Value.absent(),
    this.notes = const Value.absent(),
    this.privateNotes = const Value.absent(),
    this.isDeleted = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       treeId = Value(treeId);
  static Insertable<FamiliesV2Data> custom({
    Expression<String>? id,
    Expression<String>? treeId,
    Expression<String>? husbandId,
    Expression<String>? wifeId,
    Expression<DateTime>? marriageDate,
    Expression<String>? marriageDateQualifier,
    Expression<String>? marriagePlace,
    Expression<double>? marriagePlaceLat,
    Expression<double>? marriagePlaceLng,
    Expression<bool>? wifeTookHusbandName,
    Expression<bool>? husbandTookWifeName,
    Expression<bool>? hyphenatedSurname,
    Expression<bool>? noNameChange,
    Expression<String>? customSurnameChange,
    Expression<String>? wifeMarriedSurname,
    Expression<String>? wifeNameChangeType,
    Expression<String>? husbandMarriedSurname,
    Expression<String>? husbandNameChangeType,
    Expression<DateTime>? divorceDate,
    Expression<String>? divorceDateQualifier,
    Expression<String>? divorcePlace,
    Expression<bool>? wifeRevertedToMaiden,
    Expression<bool>? husbandRevertedName,
    Expression<String>? relationshipType,
    Expression<bool>? isPrimaryMarriage,
    Expression<String>? notes,
    Expression<String>? privateNotes,
    Expression<bool>? isDeleted,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (treeId != null) 'tree_id': treeId,
      if (husbandId != null) 'husband_id': husbandId,
      if (wifeId != null) 'wife_id': wifeId,
      if (marriageDate != null) 'marriage_date': marriageDate,
      if (marriageDateQualifier != null)
        'marriage_date_qualifier': marriageDateQualifier,
      if (marriagePlace != null) 'marriage_place': marriagePlace,
      if (marriagePlaceLat != null) 'marriage_place_lat': marriagePlaceLat,
      if (marriagePlaceLng != null) 'marriage_place_lng': marriagePlaceLng,
      if (wifeTookHusbandName != null)
        'wife_took_husband_name': wifeTookHusbandName,
      if (husbandTookWifeName != null)
        'husband_took_wife_name': husbandTookWifeName,
      if (hyphenatedSurname != null) 'hyphenated_surname': hyphenatedSurname,
      if (noNameChange != null) 'no_name_change': noNameChange,
      if (customSurnameChange != null)
        'custom_surname_change': customSurnameChange,
      if (wifeMarriedSurname != null)
        'wife_married_surname': wifeMarriedSurname,
      if (wifeNameChangeType != null)
        'wife_name_change_type': wifeNameChangeType,
      if (husbandMarriedSurname != null)
        'husband_married_surname': husbandMarriedSurname,
      if (husbandNameChangeType != null)
        'husband_name_change_type': husbandNameChangeType,
      if (divorceDate != null) 'divorce_date': divorceDate,
      if (divorceDateQualifier != null)
        'divorce_date_qualifier': divorceDateQualifier,
      if (divorcePlace != null) 'divorce_place': divorcePlace,
      if (wifeRevertedToMaiden != null)
        'wife_reverted_to_maiden': wifeRevertedToMaiden,
      if (husbandRevertedName != null)
        'husband_reverted_name': husbandRevertedName,
      if (relationshipType != null) 'relationship_type': relationshipType,
      if (isPrimaryMarriage != null) 'is_primary_marriage': isPrimaryMarriage,
      if (notes != null) 'notes': notes,
      if (privateNotes != null) 'private_notes': privateNotes,
      if (isDeleted != null) 'is_deleted': isDeleted,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  FamiliesV2Companion copyWith({
    Value<String>? id,
    Value<String>? treeId,
    Value<String?>? husbandId,
    Value<String?>? wifeId,
    Value<DateTime?>? marriageDate,
    Value<String?>? marriageDateQualifier,
    Value<String?>? marriagePlace,
    Value<double?>? marriagePlaceLat,
    Value<double?>? marriagePlaceLng,
    Value<bool>? wifeTookHusbandName,
    Value<bool>? husbandTookWifeName,
    Value<bool>? hyphenatedSurname,
    Value<bool>? noNameChange,
    Value<String?>? customSurnameChange,
    Value<String?>? wifeMarriedSurname,
    Value<String?>? wifeNameChangeType,
    Value<String?>? husbandMarriedSurname,
    Value<String?>? husbandNameChangeType,
    Value<DateTime?>? divorceDate,
    Value<String?>? divorceDateQualifier,
    Value<String?>? divorcePlace,
    Value<bool>? wifeRevertedToMaiden,
    Value<bool>? husbandRevertedName,
    Value<String>? relationshipType,
    Value<bool>? isPrimaryMarriage,
    Value<String?>? notes,
    Value<String?>? privateNotes,
    Value<bool>? isDeleted,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return FamiliesV2Companion(
      id: id ?? this.id,
      treeId: treeId ?? this.treeId,
      husbandId: husbandId ?? this.husbandId,
      wifeId: wifeId ?? this.wifeId,
      marriageDate: marriageDate ?? this.marriageDate,
      marriageDateQualifier:
          marriageDateQualifier ?? this.marriageDateQualifier,
      marriagePlace: marriagePlace ?? this.marriagePlace,
      marriagePlaceLat: marriagePlaceLat ?? this.marriagePlaceLat,
      marriagePlaceLng: marriagePlaceLng ?? this.marriagePlaceLng,
      wifeTookHusbandName: wifeTookHusbandName ?? this.wifeTookHusbandName,
      husbandTookWifeName: husbandTookWifeName ?? this.husbandTookWifeName,
      hyphenatedSurname: hyphenatedSurname ?? this.hyphenatedSurname,
      noNameChange: noNameChange ?? this.noNameChange,
      customSurnameChange: customSurnameChange ?? this.customSurnameChange,
      wifeMarriedSurname: wifeMarriedSurname ?? this.wifeMarriedSurname,
      wifeNameChangeType: wifeNameChangeType ?? this.wifeNameChangeType,
      husbandMarriedSurname:
          husbandMarriedSurname ?? this.husbandMarriedSurname,
      husbandNameChangeType:
          husbandNameChangeType ?? this.husbandNameChangeType,
      divorceDate: divorceDate ?? this.divorceDate,
      divorceDateQualifier: divorceDateQualifier ?? this.divorceDateQualifier,
      divorcePlace: divorcePlace ?? this.divorcePlace,
      wifeRevertedToMaiden: wifeRevertedToMaiden ?? this.wifeRevertedToMaiden,
      husbandRevertedName: husbandRevertedName ?? this.husbandRevertedName,
      relationshipType: relationshipType ?? this.relationshipType,
      isPrimaryMarriage: isPrimaryMarriage ?? this.isPrimaryMarriage,
      notes: notes ?? this.notes,
      privateNotes: privateNotes ?? this.privateNotes,
      isDeleted: isDeleted ?? this.isDeleted,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (treeId.present) {
      map['tree_id'] = Variable<String>(treeId.value);
    }
    if (husbandId.present) {
      map['husband_id'] = Variable<String>(husbandId.value);
    }
    if (wifeId.present) {
      map['wife_id'] = Variable<String>(wifeId.value);
    }
    if (marriageDate.present) {
      map['marriage_date'] = Variable<DateTime>(marriageDate.value);
    }
    if (marriageDateQualifier.present) {
      map['marriage_date_qualifier'] = Variable<String>(
        marriageDateQualifier.value,
      );
    }
    if (marriagePlace.present) {
      map['marriage_place'] = Variable<String>(marriagePlace.value);
    }
    if (marriagePlaceLat.present) {
      map['marriage_place_lat'] = Variable<double>(marriagePlaceLat.value);
    }
    if (marriagePlaceLng.present) {
      map['marriage_place_lng'] = Variable<double>(marriagePlaceLng.value);
    }
    if (wifeTookHusbandName.present) {
      map['wife_took_husband_name'] = Variable<bool>(wifeTookHusbandName.value);
    }
    if (husbandTookWifeName.present) {
      map['husband_took_wife_name'] = Variable<bool>(husbandTookWifeName.value);
    }
    if (hyphenatedSurname.present) {
      map['hyphenated_surname'] = Variable<bool>(hyphenatedSurname.value);
    }
    if (noNameChange.present) {
      map['no_name_change'] = Variable<bool>(noNameChange.value);
    }
    if (customSurnameChange.present) {
      map['custom_surname_change'] = Variable<String>(
        customSurnameChange.value,
      );
    }
    if (wifeMarriedSurname.present) {
      map['wife_married_surname'] = Variable<String>(wifeMarriedSurname.value);
    }
    if (wifeNameChangeType.present) {
      map['wife_name_change_type'] = Variable<String>(wifeNameChangeType.value);
    }
    if (husbandMarriedSurname.present) {
      map['husband_married_surname'] = Variable<String>(
        husbandMarriedSurname.value,
      );
    }
    if (husbandNameChangeType.present) {
      map['husband_name_change_type'] = Variable<String>(
        husbandNameChangeType.value,
      );
    }
    if (divorceDate.present) {
      map['divorce_date'] = Variable<DateTime>(divorceDate.value);
    }
    if (divorceDateQualifier.present) {
      map['divorce_date_qualifier'] = Variable<String>(
        divorceDateQualifier.value,
      );
    }
    if (divorcePlace.present) {
      map['divorce_place'] = Variable<String>(divorcePlace.value);
    }
    if (wifeRevertedToMaiden.present) {
      map['wife_reverted_to_maiden'] = Variable<bool>(
        wifeRevertedToMaiden.value,
      );
    }
    if (husbandRevertedName.present) {
      map['husband_reverted_name'] = Variable<bool>(husbandRevertedName.value);
    }
    if (relationshipType.present) {
      map['relationship_type'] = Variable<String>(relationshipType.value);
    }
    if (isPrimaryMarriage.present) {
      map['is_primary_marriage'] = Variable<bool>(isPrimaryMarriage.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (privateNotes.present) {
      map['private_notes'] = Variable<String>(privateNotes.value);
    }
    if (isDeleted.present) {
      map['is_deleted'] = Variable<bool>(isDeleted.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FamiliesV2Companion(')
          ..write('id: $id, ')
          ..write('treeId: $treeId, ')
          ..write('husbandId: $husbandId, ')
          ..write('wifeId: $wifeId, ')
          ..write('marriageDate: $marriageDate, ')
          ..write('marriageDateQualifier: $marriageDateQualifier, ')
          ..write('marriagePlace: $marriagePlace, ')
          ..write('marriagePlaceLat: $marriagePlaceLat, ')
          ..write('marriagePlaceLng: $marriagePlaceLng, ')
          ..write('wifeTookHusbandName: $wifeTookHusbandName, ')
          ..write('husbandTookWifeName: $husbandTookWifeName, ')
          ..write('hyphenatedSurname: $hyphenatedSurname, ')
          ..write('noNameChange: $noNameChange, ')
          ..write('customSurnameChange: $customSurnameChange, ')
          ..write('wifeMarriedSurname: $wifeMarriedSurname, ')
          ..write('wifeNameChangeType: $wifeNameChangeType, ')
          ..write('husbandMarriedSurname: $husbandMarriedSurname, ')
          ..write('husbandNameChangeType: $husbandNameChangeType, ')
          ..write('divorceDate: $divorceDate, ')
          ..write('divorceDateQualifier: $divorceDateQualifier, ')
          ..write('divorcePlace: $divorcePlace, ')
          ..write('wifeRevertedToMaiden: $wifeRevertedToMaiden, ')
          ..write('husbandRevertedName: $husbandRevertedName, ')
          ..write('relationshipType: $relationshipType, ')
          ..write('isPrimaryMarriage: $isPrimaryMarriage, ')
          ..write('notes: $notes, ')
          ..write('privateNotes: $privateNotes, ')
          ..write('isDeleted: $isDeleted, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $FamilyChildrenV2Table extends FamilyChildrenV2
    with TableInfo<$FamilyChildrenV2Table, FamilyChildrenV2Data> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FamilyChildrenV2Table(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _familyIdMeta = const VerificationMeta(
    'familyId',
  );
  @override
  late final GeneratedColumn<String> familyId = GeneratedColumn<String>(
    'family_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES families_v2 (id) ON DELETE RESTRICT',
    ),
  );
  static const VerificationMeta _childIdMeta = const VerificationMeta(
    'childId',
  );
  @override
  late final GeneratedColumn<String> childId = GeneratedColumn<String>(
    'child_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES genealogy_persons (id) ON DELETE RESTRICT',
    ),
  );
  static const VerificationMeta _birthOrderMeta = const VerificationMeta(
    'birthOrder',
  );
  @override
  late final GeneratedColumn<int> birthOrder = GeneratedColumn<int>(
    'birth_order',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _relationshipTypeMeta = const VerificationMeta(
    'relationshipType',
  );
  @override
  late final GeneratedColumn<String> relationshipType = GeneratedColumn<String>(
    'relationship_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('biological'),
  );
  static const VerificationMeta _childSurnameAtBirthMeta =
      const VerificationMeta('childSurnameAtBirth');
  @override
  late final GeneratedColumn<String> childSurnameAtBirth =
      GeneratedColumn<String>(
        'child_surname_at_birth',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _paternalRelationshipMeta =
      const VerificationMeta('paternalRelationship');
  @override
  late final GeneratedColumn<String> paternalRelationship =
      GeneratedColumn<String>(
        'paternal_relationship',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _maternalRelationshipMeta =
      const VerificationMeta('maternalRelationship');
  @override
  late final GeneratedColumn<String> maternalRelationship =
      GeneratedColumn<String>(
        'maternal_relationship',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isDeletedMeta = const VerificationMeta(
    'isDeleted',
  );
  @override
  late final GeneratedColumn<bool> isDeleted = GeneratedColumn<bool>(
    'is_deleted',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_deleted" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    familyId,
    childId,
    birthOrder,
    relationshipType,
    childSurnameAtBirth,
    paternalRelationship,
    maternalRelationship,
    notes,
    isDeleted,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'family_children_v2';
  @override
  VerificationContext validateIntegrity(
    Insertable<FamilyChildrenV2Data> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('family_id')) {
      context.handle(
        _familyIdMeta,
        familyId.isAcceptableOrUnknown(data['family_id']!, _familyIdMeta),
      );
    } else if (isInserting) {
      context.missing(_familyIdMeta);
    }
    if (data.containsKey('child_id')) {
      context.handle(
        _childIdMeta,
        childId.isAcceptableOrUnknown(data['child_id']!, _childIdMeta),
      );
    } else if (isInserting) {
      context.missing(_childIdMeta);
    }
    if (data.containsKey('birth_order')) {
      context.handle(
        _birthOrderMeta,
        birthOrder.isAcceptableOrUnknown(data['birth_order']!, _birthOrderMeta),
      );
    }
    if (data.containsKey('relationship_type')) {
      context.handle(
        _relationshipTypeMeta,
        relationshipType.isAcceptableOrUnknown(
          data['relationship_type']!,
          _relationshipTypeMeta,
        ),
      );
    }
    if (data.containsKey('child_surname_at_birth')) {
      context.handle(
        _childSurnameAtBirthMeta,
        childSurnameAtBirth.isAcceptableOrUnknown(
          data['child_surname_at_birth']!,
          _childSurnameAtBirthMeta,
        ),
      );
    }
    if (data.containsKey('paternal_relationship')) {
      context.handle(
        _paternalRelationshipMeta,
        paternalRelationship.isAcceptableOrUnknown(
          data['paternal_relationship']!,
          _paternalRelationshipMeta,
        ),
      );
    }
    if (data.containsKey('maternal_relationship')) {
      context.handle(
        _maternalRelationshipMeta,
        maternalRelationship.isAcceptableOrUnknown(
          data['maternal_relationship']!,
          _maternalRelationshipMeta,
        ),
      );
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    if (data.containsKey('is_deleted')) {
      context.handle(
        _isDeletedMeta,
        isDeleted.isAcceptableOrUnknown(data['is_deleted']!, _isDeletedMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  FamilyChildrenV2Data map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return FamilyChildrenV2Data(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      familyId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}family_id'],
      )!,
      childId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}child_id'],
      )!,
      birthOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}birth_order'],
      ),
      relationshipType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}relationship_type'],
      )!,
      childSurnameAtBirth: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}child_surname_at_birth'],
      ),
      paternalRelationship: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}paternal_relationship'],
      ),
      maternalRelationship: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}maternal_relationship'],
      ),
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
      isDeleted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_deleted'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $FamilyChildrenV2Table createAlias(String alias) {
    return $FamilyChildrenV2Table(attachedDatabase, alias);
  }
}

class FamilyChildrenV2Data extends DataClass
    implements Insertable<FamilyChildrenV2Data> {
  final String id;
  final String familyId;
  final String childId;
  final int? birthOrder;

  /// biological / adopted / foster / step / unknown
  final String relationshipType;
  final String? childSurnameAtBirth;
  final String? paternalRelationship;
  final String? maternalRelationship;
  final String? notes;
  final bool isDeleted;
  final DateTime createdAt;
  final DateTime updatedAt;
  const FamilyChildrenV2Data({
    required this.id,
    required this.familyId,
    required this.childId,
    this.birthOrder,
    required this.relationshipType,
    this.childSurnameAtBirth,
    this.paternalRelationship,
    this.maternalRelationship,
    this.notes,
    required this.isDeleted,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['family_id'] = Variable<String>(familyId);
    map['child_id'] = Variable<String>(childId);
    if (!nullToAbsent || birthOrder != null) {
      map['birth_order'] = Variable<int>(birthOrder);
    }
    map['relationship_type'] = Variable<String>(relationshipType);
    if (!nullToAbsent || childSurnameAtBirth != null) {
      map['child_surname_at_birth'] = Variable<String>(childSurnameAtBirth);
    }
    if (!nullToAbsent || paternalRelationship != null) {
      map['paternal_relationship'] = Variable<String>(paternalRelationship);
    }
    if (!nullToAbsent || maternalRelationship != null) {
      map['maternal_relationship'] = Variable<String>(maternalRelationship);
    }
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    map['is_deleted'] = Variable<bool>(isDeleted);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  FamilyChildrenV2Companion toCompanion(bool nullToAbsent) {
    return FamilyChildrenV2Companion(
      id: Value(id),
      familyId: Value(familyId),
      childId: Value(childId),
      birthOrder: birthOrder == null && nullToAbsent
          ? const Value.absent()
          : Value(birthOrder),
      relationshipType: Value(relationshipType),
      childSurnameAtBirth: childSurnameAtBirth == null && nullToAbsent
          ? const Value.absent()
          : Value(childSurnameAtBirth),
      paternalRelationship: paternalRelationship == null && nullToAbsent
          ? const Value.absent()
          : Value(paternalRelationship),
      maternalRelationship: maternalRelationship == null && nullToAbsent
          ? const Value.absent()
          : Value(maternalRelationship),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
          : Value(notes),
      isDeleted: Value(isDeleted),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory FamilyChildrenV2Data.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return FamilyChildrenV2Data(
      id: serializer.fromJson<String>(json['id']),
      familyId: serializer.fromJson<String>(json['familyId']),
      childId: serializer.fromJson<String>(json['childId']),
      birthOrder: serializer.fromJson<int?>(json['birthOrder']),
      relationshipType: serializer.fromJson<String>(json['relationshipType']),
      childSurnameAtBirth: serializer.fromJson<String?>(
        json['childSurnameAtBirth'],
      ),
      paternalRelationship: serializer.fromJson<String?>(
        json['paternalRelationship'],
      ),
      maternalRelationship: serializer.fromJson<String?>(
        json['maternalRelationship'],
      ),
      notes: serializer.fromJson<String?>(json['notes']),
      isDeleted: serializer.fromJson<bool>(json['isDeleted']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'familyId': serializer.toJson<String>(familyId),
      'childId': serializer.toJson<String>(childId),
      'birthOrder': serializer.toJson<int?>(birthOrder),
      'relationshipType': serializer.toJson<String>(relationshipType),
      'childSurnameAtBirth': serializer.toJson<String?>(childSurnameAtBirth),
      'paternalRelationship': serializer.toJson<String?>(paternalRelationship),
      'maternalRelationship': serializer.toJson<String?>(maternalRelationship),
      'notes': serializer.toJson<String?>(notes),
      'isDeleted': serializer.toJson<bool>(isDeleted),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  FamilyChildrenV2Data copyWith({
    String? id,
    String? familyId,
    String? childId,
    Value<int?> birthOrder = const Value.absent(),
    String? relationshipType,
    Value<String?> childSurnameAtBirth = const Value.absent(),
    Value<String?> paternalRelationship = const Value.absent(),
    Value<String?> maternalRelationship = const Value.absent(),
    Value<String?> notes = const Value.absent(),
    bool? isDeleted,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => FamilyChildrenV2Data(
    id: id ?? this.id,
    familyId: familyId ?? this.familyId,
    childId: childId ?? this.childId,
    birthOrder: birthOrder.present ? birthOrder.value : this.birthOrder,
    relationshipType: relationshipType ?? this.relationshipType,
    childSurnameAtBirth: childSurnameAtBirth.present
        ? childSurnameAtBirth.value
        : this.childSurnameAtBirth,
    paternalRelationship: paternalRelationship.present
        ? paternalRelationship.value
        : this.paternalRelationship,
    maternalRelationship: maternalRelationship.present
        ? maternalRelationship.value
        : this.maternalRelationship,
    notes: notes.present ? notes.value : this.notes,
    isDeleted: isDeleted ?? this.isDeleted,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  FamilyChildrenV2Data copyWithCompanion(FamilyChildrenV2Companion data) {
    return FamilyChildrenV2Data(
      id: data.id.present ? data.id.value : this.id,
      familyId: data.familyId.present ? data.familyId.value : this.familyId,
      childId: data.childId.present ? data.childId.value : this.childId,
      birthOrder: data.birthOrder.present
          ? data.birthOrder.value
          : this.birthOrder,
      relationshipType: data.relationshipType.present
          ? data.relationshipType.value
          : this.relationshipType,
      childSurnameAtBirth: data.childSurnameAtBirth.present
          ? data.childSurnameAtBirth.value
          : this.childSurnameAtBirth,
      paternalRelationship: data.paternalRelationship.present
          ? data.paternalRelationship.value
          : this.paternalRelationship,
      maternalRelationship: data.maternalRelationship.present
          ? data.maternalRelationship.value
          : this.maternalRelationship,
      notes: data.notes.present ? data.notes.value : this.notes,
      isDeleted: data.isDeleted.present ? data.isDeleted.value : this.isDeleted,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('FamilyChildrenV2Data(')
          ..write('id: $id, ')
          ..write('familyId: $familyId, ')
          ..write('childId: $childId, ')
          ..write('birthOrder: $birthOrder, ')
          ..write('relationshipType: $relationshipType, ')
          ..write('childSurnameAtBirth: $childSurnameAtBirth, ')
          ..write('paternalRelationship: $paternalRelationship, ')
          ..write('maternalRelationship: $maternalRelationship, ')
          ..write('notes: $notes, ')
          ..write('isDeleted: $isDeleted, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    familyId,
    childId,
    birthOrder,
    relationshipType,
    childSurnameAtBirth,
    paternalRelationship,
    maternalRelationship,
    notes,
    isDeleted,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FamilyChildrenV2Data &&
          other.id == this.id &&
          other.familyId == this.familyId &&
          other.childId == this.childId &&
          other.birthOrder == this.birthOrder &&
          other.relationshipType == this.relationshipType &&
          other.childSurnameAtBirth == this.childSurnameAtBirth &&
          other.paternalRelationship == this.paternalRelationship &&
          other.maternalRelationship == this.maternalRelationship &&
          other.notes == this.notes &&
          other.isDeleted == this.isDeleted &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class FamilyChildrenV2Companion extends UpdateCompanion<FamilyChildrenV2Data> {
  final Value<String> id;
  final Value<String> familyId;
  final Value<String> childId;
  final Value<int?> birthOrder;
  final Value<String> relationshipType;
  final Value<String?> childSurnameAtBirth;
  final Value<String?> paternalRelationship;
  final Value<String?> maternalRelationship;
  final Value<String?> notes;
  final Value<bool> isDeleted;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const FamilyChildrenV2Companion({
    this.id = const Value.absent(),
    this.familyId = const Value.absent(),
    this.childId = const Value.absent(),
    this.birthOrder = const Value.absent(),
    this.relationshipType = const Value.absent(),
    this.childSurnameAtBirth = const Value.absent(),
    this.paternalRelationship = const Value.absent(),
    this.maternalRelationship = const Value.absent(),
    this.notes = const Value.absent(),
    this.isDeleted = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  FamilyChildrenV2Companion.insert({
    required String id,
    required String familyId,
    required String childId,
    this.birthOrder = const Value.absent(),
    this.relationshipType = const Value.absent(),
    this.childSurnameAtBirth = const Value.absent(),
    this.paternalRelationship = const Value.absent(),
    this.maternalRelationship = const Value.absent(),
    this.notes = const Value.absent(),
    this.isDeleted = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       familyId = Value(familyId),
       childId = Value(childId);
  static Insertable<FamilyChildrenV2Data> custom({
    Expression<String>? id,
    Expression<String>? familyId,
    Expression<String>? childId,
    Expression<int>? birthOrder,
    Expression<String>? relationshipType,
    Expression<String>? childSurnameAtBirth,
    Expression<String>? paternalRelationship,
    Expression<String>? maternalRelationship,
    Expression<String>? notes,
    Expression<bool>? isDeleted,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (familyId != null) 'family_id': familyId,
      if (childId != null) 'child_id': childId,
      if (birthOrder != null) 'birth_order': birthOrder,
      if (relationshipType != null) 'relationship_type': relationshipType,
      if (childSurnameAtBirth != null)
        'child_surname_at_birth': childSurnameAtBirth,
      if (paternalRelationship != null)
        'paternal_relationship': paternalRelationship,
      if (maternalRelationship != null)
        'maternal_relationship': maternalRelationship,
      if (notes != null) 'notes': notes,
      if (isDeleted != null) 'is_deleted': isDeleted,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  FamilyChildrenV2Companion copyWith({
    Value<String>? id,
    Value<String>? familyId,
    Value<String>? childId,
    Value<int?>? birthOrder,
    Value<String>? relationshipType,
    Value<String?>? childSurnameAtBirth,
    Value<String?>? paternalRelationship,
    Value<String?>? maternalRelationship,
    Value<String?>? notes,
    Value<bool>? isDeleted,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return FamilyChildrenV2Companion(
      id: id ?? this.id,
      familyId: familyId ?? this.familyId,
      childId: childId ?? this.childId,
      birthOrder: birthOrder ?? this.birthOrder,
      relationshipType: relationshipType ?? this.relationshipType,
      childSurnameAtBirth: childSurnameAtBirth ?? this.childSurnameAtBirth,
      paternalRelationship: paternalRelationship ?? this.paternalRelationship,
      maternalRelationship: maternalRelationship ?? this.maternalRelationship,
      notes: notes ?? this.notes,
      isDeleted: isDeleted ?? this.isDeleted,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (familyId.present) {
      map['family_id'] = Variable<String>(familyId.value);
    }
    if (childId.present) {
      map['child_id'] = Variable<String>(childId.value);
    }
    if (birthOrder.present) {
      map['birth_order'] = Variable<int>(birthOrder.value);
    }
    if (relationshipType.present) {
      map['relationship_type'] = Variable<String>(relationshipType.value);
    }
    if (childSurnameAtBirth.present) {
      map['child_surname_at_birth'] = Variable<String>(
        childSurnameAtBirth.value,
      );
    }
    if (paternalRelationship.present) {
      map['paternal_relationship'] = Variable<String>(
        paternalRelationship.value,
      );
    }
    if (maternalRelationship.present) {
      map['maternal_relationship'] = Variable<String>(
        maternalRelationship.value,
      );
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (isDeleted.present) {
      map['is_deleted'] = Variable<bool>(isDeleted.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FamilyChildrenV2Companion(')
          ..write('id: $id, ')
          ..write('familyId: $familyId, ')
          ..write('childId: $childId, ')
          ..write('birthOrder: $birthOrder, ')
          ..write('relationshipType: $relationshipType, ')
          ..write('childSurnameAtBirth: $childSurnameAtBirth, ')
          ..write('paternalRelationship: $paternalRelationship, ')
          ..write('maternalRelationship: $maternalRelationship, ')
          ..write('notes: $notes, ')
          ..write('isDeleted: $isDeleted, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $MediaItemsTable extends MediaItems
    with TableInfo<$MediaItemsTable, MediaItem> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MediaItemsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _personIdMeta = const VerificationMeta(
    'personId',
  );
  @override
  late final GeneratedColumn<String> personId = GeneratedColumn<String>(
    'person_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES genealogy_persons (id) ON DELETE RESTRICT',
    ),
  );
  static const VerificationMeta _filePathMeta = const VerificationMeta(
    'filePath',
  );
  @override
  late final GeneratedColumn<String> filePath = GeneratedColumn<String>(
    'file_path',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _mediaTypeMeta = const VerificationMeta(
    'mediaType',
  );
  @override
  late final GeneratedColumn<String> mediaType = GeneratedColumn<String>(
    'media_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    personId,
    filePath,
    mediaType,
    title,
    description,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'media_items';
  @override
  VerificationContext validateIntegrity(
    Insertable<MediaItem> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('person_id')) {
      context.handle(
        _personIdMeta,
        personId.isAcceptableOrUnknown(data['person_id']!, _personIdMeta),
      );
    } else if (isInserting) {
      context.missing(_personIdMeta);
    }
    if (data.containsKey('file_path')) {
      context.handle(
        _filePathMeta,
        filePath.isAcceptableOrUnknown(data['file_path']!, _filePathMeta),
      );
    } else if (isInserting) {
      context.missing(_filePathMeta);
    }
    if (data.containsKey('media_type')) {
      context.handle(
        _mediaTypeMeta,
        mediaType.isAcceptableOrUnknown(data['media_type']!, _mediaTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_mediaTypeMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  MediaItem map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MediaItem(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      personId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}person_id'],
      )!,
      filePath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}file_path'],
      )!,
      mediaType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}media_type'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      ),
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $MediaItemsTable createAlias(String alias) {
    return $MediaItemsTable(attachedDatabase, alias);
  }
}

class MediaItem extends DataClass implements Insertable<MediaItem> {
  final String id;
  final String personId;
  final String filePath;

  /// photo / document / audio / video
  final String mediaType;
  final String? title;
  final String? description;
  final DateTime createdAt;
  const MediaItem({
    required this.id,
    required this.personId,
    required this.filePath,
    required this.mediaType,
    this.title,
    this.description,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['person_id'] = Variable<String>(personId);
    map['file_path'] = Variable<String>(filePath);
    map['media_type'] = Variable<String>(mediaType);
    if (!nullToAbsent || title != null) {
      map['title'] = Variable<String>(title);
    }
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  MediaItemsCompanion toCompanion(bool nullToAbsent) {
    return MediaItemsCompanion(
      id: Value(id),
      personId: Value(personId),
      filePath: Value(filePath),
      mediaType: Value(mediaType),
      title: title == null && nullToAbsent
          ? const Value.absent()
          : Value(title),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      createdAt: Value(createdAt),
    );
  }

  factory MediaItem.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MediaItem(
      id: serializer.fromJson<String>(json['id']),
      personId: serializer.fromJson<String>(json['personId']),
      filePath: serializer.fromJson<String>(json['filePath']),
      mediaType: serializer.fromJson<String>(json['mediaType']),
      title: serializer.fromJson<String?>(json['title']),
      description: serializer.fromJson<String?>(json['description']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'personId': serializer.toJson<String>(personId),
      'filePath': serializer.toJson<String>(filePath),
      'mediaType': serializer.toJson<String>(mediaType),
      'title': serializer.toJson<String?>(title),
      'description': serializer.toJson<String?>(description),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  MediaItem copyWith({
    String? id,
    String? personId,
    String? filePath,
    String? mediaType,
    Value<String?> title = const Value.absent(),
    Value<String?> description = const Value.absent(),
    DateTime? createdAt,
  }) => MediaItem(
    id: id ?? this.id,
    personId: personId ?? this.personId,
    filePath: filePath ?? this.filePath,
    mediaType: mediaType ?? this.mediaType,
    title: title.present ? title.value : this.title,
    description: description.present ? description.value : this.description,
    createdAt: createdAt ?? this.createdAt,
  );
  MediaItem copyWithCompanion(MediaItemsCompanion data) {
    return MediaItem(
      id: data.id.present ? data.id.value : this.id,
      personId: data.personId.present ? data.personId.value : this.personId,
      filePath: data.filePath.present ? data.filePath.value : this.filePath,
      mediaType: data.mediaType.present ? data.mediaType.value : this.mediaType,
      title: data.title.present ? data.title.value : this.title,
      description: data.description.present
          ? data.description.value
          : this.description,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MediaItem(')
          ..write('id: $id, ')
          ..write('personId: $personId, ')
          ..write('filePath: $filePath, ')
          ..write('mediaType: $mediaType, ')
          ..write('title: $title, ')
          ..write('description: $description, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    personId,
    filePath,
    mediaType,
    title,
    description,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MediaItem &&
          other.id == this.id &&
          other.personId == this.personId &&
          other.filePath == this.filePath &&
          other.mediaType == this.mediaType &&
          other.title == this.title &&
          other.description == this.description &&
          other.createdAt == this.createdAt);
}

class MediaItemsCompanion extends UpdateCompanion<MediaItem> {
  final Value<String> id;
  final Value<String> personId;
  final Value<String> filePath;
  final Value<String> mediaType;
  final Value<String?> title;
  final Value<String?> description;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const MediaItemsCompanion({
    this.id = const Value.absent(),
    this.personId = const Value.absent(),
    this.filePath = const Value.absent(),
    this.mediaType = const Value.absent(),
    this.title = const Value.absent(),
    this.description = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MediaItemsCompanion.insert({
    required String id,
    required String personId,
    required String filePath,
    required String mediaType,
    this.title = const Value.absent(),
    this.description = const Value.absent(),
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       personId = Value(personId),
       filePath = Value(filePath),
       mediaType = Value(mediaType),
       createdAt = Value(createdAt);
  static Insertable<MediaItem> custom({
    Expression<String>? id,
    Expression<String>? personId,
    Expression<String>? filePath,
    Expression<String>? mediaType,
    Expression<String>? title,
    Expression<String>? description,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (personId != null) 'person_id': personId,
      if (filePath != null) 'file_path': filePath,
      if (mediaType != null) 'media_type': mediaType,
      if (title != null) 'title': title,
      if (description != null) 'description': description,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MediaItemsCompanion copyWith({
    Value<String>? id,
    Value<String>? personId,
    Value<String>? filePath,
    Value<String>? mediaType,
    Value<String?>? title,
    Value<String?>? description,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return MediaItemsCompanion(
      id: id ?? this.id,
      personId: personId ?? this.personId,
      filePath: filePath ?? this.filePath,
      mediaType: mediaType ?? this.mediaType,
      title: title ?? this.title,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (personId.present) {
      map['person_id'] = Variable<String>(personId.value);
    }
    if (filePath.present) {
      map['file_path'] = Variable<String>(filePath.value);
    }
    if (mediaType.present) {
      map['media_type'] = Variable<String>(mediaType.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MediaItemsCompanion(')
          ..write('id: $id, ')
          ..write('personId: $personId, ')
          ..write('filePath: $filePath, ')
          ..write('mediaType: $mediaType, ')
          ..write('title: $title, ')
          ..write('description: $description, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $DuplicateMarkersTable extends DuplicateMarkers
    with TableInfo<$DuplicateMarkersTable, DuplicateMarker> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DuplicateMarkersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _personAIdMeta = const VerificationMeta(
    'personAId',
  );
  @override
  late final GeneratedColumn<String> personAId = GeneratedColumn<String>(
    'person_a_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES genealogy_persons (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _personBIdMeta = const VerificationMeta(
    'personBId',
  );
  @override
  late final GeneratedColumn<String> personBId = GeneratedColumn<String>(
    'person_b_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES genealogy_persons (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _reasonMeta = const VerificationMeta('reason');
  @override
  late final GeneratedColumn<String> reason = GeneratedColumn<String>(
    'reason',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    personAId,
    personBId,
    reason,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'duplicate_markers';
  @override
  VerificationContext validateIntegrity(
    Insertable<DuplicateMarker> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('person_a_id')) {
      context.handle(
        _personAIdMeta,
        personAId.isAcceptableOrUnknown(data['person_a_id']!, _personAIdMeta),
      );
    } else if (isInserting) {
      context.missing(_personAIdMeta);
    }
    if (data.containsKey('person_b_id')) {
      context.handle(
        _personBIdMeta,
        personBId.isAcceptableOrUnknown(data['person_b_id']!, _personBIdMeta),
      );
    } else if (isInserting) {
      context.missing(_personBIdMeta);
    }
    if (data.containsKey('reason')) {
      context.handle(
        _reasonMeta,
        reason.isAcceptableOrUnknown(data['reason']!, _reasonMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  DuplicateMarker map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DuplicateMarker(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      personAId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}person_a_id'],
      )!,
      personBId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}person_b_id'],
      )!,
      reason: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}reason'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $DuplicateMarkersTable createAlias(String alias) {
    return $DuplicateMarkersTable(attachedDatabase, alias);
  }
}

class DuplicateMarker extends DataClass implements Insertable<DuplicateMarker> {
  final String id;
  final String personAId;
  final String personBId;
  final String? reason;
  final DateTime createdAt;
  const DuplicateMarker({
    required this.id,
    required this.personAId,
    required this.personBId,
    this.reason,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['person_a_id'] = Variable<String>(personAId);
    map['person_b_id'] = Variable<String>(personBId);
    if (!nullToAbsent || reason != null) {
      map['reason'] = Variable<String>(reason);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  DuplicateMarkersCompanion toCompanion(bool nullToAbsent) {
    return DuplicateMarkersCompanion(
      id: Value(id),
      personAId: Value(personAId),
      personBId: Value(personBId),
      reason: reason == null && nullToAbsent
          ? const Value.absent()
          : Value(reason),
      createdAt: Value(createdAt),
    );
  }

  factory DuplicateMarker.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DuplicateMarker(
      id: serializer.fromJson<String>(json['id']),
      personAId: serializer.fromJson<String>(json['personAId']),
      personBId: serializer.fromJson<String>(json['personBId']),
      reason: serializer.fromJson<String?>(json['reason']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'personAId': serializer.toJson<String>(personAId),
      'personBId': serializer.toJson<String>(personBId),
      'reason': serializer.toJson<String?>(reason),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  DuplicateMarker copyWith({
    String? id,
    String? personAId,
    String? personBId,
    Value<String?> reason = const Value.absent(),
    DateTime? createdAt,
  }) => DuplicateMarker(
    id: id ?? this.id,
    personAId: personAId ?? this.personAId,
    personBId: personBId ?? this.personBId,
    reason: reason.present ? reason.value : this.reason,
    createdAt: createdAt ?? this.createdAt,
  );
  DuplicateMarker copyWithCompanion(DuplicateMarkersCompanion data) {
    return DuplicateMarker(
      id: data.id.present ? data.id.value : this.id,
      personAId: data.personAId.present ? data.personAId.value : this.personAId,
      personBId: data.personBId.present ? data.personBId.value : this.personBId,
      reason: data.reason.present ? data.reason.value : this.reason,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DuplicateMarker(')
          ..write('id: $id, ')
          ..write('personAId: $personAId, ')
          ..write('personBId: $personBId, ')
          ..write('reason: $reason, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, personAId, personBId, reason, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DuplicateMarker &&
          other.id == this.id &&
          other.personAId == this.personAId &&
          other.personBId == this.personBId &&
          other.reason == this.reason &&
          other.createdAt == this.createdAt);
}

class DuplicateMarkersCompanion extends UpdateCompanion<DuplicateMarker> {
  final Value<String> id;
  final Value<String> personAId;
  final Value<String> personBId;
  final Value<String?> reason;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const DuplicateMarkersCompanion({
    this.id = const Value.absent(),
    this.personAId = const Value.absent(),
    this.personBId = const Value.absent(),
    this.reason = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DuplicateMarkersCompanion.insert({
    required String id,
    required String personAId,
    required String personBId,
    this.reason = const Value.absent(),
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       personAId = Value(personAId),
       personBId = Value(personBId),
       createdAt = Value(createdAt);
  static Insertable<DuplicateMarker> custom({
    Expression<String>? id,
    Expression<String>? personAId,
    Expression<String>? personBId,
    Expression<String>? reason,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (personAId != null) 'person_a_id': personAId,
      if (personBId != null) 'person_b_id': personBId,
      if (reason != null) 'reason': reason,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DuplicateMarkersCompanion copyWith({
    Value<String>? id,
    Value<String>? personAId,
    Value<String>? personBId,
    Value<String?>? reason,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return DuplicateMarkersCompanion(
      id: id ?? this.id,
      personAId: personAId ?? this.personAId,
      personBId: personBId ?? this.personBId,
      reason: reason ?? this.reason,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (personAId.present) {
      map['person_a_id'] = Variable<String>(personAId.value);
    }
    if (personBId.present) {
      map['person_b_id'] = Variable<String>(personBId.value);
    }
    if (reason.present) {
      map['reason'] = Variable<String>(reason.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DuplicateMarkersCompanion(')
          ..write('id: $id, ')
          ..write('personAId: $personAId, ')
          ..write('personBId: $personBId, ')
          ..write('reason: $reason, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ResearchNotesTable extends ResearchNotes
    with TableInfo<$ResearchNotesTable, ResearchNote> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ResearchNotesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _personIdMeta = const VerificationMeta(
    'personId',
  );
  @override
  late final GeneratedColumn<String> personId = GeneratedColumn<String>(
    'person_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES genealogy_persons (id) ON DELETE RESTRICT',
    ),
  );
  static const VerificationMeta _noteTextMeta = const VerificationMeta(
    'noteText',
  );
  @override
  late final GeneratedColumn<String> noteText = GeneratedColumn<String>(
    'note_text',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _researchQuestionMeta = const VerificationMeta(
    'researchQuestion',
  );
  @override
  late final GeneratedColumn<String> researchQuestion = GeneratedColumn<String>(
    'research_question',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _noteDateSortMeta = const VerificationMeta(
    'noteDateSort',
  );
  @override
  late final GeneratedColumn<double> noteDateSort = GeneratedColumn<double>(
    'note_date_sort',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _noteDateDisplayMeta = const VerificationMeta(
    'noteDateDisplay',
  );
  @override
  late final GeneratedColumn<String> noteDateDisplay = GeneratedColumn<String>(
    'note_date_display',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _resolvedMeta = const VerificationMeta(
    'resolved',
  );
  @override
  late final GeneratedColumn<bool> resolved = GeneratedColumn<bool>(
    'resolved',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("resolved" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    personId,
    noteText,
    researchQuestion,
    noteDateSort,
    noteDateDisplay,
    resolved,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'research_notes';
  @override
  VerificationContext validateIntegrity(
    Insertable<ResearchNote> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('person_id')) {
      context.handle(
        _personIdMeta,
        personId.isAcceptableOrUnknown(data['person_id']!, _personIdMeta),
      );
    }
    if (data.containsKey('note_text')) {
      context.handle(
        _noteTextMeta,
        noteText.isAcceptableOrUnknown(data['note_text']!, _noteTextMeta),
      );
    } else if (isInserting) {
      context.missing(_noteTextMeta);
    }
    if (data.containsKey('research_question')) {
      context.handle(
        _researchQuestionMeta,
        researchQuestion.isAcceptableOrUnknown(
          data['research_question']!,
          _researchQuestionMeta,
        ),
      );
    }
    if (data.containsKey('note_date_sort')) {
      context.handle(
        _noteDateSortMeta,
        noteDateSort.isAcceptableOrUnknown(
          data['note_date_sort']!,
          _noteDateSortMeta,
        ),
      );
    }
    if (data.containsKey('note_date_display')) {
      context.handle(
        _noteDateDisplayMeta,
        noteDateDisplay.isAcceptableOrUnknown(
          data['note_date_display']!,
          _noteDateDisplayMeta,
        ),
      );
    }
    if (data.containsKey('resolved')) {
      context.handle(
        _resolvedMeta,
        resolved.isAcceptableOrUnknown(data['resolved']!, _resolvedMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ResearchNote map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ResearchNote(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      personId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}person_id'],
      ),
      noteText: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note_text'],
      )!,
      researchQuestion: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}research_question'],
      ),
      noteDateSort: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}note_date_sort'],
      ),
      noteDateDisplay: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note_date_display'],
      ),
      resolved: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}resolved'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $ResearchNotesTable createAlias(String alias) {
    return $ResearchNotesTable(attachedDatabase, alias);
  }
}

class ResearchNote extends DataClass implements Insertable<ResearchNote> {
  final String id;
  final String? personId;
  final String noteText;
  final String? researchQuestion;
  final double? noteDateSort;
  final String? noteDateDisplay;
  final bool resolved;
  final DateTime createdAt;
  const ResearchNote({
    required this.id,
    this.personId,
    required this.noteText,
    this.researchQuestion,
    this.noteDateSort,
    this.noteDateDisplay,
    required this.resolved,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    if (!nullToAbsent || personId != null) {
      map['person_id'] = Variable<String>(personId);
    }
    map['note_text'] = Variable<String>(noteText);
    if (!nullToAbsent || researchQuestion != null) {
      map['research_question'] = Variable<String>(researchQuestion);
    }
    if (!nullToAbsent || noteDateSort != null) {
      map['note_date_sort'] = Variable<double>(noteDateSort);
    }
    if (!nullToAbsent || noteDateDisplay != null) {
      map['note_date_display'] = Variable<String>(noteDateDisplay);
    }
    map['resolved'] = Variable<bool>(resolved);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  ResearchNotesCompanion toCompanion(bool nullToAbsent) {
    return ResearchNotesCompanion(
      id: Value(id),
      personId: personId == null && nullToAbsent
          ? const Value.absent()
          : Value(personId),
      noteText: Value(noteText),
      researchQuestion: researchQuestion == null && nullToAbsent
          ? const Value.absent()
          : Value(researchQuestion),
      noteDateSort: noteDateSort == null && nullToAbsent
          ? const Value.absent()
          : Value(noteDateSort),
      noteDateDisplay: noteDateDisplay == null && nullToAbsent
          ? const Value.absent()
          : Value(noteDateDisplay),
      resolved: Value(resolved),
      createdAt: Value(createdAt),
    );
  }

  factory ResearchNote.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ResearchNote(
      id: serializer.fromJson<String>(json['id']),
      personId: serializer.fromJson<String?>(json['personId']),
      noteText: serializer.fromJson<String>(json['noteText']),
      researchQuestion: serializer.fromJson<String?>(json['researchQuestion']),
      noteDateSort: serializer.fromJson<double?>(json['noteDateSort']),
      noteDateDisplay: serializer.fromJson<String?>(json['noteDateDisplay']),
      resolved: serializer.fromJson<bool>(json['resolved']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'personId': serializer.toJson<String?>(personId),
      'noteText': serializer.toJson<String>(noteText),
      'researchQuestion': serializer.toJson<String?>(researchQuestion),
      'noteDateSort': serializer.toJson<double?>(noteDateSort),
      'noteDateDisplay': serializer.toJson<String?>(noteDateDisplay),
      'resolved': serializer.toJson<bool>(resolved),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  ResearchNote copyWith({
    String? id,
    Value<String?> personId = const Value.absent(),
    String? noteText,
    Value<String?> researchQuestion = const Value.absent(),
    Value<double?> noteDateSort = const Value.absent(),
    Value<String?> noteDateDisplay = const Value.absent(),
    bool? resolved,
    DateTime? createdAt,
  }) => ResearchNote(
    id: id ?? this.id,
    personId: personId.present ? personId.value : this.personId,
    noteText: noteText ?? this.noteText,
    researchQuestion: researchQuestion.present
        ? researchQuestion.value
        : this.researchQuestion,
    noteDateSort: noteDateSort.present ? noteDateSort.value : this.noteDateSort,
    noteDateDisplay: noteDateDisplay.present
        ? noteDateDisplay.value
        : this.noteDateDisplay,
    resolved: resolved ?? this.resolved,
    createdAt: createdAt ?? this.createdAt,
  );
  ResearchNote copyWithCompanion(ResearchNotesCompanion data) {
    return ResearchNote(
      id: data.id.present ? data.id.value : this.id,
      personId: data.personId.present ? data.personId.value : this.personId,
      noteText: data.noteText.present ? data.noteText.value : this.noteText,
      researchQuestion: data.researchQuestion.present
          ? data.researchQuestion.value
          : this.researchQuestion,
      noteDateSort: data.noteDateSort.present
          ? data.noteDateSort.value
          : this.noteDateSort,
      noteDateDisplay: data.noteDateDisplay.present
          ? data.noteDateDisplay.value
          : this.noteDateDisplay,
      resolved: data.resolved.present ? data.resolved.value : this.resolved,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ResearchNote(')
          ..write('id: $id, ')
          ..write('personId: $personId, ')
          ..write('noteText: $noteText, ')
          ..write('researchQuestion: $researchQuestion, ')
          ..write('noteDateSort: $noteDateSort, ')
          ..write('noteDateDisplay: $noteDateDisplay, ')
          ..write('resolved: $resolved, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    personId,
    noteText,
    researchQuestion,
    noteDateSort,
    noteDateDisplay,
    resolved,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ResearchNote &&
          other.id == this.id &&
          other.personId == this.personId &&
          other.noteText == this.noteText &&
          other.researchQuestion == this.researchQuestion &&
          other.noteDateSort == this.noteDateSort &&
          other.noteDateDisplay == this.noteDateDisplay &&
          other.resolved == this.resolved &&
          other.createdAt == this.createdAt);
}

class ResearchNotesCompanion extends UpdateCompanion<ResearchNote> {
  final Value<String> id;
  final Value<String?> personId;
  final Value<String> noteText;
  final Value<String?> researchQuestion;
  final Value<double?> noteDateSort;
  final Value<String?> noteDateDisplay;
  final Value<bool> resolved;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const ResearchNotesCompanion({
    this.id = const Value.absent(),
    this.personId = const Value.absent(),
    this.noteText = const Value.absent(),
    this.researchQuestion = const Value.absent(),
    this.noteDateSort = const Value.absent(),
    this.noteDateDisplay = const Value.absent(),
    this.resolved = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ResearchNotesCompanion.insert({
    required String id,
    this.personId = const Value.absent(),
    required String noteText,
    this.researchQuestion = const Value.absent(),
    this.noteDateSort = const Value.absent(),
    this.noteDateDisplay = const Value.absent(),
    this.resolved = const Value.absent(),
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       noteText = Value(noteText),
       createdAt = Value(createdAt);
  static Insertable<ResearchNote> custom({
    Expression<String>? id,
    Expression<String>? personId,
    Expression<String>? noteText,
    Expression<String>? researchQuestion,
    Expression<double>? noteDateSort,
    Expression<String>? noteDateDisplay,
    Expression<bool>? resolved,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (personId != null) 'person_id': personId,
      if (noteText != null) 'note_text': noteText,
      if (researchQuestion != null) 'research_question': researchQuestion,
      if (noteDateSort != null) 'note_date_sort': noteDateSort,
      if (noteDateDisplay != null) 'note_date_display': noteDateDisplay,
      if (resolved != null) 'resolved': resolved,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ResearchNotesCompanion copyWith({
    Value<String>? id,
    Value<String?>? personId,
    Value<String>? noteText,
    Value<String?>? researchQuestion,
    Value<double?>? noteDateSort,
    Value<String?>? noteDateDisplay,
    Value<bool>? resolved,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return ResearchNotesCompanion(
      id: id ?? this.id,
      personId: personId ?? this.personId,
      noteText: noteText ?? this.noteText,
      researchQuestion: researchQuestion ?? this.researchQuestion,
      noteDateSort: noteDateSort ?? this.noteDateSort,
      noteDateDisplay: noteDateDisplay ?? this.noteDateDisplay,
      resolved: resolved ?? this.resolved,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (personId.present) {
      map['person_id'] = Variable<String>(personId.value);
    }
    if (noteText.present) {
      map['note_text'] = Variable<String>(noteText.value);
    }
    if (researchQuestion.present) {
      map['research_question'] = Variable<String>(researchQuestion.value);
    }
    if (noteDateSort.present) {
      map['note_date_sort'] = Variable<double>(noteDateSort.value);
    }
    if (noteDateDisplay.present) {
      map['note_date_display'] = Variable<String>(noteDateDisplay.value);
    }
    if (resolved.present) {
      map['resolved'] = Variable<bool>(resolved.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ResearchNotesCompanion(')
          ..write('id: $id, ')
          ..write('personId: $personId, ')
          ..write('noteText: $noteText, ')
          ..write('researchQuestion: $researchQuestion, ')
          ..write('noteDateSort: $noteDateSort, ')
          ..write('noteDateDisplay: $noteDateDisplay, ')
          ..write('resolved: $resolved, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $GenealogyPersonsTable genealogyPersons = $GenealogyPersonsTable(
    this,
  );
  late final $FamilyTreesTable familyTrees = $FamilyTreesTable(this);
  late final $EventsTable events = $EventsTable(this);
  late final $SurnameEventsTable surnameEvents = $SurnameEventsTable(this);
  late final $FamiliesV2Table familiesV2 = $FamiliesV2Table(this);
  late final $FamilyChildrenV2Table familyChildrenV2 = $FamilyChildrenV2Table(
    this,
  );
  late final $MediaItemsTable mediaItems = $MediaItemsTable(this);
  late final $DuplicateMarkersTable duplicateMarkers = $DuplicateMarkersTable(
    this,
  );
  late final $ResearchNotesTable researchNotes = $ResearchNotesTable(this);
  late final Index idxFamilyTreesRootPerson = Index(
    'idx_family_trees_root_person',
    'CREATE INDEX idx_family_trees_root_person ON family_trees (root_person_id)',
  );
  late final Index idxGenealogyPersonsTreeId = Index(
    'idx_genealogy_persons_tree_id',
    'CREATE INDEX idx_genealogy_persons_tree_id ON genealogy_persons (tree_id)',
  );
  late final Index idxGenealogyPersonsMergedInto = Index(
    'idx_genealogy_persons_merged_into',
    'CREATE INDEX idx_genealogy_persons_merged_into ON genealogy_persons (merged_into_id)',
  );
  late final Index idxSurnameEventsPersonId = Index(
    'idx_surname_events_person_id',
    'CREATE INDEX idx_surname_events_person_id ON surname_events (person_id)',
  );
  late final Index idxSurnameEventsRelatedPersonId = Index(
    'idx_surname_events_related_person_id',
    'CREATE INDEX idx_surname_events_related_person_id ON surname_events (related_person_id)',
  );
  late final Index idxSurnameEventsRelatedEventId = Index(
    'idx_surname_events_related_event_id',
    'CREATE INDEX idx_surname_events_related_event_id ON surname_events (related_event_id)',
  );
  late final Index idxFamiliesV2TreeId = Index(
    'idx_families_v2_tree_id',
    'CREATE INDEX idx_families_v2_tree_id ON families_v2 (tree_id)',
  );
  late final Index idxFamiliesV2HusbandId = Index(
    'idx_families_v2_husband_id',
    'CREATE INDEX idx_families_v2_husband_id ON families_v2 (husband_id)',
  );
  late final Index idxFamiliesV2WifeId = Index(
    'idx_families_v2_wife_id',
    'CREATE INDEX idx_families_v2_wife_id ON families_v2 (wife_id)',
  );
  late final Index idxFamilyChildrenV2ChildId = Index(
    'idx_family_children_v2_child_id',
    'CREATE INDEX idx_family_children_v2_child_id ON family_children_v2 (child_id)',
  );
  late final Index idxMediaItemsPersonId = Index(
    'idx_media_items_person_id',
    'CREATE INDEX idx_media_items_person_id ON media_items (person_id)',
  );
  late final Index idxEventsPersonId = Index(
    'idx_events_person_id',
    'CREATE INDEX idx_events_person_id ON events (person_id)',
  );
  late final Index idxDuplicateMarkersPersonB = Index(
    'idx_duplicate_markers_person_b',
    'CREATE INDEX idx_duplicate_markers_person_b ON duplicate_markers (person_b_id)',
  );
  late final Index idxResearchNotesPersonId = Index(
    'idx_research_notes_person_id',
    'CREATE INDEX idx_research_notes_person_id ON research_notes (person_id)',
  );
  late final GenealogyPersonDao genealogyPersonDao = GenealogyPersonDao(
    this as AppDatabase,
  );
  late final EventsDao eventsDao = EventsDao(this as AppDatabase);
  late final ResearchNotesDao researchNotesDao = ResearchNotesDao(
    this as AppDatabase,
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    genealogyPersons,
    familyTrees,
    events,
    surnameEvents,
    familiesV2,
    familyChildrenV2,
    mediaItems,
    duplicateMarkers,
    researchNotes,
    idxFamilyTreesRootPerson,
    idxGenealogyPersonsTreeId,
    idxGenealogyPersonsMergedInto,
    idxSurnameEventsPersonId,
    idxSurnameEventsRelatedPersonId,
    idxSurnameEventsRelatedEventId,
    idxFamiliesV2TreeId,
    idxFamiliesV2HusbandId,
    idxFamiliesV2WifeId,
    idxFamilyChildrenV2ChildId,
    idxMediaItemsPersonId,
    idxEventsPersonId,
    idxDuplicateMarkersPersonB,
    idxResearchNotesPersonId,
  ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'genealogy_persons',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('genealogy_persons', kind: UpdateKind.update)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'genealogy_persons',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('family_trees', kind: UpdateKind.update)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'genealogy_persons',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('surname_events', kind: UpdateKind.update)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'events',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('surname_events', kind: UpdateKind.update)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'genealogy_persons',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('duplicate_markers', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'genealogy_persons',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('duplicate_markers', kind: UpdateKind.delete)],
    ),
  ]);
}

typedef $$GenealogyPersonsTableCreateCompanionBuilder =
    GenealogyPersonsCompanion Function({
      required String id,
      required String firstName,
      Value<String?> middleName,
      Value<String?> lastName,
      Value<String?> birthSurname,
      Value<String?> marriedSurname,
      Value<String?> suffix,
      Value<String?> prefix,
      Value<String?> nickname,
      Value<String> displayNameFormat,
      Value<String?> customDisplayName,
      required String gender,
      Value<DateTime?> birthDate,
      Value<String?> birthDateQualifier,
      Value<String?> birthPlace,
      Value<double?> birthPlaceLat,
      Value<double?> birthPlaceLng,
      Value<DateTime?> deathDate,
      Value<String?> deathDateQualifier,
      Value<String?> deathPlace,
      Value<double?> deathPlaceLat,
      Value<double?> deathPlaceLng,
      Value<String?> currentPlace,
      Value<bool> isLiving,
      Value<String?> profilePhotoPath,
      Value<String?> biography,
      Value<String?> notes,
      Value<String?> occupation,
      Value<String?> religion,
      Value<String?> ethnicity,
      Value<bool> isPrivate,
      Value<int> privacyLevel,
      required String treeId,
      required String uuid,
      Value<bool> isDeleted,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<String?> mergedIntoId,
      Value<int> rowid,
    });
typedef $$GenealogyPersonsTableUpdateCompanionBuilder =
    GenealogyPersonsCompanion Function({
      Value<String> id,
      Value<String> firstName,
      Value<String?> middleName,
      Value<String?> lastName,
      Value<String?> birthSurname,
      Value<String?> marriedSurname,
      Value<String?> suffix,
      Value<String?> prefix,
      Value<String?> nickname,
      Value<String> displayNameFormat,
      Value<String?> customDisplayName,
      Value<String> gender,
      Value<DateTime?> birthDate,
      Value<String?> birthDateQualifier,
      Value<String?> birthPlace,
      Value<double?> birthPlaceLat,
      Value<double?> birthPlaceLng,
      Value<DateTime?> deathDate,
      Value<String?> deathDateQualifier,
      Value<String?> deathPlace,
      Value<double?> deathPlaceLat,
      Value<double?> deathPlaceLng,
      Value<String?> currentPlace,
      Value<bool> isLiving,
      Value<String?> profilePhotoPath,
      Value<String?> biography,
      Value<String?> notes,
      Value<String?> occupation,
      Value<String?> religion,
      Value<String?> ethnicity,
      Value<bool> isPrivate,
      Value<int> privacyLevel,
      Value<String> treeId,
      Value<String> uuid,
      Value<bool> isDeleted,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<String?> mergedIntoId,
      Value<int> rowid,
    });

final class $$GenealogyPersonsTableReferences
    extends
        BaseReferences<_$AppDatabase, $GenealogyPersonsTable, GenealogyPerson> {
  $$GenealogyPersonsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $GenealogyPersonsTable _mergedIntoIdTable(_$AppDatabase db) =>
      db.genealogyPersons.createAlias(
        $_aliasNameGenerator(
          db.genealogyPersons.mergedIntoId,
          db.genealogyPersons.id,
        ),
      );

  $$GenealogyPersonsTableProcessedTableManager? get mergedIntoId {
    final $_column = $_itemColumn<String>('merged_into_id');
    if ($_column == null) return null;
    final manager = $$GenealogyPersonsTableTableManager(
      $_db,
      $_db.genealogyPersons,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_mergedIntoIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$FamilyTreesTable, List<FamilyTree>>
  _rootOfTreesTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.familyTrees,
    aliasName: $_aliasNameGenerator(
      db.genealogyPersons.id,
      db.familyTrees.rootPersonId,
    ),
  );

  $$FamilyTreesTableProcessedTableManager get rootOfTrees {
    final manager = $$FamilyTreesTableTableManager(
      $_db,
      $_db.familyTrees,
    ).filter((f) => f.rootPersonId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_rootOfTreesTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$EventsTable, List<Event>> _eventsRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.events,
    aliasName: $_aliasNameGenerator(db.genealogyPersons.id, db.events.personId),
  );

  $$EventsTableProcessedTableManager get eventsRefs {
    final manager = $$EventsTableTableManager(
      $_db,
      $_db.events,
    ).filter((f) => f.personId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_eventsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$SurnameEventsTable, List<SurnameEvent>>
  _surnameEventsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.surnameEvents,
    aliasName: $_aliasNameGenerator(
      db.genealogyPersons.id,
      db.surnameEvents.personId,
    ),
  );

  $$SurnameEventsTableProcessedTableManager get surnameEventsRefs {
    final manager = $$SurnameEventsTableTableManager(
      $_db,
      $_db.surnameEvents,
    ).filter((f) => f.personId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_surnameEventsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$SurnameEventsTable, List<SurnameEvent>>
  _surnameEventsAboutTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.surnameEvents,
    aliasName: $_aliasNameGenerator(
      db.genealogyPersons.id,
      db.surnameEvents.relatedPersonId,
    ),
  );

  $$SurnameEventsTableProcessedTableManager get surnameEventsAbout {
    final manager = $$SurnameEventsTableTableManager($_db, $_db.surnameEvents)
        .filter(
          (f) => f.relatedPersonId.id.sqlEquals($_itemColumn<String>('id')!),
        );

    final cache = $_typedResult.readTableOrNull(_surnameEventsAboutTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$FamiliesV2Table, List<FamiliesV2Data>>
  _husbandFamiliesTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.familiesV2,
    aliasName: $_aliasNameGenerator(
      db.genealogyPersons.id,
      db.familiesV2.husbandId,
    ),
  );

  $$FamiliesV2TableProcessedTableManager get husbandFamilies {
    final manager = $$FamiliesV2TableTableManager(
      $_db,
      $_db.familiesV2,
    ).filter((f) => f.husbandId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_husbandFamiliesTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$FamiliesV2Table, List<FamiliesV2Data>>
  _wifeFamiliesTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.familiesV2,
    aliasName: $_aliasNameGenerator(
      db.genealogyPersons.id,
      db.familiesV2.wifeId,
    ),
  );

  $$FamiliesV2TableProcessedTableManager get wifeFamilies {
    final manager = $$FamiliesV2TableTableManager(
      $_db,
      $_db.familiesV2,
    ).filter((f) => f.wifeId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_wifeFamiliesTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$FamilyChildrenV2Table, List<FamilyChildrenV2Data>>
  _childFamilyLinksTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.familyChildrenV2,
    aliasName: $_aliasNameGenerator(
      db.genealogyPersons.id,
      db.familyChildrenV2.childId,
    ),
  );

  $$FamilyChildrenV2TableProcessedTableManager get childFamilyLinks {
    final manager = $$FamilyChildrenV2TableTableManager(
      $_db,
      $_db.familyChildrenV2,
    ).filter((f) => f.childId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_childFamilyLinksTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$MediaItemsTable, List<MediaItem>>
  _mediaItemsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.mediaItems,
    aliasName: $_aliasNameGenerator(
      db.genealogyPersons.id,
      db.mediaItems.personId,
    ),
  );

  $$MediaItemsTableProcessedTableManager get mediaItemsRefs {
    final manager = $$MediaItemsTableTableManager(
      $_db,
      $_db.mediaItems,
    ).filter((f) => f.personId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_mediaItemsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$ResearchNotesTable, List<ResearchNote>>
  _researchNotesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.researchNotes,
    aliasName: $_aliasNameGenerator(
      db.genealogyPersons.id,
      db.researchNotes.personId,
    ),
  );

  $$ResearchNotesTableProcessedTableManager get researchNotesRefs {
    final manager = $$ResearchNotesTableTableManager(
      $_db,
      $_db.researchNotes,
    ).filter((f) => f.personId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_researchNotesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$GenealogyPersonsTableFilterComposer
    extends Composer<_$AppDatabase, $GenealogyPersonsTable> {
  $$GenealogyPersonsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get firstName => $composableBuilder(
    column: $table.firstName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get middleName => $composableBuilder(
    column: $table.middleName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastName => $composableBuilder(
    column: $table.lastName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get birthSurname => $composableBuilder(
    column: $table.birthSurname,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get marriedSurname => $composableBuilder(
    column: $table.marriedSurname,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get suffix => $composableBuilder(
    column: $table.suffix,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get prefix => $composableBuilder(
    column: $table.prefix,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get nickname => $composableBuilder(
    column: $table.nickname,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get displayNameFormat => $composableBuilder(
    column: $table.displayNameFormat,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get customDisplayName => $composableBuilder(
    column: $table.customDisplayName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get gender => $composableBuilder(
    column: $table.gender,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get birthDate => $composableBuilder(
    column: $table.birthDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get birthDateQualifier => $composableBuilder(
    column: $table.birthDateQualifier,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get birthPlace => $composableBuilder(
    column: $table.birthPlace,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get birthPlaceLat => $composableBuilder(
    column: $table.birthPlaceLat,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get birthPlaceLng => $composableBuilder(
    column: $table.birthPlaceLng,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get deathDate => $composableBuilder(
    column: $table.deathDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get deathDateQualifier => $composableBuilder(
    column: $table.deathDateQualifier,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get deathPlace => $composableBuilder(
    column: $table.deathPlace,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get deathPlaceLat => $composableBuilder(
    column: $table.deathPlaceLat,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get deathPlaceLng => $composableBuilder(
    column: $table.deathPlaceLng,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get currentPlace => $composableBuilder(
    column: $table.currentPlace,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isLiving => $composableBuilder(
    column: $table.isLiving,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get profilePhotoPath => $composableBuilder(
    column: $table.profilePhotoPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get biography => $composableBuilder(
    column: $table.biography,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get occupation => $composableBuilder(
    column: $table.occupation,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get religion => $composableBuilder(
    column: $table.religion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get ethnicity => $composableBuilder(
    column: $table.ethnicity,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isPrivate => $composableBuilder(
    column: $table.isPrivate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get privacyLevel => $composableBuilder(
    column: $table.privacyLevel,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get treeId => $composableBuilder(
    column: $table.treeId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get uuid => $composableBuilder(
    column: $table.uuid,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isDeleted => $composableBuilder(
    column: $table.isDeleted,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$GenealogyPersonsTableFilterComposer get mergedIntoId {
    final $$GenealogyPersonsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.mergedIntoId,
      referencedTable: $db.genealogyPersons,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$GenealogyPersonsTableFilterComposer(
            $db: $db,
            $table: $db.genealogyPersons,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> rootOfTrees(
    Expression<bool> Function($$FamilyTreesTableFilterComposer f) f,
  ) {
    final $$FamilyTreesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.familyTrees,
      getReferencedColumn: (t) => t.rootPersonId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FamilyTreesTableFilterComposer(
            $db: $db,
            $table: $db.familyTrees,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> eventsRefs(
    Expression<bool> Function($$EventsTableFilterComposer f) f,
  ) {
    final $$EventsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.events,
      getReferencedColumn: (t) => t.personId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EventsTableFilterComposer(
            $db: $db,
            $table: $db.events,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> surnameEventsRefs(
    Expression<bool> Function($$SurnameEventsTableFilterComposer f) f,
  ) {
    final $$SurnameEventsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.surnameEvents,
      getReferencedColumn: (t) => t.personId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SurnameEventsTableFilterComposer(
            $db: $db,
            $table: $db.surnameEvents,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> surnameEventsAbout(
    Expression<bool> Function($$SurnameEventsTableFilterComposer f) f,
  ) {
    final $$SurnameEventsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.surnameEvents,
      getReferencedColumn: (t) => t.relatedPersonId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SurnameEventsTableFilterComposer(
            $db: $db,
            $table: $db.surnameEvents,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> husbandFamilies(
    Expression<bool> Function($$FamiliesV2TableFilterComposer f) f,
  ) {
    final $$FamiliesV2TableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.familiesV2,
      getReferencedColumn: (t) => t.husbandId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FamiliesV2TableFilterComposer(
            $db: $db,
            $table: $db.familiesV2,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> wifeFamilies(
    Expression<bool> Function($$FamiliesV2TableFilterComposer f) f,
  ) {
    final $$FamiliesV2TableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.familiesV2,
      getReferencedColumn: (t) => t.wifeId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FamiliesV2TableFilterComposer(
            $db: $db,
            $table: $db.familiesV2,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> childFamilyLinks(
    Expression<bool> Function($$FamilyChildrenV2TableFilterComposer f) f,
  ) {
    final $$FamilyChildrenV2TableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.familyChildrenV2,
      getReferencedColumn: (t) => t.childId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FamilyChildrenV2TableFilterComposer(
            $db: $db,
            $table: $db.familyChildrenV2,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> mediaItemsRefs(
    Expression<bool> Function($$MediaItemsTableFilterComposer f) f,
  ) {
    final $$MediaItemsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.mediaItems,
      getReferencedColumn: (t) => t.personId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MediaItemsTableFilterComposer(
            $db: $db,
            $table: $db.mediaItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> researchNotesRefs(
    Expression<bool> Function($$ResearchNotesTableFilterComposer f) f,
  ) {
    final $$ResearchNotesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.researchNotes,
      getReferencedColumn: (t) => t.personId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ResearchNotesTableFilterComposer(
            $db: $db,
            $table: $db.researchNotes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$GenealogyPersonsTableOrderingComposer
    extends Composer<_$AppDatabase, $GenealogyPersonsTable> {
  $$GenealogyPersonsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get firstName => $composableBuilder(
    column: $table.firstName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get middleName => $composableBuilder(
    column: $table.middleName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastName => $composableBuilder(
    column: $table.lastName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get birthSurname => $composableBuilder(
    column: $table.birthSurname,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get marriedSurname => $composableBuilder(
    column: $table.marriedSurname,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get suffix => $composableBuilder(
    column: $table.suffix,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get prefix => $composableBuilder(
    column: $table.prefix,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get nickname => $composableBuilder(
    column: $table.nickname,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get displayNameFormat => $composableBuilder(
    column: $table.displayNameFormat,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get customDisplayName => $composableBuilder(
    column: $table.customDisplayName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get gender => $composableBuilder(
    column: $table.gender,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get birthDate => $composableBuilder(
    column: $table.birthDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get birthDateQualifier => $composableBuilder(
    column: $table.birthDateQualifier,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get birthPlace => $composableBuilder(
    column: $table.birthPlace,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get birthPlaceLat => $composableBuilder(
    column: $table.birthPlaceLat,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get birthPlaceLng => $composableBuilder(
    column: $table.birthPlaceLng,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deathDate => $composableBuilder(
    column: $table.deathDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get deathDateQualifier => $composableBuilder(
    column: $table.deathDateQualifier,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get deathPlace => $composableBuilder(
    column: $table.deathPlace,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get deathPlaceLat => $composableBuilder(
    column: $table.deathPlaceLat,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get deathPlaceLng => $composableBuilder(
    column: $table.deathPlaceLng,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get currentPlace => $composableBuilder(
    column: $table.currentPlace,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isLiving => $composableBuilder(
    column: $table.isLiving,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get profilePhotoPath => $composableBuilder(
    column: $table.profilePhotoPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get biography => $composableBuilder(
    column: $table.biography,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get occupation => $composableBuilder(
    column: $table.occupation,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get religion => $composableBuilder(
    column: $table.religion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get ethnicity => $composableBuilder(
    column: $table.ethnicity,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isPrivate => $composableBuilder(
    column: $table.isPrivate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get privacyLevel => $composableBuilder(
    column: $table.privacyLevel,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get treeId => $composableBuilder(
    column: $table.treeId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get uuid => $composableBuilder(
    column: $table.uuid,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isDeleted => $composableBuilder(
    column: $table.isDeleted,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$GenealogyPersonsTableOrderingComposer get mergedIntoId {
    final $$GenealogyPersonsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.mergedIntoId,
      referencedTable: $db.genealogyPersons,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$GenealogyPersonsTableOrderingComposer(
            $db: $db,
            $table: $db.genealogyPersons,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$GenealogyPersonsTableAnnotationComposer
    extends Composer<_$AppDatabase, $GenealogyPersonsTable> {
  $$GenealogyPersonsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get firstName =>
      $composableBuilder(column: $table.firstName, builder: (column) => column);

  GeneratedColumn<String> get middleName => $composableBuilder(
    column: $table.middleName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get lastName =>
      $composableBuilder(column: $table.lastName, builder: (column) => column);

  GeneratedColumn<String> get birthSurname => $composableBuilder(
    column: $table.birthSurname,
    builder: (column) => column,
  );

  GeneratedColumn<String> get marriedSurname => $composableBuilder(
    column: $table.marriedSurname,
    builder: (column) => column,
  );

  GeneratedColumn<String> get suffix =>
      $composableBuilder(column: $table.suffix, builder: (column) => column);

  GeneratedColumn<String> get prefix =>
      $composableBuilder(column: $table.prefix, builder: (column) => column);

  GeneratedColumn<String> get nickname =>
      $composableBuilder(column: $table.nickname, builder: (column) => column);

  GeneratedColumn<String> get displayNameFormat => $composableBuilder(
    column: $table.displayNameFormat,
    builder: (column) => column,
  );

  GeneratedColumn<String> get customDisplayName => $composableBuilder(
    column: $table.customDisplayName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get gender =>
      $composableBuilder(column: $table.gender, builder: (column) => column);

  GeneratedColumn<DateTime> get birthDate =>
      $composableBuilder(column: $table.birthDate, builder: (column) => column);

  GeneratedColumn<String> get birthDateQualifier => $composableBuilder(
    column: $table.birthDateQualifier,
    builder: (column) => column,
  );

  GeneratedColumn<String> get birthPlace => $composableBuilder(
    column: $table.birthPlace,
    builder: (column) => column,
  );

  GeneratedColumn<double> get birthPlaceLat => $composableBuilder(
    column: $table.birthPlaceLat,
    builder: (column) => column,
  );

  GeneratedColumn<double> get birthPlaceLng => $composableBuilder(
    column: $table.birthPlaceLng,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get deathDate =>
      $composableBuilder(column: $table.deathDate, builder: (column) => column);

  GeneratedColumn<String> get deathDateQualifier => $composableBuilder(
    column: $table.deathDateQualifier,
    builder: (column) => column,
  );

  GeneratedColumn<String> get deathPlace => $composableBuilder(
    column: $table.deathPlace,
    builder: (column) => column,
  );

  GeneratedColumn<double> get deathPlaceLat => $composableBuilder(
    column: $table.deathPlaceLat,
    builder: (column) => column,
  );

  GeneratedColumn<double> get deathPlaceLng => $composableBuilder(
    column: $table.deathPlaceLng,
    builder: (column) => column,
  );

  GeneratedColumn<String> get currentPlace => $composableBuilder(
    column: $table.currentPlace,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isLiving =>
      $composableBuilder(column: $table.isLiving, builder: (column) => column);

  GeneratedColumn<String> get profilePhotoPath => $composableBuilder(
    column: $table.profilePhotoPath,
    builder: (column) => column,
  );

  GeneratedColumn<String> get biography =>
      $composableBuilder(column: $table.biography, builder: (column) => column);

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<String> get occupation => $composableBuilder(
    column: $table.occupation,
    builder: (column) => column,
  );

  GeneratedColumn<String> get religion =>
      $composableBuilder(column: $table.religion, builder: (column) => column);

  GeneratedColumn<String> get ethnicity =>
      $composableBuilder(column: $table.ethnicity, builder: (column) => column);

  GeneratedColumn<bool> get isPrivate =>
      $composableBuilder(column: $table.isPrivate, builder: (column) => column);

  GeneratedColumn<int> get privacyLevel => $composableBuilder(
    column: $table.privacyLevel,
    builder: (column) => column,
  );

  GeneratedColumn<String> get treeId =>
      $composableBuilder(column: $table.treeId, builder: (column) => column);

  GeneratedColumn<String> get uuid =>
      $composableBuilder(column: $table.uuid, builder: (column) => column);

  GeneratedColumn<bool> get isDeleted =>
      $composableBuilder(column: $table.isDeleted, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$GenealogyPersonsTableAnnotationComposer get mergedIntoId {
    final $$GenealogyPersonsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.mergedIntoId,
      referencedTable: $db.genealogyPersons,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$GenealogyPersonsTableAnnotationComposer(
            $db: $db,
            $table: $db.genealogyPersons,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> rootOfTrees<T extends Object>(
    Expression<T> Function($$FamilyTreesTableAnnotationComposer a) f,
  ) {
    final $$FamilyTreesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.familyTrees,
      getReferencedColumn: (t) => t.rootPersonId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FamilyTreesTableAnnotationComposer(
            $db: $db,
            $table: $db.familyTrees,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> eventsRefs<T extends Object>(
    Expression<T> Function($$EventsTableAnnotationComposer a) f,
  ) {
    final $$EventsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.events,
      getReferencedColumn: (t) => t.personId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EventsTableAnnotationComposer(
            $db: $db,
            $table: $db.events,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> surnameEventsRefs<T extends Object>(
    Expression<T> Function($$SurnameEventsTableAnnotationComposer a) f,
  ) {
    final $$SurnameEventsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.surnameEvents,
      getReferencedColumn: (t) => t.personId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SurnameEventsTableAnnotationComposer(
            $db: $db,
            $table: $db.surnameEvents,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> surnameEventsAbout<T extends Object>(
    Expression<T> Function($$SurnameEventsTableAnnotationComposer a) f,
  ) {
    final $$SurnameEventsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.surnameEvents,
      getReferencedColumn: (t) => t.relatedPersonId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SurnameEventsTableAnnotationComposer(
            $db: $db,
            $table: $db.surnameEvents,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> husbandFamilies<T extends Object>(
    Expression<T> Function($$FamiliesV2TableAnnotationComposer a) f,
  ) {
    final $$FamiliesV2TableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.familiesV2,
      getReferencedColumn: (t) => t.husbandId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FamiliesV2TableAnnotationComposer(
            $db: $db,
            $table: $db.familiesV2,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> wifeFamilies<T extends Object>(
    Expression<T> Function($$FamiliesV2TableAnnotationComposer a) f,
  ) {
    final $$FamiliesV2TableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.familiesV2,
      getReferencedColumn: (t) => t.wifeId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FamiliesV2TableAnnotationComposer(
            $db: $db,
            $table: $db.familiesV2,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> childFamilyLinks<T extends Object>(
    Expression<T> Function($$FamilyChildrenV2TableAnnotationComposer a) f,
  ) {
    final $$FamilyChildrenV2TableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.familyChildrenV2,
      getReferencedColumn: (t) => t.childId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FamilyChildrenV2TableAnnotationComposer(
            $db: $db,
            $table: $db.familyChildrenV2,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> mediaItemsRefs<T extends Object>(
    Expression<T> Function($$MediaItemsTableAnnotationComposer a) f,
  ) {
    final $$MediaItemsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.mediaItems,
      getReferencedColumn: (t) => t.personId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MediaItemsTableAnnotationComposer(
            $db: $db,
            $table: $db.mediaItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> researchNotesRefs<T extends Object>(
    Expression<T> Function($$ResearchNotesTableAnnotationComposer a) f,
  ) {
    final $$ResearchNotesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.researchNotes,
      getReferencedColumn: (t) => t.personId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ResearchNotesTableAnnotationComposer(
            $db: $db,
            $table: $db.researchNotes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$GenealogyPersonsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $GenealogyPersonsTable,
          GenealogyPerson,
          $$GenealogyPersonsTableFilterComposer,
          $$GenealogyPersonsTableOrderingComposer,
          $$GenealogyPersonsTableAnnotationComposer,
          $$GenealogyPersonsTableCreateCompanionBuilder,
          $$GenealogyPersonsTableUpdateCompanionBuilder,
          (GenealogyPerson, $$GenealogyPersonsTableReferences),
          GenealogyPerson,
          PrefetchHooks Function({
            bool mergedIntoId,
            bool rootOfTrees,
            bool eventsRefs,
            bool surnameEventsRefs,
            bool surnameEventsAbout,
            bool husbandFamilies,
            bool wifeFamilies,
            bool childFamilyLinks,
            bool mediaItemsRefs,
            bool researchNotesRefs,
          })
        > {
  $$GenealogyPersonsTableTableManager(
    _$AppDatabase db,
    $GenealogyPersonsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$GenealogyPersonsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$GenealogyPersonsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$GenealogyPersonsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> firstName = const Value.absent(),
                Value<String?> middleName = const Value.absent(),
                Value<String?> lastName = const Value.absent(),
                Value<String?> birthSurname = const Value.absent(),
                Value<String?> marriedSurname = const Value.absent(),
                Value<String?> suffix = const Value.absent(),
                Value<String?> prefix = const Value.absent(),
                Value<String?> nickname = const Value.absent(),
                Value<String> displayNameFormat = const Value.absent(),
                Value<String?> customDisplayName = const Value.absent(),
                Value<String> gender = const Value.absent(),
                Value<DateTime?> birthDate = const Value.absent(),
                Value<String?> birthDateQualifier = const Value.absent(),
                Value<String?> birthPlace = const Value.absent(),
                Value<double?> birthPlaceLat = const Value.absent(),
                Value<double?> birthPlaceLng = const Value.absent(),
                Value<DateTime?> deathDate = const Value.absent(),
                Value<String?> deathDateQualifier = const Value.absent(),
                Value<String?> deathPlace = const Value.absent(),
                Value<double?> deathPlaceLat = const Value.absent(),
                Value<double?> deathPlaceLng = const Value.absent(),
                Value<String?> currentPlace = const Value.absent(),
                Value<bool> isLiving = const Value.absent(),
                Value<String?> profilePhotoPath = const Value.absent(),
                Value<String?> biography = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<String?> occupation = const Value.absent(),
                Value<String?> religion = const Value.absent(),
                Value<String?> ethnicity = const Value.absent(),
                Value<bool> isPrivate = const Value.absent(),
                Value<int> privacyLevel = const Value.absent(),
                Value<String> treeId = const Value.absent(),
                Value<String> uuid = const Value.absent(),
                Value<bool> isDeleted = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<String?> mergedIntoId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => GenealogyPersonsCompanion(
                id: id,
                firstName: firstName,
                middleName: middleName,
                lastName: lastName,
                birthSurname: birthSurname,
                marriedSurname: marriedSurname,
                suffix: suffix,
                prefix: prefix,
                nickname: nickname,
                displayNameFormat: displayNameFormat,
                customDisplayName: customDisplayName,
                gender: gender,
                birthDate: birthDate,
                birthDateQualifier: birthDateQualifier,
                birthPlace: birthPlace,
                birthPlaceLat: birthPlaceLat,
                birthPlaceLng: birthPlaceLng,
                deathDate: deathDate,
                deathDateQualifier: deathDateQualifier,
                deathPlace: deathPlace,
                deathPlaceLat: deathPlaceLat,
                deathPlaceLng: deathPlaceLng,
                currentPlace: currentPlace,
                isLiving: isLiving,
                profilePhotoPath: profilePhotoPath,
                biography: biography,
                notes: notes,
                occupation: occupation,
                religion: religion,
                ethnicity: ethnicity,
                isPrivate: isPrivate,
                privacyLevel: privacyLevel,
                treeId: treeId,
                uuid: uuid,
                isDeleted: isDeleted,
                createdAt: createdAt,
                updatedAt: updatedAt,
                mergedIntoId: mergedIntoId,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String firstName,
                Value<String?> middleName = const Value.absent(),
                Value<String?> lastName = const Value.absent(),
                Value<String?> birthSurname = const Value.absent(),
                Value<String?> marriedSurname = const Value.absent(),
                Value<String?> suffix = const Value.absent(),
                Value<String?> prefix = const Value.absent(),
                Value<String?> nickname = const Value.absent(),
                Value<String> displayNameFormat = const Value.absent(),
                Value<String?> customDisplayName = const Value.absent(),
                required String gender,
                Value<DateTime?> birthDate = const Value.absent(),
                Value<String?> birthDateQualifier = const Value.absent(),
                Value<String?> birthPlace = const Value.absent(),
                Value<double?> birthPlaceLat = const Value.absent(),
                Value<double?> birthPlaceLng = const Value.absent(),
                Value<DateTime?> deathDate = const Value.absent(),
                Value<String?> deathDateQualifier = const Value.absent(),
                Value<String?> deathPlace = const Value.absent(),
                Value<double?> deathPlaceLat = const Value.absent(),
                Value<double?> deathPlaceLng = const Value.absent(),
                Value<String?> currentPlace = const Value.absent(),
                Value<bool> isLiving = const Value.absent(),
                Value<String?> profilePhotoPath = const Value.absent(),
                Value<String?> biography = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<String?> occupation = const Value.absent(),
                Value<String?> religion = const Value.absent(),
                Value<String?> ethnicity = const Value.absent(),
                Value<bool> isPrivate = const Value.absent(),
                Value<int> privacyLevel = const Value.absent(),
                required String treeId,
                required String uuid,
                Value<bool> isDeleted = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<String?> mergedIntoId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => GenealogyPersonsCompanion.insert(
                id: id,
                firstName: firstName,
                middleName: middleName,
                lastName: lastName,
                birthSurname: birthSurname,
                marriedSurname: marriedSurname,
                suffix: suffix,
                prefix: prefix,
                nickname: nickname,
                displayNameFormat: displayNameFormat,
                customDisplayName: customDisplayName,
                gender: gender,
                birthDate: birthDate,
                birthDateQualifier: birthDateQualifier,
                birthPlace: birthPlace,
                birthPlaceLat: birthPlaceLat,
                birthPlaceLng: birthPlaceLng,
                deathDate: deathDate,
                deathDateQualifier: deathDateQualifier,
                deathPlace: deathPlace,
                deathPlaceLat: deathPlaceLat,
                deathPlaceLng: deathPlaceLng,
                currentPlace: currentPlace,
                isLiving: isLiving,
                profilePhotoPath: profilePhotoPath,
                biography: biography,
                notes: notes,
                occupation: occupation,
                religion: religion,
                ethnicity: ethnicity,
                isPrivate: isPrivate,
                privacyLevel: privacyLevel,
                treeId: treeId,
                uuid: uuid,
                isDeleted: isDeleted,
                createdAt: createdAt,
                updatedAt: updatedAt,
                mergedIntoId: mergedIntoId,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$GenealogyPersonsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                mergedIntoId = false,
                rootOfTrees = false,
                eventsRefs = false,
                surnameEventsRefs = false,
                surnameEventsAbout = false,
                husbandFamilies = false,
                wifeFamilies = false,
                childFamilyLinks = false,
                mediaItemsRefs = false,
                researchNotesRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (rootOfTrees) db.familyTrees,
                    if (eventsRefs) db.events,
                    if (surnameEventsRefs) db.surnameEvents,
                    if (surnameEventsAbout) db.surnameEvents,
                    if (husbandFamilies) db.familiesV2,
                    if (wifeFamilies) db.familiesV2,
                    if (childFamilyLinks) db.familyChildrenV2,
                    if (mediaItemsRefs) db.mediaItems,
                    if (researchNotesRefs) db.researchNotes,
                  ],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (mergedIntoId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.mergedIntoId,
                                    referencedTable:
                                        $$GenealogyPersonsTableReferences
                                            ._mergedIntoIdTable(db),
                                    referencedColumn:
                                        $$GenealogyPersonsTableReferences
                                            ._mergedIntoIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (rootOfTrees)
                        await $_getPrefetchedData<
                          GenealogyPerson,
                          $GenealogyPersonsTable,
                          FamilyTree
                        >(
                          currentTable: table,
                          referencedTable: $$GenealogyPersonsTableReferences
                              ._rootOfTreesTable(db),
                          managerFromTypedResult: (p0) =>
                              $$GenealogyPersonsTableReferences(
                                db,
                                table,
                                p0,
                              ).rootOfTrees,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.rootPersonId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (eventsRefs)
                        await $_getPrefetchedData<
                          GenealogyPerson,
                          $GenealogyPersonsTable,
                          Event
                        >(
                          currentTable: table,
                          referencedTable: $$GenealogyPersonsTableReferences
                              ._eventsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$GenealogyPersonsTableReferences(
                                db,
                                table,
                                p0,
                              ).eventsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.personId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (surnameEventsRefs)
                        await $_getPrefetchedData<
                          GenealogyPerson,
                          $GenealogyPersonsTable,
                          SurnameEvent
                        >(
                          currentTable: table,
                          referencedTable: $$GenealogyPersonsTableReferences
                              ._surnameEventsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$GenealogyPersonsTableReferences(
                                db,
                                table,
                                p0,
                              ).surnameEventsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.personId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (surnameEventsAbout)
                        await $_getPrefetchedData<
                          GenealogyPerson,
                          $GenealogyPersonsTable,
                          SurnameEvent
                        >(
                          currentTable: table,
                          referencedTable: $$GenealogyPersonsTableReferences
                              ._surnameEventsAboutTable(db),
                          managerFromTypedResult: (p0) =>
                              $$GenealogyPersonsTableReferences(
                                db,
                                table,
                                p0,
                              ).surnameEventsAbout,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.relatedPersonId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (husbandFamilies)
                        await $_getPrefetchedData<
                          GenealogyPerson,
                          $GenealogyPersonsTable,
                          FamiliesV2Data
                        >(
                          currentTable: table,
                          referencedTable: $$GenealogyPersonsTableReferences
                              ._husbandFamiliesTable(db),
                          managerFromTypedResult: (p0) =>
                              $$GenealogyPersonsTableReferences(
                                db,
                                table,
                                p0,
                              ).husbandFamilies,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.husbandId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (wifeFamilies)
                        await $_getPrefetchedData<
                          GenealogyPerson,
                          $GenealogyPersonsTable,
                          FamiliesV2Data
                        >(
                          currentTable: table,
                          referencedTable: $$GenealogyPersonsTableReferences
                              ._wifeFamiliesTable(db),
                          managerFromTypedResult: (p0) =>
                              $$GenealogyPersonsTableReferences(
                                db,
                                table,
                                p0,
                              ).wifeFamilies,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.wifeId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (childFamilyLinks)
                        await $_getPrefetchedData<
                          GenealogyPerson,
                          $GenealogyPersonsTable,
                          FamilyChildrenV2Data
                        >(
                          currentTable: table,
                          referencedTable: $$GenealogyPersonsTableReferences
                              ._childFamilyLinksTable(db),
                          managerFromTypedResult: (p0) =>
                              $$GenealogyPersonsTableReferences(
                                db,
                                table,
                                p0,
                              ).childFamilyLinks,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.childId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (mediaItemsRefs)
                        await $_getPrefetchedData<
                          GenealogyPerson,
                          $GenealogyPersonsTable,
                          MediaItem
                        >(
                          currentTable: table,
                          referencedTable: $$GenealogyPersonsTableReferences
                              ._mediaItemsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$GenealogyPersonsTableReferences(
                                db,
                                table,
                                p0,
                              ).mediaItemsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.personId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (researchNotesRefs)
                        await $_getPrefetchedData<
                          GenealogyPerson,
                          $GenealogyPersonsTable,
                          ResearchNote
                        >(
                          currentTable: table,
                          referencedTable: $$GenealogyPersonsTableReferences
                              ._researchNotesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$GenealogyPersonsTableReferences(
                                db,
                                table,
                                p0,
                              ).researchNotesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.personId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$GenealogyPersonsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $GenealogyPersonsTable,
      GenealogyPerson,
      $$GenealogyPersonsTableFilterComposer,
      $$GenealogyPersonsTableOrderingComposer,
      $$GenealogyPersonsTableAnnotationComposer,
      $$GenealogyPersonsTableCreateCompanionBuilder,
      $$GenealogyPersonsTableUpdateCompanionBuilder,
      (GenealogyPerson, $$GenealogyPersonsTableReferences),
      GenealogyPerson,
      PrefetchHooks Function({
        bool mergedIntoId,
        bool rootOfTrees,
        bool eventsRefs,
        bool surnameEventsRefs,
        bool surnameEventsAbout,
        bool husbandFamilies,
        bool wifeFamilies,
        bool childFamilyLinks,
        bool mediaItemsRefs,
        bool researchNotesRefs,
      })
    >;
typedef $$FamilyTreesTableCreateCompanionBuilder =
    FamilyTreesCompanion Function({
      required String id,
      required String treeName,
      Value<String?> description,
      Value<String?> rootPersonId,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$FamilyTreesTableUpdateCompanionBuilder =
    FamilyTreesCompanion Function({
      Value<String> id,
      Value<String> treeName,
      Value<String?> description,
      Value<String?> rootPersonId,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

final class $$FamilyTreesTableReferences
    extends BaseReferences<_$AppDatabase, $FamilyTreesTable, FamilyTree> {
  $$FamilyTreesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $GenealogyPersonsTable _rootPersonIdTable(_$AppDatabase db) =>
      db.genealogyPersons.createAlias(
        $_aliasNameGenerator(
          db.familyTrees.rootPersonId,
          db.genealogyPersons.id,
        ),
      );

  $$GenealogyPersonsTableProcessedTableManager? get rootPersonId {
    final $_column = $_itemColumn<String>('root_person_id');
    if ($_column == null) return null;
    final manager = $$GenealogyPersonsTableTableManager(
      $_db,
      $_db.genealogyPersons,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_rootPersonIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$FamiliesV2Table, List<FamiliesV2Data>>
  _familiesInTreeTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.familiesV2,
    aliasName: $_aliasNameGenerator(db.familyTrees.id, db.familiesV2.treeId),
  );

  $$FamiliesV2TableProcessedTableManager get familiesInTree {
    final manager = $$FamiliesV2TableTableManager(
      $_db,
      $_db.familiesV2,
    ).filter((f) => f.treeId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_familiesInTreeTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$FamilyTreesTableFilterComposer
    extends Composer<_$AppDatabase, $FamilyTreesTable> {
  $$FamilyTreesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get treeName => $composableBuilder(
    column: $table.treeName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$GenealogyPersonsTableFilterComposer get rootPersonId {
    final $$GenealogyPersonsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.rootPersonId,
      referencedTable: $db.genealogyPersons,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$GenealogyPersonsTableFilterComposer(
            $db: $db,
            $table: $db.genealogyPersons,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> familiesInTree(
    Expression<bool> Function($$FamiliesV2TableFilterComposer f) f,
  ) {
    final $$FamiliesV2TableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.familiesV2,
      getReferencedColumn: (t) => t.treeId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FamiliesV2TableFilterComposer(
            $db: $db,
            $table: $db.familiesV2,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$FamilyTreesTableOrderingComposer
    extends Composer<_$AppDatabase, $FamilyTreesTable> {
  $$FamilyTreesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get treeName => $composableBuilder(
    column: $table.treeName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$GenealogyPersonsTableOrderingComposer get rootPersonId {
    final $$GenealogyPersonsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.rootPersonId,
      referencedTable: $db.genealogyPersons,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$GenealogyPersonsTableOrderingComposer(
            $db: $db,
            $table: $db.genealogyPersons,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$FamilyTreesTableAnnotationComposer
    extends Composer<_$AppDatabase, $FamilyTreesTable> {
  $$FamilyTreesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get treeName =>
      $composableBuilder(column: $table.treeName, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$GenealogyPersonsTableAnnotationComposer get rootPersonId {
    final $$GenealogyPersonsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.rootPersonId,
      referencedTable: $db.genealogyPersons,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$GenealogyPersonsTableAnnotationComposer(
            $db: $db,
            $table: $db.genealogyPersons,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> familiesInTree<T extends Object>(
    Expression<T> Function($$FamiliesV2TableAnnotationComposer a) f,
  ) {
    final $$FamiliesV2TableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.familiesV2,
      getReferencedColumn: (t) => t.treeId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FamiliesV2TableAnnotationComposer(
            $db: $db,
            $table: $db.familiesV2,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$FamilyTreesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $FamilyTreesTable,
          FamilyTree,
          $$FamilyTreesTableFilterComposer,
          $$FamilyTreesTableOrderingComposer,
          $$FamilyTreesTableAnnotationComposer,
          $$FamilyTreesTableCreateCompanionBuilder,
          $$FamilyTreesTableUpdateCompanionBuilder,
          (FamilyTree, $$FamilyTreesTableReferences),
          FamilyTree,
          PrefetchHooks Function({bool rootPersonId, bool familiesInTree})
        > {
  $$FamilyTreesTableTableManager(_$AppDatabase db, $FamilyTreesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$FamilyTreesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$FamilyTreesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$FamilyTreesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> treeName = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<String?> rootPersonId = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => FamilyTreesCompanion(
                id: id,
                treeName: treeName,
                description: description,
                rootPersonId: rootPersonId,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String treeName,
                Value<String?> description = const Value.absent(),
                Value<String?> rootPersonId = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => FamilyTreesCompanion.insert(
                id: id,
                treeName: treeName,
                description: description,
                rootPersonId: rootPersonId,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$FamilyTreesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({rootPersonId = false, familiesInTree = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [if (familiesInTree) db.familiesV2],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (rootPersonId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.rootPersonId,
                                    referencedTable:
                                        $$FamilyTreesTableReferences
                                            ._rootPersonIdTable(db),
                                    referencedColumn:
                                        $$FamilyTreesTableReferences
                                            ._rootPersonIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (familiesInTree)
                        await $_getPrefetchedData<
                          FamilyTree,
                          $FamilyTreesTable,
                          FamiliesV2Data
                        >(
                          currentTable: table,
                          referencedTable: $$FamilyTreesTableReferences
                              ._familiesInTreeTable(db),
                          managerFromTypedResult: (p0) =>
                              $$FamilyTreesTableReferences(
                                db,
                                table,
                                p0,
                              ).familiesInTree,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.treeId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$FamilyTreesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $FamilyTreesTable,
      FamilyTree,
      $$FamilyTreesTableFilterComposer,
      $$FamilyTreesTableOrderingComposer,
      $$FamilyTreesTableAnnotationComposer,
      $$FamilyTreesTableCreateCompanionBuilder,
      $$FamilyTreesTableUpdateCompanionBuilder,
      (FamilyTree, $$FamilyTreesTableReferences),
      FamilyTree,
      PrefetchHooks Function({bool rootPersonId, bool familiesInTree})
    >;
typedef $$EventsTableCreateCompanionBuilder =
    EventsCompanion Function({
      required String id,
      required String personId,
      required String eventType,
      Value<double?> dateSort,
      Value<String?> dateDisplay,
      Value<String?> place,
      Value<String?> description,
      Value<bool> isPrimary,
      Value<double?> latitude,
      Value<double?> longitude,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$EventsTableUpdateCompanionBuilder =
    EventsCompanion Function({
      Value<String> id,
      Value<String> personId,
      Value<String> eventType,
      Value<double?> dateSort,
      Value<String?> dateDisplay,
      Value<String?> place,
      Value<String?> description,
      Value<bool> isPrimary,
      Value<double?> latitude,
      Value<double?> longitude,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

final class $$EventsTableReferences
    extends BaseReferences<_$AppDatabase, $EventsTable, Event> {
  $$EventsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $GenealogyPersonsTable _personIdTable(_$AppDatabase db) =>
      db.genealogyPersons.createAlias(
        $_aliasNameGenerator(db.events.personId, db.genealogyPersons.id),
      );

  $$GenealogyPersonsTableProcessedTableManager get personId {
    final $_column = $_itemColumn<String>('person_id')!;

    final manager = $$GenealogyPersonsTableTableManager(
      $_db,
      $_db.genealogyPersons,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_personIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$SurnameEventsTable, List<SurnameEvent>>
  _surnameEventsFromTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.surnameEvents,
    aliasName: $_aliasNameGenerator(
      db.events.id,
      db.surnameEvents.relatedEventId,
    ),
  );

  $$SurnameEventsTableProcessedTableManager get surnameEventsFrom {
    final manager = $$SurnameEventsTableTableManager(
      $_db,
      $_db.surnameEvents,
    ).filter((f) => f.relatedEventId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_surnameEventsFromTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$EventsTableFilterComposer
    extends Composer<_$AppDatabase, $EventsTable> {
  $$EventsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get eventType => $composableBuilder(
    column: $table.eventType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get dateSort => $composableBuilder(
    column: $table.dateSort,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get dateDisplay => $composableBuilder(
    column: $table.dateDisplay,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get place => $composableBuilder(
    column: $table.place,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isPrimary => $composableBuilder(
    column: $table.isPrimary,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get latitude => $composableBuilder(
    column: $table.latitude,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get longitude => $composableBuilder(
    column: $table.longitude,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$GenealogyPersonsTableFilterComposer get personId {
    final $$GenealogyPersonsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.personId,
      referencedTable: $db.genealogyPersons,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$GenealogyPersonsTableFilterComposer(
            $db: $db,
            $table: $db.genealogyPersons,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> surnameEventsFrom(
    Expression<bool> Function($$SurnameEventsTableFilterComposer f) f,
  ) {
    final $$SurnameEventsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.surnameEvents,
      getReferencedColumn: (t) => t.relatedEventId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SurnameEventsTableFilterComposer(
            $db: $db,
            $table: $db.surnameEvents,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$EventsTableOrderingComposer
    extends Composer<_$AppDatabase, $EventsTable> {
  $$EventsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get eventType => $composableBuilder(
    column: $table.eventType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get dateSort => $composableBuilder(
    column: $table.dateSort,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get dateDisplay => $composableBuilder(
    column: $table.dateDisplay,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get place => $composableBuilder(
    column: $table.place,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isPrimary => $composableBuilder(
    column: $table.isPrimary,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get latitude => $composableBuilder(
    column: $table.latitude,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get longitude => $composableBuilder(
    column: $table.longitude,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$GenealogyPersonsTableOrderingComposer get personId {
    final $$GenealogyPersonsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.personId,
      referencedTable: $db.genealogyPersons,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$GenealogyPersonsTableOrderingComposer(
            $db: $db,
            $table: $db.genealogyPersons,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$EventsTableAnnotationComposer
    extends Composer<_$AppDatabase, $EventsTable> {
  $$EventsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get eventType =>
      $composableBuilder(column: $table.eventType, builder: (column) => column);

  GeneratedColumn<double> get dateSort =>
      $composableBuilder(column: $table.dateSort, builder: (column) => column);

  GeneratedColumn<String> get dateDisplay => $composableBuilder(
    column: $table.dateDisplay,
    builder: (column) => column,
  );

  GeneratedColumn<String> get place =>
      $composableBuilder(column: $table.place, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isPrimary =>
      $composableBuilder(column: $table.isPrimary, builder: (column) => column);

  GeneratedColumn<double> get latitude =>
      $composableBuilder(column: $table.latitude, builder: (column) => column);

  GeneratedColumn<double> get longitude =>
      $composableBuilder(column: $table.longitude, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$GenealogyPersonsTableAnnotationComposer get personId {
    final $$GenealogyPersonsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.personId,
      referencedTable: $db.genealogyPersons,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$GenealogyPersonsTableAnnotationComposer(
            $db: $db,
            $table: $db.genealogyPersons,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> surnameEventsFrom<T extends Object>(
    Expression<T> Function($$SurnameEventsTableAnnotationComposer a) f,
  ) {
    final $$SurnameEventsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.surnameEvents,
      getReferencedColumn: (t) => t.relatedEventId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SurnameEventsTableAnnotationComposer(
            $db: $db,
            $table: $db.surnameEvents,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$EventsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $EventsTable,
          Event,
          $$EventsTableFilterComposer,
          $$EventsTableOrderingComposer,
          $$EventsTableAnnotationComposer,
          $$EventsTableCreateCompanionBuilder,
          $$EventsTableUpdateCompanionBuilder,
          (Event, $$EventsTableReferences),
          Event,
          PrefetchHooks Function({bool personId, bool surnameEventsFrom})
        > {
  $$EventsTableTableManager(_$AppDatabase db, $EventsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$EventsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$EventsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$EventsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> personId = const Value.absent(),
                Value<String> eventType = const Value.absent(),
                Value<double?> dateSort = const Value.absent(),
                Value<String?> dateDisplay = const Value.absent(),
                Value<String?> place = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<bool> isPrimary = const Value.absent(),
                Value<double?> latitude = const Value.absent(),
                Value<double?> longitude = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => EventsCompanion(
                id: id,
                personId: personId,
                eventType: eventType,
                dateSort: dateSort,
                dateDisplay: dateDisplay,
                place: place,
                description: description,
                isPrimary: isPrimary,
                latitude: latitude,
                longitude: longitude,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String personId,
                required String eventType,
                Value<double?> dateSort = const Value.absent(),
                Value<String?> dateDisplay = const Value.absent(),
                Value<String?> place = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<bool> isPrimary = const Value.absent(),
                Value<double?> latitude = const Value.absent(),
                Value<double?> longitude = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => EventsCompanion.insert(
                id: id,
                personId: personId,
                eventType: eventType,
                dateSort: dateSort,
                dateDisplay: dateDisplay,
                place: place,
                description: description,
                isPrimary: isPrimary,
                latitude: latitude,
                longitude: longitude,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) =>
                    (e.readTable(table), $$EventsTableReferences(db, table, e)),
              )
              .toList(),
          prefetchHooksCallback:
              ({personId = false, surnameEventsFrom = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (surnameEventsFrom) db.surnameEvents,
                  ],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (personId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.personId,
                                    referencedTable: $$EventsTableReferences
                                        ._personIdTable(db),
                                    referencedColumn: $$EventsTableReferences
                                        ._personIdTable(db)
                                        .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (surnameEventsFrom)
                        await $_getPrefetchedData<
                          Event,
                          $EventsTable,
                          SurnameEvent
                        >(
                          currentTable: table,
                          referencedTable: $$EventsTableReferences
                              ._surnameEventsFromTable(db),
                          managerFromTypedResult: (p0) =>
                              $$EventsTableReferences(
                                db,
                                table,
                                p0,
                              ).surnameEventsFrom,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.relatedEventId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$EventsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $EventsTable,
      Event,
      $$EventsTableFilterComposer,
      $$EventsTableOrderingComposer,
      $$EventsTableAnnotationComposer,
      $$EventsTableCreateCompanionBuilder,
      $$EventsTableUpdateCompanionBuilder,
      (Event, $$EventsTableReferences),
      Event,
      PrefetchHooks Function({bool personId, bool surnameEventsFrom})
    >;
typedef $$SurnameEventsTableCreateCompanionBuilder =
    SurnameEventsCompanion Function({
      required String id,
      required String personId,
      required String surname,
      required String surnameType,
      Value<String?> startDate,
      Value<String?> startDateQualifier,
      Value<String?> endDate,
      Value<String?> endDateQualifier,
      Value<String?> relatedPersonId,
      Value<String?> relatedEventId,
      Value<String?> location,
      Value<String?> legalDocument,
      Value<String?> notes,
      Value<int> sortOrder,
      Value<bool> isPrimary,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });
typedef $$SurnameEventsTableUpdateCompanionBuilder =
    SurnameEventsCompanion Function({
      Value<String> id,
      Value<String> personId,
      Value<String> surname,
      Value<String> surnameType,
      Value<String?> startDate,
      Value<String?> startDateQualifier,
      Value<String?> endDate,
      Value<String?> endDateQualifier,
      Value<String?> relatedPersonId,
      Value<String?> relatedEventId,
      Value<String?> location,
      Value<String?> legalDocument,
      Value<String?> notes,
      Value<int> sortOrder,
      Value<bool> isPrimary,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

final class $$SurnameEventsTableReferences
    extends BaseReferences<_$AppDatabase, $SurnameEventsTable, SurnameEvent> {
  $$SurnameEventsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $GenealogyPersonsTable _personIdTable(_$AppDatabase db) =>
      db.genealogyPersons.createAlias(
        $_aliasNameGenerator(db.surnameEvents.personId, db.genealogyPersons.id),
      );

  $$GenealogyPersonsTableProcessedTableManager get personId {
    final $_column = $_itemColumn<String>('person_id')!;

    final manager = $$GenealogyPersonsTableTableManager(
      $_db,
      $_db.genealogyPersons,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_personIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $GenealogyPersonsTable _relatedPersonIdTable(_$AppDatabase db) =>
      db.genealogyPersons.createAlias(
        $_aliasNameGenerator(
          db.surnameEvents.relatedPersonId,
          db.genealogyPersons.id,
        ),
      );

  $$GenealogyPersonsTableProcessedTableManager? get relatedPersonId {
    final $_column = $_itemColumn<String>('related_person_id');
    if ($_column == null) return null;
    final manager = $$GenealogyPersonsTableTableManager(
      $_db,
      $_db.genealogyPersons,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_relatedPersonIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $EventsTable _relatedEventIdTable(_$AppDatabase db) =>
      db.events.createAlias(
        $_aliasNameGenerator(db.surnameEvents.relatedEventId, db.events.id),
      );

  $$EventsTableProcessedTableManager? get relatedEventId {
    final $_column = $_itemColumn<String>('related_event_id');
    if ($_column == null) return null;
    final manager = $$EventsTableTableManager(
      $_db,
      $_db.events,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_relatedEventIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$SurnameEventsTableFilterComposer
    extends Composer<_$AppDatabase, $SurnameEventsTable> {
  $$SurnameEventsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get surname => $composableBuilder(
    column: $table.surname,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get surnameType => $composableBuilder(
    column: $table.surnameType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get startDate => $composableBuilder(
    column: $table.startDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get startDateQualifier => $composableBuilder(
    column: $table.startDateQualifier,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get endDate => $composableBuilder(
    column: $table.endDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get endDateQualifier => $composableBuilder(
    column: $table.endDateQualifier,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get location => $composableBuilder(
    column: $table.location,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get legalDocument => $composableBuilder(
    column: $table.legalDocument,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isPrimary => $composableBuilder(
    column: $table.isPrimary,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$GenealogyPersonsTableFilterComposer get personId {
    final $$GenealogyPersonsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.personId,
      referencedTable: $db.genealogyPersons,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$GenealogyPersonsTableFilterComposer(
            $db: $db,
            $table: $db.genealogyPersons,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$GenealogyPersonsTableFilterComposer get relatedPersonId {
    final $$GenealogyPersonsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.relatedPersonId,
      referencedTable: $db.genealogyPersons,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$GenealogyPersonsTableFilterComposer(
            $db: $db,
            $table: $db.genealogyPersons,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$EventsTableFilterComposer get relatedEventId {
    final $$EventsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.relatedEventId,
      referencedTable: $db.events,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EventsTableFilterComposer(
            $db: $db,
            $table: $db.events,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SurnameEventsTableOrderingComposer
    extends Composer<_$AppDatabase, $SurnameEventsTable> {
  $$SurnameEventsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get surname => $composableBuilder(
    column: $table.surname,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get surnameType => $composableBuilder(
    column: $table.surnameType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get startDate => $composableBuilder(
    column: $table.startDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get startDateQualifier => $composableBuilder(
    column: $table.startDateQualifier,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get endDate => $composableBuilder(
    column: $table.endDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get endDateQualifier => $composableBuilder(
    column: $table.endDateQualifier,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get location => $composableBuilder(
    column: $table.location,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get legalDocument => $composableBuilder(
    column: $table.legalDocument,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isPrimary => $composableBuilder(
    column: $table.isPrimary,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$GenealogyPersonsTableOrderingComposer get personId {
    final $$GenealogyPersonsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.personId,
      referencedTable: $db.genealogyPersons,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$GenealogyPersonsTableOrderingComposer(
            $db: $db,
            $table: $db.genealogyPersons,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$GenealogyPersonsTableOrderingComposer get relatedPersonId {
    final $$GenealogyPersonsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.relatedPersonId,
      referencedTable: $db.genealogyPersons,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$GenealogyPersonsTableOrderingComposer(
            $db: $db,
            $table: $db.genealogyPersons,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$EventsTableOrderingComposer get relatedEventId {
    final $$EventsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.relatedEventId,
      referencedTable: $db.events,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EventsTableOrderingComposer(
            $db: $db,
            $table: $db.events,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SurnameEventsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SurnameEventsTable> {
  $$SurnameEventsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get surname =>
      $composableBuilder(column: $table.surname, builder: (column) => column);

  GeneratedColumn<String> get surnameType => $composableBuilder(
    column: $table.surnameType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get startDate =>
      $composableBuilder(column: $table.startDate, builder: (column) => column);

  GeneratedColumn<String> get startDateQualifier => $composableBuilder(
    column: $table.startDateQualifier,
    builder: (column) => column,
  );

  GeneratedColumn<String> get endDate =>
      $composableBuilder(column: $table.endDate, builder: (column) => column);

  GeneratedColumn<String> get endDateQualifier => $composableBuilder(
    column: $table.endDateQualifier,
    builder: (column) => column,
  );

  GeneratedColumn<String> get location =>
      $composableBuilder(column: $table.location, builder: (column) => column);

  GeneratedColumn<String> get legalDocument => $composableBuilder(
    column: $table.legalDocument,
    builder: (column) => column,
  );

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  GeneratedColumn<bool> get isPrimary =>
      $composableBuilder(column: $table.isPrimary, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$GenealogyPersonsTableAnnotationComposer get personId {
    final $$GenealogyPersonsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.personId,
      referencedTable: $db.genealogyPersons,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$GenealogyPersonsTableAnnotationComposer(
            $db: $db,
            $table: $db.genealogyPersons,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$GenealogyPersonsTableAnnotationComposer get relatedPersonId {
    final $$GenealogyPersonsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.relatedPersonId,
      referencedTable: $db.genealogyPersons,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$GenealogyPersonsTableAnnotationComposer(
            $db: $db,
            $table: $db.genealogyPersons,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$EventsTableAnnotationComposer get relatedEventId {
    final $$EventsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.relatedEventId,
      referencedTable: $db.events,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EventsTableAnnotationComposer(
            $db: $db,
            $table: $db.events,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SurnameEventsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SurnameEventsTable,
          SurnameEvent,
          $$SurnameEventsTableFilterComposer,
          $$SurnameEventsTableOrderingComposer,
          $$SurnameEventsTableAnnotationComposer,
          $$SurnameEventsTableCreateCompanionBuilder,
          $$SurnameEventsTableUpdateCompanionBuilder,
          (SurnameEvent, $$SurnameEventsTableReferences),
          SurnameEvent,
          PrefetchHooks Function({
            bool personId,
            bool relatedPersonId,
            bool relatedEventId,
          })
        > {
  $$SurnameEventsTableTableManager(_$AppDatabase db, $SurnameEventsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SurnameEventsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SurnameEventsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SurnameEventsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> personId = const Value.absent(),
                Value<String> surname = const Value.absent(),
                Value<String> surnameType = const Value.absent(),
                Value<String?> startDate = const Value.absent(),
                Value<String?> startDateQualifier = const Value.absent(),
                Value<String?> endDate = const Value.absent(),
                Value<String?> endDateQualifier = const Value.absent(),
                Value<String?> relatedPersonId = const Value.absent(),
                Value<String?> relatedEventId = const Value.absent(),
                Value<String?> location = const Value.absent(),
                Value<String?> legalDocument = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<bool> isPrimary = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SurnameEventsCompanion(
                id: id,
                personId: personId,
                surname: surname,
                surnameType: surnameType,
                startDate: startDate,
                startDateQualifier: startDateQualifier,
                endDate: endDate,
                endDateQualifier: endDateQualifier,
                relatedPersonId: relatedPersonId,
                relatedEventId: relatedEventId,
                location: location,
                legalDocument: legalDocument,
                notes: notes,
                sortOrder: sortOrder,
                isPrimary: isPrimary,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String personId,
                required String surname,
                required String surnameType,
                Value<String?> startDate = const Value.absent(),
                Value<String?> startDateQualifier = const Value.absent(),
                Value<String?> endDate = const Value.absent(),
                Value<String?> endDateQualifier = const Value.absent(),
                Value<String?> relatedPersonId = const Value.absent(),
                Value<String?> relatedEventId = const Value.absent(),
                Value<String?> location = const Value.absent(),
                Value<String?> legalDocument = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<bool> isPrimary = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SurnameEventsCompanion.insert(
                id: id,
                personId: personId,
                surname: surname,
                surnameType: surnameType,
                startDate: startDate,
                startDateQualifier: startDateQualifier,
                endDate: endDate,
                endDateQualifier: endDateQualifier,
                relatedPersonId: relatedPersonId,
                relatedEventId: relatedEventId,
                location: location,
                legalDocument: legalDocument,
                notes: notes,
                sortOrder: sortOrder,
                isPrimary: isPrimary,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$SurnameEventsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                personId = false,
                relatedPersonId = false,
                relatedEventId = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (personId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.personId,
                                    referencedTable:
                                        $$SurnameEventsTableReferences
                                            ._personIdTable(db),
                                    referencedColumn:
                                        $$SurnameEventsTableReferences
                                            ._personIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }
                        if (relatedPersonId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.relatedPersonId,
                                    referencedTable:
                                        $$SurnameEventsTableReferences
                                            ._relatedPersonIdTable(db),
                                    referencedColumn:
                                        $$SurnameEventsTableReferences
                                            ._relatedPersonIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }
                        if (relatedEventId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.relatedEventId,
                                    referencedTable:
                                        $$SurnameEventsTableReferences
                                            ._relatedEventIdTable(db),
                                    referencedColumn:
                                        $$SurnameEventsTableReferences
                                            ._relatedEventIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [];
                  },
                );
              },
        ),
      );
}

typedef $$SurnameEventsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SurnameEventsTable,
      SurnameEvent,
      $$SurnameEventsTableFilterComposer,
      $$SurnameEventsTableOrderingComposer,
      $$SurnameEventsTableAnnotationComposer,
      $$SurnameEventsTableCreateCompanionBuilder,
      $$SurnameEventsTableUpdateCompanionBuilder,
      (SurnameEvent, $$SurnameEventsTableReferences),
      SurnameEvent,
      PrefetchHooks Function({
        bool personId,
        bool relatedPersonId,
        bool relatedEventId,
      })
    >;
typedef $$FamiliesV2TableCreateCompanionBuilder =
    FamiliesV2Companion Function({
      required String id,
      required String treeId,
      Value<String?> husbandId,
      Value<String?> wifeId,
      Value<DateTime?> marriageDate,
      Value<String?> marriageDateQualifier,
      Value<String?> marriagePlace,
      Value<double?> marriagePlaceLat,
      Value<double?> marriagePlaceLng,
      Value<bool> wifeTookHusbandName,
      Value<bool> husbandTookWifeName,
      Value<bool> hyphenatedSurname,
      Value<bool> noNameChange,
      Value<String?> customSurnameChange,
      Value<String?> wifeMarriedSurname,
      Value<String?> wifeNameChangeType,
      Value<String?> husbandMarriedSurname,
      Value<String?> husbandNameChangeType,
      Value<DateTime?> divorceDate,
      Value<String?> divorceDateQualifier,
      Value<String?> divorcePlace,
      Value<bool> wifeRevertedToMaiden,
      Value<bool> husbandRevertedName,
      Value<String> relationshipType,
      Value<bool> isPrimaryMarriage,
      Value<String?> notes,
      Value<String?> privateNotes,
      Value<bool> isDeleted,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });
typedef $$FamiliesV2TableUpdateCompanionBuilder =
    FamiliesV2Companion Function({
      Value<String> id,
      Value<String> treeId,
      Value<String?> husbandId,
      Value<String?> wifeId,
      Value<DateTime?> marriageDate,
      Value<String?> marriageDateQualifier,
      Value<String?> marriagePlace,
      Value<double?> marriagePlaceLat,
      Value<double?> marriagePlaceLng,
      Value<bool> wifeTookHusbandName,
      Value<bool> husbandTookWifeName,
      Value<bool> hyphenatedSurname,
      Value<bool> noNameChange,
      Value<String?> customSurnameChange,
      Value<String?> wifeMarriedSurname,
      Value<String?> wifeNameChangeType,
      Value<String?> husbandMarriedSurname,
      Value<String?> husbandNameChangeType,
      Value<DateTime?> divorceDate,
      Value<String?> divorceDateQualifier,
      Value<String?> divorcePlace,
      Value<bool> wifeRevertedToMaiden,
      Value<bool> husbandRevertedName,
      Value<String> relationshipType,
      Value<bool> isPrimaryMarriage,
      Value<String?> notes,
      Value<String?> privateNotes,
      Value<bool> isDeleted,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

final class $$FamiliesV2TableReferences
    extends BaseReferences<_$AppDatabase, $FamiliesV2Table, FamiliesV2Data> {
  $$FamiliesV2TableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $FamilyTreesTable _treeIdTable(_$AppDatabase db) =>
      db.familyTrees.createAlias(
        $_aliasNameGenerator(db.familiesV2.treeId, db.familyTrees.id),
      );

  $$FamilyTreesTableProcessedTableManager get treeId {
    final $_column = $_itemColumn<String>('tree_id')!;

    final manager = $$FamilyTreesTableTableManager(
      $_db,
      $_db.familyTrees,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_treeIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $GenealogyPersonsTable _husbandIdTable(_$AppDatabase db) =>
      db.genealogyPersons.createAlias(
        $_aliasNameGenerator(db.familiesV2.husbandId, db.genealogyPersons.id),
      );

  $$GenealogyPersonsTableProcessedTableManager? get husbandId {
    final $_column = $_itemColumn<String>('husband_id');
    if ($_column == null) return null;
    final manager = $$GenealogyPersonsTableTableManager(
      $_db,
      $_db.genealogyPersons,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_husbandIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $GenealogyPersonsTable _wifeIdTable(_$AppDatabase db) =>
      db.genealogyPersons.createAlias(
        $_aliasNameGenerator(db.familiesV2.wifeId, db.genealogyPersons.id),
      );

  $$GenealogyPersonsTableProcessedTableManager? get wifeId {
    final $_column = $_itemColumn<String>('wife_id');
    if ($_column == null) return null;
    final manager = $$GenealogyPersonsTableTableManager(
      $_db,
      $_db.genealogyPersons,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_wifeIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$FamilyChildrenV2Table, List<FamilyChildrenV2Data>>
  _familyChildrenV2RefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.familyChildrenV2,
    aliasName: $_aliasNameGenerator(
      db.familiesV2.id,
      db.familyChildrenV2.familyId,
    ),
  );

  $$FamilyChildrenV2TableProcessedTableManager get familyChildrenV2Refs {
    final manager = $$FamilyChildrenV2TableTableManager(
      $_db,
      $_db.familyChildrenV2,
    ).filter((f) => f.familyId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _familyChildrenV2RefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$FamiliesV2TableFilterComposer
    extends Composer<_$AppDatabase, $FamiliesV2Table> {
  $$FamiliesV2TableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get marriageDate => $composableBuilder(
    column: $table.marriageDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get marriageDateQualifier => $composableBuilder(
    column: $table.marriageDateQualifier,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get marriagePlace => $composableBuilder(
    column: $table.marriagePlace,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get marriagePlaceLat => $composableBuilder(
    column: $table.marriagePlaceLat,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get marriagePlaceLng => $composableBuilder(
    column: $table.marriagePlaceLng,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get wifeTookHusbandName => $composableBuilder(
    column: $table.wifeTookHusbandName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get husbandTookWifeName => $composableBuilder(
    column: $table.husbandTookWifeName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get hyphenatedSurname => $composableBuilder(
    column: $table.hyphenatedSurname,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get noNameChange => $composableBuilder(
    column: $table.noNameChange,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get customSurnameChange => $composableBuilder(
    column: $table.customSurnameChange,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get wifeMarriedSurname => $composableBuilder(
    column: $table.wifeMarriedSurname,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get wifeNameChangeType => $composableBuilder(
    column: $table.wifeNameChangeType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get husbandMarriedSurname => $composableBuilder(
    column: $table.husbandMarriedSurname,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get husbandNameChangeType => $composableBuilder(
    column: $table.husbandNameChangeType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get divorceDate => $composableBuilder(
    column: $table.divorceDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get divorceDateQualifier => $composableBuilder(
    column: $table.divorceDateQualifier,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get divorcePlace => $composableBuilder(
    column: $table.divorcePlace,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get wifeRevertedToMaiden => $composableBuilder(
    column: $table.wifeRevertedToMaiden,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get husbandRevertedName => $composableBuilder(
    column: $table.husbandRevertedName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get relationshipType => $composableBuilder(
    column: $table.relationshipType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isPrimaryMarriage => $composableBuilder(
    column: $table.isPrimaryMarriage,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get privateNotes => $composableBuilder(
    column: $table.privateNotes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isDeleted => $composableBuilder(
    column: $table.isDeleted,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$FamilyTreesTableFilterComposer get treeId {
    final $$FamilyTreesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.treeId,
      referencedTable: $db.familyTrees,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FamilyTreesTableFilterComposer(
            $db: $db,
            $table: $db.familyTrees,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$GenealogyPersonsTableFilterComposer get husbandId {
    final $$GenealogyPersonsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.husbandId,
      referencedTable: $db.genealogyPersons,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$GenealogyPersonsTableFilterComposer(
            $db: $db,
            $table: $db.genealogyPersons,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$GenealogyPersonsTableFilterComposer get wifeId {
    final $$GenealogyPersonsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.wifeId,
      referencedTable: $db.genealogyPersons,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$GenealogyPersonsTableFilterComposer(
            $db: $db,
            $table: $db.genealogyPersons,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> familyChildrenV2Refs(
    Expression<bool> Function($$FamilyChildrenV2TableFilterComposer f) f,
  ) {
    final $$FamilyChildrenV2TableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.familyChildrenV2,
      getReferencedColumn: (t) => t.familyId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FamilyChildrenV2TableFilterComposer(
            $db: $db,
            $table: $db.familyChildrenV2,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$FamiliesV2TableOrderingComposer
    extends Composer<_$AppDatabase, $FamiliesV2Table> {
  $$FamiliesV2TableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get marriageDate => $composableBuilder(
    column: $table.marriageDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get marriageDateQualifier => $composableBuilder(
    column: $table.marriageDateQualifier,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get marriagePlace => $composableBuilder(
    column: $table.marriagePlace,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get marriagePlaceLat => $composableBuilder(
    column: $table.marriagePlaceLat,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get marriagePlaceLng => $composableBuilder(
    column: $table.marriagePlaceLng,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get wifeTookHusbandName => $composableBuilder(
    column: $table.wifeTookHusbandName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get husbandTookWifeName => $composableBuilder(
    column: $table.husbandTookWifeName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get hyphenatedSurname => $composableBuilder(
    column: $table.hyphenatedSurname,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get noNameChange => $composableBuilder(
    column: $table.noNameChange,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get customSurnameChange => $composableBuilder(
    column: $table.customSurnameChange,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get wifeMarriedSurname => $composableBuilder(
    column: $table.wifeMarriedSurname,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get wifeNameChangeType => $composableBuilder(
    column: $table.wifeNameChangeType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get husbandMarriedSurname => $composableBuilder(
    column: $table.husbandMarriedSurname,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get husbandNameChangeType => $composableBuilder(
    column: $table.husbandNameChangeType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get divorceDate => $composableBuilder(
    column: $table.divorceDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get divorceDateQualifier => $composableBuilder(
    column: $table.divorceDateQualifier,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get divorcePlace => $composableBuilder(
    column: $table.divorcePlace,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get wifeRevertedToMaiden => $composableBuilder(
    column: $table.wifeRevertedToMaiden,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get husbandRevertedName => $composableBuilder(
    column: $table.husbandRevertedName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get relationshipType => $composableBuilder(
    column: $table.relationshipType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isPrimaryMarriage => $composableBuilder(
    column: $table.isPrimaryMarriage,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get privateNotes => $composableBuilder(
    column: $table.privateNotes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isDeleted => $composableBuilder(
    column: $table.isDeleted,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$FamilyTreesTableOrderingComposer get treeId {
    final $$FamilyTreesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.treeId,
      referencedTable: $db.familyTrees,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FamilyTreesTableOrderingComposer(
            $db: $db,
            $table: $db.familyTrees,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$GenealogyPersonsTableOrderingComposer get husbandId {
    final $$GenealogyPersonsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.husbandId,
      referencedTable: $db.genealogyPersons,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$GenealogyPersonsTableOrderingComposer(
            $db: $db,
            $table: $db.genealogyPersons,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$GenealogyPersonsTableOrderingComposer get wifeId {
    final $$GenealogyPersonsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.wifeId,
      referencedTable: $db.genealogyPersons,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$GenealogyPersonsTableOrderingComposer(
            $db: $db,
            $table: $db.genealogyPersons,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$FamiliesV2TableAnnotationComposer
    extends Composer<_$AppDatabase, $FamiliesV2Table> {
  $$FamiliesV2TableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get marriageDate => $composableBuilder(
    column: $table.marriageDate,
    builder: (column) => column,
  );

  GeneratedColumn<String> get marriageDateQualifier => $composableBuilder(
    column: $table.marriageDateQualifier,
    builder: (column) => column,
  );

  GeneratedColumn<String> get marriagePlace => $composableBuilder(
    column: $table.marriagePlace,
    builder: (column) => column,
  );

  GeneratedColumn<double> get marriagePlaceLat => $composableBuilder(
    column: $table.marriagePlaceLat,
    builder: (column) => column,
  );

  GeneratedColumn<double> get marriagePlaceLng => $composableBuilder(
    column: $table.marriagePlaceLng,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get wifeTookHusbandName => $composableBuilder(
    column: $table.wifeTookHusbandName,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get husbandTookWifeName => $composableBuilder(
    column: $table.husbandTookWifeName,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get hyphenatedSurname => $composableBuilder(
    column: $table.hyphenatedSurname,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get noNameChange => $composableBuilder(
    column: $table.noNameChange,
    builder: (column) => column,
  );

  GeneratedColumn<String> get customSurnameChange => $composableBuilder(
    column: $table.customSurnameChange,
    builder: (column) => column,
  );

  GeneratedColumn<String> get wifeMarriedSurname => $composableBuilder(
    column: $table.wifeMarriedSurname,
    builder: (column) => column,
  );

  GeneratedColumn<String> get wifeNameChangeType => $composableBuilder(
    column: $table.wifeNameChangeType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get husbandMarriedSurname => $composableBuilder(
    column: $table.husbandMarriedSurname,
    builder: (column) => column,
  );

  GeneratedColumn<String> get husbandNameChangeType => $composableBuilder(
    column: $table.husbandNameChangeType,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get divorceDate => $composableBuilder(
    column: $table.divorceDate,
    builder: (column) => column,
  );

  GeneratedColumn<String> get divorceDateQualifier => $composableBuilder(
    column: $table.divorceDateQualifier,
    builder: (column) => column,
  );

  GeneratedColumn<String> get divorcePlace => $composableBuilder(
    column: $table.divorcePlace,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get wifeRevertedToMaiden => $composableBuilder(
    column: $table.wifeRevertedToMaiden,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get husbandRevertedName => $composableBuilder(
    column: $table.husbandRevertedName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get relationshipType => $composableBuilder(
    column: $table.relationshipType,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isPrimaryMarriage => $composableBuilder(
    column: $table.isPrimaryMarriage,
    builder: (column) => column,
  );

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<String> get privateNotes => $composableBuilder(
    column: $table.privateNotes,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isDeleted =>
      $composableBuilder(column: $table.isDeleted, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$FamilyTreesTableAnnotationComposer get treeId {
    final $$FamilyTreesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.treeId,
      referencedTable: $db.familyTrees,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FamilyTreesTableAnnotationComposer(
            $db: $db,
            $table: $db.familyTrees,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$GenealogyPersonsTableAnnotationComposer get husbandId {
    final $$GenealogyPersonsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.husbandId,
      referencedTable: $db.genealogyPersons,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$GenealogyPersonsTableAnnotationComposer(
            $db: $db,
            $table: $db.genealogyPersons,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$GenealogyPersonsTableAnnotationComposer get wifeId {
    final $$GenealogyPersonsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.wifeId,
      referencedTable: $db.genealogyPersons,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$GenealogyPersonsTableAnnotationComposer(
            $db: $db,
            $table: $db.genealogyPersons,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> familyChildrenV2Refs<T extends Object>(
    Expression<T> Function($$FamilyChildrenV2TableAnnotationComposer a) f,
  ) {
    final $$FamilyChildrenV2TableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.familyChildrenV2,
      getReferencedColumn: (t) => t.familyId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FamilyChildrenV2TableAnnotationComposer(
            $db: $db,
            $table: $db.familyChildrenV2,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$FamiliesV2TableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $FamiliesV2Table,
          FamiliesV2Data,
          $$FamiliesV2TableFilterComposer,
          $$FamiliesV2TableOrderingComposer,
          $$FamiliesV2TableAnnotationComposer,
          $$FamiliesV2TableCreateCompanionBuilder,
          $$FamiliesV2TableUpdateCompanionBuilder,
          (FamiliesV2Data, $$FamiliesV2TableReferences),
          FamiliesV2Data,
          PrefetchHooks Function({
            bool treeId,
            bool husbandId,
            bool wifeId,
            bool familyChildrenV2Refs,
          })
        > {
  $$FamiliesV2TableTableManager(_$AppDatabase db, $FamiliesV2Table table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$FamiliesV2TableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$FamiliesV2TableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$FamiliesV2TableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> treeId = const Value.absent(),
                Value<String?> husbandId = const Value.absent(),
                Value<String?> wifeId = const Value.absent(),
                Value<DateTime?> marriageDate = const Value.absent(),
                Value<String?> marriageDateQualifier = const Value.absent(),
                Value<String?> marriagePlace = const Value.absent(),
                Value<double?> marriagePlaceLat = const Value.absent(),
                Value<double?> marriagePlaceLng = const Value.absent(),
                Value<bool> wifeTookHusbandName = const Value.absent(),
                Value<bool> husbandTookWifeName = const Value.absent(),
                Value<bool> hyphenatedSurname = const Value.absent(),
                Value<bool> noNameChange = const Value.absent(),
                Value<String?> customSurnameChange = const Value.absent(),
                Value<String?> wifeMarriedSurname = const Value.absent(),
                Value<String?> wifeNameChangeType = const Value.absent(),
                Value<String?> husbandMarriedSurname = const Value.absent(),
                Value<String?> husbandNameChangeType = const Value.absent(),
                Value<DateTime?> divorceDate = const Value.absent(),
                Value<String?> divorceDateQualifier = const Value.absent(),
                Value<String?> divorcePlace = const Value.absent(),
                Value<bool> wifeRevertedToMaiden = const Value.absent(),
                Value<bool> husbandRevertedName = const Value.absent(),
                Value<String> relationshipType = const Value.absent(),
                Value<bool> isPrimaryMarriage = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<String?> privateNotes = const Value.absent(),
                Value<bool> isDeleted = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => FamiliesV2Companion(
                id: id,
                treeId: treeId,
                husbandId: husbandId,
                wifeId: wifeId,
                marriageDate: marriageDate,
                marriageDateQualifier: marriageDateQualifier,
                marriagePlace: marriagePlace,
                marriagePlaceLat: marriagePlaceLat,
                marriagePlaceLng: marriagePlaceLng,
                wifeTookHusbandName: wifeTookHusbandName,
                husbandTookWifeName: husbandTookWifeName,
                hyphenatedSurname: hyphenatedSurname,
                noNameChange: noNameChange,
                customSurnameChange: customSurnameChange,
                wifeMarriedSurname: wifeMarriedSurname,
                wifeNameChangeType: wifeNameChangeType,
                husbandMarriedSurname: husbandMarriedSurname,
                husbandNameChangeType: husbandNameChangeType,
                divorceDate: divorceDate,
                divorceDateQualifier: divorceDateQualifier,
                divorcePlace: divorcePlace,
                wifeRevertedToMaiden: wifeRevertedToMaiden,
                husbandRevertedName: husbandRevertedName,
                relationshipType: relationshipType,
                isPrimaryMarriage: isPrimaryMarriage,
                notes: notes,
                privateNotes: privateNotes,
                isDeleted: isDeleted,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String treeId,
                Value<String?> husbandId = const Value.absent(),
                Value<String?> wifeId = const Value.absent(),
                Value<DateTime?> marriageDate = const Value.absent(),
                Value<String?> marriageDateQualifier = const Value.absent(),
                Value<String?> marriagePlace = const Value.absent(),
                Value<double?> marriagePlaceLat = const Value.absent(),
                Value<double?> marriagePlaceLng = const Value.absent(),
                Value<bool> wifeTookHusbandName = const Value.absent(),
                Value<bool> husbandTookWifeName = const Value.absent(),
                Value<bool> hyphenatedSurname = const Value.absent(),
                Value<bool> noNameChange = const Value.absent(),
                Value<String?> customSurnameChange = const Value.absent(),
                Value<String?> wifeMarriedSurname = const Value.absent(),
                Value<String?> wifeNameChangeType = const Value.absent(),
                Value<String?> husbandMarriedSurname = const Value.absent(),
                Value<String?> husbandNameChangeType = const Value.absent(),
                Value<DateTime?> divorceDate = const Value.absent(),
                Value<String?> divorceDateQualifier = const Value.absent(),
                Value<String?> divorcePlace = const Value.absent(),
                Value<bool> wifeRevertedToMaiden = const Value.absent(),
                Value<bool> husbandRevertedName = const Value.absent(),
                Value<String> relationshipType = const Value.absent(),
                Value<bool> isPrimaryMarriage = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<String?> privateNotes = const Value.absent(),
                Value<bool> isDeleted = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => FamiliesV2Companion.insert(
                id: id,
                treeId: treeId,
                husbandId: husbandId,
                wifeId: wifeId,
                marriageDate: marriageDate,
                marriageDateQualifier: marriageDateQualifier,
                marriagePlace: marriagePlace,
                marriagePlaceLat: marriagePlaceLat,
                marriagePlaceLng: marriagePlaceLng,
                wifeTookHusbandName: wifeTookHusbandName,
                husbandTookWifeName: husbandTookWifeName,
                hyphenatedSurname: hyphenatedSurname,
                noNameChange: noNameChange,
                customSurnameChange: customSurnameChange,
                wifeMarriedSurname: wifeMarriedSurname,
                wifeNameChangeType: wifeNameChangeType,
                husbandMarriedSurname: husbandMarriedSurname,
                husbandNameChangeType: husbandNameChangeType,
                divorceDate: divorceDate,
                divorceDateQualifier: divorceDateQualifier,
                divorcePlace: divorcePlace,
                wifeRevertedToMaiden: wifeRevertedToMaiden,
                husbandRevertedName: husbandRevertedName,
                relationshipType: relationshipType,
                isPrimaryMarriage: isPrimaryMarriage,
                notes: notes,
                privateNotes: privateNotes,
                isDeleted: isDeleted,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$FamiliesV2TableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                treeId = false,
                husbandId = false,
                wifeId = false,
                familyChildrenV2Refs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (familyChildrenV2Refs) db.familyChildrenV2,
                  ],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (treeId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.treeId,
                                    referencedTable: $$FamiliesV2TableReferences
                                        ._treeIdTable(db),
                                    referencedColumn:
                                        $$FamiliesV2TableReferences
                                            ._treeIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }
                        if (husbandId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.husbandId,
                                    referencedTable: $$FamiliesV2TableReferences
                                        ._husbandIdTable(db),
                                    referencedColumn:
                                        $$FamiliesV2TableReferences
                                            ._husbandIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }
                        if (wifeId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.wifeId,
                                    referencedTable: $$FamiliesV2TableReferences
                                        ._wifeIdTable(db),
                                    referencedColumn:
                                        $$FamiliesV2TableReferences
                                            ._wifeIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (familyChildrenV2Refs)
                        await $_getPrefetchedData<
                          FamiliesV2Data,
                          $FamiliesV2Table,
                          FamilyChildrenV2Data
                        >(
                          currentTable: table,
                          referencedTable: $$FamiliesV2TableReferences
                              ._familyChildrenV2RefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$FamiliesV2TableReferences(
                                db,
                                table,
                                p0,
                              ).familyChildrenV2Refs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.familyId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$FamiliesV2TableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $FamiliesV2Table,
      FamiliesV2Data,
      $$FamiliesV2TableFilterComposer,
      $$FamiliesV2TableOrderingComposer,
      $$FamiliesV2TableAnnotationComposer,
      $$FamiliesV2TableCreateCompanionBuilder,
      $$FamiliesV2TableUpdateCompanionBuilder,
      (FamiliesV2Data, $$FamiliesV2TableReferences),
      FamiliesV2Data,
      PrefetchHooks Function({
        bool treeId,
        bool husbandId,
        bool wifeId,
        bool familyChildrenV2Refs,
      })
    >;
typedef $$FamilyChildrenV2TableCreateCompanionBuilder =
    FamilyChildrenV2Companion Function({
      required String id,
      required String familyId,
      required String childId,
      Value<int?> birthOrder,
      Value<String> relationshipType,
      Value<String?> childSurnameAtBirth,
      Value<String?> paternalRelationship,
      Value<String?> maternalRelationship,
      Value<String?> notes,
      Value<bool> isDeleted,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });
typedef $$FamilyChildrenV2TableUpdateCompanionBuilder =
    FamilyChildrenV2Companion Function({
      Value<String> id,
      Value<String> familyId,
      Value<String> childId,
      Value<int?> birthOrder,
      Value<String> relationshipType,
      Value<String?> childSurnameAtBirth,
      Value<String?> paternalRelationship,
      Value<String?> maternalRelationship,
      Value<String?> notes,
      Value<bool> isDeleted,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

final class $$FamilyChildrenV2TableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $FamilyChildrenV2Table,
          FamilyChildrenV2Data
        > {
  $$FamilyChildrenV2TableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $FamiliesV2Table _familyIdTable(_$AppDatabase db) =>
      db.familiesV2.createAlias(
        $_aliasNameGenerator(db.familyChildrenV2.familyId, db.familiesV2.id),
      );

  $$FamiliesV2TableProcessedTableManager get familyId {
    final $_column = $_itemColumn<String>('family_id')!;

    final manager = $$FamiliesV2TableTableManager(
      $_db,
      $_db.familiesV2,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_familyIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $GenealogyPersonsTable _childIdTable(_$AppDatabase db) =>
      db.genealogyPersons.createAlias(
        $_aliasNameGenerator(
          db.familyChildrenV2.childId,
          db.genealogyPersons.id,
        ),
      );

  $$GenealogyPersonsTableProcessedTableManager get childId {
    final $_column = $_itemColumn<String>('child_id')!;

    final manager = $$GenealogyPersonsTableTableManager(
      $_db,
      $_db.genealogyPersons,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_childIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$FamilyChildrenV2TableFilterComposer
    extends Composer<_$AppDatabase, $FamilyChildrenV2Table> {
  $$FamilyChildrenV2TableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get birthOrder => $composableBuilder(
    column: $table.birthOrder,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get relationshipType => $composableBuilder(
    column: $table.relationshipType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get childSurnameAtBirth => $composableBuilder(
    column: $table.childSurnameAtBirth,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get paternalRelationship => $composableBuilder(
    column: $table.paternalRelationship,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get maternalRelationship => $composableBuilder(
    column: $table.maternalRelationship,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isDeleted => $composableBuilder(
    column: $table.isDeleted,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$FamiliesV2TableFilterComposer get familyId {
    final $$FamiliesV2TableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.familyId,
      referencedTable: $db.familiesV2,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FamiliesV2TableFilterComposer(
            $db: $db,
            $table: $db.familiesV2,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$GenealogyPersonsTableFilterComposer get childId {
    final $$GenealogyPersonsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.childId,
      referencedTable: $db.genealogyPersons,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$GenealogyPersonsTableFilterComposer(
            $db: $db,
            $table: $db.genealogyPersons,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$FamilyChildrenV2TableOrderingComposer
    extends Composer<_$AppDatabase, $FamilyChildrenV2Table> {
  $$FamilyChildrenV2TableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get birthOrder => $composableBuilder(
    column: $table.birthOrder,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get relationshipType => $composableBuilder(
    column: $table.relationshipType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get childSurnameAtBirth => $composableBuilder(
    column: $table.childSurnameAtBirth,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get paternalRelationship => $composableBuilder(
    column: $table.paternalRelationship,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get maternalRelationship => $composableBuilder(
    column: $table.maternalRelationship,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isDeleted => $composableBuilder(
    column: $table.isDeleted,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$FamiliesV2TableOrderingComposer get familyId {
    final $$FamiliesV2TableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.familyId,
      referencedTable: $db.familiesV2,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FamiliesV2TableOrderingComposer(
            $db: $db,
            $table: $db.familiesV2,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$GenealogyPersonsTableOrderingComposer get childId {
    final $$GenealogyPersonsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.childId,
      referencedTable: $db.genealogyPersons,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$GenealogyPersonsTableOrderingComposer(
            $db: $db,
            $table: $db.genealogyPersons,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$FamilyChildrenV2TableAnnotationComposer
    extends Composer<_$AppDatabase, $FamilyChildrenV2Table> {
  $$FamilyChildrenV2TableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get birthOrder => $composableBuilder(
    column: $table.birthOrder,
    builder: (column) => column,
  );

  GeneratedColumn<String> get relationshipType => $composableBuilder(
    column: $table.relationshipType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get childSurnameAtBirth => $composableBuilder(
    column: $table.childSurnameAtBirth,
    builder: (column) => column,
  );

  GeneratedColumn<String> get paternalRelationship => $composableBuilder(
    column: $table.paternalRelationship,
    builder: (column) => column,
  );

  GeneratedColumn<String> get maternalRelationship => $composableBuilder(
    column: $table.maternalRelationship,
    builder: (column) => column,
  );

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<bool> get isDeleted =>
      $composableBuilder(column: $table.isDeleted, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$FamiliesV2TableAnnotationComposer get familyId {
    final $$FamiliesV2TableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.familyId,
      referencedTable: $db.familiesV2,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FamiliesV2TableAnnotationComposer(
            $db: $db,
            $table: $db.familiesV2,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$GenealogyPersonsTableAnnotationComposer get childId {
    final $$GenealogyPersonsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.childId,
      referencedTable: $db.genealogyPersons,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$GenealogyPersonsTableAnnotationComposer(
            $db: $db,
            $table: $db.genealogyPersons,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$FamilyChildrenV2TableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $FamilyChildrenV2Table,
          FamilyChildrenV2Data,
          $$FamilyChildrenV2TableFilterComposer,
          $$FamilyChildrenV2TableOrderingComposer,
          $$FamilyChildrenV2TableAnnotationComposer,
          $$FamilyChildrenV2TableCreateCompanionBuilder,
          $$FamilyChildrenV2TableUpdateCompanionBuilder,
          (FamilyChildrenV2Data, $$FamilyChildrenV2TableReferences),
          FamilyChildrenV2Data,
          PrefetchHooks Function({bool familyId, bool childId})
        > {
  $$FamilyChildrenV2TableTableManager(
    _$AppDatabase db,
    $FamilyChildrenV2Table table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$FamilyChildrenV2TableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$FamilyChildrenV2TableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$FamilyChildrenV2TableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> familyId = const Value.absent(),
                Value<String> childId = const Value.absent(),
                Value<int?> birthOrder = const Value.absent(),
                Value<String> relationshipType = const Value.absent(),
                Value<String?> childSurnameAtBirth = const Value.absent(),
                Value<String?> paternalRelationship = const Value.absent(),
                Value<String?> maternalRelationship = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<bool> isDeleted = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => FamilyChildrenV2Companion(
                id: id,
                familyId: familyId,
                childId: childId,
                birthOrder: birthOrder,
                relationshipType: relationshipType,
                childSurnameAtBirth: childSurnameAtBirth,
                paternalRelationship: paternalRelationship,
                maternalRelationship: maternalRelationship,
                notes: notes,
                isDeleted: isDeleted,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String familyId,
                required String childId,
                Value<int?> birthOrder = const Value.absent(),
                Value<String> relationshipType = const Value.absent(),
                Value<String?> childSurnameAtBirth = const Value.absent(),
                Value<String?> paternalRelationship = const Value.absent(),
                Value<String?> maternalRelationship = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<bool> isDeleted = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => FamilyChildrenV2Companion.insert(
                id: id,
                familyId: familyId,
                childId: childId,
                birthOrder: birthOrder,
                relationshipType: relationshipType,
                childSurnameAtBirth: childSurnameAtBirth,
                paternalRelationship: paternalRelationship,
                maternalRelationship: maternalRelationship,
                notes: notes,
                isDeleted: isDeleted,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$FamilyChildrenV2TableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({familyId = false, childId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (familyId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.familyId,
                                referencedTable:
                                    $$FamilyChildrenV2TableReferences
                                        ._familyIdTable(db),
                                referencedColumn:
                                    $$FamilyChildrenV2TableReferences
                                        ._familyIdTable(db)
                                        .id,
                              )
                              as T;
                    }
                    if (childId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.childId,
                                referencedTable:
                                    $$FamilyChildrenV2TableReferences
                                        ._childIdTable(db),
                                referencedColumn:
                                    $$FamilyChildrenV2TableReferences
                                        ._childIdTable(db)
                                        .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$FamilyChildrenV2TableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $FamilyChildrenV2Table,
      FamilyChildrenV2Data,
      $$FamilyChildrenV2TableFilterComposer,
      $$FamilyChildrenV2TableOrderingComposer,
      $$FamilyChildrenV2TableAnnotationComposer,
      $$FamilyChildrenV2TableCreateCompanionBuilder,
      $$FamilyChildrenV2TableUpdateCompanionBuilder,
      (FamilyChildrenV2Data, $$FamilyChildrenV2TableReferences),
      FamilyChildrenV2Data,
      PrefetchHooks Function({bool familyId, bool childId})
    >;
typedef $$MediaItemsTableCreateCompanionBuilder =
    MediaItemsCompanion Function({
      required String id,
      required String personId,
      required String filePath,
      required String mediaType,
      Value<String?> title,
      Value<String?> description,
      required DateTime createdAt,
      Value<int> rowid,
    });
typedef $$MediaItemsTableUpdateCompanionBuilder =
    MediaItemsCompanion Function({
      Value<String> id,
      Value<String> personId,
      Value<String> filePath,
      Value<String> mediaType,
      Value<String?> title,
      Value<String?> description,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });

final class $$MediaItemsTableReferences
    extends BaseReferences<_$AppDatabase, $MediaItemsTable, MediaItem> {
  $$MediaItemsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $GenealogyPersonsTable _personIdTable(_$AppDatabase db) =>
      db.genealogyPersons.createAlias(
        $_aliasNameGenerator(db.mediaItems.personId, db.genealogyPersons.id),
      );

  $$GenealogyPersonsTableProcessedTableManager get personId {
    final $_column = $_itemColumn<String>('person_id')!;

    final manager = $$GenealogyPersonsTableTableManager(
      $_db,
      $_db.genealogyPersons,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_personIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$MediaItemsTableFilterComposer
    extends Composer<_$AppDatabase, $MediaItemsTable> {
  $$MediaItemsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get filePath => $composableBuilder(
    column: $table.filePath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get mediaType => $composableBuilder(
    column: $table.mediaType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  $$GenealogyPersonsTableFilterComposer get personId {
    final $$GenealogyPersonsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.personId,
      referencedTable: $db.genealogyPersons,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$GenealogyPersonsTableFilterComposer(
            $db: $db,
            $table: $db.genealogyPersons,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$MediaItemsTableOrderingComposer
    extends Composer<_$AppDatabase, $MediaItemsTable> {
  $$MediaItemsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get filePath => $composableBuilder(
    column: $table.filePath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get mediaType => $composableBuilder(
    column: $table.mediaType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$GenealogyPersonsTableOrderingComposer get personId {
    final $$GenealogyPersonsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.personId,
      referencedTable: $db.genealogyPersons,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$GenealogyPersonsTableOrderingComposer(
            $db: $db,
            $table: $db.genealogyPersons,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$MediaItemsTableAnnotationComposer
    extends Composer<_$AppDatabase, $MediaItemsTable> {
  $$MediaItemsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get filePath =>
      $composableBuilder(column: $table.filePath, builder: (column) => column);

  GeneratedColumn<String> get mediaType =>
      $composableBuilder(column: $table.mediaType, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$GenealogyPersonsTableAnnotationComposer get personId {
    final $$GenealogyPersonsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.personId,
      referencedTable: $db.genealogyPersons,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$GenealogyPersonsTableAnnotationComposer(
            $db: $db,
            $table: $db.genealogyPersons,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$MediaItemsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $MediaItemsTable,
          MediaItem,
          $$MediaItemsTableFilterComposer,
          $$MediaItemsTableOrderingComposer,
          $$MediaItemsTableAnnotationComposer,
          $$MediaItemsTableCreateCompanionBuilder,
          $$MediaItemsTableUpdateCompanionBuilder,
          (MediaItem, $$MediaItemsTableReferences),
          MediaItem,
          PrefetchHooks Function({bool personId})
        > {
  $$MediaItemsTableTableManager(_$AppDatabase db, $MediaItemsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MediaItemsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MediaItemsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MediaItemsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> personId = const Value.absent(),
                Value<String> filePath = const Value.absent(),
                Value<String> mediaType = const Value.absent(),
                Value<String?> title = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MediaItemsCompanion(
                id: id,
                personId: personId,
                filePath: filePath,
                mediaType: mediaType,
                title: title,
                description: description,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String personId,
                required String filePath,
                required String mediaType,
                Value<String?> title = const Value.absent(),
                Value<String?> description = const Value.absent(),
                required DateTime createdAt,
                Value<int> rowid = const Value.absent(),
              }) => MediaItemsCompanion.insert(
                id: id,
                personId: personId,
                filePath: filePath,
                mediaType: mediaType,
                title: title,
                description: description,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$MediaItemsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({personId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (personId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.personId,
                                referencedTable: $$MediaItemsTableReferences
                                    ._personIdTable(db),
                                referencedColumn: $$MediaItemsTableReferences
                                    ._personIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$MediaItemsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $MediaItemsTable,
      MediaItem,
      $$MediaItemsTableFilterComposer,
      $$MediaItemsTableOrderingComposer,
      $$MediaItemsTableAnnotationComposer,
      $$MediaItemsTableCreateCompanionBuilder,
      $$MediaItemsTableUpdateCompanionBuilder,
      (MediaItem, $$MediaItemsTableReferences),
      MediaItem,
      PrefetchHooks Function({bool personId})
    >;
typedef $$DuplicateMarkersTableCreateCompanionBuilder =
    DuplicateMarkersCompanion Function({
      required String id,
      required String personAId,
      required String personBId,
      Value<String?> reason,
      required DateTime createdAt,
      Value<int> rowid,
    });
typedef $$DuplicateMarkersTableUpdateCompanionBuilder =
    DuplicateMarkersCompanion Function({
      Value<String> id,
      Value<String> personAId,
      Value<String> personBId,
      Value<String?> reason,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });

final class $$DuplicateMarkersTableReferences
    extends
        BaseReferences<_$AppDatabase, $DuplicateMarkersTable, DuplicateMarker> {
  $$DuplicateMarkersTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $GenealogyPersonsTable _personAIdTable(_$AppDatabase db) =>
      db.genealogyPersons.createAlias(
        $_aliasNameGenerator(
          db.duplicateMarkers.personAId,
          db.genealogyPersons.id,
        ),
      );

  $$GenealogyPersonsTableProcessedTableManager get personAId {
    final $_column = $_itemColumn<String>('person_a_id')!;

    final manager = $$GenealogyPersonsTableTableManager(
      $_db,
      $_db.genealogyPersons,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_personAIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $GenealogyPersonsTable _personBIdTable(_$AppDatabase db) =>
      db.genealogyPersons.createAlias(
        $_aliasNameGenerator(
          db.duplicateMarkers.personBId,
          db.genealogyPersons.id,
        ),
      );

  $$GenealogyPersonsTableProcessedTableManager get personBId {
    final $_column = $_itemColumn<String>('person_b_id')!;

    final manager = $$GenealogyPersonsTableTableManager(
      $_db,
      $_db.genealogyPersons,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_personBIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$DuplicateMarkersTableFilterComposer
    extends Composer<_$AppDatabase, $DuplicateMarkersTable> {
  $$DuplicateMarkersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get reason => $composableBuilder(
    column: $table.reason,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  $$GenealogyPersonsTableFilterComposer get personAId {
    final $$GenealogyPersonsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.personAId,
      referencedTable: $db.genealogyPersons,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$GenealogyPersonsTableFilterComposer(
            $db: $db,
            $table: $db.genealogyPersons,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$GenealogyPersonsTableFilterComposer get personBId {
    final $$GenealogyPersonsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.personBId,
      referencedTable: $db.genealogyPersons,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$GenealogyPersonsTableFilterComposer(
            $db: $db,
            $table: $db.genealogyPersons,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$DuplicateMarkersTableOrderingComposer
    extends Composer<_$AppDatabase, $DuplicateMarkersTable> {
  $$DuplicateMarkersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get reason => $composableBuilder(
    column: $table.reason,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$GenealogyPersonsTableOrderingComposer get personAId {
    final $$GenealogyPersonsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.personAId,
      referencedTable: $db.genealogyPersons,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$GenealogyPersonsTableOrderingComposer(
            $db: $db,
            $table: $db.genealogyPersons,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$GenealogyPersonsTableOrderingComposer get personBId {
    final $$GenealogyPersonsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.personBId,
      referencedTable: $db.genealogyPersons,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$GenealogyPersonsTableOrderingComposer(
            $db: $db,
            $table: $db.genealogyPersons,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$DuplicateMarkersTableAnnotationComposer
    extends Composer<_$AppDatabase, $DuplicateMarkersTable> {
  $$DuplicateMarkersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get reason =>
      $composableBuilder(column: $table.reason, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$GenealogyPersonsTableAnnotationComposer get personAId {
    final $$GenealogyPersonsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.personAId,
      referencedTable: $db.genealogyPersons,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$GenealogyPersonsTableAnnotationComposer(
            $db: $db,
            $table: $db.genealogyPersons,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$GenealogyPersonsTableAnnotationComposer get personBId {
    final $$GenealogyPersonsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.personBId,
      referencedTable: $db.genealogyPersons,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$GenealogyPersonsTableAnnotationComposer(
            $db: $db,
            $table: $db.genealogyPersons,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$DuplicateMarkersTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $DuplicateMarkersTable,
          DuplicateMarker,
          $$DuplicateMarkersTableFilterComposer,
          $$DuplicateMarkersTableOrderingComposer,
          $$DuplicateMarkersTableAnnotationComposer,
          $$DuplicateMarkersTableCreateCompanionBuilder,
          $$DuplicateMarkersTableUpdateCompanionBuilder,
          (DuplicateMarker, $$DuplicateMarkersTableReferences),
          DuplicateMarker,
          PrefetchHooks Function({bool personAId, bool personBId})
        > {
  $$DuplicateMarkersTableTableManager(
    _$AppDatabase db,
    $DuplicateMarkersTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DuplicateMarkersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DuplicateMarkersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DuplicateMarkersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> personAId = const Value.absent(),
                Value<String> personBId = const Value.absent(),
                Value<String?> reason = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DuplicateMarkersCompanion(
                id: id,
                personAId: personAId,
                personBId: personBId,
                reason: reason,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String personAId,
                required String personBId,
                Value<String?> reason = const Value.absent(),
                required DateTime createdAt,
                Value<int> rowid = const Value.absent(),
              }) => DuplicateMarkersCompanion.insert(
                id: id,
                personAId: personAId,
                personBId: personBId,
                reason: reason,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$DuplicateMarkersTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({personAId = false, personBId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (personAId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.personAId,
                                referencedTable:
                                    $$DuplicateMarkersTableReferences
                                        ._personAIdTable(db),
                                referencedColumn:
                                    $$DuplicateMarkersTableReferences
                                        ._personAIdTable(db)
                                        .id,
                              )
                              as T;
                    }
                    if (personBId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.personBId,
                                referencedTable:
                                    $$DuplicateMarkersTableReferences
                                        ._personBIdTable(db),
                                referencedColumn:
                                    $$DuplicateMarkersTableReferences
                                        ._personBIdTable(db)
                                        .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$DuplicateMarkersTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $DuplicateMarkersTable,
      DuplicateMarker,
      $$DuplicateMarkersTableFilterComposer,
      $$DuplicateMarkersTableOrderingComposer,
      $$DuplicateMarkersTableAnnotationComposer,
      $$DuplicateMarkersTableCreateCompanionBuilder,
      $$DuplicateMarkersTableUpdateCompanionBuilder,
      (DuplicateMarker, $$DuplicateMarkersTableReferences),
      DuplicateMarker,
      PrefetchHooks Function({bool personAId, bool personBId})
    >;
typedef $$ResearchNotesTableCreateCompanionBuilder =
    ResearchNotesCompanion Function({
      required String id,
      Value<String?> personId,
      required String noteText,
      Value<String?> researchQuestion,
      Value<double?> noteDateSort,
      Value<String?> noteDateDisplay,
      Value<bool> resolved,
      required DateTime createdAt,
      Value<int> rowid,
    });
typedef $$ResearchNotesTableUpdateCompanionBuilder =
    ResearchNotesCompanion Function({
      Value<String> id,
      Value<String?> personId,
      Value<String> noteText,
      Value<String?> researchQuestion,
      Value<double?> noteDateSort,
      Value<String?> noteDateDisplay,
      Value<bool> resolved,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });

final class $$ResearchNotesTableReferences
    extends BaseReferences<_$AppDatabase, $ResearchNotesTable, ResearchNote> {
  $$ResearchNotesTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $GenealogyPersonsTable _personIdTable(_$AppDatabase db) =>
      db.genealogyPersons.createAlias(
        $_aliasNameGenerator(db.researchNotes.personId, db.genealogyPersons.id),
      );

  $$GenealogyPersonsTableProcessedTableManager? get personId {
    final $_column = $_itemColumn<String>('person_id');
    if ($_column == null) return null;
    final manager = $$GenealogyPersonsTableTableManager(
      $_db,
      $_db.genealogyPersons,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_personIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$ResearchNotesTableFilterComposer
    extends Composer<_$AppDatabase, $ResearchNotesTable> {
  $$ResearchNotesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get noteText => $composableBuilder(
    column: $table.noteText,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get researchQuestion => $composableBuilder(
    column: $table.researchQuestion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get noteDateSort => $composableBuilder(
    column: $table.noteDateSort,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get noteDateDisplay => $composableBuilder(
    column: $table.noteDateDisplay,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get resolved => $composableBuilder(
    column: $table.resolved,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  $$GenealogyPersonsTableFilterComposer get personId {
    final $$GenealogyPersonsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.personId,
      referencedTable: $db.genealogyPersons,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$GenealogyPersonsTableFilterComposer(
            $db: $db,
            $table: $db.genealogyPersons,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ResearchNotesTableOrderingComposer
    extends Composer<_$AppDatabase, $ResearchNotesTable> {
  $$ResearchNotesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get noteText => $composableBuilder(
    column: $table.noteText,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get researchQuestion => $composableBuilder(
    column: $table.researchQuestion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get noteDateSort => $composableBuilder(
    column: $table.noteDateSort,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get noteDateDisplay => $composableBuilder(
    column: $table.noteDateDisplay,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get resolved => $composableBuilder(
    column: $table.resolved,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$GenealogyPersonsTableOrderingComposer get personId {
    final $$GenealogyPersonsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.personId,
      referencedTable: $db.genealogyPersons,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$GenealogyPersonsTableOrderingComposer(
            $db: $db,
            $table: $db.genealogyPersons,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ResearchNotesTableAnnotationComposer
    extends Composer<_$AppDatabase, $ResearchNotesTable> {
  $$ResearchNotesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get noteText =>
      $composableBuilder(column: $table.noteText, builder: (column) => column);

  GeneratedColumn<String> get researchQuestion => $composableBuilder(
    column: $table.researchQuestion,
    builder: (column) => column,
  );

  GeneratedColumn<double> get noteDateSort => $composableBuilder(
    column: $table.noteDateSort,
    builder: (column) => column,
  );

  GeneratedColumn<String> get noteDateDisplay => $composableBuilder(
    column: $table.noteDateDisplay,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get resolved =>
      $composableBuilder(column: $table.resolved, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$GenealogyPersonsTableAnnotationComposer get personId {
    final $$GenealogyPersonsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.personId,
      referencedTable: $db.genealogyPersons,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$GenealogyPersonsTableAnnotationComposer(
            $db: $db,
            $table: $db.genealogyPersons,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ResearchNotesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ResearchNotesTable,
          ResearchNote,
          $$ResearchNotesTableFilterComposer,
          $$ResearchNotesTableOrderingComposer,
          $$ResearchNotesTableAnnotationComposer,
          $$ResearchNotesTableCreateCompanionBuilder,
          $$ResearchNotesTableUpdateCompanionBuilder,
          (ResearchNote, $$ResearchNotesTableReferences),
          ResearchNote,
          PrefetchHooks Function({bool personId})
        > {
  $$ResearchNotesTableTableManager(_$AppDatabase db, $ResearchNotesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ResearchNotesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ResearchNotesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ResearchNotesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String?> personId = const Value.absent(),
                Value<String> noteText = const Value.absent(),
                Value<String?> researchQuestion = const Value.absent(),
                Value<double?> noteDateSort = const Value.absent(),
                Value<String?> noteDateDisplay = const Value.absent(),
                Value<bool> resolved = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ResearchNotesCompanion(
                id: id,
                personId: personId,
                noteText: noteText,
                researchQuestion: researchQuestion,
                noteDateSort: noteDateSort,
                noteDateDisplay: noteDateDisplay,
                resolved: resolved,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<String?> personId = const Value.absent(),
                required String noteText,
                Value<String?> researchQuestion = const Value.absent(),
                Value<double?> noteDateSort = const Value.absent(),
                Value<String?> noteDateDisplay = const Value.absent(),
                Value<bool> resolved = const Value.absent(),
                required DateTime createdAt,
                Value<int> rowid = const Value.absent(),
              }) => ResearchNotesCompanion.insert(
                id: id,
                personId: personId,
                noteText: noteText,
                researchQuestion: researchQuestion,
                noteDateSort: noteDateSort,
                noteDateDisplay: noteDateDisplay,
                resolved: resolved,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$ResearchNotesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({personId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (personId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.personId,
                                referencedTable: $$ResearchNotesTableReferences
                                    ._personIdTable(db),
                                referencedColumn: $$ResearchNotesTableReferences
                                    ._personIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$ResearchNotesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ResearchNotesTable,
      ResearchNote,
      $$ResearchNotesTableFilterComposer,
      $$ResearchNotesTableOrderingComposer,
      $$ResearchNotesTableAnnotationComposer,
      $$ResearchNotesTableCreateCompanionBuilder,
      $$ResearchNotesTableUpdateCompanionBuilder,
      (ResearchNote, $$ResearchNotesTableReferences),
      ResearchNote,
      PrefetchHooks Function({bool personId})
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$GenealogyPersonsTableTableManager get genealogyPersons =>
      $$GenealogyPersonsTableTableManager(_db, _db.genealogyPersons);
  $$FamilyTreesTableTableManager get familyTrees =>
      $$FamilyTreesTableTableManager(_db, _db.familyTrees);
  $$EventsTableTableManager get events =>
      $$EventsTableTableManager(_db, _db.events);
  $$SurnameEventsTableTableManager get surnameEvents =>
      $$SurnameEventsTableTableManager(_db, _db.surnameEvents);
  $$FamiliesV2TableTableManager get familiesV2 =>
      $$FamiliesV2TableTableManager(_db, _db.familiesV2);
  $$FamilyChildrenV2TableTableManager get familyChildrenV2 =>
      $$FamilyChildrenV2TableTableManager(_db, _db.familyChildrenV2);
  $$MediaItemsTableTableManager get mediaItems =>
      $$MediaItemsTableTableManager(_db, _db.mediaItems);
  $$DuplicateMarkersTableTableManager get duplicateMarkers =>
      $$DuplicateMarkersTableTableManager(_db, _db.duplicateMarkers);
  $$ResearchNotesTableTableManager get researchNotes =>
      $$ResearchNotesTableTableManager(_db, _db.researchNotes);
}
