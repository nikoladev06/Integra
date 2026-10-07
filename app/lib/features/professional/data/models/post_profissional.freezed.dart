// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'post_profissional.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$AutorDePost {

 String get id; String get nomeCompleto; String get username; TipoDeAutor get tipo; String? get fotoUrl;
/// Create a copy of AutorDePost
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AutorDePostCopyWith<AutorDePost> get copyWith => _$AutorDePostCopyWithImpl<AutorDePost>(this as AutorDePost, _$identity);

  /// Serializes this AutorDePost to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as AutorDePost;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AutorDePost&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.nomeCompleto, _this.nomeCompleto) || other.nomeCompleto == _this.nomeCompleto)&&(identical(other.username, _this.username) || other.username == _this.username)&&(identical(other.tipo, _this.tipo) || other.tipo == _this.tipo)&&(identical(other.fotoUrl, _this.fotoUrl) || other.fotoUrl == _this.fotoUrl));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as AutorDePost;
  return Object.hash(runtimeType,_this.id,_this.nomeCompleto,_this.username,_this.tipo,_this.fotoUrl);
}

@override
String toString() {
  final _this = this as AutorDePost;
  return 'AutorDePost(id: ${_this.id}, nomeCompleto: ${_this.nomeCompleto}, username: ${_this.username}, tipo: ${_this.tipo}, fotoUrl: ${_this.fotoUrl})';
}


}

/// @nodoc
abstract mixin class $AutorDePostCopyWith<$Res>  {
  factory $AutorDePostCopyWith(AutorDePost value, $Res Function(AutorDePost) _then) = _$AutorDePostCopyWithImpl;
@useResult
$Res call({
 String id, String nomeCompleto, String username, TipoDeAutor tipo, String? fotoUrl
});




}
/// @nodoc
class _$AutorDePostCopyWithImpl<$Res>
    implements $AutorDePostCopyWith<$Res> {
  _$AutorDePostCopyWithImpl(this._self, this._then);

  final AutorDePost _self;
  final $Res Function(AutorDePost) _then;

/// Create a copy of AutorDePost
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? nomeCompleto = null,Object? username = null,Object? tipo = null,Object? fotoUrl = freezed,}) {
  return _then(AutorDePost(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,nomeCompleto: null == nomeCompleto ? _self.nomeCompleto : nomeCompleto // ignore: cast_nullable_to_non_nullable
as String,username: null == username ? _self.username : username // ignore: cast_nullable_to_non_nullable
as String,tipo: null == tipo ? _self.tipo : tipo // ignore: cast_nullable_to_non_nullable
as TipoDeAutor,fotoUrl: freezed == fotoUrl ? _self.fotoUrl : fotoUrl // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [AutorDePost].
extension AutorDePostPatterns on AutorDePost {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AutorDePost value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AutorDePost() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AutorDePost value)  $default,){
final _that = this;
switch (_that) {
case _AutorDePost():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AutorDePost value)?  $default,){
final _that = this;
switch (_that) {
case _AutorDePost() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String nomeCompleto,  String username,  TipoDeAutor tipo,  String? fotoUrl)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AutorDePost() when $default != null:
return $default(_that.id,_that.nomeCompleto,_that.username,_that.tipo,_that.fotoUrl);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String nomeCompleto,  String username,  TipoDeAutor tipo,  String? fotoUrl)  $default,) {final _that = this;
switch (_that) {
case _AutorDePost():
return $default(_that.id,_that.nomeCompleto,_that.username,_that.tipo,_that.fotoUrl);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String nomeCompleto,  String username,  TipoDeAutor tipo,  String? fotoUrl)?  $default,) {final _that = this;
switch (_that) {
case _AutorDePost() when $default != null:
return $default(_that.id,_that.nomeCompleto,_that.username,_that.tipo,_that.fotoUrl);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _AutorDePost implements AutorDePost {
  const _AutorDePost({required this.id, required this.nomeCompleto, required this.username, required this.tipo, this.fotoUrl});
  factory _AutorDePost.fromJson(Map<String, dynamic> json) => _$AutorDePostFromJson(json);

@override final  String id;
@override final  String nomeCompleto;
@override final  String username;
@override final  TipoDeAutor tipo;
@override final  String? fotoUrl;

/// Create a copy of AutorDePost
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AutorDePostCopyWith<_AutorDePost> get copyWith => __$AutorDePostCopyWithImpl<_AutorDePost>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AutorDePostToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _AutorDePost&&(identical(other.id, id) || other.id == id)&&(identical(other.nomeCompleto, nomeCompleto) || other.nomeCompleto == nomeCompleto)&&(identical(other.username, username) || other.username == username)&&(identical(other.tipo, tipo) || other.tipo == tipo)&&(identical(other.fotoUrl, fotoUrl) || other.fotoUrl == fotoUrl));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,nomeCompleto,username,tipo,fotoUrl);
}

@override
String toString() {
    return 'AutorDePost(id: $id, nomeCompleto: $nomeCompleto, username: $username, tipo: $tipo, fotoUrl: $fotoUrl)';
}


}

/// @nodoc
abstract mixin class _$AutorDePostCopyWith<$Res> implements $AutorDePostCopyWith<$Res> {
  factory _$AutorDePostCopyWith(_AutorDePost value, $Res Function(_AutorDePost) _then) = __$AutorDePostCopyWithImpl;
@override @useResult
$Res call({
 String id, String nomeCompleto, String username, TipoDeAutor tipo, String? fotoUrl
});




}
/// @nodoc
class __$AutorDePostCopyWithImpl<$Res>
    implements _$AutorDePostCopyWith<$Res> {
  __$AutorDePostCopyWithImpl(this._self, this._then);

  final _AutorDePost _self;
  final $Res Function(_AutorDePost) _then;

/// Create a copy of AutorDePost
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? nomeCompleto = null,Object? username = null,Object? tipo = null,Object? fotoUrl = freezed,}) {
  return _then(_AutorDePost(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,nomeCompleto: null == nomeCompleto ? _self.nomeCompleto : nomeCompleto // ignore: cast_nullable_to_non_nullable
as String,username: null == username ? _self.username : username // ignore: cast_nullable_to_non_nullable
as String,tipo: null == tipo ? _self.tipo : tipo // ignore: cast_nullable_to_non_nullable
as TipoDeAutor,fotoUrl: freezed == fotoUrl ? _self.fotoUrl : fotoUrl // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$PostProfissional {

 String get id; AutorDePost get autor; String get conteudo; DateTime get criadoEm;/// A imagem no storage, enviada pelo cliente antes de publicar. Nula na grande
/// maioria: o card é de texto por padrão.
 String? get imagemUrl;/// Nula fora do feed — ver [OrigemNoFeed].
 OrigemNoFeed? get origem; int get totalDeCurtidas; int get totalDeComentarios;/// Estado **por leitor**, calculado na consulta. O `isLiked` do protótipo fazia
/// a curtida de uma pessoa aparecer para todas.
 bool get curtidoPorMim;/// Se o leitor é o autor. Vem do servidor em vez de a tela comparar ids — e
/// concluir diferente dele num caso de borda.
 bool get podeEditar; DateTime? get editadoEm;
/// Create a copy of PostProfissional
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PostProfissionalCopyWith<PostProfissional> get copyWith => _$PostProfissionalCopyWithImpl<PostProfissional>(this as PostProfissional, _$identity);

  /// Serializes this PostProfissional to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as PostProfissional;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PostProfissional&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.autor, _this.autor) || other.autor == _this.autor)&&(identical(other.conteudo, _this.conteudo) || other.conteudo == _this.conteudo)&&(identical(other.criadoEm, _this.criadoEm) || other.criadoEm == _this.criadoEm)&&(identical(other.imagemUrl, _this.imagemUrl) || other.imagemUrl == _this.imagemUrl)&&(identical(other.origem, _this.origem) || other.origem == _this.origem)&&(identical(other.totalDeCurtidas, _this.totalDeCurtidas) || other.totalDeCurtidas == _this.totalDeCurtidas)&&(identical(other.totalDeComentarios, _this.totalDeComentarios) || other.totalDeComentarios == _this.totalDeComentarios)&&(identical(other.curtidoPorMim, _this.curtidoPorMim) || other.curtidoPorMim == _this.curtidoPorMim)&&(identical(other.podeEditar, _this.podeEditar) || other.podeEditar == _this.podeEditar)&&(identical(other.editadoEm, _this.editadoEm) || other.editadoEm == _this.editadoEm));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as PostProfissional;
  return Object.hash(runtimeType,_this.id,_this.autor,_this.conteudo,_this.criadoEm,_this.imagemUrl,_this.origem,_this.totalDeCurtidas,_this.totalDeComentarios,_this.curtidoPorMim,_this.podeEditar,_this.editadoEm);
}

@override
String toString() {
  final _this = this as PostProfissional;
  return 'PostProfissional(id: ${_this.id}, autor: ${_this.autor}, conteudo: ${_this.conteudo}, criadoEm: ${_this.criadoEm}, imagemUrl: ${_this.imagemUrl}, origem: ${_this.origem}, totalDeCurtidas: ${_this.totalDeCurtidas}, totalDeComentarios: ${_this.totalDeComentarios}, curtidoPorMim: ${_this.curtidoPorMim}, podeEditar: ${_this.podeEditar}, editadoEm: ${_this.editadoEm})';
}


}

/// @nodoc
abstract mixin class $PostProfissionalCopyWith<$Res>  {
  factory $PostProfissionalCopyWith(PostProfissional value, $Res Function(PostProfissional) _then) = _$PostProfissionalCopyWithImpl;
@useResult
$Res call({
 String id, AutorDePost autor, String conteudo, DateTime criadoEm, String? imagemUrl, OrigemNoFeed? origem, int totalDeCurtidas, int totalDeComentarios, bool curtidoPorMim, bool podeEditar, DateTime? editadoEm
});


$AutorDePostCopyWith<$Res> get autor;

}
/// @nodoc
class _$PostProfissionalCopyWithImpl<$Res>
    implements $PostProfissionalCopyWith<$Res> {
  _$PostProfissionalCopyWithImpl(this._self, this._then);

  final PostProfissional _self;
  final $Res Function(PostProfissional) _then;

/// Create a copy of PostProfissional
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? autor = null,Object? conteudo = null,Object? criadoEm = null,Object? imagemUrl = freezed,Object? origem = freezed,Object? totalDeCurtidas = null,Object? totalDeComentarios = null,Object? curtidoPorMim = null,Object? podeEditar = null,Object? editadoEm = freezed,}) {
  return _then(PostProfissional(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,autor: null == autor ? _self.autor : autor // ignore: cast_nullable_to_non_nullable
as AutorDePost,conteudo: null == conteudo ? _self.conteudo : conteudo // ignore: cast_nullable_to_non_nullable
as String,criadoEm: null == criadoEm ? _self.criadoEm : criadoEm // ignore: cast_nullable_to_non_nullable
as DateTime,imagemUrl: freezed == imagemUrl ? _self.imagemUrl : imagemUrl // ignore: cast_nullable_to_non_nullable
as String?,origem: freezed == origem ? _self.origem : origem // ignore: cast_nullable_to_non_nullable
as OrigemNoFeed?,totalDeCurtidas: null == totalDeCurtidas ? _self.totalDeCurtidas : totalDeCurtidas // ignore: cast_nullable_to_non_nullable
as int,totalDeComentarios: null == totalDeComentarios ? _self.totalDeComentarios : totalDeComentarios // ignore: cast_nullable_to_non_nullable
as int,curtidoPorMim: null == curtidoPorMim ? _self.curtidoPorMim : curtidoPorMim // ignore: cast_nullable_to_non_nullable
as bool,podeEditar: null == podeEditar ? _self.podeEditar : podeEditar // ignore: cast_nullable_to_non_nullable
as bool,editadoEm: freezed == editadoEm ? _self.editadoEm : editadoEm // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}
/// Create a copy of PostProfissional
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AutorDePostCopyWith<$Res> get autor {
  
  return $AutorDePostCopyWith<$Res>(_self.autor, (value) {
    return _then(_self.copyWith(autor: value));
  });
}
}


/// Adds pattern-matching-related methods to [PostProfissional].
extension PostProfissionalPatterns on PostProfissional {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PostProfissional value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PostProfissional() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PostProfissional value)  $default,){
final _that = this;
switch (_that) {
case _PostProfissional():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PostProfissional value)?  $default,){
final _that = this;
switch (_that) {
case _PostProfissional() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  AutorDePost autor,  String conteudo,  DateTime criadoEm,  String? imagemUrl,  OrigemNoFeed? origem,  int totalDeCurtidas,  int totalDeComentarios,  bool curtidoPorMim,  bool podeEditar,  DateTime? editadoEm)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PostProfissional() when $default != null:
return $default(_that.id,_that.autor,_that.conteudo,_that.criadoEm,_that.imagemUrl,_that.origem,_that.totalDeCurtidas,_that.totalDeComentarios,_that.curtidoPorMim,_that.podeEditar,_that.editadoEm);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  AutorDePost autor,  String conteudo,  DateTime criadoEm,  String? imagemUrl,  OrigemNoFeed? origem,  int totalDeCurtidas,  int totalDeComentarios,  bool curtidoPorMim,  bool podeEditar,  DateTime? editadoEm)  $default,) {final _that = this;
switch (_that) {
case _PostProfissional():
return $default(_that.id,_that.autor,_that.conteudo,_that.criadoEm,_that.imagemUrl,_that.origem,_that.totalDeCurtidas,_that.totalDeComentarios,_that.curtidoPorMim,_that.podeEditar,_that.editadoEm);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  AutorDePost autor,  String conteudo,  DateTime criadoEm,  String? imagemUrl,  OrigemNoFeed? origem,  int totalDeCurtidas,  int totalDeComentarios,  bool curtidoPorMim,  bool podeEditar,  DateTime? editadoEm)?  $default,) {final _that = this;
switch (_that) {
case _PostProfissional() when $default != null:
return $default(_that.id,_that.autor,_that.conteudo,_that.criadoEm,_that.imagemUrl,_that.origem,_that.totalDeCurtidas,_that.totalDeComentarios,_that.curtidoPorMim,_that.podeEditar,_that.editadoEm);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PostProfissional implements PostProfissional {
  const _PostProfissional({required this.id, required this.autor, required this.conteudo, required this.criadoEm, this.imagemUrl, this.origem, this.totalDeCurtidas = 0, this.totalDeComentarios = 0, this.curtidoPorMim = false, this.podeEditar = false, this.editadoEm});
  factory _PostProfissional.fromJson(Map<String, dynamic> json) => _$PostProfissionalFromJson(json);

@override final  String id;
@override final  AutorDePost autor;
@override final  String conteudo;
@override final  DateTime criadoEm;
/// A imagem no storage, enviada pelo cliente antes de publicar. Nula na grande
/// maioria: o card é de texto por padrão.
@override final  String? imagemUrl;
/// Nula fora do feed — ver [OrigemNoFeed].
@override final  OrigemNoFeed? origem;
@override@JsonKey() final  int totalDeCurtidas;
@override@JsonKey() final  int totalDeComentarios;
/// Estado **por leitor**, calculado na consulta. O `isLiked` do protótipo fazia
/// a curtida de uma pessoa aparecer para todas.
@override@JsonKey() final  bool curtidoPorMim;
/// Se o leitor é o autor. Vem do servidor em vez de a tela comparar ids — e
/// concluir diferente dele num caso de borda.
@override@JsonKey() final  bool podeEditar;
@override final  DateTime? editadoEm;

/// Create a copy of PostProfissional
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PostProfissionalCopyWith<_PostProfissional> get copyWith => __$PostProfissionalCopyWithImpl<_PostProfissional>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PostProfissionalToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _PostProfissional&&(identical(other.id, id) || other.id == id)&&(identical(other.autor, autor) || other.autor == autor)&&(identical(other.conteudo, conteudo) || other.conteudo == conteudo)&&(identical(other.criadoEm, criadoEm) || other.criadoEm == criadoEm)&&(identical(other.imagemUrl, imagemUrl) || other.imagemUrl == imagemUrl)&&(identical(other.origem, origem) || other.origem == origem)&&(identical(other.totalDeCurtidas, totalDeCurtidas) || other.totalDeCurtidas == totalDeCurtidas)&&(identical(other.totalDeComentarios, totalDeComentarios) || other.totalDeComentarios == totalDeComentarios)&&(identical(other.curtidoPorMim, curtidoPorMim) || other.curtidoPorMim == curtidoPorMim)&&(identical(other.podeEditar, podeEditar) || other.podeEditar == podeEditar)&&(identical(other.editadoEm, editadoEm) || other.editadoEm == editadoEm));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,autor,conteudo,criadoEm,imagemUrl,origem,totalDeCurtidas,totalDeComentarios,curtidoPorMim,podeEditar,editadoEm);
}

@override
String toString() {
    return 'PostProfissional(id: $id, autor: $autor, conteudo: $conteudo, criadoEm: $criadoEm, imagemUrl: $imagemUrl, origem: $origem, totalDeCurtidas: $totalDeCurtidas, totalDeComentarios: $totalDeComentarios, curtidoPorMim: $curtidoPorMim, podeEditar: $podeEditar, editadoEm: $editadoEm)';
}


}

/// @nodoc
abstract mixin class _$PostProfissionalCopyWith<$Res> implements $PostProfissionalCopyWith<$Res> {
  factory _$PostProfissionalCopyWith(_PostProfissional value, $Res Function(_PostProfissional) _then) = __$PostProfissionalCopyWithImpl;
@override @useResult
$Res call({
 String id, AutorDePost autor, String conteudo, DateTime criadoEm, String? imagemUrl, OrigemNoFeed? origem, int totalDeCurtidas, int totalDeComentarios, bool curtidoPorMim, bool podeEditar, DateTime? editadoEm
});


@override $AutorDePostCopyWith<$Res> get autor;

}
/// @nodoc
class __$PostProfissionalCopyWithImpl<$Res>
    implements _$PostProfissionalCopyWith<$Res> {
  __$PostProfissionalCopyWithImpl(this._self, this._then);

  final _PostProfissional _self;
  final $Res Function(_PostProfissional) _then;

/// Create a copy of PostProfissional
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? autor = null,Object? conteudo = null,Object? criadoEm = null,Object? imagemUrl = freezed,Object? origem = freezed,Object? totalDeCurtidas = null,Object? totalDeComentarios = null,Object? curtidoPorMim = null,Object? podeEditar = null,Object? editadoEm = freezed,}) {
  return _then(_PostProfissional(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,autor: null == autor ? _self.autor : autor // ignore: cast_nullable_to_non_nullable
as AutorDePost,conteudo: null == conteudo ? _self.conteudo : conteudo // ignore: cast_nullable_to_non_nullable
as String,criadoEm: null == criadoEm ? _self.criadoEm : criadoEm // ignore: cast_nullable_to_non_nullable
as DateTime,imagemUrl: freezed == imagemUrl ? _self.imagemUrl : imagemUrl // ignore: cast_nullable_to_non_nullable
as String?,origem: freezed == origem ? _self.origem : origem // ignore: cast_nullable_to_non_nullable
as OrigemNoFeed?,totalDeCurtidas: null == totalDeCurtidas ? _self.totalDeCurtidas : totalDeCurtidas // ignore: cast_nullable_to_non_nullable
as int,totalDeComentarios: null == totalDeComentarios ? _self.totalDeComentarios : totalDeComentarios // ignore: cast_nullable_to_non_nullable
as int,curtidoPorMim: null == curtidoPorMim ? _self.curtidoPorMim : curtidoPorMim // ignore: cast_nullable_to_non_nullable
as bool,podeEditar: null == podeEditar ? _self.podeEditar : podeEditar // ignore: cast_nullable_to_non_nullable
as bool,editadoEm: freezed == editadoEm ? _self.editadoEm : editadoEm // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

/// Create a copy of PostProfissional
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AutorDePostCopyWith<$Res> get autor {
  
  return $AutorDePostCopyWith<$Res>(_self.autor, (value) {
    return _then(_self.copyWith(autor: value));
  });
}
}


/// @nodoc
mixin _$AutorDeComentarioProfissional {

 String get id; String get nomeCompleto; String get username; String? get fotoUrl;
/// Create a copy of AutorDeComentarioProfissional
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AutorDeComentarioProfissionalCopyWith<AutorDeComentarioProfissional> get copyWith => _$AutorDeComentarioProfissionalCopyWithImpl<AutorDeComentarioProfissional>(this as AutorDeComentarioProfissional, _$identity);

  /// Serializes this AutorDeComentarioProfissional to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as AutorDeComentarioProfissional;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AutorDeComentarioProfissional&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.nomeCompleto, _this.nomeCompleto) || other.nomeCompleto == _this.nomeCompleto)&&(identical(other.username, _this.username) || other.username == _this.username)&&(identical(other.fotoUrl, _this.fotoUrl) || other.fotoUrl == _this.fotoUrl));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as AutorDeComentarioProfissional;
  return Object.hash(runtimeType,_this.id,_this.nomeCompleto,_this.username,_this.fotoUrl);
}

@override
String toString() {
  final _this = this as AutorDeComentarioProfissional;
  return 'AutorDeComentarioProfissional(id: ${_this.id}, nomeCompleto: ${_this.nomeCompleto}, username: ${_this.username}, fotoUrl: ${_this.fotoUrl})';
}


}

/// @nodoc
abstract mixin class $AutorDeComentarioProfissionalCopyWith<$Res>  {
  factory $AutorDeComentarioProfissionalCopyWith(AutorDeComentarioProfissional value, $Res Function(AutorDeComentarioProfissional) _then) = _$AutorDeComentarioProfissionalCopyWithImpl;
@useResult
$Res call({
 String id, String nomeCompleto, String username, String? fotoUrl
});




}
/// @nodoc
class _$AutorDeComentarioProfissionalCopyWithImpl<$Res>
    implements $AutorDeComentarioProfissionalCopyWith<$Res> {
  _$AutorDeComentarioProfissionalCopyWithImpl(this._self, this._then);

  final AutorDeComentarioProfissional _self;
  final $Res Function(AutorDeComentarioProfissional) _then;

/// Create a copy of AutorDeComentarioProfissional
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? nomeCompleto = null,Object? username = null,Object? fotoUrl = freezed,}) {
  return _then(AutorDeComentarioProfissional(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,nomeCompleto: null == nomeCompleto ? _self.nomeCompleto : nomeCompleto // ignore: cast_nullable_to_non_nullable
as String,username: null == username ? _self.username : username // ignore: cast_nullable_to_non_nullable
as String,fotoUrl: freezed == fotoUrl ? _self.fotoUrl : fotoUrl // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [AutorDeComentarioProfissional].
extension AutorDeComentarioProfissionalPatterns on AutorDeComentarioProfissional {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AutorDeComentarioProfissional value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AutorDeComentarioProfissional() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AutorDeComentarioProfissional value)  $default,){
final _that = this;
switch (_that) {
case _AutorDeComentarioProfissional():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AutorDeComentarioProfissional value)?  $default,){
final _that = this;
switch (_that) {
case _AutorDeComentarioProfissional() when $default != null:
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
case _AutorDeComentarioProfissional() when $default != null:
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
case _AutorDeComentarioProfissional():
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
case _AutorDeComentarioProfissional() when $default != null:
return $default(_that.id,_that.nomeCompleto,_that.username,_that.fotoUrl);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _AutorDeComentarioProfissional implements AutorDeComentarioProfissional {
  const _AutorDeComentarioProfissional({required this.id, required this.nomeCompleto, required this.username, this.fotoUrl});
  factory _AutorDeComentarioProfissional.fromJson(Map<String, dynamic> json) => _$AutorDeComentarioProfissionalFromJson(json);

@override final  String id;
@override final  String nomeCompleto;
@override final  String username;
@override final  String? fotoUrl;

/// Create a copy of AutorDeComentarioProfissional
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AutorDeComentarioProfissionalCopyWith<_AutorDeComentarioProfissional> get copyWith => __$AutorDeComentarioProfissionalCopyWithImpl<_AutorDeComentarioProfissional>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AutorDeComentarioProfissionalToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _AutorDeComentarioProfissional&&(identical(other.id, id) || other.id == id)&&(identical(other.nomeCompleto, nomeCompleto) || other.nomeCompleto == nomeCompleto)&&(identical(other.username, username) || other.username == username)&&(identical(other.fotoUrl, fotoUrl) || other.fotoUrl == fotoUrl));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,nomeCompleto,username,fotoUrl);
}

@override
String toString() {
    return 'AutorDeComentarioProfissional(id: $id, nomeCompleto: $nomeCompleto, username: $username, fotoUrl: $fotoUrl)';
}


}

/// @nodoc
abstract mixin class _$AutorDeComentarioProfissionalCopyWith<$Res> implements $AutorDeComentarioProfissionalCopyWith<$Res> {
  factory _$AutorDeComentarioProfissionalCopyWith(_AutorDeComentarioProfissional value, $Res Function(_AutorDeComentarioProfissional) _then) = __$AutorDeComentarioProfissionalCopyWithImpl;
@override @useResult
$Res call({
 String id, String nomeCompleto, String username, String? fotoUrl
});




}
/// @nodoc
class __$AutorDeComentarioProfissionalCopyWithImpl<$Res>
    implements _$AutorDeComentarioProfissionalCopyWith<$Res> {
  __$AutorDeComentarioProfissionalCopyWithImpl(this._self, this._then);

  final _AutorDeComentarioProfissional _self;
  final $Res Function(_AutorDeComentarioProfissional) _then;

/// Create a copy of AutorDeComentarioProfissional
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? nomeCompleto = null,Object? username = null,Object? fotoUrl = freezed,}) {
  return _then(_AutorDeComentarioProfissional(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,nomeCompleto: null == nomeCompleto ? _self.nomeCompleto : nomeCompleto // ignore: cast_nullable_to_non_nullable
as String,username: null == username ? _self.username : username // ignore: cast_nullable_to_non_nullable
as String,fotoUrl: freezed == fotoUrl ? _self.fotoUrl : fotoUrl // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$ComentarioProfissional {

 String get id; String get postId; AutorDeComentarioProfissional get autor; String get conteudo; DateTime get criadoEm;/// Autor do comentário, **ou autor do post** (moderação). No Acadêmico quem
/// modera é a faculdade autora do comunicado; aqui é a pessoa ou empresa que
/// publicou. Vem do servidor: um botão que a tela mostra e o servidor recusa é
/// exatamente o que duas cópias da regra produzem.
 bool get podeRemover;
/// Create a copy of ComentarioProfissional
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ComentarioProfissionalCopyWith<ComentarioProfissional> get copyWith => _$ComentarioProfissionalCopyWithImpl<ComentarioProfissional>(this as ComentarioProfissional, _$identity);

  /// Serializes this ComentarioProfissional to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as ComentarioProfissional;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ComentarioProfissional&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.postId, _this.postId) || other.postId == _this.postId)&&(identical(other.autor, _this.autor) || other.autor == _this.autor)&&(identical(other.conteudo, _this.conteudo) || other.conteudo == _this.conteudo)&&(identical(other.criadoEm, _this.criadoEm) || other.criadoEm == _this.criadoEm)&&(identical(other.podeRemover, _this.podeRemover) || other.podeRemover == _this.podeRemover));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as ComentarioProfissional;
  return Object.hash(runtimeType,_this.id,_this.postId,_this.autor,_this.conteudo,_this.criadoEm,_this.podeRemover);
}

@override
String toString() {
  final _this = this as ComentarioProfissional;
  return 'ComentarioProfissional(id: ${_this.id}, postId: ${_this.postId}, autor: ${_this.autor}, conteudo: ${_this.conteudo}, criadoEm: ${_this.criadoEm}, podeRemover: ${_this.podeRemover})';
}


}

/// @nodoc
abstract mixin class $ComentarioProfissionalCopyWith<$Res>  {
  factory $ComentarioProfissionalCopyWith(ComentarioProfissional value, $Res Function(ComentarioProfissional) _then) = _$ComentarioProfissionalCopyWithImpl;
@useResult
$Res call({
 String id, String postId, AutorDeComentarioProfissional autor, String conteudo, DateTime criadoEm, bool podeRemover
});


$AutorDeComentarioProfissionalCopyWith<$Res> get autor;

}
/// @nodoc
class _$ComentarioProfissionalCopyWithImpl<$Res>
    implements $ComentarioProfissionalCopyWith<$Res> {
  _$ComentarioProfissionalCopyWithImpl(this._self, this._then);

  final ComentarioProfissional _self;
  final $Res Function(ComentarioProfissional) _then;

/// Create a copy of ComentarioProfissional
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? postId = null,Object? autor = null,Object? conteudo = null,Object? criadoEm = null,Object? podeRemover = null,}) {
  return _then(ComentarioProfissional(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,postId: null == postId ? _self.postId : postId // ignore: cast_nullable_to_non_nullable
as String,autor: null == autor ? _self.autor : autor // ignore: cast_nullable_to_non_nullable
as AutorDeComentarioProfissional,conteudo: null == conteudo ? _self.conteudo : conteudo // ignore: cast_nullable_to_non_nullable
as String,criadoEm: null == criadoEm ? _self.criadoEm : criadoEm // ignore: cast_nullable_to_non_nullable
as DateTime,podeRemover: null == podeRemover ? _self.podeRemover : podeRemover // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}
/// Create a copy of ComentarioProfissional
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AutorDeComentarioProfissionalCopyWith<$Res> get autor {
  
  return $AutorDeComentarioProfissionalCopyWith<$Res>(_self.autor, (value) {
    return _then(_self.copyWith(autor: value));
  });
}
}


/// Adds pattern-matching-related methods to [ComentarioProfissional].
extension ComentarioProfissionalPatterns on ComentarioProfissional {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ComentarioProfissional value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ComentarioProfissional() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ComentarioProfissional value)  $default,){
final _that = this;
switch (_that) {
case _ComentarioProfissional():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ComentarioProfissional value)?  $default,){
final _that = this;
switch (_that) {
case _ComentarioProfissional() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String postId,  AutorDeComentarioProfissional autor,  String conteudo,  DateTime criadoEm,  bool podeRemover)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ComentarioProfissional() when $default != null:
return $default(_that.id,_that.postId,_that.autor,_that.conteudo,_that.criadoEm,_that.podeRemover);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String postId,  AutorDeComentarioProfissional autor,  String conteudo,  DateTime criadoEm,  bool podeRemover)  $default,) {final _that = this;
switch (_that) {
case _ComentarioProfissional():
return $default(_that.id,_that.postId,_that.autor,_that.conteudo,_that.criadoEm,_that.podeRemover);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String postId,  AutorDeComentarioProfissional autor,  String conteudo,  DateTime criadoEm,  bool podeRemover)?  $default,) {final _that = this;
switch (_that) {
case _ComentarioProfissional() when $default != null:
return $default(_that.id,_that.postId,_that.autor,_that.conteudo,_that.criadoEm,_that.podeRemover);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ComentarioProfissional implements ComentarioProfissional {
  const _ComentarioProfissional({required this.id, required this.postId, required this.autor, required this.conteudo, required this.criadoEm, this.podeRemover = false});
  factory _ComentarioProfissional.fromJson(Map<String, dynamic> json) => _$ComentarioProfissionalFromJson(json);

@override final  String id;
@override final  String postId;
@override final  AutorDeComentarioProfissional autor;
@override final  String conteudo;
@override final  DateTime criadoEm;
/// Autor do comentário, **ou autor do post** (moderação). No Acadêmico quem
/// modera é a faculdade autora do comunicado; aqui é a pessoa ou empresa que
/// publicou. Vem do servidor: um botão que a tela mostra e o servidor recusa é
/// exatamente o que duas cópias da regra produzem.
@override@JsonKey() final  bool podeRemover;

/// Create a copy of ComentarioProfissional
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ComentarioProfissionalCopyWith<_ComentarioProfissional> get copyWith => __$ComentarioProfissionalCopyWithImpl<_ComentarioProfissional>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ComentarioProfissionalToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _ComentarioProfissional&&(identical(other.id, id) || other.id == id)&&(identical(other.postId, postId) || other.postId == postId)&&(identical(other.autor, autor) || other.autor == autor)&&(identical(other.conteudo, conteudo) || other.conteudo == conteudo)&&(identical(other.criadoEm, criadoEm) || other.criadoEm == criadoEm)&&(identical(other.podeRemover, podeRemover) || other.podeRemover == podeRemover));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,postId,autor,conteudo,criadoEm,podeRemover);
}

@override
String toString() {
    return 'ComentarioProfissional(id: $id, postId: $postId, autor: $autor, conteudo: $conteudo, criadoEm: $criadoEm, podeRemover: $podeRemover)';
}


}

/// @nodoc
abstract mixin class _$ComentarioProfissionalCopyWith<$Res> implements $ComentarioProfissionalCopyWith<$Res> {
  factory _$ComentarioProfissionalCopyWith(_ComentarioProfissional value, $Res Function(_ComentarioProfissional) _then) = __$ComentarioProfissionalCopyWithImpl;
@override @useResult
$Res call({
 String id, String postId, AutorDeComentarioProfissional autor, String conteudo, DateTime criadoEm, bool podeRemover
});


@override $AutorDeComentarioProfissionalCopyWith<$Res> get autor;

}
/// @nodoc
class __$ComentarioProfissionalCopyWithImpl<$Res>
    implements _$ComentarioProfissionalCopyWith<$Res> {
  __$ComentarioProfissionalCopyWithImpl(this._self, this._then);

  final _ComentarioProfissional _self;
  final $Res Function(_ComentarioProfissional) _then;

/// Create a copy of ComentarioProfissional
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? postId = null,Object? autor = null,Object? conteudo = null,Object? criadoEm = null,Object? podeRemover = null,}) {
  return _then(_ComentarioProfissional(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,postId: null == postId ? _self.postId : postId // ignore: cast_nullable_to_non_nullable
as String,autor: null == autor ? _self.autor : autor // ignore: cast_nullable_to_non_nullable
as AutorDeComentarioProfissional,conteudo: null == conteudo ? _self.conteudo : conteudo // ignore: cast_nullable_to_non_nullable
as String,criadoEm: null == criadoEm ? _self.criadoEm : criadoEm // ignore: cast_nullable_to_non_nullable
as DateTime,podeRemover: null == podeRemover ? _self.podeRemover : podeRemover // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

/// Create a copy of ComentarioProfissional
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AutorDeComentarioProfissionalCopyWith<$Res> get autor {
  
  return $AutorDeComentarioProfissionalCopyWith<$Res>(_self.autor, (value) {
    return _then(_self.copyWith(autor: value));
  });
}
}


/// @nodoc
mixin _$PaginaDePostsProfissionais {

 List<PostProfissional> get itens; String? get proximoCursor;
/// Create a copy of PaginaDePostsProfissionais
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PaginaDePostsProfissionaisCopyWith<PaginaDePostsProfissionais> get copyWith => _$PaginaDePostsProfissionaisCopyWithImpl<PaginaDePostsProfissionais>(this as PaginaDePostsProfissionais, _$identity);

  /// Serializes this PaginaDePostsProfissionais to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as PaginaDePostsProfissionais;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PaginaDePostsProfissionais&&const DeepCollectionEquality().equals(other.itens, _this.itens)&&(identical(other.proximoCursor, _this.proximoCursor) || other.proximoCursor == _this.proximoCursor));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as PaginaDePostsProfissionais;
  return Object.hash(runtimeType,const DeepCollectionEquality().hash(_this.itens),_this.proximoCursor);
}

@override
String toString() {
  final _this = this as PaginaDePostsProfissionais;
  return 'PaginaDePostsProfissionais(itens: ${_this.itens}, proximoCursor: ${_this.proximoCursor})';
}


}

/// @nodoc
abstract mixin class $PaginaDePostsProfissionaisCopyWith<$Res>  {
  factory $PaginaDePostsProfissionaisCopyWith(PaginaDePostsProfissionais value, $Res Function(PaginaDePostsProfissionais) _then) = _$PaginaDePostsProfissionaisCopyWithImpl;
@useResult
$Res call({
 List<PostProfissional> itens, String? proximoCursor
});




}
/// @nodoc
class _$PaginaDePostsProfissionaisCopyWithImpl<$Res>
    implements $PaginaDePostsProfissionaisCopyWith<$Res> {
  _$PaginaDePostsProfissionaisCopyWithImpl(this._self, this._then);

  final PaginaDePostsProfissionais _self;
  final $Res Function(PaginaDePostsProfissionais) _then;

/// Create a copy of PaginaDePostsProfissionais
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? itens = null,Object? proximoCursor = freezed,}) {
  return _then(PaginaDePostsProfissionais(
itens: null == itens ? _self.itens : itens // ignore: cast_nullable_to_non_nullable
as List<PostProfissional>,proximoCursor: freezed == proximoCursor ? _self.proximoCursor : proximoCursor // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [PaginaDePostsProfissionais].
extension PaginaDePostsProfissionaisPatterns on PaginaDePostsProfissionais {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PaginaDePostsProfissionais value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PaginaDePostsProfissionais() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PaginaDePostsProfissionais value)  $default,){
final _that = this;
switch (_that) {
case _PaginaDePostsProfissionais():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PaginaDePostsProfissionais value)?  $default,){
final _that = this;
switch (_that) {
case _PaginaDePostsProfissionais() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<PostProfissional> itens,  String? proximoCursor)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PaginaDePostsProfissionais() when $default != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<PostProfissional> itens,  String? proximoCursor)  $default,) {final _that = this;
switch (_that) {
case _PaginaDePostsProfissionais():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<PostProfissional> itens,  String? proximoCursor)?  $default,) {final _that = this;
switch (_that) {
case _PaginaDePostsProfissionais() when $default != null:
return $default(_that.itens,_that.proximoCursor);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PaginaDePostsProfissionais implements PaginaDePostsProfissionais {
  const _PaginaDePostsProfissionais({ List<PostProfissional> itens = const <PostProfissional>[], this.proximoCursor}): _itens = itens;
  factory _PaginaDePostsProfissionais.fromJson(Map<String, dynamic> json) => _$PaginaDePostsProfissionaisFromJson(json);

 final  List<PostProfissional> _itens;
@override@JsonKey() List<PostProfissional> get itens {
  if (_itens is EqualUnmodifiableListView) return _itens;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_itens);
}

@override final  String? proximoCursor;

/// Create a copy of PaginaDePostsProfissionais
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PaginaDePostsProfissionaisCopyWith<_PaginaDePostsProfissionais> get copyWith => __$PaginaDePostsProfissionaisCopyWithImpl<_PaginaDePostsProfissionais>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PaginaDePostsProfissionaisToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _PaginaDePostsProfissionais&&const DeepCollectionEquality().equals(other.itens, _itens)&&(identical(other.proximoCursor, proximoCursor) || other.proximoCursor == proximoCursor));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,const DeepCollectionEquality().hash(_itens),proximoCursor);
}

@override
String toString() {
    return 'PaginaDePostsProfissionais(itens: $itens, proximoCursor: $proximoCursor)';
}


}

/// @nodoc
abstract mixin class _$PaginaDePostsProfissionaisCopyWith<$Res> implements $PaginaDePostsProfissionaisCopyWith<$Res> {
  factory _$PaginaDePostsProfissionaisCopyWith(_PaginaDePostsProfissionais value, $Res Function(_PaginaDePostsProfissionais) _then) = __$PaginaDePostsProfissionaisCopyWithImpl;
@override @useResult
$Res call({
 List<PostProfissional> itens, String? proximoCursor
});




}
/// @nodoc
class __$PaginaDePostsProfissionaisCopyWithImpl<$Res>
    implements _$PaginaDePostsProfissionaisCopyWith<$Res> {
  __$PaginaDePostsProfissionaisCopyWithImpl(this._self, this._then);

  final _PaginaDePostsProfissionais _self;
  final $Res Function(_PaginaDePostsProfissionais) _then;

/// Create a copy of PaginaDePostsProfissionais
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? itens = null,Object? proximoCursor = freezed,}) {
  return _then(_PaginaDePostsProfissionais(
itens: null == itens ? _self._itens : itens // ignore: cast_nullable_to_non_nullable
as List<PostProfissional>,proximoCursor: freezed == proximoCursor ? _self.proximoCursor : proximoCursor // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$PaginaDeComentariosProfissionais {

 List<ComentarioProfissional> get itens; String? get proximoCursor;
/// Create a copy of PaginaDeComentariosProfissionais
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PaginaDeComentariosProfissionaisCopyWith<PaginaDeComentariosProfissionais> get copyWith => _$PaginaDeComentariosProfissionaisCopyWithImpl<PaginaDeComentariosProfissionais>(this as PaginaDeComentariosProfissionais, _$identity);

  /// Serializes this PaginaDeComentariosProfissionais to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as PaginaDeComentariosProfissionais;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PaginaDeComentariosProfissionais&&const DeepCollectionEquality().equals(other.itens, _this.itens)&&(identical(other.proximoCursor, _this.proximoCursor) || other.proximoCursor == _this.proximoCursor));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as PaginaDeComentariosProfissionais;
  return Object.hash(runtimeType,const DeepCollectionEquality().hash(_this.itens),_this.proximoCursor);
}

@override
String toString() {
  final _this = this as PaginaDeComentariosProfissionais;
  return 'PaginaDeComentariosProfissionais(itens: ${_this.itens}, proximoCursor: ${_this.proximoCursor})';
}


}

/// @nodoc
abstract mixin class $PaginaDeComentariosProfissionaisCopyWith<$Res>  {
  factory $PaginaDeComentariosProfissionaisCopyWith(PaginaDeComentariosProfissionais value, $Res Function(PaginaDeComentariosProfissionais) _then) = _$PaginaDeComentariosProfissionaisCopyWithImpl;
@useResult
$Res call({
 List<ComentarioProfissional> itens, String? proximoCursor
});




}
/// @nodoc
class _$PaginaDeComentariosProfissionaisCopyWithImpl<$Res>
    implements $PaginaDeComentariosProfissionaisCopyWith<$Res> {
  _$PaginaDeComentariosProfissionaisCopyWithImpl(this._self, this._then);

  final PaginaDeComentariosProfissionais _self;
  final $Res Function(PaginaDeComentariosProfissionais) _then;

/// Create a copy of PaginaDeComentariosProfissionais
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? itens = null,Object? proximoCursor = freezed,}) {
  return _then(PaginaDeComentariosProfissionais(
itens: null == itens ? _self.itens : itens // ignore: cast_nullable_to_non_nullable
as List<ComentarioProfissional>,proximoCursor: freezed == proximoCursor ? _self.proximoCursor : proximoCursor // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [PaginaDeComentariosProfissionais].
extension PaginaDeComentariosProfissionaisPatterns on PaginaDeComentariosProfissionais {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PaginaDeComentariosProfissionais value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PaginaDeComentariosProfissionais() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PaginaDeComentariosProfissionais value)  $default,){
final _that = this;
switch (_that) {
case _PaginaDeComentariosProfissionais():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PaginaDeComentariosProfissionais value)?  $default,){
final _that = this;
switch (_that) {
case _PaginaDeComentariosProfissionais() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<ComentarioProfissional> itens,  String? proximoCursor)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PaginaDeComentariosProfissionais() when $default != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<ComentarioProfissional> itens,  String? proximoCursor)  $default,) {final _that = this;
switch (_that) {
case _PaginaDeComentariosProfissionais():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<ComentarioProfissional> itens,  String? proximoCursor)?  $default,) {final _that = this;
switch (_that) {
case _PaginaDeComentariosProfissionais() when $default != null:
return $default(_that.itens,_that.proximoCursor);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PaginaDeComentariosProfissionais implements PaginaDeComentariosProfissionais {
  const _PaginaDeComentariosProfissionais({ List<ComentarioProfissional> itens = const <ComentarioProfissional>[], this.proximoCursor}): _itens = itens;
  factory _PaginaDeComentariosProfissionais.fromJson(Map<String, dynamic> json) => _$PaginaDeComentariosProfissionaisFromJson(json);

 final  List<ComentarioProfissional> _itens;
@override@JsonKey() List<ComentarioProfissional> get itens {
  if (_itens is EqualUnmodifiableListView) return _itens;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_itens);
}

@override final  String? proximoCursor;

/// Create a copy of PaginaDeComentariosProfissionais
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PaginaDeComentariosProfissionaisCopyWith<_PaginaDeComentariosProfissionais> get copyWith => __$PaginaDeComentariosProfissionaisCopyWithImpl<_PaginaDeComentariosProfissionais>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PaginaDeComentariosProfissionaisToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _PaginaDeComentariosProfissionais&&const DeepCollectionEquality().equals(other.itens, _itens)&&(identical(other.proximoCursor, proximoCursor) || other.proximoCursor == proximoCursor));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,const DeepCollectionEquality().hash(_itens),proximoCursor);
}

@override
String toString() {
    return 'PaginaDeComentariosProfissionais(itens: $itens, proximoCursor: $proximoCursor)';
}


}

/// @nodoc
abstract mixin class _$PaginaDeComentariosProfissionaisCopyWith<$Res> implements $PaginaDeComentariosProfissionaisCopyWith<$Res> {
  factory _$PaginaDeComentariosProfissionaisCopyWith(_PaginaDeComentariosProfissionais value, $Res Function(_PaginaDeComentariosProfissionais) _then) = __$PaginaDeComentariosProfissionaisCopyWithImpl;
@override @useResult
$Res call({
 List<ComentarioProfissional> itens, String? proximoCursor
});




}
/// @nodoc
class __$PaginaDeComentariosProfissionaisCopyWithImpl<$Res>
    implements _$PaginaDeComentariosProfissionaisCopyWith<$Res> {
  __$PaginaDeComentariosProfissionaisCopyWithImpl(this._self, this._then);

  final _PaginaDeComentariosProfissionais _self;
  final $Res Function(_PaginaDeComentariosProfissionais) _then;

/// Create a copy of PaginaDeComentariosProfissionais
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? itens = null,Object? proximoCursor = freezed,}) {
  return _then(_PaginaDeComentariosProfissionais(
itens: null == itens ? _self._itens : itens // ignore: cast_nullable_to_non_nullable
as List<ComentarioProfissional>,proximoCursor: freezed == proximoCursor ? _self.proximoCursor : proximoCursor // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

/// @nodoc
mixin _$UrlDeUpload {

/// Destino do `PUT`, com assinatura de curta validade. O `PUT` tem que levar
/// exatamente o `Content-Type` e o `Content-Length` declarados ao pedir — os
/// dois entram na assinatura, e é o que faz o limite de tamanho ser do
/// storage e não uma promessa do cliente.
 String get uploadUrl;/// A URL a gravar depois que o `PUT` tiver sucesso.
 String get urlFinal; DateTime get expiraEm;
/// Create a copy of UrlDeUpload
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$UrlDeUploadCopyWith<UrlDeUpload> get copyWith => _$UrlDeUploadCopyWithImpl<UrlDeUpload>(this as UrlDeUpload, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as UrlDeUpload;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UrlDeUpload&&(identical(other.uploadUrl, _this.uploadUrl) || other.uploadUrl == _this.uploadUrl)&&(identical(other.urlFinal, _this.urlFinal) || other.urlFinal == _this.urlFinal)&&(identical(other.expiraEm, _this.expiraEm) || other.expiraEm == _this.expiraEm));
}


@override
int get hashCode {
  final _this = this as UrlDeUpload;
  return Object.hash(runtimeType,_this.uploadUrl,_this.urlFinal,_this.expiraEm);
}

@override
String toString() {
  final _this = this as UrlDeUpload;
  return 'UrlDeUpload(uploadUrl: ${_this.uploadUrl}, urlFinal: ${_this.urlFinal}, expiraEm: ${_this.expiraEm})';
}


}

/// @nodoc
abstract mixin class $UrlDeUploadCopyWith<$Res>  {
  factory $UrlDeUploadCopyWith(UrlDeUpload value, $Res Function(UrlDeUpload) _then) = _$UrlDeUploadCopyWithImpl;
@useResult
$Res call({
 String uploadUrl, String urlFinal, DateTime expiraEm
});




}
/// @nodoc
class _$UrlDeUploadCopyWithImpl<$Res>
    implements $UrlDeUploadCopyWith<$Res> {
  _$UrlDeUploadCopyWithImpl(this._self, this._then);

  final UrlDeUpload _self;
  final $Res Function(UrlDeUpload) _then;

/// Create a copy of UrlDeUpload
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? uploadUrl = null,Object? urlFinal = null,Object? expiraEm = null,}) {
  return _then(UrlDeUpload(
uploadUrl: null == uploadUrl ? _self.uploadUrl : uploadUrl // ignore: cast_nullable_to_non_nullable
as String,urlFinal: null == urlFinal ? _self.urlFinal : urlFinal // ignore: cast_nullable_to_non_nullable
as String,expiraEm: null == expiraEm ? _self.expiraEm : expiraEm // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [UrlDeUpload].
extension UrlDeUploadPatterns on UrlDeUpload {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _UrlDeUpload value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _UrlDeUpload() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _UrlDeUpload value)  $default,){
final _that = this;
switch (_that) {
case _UrlDeUpload():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _UrlDeUpload value)?  $default,){
final _that = this;
switch (_that) {
case _UrlDeUpload() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String uploadUrl,  String urlFinal,  DateTime expiraEm)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _UrlDeUpload() when $default != null:
return $default(_that.uploadUrl,_that.urlFinal,_that.expiraEm);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String uploadUrl,  String urlFinal,  DateTime expiraEm)  $default,) {final _that = this;
switch (_that) {
case _UrlDeUpload():
return $default(_that.uploadUrl,_that.urlFinal,_that.expiraEm);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String uploadUrl,  String urlFinal,  DateTime expiraEm)?  $default,) {final _that = this;
switch (_that) {
case _UrlDeUpload() when $default != null:
return $default(_that.uploadUrl,_that.urlFinal,_that.expiraEm);case _:
  return null;

}
}

}

/// @nodoc


class _UrlDeUpload implements UrlDeUpload {
  const _UrlDeUpload({required this.uploadUrl, required this.urlFinal, required this.expiraEm});
  

/// Destino do `PUT`, com assinatura de curta validade. O `PUT` tem que levar
/// exatamente o `Content-Type` e o `Content-Length` declarados ao pedir — os
/// dois entram na assinatura, e é o que faz o limite de tamanho ser do
/// storage e não uma promessa do cliente.
@override final  String uploadUrl;
/// A URL a gravar depois que o `PUT` tiver sucesso.
@override final  String urlFinal;
@override final  DateTime expiraEm;

/// Create a copy of UrlDeUpload
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$UrlDeUploadCopyWith<_UrlDeUpload> get copyWith => __$UrlDeUploadCopyWithImpl<_UrlDeUpload>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _UrlDeUpload&&(identical(other.uploadUrl, uploadUrl) || other.uploadUrl == uploadUrl)&&(identical(other.urlFinal, urlFinal) || other.urlFinal == urlFinal)&&(identical(other.expiraEm, expiraEm) || other.expiraEm == expiraEm));
}


@override
int get hashCode {
    return Object.hash(runtimeType,uploadUrl,urlFinal,expiraEm);
}

@override
String toString() {
    return 'UrlDeUpload(uploadUrl: $uploadUrl, urlFinal: $urlFinal, expiraEm: $expiraEm)';
}


}

/// @nodoc
abstract mixin class _$UrlDeUploadCopyWith<$Res> implements $UrlDeUploadCopyWith<$Res> {
  factory _$UrlDeUploadCopyWith(_UrlDeUpload value, $Res Function(_UrlDeUpload) _then) = __$UrlDeUploadCopyWithImpl;
@override @useResult
$Res call({
 String uploadUrl, String urlFinal, DateTime expiraEm
});




}
/// @nodoc
class __$UrlDeUploadCopyWithImpl<$Res>
    implements _$UrlDeUploadCopyWith<$Res> {
  __$UrlDeUploadCopyWithImpl(this._self, this._then);

  final _UrlDeUpload _self;
  final $Res Function(_UrlDeUpload) _then;

/// Create a copy of UrlDeUpload
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? uploadUrl = null,Object? urlFinal = null,Object? expiraEm = null,}) {
  return _then(_UrlDeUpload(
uploadUrl: null == uploadUrl ? _self.uploadUrl : uploadUrl // ignore: cast_nullable_to_non_nullable
as String,urlFinal: null == urlFinal ? _self.urlFinal : urlFinal // ignore: cast_nullable_to_non_nullable
as String,expiraEm: null == expiraEm ? _self.expiraEm : expiraEm // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}

// dart format on
