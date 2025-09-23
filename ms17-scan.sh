#!/usr/bin/env bash
# run-ms17-scan.sh
# Usage:
#   ./run-ms17-scan.sh [network] [nse_path]
# Examples:
#   ./run-ms17-scan.sh                    # uses defaults
#   ./run-ms17-scan.sh 10.120.24.0/24
#   ./run-ms17-scan.sh 10.120.24.0/24 /root/smb-vuln-ms17-010.nse

set -eo pipefail

# Defaults
NETWORK="${1:-10.120.24.0/24}"
NSE_PATH="${2:-/root/smb-vuln-ms17-010.nse}"
NMAP_BIN="${NMAP_BIN:-nmap}"

# Basic checks
if ! command -v "$NMAP_BIN" >/dev/null 2>&1; then
  echo "ERROR: nmap not found in PATH. Install nmap or set NMAP_BIN to its path." >&2
  exit 2
fi

if [ ! -f "$NSE_PATH" ]; then
  echo "ERROR: NSE script not found at: $NSE_PATH" >&2
  exit 3
fi

# sanitize network string for filename (replace / with -)
SAFE_NET="${NETWORK//\//-}"
OUTFILE="ms17-010-${SAFE_NET}-range.txt"

echo "Running: $NMAP_BIN -p445 --script=${NSE_PATH} ${NETWORK} -Pn"
echo "Output -> ${OUTFILE}"
echo

# Run nmap and tee to file
# Use --min-rate or other nmap options if you need tuning
"$NMAP_BIN" -p445 --script="${NSE_PATH}" "${NETWORK}" -Pn | tee "${OUTFILE}"
RC=${PIPESTATUS[0]:-0}

if [ "$RC" -ne 0 ]; then
  echo "nmap exited with code $RC" >&2
else
  echo "nmap completed successfully."
fi

exit "$RC"
