# Pacote Offline (release-bundle.zip)

Este pacote contém:
- backend/ quarkus-app (runnable com Java 21)
- frontend/ dist (se você tiver construído antes de empacotar)
- keycloak/ realm-export.json
- run-backend.ps1 (perfil default, exige Keycloak)
- run-backend-dev.ps1 (perfil dev, sem Keycloak/Kafka, porta 8081 por padrão)

## Pré-requisitos
- Windows + PowerShell
- Java 21 na PATH (verifique com `java -version`)
- (Opcional) Node.js 20 para servir o frontend dist

## Como executar

### Backend (perfil dev, sem Keycloak)
```powershell
# dentro do zip extraído
./run-backend-dev.ps1 -Port 8081
# Health: http://localhost:8081/api/health
```

### Backend (perfil default, com Keycloak)
```powershell
# Suba o Keycloak (porta 8180) conforme README do projeto original
./run-backend.ps1 -Port 8080
# Health: http://localhost:8080/api/health
```

### Frontend (se dist estiver incluído)
Você pode usar um servidor estático simples (requer Node):
```powershell
npm i -g http-server
http-server ./frontend/dist -p 4200
```
Acesse http://localhost:4200

Observações:
- Caso sua aplicação Angular use rotas (SPA), prefira um servidor estático (como acima) em vez de abrir index.html direto no navegador.
- Para integrar a autenticação, use o backend em perfil default e Keycloak ativo.
