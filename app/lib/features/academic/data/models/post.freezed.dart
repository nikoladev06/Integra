// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'post.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$InstituicaoDoPost {

 String get id; String get nome; String get sigla; String? get fotoUrl;
/// Create a copy of InstituicaoDoPost
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$InstituicaoDoPostCopyWith<InstituicaoDoPost> get copyWith => _$InstituicaoDoPostCopyWithImpl<InstituicaoDoPost>(this as InstituicaoDoPost, _$identity);

  /// Serializes this InstituicaoDoPost to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as InstituicaoDoPost;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is InstituicaoDoPost&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.nome, _this.nome) || other.nome == _this.nome)&&(identical(other.sigla, _this.sigla) || other.sigla == _this.sigla)&&(identical(other.fotoUrl, _this.fotoUrl) || other.fotoUrl == _this.fotoUrl));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as InstituicaoDoPost;
  return Object.hash(runtimeType,_this.id,_this.nome,_this.sigla,_this.fotoUrl);
}

@override
String toString() {
  final _this = this as InstituicaoDoPost;
  return 'InstituicaoDoPost(id: ${_this.id}, nome: ${_this.nome}, sigla: ${_this.sigla}, fotoUrl: ${_this.fotoUrl})';
}


}

/// @nodoc
abstract mixin class $InstituicaoDoPostCopyWith<$Res>  {
  factory $InstituicaoDoPostCopyWith(InstituicaoDoPost value, $Res Function(InstituicaoDoPost) _then) = _$InstituicaoDoPostCopyWithImpl;
@useResult
$Res call({
 String id, String nome, String sigla, String? fotoUrl
});




}
/// @nodoc
class _$InstituicaoDoPostCopyWithImpl<$Res>
    implements $InstituicaoDoPostCopyWith<$Res> {
  _$InstituicaoDoPostCopyWithImpl(this._self, this._then);

  final InstituicaoDoPost _self;
  final $Res Function(InstituicaoDoPost) _then;

/// Create a copy of InstituicaoDoPost
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? nome = null,Object? sigla = null,Object? fotoUrl = freezed,}) {
  return _then(InstituicaoDoPost(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,nome: null == nome ? _self.nome : nome // ignore: cast_nullable_to_non_nullable
as String,sigla: null == sigla ? _self.sigla : sigla // ignore: cast_nullable_to_non_nullable
as String,fotoUrl: freezed == fotoUrl ? _self.fotoUrl : fotoUrl // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [InstituicaoDoPost].
extension InstituicaoDoPostPatterns on InstituicaoDoPost {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _InstituicaoDoPost value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _InstituicaoDoPost() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _InstituicaoDoPost value)  $default,){
final _that = this;
switch (_that) {
case _InstituicaoDoPost():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _InstituicaoDoPost value)?  $default,){
final _that = this;
switch (_that) {
case _InstituicaoDoPost() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String nome,  String sigla,  String? fotoUrl)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _InstituicaoDoPost() when $default != null:
return $default(_that.id,_that.nome,_that.sigla,_that.fotoUrl);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String nome,  String sigla,  String? fotoUrl)  $default,) {final _that = this;
switch (_that) {
case _InstituicaoDoPost():
return $default(_that.id,_that.nome,_that.sigla,_that.fotoUrl);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String nome,  String sigla,  String? fotoUrl)?  $default,) {final _that = this;
switch (_that) {
case _InstituicaoDoPost() when $default != null:
return $default(_that.id,_that.nome,_that.sigla,_that.fotoUrl);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _InstituicaoDoPost implements InstituicaoDoPost {
  const _InstituicaoDoPost({required this.id, required this.nome, required this.sigla, this.fotoUrl});
  factory _InstituicaoDoPost.fromJson(Map<String, dynamic> json) => _$InstituicaoDoPostFromJson(json);

@override final  String id;
@override final  String nome;
@override final  String sigla;
@override final  String? fotoUrl;

/// Create a copy of InstituicaoDoPost
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$InstituicaoDoPostCopyWith<_InstituicaoDoPost> get copyWith => __$InstituicaoDoPostCopyWithImpl<_InstituicaoDoPost>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$InstituicaoDoPostToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _InstituicaoDoPost&&(identical(other.id, id) || other.id == id)&&(identical(other.nome, nome) || other.nome == nome)&&(identical(other.sigla, sigla) || other.sigla == sigla)&&(identical(other.fotoUrl, fotoUrl) || other.fotoUrl == fotoUrl));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,nome,sigla,fotoUrl);
}

@override
String toString() {
    return 'InstituicaoDoPost(id: $id, nome: $nome, sigla: $sigla, fotoUrl: $fotoUrl)';
}


}

/// @nodoc
abstract mixin class _$InstituicaoDoPostCopyWith<$Res> implements $InstituicaoDoPostCopyWith<$Res> {
  factory _$InstituicaoDoPostCopyWith(_InstituicaoDoPost value, $Res Function(_InstituicaoDoPost) _then) = __$InstituicaoDoPostCopyWithImpl;
@override @useResult
$Res call({
 String id, String nome, String sigla, String? fotoUrl
});




}
/// @nodoc
class __$InstituicaoDoPostCopyWithImpl<$Res>
    implements _$InstituicaoDoPostCopyWith<$Res> {
  __$InstituicaoDoPostCopyWithImpl(this._self, this._then);

  final _InstituicaoDoPost _self;
  final $Res Function(_InstituicaoDoPost) _then;

/// Create a copy of InstituicaoDoPost
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? nome = null,Object? sigla = null,Object? fotoUrl = freezed,}) {
  return _then(_InstituicaoDoPost(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,nome: null == nome ? _self.nome : nome // ignore: cast_nullable_to_non_nullable
as String,sigla: null == sigla ? _self.sigla : sigla // ignore: cast_nullable_to_non_nullable
as String,fotoUrl: freezed == fotoUrl ? _self.fotoUrl : fotoUrl // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$Post {

 String get id; InstituicaoDoPost get instituicao; Visibilidade get visibilidade; String get conteudo; DateTime get criadoEm;/// Presente **somente** quando [visibilidade] é [Visibilidade.curso]. A tela
/// mostra o nome ao lado do alcance: o aluno precisa saber que aquilo não é
/// público, e para qual turma foi.
 Curso? get curso; int get totalDeCurtidas; int get totalDeComentarios;/// Estado **por leitor**, calculado na consulta. O protótipo guardava
/// `isLiked` dentro do post, e a curtida de uma pessoa aparecia para todas.
 bool get curtidoPorMim;/// Se o leitor é a conta autora. Vem do servidor em vez de a tela comparar
/// ids — e concluir diferente dele num caso de borda.
 bool get podeEditar;/// Não nulo depois de uma edição. A tela mostra "editado" ao lado da data,
/// porque a faculdade pode mudar até o alcance de um post publicado e quem
/// já leu não é avisado.
 DateTime? get editadoEm;
/// Create a copy of Post
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PostCopyWith<Post> get copyWith => _$PostCopyWithImpl<Post>(this as Post, _$identity);

  /// Serializes this Post to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as Post;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Post&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.instituicao, _this.instituicao) || other.instituicao == _this.instituicao)&&(identical(other.visibilidade, _this.visibilidade) || other.visibilidade == _this.visibilidade)&&(identical(other.conteudo, _this.conteudo) || other.conteudo == _this.conteudo)&&(identical(other.criadoEm, _this.criadoEm) || other.criadoEm == _this.criadoEm)&&(identical(other.curso, _this.curso) || other.curso == _this.curso)&&(identical(other.totalDeCurtidas, _this.totalDeCurtidas) || other.totalDeCurtidas == _this.totalDeCurtidas)&&(identical(other.totalDeComentarios, _this.totalDeComentarios) || other.totalDeComentarios == _this.totalDeComentarios)&&(identical(other.curtidoPorMim, _this.curtidoPorMim) || other.curtidoPorMim == _this.curtidoPorMim)&&(identical(other.podeEditar, _this.podeEditar) || other.podeEditar == _this.podeEditar)&&(identical(other.editadoEm, _this.editadoEm) || other.editadoEm == _this.editadoEm));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as Post;
  return Object.hash(runtimeType,_this.id,_this.instituicao,_this.visibilidade,_this.conteudo,_this.criadoEm,_this.curso,_this.totalDeCurtidas,_this.totalDeComentarios,_this.curtidoPorMim,_this.podeEditar,_this.editadoEm);
}

@override
String toString() {
  final _this = this as Post;
  return 'Post(id: ${_this.id}, instituicao: ${_this.instituicao}, visibilidade: ${_this.visibilidade}, conteudo: ${_this.conteudo}, criadoEm: ${_this.criadoEm}, curso: ${_this.curso}, totalDeCurtidas: ${_this.totalDeCurtidas}, totalDeComentarios: ${_this.totalDeComentarios}, curtidoPorMim: ${_this.curtidoPorMim}, podeEditar: ${_this.podeEditar}, editadoEm: ${_this.editadoEm})';
}


}

/// @nodoc
abstract mixin class $PostCopyWith<$Res>  {
  factory $PostCopyWith(Post value, $Res Function(Post) _then) = _$PostCopyWithImpl;
@useResult
$Res call({
 String id, InstituicaoDoPost instituicao, Visibilidade visibilidade, String conteudo, DateTime criadoEm, Curso? curso, int totalDeCurtidas, int totalDeComentarios, bool curtidoPorMim, bool podeEditar, DateTime? editadoEm
});


$InstituicaoDoPostCopyWith<$Res> get instituicao;$CursoCopyWith<$Res>? get curso;

}
/// @nodoc
class _$PostCopyWithImpl<$Res>
    implements $PostCopyWith<$Res> {
  _$PostCopyWithImpl(this._self, this._then);

  final Post _self;
  final $Res Function(Post) _then;

/// Create a copy of Post
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? instituicao = null,Object? visibilidade = null,Object? conteudo = null,Object? criadoEm = null,Object? curso = freezed,Object? totalDeCurtidas = null,Object? totalDeComentarios = null,Object? curtidoPorMim = null,Object? podeEditar = null,Object? editadoEm = freezed,}) {
  return _then(Post(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,instituicao: null == instituicao ? _self.instituicao : instituicao // ignore: cast_nullable_to_non_nullable
as InstituicaoDoPost,visibilidade: null == visibilidade ? _self.visibilidade : visibilidade // ignore: cast_nullable_to_non_nullable
as Visibilidade,conteudo: null == conteudo ? _self.conteudo : conteudo // ignore: cast_nullable_to_non_nullable
as String,criadoEm: null == criadoEm ? _self.criadoEm : criadoEm // ignore: cast_nullable_to_non_nullable
as DateTime,curso: freezed == curso ? _self.curso : curso // ignore: cast_nullable_to_non_nullable
as Curso?,totalDeCurtidas: null == totalDeCurtidas ? _self.totalDeCurtidas : totalDeCurtidas // ignore: cast_nullable_to_non_nullable
as int,totalDeComentarios: null == totalDeComentarios ? _self.totalDeComentarios : totalDeComentarios // ignore: cast_nullable_to_non_nullable
as int,curtidoPorMim: null == curtidoPorMim ? _self.curtidoPorMim : curtidoPorMim // ignore: cast_nullable_to_non_nullable
as bool,podeEditar: null == podeEditar ? _self.podeEditar : podeEditar // ignore: cast_nullable_to_non_nullable
as bool,editadoEm: freezed == editadoEm ? _self.editadoEm : editadoEm // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}
/// Create a copy of Post
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$InstituicaoDoPostCopyWith<$Res> get instituicao {
  
  return $InstituicaoDoPostCopyWith<$Res>(_self.instituicao, (value) {
    return _then(_self.copyWith(instituicao: value));
  });
}/// Create a copy of Post
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CursoCopyWith<$Res>? get curso {
    if (_self.curso == null) {
    return null;
  }

  return $CursoCopyWith<$Res>(_self.curso!, (value) {
    return _then(_self.copyWith(curso: value));
  });
}
}


/// Adds pattern-matching-related methods to [Post].
extension PostPatterns on Post {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Post value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Post() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Post value)  $default,){
final _that = this;
switch (_that) {
case _Post():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Post value)?  $default,){
final _that = this;
switch (_that) {
case _Post() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  InstituicaoDoPost instituicao,  Visibilidade visibilidade,  String conteudo,  DateTime criadoEm,  Curso? curso,  int totalDeCurtidas,  int totalDeComentarios,  bool curtidoPorMim,  bool podeEditar,  DateTime? editadoEm)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Post() when $default != null:
return $default(_that.id,_that.instituicao,_that.visibilidade,_that.conteudo,_that.criadoEm,_that.curso,_that.totalDeCurtidas,_that.totalDeComentarios,_that.curtidoPorMim,_that.podeEditar,_that.editadoEm);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  InstituicaoDoPost instituicao,  Visibilidade visibilidade,  String conteudo,  DateTime criadoEm,  Curso? curso,  int totalDeCurtidas,  int totalDeComentarios,  bool curtidoPorMim,  bool podeEditar,  DateTime? editadoEm)  $default,) {final _that = this;
switch (_that) {
case _Post():
return $default(_that.id,_that.instituicao,_that.visibilidade,_that.conteudo,_that.criadoEm,_that.curso,_that.totalDeCurtidas,_that.totalDeComentarios,_that.curtidoPorMim,_that.podeEditar,_that.editadoEm);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  InstituicaoDoPost instituicao,  Visibilidade visibilidade,  String conteudo,  DateTime criadoEm,  Curso? curso,  int totalDeCurtidas,  int totalDeComentarios,  bool curtidoPorMim,  bool podeEditar,  DateTime? editadoEm)?  $default,) {final _that = this;
switch (_that) {
case _Post() when $default != null:
return $default(_that.id,_that.instituicao,_that.visibilidade,_that.conteudo,_that.criadoEm,_that.curso,_that.totalDeCurtidas,_that.totalDeComentarios,_that.curtidoPorMim,_that.podeEditar,_that.editadoEm);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Post implements Post {
  const _Post({required this.id, required this.instituicao, required this.visibilidade, required this.conteudo, required this.criadoEm, this.curso, this.totalDeCurtidas = 0, this.totalDeComentarios = 0, this.curtidoPorMim = false, this.podeEditar = false, this.editadoEm});
  factory _Post.fromJson(Map<String, dynamic> json) => _$PostFromJson(json);

@override final  String id;
@override final  InstituicaoDoPost instituicao;
@override final  Visibilidade visibilidade;
@override final  String conteudo;
@override final  DateTime criadoEm;
/// Presente **somente** quando [visibilidade] é [Visibilidade.curso]. A tela
/// mostra o nome ao lado do alcance: o aluno precisa saber que aquilo não é
/// público, e para qual turma foi.
@override final  Curso? curso;
@override@JsonKey() final  int totalDeCurtidas;
@override@JsonKey() final  int totalDeComentarios;
/// Estado **por leitor**, calculado na consulta. O protótipo guardava
/// `isLiked` dentro do post, e a curtida de uma pessoa aparecia para todas.
@override@JsonKey() final  bool curtidoPorMim;
/// Se o leitor é a conta autora. Vem do servidor em vez de a tela comparar
/// ids — e concluir diferente dele num caso de borda.
@override@JsonKey() final  bool podeEditar;
/// Não nulo depois de uma edição. A tela mostra "editado" ao lado da data,
/// porque a faculdade pode mudar até o alcance de um post publicado e quem
/// já leu não é avisado.
@override final  DateTime? editadoEm;

/// Create a copy of Post
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PostCopyWith<_Post> get copyWith => __$PostCopyWithImpl<_Post>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PostToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _Post&&(identical(other.id, id) || other.id == id)&&(identical(other.instituicao, instituicao) || other.instituicao == instituicao)&&(identical(other.visibilidade, visibilidade) || other.visibilidade == visibilidade)&&(identical(other.conteudo, conteudo) || other.conteudo == conteudo)&&(identical(other.criadoEm, criadoEm) || other.criadoEm == criadoEm)&&(identical(other.curso, curso) || other.curso == curso)&&(identical(other.totalDeCurtidas, totalDeCurtidas) || other.totalDeCurtidas == totalDeCurtidas)&&(identical(other.totalDeComentarios, totalDeComentarios) || other.totalDeComentarios == totalDeComentarios)&&(identical(other.curtidoPorMim, curtidoPorMim) || other.curtidoPorMim == curtidoPorMim)&&(identical(other.podeEditar, podeEditar) || other.podeEditar == podeEditar)&&(identical(other.editadoEm, editadoEm) || other.editadoEm == editadoEm));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,instituicao,visibilidade,conteudo,criadoEm,curso,totalDeCurtidas,totalDeComentarios,curtidoPorMim,podeEditar,editadoEm);
}

@override
String toString() {
    return 'Post(id: $id, instituicao: $instituicao, visibilidade: $visibilidade, conteudo: $conteudo, criadoEm: $criadoEm, curso: $curso, totalDeCurtidas: $totalDeCurtidas, totalDeComentarios: $totalDeComentarios, curtidoPorMim: $curtidoPorMim, podeEditar: $podeEditar, editadoEm: $editadoEm)';
}


}

/// @nodoc
abstract mixin class _$PostCopyWith<$Res> implements $PostCopyWith<$Res> {
  factory _$PostCopyWith(_Post value, $Res Function(_Post) _then) = __$PostCopyWithImpl;
@override @useResult
$Res call({
 String id, InstituicaoDoPost instituicao, Visibilidade visibilidade, String conteudo, DateTime criadoEm, Curso? curso, int totalDeCurtidas, int totalDeComentarios, bool curtidoPorMim, bool podeEditar, DateTime? editadoEm
});


@override $InstituicaoDoPostCopyWith<$Res> get instituicao;@override $CursoCopyWith<$Res>? get curso;

}
/// @nodoc
class __$PostCopyWithImpl<$Res>
    implements _$PostCopyWith<$Res> {
  __$PostCopyWithImpl(this._self, this._then);

  final _Post _self;
  final $Res Function(_Post) _then;

/// Create a copy of Post
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? instituicao = null,Object? visibilidade = null,Object? conteudo = null,Object? criadoEm = null,Object? curso = freezed,Object? totalDeCurtidas = null,Object? totalDeComentarios = null,Object? curtidoPorMim = null,Object? podeEditar = null,Object? editadoEm = freezed,}) {
  return _then(_Post(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,instituicao: null == instituicao ? _self.instituicao : instituicao // ignore: cast_nullable_to_non_nullable
as InstituicaoDoPost,visibilidade: null == visibilidade ? _self.visibilidade : visibilidade // ignore: cast_nullable_to_non_nullable
as Visibilidade,conteudo: null == conteudo ? _self.conteudo : conteudo // ignore: cast_nullable_to_non_nullable
as String,criadoEm: null == criadoEm ? _self.criadoEm : criadoEm // ignore: cast_nullable_to_non_nullable
as DateTime,curso: freezed == curso ? _self.curso : curso // ignore: cast_nullable_to_non_nullable
as Curso?,totalDeCurtidas: null == totalDeCurtidas ? _self.totalDeCurtidas : totalDeCurtidas // ignore: cast_nullable_to_non_nullable
as int,totalDeComentarios: null == totalDeComentarios ? _self.totalDeComentarios : totalDeComentarios // ignore: cast_nullable_to_non_nullable
as int,curtidoPorMim: null == curtidoPorMim ? _self.curtidoPorMim : curtidoPorMim // ignore: cast_nullable_to_non_nullable
as bool,podeEditar: null == podeEditar ? _self.podeEditar : podeEditar // ignore: cast_nullable_to_non_nullable
as bool,editadoEm: freezed == editadoEm ? _self.editadoEm : editadoEm // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

/// Create a copy of Post
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$InstituicaoDoPostCopyWith<$Res> get instituicao {
  
  return $InstituicaoDoPostCopyWith<$Res>(_self.instituicao, (value) {
    return _then(_self.copyWith(instituicao: value));
  });
}/// Create a copy of Post
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CursoCopyWith<$Res>? get curso {
    if (_self.curso == null) {
    return null;
  }

  return $CursoCopyWith<$Res>(_self.curso!, (value) {
    return _then(_self.copyWith(curso: value));
  });
}
}


/// @nodoc
mixin _$AutorDeComentario {

 String get id; String get nomeCompleto; String get username; String? get fotoUrl;
/// Create a copy of AutorDeComentario
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AutorDeComentarioCopyWith<AutorDeComentario> get copyWith => _$AutorDeComentarioCopyWithImpl<AutorDeComentario>(this as AutorDeComentario, _$identity);

  /// Serializes this AutorDeComentario to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as AutorDeComentario;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AutorDeComentario&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.nomeCompleto, _this.nomeCompleto) || other.nomeCompleto == _this.nomeCompleto)&&(identical(other.username, _this.username) || other.username == _this.username)&&(identical(other.fotoUrl, _this.fotoUrl) || other.fotoUrl == _this.fotoUrl));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as AutorDeComentario;
  return Object.hash(runtimeType,_this.id,_this.nomeCompleto,_this.username,_this.fotoUrl);
}

@override
String toString() {
  final _this = this as AutorDeComentario;
  return 'AutorDeComentario(id: ${_this.id}, nomeCompleto: ${_this.nomeCompleto}, username: ${_this.username}, fotoUrl: ${_this.fotoUrl})';
}


}

/// @nodoc
abstract mixin class $AutorDeComentarioCopyWith<$Res>  {
  factory $AutorDeComentarioCopyWith(AutorDeComentario value, $Res Function(AutorDeComentario) _then) = _$AutorDeComentarioCopyWithImpl;
@useResult
$Res call({
 String id, String nomeCompleto, String username, String? fotoUrl
});




}
/// @nodoc
class _$AutorDeComentarioCopyWithImpl<$Res>
    implements $AutorDeComentarioCopyWith<$Res> {
  _$AutorDeComentarioCopyWithImpl(this._self, this._then);

  final AutorDeComentario _self;
  final $Res Function(AutorDeComentario) _then;

/// Create a copy of AutorDeComentario
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? nomeCompleto = null,Object? username = null,Object? fotoUrl = freezed,}) {
  return _then(AutorDeComentario(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,nomeCompleto: null == nomeCompleto ? _self.nomeCompleto : nomeCompleto // ignore: cast_nullable_to_non_nullable
as String,username: null == username ? _self.username : username // ignore: cast_nullable_to_non_nullable
as String,fotoUrl: freezed == fotoUrl ? _self.fotoUrl : fotoUrl // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [AutorDeComentario].
extension AutorDeComentarioPatterns on AutorDeComentario {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AutorDeComentario value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AutorDeComentario() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AutorDeComentario value)  $default,){
final _that = this;
switch (_that) {
case _AutorDeComentario():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AutorDeComentario value)?  $default,){
final _that = this;
switch (_that) {
case _AutorDeComentario() when $default != null:
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
case _AutorDeComentario() when $default != null:
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
case _AutorDeComentario():
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
case _AutorDeComentario() when $default != null:
return $default(_that.id,_that.nomeCompleto,_that.username,_that.fotoUrl);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _AutorDeComentario implements AutorDeComentario {
  const _AutorDeComentario({required this.id, required this.nomeCompleto, required this.username, this.fotoUrl});
  factory _AutorDeComentario.fromJson(Map<String, dynamic> json) => _$AutorDeComentarioFromJson(json);

@override final  String id;
@override final  String nomeCompleto;
@override final  String username;
@override final  String? fotoUrl;

/// Create a copy of AutorDeComentario
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AutorDeComentarioCopyWith<_AutorDeComentario> get copyWith => __$AutorDeComentarioCopyWithImpl<_AutorDeComentario>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AutorDeComentarioToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _AutorDeComentario&&(identical(other.id, id) || other.id == id)&&(identical(other.nomeCompleto, nomeCompleto) || other.nomeCompleto == nomeCompleto)&&(identical(other.username, username) || other.username == username)&&(identical(other.fotoUrl, fotoUrl) || other.fotoUrl == fotoUrl));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,nomeCompleto,username,fotoUrl);
}

@override
String toString() {
    return 'AutorDeComentario(id: $id, nomeCompleto: $nomeCompleto, username: $username, fotoUrl: $fotoUrl)';
}


}

/// @nodoc
abstract mixin class _$AutorDeComentarioCopyWith<$Res> implements $AutorDeComentarioCopyWith<$Res> {
  factory _$AutorDeComentarioCopyWith(_AutorDeComentario value, $Res Function(_AutorDeComentario) _then) = __$AutorDeComentarioCopyWithImpl;
@override @useResult
$Res call({
 String id, String nomeCompleto, String username, String? fotoUrl
});




}
/// @nodoc
class __$AutorDeComentarioCopyWithImpl<$Res>
    implements _$AutorDeComentarioCopyWith<$Res> {
  __$AutorDeComentarioCopyWithImpl(this._self, this._then);

  final _AutorDeComentario _self;
  final $Res Function(_AutorDeComentario) _then;

/// Create a copy of AutorDeComentario
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? nomeCompleto = null,Object? username = null,Object? fotoUrl = freezed,}) {
  return _then(_AutorDeComentario(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,nomeCompleto: null == nomeCompleto ? _self.nomeCompleto : nomeCompleto // ignore: cast_nullable_to_non_nullable
as String,username: null == username ? _self.username : username // ignore: cast_nullable_to_non_nullable
as String,fotoUrl: freezed == fotoUrl ? _self.fotoUrl : fotoUrl // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$Comentario {

 String get id; String get postId; AutorDeComentario get autor; String get conteudo; DateTime get criadoEm;/// Autor do comentário, ou a faculdade autora do post (moderação). Vem do
/// servidor: um botão que a tela decide mostrar e o servidor recusa é
/// exatamente o que duas cópias da regra produzem.
 bool get podeRemover;
/// Create a copy of Comentario
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ComentarioCopyWith<Comentario> get copyWith => _$ComentarioCopyWithImpl<Comentario>(this as Comentario, _$identity);

  /// Serializes this Comentario to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as Comentario;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Comentario&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.postId, _this.postId) || other.postId == _this.postId)&&(identical(other.autor, _this.autor) || other.autor == _this.autor)&&(identical(other.conteudo, _this.conteudo) || other.conteudo == _this.conteudo)&&(identical(other.criadoEm, _this.criadoEm) || other.criadoEm == _this.criadoEm)&&(identical(other.podeRemover, _this.podeRemover) || other.podeRemover == _this.podeRemover));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as Comentario;
  return Object.hash(runtimeType,_this.id,_this.postId,_this.autor,_this.conteudo,_this.criadoEm,_this.podeRemover);
}

@override
String toString() {
  final _this = this as Comentario;
  return 'Comentario(id: ${_this.id}, postId: ${_this.postId}, autor: ${_this.autor}, conteudo: ${_this.conteudo}, criadoEm: ${_this.criadoEm}, podeRemover: ${_this.podeRemover})';
}


}

/// @nodoc
abstract mixin class $ComentarioCopyWith<$Res>  {
  factory $ComentarioCopyWith(Comentario value, $Res Function(Comentario) _then) = _$ComentarioCopyWithImpl;
@useResult
$Res call({
 String id, String postId, AutorDeComentario autor, String conteudo, DateTime criadoEm, bool podeRemover
});


$AutorDeComentarioCopyWith<$Res> get autor;

}
/// @nodoc
class _$ComentarioCopyWithImpl<$Res>
    implements $ComentarioCopyWith<$Res> {
  _$ComentarioCopyWithImpl(this._self, this._then);

  final Comentario _self;
  final $Res Function(Comentario) _then;

/// Create a copy of Comentario
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? postId = null,Object? autor = null,Object? conteudo = null,Object? criadoEm = null,Object? podeRemover = null,}) {
  return _then(Comentario(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,postId: null == postId ? _self.postId : postId // ignore: cast_nullable_to_non_nullable
as String,autor: null == autor ? _self.autor : autor // ignore: cast_nullable_to_non_nullable
as AutorDeComentario,conteudo: null == conteudo ? _self.conteudo : conteudo // ignore: cast_nullable_to_non_nullable
as String,criadoEm: null == criadoEm ? _self.criadoEm : criadoEm // ignore: cast_nullable_to_non_nullable
as DateTime,podeRemover: null == podeRemover ? _self.podeRemover : podeRemover // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}
/// Create a copy of Comentario
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AutorDeComentarioCopyWith<$Res> get autor {
  
  return $AutorDeComentarioCopyWith<$Res>(_self.autor, (value) {
    return _then(_self.copyWith(autor: value));
  });
}
}


/// Adds pattern-matching-related methods to [Comentario].
extension ComentarioPatterns on Comentario {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Comentario value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Comentario() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Comentario value)  $default,){
final _that = this;
switch (_that) {
case _Comentario():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Comentario value)?  $default,){
final _that = this;
switch (_that) {
case _Comentario() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String postId,  AutorDeComentario autor,  String conteudo,  DateTime criadoEm,  bool podeRemover)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Comentario() when $default != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String postId,  AutorDeComentario autor,  String conteudo,  DateTime criadoEm,  bool podeRemover)  $default,) {final _that = this;
switch (_that) {
case _Comentario():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String postId,  AutorDeComentario autor,  String conteudo,  DateTime criadoEm,  bool podeRemover)?  $default,) {final _that = this;
switch (_that) {
case _Comentario() when $default != null:
return $default(_that.id,_that.postId,_that.autor,_that.conteudo,_that.criadoEm,_that.podeRemover);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Comentario implements Comentario {
  const _Comentario({required this.id, required this.postId, required this.autor, required this.conteudo, required this.criadoEm, this.podeRemover = false});
  factory _Comentario.fromJson(Map<String, dynamic> json) => _$ComentarioFromJson(json);

@override final  String id;
@override final  String postId;
@override final  AutorDeComentario autor;
@override final  String conteudo;
@override final  DateTime criadoEm;
/// Autor do comentário, ou a faculdade autora do post (moderação). Vem do
/// servidor: um botão que a tela decide mostrar e o servidor recusa é
/// exatamente o que duas cópias da regra produzem.
@override@JsonKey() final  bool podeRemover;

/// Create a copy of Comentario
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ComentarioCopyWith<_Comentario> get copyWith => __$ComentarioCopyWithImpl<_Comentario>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ComentarioToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _Comentario&&(identical(other.id, id) || other.id == id)&&(identical(other.postId, postId) || other.postId == postId)&&(identical(other.autor, autor) || other.autor == autor)&&(identical(other.conteudo, conteudo) || other.conteudo == conteudo)&&(identical(other.criadoEm, criadoEm) || other.criadoEm == criadoEm)&&(identical(other.podeRemover, podeRemover) || other.podeRemover == podeRemover));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,postId,autor,conteudo,criadoEm,podeRemover);
}

@override
String toString() {
    return 'Comentario(id: $id, postId: $postId, autor: $autor, conteudo: $conteudo, criadoEm: $criadoEm, podeRemover: $podeRemover)';
}


}

/// @nodoc
abstract mixin class _$ComentarioCopyWith<$Res> implements $ComentarioCopyWith<$Res> {
  factory _$ComentarioCopyWith(_Comentario value, $Res Function(_Comentario) _then) = __$ComentarioCopyWithImpl;
@override @useResult
$Res call({
 String id, String postId, AutorDeComentario autor, String conteudo, DateTime criadoEm, bool podeRemover
});


@override $AutorDeComentarioCopyWith<$Res> get autor;

}
/// @nodoc
class __$ComentarioCopyWithImpl<$Res>
    implements _$ComentarioCopyWith<$Res> {
  __$ComentarioCopyWithImpl(this._self, this._then);

  final _Comentario _self;
  final $Res Function(_Comentario) _then;

/// Create a copy of Comentario
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? postId = null,Object? autor = null,Object? conteudo = null,Object? criadoEm = null,Object? podeRemover = null,}) {
  return _then(_Comentario(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,postId: null == postId ? _self.postId : postId // ignore: cast_nullable_to_non_nullable
as String,autor: null == autor ? _self.autor : autor // ignore: cast_nullable_to_non_nullable
as AutorDeComentario,conteudo: null == conteudo ? _self.conteudo : conteudo // ignore: cast_nullable_to_non_nullable
as String,criadoEm: null == criadoEm ? _self.criadoEm : criadoEm // ignore: cast_nullable_to_non_nullable
as DateTime,podeRemover: null == podeRemover ? _self.podeRemover : podeRemover // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

/// Create a copy of Comentario
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AutorDeComentarioCopyWith<$Res> get autor {
  
  return $AutorDeComentarioCopyWith<$Res>(_self.autor, (value) {
    return _then(_self.copyWith(autor: value));
  });
}
}


/// @nodoc
mixin _$PaginaDePosts {

 List<Post> get itens; String? get proximoCursor;
/// Create a copy of PaginaDePosts
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PaginaDePostsCopyWith<PaginaDePosts> get copyWith => _$PaginaDePostsCopyWithImpl<PaginaDePosts>(this as PaginaDePosts, _$identity);

  /// Serializes this PaginaDePosts to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as PaginaDePosts;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PaginaDePosts&&const DeepCollectionEquality().equals(other.itens, _this.itens)&&(identical(other.proximoCursor, _this.proximoCursor) || other.proximoCursor == _this.proximoCursor));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as PaginaDePosts;
  return Object.hash(runtimeType,const DeepCollectionEquality().hash(_this.itens),_this.proximoCursor);
}

@override
String toString() {
  final _this = this as PaginaDePosts;
  return 'PaginaDePosts(itens: ${_this.itens}, proximoCursor: ${_this.proximoCursor})';
}


}

/// @nodoc
abstract mixin class $PaginaDePostsCopyWith<$Res>  {
  factory $PaginaDePostsCopyWith(PaginaDePosts value, $Res Function(PaginaDePosts) _then) = _$PaginaDePostsCopyWithImpl;
@useResult
$Res call({
 List<Post> itens, String? proximoCursor
});




}
/// @nodoc
class _$PaginaDePostsCopyWithImpl<$Res>
    implements $PaginaDePostsCopyWith<$Res> {
  _$PaginaDePostsCopyWithImpl(this._self, this._then);

  final PaginaDePosts _self;
  final $Res Function(PaginaDePosts) _then;

/// Create a copy of PaginaDePosts
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? itens = null,Object? proximoCursor = freezed,}) {
  return _then(PaginaDePosts(
itens: null == itens ? _self.itens : itens // ignore: cast_nullable_to_non_nullable
as List<Post>,proximoCursor: freezed == proximoCursor ? _self.proximoCursor : proximoCursor // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [PaginaDePosts].
extension PaginaDePostsPatterns on PaginaDePosts {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PaginaDePosts value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PaginaDePosts() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PaginaDePosts value)  $default,){
final _that = this;
switch (_that) {
case _PaginaDePosts():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PaginaDePosts value)?  $default,){
final _that = this;
switch (_that) {
case _PaginaDePosts() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<Post> itens,  String? proximoCursor)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PaginaDePosts() when $default != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<Post> itens,  String? proximoCursor)  $default,) {final _that = this;
switch (_that) {
case _PaginaDePosts():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<Post> itens,  String? proximoCursor)?  $default,) {final _that = this;
switch (_that) {
case _PaginaDePosts() when $default != null:
return $default(_that.itens,_that.proximoCursor);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PaginaDePosts implements PaginaDePosts {
  const _PaginaDePosts({ List<Post> itens = const <Post>[], this.proximoCursor}): _itens = itens;
  factory _PaginaDePosts.fromJson(Map<String, dynamic> json) => _$PaginaDePostsFromJson(json);

 final  List<Post> _itens;
@override@JsonKey() List<Post> get itens {
  if (_itens is EqualUnmodifiableListView) return _itens;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_itens);
}

@override final  String? proximoCursor;

/// Create a copy of PaginaDePosts
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PaginaDePostsCopyWith<_PaginaDePosts> get copyWith => __$PaginaDePostsCopyWithImpl<_PaginaDePosts>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PaginaDePostsToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _PaginaDePosts&&const DeepCollectionEquality().equals(other.itens, _itens)&&(identical(other.proximoCursor, proximoCursor) || other.proximoCursor == proximoCursor));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,const DeepCollectionEquality().hash(_itens),proximoCursor);
}

@override
String toString() {
    return 'PaginaDePosts(itens: $itens, proximoCursor: $proximoCursor)';
}


}

/// @nodoc
abstract mixin class _$PaginaDePostsCopyWith<$Res> implements $PaginaDePostsCopyWith<$Res> {
  factory _$PaginaDePostsCopyWith(_PaginaDePosts value, $Res Function(_PaginaDePosts) _then) = __$PaginaDePostsCopyWithImpl;
@override @useResult
$Res call({
 List<Post> itens, String? proximoCursor
});




}
/// @nodoc
class __$PaginaDePostsCopyWithImpl<$Res>
    implements _$PaginaDePostsCopyWith<$Res> {
  __$PaginaDePostsCopyWithImpl(this._self, this._then);

  final _PaginaDePosts _self;
  final $Res Function(_PaginaDePosts) _then;

/// Create a copy of PaginaDePosts
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? itens = null,Object? proximoCursor = freezed,}) {
  return _then(_PaginaDePosts(
itens: null == itens ? _self._itens : itens // ignore: cast_nullable_to_non_nullable
as List<Post>,proximoCursor: freezed == proximoCursor ? _self.proximoCursor : proximoCursor // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$PaginaDeComentarios {

 List<Comentario> get itens; String? get proximoCursor;
/// Create a copy of PaginaDeComentarios
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PaginaDeComentariosCopyWith<PaginaDeComentarios> get copyWith => _$PaginaDeComentariosCopyWithImpl<PaginaDeComentarios>(this as PaginaDeComentarios, _$identity);

  /// Serializes this PaginaDeComentarios to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as PaginaDeComentarios;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PaginaDeComentarios&&const DeepCollectionEquality().equals(other.itens, _this.itens)&&(identical(other.proximoCursor, _this.proximoCursor) || other.proximoCursor == _this.proximoCursor));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as PaginaDeComentarios;
  return Object.hash(runtimeType,const DeepCollectionEquality().hash(_this.itens),_this.proximoCursor);
}

@override
String toString() {
  final _this = this as PaginaDeComentarios;
  return 'PaginaDeComentarios(itens: ${_this.itens}, proximoCursor: ${_this.proximoCursor})';
}


}

/// @nodoc
abstract mixin class $PaginaDeComentariosCopyWith<$Res>  {
  factory $PaginaDeComentariosCopyWith(PaginaDeComentarios value, $Res Function(PaginaDeComentarios) _then) = _$PaginaDeComentariosCopyWithImpl;
@useResult
$Res call({
 List<Comentario> itens, String? proximoCursor
});




}
/// @nodoc
class _$PaginaDeComentariosCopyWithImpl<$Res>
    implements $PaginaDeComentariosCopyWith<$Res> {
  _$PaginaDeComentariosCopyWithImpl(this._self, this._then);

  final PaginaDeComentarios _self;
  final $Res Function(PaginaDeComentarios) _then;

/// Create a copy of PaginaDeComentarios
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? itens = null,Object? proximoCursor = freezed,}) {
  return _then(PaginaDeComentarios(
itens: null == itens ? _self.itens : itens // ignore: cast_nullable_to_non_nullable
as List<Comentario>,proximoCursor: freezed == proximoCursor ? _self.proximoCursor : proximoCursor // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [PaginaDeComentarios].
extension PaginaDeComentariosPatterns on PaginaDeComentarios {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PaginaDeComentarios value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PaginaDeComentarios() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PaginaDeComentarios value)  $default,){
final _that = this;
switch (_that) {
case _PaginaDeComentarios():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PaginaDeComentarios value)?  $default,){
final _that = this;
switch (_that) {
case _PaginaDeComentarios() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<Comentario> itens,  String? proximoCursor)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PaginaDeComentarios() when $default != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<Comentario> itens,  String? proximoCursor)  $default,) {final _that = this;
switch (_that) {
case _PaginaDeComentarios():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<Comentario> itens,  String? proximoCursor)?  $default,) {final _that = this;
switch (_that) {
case _PaginaDeComentarios() when $default != null:
return $default(_that.itens,_that.proximoCursor);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PaginaDeComentarios implements PaginaDeComentarios {
  const _PaginaDeComentarios({ List<Comentario> itens = const <Comentario>[], this.proximoCursor}): _itens = itens;
  factory _PaginaDeComentarios.fromJson(Map<String, dynamic> json) => _$PaginaDeComentariosFromJson(json);

 final  List<Comentario> _itens;
@override@JsonKey() List<Comentario> get itens {
  if (_itens is EqualUnmodifiableListView) return _itens;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_itens);
}

@override final  String? proximoCursor;

/// Create a copy of PaginaDeComentarios
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PaginaDeComentariosCopyWith<_PaginaDeComentarios> get copyWith => __$PaginaDeComentariosCopyWithImpl<_PaginaDeComentarios>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PaginaDeComentariosToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _PaginaDeComentarios&&const DeepCollectionEquality().equals(other.itens, _itens)&&(identical(other.proximoCursor, proximoCursor) || other.proximoCursor == proximoCursor));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,const DeepCollectionEquality().hash(_itens),proximoCursor);
}

@override
String toString() {
    return 'PaginaDeComentarios(itens: $itens, proximoCursor: $proximoCursor)';
}


}

/// @nodoc
abstract mixin class _$PaginaDeComentariosCopyWith<$Res> implements $PaginaDeComentariosCopyWith<$Res> {
  factory _$PaginaDeComentariosCopyWith(_PaginaDeComentarios value, $Res Function(_PaginaDeComentarios) _then) = __$PaginaDeComentariosCopyWithImpl;
@override @useResult
$Res call({
 List<Comentario> itens, String? proximoCursor
});




}
/// @nodoc
class __$PaginaDeComentariosCopyWithImpl<$Res>
    implements _$PaginaDeComentariosCopyWith<$Res> {
  __$PaginaDeComentariosCopyWithImpl(this._self, this._then);

  final _PaginaDeComentarios _self;
  final $Res Function(_PaginaDeComentarios) _then;

/// Create a copy of PaginaDeComentarios
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? itens = null,Object? proximoCursor = freezed,}) {
  return _then(_PaginaDeComentarios(
itens: null == itens ? _self._itens : itens // ignore: cast_nullable_to_non_nullable
as List<Comentario>,proximoCursor: freezed == proximoCursor ? _self.proximoCursor : proximoCursor // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
