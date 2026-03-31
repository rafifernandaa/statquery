# Copyright 2025 Rafi Fernanda Aldin
#
# Licensed under the Apache License, Version 2.0 (the "License");
# StatQuery: Natural Language Interface for Statistical Methods Catalog
# Track 3 - Gen AI Academy APAC | AlloyDB AI Project Submission
# Project: my-project-31-491314

import os
import json
import traceback
from flask import Flask, request, jsonify, render_template
from dotenv import load_dotenv
from google import genai
from google.genai import types
from sqlalchemy import create_engine, text

load_dotenv()

app = Flask(__name__)

# --- Configuration ---
GEMINI_API_KEY = os.getenv("GEMINI_API_KEY")
DATABASE_URL = os.getenv("DATABASE_URL")

# --- Initialize clients ---
genai_client = None
engine = None

try:
    genai_client = genai.Client(api_key=GEMINI_API_KEY)
    if not DATABASE_URL:
        raise ValueError("DATABASE_URL is not set.")
    engine = create_engine(DATABASE_URL, pool_pre_ping=True)
    print("✅ Gemini + AlloyDB clients initialized.")
except Exception as e:
    print(f"❌ Initialization Error: {traceback.format_exc()}")


# ============================================================
# ROUTES
# ============================================================

@app.route("/")
def home():
    """Render main UI with all statistical methods."""
    if engine is None:
        return jsonify({"error": "Database engine not initialized."}), 500
    try:
        with engine.connect() as conn:
            result = conn.execute(text("""
                SELECT method_id, name, category, subcategory,
                       description, use_case, data_type,
                       difficulty, min_sample_size, r_packages, python_packages
                FROM statistical_methods
                ORDER BY category, name
            """))
            methods = [dict(row._mapping) for row in result]
        return render_template("app.html", methods=methods)
    except Exception as e:
        print(f"Home error: {traceback.format_exc()}")
        return jsonify({"error": str(e)}), 500


@app.route("/api/methods", methods=["GET"])
def get_methods():
    """Return all methods as JSON, optionally filtered by category."""
    if engine is None:
        return jsonify({"error": "Database not initialized."}), 500
    category = request.args.get("category")
    try:
        with engine.connect() as conn:
            if category and category != "All":
                result = conn.execute(text("""
                    SELECT method_id, name, category, subcategory,
                           description, use_case, data_type,
                           difficulty, min_sample_size, r_packages, python_packages
                    FROM statistical_methods
                    WHERE category = :cat
                    ORDER BY name
                """), {"cat": category})
            else:
                result = conn.execute(text("""
                    SELECT method_id, name, category, subcategory,
                           description, use_case, data_type,
                           difficulty, min_sample_size, r_packages, python_packages
                    FROM statistical_methods
                    ORDER BY category, name
                """))
            methods = [dict(row._mapping) for row in result]
        return jsonify(methods)
    except Exception as e:
        return jsonify({"error": str(e)}), 500


@app.route("/api/nl-query", methods=["POST"])
def natural_language_query():
    """
    Core feature: Accept a natural language question,
    use AlloyDB AI (vector similarity + ai.if inline filter)
    to return matching statistical methods.
    Also logs the query for transparency.
    """
    if engine is None:
        return jsonify({"error": "Database not initialized."}), 500

    data = request.json
    nl_query = data.get("query", "").strip()

    if not nl_query:
        return jsonify({"error": "Query cannot be empty."}), 400

    try:
        with engine.connect() as conn:
            # --- AlloyDB AI: Vector similarity search + inline Gemini filter ---
            search_sql = text("""
                SELECT
                    method_id,
                    name,
                    category,
                    subcategory,
                    description,
                    use_case,
                    assumptions,
                    data_type,
                    difficulty,
                    min_sample_size,
                    software,
                    r_packages,
                    python_packages,
                    reference,
                    ROUND(
                        CAST(
                            1 - (method_vector <=>
                                 embedding('text-embedding-005', :query)::vector)
                        AS NUMERIC), 3
                    ) AS similarity_score
                FROM statistical_methods
                WHERE method_vector IS NOT NULL
                  AND ai.if(
                        prompt => 'Does this statistical method: "' || name || '" with description: "' ||
                                  description || '" and use case: "' || use_case ||
                                  '" match or relate to this user request: "' || :query ||
                                  '"? Answer yes only if there is a genuine relevance.',
                        model_id => 'gemini-2.0-flash'
                      )
                ORDER BY method_vector <=> embedding('text-embedding-005', :query)::vector
                LIMIT 6
            """)

            result = conn.execute(search_sql, {"query": nl_query})
            methods = [dict(row._mapping) for row in result]

            # Log the query
            conn.execute(text("""
                INSERT INTO query_log (nl_query, result_count)
                VALUES (:q, :cnt)
            """), {"q": nl_query, "cnt": len(methods)})
            conn.commit()

        # Generate an AI interpretation of the results
        ai_summary = generate_result_summary(nl_query, methods)

        return jsonify({
            "query": nl_query,
            "results": methods,
            "count": len(methods),
            "ai_summary": ai_summary
        })

    except Exception as e:
        print(f"NL Query error: {traceback.format_exc()}")
        return jsonify({
            "error": "Query execution failed.",
            "details": str(e),
            "traceback": traceback.format_exc()
        }), 500


@app.route("/api/nl-to-sql", methods=["POST"])
def nl_to_sql():
    """
    Bonus endpoint: Show the SQL that AlloyDB AI would generate
    for a natural language query — for educational transparency.
    Uses Gemini to translate NL → SQL.
    """
    if genai_client is None:
        return jsonify({"error": "Gemini client not initialized."}), 500

    data = request.json
    nl_query = data.get("query", "").strip()

    if not nl_query:
        return jsonify({"error": "Query cannot be empty."}), 400

    schema_context = """
    Table: statistical_methods
    Columns: method_id, name, category (Regression/IRT/SEM/Bayesian/Nonparametric/Multivariate/Survival/Time Series),
    subcategory, description, use_case, assumptions, min_sample_size,
    data_type (continuous/categorical/ordinal/mixed), software, r_packages,
    python_packages, difficulty (Beginner/Intermediate/Advanced), reference
    """

    prompt = f"""You are a SQL expert for a statistical methods catalog stored in AlloyDB for PostgreSQL.

Given this table schema:
{schema_context}

Translate this natural language question into a valid PostgreSQL SQL query:
"{nl_query}"

Rules:
- Use ILIKE for text matching (case-insensitive)
- Use ORDER BY and LIMIT 10
- Return ONLY the SQL query, no explanation, no markdown fences
- Use WHERE clauses that make logical sense for statistics domain
"""

    try:
        response = genai_client.models.generate_content(
            model="gemini-2.0-flash",
            contents=prompt
        )
        generated_sql = response.text.strip().replace("```sql", "").replace("```", "").strip()

        # Execute the generated SQL for real results
        results = []
        with engine.connect() as conn:
            try:
                result = conn.execute(text(generated_sql))
                results = [dict(row._mapping) for row in result]
            except Exception as sql_err:
                results = []
                generated_sql += f"\n\n-- Execution error: {str(sql_err)}"

        return jsonify({
            "nl_query": nl_query,
            "generated_sql": generated_sql,
            "results": results,
            "count": len(results)
        })

    except Exception as e:
        return jsonify({"error": str(e)}), 500


@app.route("/api/method/<int:method_id>", methods=["GET"])
def get_method_detail(method_id):
    """Get full details of a single method."""
    if engine is None:
        return jsonify({"error": "Database not initialized."}), 500
    try:
        with engine.connect() as conn:
            result = conn.execute(text("""
                SELECT * FROM statistical_methods WHERE method_id = :id
            """), {"id": method_id})
            row = result.fetchone()
            if not row:
                return jsonify({"error": "Method not found."}), 404
            return jsonify(dict(row._mapping))
    except Exception as e:
        return jsonify({"error": str(e)}), 500


@app.route("/api/categories", methods=["GET"])
def get_categories():
    """Return distinct categories for filter UI."""
    if engine is None:
        return jsonify({"error": "Database not initialized."}), 500
    try:
        with engine.connect() as conn:
            result = conn.execute(text("""
                SELECT DISTINCT category FROM statistical_methods ORDER BY category
            """))
            categories = [row[0] for row in result]
        return jsonify(["All"] + categories)
    except Exception as e:
        return jsonify({"error": str(e)}), 500


@app.route("/api/query-log", methods=["GET"])
def get_query_log():
    """Return recent query log for transparency dashboard."""
    if engine is None:
        return jsonify({"error": "Database not initialized."}), 500
    try:
        with engine.connect() as conn:
            result = conn.execute(text("""
                SELECT nl_query, result_count, queried_at
                FROM query_log
                ORDER BY queried_at DESC
                LIMIT 20
            """))
            logs = [dict(row._mapping) for row in result]
        return jsonify(logs)
    except Exception as e:
        return jsonify({"error": str(e)}), 500


# ============================================================
# HELPER
# ============================================================

def generate_result_summary(nl_query: str, methods: list) -> str:
    """Use Gemini to generate a concise expert summary of search results."""
    if genai_client is None or not methods:
        return ""
    method_names = ", ".join([m["name"] for m in methods])
    prompt = f"""You are a statistics professor assistant.
A student asked: "{nl_query}"

The system found these matching statistical methods: {method_names}.

Write a 2-sentence expert recommendation explaining which method(s) are most relevant and why.
Be concise, direct, and educational. No markdown, no bullet points."""

    try:
        response = genai_client.models.generate_content(
            model="gemini-2.0-flash",
            contents=prompt
        )
        return response.text.strip()
    except Exception:
        return ""


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=int(os.environ.get("PORT", 8080)), threaded=True)
