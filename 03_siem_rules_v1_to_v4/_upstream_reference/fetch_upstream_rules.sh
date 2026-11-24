#!/usr/bin/env bash
# Tai ban goc 3 rule baseline (SC1/SC2 Sigma DRL-1.1, SC3 Splunk Apache-2.0).
# KHONG tai rule Elastic (Elastic License v2 - khong duoc redistribute, chi link).
# Chay: bash fetch_upstream_rules.sh   (can curl)
set -euo pipefail
cd "$(dirname "$0")"

declare -A RULES=(
  ["proc_creation_win_hktl_bloodhound_sharphound.yml"]="https://raw.githubusercontent.com/SigmaHQ/sigma/master/rules/windows/process_creation/proc_creation_win_hktl_bloodhound_sharphound.yml"
  ["win_security_susp_rc4_kerberos.yml"]="https://raw.githubusercontent.com/SigmaHQ/sigma/master/rules/windows/builtin/security/win_security_susp_rc4_kerberos.yml"
  ["windows_sqlservr_spawning_shell.yml"]="https://raw.githubusercontent.com/splunk/security_content/develop/detections/endpoint/windows_sqlservr_spawning_shell.yml"
)

for f in "${!RULES[@]}"; do
  echo "[*] $f"
  curl -fsSL "${RULES[$f]}" -o "$f" && echo "    OK" || echo "    LOI - kiem tra lai URL (branch co the doi)"
done

echo "[i] Elastic xp_cmdshell: KHONG tai (Elastic License v2). Xem link trong NOTICE.md."
echo "[+] Xong. Dung git add de commit cac file goc nay."
