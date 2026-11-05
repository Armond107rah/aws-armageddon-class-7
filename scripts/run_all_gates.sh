TF_DIR="${TF_DIR:-.}"
RESULTS_DIR="${RESULTS_DIR:-./scripts-results}"

REGION="${REGION:-us-east-1}"

# Manual overrides (optional)
INSTANCE_ID="${INSTANCE_ID:-}"
SECRET_ARN="${SECRET_ARN:-}"
DB_ID="${DB_ID:-}"

# Optional behavior toggles
REQUIRE_ROTATION="${REQUIRE_ROTATION:-false}"
CHECK_SECRET_POLICY_WILDCARD="${CHECK_SECRET_POLICY_WILDCARD:-true}"
EXPECTED_ROLE_NAME="${EXPECTED_ROLE_NAME:-lab-1c-ec2-role01}"
CHECK_PRIVATE_SUBNETS="${CHECK_PRIVATE_SUBNETS:-true}"

# Final output file
OUT_JSON="${OUT_JSON:-${RESULTS_DIR}/run_all_gates.json}"

# ----------------------------
# Helpers
# ----------------------------
now_utc() {
  date -u +"%Y-%m-%dT%H:%M:%SZ"
}

have_file() {
  [[ -f "$1" ]]
}

require_cmd() {
  command -v "$1" >/dev/null 2>&1 || {
    echo "ERROR: Required command '$1' is not installed or not on PATH." >&2
    exit 1
  }
}

badge_color() {
  local status="$1"
  local warnings="$2"

  if [[ "$status" == "FAIL" ]]; then
    echo "RED"
    return
  fi

  if [[ "$warnings" -gt 0 ]]; then
    echo "YELLOW"
    return
  fi

  echo "GREEN"
}

read_tf_output() {
  local output_name="$1"
  terraform -chdir="$TF_DIR" output -raw "$output_name" 2>/dev/null || true
}

# ----------------------------
# Preconditions
# ----------------------------
require_cmd jq
require_cmd aws

mkdir -p "$RESULTS_DIR"

if have_file "${TF_DIR}/terraform.tfstate" || have_file "${TF_DIR}/.terraform"; then
  if command -v terraform >/dev/null 2>&1; then
    echo "INFO: Terraform detected. Attempting to auto-read outputs..."
  fi
fi

# Auto-discover from Terraform outputs if not explicitly set
if [[ -z "$INSTANCE_ID" ]]; then
  INSTANCE_ID="$(read_tf_output ec2_instance_id)"
fi

if [[ -z "$SECRET_ARN" ]]; then
  SECRET_ARN="$(read_tf_output secret_arn)"
fi

if [[ -z "$DB_ID" ]]; then
  DB_ID="$(read_tf_output rds_identifier)"
fi

# Validation
if [[ -z "$INSTANCE_ID" || -z "$SECRET_ARN" || -z "$DB_ID" ]]; then
  echo "ERROR: Missing required values." >&2
  echo "Resolved values:" >&2
  echo "  REGION      = ${REGION}" >&2
  echo "  INSTANCE_ID = ${INSTANCE_ID:-<empty>}" >&2
  echo "  SECRET_ARN  = ${SECRET_ARN:-<empty>}" >&2
  echo "  DB_ID       = ${DB_ID:-<empty>}" >&2
  echo "" >&2
  echo "Fix one of the following:" >&2
  echo "1. Run terraform apply first so outputs exist" >&2
  echo "2. Export env vars manually:" >&2
  echo "   REGION=us-east-1 INSTANCE_ID=i-xxxx SECRET_ARN=arn:aws:secretsmanager:... DB_ID=lab-1c-mysql ./scripts/run_all_gates.sh" >&2
  exit 1
fi

if ! have_file "./scripts/gate_secrets_and_role.sh" || ! have_file "./scripts/gate_network_db.sh"; then
  echo "ERROR: Missing required gate scripts in ./scripts/" >&2
  echo "Expected:" >&2
  echo "  ./scripts/gate_secrets_and_role.sh" >&2
  echo "  ./scripts/gate_network_db.sh" >&2
  exit 1
fi

chmod +x ./scripts/gate_secrets_and_role.sh ./scripts/gate_network_db.sh || true

# ----------------------------
# Run Gate 1: Secrets + Role
# ----------------------------
echo "=== Running Gate 1/2: secrets_and_role ==="
set +e
OUT_JSON="${RESULTS_DIR}/run_all_gates_gate1.json" \
REGION="$REGION" \
INSTANCE_ID="$INSTANCE_ID" \
SECRET_ARN="$SECRET_ARN" \
REQUIRE_ROTATION="$REQUIRE_ROTATION" \
CHECK_SECRET_POLICY_WILDCARD="$CHECK_SECRET_POLICY_WILDCARD" \
EXPECTED_ROLE_NAME="$EXPECTED_ROLE_NAME" \
./scripts/gate_secrets_and_role.sh
rc1=$?
set -e

# ----------------------------
# Run Gate 2: Network + DB
# ----------------------------
echo "=== Running Gate 2/2: network_db ==="
set +e
OUT_JSON="${RESULTS_DIR}/run_all_gates_gate2.json" \
REGION="$REGION" \
INSTANCE_ID="$INSTANCE_ID" \
DB_ID="$DB_ID" \
CHECK_PRIVATE_SUBNETS="$CHECK_PRIVATE_SUBNETS" \
./scripts/gate_network_db.sh
rc2=$?
set -e

# ----------------------------
# Determine overall result
# ----------------------------
overall_exit=0
overall_status="PASS"

if [[ "$rc1" -ne 0 || "$rc2" -ne 0 ]]; then
  overall_status="FAIL"
  overall_exit=2
fi

# Best-effort warning detection
warn_count=0

if [[ -f "${RESULTS_DIR}/run_all_gates_gate1.json" ]]; then
  if jq -e '.warnings | length > 0' "${RESULTS_DIR}/run_all_gates_gate1.json" >/dev/null 2>&1; then
    warn_count=$((warn_count + 1))
  fi
fi

if [[ -f "${RESULTS_DIR}/run_all_gates_gate2.json" ]]; then
  if jq -e '.warnings | length > 0' "${RESULTS_DIR}/run_all_gates_gate2.json" >/dev/null 2>&1; then
    warn_count=$((warn_count + 1))
  fi
fi

badge="$(badge_color "$overall_status" "$warn_count")"
timestamp="$(now_utc)"

# ----------------------------
# Write combined report
# ----------------------------
jq -n \
  --arg gate "all_gates" \
  --arg ts "$timestamp" \
  --arg region "$REGION" \
  --arg instance_id "$INSTANCE_ID" \
  --arg secret_arn "$SECRET_ARN" \
  --arg db_id "$DB_ID" \
  --arg badge "$badge" \
  --arg overall_status "$overall_status" \
  --argjson overall_exit "$overall_exit" \
  --argjson rc1 "$rc1" \
  --argjson rc2 "$rc2" \
  '{
    gate: $gate,
    timestamp_utc: $ts,
    region: $region,
    inputs: {
      instance_id: $instance_id,
      secret_arn: $secret_arn,
      db_id: $db_id
    },
    child_gates: [
      {
        name: "secrets_and_role",
        script: "gate_secrets_and_role.sh",
        result_file: "scripts-results/run_all_gates_gate1.json",
        exit_code: $rc1
      },
      {
        name: "network_db",
        script: "gate_network_db.sh",
        result_file: "scripts-results/run_all_gates_gate2.json",
        exit_code: $rc2
      }
    ],
    badge: {
      status: $badge,
      meaning: "GREEN=all pass, YELLOW=pass with warnings, RED=one or more failures"
    },
    status: $overall_status,
    exit_code: $overall_exit
  }' > "$OUT_JSON"

# ----------------------------
# Console Summary
# ----------------------------
echo ""
echo "===== Combined Gate Summary ====="
echo "Region:                    $REGION"
echo "Instance ID:               $INSTANCE_ID"
echo "Secret ARN:                $SECRET_ARN"
echo "DB Identifier:             $DB_ID"
echo "---------------------------------"
echo "Gate 1 exit (secrets/role): $rc1"
echo "Gate 2 exit (network/db):   $rc2"
echo "---------------------------------"
echo "Badge:                     $badge"
echo "Overall Result:            $overall_status"
echo "Combined Report:           $OUT_JSON"
echo "================================="
echo ""

exit "$overall_exit"