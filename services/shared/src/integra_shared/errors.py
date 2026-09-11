"""Formato de erro único, igual ao dos contratos em `contracts/`.

O FastAPI responde 422 no formato dele (`{"detail": [...]}`), que não é o que os
contratos declaram e não é o que o cliente Flutter sabe ler. Os handlers aqui
traduzem tudo para `{code, message, fields}`.

`fields` carrega mensagens em português exibíveis direto na tela — as mesmas de
`app/lib/features/auth/domain/auth_validators.dart`. É isso que faz o contrato ser
verdade e não intenção: se o serviço respondesse em inglês, o cliente teria que
manter um segundo conjunto de mensagens e os dois divergiriam na primeira mudança.
"""

from fastapi import FastAPI, Request, status
from fastapi.exceptions import RequestValidationError
from fastapi.responses import JSONResponse
from pydantic import BaseModel, Field
from starlette.exceptions import HTTPException as StarletteHTTPException


class ErrorResponse(BaseModel):
    """Corpo de erro de toda a API. Espelha `components.schemas.Error` nos contratos."""

    code: str = Field(description="Identificador estável para o cliente ramificar.")
    message: str = Field(description="Mensagem em português, exibível ao usuário.")
    fields: dict[str, list[str]] | None = None


class AppError(Exception):
    """Erro de negócio com código e status próprios.

    Levantar isto, em vez de `HTTPException`, mantém o corpo no formato do contrato
    sem cada rota ter que montá-lo à mão.
    """

    def __init__(
        self,
        code: str,
        message: str,
        status_code: int = status.HTTP_400_BAD_REQUEST,
        fields: dict[str, list[str]] | None = None,
    ) -> None:
        super().__init__(message)
        self.code = code
        self.message = message
        self.status_code = status_code
        self.fields = fields


# Traduções dos erros estruturais do Pydantic. Regras de negócio (comprimento de
# senha, formato de telefone) não passam por aqui: elas moram nos validadores de
# cada serviço, que já levantam AppError com a mensagem exata do cliente.
_MENSAGENS_PYDANTIC = {
    "missing": "Campo obrigatório",
    "string_type": "Deve ser um texto",
    "int_type": "Deve ser um número inteiro",
    "bool_type": "Deve ser verdadeiro ou falso",
    "uuid_parsing": "Identificador inválido",
    "json_invalid": "Corpo da requisição não é um JSON válido",
    "value_error": "Valor inválido",
    "enum": "Valor fora das opções permitidas",
}


def _nome_do_campo(loc: tuple[object, ...]) -> str:
    """Converte o `loc` do Pydantic em nome de campo utilizável pelo cliente.

    O `loc` vem prefixado pela origem (`body`, `query`, `path`), que o cliente não
    precisa ver; e partes aninhadas viram caminho pontuado para casar com o campo
    do formulário. Sem nenhuma parte útil, cai em `_` — erro do corpo como um todo.
    """
    partes = [str(p) for p in loc if p not in ("body", "query", "path", "header")]
    return ".".join(partes) if partes else "_"


def registrar_handlers(app: FastAPI) -> None:
    @app.exception_handler(AppError)
    async def _app_error(_: Request, exc: AppError) -> JSONResponse:
        corpo = ErrorResponse(code=exc.code, message=exc.message, fields=exc.fields)
        return JSONResponse(
            status_code=exc.status_code,
            content=corpo.model_dump(exclude_none=True),
        )

    @app.exception_handler(RequestValidationError)
    async def _validacao(_: Request, exc: RequestValidationError) -> JSONResponse:
        campos: dict[str, list[str]] = {}
        for erro in exc.errors():
            campo = _nome_do_campo(erro.get("loc", ()))
            mensagem = _MENSAGENS_PYDANTIC.get(
                erro.get("type", ""),
                erro.get("msg", "Valor inválido"),
            )
            campos.setdefault(campo, []).append(mensagem)

        corpo = ErrorResponse(
            code="validation_error",
            message="Verifique os campos destacados",
            fields=campos,
        )
        return JSONResponse(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            content=corpo.model_dump(exclude_none=True),
        )

    @app.exception_handler(StarletteHTTPException)
    async def _http(_: Request, exc: StarletteHTTPException) -> JSONResponse:
        # Cobre o 404 de rota inexistente e o 405, que nenhuma rota nossa produz
        # mas que o cliente recebe se errar o caminho — melhor no formato conhecido.
        corpo = ErrorResponse(
            code=f"http_{exc.status_code}",
            message=str(exc.detail),
        )
        return JSONResponse(
            status_code=exc.status_code,
            content=corpo.model_dump(exclude_none=True),
        )
