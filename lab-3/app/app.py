
"""Lab 3 Tokyo application: SSM + Secrets Manager + TLS RDS MySQL."""

import json
import logging
import os
import ssl

from datetime import datetime, timezone
from functools import wraps

import boto3
import pymysql

from botocore.exceptions import BotoCoreError, ClientError
from flask import Flask, jsonify, request


# -------------------------------------------
# 1. Tokyo application configuration
# -------------------------------------------

REGION = os.environ.get(
    "AWS_REGION",
    "ap-northeast-1"
)

PREFIX = os.environ.get(
    "PARAMETER_PREFIX",
    "/lab3/tokyo/db"
).rstrip("/")

DB_ID = os.environ.get(
    "DB_INSTANCE_IDENTIFIER",
    "shinjuku-lab3-mysql"
)

RDS_CA_BUNDLE = os.environ.get(
    "RDS_CA_BUNDLE",
    "/etc/pki/rds/global-bundle.pem"
)


app = Flask(__name__)
logging.basicConfig(level=logging.INFO)

ssm = boto3.client("ssm", region_name=REGION)

secrets = boto3.client(
    "secretsmanager",
    region_name=REGION
)

cloudwatch = boto3.client(
    "cloudwatch",
    region_name=REGION
)


# -------------------------------------------
# 2. Avoid caching database API responses
# -------------------------------------------

@app.after_request
def prevent_sensitive_caching(response):
    if request.path != "/static/example.txt":
        response.headers["Cache-Control"] = "no-store"

    return response


# -------------------------------------------
# 3. Retrieve database configuration
# -------------------------------------------

def database_settings():

    required = [
        "endpoint",
        "port",
        "name",
        "master-secret-arn"
    ]

    names = [
        f"{PREFIX}/{key}"
        for key in required
    ]

    result = ssm.get_parameters(
        Names=names,
        WithDecryption=False
    )

    values = {
        item["Name"]: item["Value"]
        for item in result["Parameters"]
    }

    missing = [
        name
        for name in names
        if name not in values
    ]

    if missing:
        app.logger.error(
            "Missing database configuration parameters"
        )

        raise KeyError(
            "Missing database configuration"
        )

    secret = secrets.get_secret_value(
        SecretId=values[
            f"{PREFIX}/master-secret-arn"
        ]
    )

    credentials = json.loads(
        secret["SecretString"]
    )

    return {
        "host": values[f"{PREFIX}/endpoint"],
        "port": int(values[f"{PREFIX}/port"]),
        "database": values[f"{PREFIX}/name"],
        "user": credentials["username"],
        "password": credentials["password"]
    }


# -------------------------------------------
# 4. Establish verified TLS connection
# -------------------------------------------

def open_database():

    config = database_settings()

    # Load the trusted AWS RDS certificate bundle.
    # Fail if the bundle is missing or invalid.

    tls_context = ssl.create_default_context(
        cafile=RDS_CA_BUNDLE
    )

    # Require TLS 1.2 or later.

    tls_context.minimum_version = (
        ssl.TLSVersion.TLSv1_2
    )

    # Verify the certificate and database hostname.

    tls_context.verify_mode = ssl.CERT_REQUIRED
    tls_context.check_hostname = True

    return pymysql.connect(
        **config,
        ssl=tls_context,
        charset="utf8mb4",
        cursorclass=pymysql.cursors.DictCursor,
        autocommit=True,
        connect_timeout=5,
        read_timeout=5,
        write_timeout=5
    )


# -------------------------------------------
# 5. Database monitoring
# -------------------------------------------

def record_connection_failure():

    try:
        cloudwatch.put_metric_data(
            Namespace="Lab3/TokyoDatabase",
            MetricData=[
                {
                    "MetricName": "DBConnectionErrors",
                    "Dimensions": [
                        {
                            "Name": "DBInstanceIdentifier",
                            "Value": DB_ID
                        }
                    ],
                    "Value": 1,
                    "Unit": "Count"
                }
            ]
        )

    except (ClientError, BotoCoreError) as error:
        app.logger.warning(
            "Metric publication failed: %s",
            type(error).__name__
        )


def handle_database_errors(handler):

    @wraps(handler)
    def wrapped(*args, **kwargs):

        try:
            return handler(*args, **kwargs)

        except (
            ClientError,
            BotoCoreError,
            pymysql.MySQLError,
            KeyError,
            ValueError,
            TypeError,
            OSError
        ) as error:

            # Log error type only.
            # Never log credentials or patient data.

            app.logger.error(
                "Database operation failed: %s",
                type(error).__name__
            )

            record_connection_failure()

            return jsonify(
                error="Database temporarily unavailable"
            ), 503

    return wrapped


# -------------------------------------------
# 6. Health and cache-test endpoints
# -------------------------------------------

@app.get("/health")
def health():
    return jsonify(status="ok")


@app.get("/static/example.txt")
def static_cache_example():

    response = app.response_class(
        "AWS Armageddon Lab 3 public cache test\n",
        mimetype="text/plain"
    )

    response.headers["Cache-Control"] = (
        "public, max-age=86400"
    )

    return response


@app.get("/api/cache-test")
def api_cache_test():

    return jsonify(
        message="Dynamic API cache test",
        generated_at=datetime.now(
            timezone.utc
        ).isoformat()
    )


# -------------------------------------------
# 7. Database readiness
# -------------------------------------------

@app.get("/ready")
@handle_database_errors
def ready():

    with open_database() as connection:
        with connection.cursor() as cursor:
            cursor.execute("SELECT 1")

    return jsonify(database="reachable")


# -------------------------------------------
# 8. Initialize synthetic notes table
# -------------------------------------------

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


# -------------------------------------------
# 9. Insert synthetic test records
# -------------------------------------------

@app.post("/add")
@handle_database_errors
def add_note():

    body = request.get_json(silent=True)

    note = (
        body.get("note")
        if isinstance(body, dict)
        else None
    )

    if (
        not isinstance(note, str)
        or not note.strip()
        or len(note.strip()) > 255
    ):
        return jsonify(
            error="Provide a note of 1 to 255 characters"
        ), 400

    with open_database() as connection:
        with connection.cursor() as cursor:

            cursor.execute(
                "INSERT INTO notes (note) VALUES (%s)",
                (note.strip(),)
            )

            note_id = cursor.lastrowid

    return jsonify(
        id=note_id,
        message="Note saved"
    ), 201


# -------------------------------------------
# 10. Retrieve synthetic test records
# -------------------------------------------

@app.get("/list")
@app.get("/api/list")
@handle_database_errors
def list_notes():

    with open_database() as connection:
        with connection.cursor() as cursor:

            cursor.execute(
                "SELECT id, note "
                "FROM notes ORDER BY id DESC LIMIT 100"
            )

            rows = cursor.fetchall()

    return jsonify(notes=rows)
