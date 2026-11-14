"""Lab 1C/2 notes API: EC2 -> SSM/Secrets Manager -> RDS MySQL."""
import json
import logging
import os
from datetime import datetime, timezone
from functools import wraps

import boto3
import pymysql
from botocore.exceptions import BotoCoreError, ClientError
from flask import Flask, jsonify, request

REGION = os.environ.get("AWS_REGION", "us-east-1")
PREFIX = os.environ.get("PARAMETER_PREFIX", "/lab/db").rstrip("/")
DB_ID = os.environ.get("DB_INSTANCE_IDENTIFIER", "lab-1c-learning-mysql")

app = Flask(__name__)
logging.basicConfig(level=logging.INFO)
ssm = boto3.client("ssm", region_name=REGION)
secrets = boto3.client("secretsmanager", region_name=REGION)
cloudwatch = boto3.client("cloudwatch", region_name=REGION)


def database_settings():
    required = ["endpoint", "port", "name", "master-secret-arn"]
    names = [f"{PREFIX}/{key}" for key in required]
    result = ssm.get_parameters(Names=names, WithDecryption=False)
    values = {item["Name"]: item["Value"] for item in result["Parameters"]}
    missing = [name for name in names if name not in values]
    if missing:
        # Log parameter names only, never secret values.
        app.logger.error("Missing SSM database parameters: %s", ", ".join(missing))
        raise KeyError("Missing database configuration parameter")
    secret = secrets.get_secret_value(SecretId=values[f"{PREFIX}/master-secret-arn"])
    credentials = json.loads(secret["SecretString"])
    return {
        "host": values[f"{PREFIX}/endpoint"],
        "port": int(values[f"{PREFIX}/port"]),
        "database": values[f"{PREFIX}/name"],
        "user": credentials["username"],
        "password": credentials["password"],
    }


def open_database():
    config = database_settings()
    return pymysql.connect(
        **config,
        charset="utf8mb4",
        cursorclass=pymysql.cursors.DictCursor,
        autocommit=True,
        connect_timeout=5,
        read_timeout=5,
        write_timeout=5,
    )


def record_connection_failure():
    try:
        cloudwatch.put_metric_data(
            Namespace="Lab1C/Database",
            MetricData=[{
                "MetricName": "DBConnectionErrors",
                "Dimensions": [{"Name": "DBInstanceIdentifier", "Value": DB_ID}],
                "Value": 1,
                "Unit": "Count",
            }],
        )
    except (ClientError, BotoCoreError) as error:
        app.logger.warning("Could not publish CloudWatch metric: %s", type(error).__name__)


def handle_database_errors(handler):
    @wraps(handler)
    def wrapped(*args, **kwargs):
        try:
            return handler(*args, **kwargs)
        except (ClientError, BotoCoreError, pymysql.MySQLError, KeyError, ValueError, TypeError) as error:
            app.logger.error("Database operation failed: %s", type(error).__name__)
            record_connection_failure()
            return jsonify(error="Database temporarily unavailable"), 503
    return wrapped


@app.get("/health")
def health():
    return jsonify(status="ok")


# Lab 2B: deterministic, public response for CloudFront static caching tests.
# A real static asset can also be served from Flask's static/ directory.
@app.get("/static/example.txt")
def static_cache_example():
    response = app.response_class(
        "AWS Armageddon Lab 2B public static cache example\n",
        mimetype="text/plain",
    )
    response.headers["Cache-Control"] = "public, max-age=86400"
    return response


# Lab 2B: no database required; a changing timestamp proves API freshness.
@app.get("/api/cache-test")
def api_cache_test():
    response = jsonify(
        message="Dynamic API cache test",
        generated_at=datetime.now(timezone.utc).isoformat(),
    )
    response.headers["Cache-Control"] = "no-store"
    return response


@app.get("/ready")
@handle_database_errors
def ready():
    with open_database() as connection:
        with connection.cursor() as cursor:
            cursor.execute("SELECT 1")
    return jsonify(database="reachable")


@app.post("/init")
@handle_database_errors
def init_notes():
    with open_database() as connection:
        with connection.cursor() as cursor:
            cursor.execute("""
                CREATE TABLE IF NOT EXISTS notes (
                    id INT AUTO_INCREMENT PRIMARY KEY,
                    note VARCHAR(255) NOT NULL
                )
            """)
    app.logger.info("Notes table initialized")
    return jsonify(message="Notes table ready")


@app.post("/add")
@handle_database_errors
def add_note():
    body = request.get_json(silent=True)
    note = body.get("note") if isinstance(body, dict) else None
    if not isinstance(note, str) or not note.strip() or len(note.strip()) > 255:
        return jsonify(error="Provide a note of 1 to 255 characters"), 400
    with open_database() as connection:
        with connection.cursor() as cursor:
            cursor.execute("INSERT INTO notes (note) VALUES (%s)", (note.strip(),))
            note_id = cursor.lastrowid
    return jsonify(id=note_id, message="Note saved"), 201


@app.get("/list")
@app.get("/api/list")
@handle_database_errors
def list_notes():
    with open_database() as connection:
        with connection.cursor() as cursor:
            cursor.execute("SELECT id, note FROM notes ORDER BY id DESC LIMIT 100")
            rows = cursor.fetchall()
    response = jsonify(notes=rows)
    response.headers["Cache-Control"] = "no-store"
    return response
