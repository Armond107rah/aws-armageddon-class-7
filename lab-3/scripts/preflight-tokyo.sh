#!/usr/bin/env bash
set -euo pipefail

# Locate repository root.
REPO="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$REPO"

echo "=== LAB 3 TOKYO PRE-DEPLOYMENT REVIEW ==="

# 1. Verify required application and Terraform files.

required_files=(
  "lab-3/app/app.py"
  "lab-3/app/requirements.txt"
  "lab-3/terraform/tokyo/versions.tf"
  "lab-3/terraform/tokyo/compute.tf"
  "lab-3/terraform/tokyo/database.tf"
  "lab-3/terraform/tokyo/bootstrap.sh.tftpl"
  "lab-3/terraform/tokyo/artifact_storage.tf"
  "lab-3/terraform/tokyo/monitoring.tf"
  "lab-3/terraform/modules/database/main.tf"
)

for path in "${required_files[@]}"; do
  if [[ ! -f "$path" ]]; then
    echo "FAIL: Missing $path"
    exit 1
  fi
done

echo "PASS: Required source files exist"

# 2. Verify user-data script format.

bootstrap="lab-3/terraform/tokyo/bootstrap.sh.tftpl"

if [[ "$(head -n 1 "$bootstrap")" != "#!/bin/bash" ]]; then
  echo "FAIL: Bootstrap must begin with #!/bin/bash"
  exit 1
fi

bash -n "$bootstrap"
echo "PASS: Bootstrap script syntax"

# 3. Inspect Python and the deployment archive.

python3 - <<'PY'
import ast
import hashlib
import ssl
import tarfile
from pathlib import Path, PurePosixPath

app = Path("lab-3/app/app.py")
bundle = Path("lab-3/build/tokyo-app-bundle.tar.gz")

ast.parse(app.read_text(encoding="utf-8"))
print("PASS: Python application syntax")

if not bundle.is_file():
    raise SystemExit(
        "FAIL: Build the application bundle first"
    )

with tarfile.open(bundle, "r:gz") as archive:
    files = {}

    for member in archive.getmembers():
        name = member.name
        if name.startswith("./"):
            name = name[2:]

        path = PurePosixPath(name)

        if path.is_absolute() or ".." in path.parts:
            raise SystemExit("FAIL: Unsafe archive path")

        if member.issym() or member.islnk():
            raise SystemExit("FAIL: Archive contains link")

        if member.isfile():
            files[name] = member

    required = {
        "app.py",
        "requirements.txt",
        "certs/global-bundle.pem",
    }

    missing = required - files.keys()

    if missing:
        raise SystemExit(
            f"FAIL: Missing bundle files: {sorted(missing)}"
        )

    wheels = [
        name for name in files
        if name.startswith("wheels/")
        and name.endswith(".whl")
    ]

    if not wheels:
        raise SystemExit("FAIL: No Python wheels found")

    pem = archive.extractfile(
        files["certs/global-bundle.pem"]
    ).read().decode("ascii")

    context = ssl.create_default_context(cadata=pem)

    if not context.get_ca_certs():
        raise SystemExit("FAIL: CA bundle is empty")

    if not context.check_hostname:
        raise SystemExit("FAIL: Hostname checks disabled")

    print("PASS: Application bundle structure")
    print(f"PASS: {len(wheels)} Python wheel files")
    print("PASS: RDS CA certificate bundle loads")

digest = hashlib.sha256(bundle.read_bytes()).hexdigest()
print("Bundle SHA256:", digest)
PY

# 4. Check Terraform formatting.

terraform \
  -chdir="lab-3/terraform/modules/database" \
  fmt -check

terraform \
  -chdir="lab-3/terraform/tokyo" \
  fmt -check

echo "PASS: Terraform formatting"

# 5. Initialize without configuring a backend.

terraform \
  -chdir="lab-3/terraform/tokyo" \
  init -backend=false -input=false

# 6. Validate Terraform configuration.

terraform \
  -chdir="lab-3/terraform/tokyo" \
  validate -no-color

echo "=== LOCAL PREFLIGHT PASSED ==="
echo "No AWS infrastructure was deployed."
