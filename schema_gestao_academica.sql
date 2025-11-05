
-- Schema for Gestão Acadêmica (PostgreSQL)
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Roles (enum-like)
CREATE TABLE roles (
  id SERIAL PRIMARY KEY,
  name VARCHAR(50) UNIQUE NOT NULL
);

INSERT INTO roles (name) VALUES ('ADMIN'), ('COORDENADOR'), ('PROFESSOR'), ('ALUNO'), ('SECRETARIA');

-- Users (base table for alunos, professores, coordenadores)
CREATE TABLE users (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  nome VARCHAR(200) NOT NULL,
  email VARCHAR(200) UNIQUE NOT NULL,
  senha_hash VARCHAR(512) NOT NULL,
  role_id INTEGER REFERENCES roles(id),
  cpf VARCHAR(20),
  telefone VARCHAR(50),
  endereco TEXT,
  data_nascimento DATE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Cursos
CREATE TABLE cursos (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  nome VARCHAR(200) NOT NULL,
  codigo VARCHAR(50),
  descricao TEXT,
  duracao_meses INTEGER,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Disciplinas
CREATE TABLE disciplinas (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  nome VARCHAR(200) NOT NULL,
  codigo VARCHAR(50),
  carga_horaria INTEGER,
  curso_id UUID REFERENCES cursos(id),
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Turmas
CREATE TABLE turmas (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  nome VARCHAR(100) NOT NULL,
  ano INTEGER,
  semestre INTEGER,
  disciplina_id UUID REFERENCES disciplinas(id),
  professor_id UUID REFERENCES users(id),
  sala VARCHAR(100),
  horario TEXT,
  capacidade INTEGER,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Matrículas (aluno em turma)
CREATE TABLE matriculas (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  aluno_id UUID REFERENCES users(id) ON DELETE CASCADE,
  turma_id UUID REFERENCES turmas(id) ON DELETE CASCADE,
  data_matricula TIMESTAMPTZ DEFAULT NOW(),
  status VARCHAR(50) DEFAULT 'MATRICULADO',
  UNIQUE(aluno_id, turma_id)
);

-- Notas / Avaliações
CREATE TABLE avaliacoes (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  matricula_id UUID REFERENCES matriculas(id) ON DELETE CASCADE,
  tipo VARCHAR(100),
  nota NUMERIC(5,2),
  peso NUMERIC(5,2) DEFAULT 1,
  data_avaliacao TIMESTAMPTZ DEFAULT NOW(),
  observacoes TEXT
);

-- Auth refresh tokens
CREATE TABLE refresh_tokens (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  token VARCHAR(512) NOT NULL,
  expires_at TIMESTAMPTZ NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Dashboard / logs (simplified)
CREATE TABLE access_logs (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES users(id),
  path VARCHAR(500),
  method VARCHAR(10),
  status SMALLINT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_turmas_professor ON turmas(professor_id);
CREATE INDEX idx_matriculas_aluno ON matriculas(aluno_id);

-- Seed example admin user (senha_hash a ser gerada com bcrypt)
INSERT INTO users (id, nome, email, senha_hash, role_id)
VALUES ('00000000-0000-0000-0000-000000000001','Admin','admin@academia.local','$2y$12$EXEMPLO_HASH', (SELECT id FROM roles WHERE name='ADMIN'));

