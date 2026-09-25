// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'instituicao.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$PerfilDeUniversidade {

 String get id; String get nome; String get sigla;/// Se o leitor tem vínculo ativo com esta instituição. Decide se o menu
/// oferece "inserir CPF" ou "encerrar vínculo".
 bool get temVinculo; bool get seguindo;/// Quantos têm vínculo ativo. Agregado, sem expor quem.
 int get totalDeAlunos; String? get bio; String? get fotoUrl;
/// Create a copy of PerfilDeUniversidade
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PerfilDeUniversidadeCopyWith<PerfilDeUniversidade> get copyWith => _$PerfilDeUniversidadeCopyWithImpl<PerfilDeUniversidade>(this as PerfilDeUniversidade, _$identity);

  /// Serializes this PerfilDeUniversidade to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as PerfilDeUniversidade;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PerfilDeUniversidade&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.nome, _this.nome) || other.nome == _this.nome)&&(identical(other.sigla, _this.sigla) || other.sigla == _this.sigla)&&(identical(other.temVinculo, _this.temVinculo) || other.temVinculo == _this.temVinculo)&&(identical(other.seguindo, _this.seguindo) || other.seguindo == _this.seguindo)&&(identical(other.totalDeAlunos, _this.totalDeAlunos) || other.totalDeAlunos == _this.totalDeAlunos)&&(identical(other.bio, _this.bio) || other.bio == _this.bio)&&(identical(other.fotoUrl, _this.fotoUrl) || other.fotoUrl == _this.fotoUrl));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as PerfilDeUniversidade;
  return Object.hash(runtimeType,_this.id,_this.nome,_this.sigla,_this.temVinculo,_this.seguindo,_this.totalDeAlunos,_this.bio,_this.fotoUrl);
}

@override
String toString() {
  final _this = this as PerfilDeUniversidade;
  return 'PerfilDeUniversidade(id: ${_this.id}, nome: ${_this.nome}, sigla: ${_this.sigla}, temVinculo: ${_this.temVinculo}, seguindo: ${_this.seguindo}, totalDeAlunos: ${_this.totalDeAlunos}, bio: ${_this.bio}, fotoUrl: ${_this.fotoUrl})';
}


}

/// @nodoc
abstract mixin class $PerfilDeUniversidadeCopyWith<$Res>  {
  factory $PerfilDeUniversidadeCopyWith(PerfilDeUniversidade value, $Res Function(PerfilDeUniversidade) _then) = _$PerfilDeUniversidadeCopyWithImpl;
@useResult
$Res call({
 String id, String nome, String sigla, bool temVinculo, bool seguindo, int totalDeAlunos, String? bio, String? fotoUrl
});




}
/// @nodoc
class _$PerfilDeUniversidadeCopyWithImpl<$Res>
    implements $PerfilDeUniversidadeCopyWith<$Res> {
  _$PerfilDeUniversidadeCopyWithImpl(this._self, this._then);

  final PerfilDeUniversidade _self;
  final $Res Function(PerfilDeUniversidade) _then;

/// Create a copy of PerfilDeUniversidade
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? nome = null,Object? sigla = null,Object? temVinculo = null,Object? seguindo = null,Object? totalDeAlunos = null,Object? bio = freezed,Object? fotoUrl = freezed,}) {
  return _then(PerfilDeUniversidade(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,nome: null == nome ? _self.nome : nome // ignore: cast_nullable_to_non_nullable
as String,sigla: null == sigla ? _self.sigla : sigla // ignore: cast_nullable_to_non_nullable
as String,temVinculo: null == temVinculo ? _self.temVinculo : temVinculo // ignore: cast_nullable_to_non_nullable
as bool,seguindo: null == seguindo ? _self.seguindo : seguindo // ignore: cast_nullable_to_non_nullable
as bool,totalDeAlunos: null == totalDeAlunos ? _self.totalDeAlunos : totalDeAlunos // ignore: cast_nullable_to_non_nullable
as int,bio: freezed == bio ? _self.bio : bio // ignore: cast_nullable_to_non_nullable
as String?,fotoUrl: freezed == fotoUrl ? _self.fotoUrl : fotoUrl // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [PerfilDeUniversidade].
extension PerfilDeUniversidadePatterns on PerfilDeUniversidade {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PerfilDeUniversidade value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PerfilDeUniversidade() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PerfilDeUniversidade value)  $default,){
final _that = this;
switch (_that) {
case _PerfilDeUniversidade():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PerfilDeUniversidade value)?  $default,){
final _that = this;
switch (_that) {
case _PerfilDeUniversidade() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String nome,  String sigla,  bool temVinculo,  bool seguindo,  int totalDeAlunos,  String? bio,  String? fotoUrl)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PerfilDeUniversidade() when $default != null:
return $default(_that.id,_that.nome,_that.sigla,_that.temVinculo,_that.seguindo,_that.totalDeAlunos,_that.bio,_that.fotoUrl);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String nome,  String sigla,  bool temVinculo,  bool seguindo,  int totalDeAlunos,  String? bio,  String? fotoUrl)  $default,) {final _that = this;
switch (_that) {
case _PerfilDeUniversidade():
return $default(_that.id,_that.nome,_that.sigla,_that.temVinculo,_that.seguindo,_that.totalDeAlunos,_that.bio,_that.fotoUrl);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String nome,  String sigla,  bool temVinculo,  bool seguindo,  int totalDeAlunos,  String? bio,  String? fotoUrl)?  $default,) {final _that = this;
switch (_that) {
case _PerfilDeUniversidade() when $default != null:
return $default(_that.id,_that.nome,_that.sigla,_that.temVinculo,_that.seguindo,_that.totalDeAlunos,_that.bio,_that.fotoUrl);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PerfilDeUniversidade implements PerfilDeUniversidade {
  const _PerfilDeUniversidade({required this.id, required this.nome, required this.sigla, required this.temVinculo, required this.seguindo, this.totalDeAlunos = 0, this.bio, this.fotoUrl});
  factory _PerfilDeUniversidade.fromJson(Map<String, dynamic> json) => _$PerfilDeUniversidadeFromJson(json);

@override final  String id;
@override final  String nome;
@override final  String sigla;
/// Se o leitor tem vínculo ativo com esta instituição. Decide se o menu
/// oferece "inserir CPF" ou "encerrar vínculo".
@override final  bool temVinculo;
@override final  bool seguindo;
/// Quantos têm vínculo ativo. Agregado, sem expor quem.
@override@JsonKey() final  int totalDeAlunos;
@override final  String? bio;
@override final  String? fotoUrl;

/// Create a copy of PerfilDeUniversidade
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PerfilDeUniversidadeCopyWith<_PerfilDeUniversidade> get copyWith => __$PerfilDeUniversidadeCopyWithImpl<_PerfilDeUniversidade>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PerfilDeUniversidadeToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _PerfilDeUniversidade&&(identical(other.id, id) || other.id == id)&&(identical(other.nome, nome) || other.nome == nome)&&(identical(other.sigla, sigla) || other.sigla == sigla)&&(identical(other.temVinculo, temVinculo) || other.temVinculo == temVinculo)&&(identical(other.seguindo, seguindo) || other.seguindo == seguindo)&&(identical(other.totalDeAlunos, totalDeAlunos) || other.totalDeAlunos == totalDeAlunos)&&(identical(other.bio, bio) || other.bio == bio)&&(identical(other.fotoUrl, fotoUrl) || other.fotoUrl == fotoUrl));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,nome,sigla,temVinculo,seguindo,totalDeAlunos,bio,fotoUrl);
}

@override
String toString() {
    return 'PerfilDeUniversidade(id: $id, nome: $nome, sigla: $sigla, temVinculo: $temVinculo, seguindo: $seguindo, totalDeAlunos: $totalDeAlunos, bio: $bio, fotoUrl: $fotoUrl)';
}


}

/// @nodoc
abstract mixin class _$PerfilDeUniversidadeCopyWith<$Res> implements $PerfilDeUniversidadeCopyWith<$Res> {
  factory _$PerfilDeUniversidadeCopyWith(_PerfilDeUniversidade value, $Res Function(_PerfilDeUniversidade) _then) = __$PerfilDeUniversidadeCopyWithImpl;
@override @useResult
$Res call({
 String id, String nome, String sigla, bool temVinculo, bool seguindo, int totalDeAlunos, String? bio, String? fotoUrl
});




}
/// @nodoc
class __$PerfilDeUniversidadeCopyWithImpl<$Res>
    implements _$PerfilDeUniversidadeCopyWith<$Res> {
  __$PerfilDeUniversidadeCopyWithImpl(this._self, this._then);

  final _PerfilDeUniversidade _self;
  final $Res Function(_PerfilDeUniversidade) _then;

/// Create a copy of PerfilDeUniversidade
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? nome = null,Object? sigla = null,Object? temVinculo = null,Object? seguindo = null,Object? totalDeAlunos = null,Object? bio = freezed,Object? fotoUrl = freezed,}) {
  return _then(_PerfilDeUniversidade(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,nome: null == nome ? _self.nome : nome // ignore: cast_nullable_to_non_nullable
as String,sigla: null == sigla ? _self.sigla : sigla // ignore: cast_nullable_to_non_nullable
as String,temVinculo: null == temVinculo ? _self.temVinculo : temVinculo // ignore: cast_nullable_to_non_nullable
as bool,seguindo: null == seguindo ? _self.seguindo : seguindo // ignore: cast_nullable_to_non_nullable
as bool,totalDeAlunos: null == totalDeAlunos ? _self.totalDeAlunos : totalDeAlunos // ignore: cast_nullable_to_non_nullable
as int,bio: freezed == bio ? _self.bio : bio // ignore: cast_nullable_to_non_nullable
as String?,fotoUrl: freezed == fotoUrl ? _self.fotoUrl : fotoUrl // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$UniversidadeSeguida {

 String get id; String get nome; String get sigla; bool get propria; bool get temConta; DateTime? get seguidaEm;
/// Create a copy of UniversidadeSeguida
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$UniversidadeSeguidaCopyWith<UniversidadeSeguida> get copyWith => _$UniversidadeSeguidaCopyWithImpl<UniversidadeSeguida>(this as UniversidadeSeguida, _$identity);

  /// Serializes this UniversidadeSeguida to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as UniversidadeSeguida;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UniversidadeSeguida&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.nome, _this.nome) || other.nome == _this.nome)&&(identical(other.sigla, _this.sigla) || other.sigla == _this.sigla)&&(identical(other.propria, _this.propria) || other.propria == _this.propria)&&(identical(other.temConta, _this.temConta) || other.temConta == _this.temConta)&&(identical(other.seguidaEm, _this.seguidaEm) || other.seguidaEm == _this.seguidaEm));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as UniversidadeSeguida;
  return Object.hash(runtimeType,_this.id,_this.nome,_this.sigla,_this.propria,_this.temConta,_this.seguidaEm);
}

@override
String toString() {
  final _this = this as UniversidadeSeguida;
  return 'UniversidadeSeguida(id: ${_this.id}, nome: ${_this.nome}, sigla: ${_this.sigla}, propria: ${_this.propria}, temConta: ${_this.temConta}, seguidaEm: ${_this.seguidaEm})';
}


}

/// @nodoc
abstract mixin class $UniversidadeSeguidaCopyWith<$Res>  {
  factory $UniversidadeSeguidaCopyWith(UniversidadeSeguida value, $Res Function(UniversidadeSeguida) _then) = _$UniversidadeSeguidaCopyWithImpl;
@useResult
$Res call({
 String id, String nome, String sigla, bool propria, bool temConta, DateTime? seguidaEm
});




}
/// @nodoc
class _$UniversidadeSeguidaCopyWithImpl<$Res>
    implements $UniversidadeSeguidaCopyWith<$Res> {
  _$UniversidadeSeguidaCopyWithImpl(this._self, this._then);

  final UniversidadeSeguida _self;
  final $Res Function(UniversidadeSeguida) _then;

/// Create a copy of UniversidadeSeguida
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? nome = null,Object? sigla = null,Object? propria = null,Object? temConta = null,Object? seguidaEm = freezed,}) {
  return _then(UniversidadeSeguida(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,nome: null == nome ? _self.nome : nome // ignore: cast_nullable_to_non_nullable
as String,sigla: null == sigla ? _self.sigla : sigla // ignore: cast_nullable_to_non_nullable
as String,propria: null == propria ? _self.propria : propria // ignore: cast_nullable_to_non_nullable
as bool,temConta: null == temConta ? _self.temConta : temConta // ignore: cast_nullable_to_non_nullable
as bool,seguidaEm: freezed == seguidaEm ? _self.seguidaEm : seguidaEm // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [UniversidadeSeguida].
extension UniversidadeSeguidaPatterns on UniversidadeSeguida {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _UniversidadeSeguida value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _UniversidadeSeguida() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _UniversidadeSeguida value)  $default,){
final _that = this;
switch (_that) {
case _UniversidadeSeguida():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _UniversidadeSeguida value)?  $default,){
final _that = this;
switch (_that) {
case _UniversidadeSeguida() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String nome,  String sigla,  bool propria,  bool temConta,  DateTime? seguidaEm)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _UniversidadeSeguida() when $default != null:
return $default(_that.id,_that.nome,_that.sigla,_that.propria,_that.temConta,_that.seguidaEm);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String nome,  String sigla,  bool propria,  bool temConta,  DateTime? seguidaEm)  $default,) {final _that = this;
switch (_that) {
case _UniversidadeSeguida():
return $default(_that.id,_that.nome,_that.sigla,_that.propria,_that.temConta,_that.seguidaEm);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String nome,  String sigla,  bool propria,  bool temConta,  DateTime? seguidaEm)?  $default,) {final _that = this;
switch (_that) {
case _UniversidadeSeguida() when $default != null:
return $default(_that.id,_that.nome,_that.sigla,_that.propria,_that.temConta,_that.seguidaEm);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _UniversidadeSeguida implements UniversidadeSeguida {
  const _UniversidadeSeguida({required this.id, required this.nome, required this.sigla, required this.propria, this.temConta = false, this.seguidaEm});
  factory _UniversidadeSeguida.fromJson(Map<String, dynamic> json) => _$UniversidadeSeguidaFromJson(json);

@override final  String id;
@override final  String nome;
@override final  String sigla;
@override final  bool propria;
@override@JsonKey() final  bool temConta;
@override final  DateTime? seguidaEm;

/// Create a copy of UniversidadeSeguida
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$UniversidadeSeguidaCopyWith<_UniversidadeSeguida> get copyWith => __$UniversidadeSeguidaCopyWithImpl<_UniversidadeSeguida>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$UniversidadeSeguidaToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _UniversidadeSeguida&&(identical(other.id, id) || other.id == id)&&(identical(other.nome, nome) || other.nome == nome)&&(identical(other.sigla, sigla) || other.sigla == sigla)&&(identical(other.propria, propria) || other.propria == propria)&&(identical(other.temConta, temConta) || other.temConta == temConta)&&(identical(other.seguidaEm, seguidaEm) || other.seguidaEm == seguidaEm));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,nome,sigla,propria,temConta,seguidaEm);
}

@override
String toString() {
    return 'UniversidadeSeguida(id: $id, nome: $nome, sigla: $sigla, propria: $propria, temConta: $temConta, seguidaEm: $seguidaEm)';
}


}

/// @nodoc
abstract mixin class _$UniversidadeSeguidaCopyWith<$Res> implements $UniversidadeSeguidaCopyWith<$Res> {
  factory _$UniversidadeSeguidaCopyWith(_UniversidadeSeguida value, $Res Function(_UniversidadeSeguida) _then) = __$UniversidadeSeguidaCopyWithImpl;
@override @useResult
$Res call({
 String id, String nome, String sigla, bool propria, bool temConta, DateTime? seguidaEm
});




}
/// @nodoc
class __$UniversidadeSeguidaCopyWithImpl<$Res>
    implements _$UniversidadeSeguidaCopyWith<$Res> {
  __$UniversidadeSeguidaCopyWithImpl(this._self, this._then);

  final _UniversidadeSeguida _self;
  final $Res Function(_UniversidadeSeguida) _then;

/// Create a copy of UniversidadeSeguida
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? nome = null,Object? sigla = null,Object? propria = null,Object? temConta = null,Object? seguidaEm = freezed,}) {
  return _then(_UniversidadeSeguida(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,nome: null == nome ? _self.nome : nome // ignore: cast_nullable_to_non_nullable
as String,sigla: null == sigla ? _self.sigla : sigla // ignore: cast_nullable_to_non_nullable
as String,propria: null == propria ? _self.propria : propria // ignore: cast_nullable_to_non_nullable
as bool,temConta: null == temConta ? _self.temConta : temConta // ignore: cast_nullable_to_non_nullable
as bool,seguidaEm: freezed == seguidaEm ? _self.seguidaEm : seguidaEm // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}


/// @nodoc
mixin _$ResultadoDeBusca {

 List<Universidade> get universidades; List<Perfil> get empresas; List<Perfil> get pessoas;
/// Create a copy of ResultadoDeBusca
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ResultadoDeBuscaCopyWith<ResultadoDeBusca> get copyWith => _$ResultadoDeBuscaCopyWithImpl<ResultadoDeBusca>(this as ResultadoDeBusca, _$identity);

  /// Serializes this ResultadoDeBusca to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as ResultadoDeBusca;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ResultadoDeBusca&&const DeepCollectionEquality().equals(other.universidades, _this.universidades)&&const DeepCollectionEquality().equals(other.empresas, _this.empresas)&&const DeepCollectionEquality().equals(other.pessoas, _this.pessoas));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as ResultadoDeBusca;
  return Object.hash(runtimeType,const DeepCollectionEquality().hash(_this.universidades),const DeepCollectionEquality().hash(_this.empresas),const DeepCollectionEquality().hash(_this.pessoas));
}

@override
String toString() {
  final _this = this as ResultadoDeBusca;
  return 'ResultadoDeBusca(universidades: ${_this.universidades}, empresas: ${_this.empresas}, pessoas: ${_this.pessoas})';
}


}

/// @nodoc
abstract mixin class $ResultadoDeBuscaCopyWith<$Res>  {
  factory $ResultadoDeBuscaCopyWith(ResultadoDeBusca value, $Res Function(ResultadoDeBusca) _then) = _$ResultadoDeBuscaCopyWithImpl;
@useResult
$Res call({
 List<Universidade> universidades, List<Perfil> empresas, List<Perfil> pessoas
});




}
/// @nodoc
class _$ResultadoDeBuscaCopyWithImpl<$Res>
    implements $ResultadoDeBuscaCopyWith<$Res> {
  _$ResultadoDeBuscaCopyWithImpl(this._self, this._then);

  final ResultadoDeBusca _self;
  final $Res Function(ResultadoDeBusca) _then;

/// Create a copy of ResultadoDeBusca
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? universidades = null,Object? empresas = null,Object? pessoas = null,}) {
  return _then(ResultadoDeBusca(
universidades: null == universidades ? _self.universidades : universidades // ignore: cast_nullable_to_non_nullable
as List<Universidade>,empresas: null == empresas ? _self.empresas : empresas // ignore: cast_nullable_to_non_nullable
as List<Perfil>,pessoas: null == pessoas ? _self.pessoas : pessoas // ignore: cast_nullable_to_non_nullable
as List<Perfil>,
  ));
}

}


/// Adds pattern-matching-related methods to [ResultadoDeBusca].
extension ResultadoDeBuscaPatterns on ResultadoDeBusca {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ResultadoDeBusca value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ResultadoDeBusca() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ResultadoDeBusca value)  $default,){
final _that = this;
switch (_that) {
case _ResultadoDeBusca():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ResultadoDeBusca value)?  $default,){
final _that = this;
switch (_that) {
case _ResultadoDeBusca() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<Universidade> universidades,  List<Perfil> empresas,  List<Perfil> pessoas)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ResultadoDeBusca() when $default != null:
return $default(_that.universidades,_that.empresas,_that.pessoas);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<Universidade> universidades,  List<Perfil> empresas,  List<Perfil> pessoas)  $default,) {final _that = this;
switch (_that) {
case _ResultadoDeBusca():
return $default(_that.universidades,_that.empresas,_that.pessoas);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<Universidade> universidades,  List<Perfil> empresas,  List<Perfil> pessoas)?  $default,) {final _that = this;
switch (_that) {
case _ResultadoDeBusca() when $default != null:
return $default(_that.universidades,_that.empresas,_that.pessoas);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ResultadoDeBusca implements ResultadoDeBusca {
  const _ResultadoDeBusca({ List<Universidade> universidades = const <Universidade>[],  List<Perfil> empresas = const <Perfil>[],  List<Perfil> pessoas = const <Perfil>[]}): _universidades = universidades,_empresas = empresas,_pessoas = pessoas;
  factory _ResultadoDeBusca.fromJson(Map<String, dynamic> json) => _$ResultadoDeBuscaFromJson(json);

 final  List<Universidade> _universidades;
@override@JsonKey() List<Universidade> get universidades {
  if (_universidades is EqualUnmodifiableListView) return _universidades;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_universidades);
}

 final  List<Perfil> _empresas;
@override@JsonKey() List<Perfil> get empresas {
  if (_empresas is EqualUnmodifiableListView) return _empresas;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_empresas);
}

 final  List<Perfil> _pessoas;
@override@JsonKey() List<Perfil> get pessoas {
  if (_pessoas is EqualUnmodifiableListView) return _pessoas;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_pessoas);
}


/// Create a copy of ResultadoDeBusca
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ResultadoDeBuscaCopyWith<_ResultadoDeBusca> get copyWith => __$ResultadoDeBuscaCopyWithImpl<_ResultadoDeBusca>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ResultadoDeBuscaToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _ResultadoDeBusca&&const DeepCollectionEquality().equals(other.universidades, _universidades)&&const DeepCollectionEquality().equals(other.empresas, _empresas)&&const DeepCollectionEquality().equals(other.pessoas, _pessoas));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,const DeepCollectionEquality().hash(_universidades),const DeepCollectionEquality().hash(_empresas),const DeepCollectionEquality().hash(_pessoas));
}

@override
String toString() {
    return 'ResultadoDeBusca(universidades: $universidades, empresas: $empresas, pessoas: $pessoas)';
}


}

/// @nodoc
abstract mixin class _$ResultadoDeBuscaCopyWith<$Res> implements $ResultadoDeBuscaCopyWith<$Res> {
  factory _$ResultadoDeBuscaCopyWith(_ResultadoDeBusca value, $Res Function(_ResultadoDeBusca) _then) = __$ResultadoDeBuscaCopyWithImpl;
@override @useResult
$Res call({
 List<Universidade> universidades, List<Perfil> empresas, List<Perfil> pessoas
});




}
/// @nodoc
class __$ResultadoDeBuscaCopyWithImpl<$Res>
    implements _$ResultadoDeBuscaCopyWith<$Res> {
  __$ResultadoDeBuscaCopyWithImpl(this._self, this._then);

  final _ResultadoDeBusca _self;
  final $Res Function(_ResultadoDeBusca) _then;

/// Create a copy of ResultadoDeBusca
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? universidades = null,Object? empresas = null,Object? pessoas = null,}) {
  return _then(_ResultadoDeBusca(
universidades: null == universidades ? _self._universidades : universidades // ignore: cast_nullable_to_non_nullable
as List<Universidade>,empresas: null == empresas ? _self._empresas : empresas // ignore: cast_nullable_to_non_nullable
as List<Perfil>,pessoas: null == pessoas ? _self._pessoas : pessoas // ignore: cast_nullable_to_non_nullable
as List<Perfil>,
  ));
}


}

// dart format on
