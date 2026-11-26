
#!/usr/bin/env bash
set -euo pipefail

# Run this script from any directory.
REPO="$(cd "$(dirname "$0")/../.." && pwd)"

APP="$REPO/lab-3/app"
BUILD="$REPO/lab-3/build"
STAGE="$BUILD/stage"

test -f "$APP/app.py"
test -f "$APP/requirements.txt"

# Start with a clean local build directory.
mkdir -p "$BUILD"
rm -rf "$STAGE"
mkdir -p "$STAGE/wheels" "$STAGE/certs"

# Copy our application source.
cp "$APP/app.py" "$STAGE/app.py"
cp "$APP/requirements.txt" "$STAGE/requirements.txt"

# Download the public AWS RDS trust bundle.
curl --fail --location --show-error \
  "https://truststore.pki.rds.amazonaws.com/global/global-bundle.pem" \
  --output "$STAGE/certs/global-bundle.pem"

# Download Linux x86-64 wheels for Python 3.9.
# These downloads happen on your Mac, not EC2.
python3 -m pip download \
  --only-binary=:all: \
  --platform manylinux2014_x86_64 \
  --python-version 39 \
  --implementation cp \
  --abi cp39 \
  --dest "$STAGE/wheels" \
  -r "$APP/requirements.txt"

# Package application, dependencies and CA.
tar -czf "$BUILD/tokyo-app-bundle.tar.gz" \
  -C "$STAGE" .

# Record archive checksum.
shasum -a 256 "$BUILD/tokyo-app-bundle.tar.gz"

echo "PASS: Local Tokyo application bundle created"
echo "Artifact: lab-3/build/tokyo-app-bundle.tar.gz"
