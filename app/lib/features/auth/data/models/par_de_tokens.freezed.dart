// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'par_de_tokens.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ParDeTokens {

 String get accessToken; String get refreshToken; int get expiresIn; String get tokenType;
/// Create a copy of ParDeTokens
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ParDeTokensCopyWith<ParDeTokens> get copyWith => _$ParDeTokensCopyWithImpl<ParDeTokens>(this as ParDeTokens, _$identity);

  /// Serializes this ParDeTokens to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as ParDeTokens;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ParDeTokens&&(identical(other.accessToken, _this.accessToken) || other.accessToken == _this.accessToken)&&(identical(other.refreshToken, _this.refreshToken) || other.refreshToken == _this.refreshToken)&&(identical(other.expiresIn, _this.expiresIn) || other.expiresIn == _this.expiresIn)&&(identical(other.tokenType, _this.tokenType) || other.tokenType == _this.tokenType));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as ParDeTokens;
  return Object.hash(runtimeType,_this.accessToken,_this.refreshToken,_this.expiresIn,_this.tokenType);
}

@override
String toString() {
  final _this = this as ParDeTokens;
  return 'ParDeTokens(accessToken: ${_this.accessToken}, refreshToken: ${_this.refreshToken}, expiresIn: ${_this.expiresIn}, tokenType: ${_this.tokenType})';
}


}

/// @nodoc
abstract mixin class $ParDeTokensCopyWith<$Res>  {
  factory $ParDeTokensCopyWith(ParDeTokens value, $Res Function(ParDeTokens) _then) = _$ParDeTokensCopyWithImpl;
@useResult
$Res call({
 String accessToken, String refreshToken, int expiresIn, String tokenType
});




}
/// @nodoc
class _$ParDeTokensCopyWithImpl<$Res>
    implements $ParDeTokensCopyWith<$Res> {
  _$ParDeTokensCopyWithImpl(this._self, this._then);

  final ParDeTokens _self;
  final $Res Function(ParDeTokens) _then;

/// Create a copy of ParDeTokens
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? accessToken = null,Object? refreshToken = null,Object? expiresIn = null,Object? tokenType = null,}) {
  return _then(ParDeTokens(
accessToken: null == accessToken ? _self.accessToken : accessToken // ignore: cast_nullable_to_non_nullable
as String,refreshToken: null == refreshToken ? _self.refreshToken : refreshToken // ignore: cast_nullable_to_non_nullable
as String,expiresIn: null == expiresIn ? _self.expiresIn : expiresIn // ignore: cast_nullable_to_non_nullable
as int,tokenType: null == tokenType ? _self.tokenType : tokenType // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [ParDeTokens].
extension ParDeTokensPatterns on ParDeTokens {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ParDeTokens value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ParDeTokens() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ParDeTokens value)  $default,){
final _that = this;
switch (_that) {
case _ParDeTokens():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ParDeTokens value)?  $default,){
final _that = this;
switch (_that) {
case _ParDeTokens() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String accessToken,  String refreshToken,  int expiresIn,  String tokenType)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ParDeTokens() when $default != null:
return $default(_that.accessToken,_that.refreshToken,_that.expiresIn,_that.tokenType);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String accessToken,  String refreshToken,  int expiresIn,  String tokenType)  $default,) {final _that = this;
switch (_that) {
case _ParDeTokens():
return $default(_that.accessToken,_that.refreshToken,_that.expiresIn,_that.tokenType);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String accessToken,  String refreshToken,  int expiresIn,  String tokenType)?  $default,) {final _that = this;
switch (_that) {
case _ParDeTokens() when $default != null:
return $default(_that.accessToken,_that.refreshToken,_that.expiresIn,_that.tokenType);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ParDeTokens implements ParDeTokens {
  const _ParDeTokens({required this.accessToken, required this.refreshToken, required this.expiresIn, this.tokenType = 'Bearer'});
  factory _ParDeTokens.fromJson(Map<String, dynamic> json) => _$ParDeTokensFromJson(json);

@override final  String accessToken;
@override final  String refreshToken;
@override final  int expiresIn;
@override@JsonKey() final  String tokenType;

/// Create a copy of ParDeTokens
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ParDeTokensCopyWith<_ParDeTokens> get copyWith => __$ParDeTokensCopyWithImpl<_ParDeTokens>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ParDeTokensToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _ParDeTokens&&(identical(other.accessToken, accessToken) || other.accessToken == accessToken)&&(identical(other.refreshToken, refreshToken) || other.refreshToken == refreshToken)&&(identical(other.expiresIn, expiresIn) || other.expiresIn == expiresIn)&&(identical(other.tokenType, tokenType) || other.tokenType == tokenType));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,accessToken,refreshToken,expiresIn,tokenType);
}

@override
String toString() {
    return 'ParDeTokens(accessToken: $accessToken, refreshToken: $refreshToken, expiresIn: $expiresIn, tokenType: $tokenType)';
}


}

/// @nodoc
abstract mixin class _$ParDeTokensCopyWith<$Res> implements $ParDeTokensCopyWith<$Res> {
  factory _$ParDeTokensCopyWith(_ParDeTokens value, $Res Function(_ParDeTokens) _then) = __$ParDeTokensCopyWithImpl;
@override @useResult
$Res call({
 String accessToken, String refreshToken, int expiresIn, String tokenType
});




}
/// @nodoc
class __$ParDeTokensCopyWithImpl<$Res>
    implements _$ParDeTokensCopyWith<$Res> {
  __$ParDeTokensCopyWithImpl(this._self, this._then);

  final _ParDeTokens _self;
  final $Res Function(_ParDeTokens) _then;

/// Create a copy of ParDeTokens
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? accessToken = null,Object? refreshToken = null,Object? expiresIn = null,Object? tokenType = null,}) {
  return _then(_ParDeTokens(
accessToken: null == accessToken ? _self.accessToken : accessToken // ignore: cast_nullable_to_non_nullable
as String,refreshToken: null == refreshToken ? _self.refreshToken : refreshToken // ignore: cast_nullable_to_non_nullable
as String,expiresIn: null == expiresIn ? _self.expiresIn : expiresIn // ignore: cast_nullable_to_non_nullable
as int,tokenType: null == tokenType ? _self.tokenType : tokenType // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
