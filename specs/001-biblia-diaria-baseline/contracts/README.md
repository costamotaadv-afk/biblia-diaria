# Contracts — Bíblia Diária Linha de Base

Este diretório documenta as **interfaces que o projeto expõe** internamente
(app Flutter, sem serviço externo). Contratos são a fronteira estável entre
módulos; mudanças aqui exigem atualização dos testes correspondentes.

| Contrato | Descrição | Arquivo |
|----------|-----------|---------|
| Módulos puros (`lib/*.dart`) | APIs públicas das regras de negócio e guardiões de dados | [module-apis.md](module-apis.md) |
| Armazenamento local | Chaves, formatos e regras de persistência | [storage.md](storage.md) |
| Plataforma e plugins | Gates de capacidade e degradação (voz, anúncios, clipboard) | [platform.md](platform.md) |
| Widgets (UI) | Contratos de componentes reutilizáveis | [module-apis.md](module-apis.md) (seção Widgets) |

Convenções do projeto (constituição v1.0.0):

- Lógica pura → funções sem I/O/estado, mesmo input → mesmo output.
- Nenhum contrato depende de framework externo de estado; UI lê funções puras e
  chama callbacks injetados.
- Nomes e mensagens em pt-BR.
