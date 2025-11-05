# Gestão Acadêmica – Angular + Quarkus + Keycloak

Aplicação full‑stack com frontend Angular 20 (standalone) e backend Java Quarkus 3.x em arquitetura hexagonal. Autenticação é centralizada via Keycloak (OIDC), porém o usuário final vê uma tela de login “normal” (usuário/senha); a integração com o Keycloak ocorre internamente.

## Tecnologias
- Frontend
  - Angular 20 (standalone), Router, FormsModule (template‑driven)
  - HttpClient + Interceptor (injeta Bearer e faz retry automático após refresh)
  - Guards de autenticação e papéis: aluno, professor, coordenador
  - Playwright para E2E
  - keycloak-js (para init/check-sso e fallback quando necessário)
- Backend
  - Quarkus 3.x (RESTEasy Reactive)
  - OIDC (Keycloak): troca de usuário/senha por token (password grant) e refresh
  - Jackson para JSON
  - Health endpoint exposto em `/api/health`
  - Hibernate Reactive Panache e Messaging (scaffolding; Kafka DevServices desabilitado)
- Infra/Auth
  - Keycloak 26.x (realm import via docker‑compose)
  - Docker Compose para provisionar Keycloak com `realm-export.json`
- DevOps
  - GitHub Actions: build do backend, start do jar, front via Playwright webServer e E2E

## Recursos implementados
- Tela de login simples (usuário/senha) com Keycloak “oculto”
- Interceptor de autenticação com refresh de token e retry do request 401/403
- Roteamento por papel: aluno → `/dashboard-aluno`, professor → `/dashboard-professor`, coordenador → `/dashboard-coordenador`
- Logout interno (sem redirecionar para Keycloak)
- Health check do backend em `/api/health`
- E2E cobrindo: login UI, roteamento por papel, logout, fluxo de refresh e smoke test da API

## Estrutura de pastas
- `java/` – Backend Quarkus (arquitetura hexagonal)
  - `domain/`, `application/`, `infrastructure/`, `web/`
- `frontend/` – Angular
  - Componentes (login, dashboards), Interceptor, Guards, Services
  - Proxy (`frontend/proxy.conf.json`) mapeando `/api` → `http://localhost:8080`
- `keycloak/realm-export.json` – Realm `gestao-academica` com papéis e usuários de exemplo
- `.github/workflows/ci.yml` – Pipeline de CI

## Portas
- Frontend (Angular): http://localhost:4200
- Backend (Quarkus): http://localhost:8080
- Keycloak: http://localhost:8180

## Pré‑requisitos
- Node.js 20 + npm
- Java 21 (LTS) + Maven 3.9+
- Docker Desktop (para subir o Keycloak via compose)
  
Opcional, para banco local: Docker para PostgreSQL (já incluso no docker-compose).

## Como rodar (Windows PowerShell)
Checklist rápido de integração (DB + backend + frontend):
- [ ] Subir Postgres do docker-compose
- [ ] Criar DB e aplicar `schema_gestao_academica.sql`
- [ ] Exportar DB_URL/DB_USER/DB_PASSWORD (se necessário)
- [ ] Subir backend (`quarkus:dev`) e checar `/api/health`
- [ ] Subir frontend e acessar `/login`

1) Subir o Keycloak com realm e usuários prontos
```powershell
docker compose up -d keycloak
```

Usuários de exemplo (realm `gestao-academica`):
2) Subir o backend (Quarkus)
```powershell
mvn -f .\java\pom.xml quarkus:dev
# opcional: se a 8080 estiver ocupada, rode em 8081
mvn -f .\java\pom.xml quarkus:dev -Dquarkus.http.port=8081
```
Health: http://localhost:8080/api/health (ou 8081) → `{ "status": "ok" }`
- coord.dev → `/dashboard-coordenador`

- Backend (Quarkus): http://localhost:8080 (ou 8081, se você iniciar com o parâmetro)

2) Subir o backend (Quarkus)
```powershell
mvn -f .\java\pom.xml quarkus:dev
```
Health: http://localhost:8080/api/health → `{ "status": "ok" }`

3) Subir o frontend (Angular)
```powershell
npm install
npm run start:test
```
Acesse http://localhost:4200/login

Opcional: subir tudo junto (Keycloak + backend + frontend) em um terminal
```powershell
npm run dev:all
```

### Integração com Banco de Dados (PostgreSQL) – passo a passo 🐘
O backend usa cliente reativo do PostgreSQL (sem ORM) e requer o schema exato de `schema_gestao_academica.sql`.

1) Suba o Postgres local via Docker (usando o compose do projeto)
```powershell
docker compose up -d postgres
```

2) Crie o banco e aplique o schema do DB Developer
```powershell
# copie o arquivo SQL para dentro do container e aplique
# Observação: se o arquivo .sql não estiver nesta pasta, ajuste o caminho abaixo.
# Exemplo (substitua pelo caminho real do seu arquivo .sql):
# docker cp "C:\\Users\\SEU_USUARIO\\Desktop\\schema_gestao_academica.sql" postgres:/schema.sql
docker cp .\schema_gestao_academica.sql postgres:/schema.sql
docker exec -it postgres psql -U postgres -c "CREATE DATABASE gestao_academica;"
docker exec -it postgres psql -U postgres -d gestao_academica -f /schema.sql
```

3) Configure (se necessário) variáveis de ambiente do backend
- Padrão (se você usou o docker-compose do projeto):
  - DB_URL: `postgresql://localhost:5432/gestao_academica`
  - DB_USER: `postgres`
  - DB_PASSWORD: `postgres`

Para sobrescrever (na sessão atual do PowerShell):
```powershell
$env:DB_URL = "postgresql://localhost:5432/gestao_academica"
$env:DB_USER = "postgres"
$env:DB_PASSWORD = "postgres"
```

4) Inicie o backend já apontando para o Postgres
```powershell
mvn -f .\java\pom.xml quarkus:dev
# ou, porta alternativa
mvn -f .\java\pom.xml quarkus:dev -Dquarkus.http.port=8081
```

5) Verifique a saúde e a conexão básica
```powershell
# health do serviço
curl http://localhost:8080/api/health

# exemplos de endpoints que consultam o banco (podem retornar lista vazia no início)
curl http://localhost:8080/api/coordenador/cursos
curl http://localhost:8080/api/coordenador/disciplinas
curl http://localhost:8080/api/coordenador/turmas
curl http://localhost:8080/api/coordenador/matriculas/pendentes
```

6) Inicie o frontend (usa proxy para /api → backend)
```powershell
npm install
npm run start:test
```
Acesse http://localhost:4200/login

Notas importantes:
- Autenticação: o backend usa OIDC (Keycloak). Para que dashboards de Professor/Aluno funcionem, o e‑mail do usuário no Keycloak deve existir em `users.email` no banco (mesmo valor).
- Papéis (roles): mapeados pela tabela `roles` (ADMIN, COORDENADOR, PROFESSOR, ALUNO, SECRETARIA) e referenciados por `users.role_id`.
- Status de matrícula: o backend trata pendências comparando `UPPER(m.status) = 'PENDENTE'` e usa `MATRICULADO` como padrão de criação.
- As consultas são 100% SQL, via PgClient reativo, aderindo ao schema fixo fornecido.

## Configuração (detalhes)
### Frontend – Keycloak
Arquivo: `frontend/src/keycloak.config.ts`
- `url`: `http://localhost:8180/`
- `realm`: `gestao-academica`
- `clientId`: `frontend`

### Backend – Quarkus
Arquivo: `java/src/main/resources/application.properties`
- `quarkus.http.port=8080`
- `quarkus.http.cors=true` e `origins=http://localhost:4200`
- `quarkus.oidc.auth-server-url=${OIDC_URL:http://localhost:8180/realms/gestao-academica}`
- `quarkus.oidc.client-id=${OIDC_CLIENT:frontend}`
- `quarkus.oidc.credentials.secret=${OIDC_SECRET:change-me}` (se client confidencial)
- Público: `/api/auth/login`, `/api/auth/refresh`, `/api/health`
 
Notas de desenvolvimento:
- Em `%dev`, o OIDC está desabilitado e os canais Kafka também (para facilitar smoke tests sem dependências externas).
- A porta em `%dev` é 8081 por padrão, evitando conflito com outros serviços.

## Autenticação – Endpoints do backend
- `POST /api/auth/login`
  - Body: `{ "username": "...", "password": "..." }`
  - Retorna os tokens do Keycloak (password grant)
- `POST /api/auth/refresh`
  - Body: `{ "refresh_token": "..." }`
  - Retorna novos tokens (refresh token grant)

O frontend gerencia o armazenamento/renovação do token e executa retry automático nos 401/403 via interceptor.

## Testes
### Unitários (Angular – Karma)
```powershell
npm test
```

### End‑to‑End (Playwright)
Playwright já inicia o frontend em 4200 automaticamente:
```powershell
npm run e2e
```

Para incluir o smoke test da API (requer backend rodando):
```powershell
$env:API_SMOKE=1
npm run e2e
```

## Scripts úteis (package.json)
- `start` → `ng serve`
- `start:test` → `ng serve --port 4200 --no-open`
- `dev:keycloak` → `docker compose up -d keycloak`
- `dev:back` → `mvn -f ./java/pom.xml quarkus:dev`
- `dev:all` → sobe Keycloak, backend e frontend juntos
- `e2e` → `playwright test` (com webServer automático)
- `e2e:install` → instala navegadores do Playwright

## CI (GitHub Actions)
Arquivo: `.github/workflows/ci.yml`
- Build do backend (`mvn -f java/pom.xml -DskipTests package`)
- Start do jar e espera pelo `/api/health`
- E2E com Playwright (webServer do front e `API_SMOKE=1`)

## Solução de problemas
- 401/403 após algum tempo → confirme “Direct Access Grants” no client `frontend` do Keycloak; verifique relógio do sistema (campo `exp` do JWT)
- CORS/Proxy → `quarkus.http.cors.origins=http://localhost:4200` e `frontend/proxy.conf.json` → `http://localhost:8080`
- Kafka/DevServices pedindo Docker → já está desabilitado: `quarkus.kafka.devservices.enabled=false`
- Maven fora do PATH → use o caminho completo para `mvn.cmd`

---
