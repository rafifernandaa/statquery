# StatQuery 📊

**Natural Language Interface for a Statistical Methods Catalog**

**Use case:** Querying a curated statistical methods catalog (IRT, SEM, Regression, Bayesian, etc.) using natural language powered by AlloyDB AI.

---

## What This Project Does

StatQuery lets users ask questions in plain English like:

> *"What method should I use for ordinal survey data with small samples?"*
> *"Show me IRT models for psychometric scale development"*
> *"Methods for causal mediation with latent variables"*

AlloyDB AI converts the query into vector embeddings, performs semantic similarity search **inside the database**, applies an inline Gemini AI filter (`ai.if()`), executes the SQL, and returns the most relevant statistical methods — all without writing a single line of traditional SQL.

---

## Architecture

```
User (Browser)
     │
     ▼
Flask App (Cloud Run)
     │
     ├── /api/nl-query  ──→  AlloyDB AI
     │                          ├── embedding('text-embedding-005', query)
     │                          ├── vector similarity search (<=>)
     │                          └── ai.if(model_id='gemini-3-flash-preview')
     │
     ├── /api/nl-to-sql ──→  Gemini API (NL → SQL translation)
     │
     └── /api/methods   ──→  AlloyDB (standard SQL catalog browse)
```

---

## Dataset

Custom table: `statistical_methods` — **30 rows** covering:

| Category | Methods Included |
|---|---|
| Regression | OLS, Logistic, Ordinal, Poisson, Panel (FEM/REM), Ridge, LASSO |
| IRT | Rasch (1PL), 2PL, 3PL, Graded Response Model, DIF Analysis |
| SEM | CFA, Full SEM, PLS-SEM, Mediation, Moderation |
| Bayesian | Bayesian Regression, Bayesian Networks |
| Nonparametric | Mann-Whitney, Kruskal-Wallis, Spearman |
| Multivariate | PCA, EFA, K-Means, LDA |
| Survival | Kaplan-Meier, Cox Proportional Hazards |
| Time Series | ARIMA |

Schema columns: `name, category, subcategory, description, use_case, assumptions, min_sample_size, data_type, software, r_packages, python_packages, difficulty, reference, method_vector`

---

## AlloyDB AI Features Used

### 1. In-database Vector Embeddings
```sql
-- Generate embeddings at insert time (AlloyDB calls text-embedding-005 inline)
UPDATE statistical_methods
SET method_vector = embedding('text-embedding-005',
    name || ' ' || category || ' ' || description || ' ' || use_case
)::vector;
```

### 2. Vector Similarity Search
```sql
-- Cosine distance search against user query
ORDER BY method_vector <=> embedding('text-embedding-005', :query)::vector
```

### 3. Inline Gemini AI Filter (`ai.if`)
```sql
-- AlloyDB calls Gemini inline to validate semantic relevance
AND ai.if(
    prompt => 'Does this method: "' || name || '" match the request: "' || :query || '"?',
    model_id => 'gemini-3-flash-preview'
)
```

### 4. Natural Language → SQL (Gemini API)
The `/api/nl-to-sql` endpoint uses Gemini to translate a natural language question into a valid PostgreSQL query against the schema, then executes it live.

---

## Project Structure

```
statquery/
├── app.py              # Flask app — all routes and AlloyDB AI logic
├── schema.sql          # Table schema + seed data (30 methods) + vector setup
├── requirements.txt
├── Dockerfile
├── deploy.sh           # Full deploy script (AlloyDB setup → Cloud Run)
├── .env                # Environment variables (not committed to Git)
├── .gitignore
└── templates/
    └── app.html        # Single-file frontend (HTML + CSS + JS)
```

---

## Setup & Deployment

### Prerequisites
- GCP Project: `my-project-31-491314`
- AlloyDB cluster + instance running (use [easy-alloydb-setup](https://github.com/AbiramiSukumaran/easy-alloydb-setup))
- AlloyDB AI natural language enabled on your instance
- Gemini API key

### Step 1: Set up AlloyDB

Clone and run the easy-alloydb-setup tool in Cloud Shell:
```bash
git clone https://github.com/AbiramiSukumaran/easy-alloydb-setup
cd easy-alloydb-setup
sh run.sh
```

### Step 2: Load the Schema

Connect to your AlloyDB instance via Cloud Shell or AlloyDB Studio and run:
```bash
# From Cloud Shell (with psql installed):
psql "host=YOUR_PRIVATE_IP user=postgres dbname=postgres" -f schema.sql
```

Or paste the contents of `schema.sql` directly into **AlloyDB Studio → SQL Editor**.

### Step 3: Enable AlloyDB AI Natural Language

First, grant the AlloyDB service account the Vertex AI User role so it can call Gemini inline:
```bash
gcloud projects add-iam-policy-binding my-project-31-491314 \
  --member="serviceAccount:c-676289354133-97e4ab8c@gcp-sa-alloydb.iam.gserviceaccount.com" \
  --role="roles/aiplatform.user"
```

Then in **AlloyDB Studio → SQL Editor**, register the Gemini model:
```sql
CALL google_ml.create_model(
  model_id => 'gemini-3-flash-preview',
  model_request_url => 'https://aiplatform.googleapis.com/v1/projects/my-project-31-491314/locations/global/publishers/google/models/gemini-3-flash-preview:generateContent',
  model_qualified_name => 'gemini-3-flash-preview',
  model_provider => 'google',
  model_type => 'llm',
  model_auth_type => 'alloydb_service_agent_iam'
);
```

### Step 4: Deploy to Cloud Run

Fill in your values in `deploy.sh`, then:
```bash
chmod +x deploy.sh
sh deploy.sh
```

Or manually:
```bash
gcloud config set project my-project-31-491314

gcloud beta run deploy statquery \
  --source . \
  --region=us-central1 \
  --network=YOUR_NETWORK \
  --subnet=YOUR_SUBNET \
  --allow-unauthenticated \
  --vpc-egress=all-traffic \
  --memory=1Gi \
  --clear-base-image \
  --set-env-vars GEMINI_API_KEY=YOUR_KEY,DATABASE_URL=postgresql+pg8000://postgres:YOUR_PASS@YOUR_IP:5432/postgres
```

### Step 5: Verify

```bash
# Check logs
gcloud run logs read statquery --region=us-central1 --limit=50

# Test locally (optional)
pip install -r requirements.txt
# make sure .env is filled with your values
python app.py
```

---

## API Endpoints

| Method | Endpoint | Description |
|---|---|---|
| GET | `/` | Main UI with full catalog |
| POST | `/api/nl-query` | AlloyDB AI semantic search |
| POST | `/api/nl-to-sql` | Gemini NL → SQL translation |
| GET | `/api/methods?category=IRT` | Filter catalog by category |
| GET | `/api/method/:id` | Full method detail |
| GET | `/api/categories` | List all categories |
| GET | `/api/query-log` | Recent NL query history |

---

## Sample Natural Language Queries

```
"What method should I use for predicting a binary outcome?"
"Show me IRT models suitable for polytomous items"
"Methods for testing mediation with latent variables in SEM"
"Nonparametric tests for non-normal ordinal data"
"Regression methods for time-series panel data"
"Beginner-friendly methods for continuous outcomes with small n"
"Which methods work with categorical and ordinal mixed data?"
"Methods that use the lavaan package in R"
```

---

## Tech Stack

| Component | Technology |
|---|---|
| Database | AlloyDB for PostgreSQL (Google Cloud) |
| AI (in-database) | AlloyDB AI: `embedding()` + `ai.if()` + Gemini 3 Flash Preview |
| Backend | Python 3.12, Flask, SQLAlchemy + pg8000 |
| Frontend | Single-file HTML/CSS/JS (Space Mono + Syne fonts) |
| Deployment | Cloud Run (source deploy via `gcloud beta run deploy`) |
| AI API | Google Gemini API via `google-genai` SDK |

---

## License

Apache 2.0
