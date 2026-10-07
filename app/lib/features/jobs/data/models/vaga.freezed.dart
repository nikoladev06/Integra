// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'vaga.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$EmpresaDaVaga {

 String get id; String get nome; String get username; String? get fotoUrl;
/// Create a copy of EmpresaDaVaga
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$EmpresaDaVagaCopyWith<EmpresaDaVaga> get copyWith => _$EmpresaDaVagaCopyWithImpl<EmpresaDaVaga>(this as EmpresaDaVaga, _$identity);

  /// Serializes this EmpresaDaVaga to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as EmpresaDaVaga;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is EmpresaDaVaga&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.nome, _this.nome) || other.nome == _this.nome)&&(identical(other.username, _this.username) || other.username == _this.username)&&(identical(other.fotoUrl, _this.fotoUrl) || other.fotoUrl == _this.fotoUrl));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as EmpresaDaVaga;
  return Object.hash(runtimeType,_this.id,_this.nome,_this.username,_this.fotoUrl);
}

@override
String toString() {
  final _this = this as EmpresaDaVaga;
  return 'EmpresaDaVaga(id: ${_this.id}, nome: ${_this.nome}, username: ${_this.username}, fotoUrl: ${_this.fotoUrl})';
}


}

/// @nodoc
abstract mixin class $EmpresaDaVagaCopyWith<$Res>  {
  factory $EmpresaDaVagaCopyWith(EmpresaDaVaga value, $Res Function(EmpresaDaVaga) _then) = _$EmpresaDaVagaCopyWithImpl;
@useResult
$Res call({
 String id, String nome, String username, String? fotoUrl
});




}
/// @nodoc
class _$EmpresaDaVagaCopyWithImpl<$Res>
    implements $EmpresaDaVagaCopyWith<$Res> {
  _$EmpresaDaVagaCopyWithImpl(this._self, this._then);

  final EmpresaDaVaga _self;
  final $Res Function(EmpresaDaVaga) _then;

/// Create a copy of EmpresaDaVaga
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? nome = null,Object? username = null,Object? fotoUrl = freezed,}) {
  return _then(EmpresaDaVaga(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,nome: null == nome ? _self.nome : nome // ignore: cast_nullable_to_non_nullable
as String,username: null == username ? _self.username : username // ignore: cast_nullable_to_non_nullable
as String,fotoUrl: freezed == fotoUrl ? _self.fotoUrl : fotoUrl // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [EmpresaDaVaga].
extension EmpresaDaVagaPatterns on EmpresaDaVaga {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _EmpresaDaVaga value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _EmpresaDaVaga() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _EmpresaDaVaga value)  $default,){
final _that = this;
switch (_that) {
case _EmpresaDaVaga():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _EmpresaDaVaga value)?  $default,){
final _that = this;
switch (_that) {
case _EmpresaDaVaga() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String nome,  String username,  String? fotoUrl)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _EmpresaDaVaga() when $default != null:
return $default(_that.id,_that.nome,_that.username,_that.fotoUrl);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String nome,  String username,  String? fotoUrl)  $default,) {final _that = this;
switch (_that) {
case _EmpresaDaVaga():
return $default(_that.id,_that.nome,_that.username,_that.fotoUrl);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String nome,  String username,  String? fotoUrl)?  $default,) {final _that = this;
switch (_that) {
case _EmpresaDaVaga() when $default != null:
return $default(_that.id,_that.nome,_that.username,_that.fotoUrl);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _EmpresaDaVaga implements EmpresaDaVaga {
  const _EmpresaDaVaga({required this.id, required this.nome, required this.username, this.fotoUrl});
  factory _EmpresaDaVaga.fromJson(Map<String, dynamic> json) => _$EmpresaDaVagaFromJson(json);

@override final  String id;
@override final  String nome;
@override final  String username;
@override final  String? fotoUrl;

/// Create a copy of EmpresaDaVaga
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$EmpresaDaVagaCopyWith<_EmpresaDaVaga> get copyWith => __$EmpresaDaVagaCopyWithImpl<_EmpresaDaVaga>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$EmpresaDaVagaToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _EmpresaDaVaga&&(identical(other.id, id) || other.id == id)&&(identical(other.nome, nome) || other.nome == nome)&&(identical(other.username, username) || other.username == username)&&(identical(other.fotoUrl, fotoUrl) || other.fotoUrl == fotoUrl));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,nome,username,fotoUrl);
}

@override
String toString() {
    return 'EmpresaDaVaga(id: $id, nome: $nome, username: $username, fotoUrl: $fotoUrl)';
}


}

/// @nodoc
abstract mixin class _$EmpresaDaVagaCopyWith<$Res> implements $EmpresaDaVagaCopyWith<$Res> {
  factory _$EmpresaDaVagaCopyWith(_EmpresaDaVaga value, $Res Function(_EmpresaDaVaga) _then) = __$EmpresaDaVagaCopyWithImpl;
@override @useResult
$Res call({
 String id, String nome, String username, String? fotoUrl
});




}
/// @nodoc
class __$EmpresaDaVagaCopyWithImpl<$Res>
    implements _$EmpresaDaVagaCopyWith<$Res> {
  __$EmpresaDaVagaCopyWithImpl(this._self, this._then);

  final _EmpresaDaVaga _self;
  final $Res Function(_EmpresaDaVaga) _then;

/// Create a copy of EmpresaDaVaga
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? nome = null,Object? username = null,Object? fotoUrl = freezed,}) {
  return _then(_EmpresaDaVaga(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,nome: null == nome ? _self.nome : nome // ignore: cast_nullable_to_non_nullable
as String,username: null == username ? _self.username : username // ignore: cast_nullable_to_non_nullable
as String,fotoUrl: freezed == fotoUrl ? _self.fotoUrl : fotoUrl // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$CandidatoResumo {

 String get id; String get nomeCompleto; String get username; String? get fotoUrl;
/// Create a copy of CandidatoResumo
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CandidatoResumoCopyWith<CandidatoResumo> get copyWith => _$CandidatoResumoCopyWithImpl<CandidatoResumo>(this as CandidatoResumo, _$identity);

  /// Serializes this CandidatoResumo to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as CandidatoResumo;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CandidatoResumo&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.nomeCompleto, _this.nomeCompleto) || other.nomeCompleto == _this.nomeCompleto)&&(identical(other.username, _this.username) || other.username == _this.username)&&(identical(other.fotoUrl, _this.fotoUrl) || other.fotoUrl == _this.fotoUrl));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as CandidatoResumo;
  return Object.hash(runtimeType,_this.id,_this.nomeCompleto,_this.username,_this.fotoUrl);
}

@override
String toString() {
  final _this = this as CandidatoResumo;
  return 'CandidatoResumo(id: ${_this.id}, nomeCompleto: ${_this.nomeCompleto}, username: ${_this.username}, fotoUrl: ${_this.fotoUrl})';
}


}

/// @nodoc
abstract mixin class $CandidatoResumoCopyWith<$Res>  {
  factory $CandidatoResumoCopyWith(CandidatoResumo value, $Res Function(CandidatoResumo) _then) = _$CandidatoResumoCopyWithImpl;
@useResult
$Res call({
 String id, String nomeCompleto, String username, String? fotoUrl
});




}
/// @nodoc
class _$CandidatoResumoCopyWithImpl<$Res>
    implements $CandidatoResumoCopyWith<$Res> {
  _$CandidatoResumoCopyWithImpl(this._self, this._then);

  final CandidatoResumo _self;
  final $Res Function(CandidatoResumo) _then;

/// Create a copy of CandidatoResumo
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? nomeCompleto = null,Object? username = null,Object? fotoUrl = freezed,}) {
  return _then(CandidatoResumo(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,nomeCompleto: null == nomeCompleto ? _self.nomeCompleto : nomeCompleto // ignore: cast_nullable_to_non_nullable
as String,username: null == username ? _self.username : username // ignore: cast_nullable_to_non_nullable
as String,fotoUrl: freezed == fotoUrl ? _self.fotoUrl : fotoUrl // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [CandidatoResumo].
extension CandidatoResumoPatterns on CandidatoResumo {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CandidatoResumo value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CandidatoResumo() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CandidatoResumo value)  $default,){
final _that = this;
switch (_that) {
case _CandidatoResumo():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CandidatoResumo value)?  $default,){
final _that = this;
switch (_that) {
case _CandidatoResumo() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String nomeCompleto,  String username,  String? fotoUrl)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CandidatoResumo() when $default != null:
return $default(_that.id,_that.nomeCompleto,_that.username,_that.fotoUrl);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String nomeCompleto,  String username,  String? fotoUrl)  $default,) {final _that = this;
switch (_that) {
case _CandidatoResumo():
return $default(_that.id,_that.nomeCompleto,_that.username,_that.fotoUrl);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String nomeCompleto,  String username,  String? fotoUrl)?  $default,) {final _that = this;
switch (_that) {
case _CandidatoResumo() when $default != null:
return $default(_that.id,_that.nomeCompleto,_that.username,_that.fotoUrl);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CandidatoResumo implements CandidatoResumo {
  const _CandidatoResumo({required this.id, required this.nomeCompleto, required this.username, this.fotoUrl});
  factory _CandidatoResumo.fromJson(Map<String, dynamic> json) => _$CandidatoResumoFromJson(json);

@override final  String id;
@override final  String nomeCompleto;
@override final  String username;
@override final  String? fotoUrl;

/// Create a copy of CandidatoResumo
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CandidatoResumoCopyWith<_CandidatoResumo> get copyWith => __$CandidatoResumoCopyWithImpl<_CandidatoResumo>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CandidatoResumoToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _CandidatoResumo&&(identical(other.id, id) || other.id == id)&&(identical(other.nomeCompleto, nomeCompleto) || other.nomeCompleto == nomeCompleto)&&(identical(other.username, username) || other.username == username)&&(identical(other.fotoUrl, fotoUrl) || other.fotoUrl == fotoUrl));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,nomeCompleto,username,fotoUrl);
}

@override
String toString() {
    return 'CandidatoResumo(id: $id, nomeCompleto: $nomeCompleto, username: $username, fotoUrl: $fotoUrl)';
}


}

/// @nodoc
abstract mixin class _$CandidatoResumoCopyWith<$Res> implements $CandidatoResumoCopyWith<$Res> {
  factory _$CandidatoResumoCopyWith(_CandidatoResumo value, $Res Function(_CandidatoResumo) _then) = __$CandidatoResumoCopyWithImpl;
@override @useResult
$Res call({
 String id, String nomeCompleto, String username, String? fotoUrl
});




}
/// @nodoc
class __$CandidatoResumoCopyWithImpl<$Res>
    implements _$CandidatoResumoCopyWith<$Res> {
  __$CandidatoResumoCopyWithImpl(this._self, this._then);

  final _CandidatoResumo _self;
  final $Res Function(_CandidatoResumo) _then;

/// Create a copy of CandidatoResumo
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? nomeCompleto = null,Object? username = null,Object? fotoUrl = freezed,}) {
  return _then(_CandidatoResumo(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,nomeCompleto: null == nomeCompleto ? _self.nomeCompleto : nomeCompleto // ignore: cast_nullable_to_non_nullable
as String,username: null == username ? _self.username : username // ignore: cast_nullable_to_non_nullable
as String,fotoUrl: freezed == fotoUrl ? _self.fotoUrl : fotoUrl // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$Vaga {

 String get id; EmpresaDaVaga get empresa; String get titulo; String get descricao; TipoDeVaga get tipo; Modalidade get modalidade; EstadoDaVaga get estado; DateTime get criadoEm;/// Nulo exatamente quando [modalidade] é [Modalidade.remoto].
 String? get local; int get totalDeCandidaturas;/// Estado **por leitor**. **Nulo para quem não é aluno** — uma empresa não tem
/// o que responder aqui, e `false` a faria parecer elegível a se candidatar.
 bool? get candidaturaEnviada;/// Se o leitor é a empresa autora. Vem do servidor: é o que decide os botões de
/// editar e encerrar, e inferir no cliente é como um botão aparece e é recusado.
 bool get podeEditar; DateTime? get editadoEm;
/// Create a copy of Vaga
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$VagaCopyWith<Vaga> get copyWith => _$VagaCopyWithImpl<Vaga>(this as Vaga, _$identity);

  /// Serializes this Vaga to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as Vaga;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Vaga&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.empresa, _this.empresa) || other.empresa == _this.empresa)&&(identical(other.titulo, _this.titulo) || other.titulo == _this.titulo)&&(identical(other.descricao, _this.descricao) || other.descricao == _this.descricao)&&(identical(other.tipo, _this.tipo) || other.tipo == _this.tipo)&&(identical(other.modalidade, _this.modalidade) || other.modalidade == _this.modalidade)&&(identical(other.estado, _this.estado) || other.estado == _this.estado)&&(identical(other.criadoEm, _this.criadoEm) || other.criadoEm == _this.criadoEm)&&(identical(other.local, _this.local) || other.local == _this.local)&&(identical(other.totalDeCandidaturas, _this.totalDeCandidaturas) || other.totalDeCandidaturas == _this.totalDeCandidaturas)&&(identical(other.candidaturaEnviada, _this.candidaturaEnviada) || other.candidaturaEnviada == _this.candidaturaEnviada)&&(identical(other.podeEditar, _this.podeEditar) || other.podeEditar == _this.podeEditar)&&(identical(other.editadoEm, _this.editadoEm) || other.editadoEm == _this.editadoEm));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as Vaga;
  return Object.hash(runtimeType,_this.id,_this.empresa,_this.titulo,_this.descricao,_this.tipo,_this.modalidade,_this.estado,_this.criadoEm,_this.local,_this.totalDeCandidaturas,_this.candidaturaEnviada,_this.podeEditar,_this.editadoEm);
}

@override
String toString() {
  final _this = this as Vaga;
  return 'Vaga(id: ${_this.id}, empresa: ${_this.empresa}, titulo: ${_this.titulo}, descricao: ${_this.descricao}, tipo: ${_this.tipo}, modalidade: ${_this.modalidade}, estado: ${_this.estado}, criadoEm: ${_this.criadoEm}, local: ${_this.local}, totalDeCandidaturas: ${_this.totalDeCandidaturas}, candidaturaEnviada: ${_this.candidaturaEnviada}, podeEditar: ${_this.podeEditar}, editadoEm: ${_this.editadoEm})';
}


}

/// @nodoc
abstract mixin class $VagaCopyWith<$Res>  {
  factory $VagaCopyWith(Vaga value, $Res Function(Vaga) _then) = _$VagaCopyWithImpl;
@useResult
$Res call({
 String id, EmpresaDaVaga empresa, String titulo, String descricao, TipoDeVaga tipo, Modalidade modalidade, EstadoDaVaga estado, DateTime criadoEm, String? local, int totalDeCandidaturas, bool? candidaturaEnviada, bool podeEditar, DateTime? editadoEm
});


$EmpresaDaVagaCopyWith<$Res> get empresa;

}
/// @nodoc
class _$VagaCopyWithImpl<$Res>
    implements $VagaCopyWith<$Res> {
  _$VagaCopyWithImpl(this._self, this._then);

  final Vaga _self;
  final $Res Function(Vaga) _then;

/// Create a copy of Vaga
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? empresa = null,Object? titulo = null,Object? descricao = null,Object? tipo = null,Object? modalidade = null,Object? estado = null,Object? criadoEm = null,Object? local = freezed,Object? totalDeCandidaturas = null,Object? candidaturaEnviada = freezed,Object? podeEditar = null,Object? editadoEm = freezed,}) {
  return _then(Vaga(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,empresa: null == empresa ? _self.empresa : empresa // ignore: cast_nullable_to_non_nullable
as EmpresaDaVaga,titulo: null == titulo ? _self.titulo : titulo // ignore: cast_nullable_to_non_nullable
as String,descricao: null == descricao ? _self.descricao : descricao // ignore: cast_nullable_to_non_nullable
as String,tipo: null == tipo ? _self.tipo : tipo // ignore: cast_nullable_to_non_nullable
as TipoDeVaga,modalidade: null == modalidade ? _self.modalidade : modalidade // ignore: cast_nullable_to_non_nullable
as Modalidade,estado: null == estado ? _self.estado : estado // ignore: cast_nullable_to_non_nullable
as EstadoDaVaga,criadoEm: null == criadoEm ? _self.criadoEm : criadoEm // ignore: cast_nullable_to_non_nullable
as DateTime,local: freezed == local ? _self.local : local // ignore: cast_nullable_to_non_nullable
as String?,totalDeCandidaturas: null == totalDeCandidaturas ? _self.totalDeCandidaturas : totalDeCandidaturas // ignore: cast_nullable_to_non_nullable
as int,candidaturaEnviada: freezed == candidaturaEnviada ? _self.candidaturaEnviada : candidaturaEnviada // ignore: cast_nullable_to_non_nullable
as bool?,podeEditar: null == podeEditar ? _self.podeEditar : podeEditar // ignore: cast_nullable_to_non_nullable
as bool,editadoEm: freezed == editadoEm ? _self.editadoEm : editadoEm // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}
/// Create a copy of Vaga
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$EmpresaDaVagaCopyWith<$Res> get empresa {
  
  return $EmpresaDaVagaCopyWith<$Res>(_self.empresa, (value) {
    return _then(_self.copyWith(empresa: value));
  });
}
}


/// Adds pattern-matching-related methods to [Vaga].
extension VagaPatterns on Vaga {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Vaga value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Vaga() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Vaga value)  $default,){
final _that = this;
switch (_that) {
case _Vaga():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Vaga value)?  $default,){
final _that = this;
switch (_that) {
case _Vaga() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  EmpresaDaVaga empresa,  String titulo,  String descricao,  TipoDeVaga tipo,  Modalidade modalidade,  EstadoDaVaga estado,  DateTime criadoEm,  String? local,  int totalDeCandidaturas,  bool? candidaturaEnviada,  bool podeEditar,  DateTime? editadoEm)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Vaga() when $default != null:
return $default(_that.id,_that.empresa,_that.titulo,_that.descricao,_that.tipo,_that.modalidade,_that.estado,_that.criadoEm,_that.local,_that.totalDeCandidaturas,_that.candidaturaEnviada,_that.podeEditar,_that.editadoEm);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  EmpresaDaVaga empresa,  String titulo,  String descricao,  TipoDeVaga tipo,  Modalidade modalidade,  EstadoDaVaga estado,  DateTime criadoEm,  String? local,  int totalDeCandidaturas,  bool? candidaturaEnviada,  bool podeEditar,  DateTime? editadoEm)  $default,) {final _that = this;
switch (_that) {
case _Vaga():
return $default(_that.id,_that.empresa,_that.titulo,_that.descricao,_that.tipo,_that.modalidade,_that.estado,_that.criadoEm,_that.local,_that.totalDeCandidaturas,_that.candidaturaEnviada,_that.podeEditar,_that.editadoEm);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  EmpresaDaVaga empresa,  String titulo,  String descricao,  TipoDeVaga tipo,  Modalidade modalidade,  EstadoDaVaga estado,  DateTime criadoEm,  String? local,  int totalDeCandidaturas,  bool? candidaturaEnviada,  bool podeEditar,  DateTime? editadoEm)?  $default,) {final _that = this;
switch (_that) {
case _Vaga() when $default != null:
return $default(_that.id,_that.empresa,_that.titulo,_that.descricao,_that.tipo,_that.modalidade,_that.estado,_that.criadoEm,_that.local,_that.totalDeCandidaturas,_that.candidaturaEnviada,_that.podeEditar,_that.editadoEm);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Vaga implements Vaga {
  const _Vaga({required this.id, required this.empresa, required this.titulo, required this.descricao, required this.tipo, required this.modalidade, required this.estado, required this.criadoEm, this.local, this.totalDeCandidaturas = 0, this.candidaturaEnviada, this.podeEditar = false, this.editadoEm});
  factory _Vaga.fromJson(Map<String, dynamic> json) => _$VagaFromJson(json);

@override final  String id;
@override final  EmpresaDaVaga empresa;
@override final  String titulo;
@override final  String descricao;
@override final  TipoDeVaga tipo;
@override final  Modalidade modalidade;
@override final  EstadoDaVaga estado;
@override final  DateTime criadoEm;
/// Nulo exatamente quando [modalidade] é [Modalidade.remoto].
@override final  String? local;
@override@JsonKey() final  int totalDeCandidaturas;
/// Estado **por leitor**. **Nulo para quem não é aluno** — uma empresa não tem
/// o que responder aqui, e `false` a faria parecer elegível a se candidatar.
@override final  bool? candidaturaEnviada;
/// Se o leitor é a empresa autora. Vem do servidor: é o que decide os botões de
/// editar e encerrar, e inferir no cliente é como um botão aparece e é recusado.
@override@JsonKey() final  bool podeEditar;
@override final  DateTime? editadoEm;

/// Create a copy of Vaga
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$VagaCopyWith<_Vaga> get copyWith => __$VagaCopyWithImpl<_Vaga>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$VagaToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _Vaga&&(identical(other.id, id) || other.id == id)&&(identical(other.empresa, empresa) || other.empresa == empresa)&&(identical(other.titulo, titulo) || other.titulo == titulo)&&(identical(other.descricao, descricao) || other.descricao == descricao)&&(identical(other.tipo, tipo) || other.tipo == tipo)&&(identical(other.modalidade, modalidade) || other.modalidade == modalidade)&&(identical(other.estado, estado) || other.estado == estado)&&(identical(other.criadoEm, criadoEm) || other.criadoEm == criadoEm)&&(identical(other.local, local) || other.local == local)&&(identical(other.totalDeCandidaturas, totalDeCandidaturas) || other.totalDeCandidaturas == totalDeCandidaturas)&&(identical(other.candidaturaEnviada, candidaturaEnviada) || other.candidaturaEnviada == candidaturaEnviada)&&(identical(other.podeEditar, podeEditar) || other.podeEditar == podeEditar)&&(identical(other.editadoEm, editadoEm) || other.editadoEm == editadoEm));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,empresa,titulo,descricao,tipo,modalidade,estado,criadoEm,local,totalDeCandidaturas,candidaturaEnviada,podeEditar,editadoEm);
}

@override
String toString() {
    return 'Vaga(id: $id, empresa: $empresa, titulo: $titulo, descricao: $descricao, tipo: $tipo, modalidade: $modalidade, estado: $estado, criadoEm: $criadoEm, local: $local, totalDeCandidaturas: $totalDeCandidaturas, candidaturaEnviada: $candidaturaEnviada, podeEditar: $podeEditar, editadoEm: $editadoEm)';
}


}

/// @nodoc
abstract mixin class _$VagaCopyWith<$Res> implements $VagaCopyWith<$Res> {
  factory _$VagaCopyWith(_Vaga value, $Res Function(_Vaga) _then) = __$VagaCopyWithImpl;
@override @useResult
$Res call({
 String id, EmpresaDaVaga empresa, String titulo, String descricao, TipoDeVaga tipo, Modalidade modalidade, EstadoDaVaga estado, DateTime criadoEm, String? local, int totalDeCandidaturas, bool? candidaturaEnviada, bool podeEditar, DateTime? editadoEm
});


@override $EmpresaDaVagaCopyWith<$Res> get empresa;

}
/// @nodoc
class __$VagaCopyWithImpl<$Res>
    implements _$VagaCopyWith<$Res> {
  __$VagaCopyWithImpl(this._self, this._then);

  final _Vaga _self;
  final $Res Function(_Vaga) _then;

/// Create a copy of Vaga
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? empresa = null,Object? titulo = null,Object? descricao = null,Object? tipo = null,Object? modalidade = null,Object? estado = null,Object? criadoEm = null,Object? local = freezed,Object? totalDeCandidaturas = null,Object? candidaturaEnviada = freezed,Object? podeEditar = null,Object? editadoEm = freezed,}) {
  return _then(_Vaga(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,empresa: null == empresa ? _self.empresa : empresa // ignore: cast_nullable_to_non_nullable
as EmpresaDaVaga,titulo: null == titulo ? _self.titulo : titulo // ignore: cast_nullable_to_non_nullable
as String,descricao: null == descricao ? _self.descricao : descricao // ignore: cast_nullable_to_non_nullable
as String,tipo: null == tipo ? _self.tipo : tipo // ignore: cast_nullable_to_non_nullable
as TipoDeVaga,modalidade: null == modalidade ? _self.modalidade : modalidade // ignore: cast_nullable_to_non_nullable
as Modalidade,estado: null == estado ? _self.estado : estado // ignore: cast_nullable_to_non_nullable
as EstadoDaVaga,criadoEm: null == criadoEm ? _self.criadoEm : criadoEm // ignore: cast_nullable_to_non_nullable
as DateTime,local: freezed == local ? _self.local : local // ignore: cast_nullable_to_non_nullable
as String?,totalDeCandidaturas: null == totalDeCandidaturas ? _self.totalDeCandidaturas : totalDeCandidaturas // ignore: cast_nullable_to_non_nullable
as int,candidaturaEnviada: freezed == candidaturaEnviada ? _self.candidaturaEnviada : candidaturaEnviada // ignore: cast_nullable_to_non_nullable
as bool?,podeEditar: null == podeEditar ? _self.podeEditar : podeEditar // ignore: cast_nullable_to_non_nullable
as bool,editadoEm: freezed == editadoEm ? _self.editadoEm : editadoEm // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

/// Create a copy of Vaga
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$EmpresaDaVagaCopyWith<$Res> get empresa {
  
  return $EmpresaDaVagaCopyWith<$Res>(_self.empresa, (value) {
    return _then(_self.copyWith(empresa: value));
  });
}
}


/// @nodoc
mixin _$Candidatura {

 String get id; Vaga get vaga; CandidatoResumo get candidato; EstadoDaCandidatura get estado; DateTime get criadoEm;/// A data da **primeira** vez que a empresa abriu. Marcar de novo não a move: é
/// o que o aluno lê como "foi vista", e uma data que andasse contaria quantas
/// vezes olharam.
 DateTime? get visualizadaEm;
/// Create a copy of Candidatura
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CandidaturaCopyWith<Candidatura> get copyWith => _$CandidaturaCopyWithImpl<Candidatura>(this as Candidatura, _$identity);

  /// Serializes this Candidatura to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as Candidatura;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Candidatura&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.vaga, _this.vaga) || other.vaga == _this.vaga)&&(identical(other.candidato, _this.candidato) || other.candidato == _this.candidato)&&(identical(other.estado, _this.estado) || other.estado == _this.estado)&&(identical(other.criadoEm, _this.criadoEm) || other.criadoEm == _this.criadoEm)&&(identical(other.visualizadaEm, _this.visualizadaEm) || other.visualizadaEm == _this.visualizadaEm));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as Candidatura;
  return Object.hash(runtimeType,_this.id,_this.vaga,_this.candidato,_this.estado,_this.criadoEm,_this.visualizadaEm);
}

@override
String toString() {
  final _this = this as Candidatura;
  return 'Candidatura(id: ${_this.id}, vaga: ${_this.vaga}, candidato: ${_this.candidato}, estado: ${_this.estado}, criadoEm: ${_this.criadoEm}, visualizadaEm: ${_this.visualizadaEm})';
}


}

/// @nodoc
abstract mixin class $CandidaturaCopyWith<$Res>  {
  factory $CandidaturaCopyWith(Candidatura value, $Res Function(Candidatura) _then) = _$CandidaturaCopyWithImpl;
@useResult
$Res call({
 String id, Vaga vaga, CandidatoResumo candidato, EstadoDaCandidatura estado, DateTime criadoEm, DateTime? visualizadaEm
});


$VagaCopyWith<$Res> get vaga;$CandidatoResumoCopyWith<$Res> get candidato;

}
/// @nodoc
class _$CandidaturaCopyWithImpl<$Res>
    implements $CandidaturaCopyWith<$Res> {
  _$CandidaturaCopyWithImpl(this._self, this._then);

  final Candidatura _self;
  final $Res Function(Candidatura) _then;

/// Create a copy of Candidatura
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? vaga = null,Object? candidato = null,Object? estado = null,Object? criadoEm = null,Object? visualizadaEm = freezed,}) {
  return _then(Candidatura(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,vaga: null == vaga ? _self.vaga : vaga // ignore: cast_nullable_to_non_nullable
as Vaga,candidato: null == candidato ? _self.candidato : candidato // ignore: cast_nullable_to_non_nullable
as CandidatoResumo,estado: null == estado ? _self.estado : estado // ignore: cast_nullable_to_non_nullable
as EstadoDaCandidatura,criadoEm: null == criadoEm ? _self.criadoEm : criadoEm // ignore: cast_nullable_to_non_nullable
as DateTime,visualizadaEm: freezed == visualizadaEm ? _self.visualizadaEm : visualizadaEm // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}
/// Create a copy of Candidatura
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$VagaCopyWith<$Res> get vaga {
  
  return $VagaCopyWith<$Res>(_self.vaga, (value) {
    return _then(_self.copyWith(vaga: value));
  });
}/// Create a copy of Candidatura
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CandidatoResumoCopyWith<$Res> get candidato {
  
  return $CandidatoResumoCopyWith<$Res>(_self.candidato, (value) {
    return _then(_self.copyWith(candidato: value));
  });
}
}


/// Adds pattern-matching-related methods to [Candidatura].
extension CandidaturaPatterns on Candidatura {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Candidatura value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Candidatura() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Candidatura value)  $default,){
final _that = this;
switch (_that) {
case _Candidatura():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Candidatura value)?  $default,){
final _that = this;
switch (_that) {
case _Candidatura() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  Vaga vaga,  CandidatoResumo candidato,  EstadoDaCandidatura estado,  DateTime criadoEm,  DateTime? visualizadaEm)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Candidatura() when $default != null:
return $default(_that.id,_that.vaga,_that.candidato,_that.estado,_that.criadoEm,_that.visualizadaEm);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  Vaga vaga,  CandidatoResumo candidato,  EstadoDaCandidatura estado,  DateTime criadoEm,  DateTime? visualizadaEm)  $default,) {final _that = this;
switch (_that) {
case _Candidatura():
return $default(_that.id,_that.vaga,_that.candidato,_that.estado,_that.criadoEm,_that.visualizadaEm);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  Vaga vaga,  CandidatoResumo candidato,  EstadoDaCandidatura estado,  DateTime criadoEm,  DateTime? visualizadaEm)?  $default,) {final _that = this;
switch (_that) {
case _Candidatura() when $default != null:
return $default(_that.id,_that.vaga,_that.candidato,_that.estado,_that.criadoEm,_that.visualizadaEm);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Candidatura implements Candidatura {
  const _Candidatura({required this.id, required this.vaga, required this.candidato, required this.estado, required this.criadoEm, this.visualizadaEm});
  factory _Candidatura.fromJson(Map<String, dynamic> json) => _$CandidaturaFromJson(json);

@override final  String id;
@override final  Vaga vaga;
@override final  CandidatoResumo candidato;
@override final  EstadoDaCandidatura estado;
@override final  DateTime criadoEm;
/// A data da **primeira** vez que a empresa abriu. Marcar de novo não a move: é
/// o que o aluno lê como "foi vista", e uma data que andasse contaria quantas
/// vezes olharam.
@override final  DateTime? visualizadaEm;

/// Create a copy of Candidatura
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CandidaturaCopyWith<_Candidatura> get copyWith => __$CandidaturaCopyWithImpl<_Candidatura>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CandidaturaToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _Candidatura&&(identical(other.id, id) || other.id == id)&&(identical(other.vaga, vaga) || other.vaga == vaga)&&(identical(other.candidato, candidato) || other.candidato == candidato)&&(identical(other.estado, estado) || other.estado == estado)&&(identical(other.criadoEm, criadoEm) || other.criadoEm == criadoEm)&&(identical(other.visualizadaEm, visualizadaEm) || other.visualizadaEm == visualizadaEm));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,vaga,candidato,estado,criadoEm,visualizadaEm);
}

@override
String toString() {
    return 'Candidatura(id: $id, vaga: $vaga, candidato: $candidato, estado: $estado, criadoEm: $criadoEm, visualizadaEm: $visualizadaEm)';
}


}

/// @nodoc
abstract mixin class _$CandidaturaCopyWith<$Res> implements $CandidaturaCopyWith<$Res> {
  factory _$CandidaturaCopyWith(_Candidatura value, $Res Function(_Candidatura) _then) = __$CandidaturaCopyWithImpl;
@override @useResult
$Res call({
 String id, Vaga vaga, CandidatoResumo candidato, EstadoDaCandidatura estado, DateTime criadoEm, DateTime? visualizadaEm
});


@override $VagaCopyWith<$Res> get vaga;@override $CandidatoResumoCopyWith<$Res> get candidato;

}
/// @nodoc
class __$CandidaturaCopyWithImpl<$Res>
    implements _$CandidaturaCopyWith<$Res> {
  __$CandidaturaCopyWithImpl(this._self, this._then);

  final _Candidatura _self;
  final $Res Function(_Candidatura) _then;

/// Create a copy of Candidatura
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? vaga = null,Object? candidato = null,Object? estado = null,Object? criadoEm = null,Object? visualizadaEm = freezed,}) {
  return _then(_Candidatura(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,vaga: null == vaga ? _self.vaga : vaga // ignore: cast_nullable_to_non_nullable
as Vaga,candidato: null == candidato ? _self.candidato : candidato // ignore: cast_nullable_to_non_nullable
as CandidatoResumo,estado: null == estado ? _self.estado : estado // ignore: cast_nullable_to_non_nullable
as EstadoDaCandidatura,criadoEm: null == criadoEm ? _self.criadoEm : criadoEm // ignore: cast_nullable_to_non_nullable
as DateTime,visualizadaEm: freezed == visualizadaEm ? _self.visualizadaEm : visualizadaEm // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

/// Create a copy of Candidatura
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$VagaCopyWith<$Res> get vaga {
  
  return $VagaCopyWith<$Res>(_self.vaga, (value) {
    return _then(_self.copyWith(vaga: value));
  });
}/// Create a copy of Candidatura
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CandidatoResumoCopyWith<$Res> get candidato {
  
  return $CandidatoResumoCopyWith<$Res>(_self.candidato, (value) {
    return _then(_self.copyWith(candidato: value));
  });
}
}


/// @nodoc
mixin _$PaginaDeVagas {

 List<Vaga> get itens; String? get proximoCursor;
/// Create a copy of PaginaDeVagas
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PaginaDeVagasCopyWith<PaginaDeVagas> get copyWith => _$PaginaDeVagasCopyWithImpl<PaginaDeVagas>(this as PaginaDeVagas, _$identity);

  /// Serializes this PaginaDeVagas to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as PaginaDeVagas;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PaginaDeVagas&&const DeepCollectionEquality().equals(other.itens, _this.itens)&&(identical(other.proximoCursor, _this.proximoCursor) || other.proximoCursor == _this.proximoCursor));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as PaginaDeVagas;
  return Object.hash(runtimeType,const DeepCollectionEquality().hash(_this.itens),_this.proximoCursor);
}

@override
String toString() {
  final _this = this as PaginaDeVagas;
  return 'PaginaDeVagas(itens: ${_this.itens}, proximoCursor: ${_this.proximoCursor})';
}


}

/// @nodoc
abstract mixin class $PaginaDeVagasCopyWith<$Res>  {
  factory $PaginaDeVagasCopyWith(PaginaDeVagas value, $Res Function(PaginaDeVagas) _then) = _$PaginaDeVagasCopyWithImpl;
@useResult
$Res call({
 List<Vaga> itens, String? proximoCursor
});




}
/// @nodoc
class _$PaginaDeVagasCopyWithImpl<$Res>
    implements $PaginaDeVagasCopyWith<$Res> {
  _$PaginaDeVagasCopyWithImpl(this._self, this._then);

  final PaginaDeVagas _self;
  final $Res Function(PaginaDeVagas) _then;

/// Create a copy of PaginaDeVagas
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? itens = null,Object? proximoCursor = freezed,}) {
  return _then(PaginaDeVagas(
itens: null == itens ? _self.itens : itens // ignore: cast_nullable_to_non_nullable
as List<Vaga>,proximoCursor: freezed == proximoCursor ? _self.proximoCursor : proximoCursor // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [PaginaDeVagas].
extension PaginaDeVagasPatterns on PaginaDeVagas {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PaginaDeVagas value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PaginaDeVagas() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PaginaDeVagas value)  $default,){
final _that = this;
switch (_that) {
case _PaginaDeVagas():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PaginaDeVagas value)?  $default,){
final _that = this;
switch (_that) {
case _PaginaDeVagas() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<Vaga> itens,  String? proximoCursor)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PaginaDeVagas() when $default != null:
return $default(_that.itens,_that.proximoCursor);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<Vaga> itens,  String? proximoCursor)  $default,) {final _that = this;
switch (_that) {
case _PaginaDeVagas():
return $default(_that.itens,_that.proximoCursor);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<Vaga> itens,  String? proximoCursor)?  $default,) {final _that = this;
switch (_that) {
case _PaginaDeVagas() when $default != null:
return $default(_that.itens,_that.proximoCursor);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PaginaDeVagas implements PaginaDeVagas {
  const _PaginaDeVagas({ List<Vaga> itens = const <Vaga>[], this.proximoCursor}): _itens = itens;
  factory _PaginaDeVagas.fromJson(Map<String, dynamic> json) => _$PaginaDeVagasFromJson(json);

 final  List<Vaga> _itens;
@override@JsonKey() List<Vaga> get itens {
  if (_itens is EqualUnmodifiableListView) return _itens;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_itens);
}

@override final  String? proximoCursor;

/// Create a copy of PaginaDeVagas
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PaginaDeVagasCopyWith<_PaginaDeVagas> get copyWith => __$PaginaDeVagasCopyWithImpl<_PaginaDeVagas>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PaginaDeVagasToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _PaginaDeVagas&&const DeepCollectionEquality().equals(other.itens, _itens)&&(identical(other.proximoCursor, proximoCursor) || other.proximoCursor == proximoCursor));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,const DeepCollectionEquality().hash(_itens),proximoCursor);
}

@override
String toString() {
    return 'PaginaDeVagas(itens: $itens, proximoCursor: $proximoCursor)';
}


}

/// @nodoc
abstract mixin class _$PaginaDeVagasCopyWith<$Res> implements $PaginaDeVagasCopyWith<$Res> {
  factory _$PaginaDeVagasCopyWith(_PaginaDeVagas value, $Res Function(_PaginaDeVagas) _then) = __$PaginaDeVagasCopyWithImpl;
@override @useResult
$Res call({
 List<Vaga> itens, String? proximoCursor
});




}
/// @nodoc
class __$PaginaDeVagasCopyWithImpl<$Res>
    implements _$PaginaDeVagasCopyWith<$Res> {
  __$PaginaDeVagasCopyWithImpl(this._self, this._then);

  final _PaginaDeVagas _self;
  final $Res Function(_PaginaDeVagas) _then;

/// Create a copy of PaginaDeVagas
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? itens = null,Object? proximoCursor = freezed,}) {
  return _then(_PaginaDeVagas(
itens: null == itens ? _self._itens : itens // ignore: cast_nullable_to_non_nullable
as List<Vaga>,proximoCursor: freezed == proximoCursor ? _self.proximoCursor : proximoCursor // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$PaginaDeCandidaturas {

 List<Candidatura> get itens; String? get proximoCursor;
/// Create a copy of PaginaDeCandidaturas
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PaginaDeCandidaturasCopyWith<PaginaDeCandidaturas> get copyWith => _$PaginaDeCandidaturasCopyWithImpl<PaginaDeCandidaturas>(this as PaginaDeCandidaturas, _$identity);

  /// Serializes this PaginaDeCandidaturas to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as PaginaDeCandidaturas;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PaginaDeCandidaturas&&const DeepCollectionEquality().equals(other.itens, _this.itens)&&(identical(other.proximoCursor, _this.proximoCursor) || other.proximoCursor == _this.proximoCursor));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as PaginaDeCandidaturas;
  return Object.hash(runtimeType,const DeepCollectionEquality().hash(_this.itens),_this.proximoCursor);
}

@override
String toString() {
  final _this = this as PaginaDeCandidaturas;
  return 'PaginaDeCandidaturas(itens: ${_this.itens}, proximoCursor: ${_this.proximoCursor})';
}


}

/// @nodoc
abstract mixin class $PaginaDeCandidaturasCopyWith<$Res>  {
  factory $PaginaDeCandidaturasCopyWith(PaginaDeCandidaturas value, $Res Function(PaginaDeCandidaturas) _then) = _$PaginaDeCandidaturasCopyWithImpl;
@useResult
$Res call({
 List<Candidatura> itens, String? proximoCursor
});




}
/// @nodoc
class _$PaginaDeCandidaturasCopyWithImpl<$Res>
    implements $PaginaDeCandidaturasCopyWith<$Res> {
  _$PaginaDeCandidaturasCopyWithImpl(this._self, this._then);

  final PaginaDeCandidaturas _self;
  final $Res Function(PaginaDeCandidaturas) _then;

/// Create a copy of PaginaDeCandidaturas
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? itens = null,Object? proximoCursor = freezed,}) {
  return _then(PaginaDeCandidaturas(
itens: null == itens ? _self.itens : itens // ignore: cast_nullable_to_non_nullable
as List<Candidatura>,proximoCursor: freezed == proximoCursor ? _self.proximoCursor : proximoCursor // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [PaginaDeCandidaturas].
extension PaginaDeCandidaturasPatterns on PaginaDeCandidaturas {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PaginaDeCandidaturas value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PaginaDeCandidaturas() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PaginaDeCandidaturas value)  $default,){
final _that = this;
switch (_that) {
case _PaginaDeCandidaturas():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PaginaDeCandidaturas value)?  $default,){
final _that = this;
switch (_that) {
case _PaginaDeCandidaturas() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<Candidatura> itens,  String? proximoCursor)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PaginaDeCandidaturas() when $default != null:
return $default(_that.itens,_that.proximoCursor);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<Candidatura> itens,  String? proximoCursor)  $default,) {final _that = this;
switch (_that) {
case _PaginaDeCandidaturas():
return $default(_that.itens,_that.proximoCursor);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<Candidatura> itens,  String? proximoCursor)?  $default,) {final _that = this;
switch (_that) {
case _PaginaDeCandidaturas() when $default != null:
return $default(_that.itens,_that.proximoCursor);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PaginaDeCandidaturas implements PaginaDeCandidaturas {
  const _PaginaDeCandidaturas({ List<Candidatura> itens = const <Candidatura>[], this.proximoCursor}): _itens = itens;
  factory _PaginaDeCandidaturas.fromJson(Map<String, dynamic> json) => _$PaginaDeCandidaturasFromJson(json);

 final  List<Candidatura> _itens;
@override@JsonKey() List<Candidatura> get itens {
  if (_itens is EqualUnmodifiableListView) return _itens;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_itens);
}

@override final  String? proximoCursor;

/// Create a copy of PaginaDeCandidaturas
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PaginaDeCandidaturasCopyWith<_PaginaDeCandidaturas> get copyWith => __$PaginaDeCandidaturasCopyWithImpl<_PaginaDeCandidaturas>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PaginaDeCandidaturasToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _PaginaDeCandidaturas&&const DeepCollectionEquality().equals(other.itens, _itens)&&(identical(other.proximoCursor, proximoCursor) || other.proximoCursor == proximoCursor));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,const DeepCollectionEquality().hash(_itens),proximoCursor);
}

@override
String toString() {
    return 'PaginaDeCandidaturas(itens: $itens, proximoCursor: $proximoCursor)';
}


}

/// @nodoc
abstract mixin class _$PaginaDeCandidaturasCopyWith<$Res> implements $PaginaDeCandidaturasCopyWith<$Res> {
  factory _$PaginaDeCandidaturasCopyWith(_PaginaDeCandidaturas value, $Res Function(_PaginaDeCandidaturas) _then) = __$PaginaDeCandidaturasCopyWithImpl;
@override @useResult
$Res call({
 List<Candidatura> itens, String? proximoCursor
});




}
/// @nodoc
class __$PaginaDeCandidaturasCopyWithImpl<$Res>
    implements _$PaginaDeCandidaturasCopyWith<$Res> {
  __$PaginaDeCandidaturasCopyWithImpl(this._self, this._then);

  final _PaginaDeCandidaturas _self;
  final $Res Function(_PaginaDeCandidaturas) _then;

/// Create a copy of PaginaDeCandidaturas
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? itens = null,Object? proximoCursor = freezed,}) {
  return _then(_PaginaDeCandidaturas(
itens: null == itens ? _self._itens : itens // ignore: cast_nullable_to_non_nullable
as List<Candidatura>,proximoCursor: freezed == proximoCursor ? _self.proximoCursor : proximoCursor // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

/// @nodoc
mixin _$FiltroDeVagas {

 TipoDeVaga? get tipo; Modalidade? get modalidade;/// As vagas de uma empresa — a aba de vagas do perfil dela.
 String? get empresaId;/// Abertas por padrão. `fechada` existe para a empresa ver o que encerrou, e
/// **não é filtro de autorização**: vaga fechada não é conteúdo restrito, só
/// conteúdo velho.
 EstadoDaVaga get estado;
/// Create a copy of FiltroDeVagas
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FiltroDeVagasCopyWith<FiltroDeVagas> get copyWith => _$FiltroDeVagasCopyWithImpl<FiltroDeVagas>(this as FiltroDeVagas, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as FiltroDeVagas;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is FiltroDeVagas&&(identical(other.tipo, _this.tipo) || other.tipo == _this.tipo)&&(identical(other.modalidade, _this.modalidade) || other.modalidade == _this.modalidade)&&(identical(other.empresaId, _this.empresaId) || other.empresaId == _this.empresaId)&&(identical(other.estado, _this.estado) || other.estado == _this.estado));
}


@override
int get hashCode {
  final _this = this as FiltroDeVagas;
  return Object.hash(runtimeType,_this.tipo,_this.modalidade,_this.empresaId,_this.estado);
}

@override
String toString() {
  final _this = this as FiltroDeVagas;
  return 'FiltroDeVagas(tipo: ${_this.tipo}, modalidade: ${_this.modalidade}, empresaId: ${_this.empresaId}, estado: ${_this.estado})';
}


}

/// @nodoc
abstract mixin class $FiltroDeVagasCopyWith<$Res>  {
  factory $FiltroDeVagasCopyWith(FiltroDeVagas value, $Res Function(FiltroDeVagas) _then) = _$FiltroDeVagasCopyWithImpl;
@useResult
$Res call({
 TipoDeVaga? tipo, Modalidade? modalidade, String? empresaId, EstadoDaVaga estado
});




}
/// @nodoc
class _$FiltroDeVagasCopyWithImpl<$Res>
    implements $FiltroDeVagasCopyWith<$Res> {
  _$FiltroDeVagasCopyWithImpl(this._self, this._then);

  final FiltroDeVagas _self;
  final $Res Function(FiltroDeVagas) _then;

/// Create a copy of FiltroDeVagas
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? tipo = freezed,Object? modalidade = freezed,Object? empresaId = freezed,Object? estado = null,}) {
  return _then(FiltroDeVagas(
tipo: freezed == tipo ? _self.tipo : tipo // ignore: cast_nullable_to_non_nullable
as TipoDeVaga?,modalidade: freezed == modalidade ? _self.modalidade : modalidade // ignore: cast_nullable_to_non_nullable
as Modalidade?,empresaId: freezed == empresaId ? _self.empresaId : empresaId // ignore: cast_nullable_to_non_nullable
as String?,estado: null == estado ? _self.estado : estado // ignore: cast_nullable_to_non_nullable
as EstadoDaVaga,
  ));
}

}


/// Adds pattern-matching-related methods to [FiltroDeVagas].
extension FiltroDeVagasPatterns on FiltroDeVagas {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _FiltroDeVagas value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _FiltroDeVagas() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _FiltroDeVagas value)  $default,){
final _that = this;
switch (_that) {
case _FiltroDeVagas():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _FiltroDeVagas value)?  $default,){
final _that = this;
switch (_that) {
case _FiltroDeVagas() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( TipoDeVaga? tipo,  Modalidade? modalidade,  String? empresaId,  EstadoDaVaga estado)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _FiltroDeVagas() when $default != null:
return $default(_that.tipo,_that.modalidade,_that.empresaId,_that.estado);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( TipoDeVaga? tipo,  Modalidade? modalidade,  String? empresaId,  EstadoDaVaga estado)  $default,) {final _that = this;
switch (_that) {
case _FiltroDeVagas():
return $default(_that.tipo,_that.modalidade,_that.empresaId,_that.estado);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( TipoDeVaga? tipo,  Modalidade? modalidade,  String? empresaId,  EstadoDaVaga estado)?  $default,) {final _that = this;
switch (_that) {
case _FiltroDeVagas() when $default != null:
return $default(_that.tipo,_that.modalidade,_that.empresaId,_that.estado);case _:
  return null;

}
}

}

/// @nodoc


class _FiltroDeVagas implements FiltroDeVagas {
  const _FiltroDeVagas({this.tipo, this.modalidade, this.empresaId, this.estado = EstadoDaVaga.aberta});
  

@override final  TipoDeVaga? tipo;
@override final  Modalidade? modalidade;
/// As vagas de uma empresa — a aba de vagas do perfil dela.
@override final  String? empresaId;
/// Abertas por padrão. `fechada` existe para a empresa ver o que encerrou, e
/// **não é filtro de autorização**: vaga fechada não é conteúdo restrito, só
/// conteúdo velho.
@override@JsonKey() final  EstadoDaVaga estado;

/// Create a copy of FiltroDeVagas
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$FiltroDeVagasCopyWith<_FiltroDeVagas> get copyWith => __$FiltroDeVagasCopyWithImpl<_FiltroDeVagas>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _FiltroDeVagas&&(identical(other.tipo, tipo) || other.tipo == tipo)&&(identical(other.modalidade, modalidade) || other.modalidade == modalidade)&&(identical(other.empresaId, empresaId) || other.empresaId == empresaId)&&(identical(other.estado, estado) || other.estado == estado));
}


@override
int get hashCode {
    return Object.hash(runtimeType,tipo,modalidade,empresaId,estado);
}

@override
String toString() {
    return 'FiltroDeVagas(tipo: $tipo, modalidade: $modalidade, empresaId: $empresaId, estado: $estado)';
}


}

/// @nodoc
abstract mixin class _$FiltroDeVagasCopyWith<$Res> implements $FiltroDeVagasCopyWith<$Res> {
  factory _$FiltroDeVagasCopyWith(_FiltroDeVagas value, $Res Function(_FiltroDeVagas) _then) = __$FiltroDeVagasCopyWithImpl;
@override @useResult
$Res call({
 TipoDeVaga? tipo, Modalidade? modalidade, String? empresaId, EstadoDaVaga estado
});




}
/// @nodoc
class __$FiltroDeVagasCopyWithImpl<$Res>
    implements _$FiltroDeVagasCopyWith<$Res> {
  __$FiltroDeVagasCopyWithImpl(this._self, this._then);

  final _FiltroDeVagas _self;
  final $Res Function(_FiltroDeVagas) _then;

/// Create a copy of FiltroDeVagas
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? tipo = freezed,Object? modalidade = freezed,Object? empresaId = freezed,Object? estado = null,}) {
  return _then(_FiltroDeVagas(
tipo: freezed == tipo ? _self.tipo : tipo // ignore: cast_nullable_to_non_nullable
as TipoDeVaga?,modalidade: freezed == modalidade ? _self.modalidade : modalidade // ignore: cast_nullable_to_non_nullable
as Modalidade?,empresaId: freezed == empresaId ? _self.empresaId : empresaId // ignore: cast_nullable_to_non_nullable
as String?,estado: null == estado ? _self.estado : estado // ignore: cast_nullable_to_non_nullable
as EstadoDaVaga,
  ));
}


}

// dart format on
