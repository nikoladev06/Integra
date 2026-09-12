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

 String get id; String get nome; String get sigla;
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
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Universidade&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.nome, _this.nome) || other.nome == _this.nome)&&(identical(other.sigla, _this.sigla) || other.sigla == _this.sigla));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as Universidade;
  return Object.hash(runtimeType,_this.id,_this.nome,_this.sigla);
}

@override
String toString() {
  final _this = this as Universidade;
  return 'Universidade(id: ${_this.id}, nome: ${_this.nome}, sigla: ${_this.sigla})';
}


}

/// @nodoc
abstract mixin class $UniversidadeCopyWith<$Res>  {
  factory $UniversidadeCopyWith(Universidade value, $Res Function(Universidade) _then) = _$UniversidadeCopyWithImpl;
@useResult
$Res call({
 String id, String nome, String sigla
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
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? nome = null,Object? sigla = null,}) {
  return _then(Universidade(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,nome: null == nome ? _self.nome : nome // ignore: cast_nullable_to_non_nullable
as String,sigla: null == sigla ? _self.sigla : sigla // ignore: cast_nullable_to_non_nullable
as String,
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String nome,  String sigla)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Universidade() when $default != null:
return $default(_that.id,_that.nome,_that.sigla);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String nome,  String sigla)  $default,) {final _that = this;
switch (_that) {
case _Universidade():
return $default(_that.id,_that.nome,_that.sigla);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String nome,  String sigla)?  $default,) {final _that = this;
switch (_that) {
case _Universidade() when $default != null:
return $default(_that.id,_that.nome,_that.sigla);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Universidade implements Universidade {
  const _Universidade({required this.id, required this.nome, required this.sigla});
  factory _Universidade.fromJson(Map<String, dynamic> json) => _$UniversidadeFromJson(json);

@override final  String id;
@override final  String nome;
@override final  String sigla;

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
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _Universidade&&(identical(other.id, id) || other.id == id)&&(identical(other.nome, nome) || other.nome == nome)&&(identical(other.sigla, sigla) || other.sigla == sigla));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,nome,sigla);
}

@override
String toString() {
    return 'Universidade(id: $id, nome: $nome, sigla: $sigla)';
}


}

/// @nodoc
abstract mixin class _$UniversidadeCopyWith<$Res> implements $UniversidadeCopyWith<$Res> {
  factory _$UniversidadeCopyWith(_Universidade value, $Res Function(_Universidade) _then) = __$UniversidadeCopyWithImpl;
@override @useResult
$Res call({
 String id, String nome, String sigla
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
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? nome = null,Object? sigla = null,}) {
  return _then(_Universidade(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,nome: null == nome ? _self.nome : nome // ignore: cast_nullable_to_non_nullable
as String,sigla: null == sigla ? _self.sigla : sigla // ignore: cast_nullable_to_non_nullable
as String,
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
mixin _$Afiliacao {

 Universidade get universidade; Curso get curso;
/// Create a copy of Afiliacao
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AfiliacaoCopyWith<Afiliacao> get copyWith => _$AfiliacaoCopyWithImpl<Afiliacao>(this as Afiliacao, _$identity);

  /// Serializes this Afiliacao to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as Afiliacao;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Afiliacao&&(identical(other.universidade, _this.universidade) || other.universidade == _this.universidade)&&(identical(other.curso, _this.curso) || other.curso == _this.curso));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as Afiliacao;
  return Object.hash(runtimeType,_this.universidade,_this.curso);
}

@override
String toString() {
  final _this = this as Afiliacao;
  return 'Afiliacao(universidade: ${_this.universidade}, curso: ${_this.curso})';
}


}

/// @nodoc
abstract mixin class $AfiliacaoCopyWith<$Res>  {
  factory $AfiliacaoCopyWith(Afiliacao value, $Res Function(Afiliacao) _then) = _$AfiliacaoCopyWithImpl;
@useResult
$Res call({
 Universidade universidade, Curso curso
});


$UniversidadeCopyWith<$Res> get universidade;$CursoCopyWith<$Res> get curso;

}
/// @nodoc
class _$AfiliacaoCopyWithImpl<$Res>
    implements $AfiliacaoCopyWith<$Res> {
  _$AfiliacaoCopyWithImpl(this._self, this._then);

  final Afiliacao _self;
  final $Res Function(Afiliacao) _then;

/// Create a copy of Afiliacao
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? universidade = null,Object? curso = null,}) {
  return _then(Afiliacao(
universidade: null == universidade ? _self.universidade : universidade // ignore: cast_nullable_to_non_nullable
as Universidade,curso: null == curso ? _self.curso : curso // ignore: cast_nullable_to_non_nullable
as Curso,
  ));
}
/// Create a copy of Afiliacao
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$UniversidadeCopyWith<$Res> get universidade {
  
  return $UniversidadeCopyWith<$Res>(_self.universidade, (value) {
    return _then(_self.copyWith(universidade: value));
  });
}/// Create a copy of Afiliacao
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CursoCopyWith<$Res> get curso {
  
  return $CursoCopyWith<$Res>(_self.curso, (value) {
    return _then(_self.copyWith(curso: value));
  });
}
}


/// Adds pattern-matching-related methods to [Afiliacao].
extension AfiliacaoPatterns on Afiliacao {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Afiliacao value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Afiliacao() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Afiliacao value)  $default,){
final _that = this;
switch (_that) {
case _Afiliacao():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Afiliacao value)?  $default,){
final _that = this;
switch (_that) {
case _Afiliacao() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( Universidade universidade,  Curso curso)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Afiliacao() when $default != null:
return $default(_that.universidade,_that.curso);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( Universidade universidade,  Curso curso)  $default,) {final _that = this;
switch (_that) {
case _Afiliacao():
return $default(_that.universidade,_that.curso);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( Universidade universidade,  Curso curso)?  $default,) {final _that = this;
switch (_that) {
case _Afiliacao() when $default != null:
return $default(_that.universidade,_that.curso);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Afiliacao implements Afiliacao {
  const _Afiliacao({required this.universidade, required this.curso});
  factory _Afiliacao.fromJson(Map<String, dynamic> json) => _$AfiliacaoFromJson(json);

@override final  Universidade universidade;
@override final  Curso curso;

/// Create a copy of Afiliacao
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AfiliacaoCopyWith<_Afiliacao> get copyWith => __$AfiliacaoCopyWithImpl<_Afiliacao>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AfiliacaoToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _Afiliacao&&(identical(other.universidade, universidade) || other.universidade == universidade)&&(identical(other.curso, curso) || other.curso == curso));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,universidade,curso);
}

@override
String toString() {
    return 'Afiliacao(universidade: $universidade, curso: $curso)';
}


}

/// @nodoc
abstract mixin class _$AfiliacaoCopyWith<$Res> implements $AfiliacaoCopyWith<$Res> {
  factory _$AfiliacaoCopyWith(_Afiliacao value, $Res Function(_Afiliacao) _then) = __$AfiliacaoCopyWithImpl;
@override @useResult
$Res call({
 Universidade universidade, Curso curso
});


@override $UniversidadeCopyWith<$Res> get universidade;@override $CursoCopyWith<$Res> get curso;

}
/// @nodoc
class __$AfiliacaoCopyWithImpl<$Res>
    implements _$AfiliacaoCopyWith<$Res> {
  __$AfiliacaoCopyWithImpl(this._self, this._then);

  final _Afiliacao _self;
  final $Res Function(_Afiliacao) _then;

/// Create a copy of Afiliacao
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? universidade = null,Object? curso = null,}) {
  return _then(_Afiliacao(
universidade: null == universidade ? _self.universidade : universidade // ignore: cast_nullable_to_non_nullable
as Universidade,curso: null == curso ? _self.curso : curso // ignore: cast_nullable_to_non_nullable
as Curso,
  ));
}

/// Create a copy of Afiliacao
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$UniversidadeCopyWith<$Res> get universidade {
  
  return $UniversidadeCopyWith<$Res>(_self.universidade, (value) {
    return _then(_self.copyWith(universidade: value));
  });
}/// Create a copy of Afiliacao
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

 String get id; String get nomeCompleto; String get username; TipoConta get tipo; Afiliacao get afiliacao; DateTime get criadoEm; String? get fotoUrl; String? get bio; String? get email; String? get telefone; DateTime? get alteradoEm;
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
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Perfil&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.nomeCompleto, _this.nomeCompleto) || other.nomeCompleto == _this.nomeCompleto)&&(identical(other.username, _this.username) || other.username == _this.username)&&(identical(other.tipo, _this.tipo) || other.tipo == _this.tipo)&&(identical(other.afiliacao, _this.afiliacao) || other.afiliacao == _this.afiliacao)&&(identical(other.criadoEm, _this.criadoEm) || other.criadoEm == _this.criadoEm)&&(identical(other.fotoUrl, _this.fotoUrl) || other.fotoUrl == _this.fotoUrl)&&(identical(other.bio, _this.bio) || other.bio == _this.bio)&&(identical(other.email, _this.email) || other.email == _this.email)&&(identical(other.telefone, _this.telefone) || other.telefone == _this.telefone)&&(identical(other.alteradoEm, _this.alteradoEm) || other.alteradoEm == _this.alteradoEm));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as Perfil;
  return Object.hash(runtimeType,_this.id,_this.nomeCompleto,_this.username,_this.tipo,_this.afiliacao,_this.criadoEm,_this.fotoUrl,_this.bio,_this.email,_this.telefone,_this.alteradoEm);
}

@override
String toString() {
  final _this = this as Perfil;
  return 'Perfil(id: ${_this.id}, nomeCompleto: ${_this.nomeCompleto}, username: ${_this.username}, tipo: ${_this.tipo}, afiliacao: ${_this.afiliacao}, criadoEm: ${_this.criadoEm}, fotoUrl: ${_this.fotoUrl}, bio: ${_this.bio}, email: ${_this.email}, telefone: ${_this.telefone}, alteradoEm: ${_this.alteradoEm})';
}


}

/// @nodoc
abstract mixin class $PerfilCopyWith<$Res>  {
  factory $PerfilCopyWith(Perfil value, $Res Function(Perfil) _then) = _$PerfilCopyWithImpl;
@useResult
$Res call({
 String id, String nomeCompleto, String username, TipoConta tipo, Afiliacao afiliacao, DateTime criadoEm, String? fotoUrl, String? bio, String? email, String? telefone, DateTime? alteradoEm
});


$AfiliacaoCopyWith<$Res> get afiliacao;

}
/// @nodoc
class _$PerfilCopyWithImpl<$Res>
    implements $PerfilCopyWith<$Res> {
  _$PerfilCopyWithImpl(this._self, this._then);

  final Perfil _self;
  final $Res Function(Perfil) _then;

/// Create a copy of Perfil
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? nomeCompleto = null,Object? username = null,Object? tipo = null,Object? afiliacao = null,Object? criadoEm = null,Object? fotoUrl = freezed,Object? bio = freezed,Object? email = freezed,Object? telefone = freezed,Object? alteradoEm = freezed,}) {
  return _then(Perfil(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,nomeCompleto: null == nomeCompleto ? _self.nomeCompleto : nomeCompleto // ignore: cast_nullable_to_non_nullable
as String,username: null == username ? _self.username : username // ignore: cast_nullable_to_non_nullable
as String,tipo: null == tipo ? _self.tipo : tipo // ignore: cast_nullable_to_non_nullable
as TipoConta,afiliacao: null == afiliacao ? _self.afiliacao : afiliacao // ignore: cast_nullable_to_non_nullable
as Afiliacao,criadoEm: null == criadoEm ? _self.criadoEm : criadoEm // ignore: cast_nullable_to_non_nullable
as DateTime,fotoUrl: freezed == fotoUrl ? _self.fotoUrl : fotoUrl // ignore: cast_nullable_to_non_nullable
as String?,bio: freezed == bio ? _self.bio : bio // ignore: cast_nullable_to_non_nullable
as String?,email: freezed == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String?,telefone: freezed == telefone ? _self.telefone : telefone // ignore: cast_nullable_to_non_nullable
as String?,alteradoEm: freezed == alteradoEm ? _self.alteradoEm : alteradoEm // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}
/// Create a copy of Perfil
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AfiliacaoCopyWith<$Res> get afiliacao {
  
  return $AfiliacaoCopyWith<$Res>(_self.afiliacao, (value) {
    return _then(_self.copyWith(afiliacao: value));
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String nomeCompleto,  String username,  TipoConta tipo,  Afiliacao afiliacao,  DateTime criadoEm,  String? fotoUrl,  String? bio,  String? email,  String? telefone,  DateTime? alteradoEm)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Perfil() when $default != null:
return $default(_that.id,_that.nomeCompleto,_that.username,_that.tipo,_that.afiliacao,_that.criadoEm,_that.fotoUrl,_that.bio,_that.email,_that.telefone,_that.alteradoEm);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String nomeCompleto,  String username,  TipoConta tipo,  Afiliacao afiliacao,  DateTime criadoEm,  String? fotoUrl,  String? bio,  String? email,  String? telefone,  DateTime? alteradoEm)  $default,) {final _that = this;
switch (_that) {
case _Perfil():
return $default(_that.id,_that.nomeCompleto,_that.username,_that.tipo,_that.afiliacao,_that.criadoEm,_that.fotoUrl,_that.bio,_that.email,_that.telefone,_that.alteradoEm);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String nomeCompleto,  String username,  TipoConta tipo,  Afiliacao afiliacao,  DateTime criadoEm,  String? fotoUrl,  String? bio,  String? email,  String? telefone,  DateTime? alteradoEm)?  $default,) {final _that = this;
switch (_that) {
case _Perfil() when $default != null:
return $default(_that.id,_that.nomeCompleto,_that.username,_that.tipo,_that.afiliacao,_that.criadoEm,_that.fotoUrl,_that.bio,_that.email,_that.telefone,_that.alteradoEm);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Perfil implements Perfil {
  const _Perfil({required this.id, required this.nomeCompleto, required this.username, required this.tipo, required this.afiliacao, required this.criadoEm, this.fotoUrl, this.bio, this.email, this.telefone, this.alteradoEm});
  factory _Perfil.fromJson(Map<String, dynamic> json) => _$PerfilFromJson(json);

@override final  String id;
@override final  String nomeCompleto;
@override final  String username;
@override final  TipoConta tipo;
@override final  Afiliacao afiliacao;
@override final  DateTime criadoEm;
@override final  String? fotoUrl;
@override final  String? bio;
@override final  String? email;
@override final  String? telefone;
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
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _Perfil&&(identical(other.id, id) || other.id == id)&&(identical(other.nomeCompleto, nomeCompleto) || other.nomeCompleto == nomeCompleto)&&(identical(other.username, username) || other.username == username)&&(identical(other.tipo, tipo) || other.tipo == tipo)&&(identical(other.afiliacao, afiliacao) || other.afiliacao == afiliacao)&&(identical(other.criadoEm, criadoEm) || other.criadoEm == criadoEm)&&(identical(other.fotoUrl, fotoUrl) || other.fotoUrl == fotoUrl)&&(identical(other.bio, bio) || other.bio == bio)&&(identical(other.email, email) || other.email == email)&&(identical(other.telefone, telefone) || other.telefone == telefone)&&(identical(other.alteradoEm, alteradoEm) || other.alteradoEm == alteradoEm));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,nomeCompleto,username,tipo,afiliacao,criadoEm,fotoUrl,bio,email,telefone,alteradoEm);
}

@override
String toString() {
    return 'Perfil(id: $id, nomeCompleto: $nomeCompleto, username: $username, tipo: $tipo, afiliacao: $afiliacao, criadoEm: $criadoEm, fotoUrl: $fotoUrl, bio: $bio, email: $email, telefone: $telefone, alteradoEm: $alteradoEm)';
}


}

/// @nodoc
abstract mixin class _$PerfilCopyWith<$Res> implements $PerfilCopyWith<$Res> {
  factory _$PerfilCopyWith(_Perfil value, $Res Function(_Perfil) _then) = __$PerfilCopyWithImpl;
@override @useResult
$Res call({
 String id, String nomeCompleto, String username, TipoConta tipo, Afiliacao afiliacao, DateTime criadoEm, String? fotoUrl, String? bio, String? email, String? telefone, DateTime? alteradoEm
});


@override $AfiliacaoCopyWith<$Res> get afiliacao;

}
/// @nodoc
class __$PerfilCopyWithImpl<$Res>
    implements _$PerfilCopyWith<$Res> {
  __$PerfilCopyWithImpl(this._self, this._then);

  final _Perfil _self;
  final $Res Function(_Perfil) _then;

/// Create a copy of Perfil
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? nomeCompleto = null,Object? username = null,Object? tipo = null,Object? afiliacao = null,Object? criadoEm = null,Object? fotoUrl = freezed,Object? bio = freezed,Object? email = freezed,Object? telefone = freezed,Object? alteradoEm = freezed,}) {
  return _then(_Perfil(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,nomeCompleto: null == nomeCompleto ? _self.nomeCompleto : nomeCompleto // ignore: cast_nullable_to_non_nullable
as String,username: null == username ? _self.username : username // ignore: cast_nullable_to_non_nullable
as String,tipo: null == tipo ? _self.tipo : tipo // ignore: cast_nullable_to_non_nullable
as TipoConta,afiliacao: null == afiliacao ? _self.afiliacao : afiliacao // ignore: cast_nullable_to_non_nullable
as Afiliacao,criadoEm: null == criadoEm ? _self.criadoEm : criadoEm // ignore: cast_nullable_to_non_nullable
as DateTime,fotoUrl: freezed == fotoUrl ? _self.fotoUrl : fotoUrl // ignore: cast_nullable_to_non_nullable
as String?,bio: freezed == bio ? _self.bio : bio // ignore: cast_nullable_to_non_nullable
as String?,email: freezed == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String?,telefone: freezed == telefone ? _self.telefone : telefone // ignore: cast_nullable_to_non_nullable
as String?,alteradoEm: freezed == alteradoEm ? _self.alteradoEm : alteradoEm // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

/// Create a copy of Perfil
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AfiliacaoCopyWith<$Res> get afiliacao {
  
  return $AfiliacaoCopyWith<$Res>(_self.afiliacao, (value) {
    return _then(_self.copyWith(afiliacao: value));
  });
}
}

// dart format on
