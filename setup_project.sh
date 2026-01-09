#!/bin/bash

# Script de génération complète du projet Semantic Interop
# Auteur: Mathieu (@mathieu-kosmio)
# Date: 2026-01-09

set -e  # Arrêt en cas d'erreur

echo "🚀 Génération de la structure du projet Semantic Interop..."

# ============================================================================
# FICHIERS RACINE
# ============================================================================

echo "📝 Création des fichiers de configuration racine..."

# requirements.txt
cat > requirements.txt << 'EOF'
# Core API
fastapi==0.104.1
uvicorn[standard]==0.24.0
pydantic==2.5.0
pydantic-settings==2.1.0
python-dotenv==1.0.0
python-multipart==0.0.6

# Graph DB
neo4j==5.15.0
py2neo==2021.2.3

# Vector DB
pymilvus==2.3.4

# Task queue
celery==5.3.4
redis==5.0.1

# ML & Embeddings
torch==2.1.2
transformers==4.36.2
sentence-transformers==2.2.2
scikit-learn==1.3.2
numpy==1.24.4
scipy==1.11.4

# NLP
nltk==3.8.1
spacy==3.7.2

# RAG
langchain==0.1.0
langchain-community==0.0.10
openai==1.6.1
tiktoken==0.5.2

# RDF & Ontologies
rdflib==7.0.0
owlrl==6.0.2

# API clients
httpx==0.25.2
aiohttp==3.9.1

# Data validation
jsonschema==4.20.0

# Logging & monitoring
loguru==0.7.2

# Testing
pytest==7.4.3
pytest-asyncio==0.21.1
pytest-cov==4.1.0
httpx==0.25.2

# Code quality
black==23.12.1
flake8==6.1.0
mypy==1.7.1
isort==5.13.2

# Documentation
mkdocs==1.5.3
mkdocs-material==9.5.3
EOF

# docker-compose.yml
cat > docker-compose.yml << 'EOF'
version: '3.8'

services:
  neo4j:
    image: neo4j:5.15-community
    container_name: semantic-interop-neo4j
    ports:
      - "7474:7474"  # HTTP
      - "7687:7687"  # Bolt
    environment:
      NEO4J_AUTH: neo4j/semanticinterop2026
      NEO4J_PLUGINS: '["apoc", "graph-data-science"]'
      NEO4J_dbms_memory_heap_max__size: 2G
      NEO4J_dbms_memory_pagecache_size: 1G
    volumes:
      - neo4j_data:/data
      - neo4j_logs:/logs
      - neo4j_import:/var/lib/neo4j/import
      - neo4j_plugins:/plugins
    networks:
      - semantic-interop-net
    restart: unless-stopped

  milvus-etcd:
    image: quay.io/coreos/etcd:v3.5.5
    container_name: semantic-interop-milvus-etcd
    environment:
      - ETCD_AUTO_COMPACTION_MODE=revision
      - ETCD_AUTO_COMPACTION_RETENTION=1000
      - ETCD_QUOTA_BACKEND_BYTES=4294967296
      - ETCD_SNAPSHOT_COUNT=50000
    volumes:
      - etcd_data:/etcd
    command: etcd -advertise-client-urls=http://127.0.0.1:2379 -listen-client-urls http://0.0.0.0:2379 --data-dir /etcd
    networks:
      - semantic-interop-net

  milvus-minio:
    image: minio/minio:RELEASE.2023-03-20T20-16-18Z
    container_name: semantic-interop-milvus-minio
    environment:
      MINIO_ACCESS_KEY: minioadmin
      MINIO_SECRET_KEY: minioadmin
    volumes:
      - minio_data:/minio_data
    command: minio server /minio_data
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:9000/minio/health/live"]
      interval: 30s
      timeout: 20s
      retries: 3
    networks:
      - semantic-interop-net

  milvus-standalone:
    image: milvusdb/milvus:v2.3.4
    container_name: semantic-interop-milvus
    depends_on:
      - milvus-etcd
      - milvus-minio
    environment:
      ETCD_ENDPOINTS: milvus-etcd:2379
      MINIO_ADDRESS: milvus-minio:9000
    volumes:
      - milvus_data:/var/lib/milvus
    ports:
      - "19530:19530"
      - "9091:9091"
    networks:
      - semantic-interop-net
    restart: unless-stopped

  redis:
    image: redis:7-alpine
    container_name: semantic-interop-redis
    ports:
      - "6379:6379"
    volumes:
      - redis_data:/data
    networks:
      - semantic-interop-net
    restart: unless-stopped
    command: redis-server --appendonly yes

  api:
    build:
      context: .
      dockerfile: Dockerfile
    container_name: semantic-interop-api
    depends_on:
      - neo4j
      - milvus-standalone
      - redis
    ports:
      - "8000:8000"
    environment:
      - NEO4J_URI=bolt://neo4j:7687
      - NEO4J_USER=neo4j
      - NEO4J_PASSWORD=semanticinterop2026
      - MILVUS_HOST=milvus-standalone
      - MILVUS_PORT=19530
      - REDIS_URL=redis://redis:6379/0
      - ENVIRONMENT=development
    volumes:
      - ./app:/app/app
      - ./alignment_engine:/app/alignment_engine
      - ./data:/app/data
    networks:
      - semantic-interop-net
    restart: unless-stopped
    command: uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload

volumes:
  neo4j_data:
  neo4j_logs:
  neo4j_import:
  neo4j_plugins:
  milvus_data:
  minio_data:
  etcd_data:
  redis_data:

networks:
  semantic-interop-net:
    driver: bridge
EOF

# Dockerfile
cat > Dockerfile << 'EOF'
FROM python:3.11-slim

WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y \
    gcc \
    g++ \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Copy requirements
COPY requirements.txt .

# Install Python dependencies
RUN pip install --no-cache-dir -r requirements.txt

# Download spacy model
RUN python -m spacy download fr_core_news_md

# Copy application code
COPY . .

# Expose port
EXPOSE 8000

# Run application
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]
EOF

# LICENSE (AGPL-3.0)
cat > LICENSE << 'EOF'
                    GNU AFFERO GENERAL PUBLIC LICENSE
                       Version 3, 19 November 2007

 Copyright (C) 2026 Kosmio - Mathieu
 Everyone is permitted to copy and distribute verbatim copies
 of this license document, but changing it is not allowed.

                            Preamble

  The GNU Affero General Public License is a free, copyleft license for
software and other kinds of works, specifically designed to ensure
cooperation with the community in the case of network server software.

  [Full AGPL-3.0 license text would be here - truncated for brevity]
  
For the complete license text, see: https://www.gnu.org/licenses/agpl-3.0.txt
EOF

# .env.example
cat > .env.example << 'EOF'
# Neo4j Configuration
NEO4J_URI=bolt://localhost:7687
NEO4J_USER=neo4j
NEO4J_PASSWORD=semanticinterop2026

# Milvus Configuration
MILVUS_HOST=localhost
MILVUS_PORT=19530

# Redis Configuration
REDIS_URL=redis://localhost:6379/0

# API Configuration
API_HOST=0.0.0.0
API_PORT=8000
API_WORKERS=4

# OpenAI (optional for RAG)
OPENAI_API_KEY=your_openai_key_here

# Environment
ENVIRONMENT=development
LOG_LEVEL=INFO
EOF

# CONTRIBUTING.md
cat > CONTRIBUTING.md << 'EOF'
# Guide de Contribution

Merci de votre intérêt pour contribuer à Semantic Interop ! 🎉

## Comment contribuer

1. **Fork** le repository
2. Créez une **branche** pour votre feature (`git checkout -b feature/amazing-feature`)
3. **Commitez** vos changements (`git commit -m '✨ Add amazing feature'`)
4. **Pushez** sur la branche (`git push origin feature/amazing-feature`)
5. Ouvrez une **Pull Request**

## Standards de code

- Python : PEP 8 (utilisez `black` et `flake8`)
- Commits : Convention Conventional Commits avec emojis
- Tests : Coverage > 80%
- Documentation : Docstrings Google Style

## Domaines de contribution

- 🔬 Amélioration des algorithmes de similarité
- 🌐 Support multilingue
- 📊 Nouveaux référentiels (ODD, EMAS, etc.)
- 🎨 Interface utilisateur
- 📚 Documentation & exemples

## Questions ?

Ouvrez une **issue** ou contactez : contact@kosmio.eu
EOF

echo "✅ Fichiers racine créés"

# ============================================================================
# STRUCTURE DOSSIERS
# ============================================================================

echo "📁 Création de la structure des dossiers..."

mkdir -p DOCUMENTATION
mkdir -p app/{apis,models,services,utils}
mkdir -p alignment_engine
mkdir -p data/{ontologies,examples}
mkdir -p tests
mkdir -p k8s
mkdir -p docs

echo "✅ Structure des dossiers créée"

# ============================================================================
# DOCUMENTATION (fichiers simplifiés - les vrais contenus à copier manuellement)
# ============================================================================

echo "📚 Création des fichiers DOCUMENTATION/..."

cat > DOCUMENTATION/00_COMMENCER_ICI.txt << 'EOF'
═══════════════════════════════════════════════════════════════════════════
   🌍 SEMANTIC INTEROP - PLATEFORME D'ALIGNEMENT SÉMANTIQUE DE RÉFÉRENTIELS
═══════════════════════════════════════════════════════════════════════════

📍 VOUS ÊTES ICI : Point d'entrée de la documentation

Ce projet permet d'aligner automatiquement les critères de différents 
référentiels de durabilité (CSRD/ESRS, Taxonomie UE, ODD, labels, etc.) 
via IA et correspondance sémantique.

🎯 COMMENCEZ PAR :
1. Lire ce fichier (2 min)
2. Consulter LISEZMOI_DABORD.txt pour navigation par profil
3. Choisir votre document selon votre rôle

📚 DOCUMENTS DISPONIBLES :
- these_doctorale_fr_complete.md (2107 lignes) - Chercheurs
- guide_implementation_fr.md (1753 lignes) - Développeurs  
- resume_executif_fr.md (240 lignes) - Décideurs
- INDEX_COMPLET.md - Navigation détaillée
- DEMARRAGE_RAPIDE.md - Quick start

🚀 DÉMARRAGE RAPIDE :
```bash
docker-compose up -d
pip install -r requirements.txt
uvicorn app.main:app --reload
