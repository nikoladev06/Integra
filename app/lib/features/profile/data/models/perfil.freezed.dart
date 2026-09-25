// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'perfil.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Universidade {

 String get id; String get nome; String get sigla;/// Se já existe conta institucional administrando esta universidade.
///
/// O perfil de uma sem conta não tem posts nem matrículas — e a tela diz
/// isso, em vez de mostrar um feed vazio sem explicação.
 bool get temConta;
/// Create a copy of Universidade
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$UniversidadeCopyWith<Universidade> get copyWith => _$UniversidadeCopyWithImpl<Universidade>(this as Universidade, _$identity);

  /// Serializes this Universidade to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as Universidade;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Universidade&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.nome, _this.nome) || other.nome == _this.nome)&&(identical(other.sigla, _this.sigla) || other.sigla == _this.sigla)&&(identical(other.temConta, _this.temConta) || other.temConta == _this.temConta));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as Universidade;
  return Object.hash(runtimeType,_this.id,_this.nome,_this.sigla,_this.temConta);
}

@override
String toString() {
  final _this = this as Universidade;
  return 'Universidade(id: ${_this.id}, nome: ${_this.nome}, sigla: ${_this.sigla}, temConta: ${_this.temConta})';
}


}

/// @nodoc
abstract mixin class $UniversidadeCopyWith<$Res>  {
  factory $UniversidadeCopyWith(Universidade value, $Res Function(Universidade) _then) = _$UniversidadeCopyWithImpl;
@useResult
$Res call({
 String id, String nome, String sigla, bool temConta
});




}
/// @nodoc
class _$UniversidadeCopyWithImpl<$Res>
    implements $UniversidadeCopyWith<$Res> {
  _$UniversidadeCopyWithImpl(this._self, this._then);

  final Universidade _self;
  final $Res Function(Universidade) _then;

/// Create a copy of Universidade
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? nome = null,Object? sigla = null,Object? temConta = null,}) {
  return _then(Universidade(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,nome: null == nome ? _self.nome : nome // ignore: cast_nullable_to_non_nullable
as String,sigla: null == sigla ? _self.sigla : sigla // ignore: cast_nullable_to_non_nullable
as String,temConta: null == temConta ? _self.temConta : temConta // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [Universidade].
extension UniversidadePatterns on Universidade {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Universidade value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Universidade() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Universidade value)  $default,){
final _that = this;
switch (_that) {
case _Universidade():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Universidade value)?  $default,){
final _that = this;
switch (_that) {
case _Universidade() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String nome,  String sigla,  bool temConta)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Universidade() when $default != null:
return $default(_that.id,_that.nome,_that.sigla,_that.temConta);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String nome,  String sigla,  bool temConta)  $default,) {final _that = this;
switch (_that) {
case _Universidade():
return $default(_that.id,_that.nome,_that.sigla,_that.temConta);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String nome,  String sigla,  bool temConta)?  $default,) {final _that = this;
switch (_that) {
case _Universidade() when $default != null:
return $default(_that.id,_that.nome,_that.sigla,_that.temConta);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Universidade implements Universidade {
  const _Universidade({required this.id, required this.nome, required this.sigla, this.temConta = false});
  factory _Universidade.fromJson(Map<String, dynamic> json) => _$UniversidadeFromJson(json);

@override final  String id;
@override final  String nome;
@override final  String sigla;
/// Se já existe conta institucional administrando esta universidade.
///
/// O perfil de uma sem conta não tem posts nem matrículas — e a tela diz
/// isso, em vez de mostrar um feed vazio sem explicação.
@override@JsonKey() final  bool temConta;

/// Create a copy of Universidade
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$UniversidadeCopyWith<_Universidade> get copyWith => __$UniversidadeCopyWithImpl<_Universidade>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$UniversidadeToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _Universidade&&(identical(other.id, id) || other.id == id)&&(identical(other.nome, nome) || other.nome == nome)&&(identical(other.sigla, sigla) || other.sigla == sigla)&&(identical(other.temConta, temConta) || other.temConta == temConta));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,nome,sigla,temConta);
}

@override
String toString() {
    return 'Universidade(id: $id, nome: $nome, sigla: $sigla, temConta: $temConta)';
}


}

/// @nodoc
abstract mixin class _$UniversidadeCopyWith<$Res> implements $UniversidadeCopyWith<$Res> {
  factory _$UniversidadeCopyWith(_Universidade value, $Res Function(_Universidade) _then) = __$UniversidadeCopyWithImpl;
@override @useResult
$Res call({
 String id, String nome, String sigla, bool temConta
});




}
/// @nodoc
class __$UniversidadeCopyWithImpl<$Res>
    implements _$UniversidadeCopyWith<$Res> {
  __$UniversidadeCopyWithImpl(this._self, this._then);

  final _Universidade _self;
  final $Res Function(_Universidade) _then;

/// Create a copy of Universidade
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? nome = null,Object? sigla = null,Object? temConta = null,}) {
  return _then(_Universidade(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,nome: null == nome ? _self.nome : nome // ignore: cast_nullable_to_non_nullable
as String,sigla: null == sigla ? _self.sigla : sigla // ignore: cast_nullable_to_non_nullable
as String,temConta: null == temConta ? _self.temConta : temConta // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}


/// @nodoc
mixin _$Curso {

 String get id; String get nome;
/// Create a copy of Curso
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CursoCopyWith<Curso> get copyWith => _$CursoCopyWithImpl<Curso>(this as Curso, _$identity);

  /// Serializes this Curso to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as Curso;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Curso&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.nome, _this.nome) || other.nome == _this.nome));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as Curso;
  return Object.hash(runtimeType,_this.id,_this.nome);
}

@override
String toString() {
  final _this = this as Curso;
  return 'Curso(id: ${_this.id}, nome: ${_this.nome})';
}


}

/// @nodoc
abstract mixin class $CursoCopyWith<$Res>  {
  factory $CursoCopyWith(Curso value, $Res Function(Curso) _then) = _$CursoCopyWithImpl;
@useResult
$Res call({
 String id, String nome
});




}
/// @nodoc
class _$CursoCopyWithImpl<$Res>
    implements $CursoCopyWith<$Res> {
  _$CursoCopyWithImpl(this._self, this._then);

  final Curso _self;
  final $Res Function(Curso) _then;

/// Create a copy of Curso
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? nome = null,}) {
  return _then(Curso(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,nome: null == nome ? _self.nome : nome // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [Curso].
extension CursoPatterns on Curso {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Curso value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Curso() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Curso value)  $default,){
final _that = this;
switch (_that) {
case _Curso():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Curso value)?  $default,){
final _that = this;
switch (_that) {
case _Curso() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String nome)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Curso() when $default != null:
return $default(_that.id,_that.nome);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String nome)  $default,) {final _that = this;
switch (_that) {
case _Curso():
return $default(_that.id,_that.nome);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String nome)?  $default,) {final _that = this;
switch (_that) {
case _Curso() when $default != null:
return $default(_that.id,_that.nome);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Curso implements Curso {
  const _Curso({required this.id, required this.nome});
  factory _Curso.fromJson(Map<String, dynamic> json) => _$CursoFromJson(json);

@override final  String id;
@override final  String nome;

/// Create a copy of Curso
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CursoCopyWith<_Curso> get copyWith => __$CursoCopyWithImpl<_Curso>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CursoToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _Curso&&(identical(other.id, id) || other.id == id)&&(identical(other.nome, nome) || other.nome == nome));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,nome);
}

@override
String toString() {
    return 'Curso(id: $id, nome: $nome)';
}


}

/// @nodoc
abstract mixin class _$CursoCopyWith<$Res> implements $CursoCopyWith<$Res> {
  factory _$CursoCopyWith(_Curso value, $Res Function(_Curso) _then) = __$CursoCopyWithImpl;
@override @useResult
$Res call({
 String id, String nome
});




}
/// @nodoc
class __$CursoCopyWithImpl<$Res>
    implements _$CursoCopyWith<$Res> {
  __$CursoCopyWithImpl(this._self, this._then);

  final _Curso _self;
  final $Res Function(_Curso) _then;

/// Create a copy of Curso
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? nome = null,}) {
  return _then(_Curso(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,nome: null == nome ? _self.nome : nome // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$Formacao {

 String get id; Universidade get universidade; Curso get curso; DateTime get criadoEm; DateTime? get verificadaEm;
/// Create a copy of Formacao
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FormacaoCopyWith<Formacao> get copyWith => _$FormacaoCopyWithImpl<Formacao>(this as Formacao, _$identity);

  /// Serializes this Formacao to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as Formacao;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Formacao&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.universidade, _this.universidade) || other.universidade == _this.universidade)&&(identical(other.curso, _this.curso) || other.curso == _this.curso)&&(identical(other.criadoEm, _this.criadoEm) || other.criadoEm == _this.criadoEm)&&(identical(other.verificadaEm, _this.verificadaEm) || other.verificadaEm == _this.verificadaEm));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as Formacao;
  return Object.hash(runtimeType,_this.id,_this.universidade,_this.curso,_this.criadoEm,_this.verificadaEm);
}

@override
String toString() {
  final _this = this as Formacao;
  return 'Formacao(id: ${_this.id}, universidade: ${_this.universidade}, curso: ${_this.curso}, criadoEm: ${_this.criadoEm}, verificadaEm: ${_this.verificadaEm})';
}


}

/// @nodoc
abstract mixin class $FormacaoCopyWith<$Res>  {
  factory $FormacaoCopyWith(Formacao value, $Res Function(Formacao) _then) = _$FormacaoCopyWithImpl;
@useResult
$Res call({
 String id, Universidade universidade, Curso curso, DateTime criadoEm, DateTime? verificadaEm
});


$UniversidadeCopyWith<$Res> get universidade;$CursoCopyWith<$Res> get curso;

}
/// @nodoc
class _$FormacaoCopyWithImpl<$Res>
    implements $FormacaoCopyWith<$Res> {
  _$FormacaoCopyWithImpl(this._self, this._then);

  final Formacao _self;
  final $Res Function(Formacao) _then;

/// Create a copy of Formacao
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? universidade = null,Object? curso = null,Object? criadoEm = null,Object? verificadaEm = freezed,}) {
  return _then(Formacao(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,universidade: null == universidade ? _self.universidade : universidade // ignore: cast_nullable_to_non_nullable
as Universidade,curso: null == curso ? _self.curso : curso // ignore: cast_nullable_to_non_nullable
as Curso,criadoEm: null == criadoEm ? _self.criadoEm : criadoEm // ignore: cast_nullable_to_non_nullable
as DateTime,verificadaEm: freezed == verificadaEm ? _self.verificadaEm : verificadaEm // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}
/// Create a copy of Formacao
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$UniversidadeCopyWith<$Res> get universidade {
  
  return $UniversidadeCopyWith<$Res>(_self.universidade, (value) {
    return _then(_self.copyWith(universidade: value));
  });
}/// Create a copy of Formacao
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CursoCopyWith<$Res> get curso {
  
  return $CursoCopyWith<$Res>(_self.curso, (value) {
    return _then(_self.copyWith(curso: value));
  });
}
}


/// Adds pattern-matching-related methods to [Formacao].
extension FormacaoPatterns on Formacao {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Formacao value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Formacao() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Formacao value)  $default,){
final _that = this;
switch (_that) {
case _Formacao():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Formacao value)?  $default,){
final _that = this;
switch (_that) {
case _Formacao() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  Universidade universidade,  Curso curso,  DateTime criadoEm,  DateTime? verificadaEm)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Formacao() when $default != null:
return $default(_that.id,_that.universidade,_that.curso,_that.criadoEm,_that.verificadaEm);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  Universidade universidade,  Curso curso,  DateTime criadoEm,  DateTime? verificadaEm)  $default,) {final _that = this;
switch (_that) {
case _Formacao():
return $default(_that.id,_that.universidade,_that.curso,_that.criadoEm,_that.verificadaEm);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  Universidade universidade,  Curso curso,  DateTime criadoEm,  DateTime? verificadaEm)?  $default,) {final _that = this;
switch (_that) {
case _Formacao() when $default != null:
return $default(_that.id,_that.universidade,_that.curso,_that.criadoEm,_that.verificadaEm);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Formacao implements Formacao {
  const _Formacao({required this.id, required this.universidade, required this.curso, required this.criadoEm, this.verificadaEm});
  factory _Formacao.fromJson(Map<String, dynamic> json) => _$FormacaoFromJson(json);

@override final  String id;
@override final  Universidade universidade;
@override final  Curso curso;
@override final  DateTime criadoEm;
@override final  DateTime? verificadaEm;

/// Create a copy of Formacao
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$FormacaoCopyWith<_Formacao> get copyWith => __$FormacaoCopyWithImpl<_Formacao>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$FormacaoToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _Formacao&&(identical(other.id, id) || other.id == id)&&(identical(other.universidade, universidade) || other.universidade == universidade)&&(identical(other.curso, curso) || other.curso == curso)&&(identical(other.criadoEm, criadoEm) || other.criadoEm == criadoEm)&&(identical(other.verificadaEm, verificadaEm) || other.verificadaEm == verificadaEm));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,universidade,curso,criadoEm,verificadaEm);
}

@override
String toString() {
    return 'Formacao(id: $id, universidade: $universidade, curso: $curso, criadoEm: $criadoEm, verificadaEm: $verificadaEm)';
}


}

/// @nodoc
abstract mixin class _$FormacaoCopyWith<$Res> implements $FormacaoCopyWith<$Res> {
  factory _$FormacaoCopyWith(_Formacao value, $Res Function(_Formacao) _then) = __$FormacaoCopyWithImpl;
@override @useResult
$Res call({
 String id, Universidade universidade, Curso curso, DateTime criadoEm, DateTime? verificadaEm
});


@override $UniversidadeCopyWith<$Res> get universidade;@override $CursoCopyWith<$Res> get curso;

}
/// @nodoc
class __$FormacaoCopyWithImpl<$Res>
    implements _$FormacaoCopyWith<$Res> {
  __$FormacaoCopyWithImpl(this._self, this._then);

  final _Formacao _self;
  final $Res Function(_Formacao) _then;

/// Create a copy of Formacao
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? universidade = null,Object? curso = null,Object? criadoEm = null,Object? verificadaEm = freezed,}) {
  return _then(_Formacao(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,universidade: null == universidade ? _self.universidade : universidade // ignore: cast_nullable_to_non_nullable
as Universidade,curso: null == curso ? _self.curso : curso // ignore: cast_nullable_to_non_nullable
as Curso,criadoEm: null == criadoEm ? _self.criadoEm : criadoEm // ignore: cast_nullable_to_non_nullable
as DateTime,verificadaEm: freezed == verificadaEm ? _self.verificadaEm : verificadaEm // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

/// Create a copy of Formacao
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$UniversidadeCopyWith<$Res> get universidade {
  
  return $UniversidadeCopyWith<$Res>(_self.universidade, (value) {
    return _then(_self.copyWith(universidade: value));
  });
}/// Create a copy of Formacao
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CursoCopyWith<$Res> get curso {
  
  return $CursoCopyWith<$Res>(_self.curso, (value) {
    return _then(_self.copyWith(curso: value));
  });
}
}


/// @nodoc
mixin _$Vinculo {

 Universidade get universidade; Curso get curso; DateTime get criadoEm;
/// Create a copy of Vinculo
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$VinculoCopyWith<Vinculo> get copyWith => _$VinculoCopyWithImpl<Vinculo>(this as Vinculo, _$identity);

  /// Serializes this Vinculo to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as Vinculo;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Vinculo&&(identical(other.universidade, _this.universidade) || other.universidade == _this.universidade)&&(identical(other.curso, _this.curso) || other.curso == _this.curso)&&(identical(other.criadoEm, _this.criadoEm) || other.criadoEm == _this.criadoEm));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as Vinculo;
  return Object.hash(runtimeType,_this.universidade,_this.curso,_this.criadoEm);
}

@override
String toString() {
  final _this = this as Vinculo;
  return 'Vinculo(universidade: ${_this.universidade}, curso: ${_this.curso}, criadoEm: ${_this.criadoEm})';
}


}

/// @nodoc
abstract mixin class $VinculoCopyWith<$Res>  {
  factory $VinculoCopyWith(Vinculo value, $Res Function(Vinculo) _then) = _$VinculoCopyWithImpl;
@useResult
$Res call({
 Universidade universidade, Curso curso, DateTime criadoEm
});


$UniversidadeCopyWith<$Res> get universidade;$CursoCopyWith<$Res> get curso;

}
/// @nodoc
class _$VinculoCopyWithImpl<$Res>
    implements $VinculoCopyWith<$Res> {
  _$VinculoCopyWithImpl(this._self, this._then);

  final Vinculo _self;
  final $Res Function(Vinculo) _then;

/// Create a copy of Vinculo
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? universidade = null,Object? curso = null,Object? criadoEm = null,}) {
  return _then(Vinculo(
universidade: null == universidade ? _self.universidade : universidade // ignore: cast_nullable_to_non_nullable
as Universidade,curso: null == curso ? _self.curso : curso // ignore: cast_nullable_to_non_nullable
as Curso,criadoEm: null == criadoEm ? _self.criadoEm : criadoEm // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}
/// Create a copy of Vinculo
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$UniversidadeCopyWith<$Res> get universidade {
  
  return $UniversidadeCopyWith<$Res>(_self.universidade, (value) {
    return _then(_self.copyWith(universidade: value));
  });
}/// Create a copy of Vinculo
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CursoCopyWith<$Res> get curso {
  
  return $CursoCopyWith<$Res>(_self.curso, (value) {
    return _then(_self.copyWith(curso: value));
  });
}
}


/// Adds pattern-matching-related methods to [Vinculo].
extension VinculoPatterns on Vinculo {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Vinculo value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Vinculo() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Vinculo value)  $default,){
final _that = this;
switch (_that) {
case _Vinculo():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Vinculo value)?  $default,){
final _that = this;
switch (_that) {
case _Vinculo() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( Universidade universidade,  Curso curso,  DateTime criadoEm)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Vinculo() when $default != null:
return $default(_that.universidade,_that.curso,_that.criadoEm);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( Universidade universidade,  Curso curso,  DateTime criadoEm)  $default,) {final _that = this;
switch (_that) {
case _Vinculo():
return $default(_that.universidade,_that.curso,_that.criadoEm);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( Universidade universidade,  Curso curso,  DateTime criadoEm)?  $default,) {final _that = this;
switch (_that) {
case _Vinculo() when $default != null:
return $default(_that.universidade,_that.curso,_that.criadoEm);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Vinculo implements Vinculo {
  const _Vinculo({required this.universidade, required this.curso, required this.criadoEm});
  factory _Vinculo.fromJson(Map<String, dynamic> json) => _$VinculoFromJson(json);

@override final  Universidade universidade;
@override final  Curso curso;
@override final  DateTime criadoEm;

/// Create a copy of Vinculo
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$VinculoCopyWith<_Vinculo> get copyWith => __$VinculoCopyWithImpl<_Vinculo>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$VinculoToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _Vinculo&&(identical(other.universidade, universidade) || other.universidade == universidade)&&(identical(other.curso, curso) || other.curso == curso)&&(identical(other.criadoEm, criadoEm) || other.criadoEm == criadoEm));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,universidade,curso,criadoEm);
}

@override
String toString() {
    return 'Vinculo(universidade: $universidade, curso: $curso, criadoEm: $criadoEm)';
}


}

/// @nodoc
abstract mixin class _$VinculoCopyWith<$Res> implements $VinculoCopyWith<$Res> {
  factory _$VinculoCopyWith(_Vinculo value, $Res Function(_Vinculo) _then) = __$VinculoCopyWithImpl;
@override @useResult
$Res call({
 Universidade universidade, Curso curso, DateTime criadoEm
});


@override $UniversidadeCopyWith<$Res> get universidade;@override $CursoCopyWith<$Res> get curso;

}
/// @nodoc
class __$VinculoCopyWithImpl<$Res>
    implements _$VinculoCopyWith<$Res> {
  __$VinculoCopyWithImpl(this._self, this._then);

  final _Vinculo _self;
  final $Res Function(_Vinculo) _then;

/// Create a copy of Vinculo
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? universidade = null,Object? curso = null,Object? criadoEm = null,}) {
  return _then(_Vinculo(
universidade: null == universidade ? _self.universidade : universidade // ignore: cast_nullable_to_non_nullable
as Universidade,curso: null == curso ? _self.curso : curso // ignore: cast_nullable_to_non_nullable
as Curso,criadoEm: null == criadoEm ? _self.criadoEm : criadoEm // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

/// Create a copy of Vinculo
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$UniversidadeCopyWith<$Res> get universidade {
  
  return $UniversidadeCopyWith<$Res>(_self.universidade, (value) {
    return _then(_self.copyWith(universidade: value));
  });
}/// Create a copy of Vinculo
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CursoCopyWith<$Res> get curso {
  
  return $CursoCopyWith<$Res>(_self.curso, (value) {
    return _then(_self.copyWith(curso: value));
  });
}
}


/// @nodoc
mixin _$Perfil {

 String get id; String get nomeCompleto; String get username; TipoConta get tipo; DateTime get criadoEm;/// O currículo. Pode estar vazio — é o estado de quem acabou de entrar.
 List<Formacao> get formacoes;/// A instituição atual, quando há. Público de propósito: é o equivalente a
/// "trabalha em" num perfil profissional.
 Vinculo? get vinculo; String? get fotoUrl; String? get bio; String? get email;/// Apenas dígitos. Nulo em conta `faculdade` e `empresa`.
 String? get cpf;/// Apenas dígitos. Nulo em conta de aluno. Uma conta nunca tem os dois.
 String? get cnpj; String? get telefone;/// Quando a conta passou a poder agir. **Nulo significa pendente**, e só
/// acontece em conta institucional: a de aluno nasce ativa.
 DateTime? get ativadaEm; DateTime? get alteradoEm;
/// Create a copy of Perfil
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PerfilCopyWith<Perfil> get copyWith => _$PerfilCopyWithImpl<Perfil>(this as Perfil, _$identity);

  /// Serializes this Perfil to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as Perfil;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Perfil&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.nomeCompleto, _this.nomeCompleto) || other.nomeCompleto == _this.nomeCompleto)&&(identical(other.username, _this.username) || other.username == _this.username)&&(identical(other.tipo, _this.tipo) || other.tipo == _this.tipo)&&(identical(other.criadoEm, _this.criadoEm) || other.criadoEm == _this.criadoEm)&&const DeepCollectionEquality().equals(other.formacoes, _this.formacoes)&&(identical(other.vinculo, _this.vinculo) || other.vinculo == _this.vinculo)&&(identical(other.fotoUrl, _this.fotoUrl) || other.fotoUrl == _this.fotoUrl)&&(identical(other.bio, _this.bio) || other.bio == _this.bio)&&(identical(other.email, _this.email) || other.email == _this.email)&&(identical(other.cpf, _this.cpf) || other.cpf == _this.cpf)&&(identical(other.cnpj, _this.cnpj) || other.cnpj == _this.cnpj)&&(identical(other.telefone, _this.telefone) || other.telefone == _this.telefone)&&(identical(other.ativadaEm, _this.ativadaEm) || other.ativadaEm == _this.ativadaEm)&&(identical(other.alteradoEm, _this.alteradoEm) || other.alteradoEm == _this.alteradoEm));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as Perfil;
  return Object.hash(runtimeType,_this.id,_this.nomeCompleto,_this.username,_this.tipo,_this.criadoEm,const DeepCollectionEquality().hash(_this.formacoes),_this.vinculo,_this.fotoUrl,_this.bio,_this.email,_this.cpf,_this.cnpj,_this.telefone,_this.ativadaEm,_this.alteradoEm);
}

@override
String toString() {
  final _this = this as Perfil;
  return 'Perfil(id: ${_this.id}, nomeCompleto: ${_this.nomeCompleto}, username: ${_this.username}, tipo: ${_this.tipo}, criadoEm: ${_this.criadoEm}, formacoes: ${_this.formacoes}, vinculo: ${_this.vinculo}, fotoUrl: ${_this.fotoUrl}, bio: ${_this.bio}, email: ${_this.email}, cpf: ${_this.cpf}, cnpj: ${_this.cnpj}, telefone: ${_this.telefone}, ativadaEm: ${_this.ativadaEm}, alteradoEm: ${_this.alteradoEm})';
}


}

/// @nodoc
abstract mixin class $PerfilCopyWith<$Res>  {
  factory $PerfilCopyWith(Perfil value, $Res Function(Perfil) _then) = _$PerfilCopyWithImpl;
@useResult
$Res call({
 String id, String nomeCompleto, String username, TipoConta tipo, DateTime criadoEm, List<Formacao> formacoes, Vinculo? vinculo, String? fotoUrl, String? bio, String? email, String? cpf, String? cnpj, String? telefone, DateTime? ativadaEm, DateTime? alteradoEm
});


$VinculoCopyWith<$Res>? get vinculo;

}
/// @nodoc
class _$PerfilCopyWithImpl<$Res>
    implements $PerfilCopyWith<$Res> {
  _$PerfilCopyWithImpl(this._self, this._then);

  final Perfil _self;
  final $Res Function(Perfil) _then;

/// Create a copy of Perfil
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? nomeCompleto = null,Object? username = null,Object? tipo = null,Object? criadoEm = null,Object? formacoes = null,Object? vinculo = freezed,Object? fotoUrl = freezed,Object? bio = freezed,Object? email = freezed,Object? cpf = freezed,Object? cnpj = freezed,Object? telefone = freezed,Object? ativadaEm = freezed,Object? alteradoEm = freezed,}) {
  return _then(Perfil(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,nomeCompleto: null == nomeCompleto ? _self.nomeCompleto : nomeCompleto // ignore: cast_nullable_to_non_nullable
as String,username: null == username ? _self.username : username // ignore: cast_nullable_to_non_nullable
as String,tipo: null == tipo ? _self.tipo : tipo // ignore: cast_nullable_to_non_nullable
as TipoConta,criadoEm: null == criadoEm ? _self.criadoEm : criadoEm // ignore: cast_nullable_to_non_nullable
as DateTime,formacoes: null == formacoes ? _self.formacoes : formacoes // ignore: cast_nullable_to_non_nullable
as List<Formacao>,vinculo: freezed == vinculo ? _self.vinculo : vinculo // ignore: cast_nullable_to_non_nullable
as Vinculo?,fotoUrl: freezed == fotoUrl ? _self.fotoUrl : fotoUrl // ignore: cast_nullable_to_non_nullable
as String?,bio: freezed == bio ? _self.bio : bio // ignore: cast_nullable_to_non_nullable
as String?,email: freezed == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String?,cpf: freezed == cpf ? _self.cpf : cpf // ignore: cast_nullable_to_non_nullable
as String?,cnpj: freezed == cnpj ? _self.cnpj : cnpj // ignore: cast_nullable_to_non_nullable
as String?,telefone: freezed == telefone ? _self.telefone : telefone // ignore: cast_nullable_to_non_nullable
as String?,ativadaEm: freezed == ativadaEm ? _self.ativadaEm : ativadaEm // ignore: cast_nullable_to_non_nullable
as DateTime?,alteradoEm: freezed == alteradoEm ? _self.alteradoEm : alteradoEm // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}
/// Create a copy of Perfil
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$VinculoCopyWith<$Res>? get vinculo {
    if (_self.vinculo == null) {
    return null;
  }

  return $VinculoCopyWith<$Res>(_self.vinculo!, (value) {
    return _then(_self.copyWith(vinculo: value));
  });
}
}


/// Adds pattern-matching-related methods to [Perfil].
extension PerfilPatterns on Perfil {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Perfil value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Perfil() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Perfil value)  $default,){
final _that = this;
switch (_that) {
case _Perfil():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Perfil value)?  $default,){
final _that = this;
switch (_that) {
case _Perfil() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String nomeCompleto,  String username,  TipoConta tipo,  DateTime criadoEm,  List<Formacao> formacoes,  Vinculo? vinculo,  String? fotoUrl,  String? bio,  String? email,  String? cpf,  String? cnpj,  String? telefone,  DateTime? ativadaEm,  DateTime? alteradoEm)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Perfil() when $default != null:
return $default(_that.id,_that.nomeCompleto,_that.username,_that.tipo,_that.criadoEm,_that.formacoes,_that.vinculo,_that.fotoUrl,_that.bio,_that.email,_that.cpf,_that.cnpj,_that.telefone,_that.ativadaEm,_that.alteradoEm);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String nomeCompleto,  String username,  TipoConta tipo,  DateTime criadoEm,  List<Formacao> formacoes,  Vinculo? vinculo,  String? fotoUrl,  String? bio,  String? email,  String? cpf,  String? cnpj,  String? telefone,  DateTime? ativadaEm,  DateTime? alteradoEm)  $default,) {final _that = this;
switch (_that) {
case _Perfil():
return $default(_that.id,_that.nomeCompleto,_that.username,_that.tipo,_that.criadoEm,_that.formacoes,_that.vinculo,_that.fotoUrl,_that.bio,_that.email,_that.cpf,_that.cnpj,_that.telefone,_that.ativadaEm,_that.alteradoEm);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String nomeCompleto,  String username,  TipoConta tipo,  DateTime criadoEm,  List<Formacao> formacoes,  Vinculo? vinculo,  String? fotoUrl,  String? bio,  String? email,  String? cpf,  String? cnpj,  String? telefone,  DateTime? ativadaEm,  DateTime? alteradoEm)?  $default,) {final _that = this;
switch (_that) {
case _Perfil() when $default != null:
return $default(_that.id,_that.nomeCompleto,_that.username,_that.tipo,_that.criadoEm,_that.formacoes,_that.vinculo,_that.fotoUrl,_that.bio,_that.email,_that.cpf,_that.cnpj,_that.telefone,_that.ativadaEm,_that.alteradoEm);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Perfil implements Perfil {
  const _Perfil({required this.id, required this.nomeCompleto, required this.username, required this.tipo, required this.criadoEm,  List<Formacao> formacoes = const <Formacao>[], this.vinculo, this.fotoUrl, this.bio, this.email, this.cpf, this.cnpj, this.telefone, this.ativadaEm, this.alteradoEm}): _formacoes = formacoes;
  factory _Perfil.fromJson(Map<String, dynamic> json) => _$PerfilFromJson(json);

@override final  String id;
@override final  String nomeCompleto;
@override final  String username;
@override final  TipoConta tipo;
@override final  DateTime criadoEm;
/// O currículo. Pode estar vazio — é o estado de quem acabou de entrar.
 final  List<Formacao> _formacoes;
/// O currículo. Pode estar vazio — é o estado de quem acabou de entrar.
@override@JsonKey() List<Formacao> get formacoes {
  if (_formacoes is EqualUnmodifiableListView) return _formacoes;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_formacoes);
}

/// A instituição atual, quando há. Público de propósito: é o equivalente a
/// "trabalha em" num perfil profissional.
@override final  Vinculo? vinculo;
@override final  String? fotoUrl;
@override final  String? bio;
@override final  String? email;
/// Apenas dígitos. Nulo em conta `faculdade` e `empresa`.
@override final  String? cpf;
/// Apenas dígitos. Nulo em conta de aluno. Uma conta nunca tem os dois.
@override final  String? cnpj;
@override final  String? telefone;
/// Quando a conta passou a poder agir. **Nulo significa pendente**, e só
/// acontece em conta institucional: a de aluno nasce ativa.
@override final  DateTime? ativadaEm;
@override final  DateTime? alteradoEm;

/// Create a copy of Perfil
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PerfilCopyWith<_Perfil> get copyWith => __$PerfilCopyWithImpl<_Perfil>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PerfilToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _Perfil&&(identical(other.id, id) || other.id == id)&&(identical(other.nomeCompleto, nomeCompleto) || other.nomeCompleto == nomeCompleto)&&(identical(other.username, username) || other.username == username)&&(identical(other.tipo, tipo) || other.tipo == tipo)&&(identical(other.criadoEm, criadoEm) || other.criadoEm == criadoEm)&&const DeepCollectionEquality().equals(other.formacoes, _formacoes)&&(identical(other.vinculo, vinculo) || other.vinculo == vinculo)&&(identical(other.fotoUrl, fotoUrl) || other.fotoUrl == fotoUrl)&&(identical(other.bio, bio) || other.bio == bio)&&(identical(other.email, email) || other.email == email)&&(identical(other.cpf, cpf) || other.cpf == cpf)&&(identical(other.cnpj, cnpj) || other.cnpj == cnpj)&&(identical(other.telefone, telefone) || other.telefone == telefone)&&(identical(other.ativadaEm, ativadaEm) || other.ativadaEm == ativadaEm)&&(identical(other.alteradoEm, alteradoEm) || other.alteradoEm == alteradoEm));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,nomeCompleto,username,tipo,criadoEm,const DeepCollectionEquality().hash(_formacoes),vinculo,fotoUrl,bio,email,cpf,cnpj,telefone,ativadaEm,alteradoEm);
}

@override
String toString() {
    return 'Perfil(id: $id, nomeCompleto: $nomeCompleto, username: $username, tipo: $tipo, criadoEm: $criadoEm, formacoes: $formacoes, vinculo: $vinculo, fotoUrl: $fotoUrl, bio: $bio, email: $email, cpf: $cpf, cnpj: $cnpj, telefone: $telefone, ativadaEm: $ativadaEm, alteradoEm: $alteradoEm)';
}


}

/// @nodoc
abstract mixin class _$PerfilCopyWith<$Res> implements $PerfilCopyWith<$Res> {
  factory _$PerfilCopyWith(_Perfil value, $Res Function(_Perfil) _then) = __$PerfilCopyWithImpl;
@override @useResult
$Res call({
 String id, String nomeCompleto, String username, TipoConta tipo, DateTime criadoEm, List<Formacao> formacoes, Vinculo? vinculo, String? fotoUrl, String? bio, String? email, String? cpf, String? cnpj, String? telefone, DateTime? ativadaEm, DateTime? alteradoEm
});


@override $VinculoCopyWith<$Res>? get vinculo;

}
/// @nodoc
class __$PerfilCopyWithImpl<$Res>
    implements _$PerfilCopyWith<$Res> {
  __$PerfilCopyWithImpl(this._self, this._then);

  final _Perfil _self;
  final $Res Function(_Perfil) _then;

/// Create a copy of Perfil
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? nomeCompleto = null,Object? username = null,Object? tipo = null,Object? criadoEm = null,Object? formacoes = null,Object? vinculo = freezed,Object? fotoUrl = freezed,Object? bio = freezed,Object? email = freezed,Object? cpf = freezed,Object? cnpj = freezed,Object? telefone = freezed,Object? ativadaEm = freezed,Object? alteradoEm = freezed,}) {
  return _then(_Perfil(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,nomeCompleto: null == nomeCompleto ? _self.nomeCompleto : nomeCompleto // ignore: cast_nullable_to_non_nullable
as String,username: null == username ? _self.username : username // ignore: cast_nullable_to_non_nullable
as String,tipo: null == tipo ? _self.tipo : tipo // ignore: cast_nullable_to_non_nullable
as TipoConta,criadoEm: null == criadoEm ? _self.criadoEm : criadoEm // ignore: cast_nullable_to_non_nullable
as DateTime,formacoes: null == formacoes ? _self._formacoes : formacoes // ignore: cast_nullable_to_non_nullable
as List<Formacao>,vinculo: freezed == vinculo ? _self.vinculo : vinculo // ignore: cast_nullable_to_non_nullable
as Vinculo?,fotoUrl: freezed == fotoUrl ? _self.fotoUrl : fotoUrl // ignore: cast_nullable_to_non_nullable
as String?,bio: freezed == bio ? _self.bio : bio // ignore: cast_nullable_to_non_nullable
as String?,email: freezed == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String?,cpf: freezed == cpf ? _self.cpf : cpf // ignore: cast_nullable_to_non_nullable
as String?,cnpj: freezed == cnpj ? _self.cnpj : cnpj // ignore: cast_nullable_to_non_nullable
as String?,telefone: freezed == telefone ? _self.telefone : telefone // ignore: cast_nullable_to_non_nullable
as String?,ativadaEm: freezed == ativadaEm ? _self.ativadaEm : ativadaEm // ignore: cast_nullable_to_non_nullable
as DateTime?,alteradoEm: freezed == alteradoEm ? _self.alteradoEm : alteradoEm // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

/// Create a copy of Perfil
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$VinculoCopyWith<$Res>? get vinculo {
    if (_self.vinculo == null) {
    return null;
  }

  return $VinculoCopyWith<$Res>(_self.vinculo!, (value) {
    return _then(_self.copyWith(vinculo: value));
  });
}
}

// dart format on
