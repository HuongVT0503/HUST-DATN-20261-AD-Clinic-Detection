#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Tep: 01_clinic_lab_and_noise/log_anonymizer/anonymize_sensitive_emr_logs.py
Mo ta: An danh hoa du lieu ca nhan nhay cam (So CCCD, Ma the BHYT, Ho ten benh nhan) trong nhat ky kiem toan theo Luat BVDLCN 91/2025/QH15 va Nghi dinh 356/2025/ND-CP (hieu luc 01/01/2026).

HAI CHE DO:
  1) Text/JSON/CSV:   -i input.json -o output.json
  2) .evtx truc tiep:        --evtx input.evtx -o output_sanitized.jsonl
     -> doc tung ban ghi .evtx, trich XML, an danh hoa, ghi ra JSONL (1 ban ghi/dong).

LUU Y:
  - Che do --evtx tao ra DU LIEU DA SACH de CHIA SE/LUU TRU (vd phat hanh dataset mau). Nhung neu nap JSONL nay bang Filebeat thi SE MAT anh xa truong ECS cua Winlogbeat (winlog.event_data.*),
    lam hong cac KQL dang dung. => Chi dung --evtx cho muc dich chia se dataset sach.
  - De "an danh TRONG pipeline ma VAN giu truong ECS" (khuyen dung cho SIEM): dung ES INGEST PIPELINE
    'emr-anonymize' (file 03_siem_rules_v1_to_v4/elk_docker_wsl2/emr_anonymize_ingest_pipeline.json),
    tro winlogbeat output.elasticsearch.pipeline toi no. Winlogbeat KHONG chay duoc script Python nay,
    nen viec "goi .py trong winlogbeat config" la KHONG the; thay vao do winlogbeat goi ingest pipeline.

Phu thuoc che do --evtx: pip install python-evtx  (hoac co 'evtx_dump' trong PATH).
"""
import argparse
import hashlib
import json
import re
import sys
from pathlib import Path

SALT_SECRET = "HUST_DATN_20261_PDPL_91_2025_QH15_SALT"

# So CCCD: 12 chu so bat dau bang 0 (chuan CCCD Viet Nam).
REGEX_CCCD = re.compile(r"\b(0\d{11})\b")
# Ma the BHYT: 2 chu cai + 13 chu so = 15 ky tu (khop Init_HIS_EMR_Schema.sql).
REGEX_BHYT = re.compile(r"\b([A-Z]{2}\d{13})\b")
REGEX_PATIENT_NAME = re.compile(
    r"(Nguyễn Văn An|Trần Thị Bình|Lê Hoàng Cường|Phạm Minh Dũng|Hoàng Thu Hà|"
    r"Vũ Quốc Khánh|Đặng Ngọc Lan|Bùi Xuân Mạnh|NGUYEN VAN BENH NHAN)\s*\(\d+\)",
    re.IGNORECASE,
)


def sha256_pseudonymize(raw_value: str, prefix: str) -> str:
    digest = hashlib.sha256(f"{SALT_SECRET}:{raw_value}".encode("utf-8")).hexdigest()[:10]
    return f"<{prefix}_ANON_{digest.upper()}>"


def anonymize_text_content(content: str) -> str:
    content = REGEX_CCCD.sub(lambda m: sha256_pseudonymize(m.group(1), "CCCD"), content)
    content = REGEX_BHYT.sub(lambda m: sha256_pseudonymize(m.group(1), "BHYT"), content)
    content = REGEX_PATIENT_NAME.sub(lambda m: sha256_pseudonymize(m.group(0), "PATIENT"), content)
    return content


def process_log_file(input_path: Path, output_path: Path) -> None:
    raw_text = input_path.read_text(encoding="utf-8", errors="ignore")
    output_path.write_text(anonymize_text_content(raw_text), encoding="utf-8")
    print(f"[+] Da an danh hoa (text) theo Luat BVDLCN 91/2025/QH15: {output_path}")


def process_evtx(input_path: Path, output_path: Path) -> None:
    """Doc .evtx -> an danh hoa XML tung ban ghi -> ghi JSONL {record_xml: <sanitized>}."""
    try:
        from Evtx.Evtx import Evtx  # package: python-evtx
    except ImportError:
        sys.exit("[!] Thieu python-evtx. Chay: pip install python-evtx  (hoac dung 'evtx_dump' rieng).")
    n = 0
    with Evtx(str(input_path)) as log, output_path.open("w", encoding="utf-8") as out:
        for record in log.records():
            xml = record.xml()
            out.write(json.dumps({"record_xml": anonymize_text_content(xml)}, ensure_ascii=False) + "\n")
            n += 1
    print(f"[+] Da an danh hoa {n} ban ghi .evtx -> {output_path} (JSONL).")
    print("    Luu y: JSONL nay DA MAT anh xa ECS cua Winlogbeat - chi dung de CHIA SE dataset sach.")


def main():
    ap = argparse.ArgumentParser(description="An danh hoa du lieu benh an nhay cam truoc khi nap/chia se.")
    ap.add_argument("-i", "--input", help="Tep log text/JSON/CSV dau vao")
    ap.add_argument("--evtx", help="Tep .evtx dau vao (che do moi)")
    ap.add_argument("-o", "--output", help="Tep dau ra")
    args = ap.parse_args()

    if args.evtx:
        if not args.output:
            sys.exit("[!] Che do --evtx can -o <output.jsonl>.")
        process_evtx(Path(args.evtx), Path(args.output))
    elif args.input and args.output:
        process_log_file(Path(args.input), Path(args.output))
    else:
        # Self-test demo
        sample = (
            "EventID=33205 | server_principal_name=CLINIC\\SVC_HIS_Database | "
            "statement=SELECT MaBenhAn, SoCCCD='001204100001', MaTheBHYT='DN4010120000001', "
            "HoTen=N'Nguyễn Văn An (1)' FROM HIS_ClinicDB.dbo.HoSoBenhAn;"
        )
        print("[*] Goc:   ", sample)
        print("[*] An danh:", anonymize_text_content(sample))


if __name__ == "__main__":
    main()
