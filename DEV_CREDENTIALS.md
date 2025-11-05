# Credenciais de Desenvolvimento (provisórias)

Estas credenciais são apenas para validação em ambiente de desenvolvimento. Não use em produção.
Remover este arquivo e/ou alterar as credenciais antes de compartilhar o repositório publicamente.

## Keycloak (Realm: gestao-academica)

Senha (todas): Dev@2025!

- Aluno
  - Usuário: aluno.dev
  - E-mail: aluno.dev@gestao-local.test
  - Acesso esperado: /dashboard-aluno

- Professor
  - Usuário: prof.dev
  - E-mail: prof.dev@gestao-local.test
  - Acesso esperado: /dashboard-professor

- Coordenador
  - Usuário: coord.dev
  - E-mail: coord.dev@gestao-local.test
  - Acesso esperado: /dashboard-coordenador

## Como usar

1. Suba o Keycloak via docker compose (o realm-export.json já inclui os usuários acima):

```powershell
docker compose up -d keycloak
```

2. Suba o backend (Quarkus) e o frontend (Angular) conforme o README principal.
3. Acesse http://localhost:4200/login e autentique com um dos usuários acima.

## Observações
- A tela de login aceita usuário ou e-mail.
- O fluxo é interno: a aplicação troca as credenciais por token no Keycloak sem expor a tela do Keycloak para o usuário final.
- Após a validação, substitua essas credenciais por um fluxo de criação/convite próprio e remova este arquivo do repositório.
