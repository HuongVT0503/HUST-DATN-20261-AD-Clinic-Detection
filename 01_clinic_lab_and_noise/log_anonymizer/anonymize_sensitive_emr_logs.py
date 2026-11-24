#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
anonymize_sensitive_emr_logs.py

An danh hoa CCCD / ma the BHYT / ho ten benh nhan trong cac file TEXT/CSV/JSON (Luat BVDLCN
91/2025/QH15, ND 356/2025/ND-CP). Dung cho cac artifact DANG VAN BAN cua do an:
  - CSV canh bao xuat tu Kibana truoc khi cong khai,
  - ground_truth_sql.log, log mau dua vao phu luc quyen,
  - bo dataset .evtx DA CONVERT ra text/JSON de phat hanh.

KHONG xu ly .evtx truc tiep. Ly do: luong nap log song (live) la .evtx -> Winlogbeat -> Elasticsearch,
va viec an danh o luong do do ES INGEST PIPELINE 'emr-anonymize' lam (giu nguyen truong ECS cho luat
KQL chay). Chi tiet kien truc 2 lan: xem README.md cung thu muc.
"""
import argparse
import hashlib
import re
import sys
from pathlib import Path

SALT_SECRET = "HUST_DATN_20261_PDPL_91_2025_QH15_SALT"

REGEX_CCCD = re.compile(r"\b(0\d{11})\b")                 # CCCD 12 so, bat dau 0
REGEX_BHYT = re.compile(r"\b([A-Z]{2}\d{13})\b")          # BHYT 2 chu + 13 so
REGEX_PATIENT_NAME = re.compile(
    r"(Nguyễn Văn An|Trần Thị Bình|Lê Hoàng Cường|Phạm Minh Dũng|Hoàng Thu Hà|"
    r"Vũ Quốc Khánh|Đặng Ngọc Lan|Bùi Xuân Mạnh|NGUYEN VAN BENH NHAN)\s*\(\d+\)",
    re.IGNORECASE,
)


def pseudonymize(raw: str, prefix: str) -> str:
    # Hash co salt, giu 10 ky tu dau de con doi sanh tuong quan giua cac ban ghi.
    digest = hashlib.sha256(f"{SALT_SECRET}:{raw}".encode("utf-8")).hexdigest()[:10]
    return f"<{prefix}_ANON_{digest.upper()}>"


def anonymize(content: str) -> str:
    content = REGEX_CCCD.sub(lambda m: pseudonymize(m.group(1), "CCCD"), content)
    content = REGEX_BHYT.sub(lambda m: pseudonymize(m.group(1), "BHYT"), content)
    content = REGEX_PATIENT_NAME.sub(lambda m: pseudonymize(m.group(0), "PATIENT"), content)
    return content


def main():
    ap = argparse.ArgumentParser(description="An danh hoa file text/CSV/JSON truoc khi cong khai.")
    ap.add_argument("-i", "--input", help="File dau vao (text/CSV/JSON)")
    ap.add_argument("-o", "--output", help="File dau ra")
    args = ap.parse_args()

    if args.input and args.output:
        Path(args.output).write_text(
            anonymize(Path(args.input).read_text(encoding="utf-8", errors="ignore")),
            encoding="utf-8",
        )
        print(f"[+] Da an danh hoa -> {args.output}")
    elif args.input or args.output:
        sys.exit("[!] Can ca -i va -o.")
    else:
        sample = ("statement=SELECT SoCCCD='001204100001', MaTheBHYT='DN4010120000001', "
                  "HoTen=N'Nguyễn Văn An (1)' FROM dbo.HoSoBenhAn;")
        print("[*] Goc:   ", sample)
        print("[*] An danh:", anonymize(sample))


if __name__ == "__main__":
    main()
