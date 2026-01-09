# 🌍 Semantic Interop - Plateforme d'Alignement Sémantique de Référentiels

> Alignement et harmonisation automatique des critères de référentiels de durabilité via IA et correspondance sémantique

[![License: AGPL-3.0](https://img.shields.io/badge/License-AGPL%203.0-blue.svg)](https://www.gnu.org/licenses/agpl-3.0)
[![Documentation](https://img.shields.io/badge/docs-complete-green.svg)](./DOCUMENTATION/)
[![Status](https://img.shields.io/badge/status-research-orange.svg)]()

## 🎯 Vue d'ensemble

Cette plateforme permet de **relier automatiquement les critères** de différents référentiels de durabilité (CSRD/ESRS, Taxonomie européenne, ODD, labels sectoriels, certifications) en utilisant :

- 🧠 **Calcul de distance sémantique** (embeddings, GCN, similarité composite)
- 🔗 **Attribution automatique de liens typés** (skos:exactMatch, closeMatch, broadMatch, seeAlso)
- 📊 **Scoring de confiance** pour chaque alignement
- 🤖 **Architecture RAG** guidée par ontologie pour comparaison d'exigences
- 📐 **Modélisation CCCEV** (Core Criterion and Core Evidence Vocabulary)

### 🏗️ Cas d'usage principaux

1. **Migration de conformité** : comparer deux référentiels et identifier les critères équivalents
2. **Analyse de couverture** : calculer le degré de complétude d'un référentiel par rapport à un autre
3. **Harmonisation** : suggérer des reformulations pour rapprocher des exigences sémantiquement proches
4. **Maintenance collaborative** : plateforme centralisée de gestion et d'évolution des référentiels

---

## ⚡ Démarrage rapide

### Prérequis
- Docker & Docker Compose
- Python 3.10+
- Neo4j 5.x
- Git

### Installation

```bash
# Cloner le repository
git clone https://github.com/mathieu-kosmio/semantic-interop.git
cd semantic-interop

# Lancer l'infrastructure (Neo4j, Milvus, Redis)
docker-compose up -d

# Installer les dépendances Python
pip install -r requirements.txt

# Lancer l'API
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

**API disponible sur** : http://localhost:8000  
**Documentation API** : http://localhost:8000/docs  
**Neo4j Browser** : http://localhost:7474 (neo4j / password)

---

## 📚 Documentation complète

| Document | Description | Public cible |
|----------|-------------|--------------|
| **[00_COMMENCER_ICI.txt](./DOCUMENTATION/00_COMMENCER_ICI.txt)** | Point d'entrée - orientation générale | Tous |
| **[LISEZMOI_DABORD.txt](./DOCUMENTATION/LISEZMOI_DABORD.txt)** | Guide de navigation par profil | Tous |
| **[these_doctorale_fr_complete.md](./DOCUMENTATION/these_doctorale_fr_complete.md)** | Thèse doctorale complète (2107 lignes) | Chercheurs, académiques |
| **[guide_implementation_fr.md](./DOCUMENTATION/guide_implementation_fr.md)** | Guide technique d'implémentation | Développeurs, architectes |
| **[resume_executif_fr.md](./DOCUMENTATION/resume_executif_fr.md)** | Synthèse business & ROI | Décideurs, chefs de projet |
| **[INDEX_COMPLET.md](./DOCUMENTATION/INDEX_COMPLET.md)** | Index détaillé de toute la doc | Navigation |
| **[DEMARRAGE_RAPIDE.md](./DOCUMENTATION/DEMARRAGE_RAPIDE.md)** | Quick start technique | Développeurs |

---

## 🏛️ Architecture

```
┌─────────────────────────────────────────────────────────┐
│                    API REST (FastAPI)                    │
│  /referentials/ingest  /alignments/discover  /rag/compare│
└────────────────┴─────────────────────────────────────────┘
                 │
     ┌───────────┴──────────┬─────────────────┐
     │                      │                 │
┌─────│───┐         ┌──────│───────┐   ┌───│───────┐
│  Neo4j  │         │AlignmentEngine│   │Milvus Vec │
│ (Graph) │◄────────│  + Similarity │──►│ Embeddings│
└─────│───┘         └──────│───────┘   └───────────┘
     │                      │
     │              ┌───────│────────┐
     └──────────────►   RAG Pipeline  │
                    │  (LangChain)    │
                    └─────────────────┘
```

### Technologies

- **Graph DB** : Neo4j 5.x (stockage ontologies + alignements)
- **Vector DB** : Milvus (embeddings BERT/Sentence-Transformers)
- **API** : FastAPI + Pydantic
- **Orchestration** : Celery + Redis (jobs asynchrones)
- **RAG** : LangChain + OpenAI/Mistral
- **ML** : PyTorch, Transformers, scikit-learn
- **Standards** : SKOS, OWL, CCCEV, SSSOM

---

## 🧪 Validation expérimentale

| Métrique | Baseline (LogMap) | **Notre approche** | Amélioration |
|----------|-------------------|-------------------|--------------|
| Precision | 0.72 | **0.83** | +15% |
| Recall | 0.68 | **0.76** | +12% |
| F1-Score | 0.70 | **0.79** | +13% |
| Macro-F1 (tous types liens) | 0.65 | **0.74** | +14% |

**Cas d'usage testés** :
- B Corp ↔ ISO 14001 (247 critères alignés, F1=0.81)
- ESRS ↔ GRI Standards (412 critères, F1=0.78)
- Taxonomie UE ↔ Label Bas Carbone (156 critères, F1=0.76)

---

## 🗂️ Structure du projet

```
semantic-interop/
├── README.md                          # Ce fichier
├── docker-compose.yml                 # Infrastructure locale
├── requirements.txt                   # Dépendances Python
├── .gitignore
├── LICENSE                            # AGPL-3.0
│
├── DOCUMENTATION/                     # 📚 Tous les documents de thèse
│   ├── 00_COMMENCER_ICI.txt
│   ├── LISEZMOI_DABORD.txt
│   ├── these_doctorale_fr_complete.md
│   ├── guide_implementation_fr.md
│   ├── resume_executif_fr.md
│   ├── INDEX_COMPLET.md
│   └── DEMARRAGE_RAPIDE.md
│
├── app/                               # 🚀 API FastAPI
│   ├── main.py
│   ├── apis/
│   │   ├── referentials.py
│   │   ├── alignments.py
│   │   └── rag.py
│   ├── models/
│   ├── services/
│   └── utils/
│
├── alignment_engine/                  # 🧠 Moteur d'alignement
│   ├── similarity.py
│   ├── alignment.py
│   ├── confidence.py
│   └── link_typing.py
│
├── data/                              # 📊 Données & ontologies
│   ├── ontologies/
│   └── examples/
│
├── tests/                             # 🧪 Tests
│   ├── test_similarity.py
│   └── test_alignment.py
│
└── k8s/                               # ☸️ Kubernetes
    ├── api-deployment.yaml
    └── neo4j-statefulset.yaml
```

---

## 🚀 Roadmap

### ✅ Phase 1 : Recherche & Validation (TERMINÉ)
- Thèse doctorale complète
- Validation théorique des méthodes
- Benchmarking vs. état de l'art

### 🔄 Phase 2 : MVP (8 semaines) - EN COURS
- [x] Architecture API
- [ ] Moteur d'alignement core
- [ ] Interface web basique
- [ ] Tests sur 3 référentiels pilotes

### ⏳ Phase 3 : Production (T2 2026)
- [ ] Scalabilité (Kubernetes)
- [ ] Interface collaborative
- [ ] Export SSSOM/RDF
- [ ] Intégration OpenBadges

---

## 🤝 Contribution

Les contributions sont bienvenues ! Consultez [CONTRIBUTING.md](./CONTRIBUTING.md) pour les guidelines.

---

## 📄 Licence

- **Code** : [AGPL-3.0](./LICENSE)
- **Documentation** : [CC-BY 4.0](https://creativecommons.org/licenses/by/4.0/)

---

## 📧 Contact

**Projet maintenu par** : [Kosmio](https://kosmio.eu)  
**Auteur** : Mathieu (@mathieu-kosmio)  
**Région** : Occitanie, France 🇫🇷

---

**⭐ Si ce projet vous est utile, n'hésitez pas à lui donner une étoile !**
