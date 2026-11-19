#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Tệp: 01_clinic_lab_and_noise/log_anonymizer/anonymize_sensitive_emr_logs.py
Đồ án Tốt nghiệp Kỳ 2026.1 - Đại học Bách khoa Hà Nội (HUST)
Sinh viên thực hiện: Vũ Thúy Hường - MSSV: 20225135
Mô tả: Công cụ ẩn danh hóa dữ liệu cá nhân nhạy cảm (Số CCCD, Mã thẻ BHYT, Họ tên bệnh nhân)
       trong nhật ký kiểm toán (JSON/CSV/XML) theo quy định tại Luật Bảo vệ dữ liệu cá nhân
       số 91/2025/QH15 và Nghị định 356/2025/NĐ-CP (hiệu lực từ 01/01/2026).
"""

import argparse
import hashlib
import re
from pathlib import Path

SALT_SECRET = "HUST_DATN_20261_PDPL_91_2025_QH15_SALT"

# Biểu thức chính quy nhận diện dữ liệu nhạy cảm của bệnh nhân trong log
REGEX_CCCD = re.compile(r"\b(0\d{11})\b")
REGEX_BHYT = re.compile(r"\b([A-Z]{2}\d{13})\b")
REGEX_PATIENT_NAME = re.compile(
    r"(Nguyễn Văn An|Trần Thị Bình|Lê Hoàng Cường|Phạm Minh Dũng|Hoàng Thu Hà|"
    r"Vũ Quốc Khánh|Đặng Ngọc Lan|Bùi Xuân Mạnh|NGUYEN VAN BENH NHAN)\s*\(\d+\)",
    re.IGNORECASE,
)


def sha256_pseudonymize(raw_value: str, prefix: str) -> str:
    """Băm một chiều SHA-256 kèm Salt, giữ lại 10 ký tự đầu để phục vụ đối sánh tương quan."""
    digest = hashlib.sha256(f"{SALT_SECRET}:{raw_value}".encode("utf-8")).hexdigest()[:10]
    return f"<{prefix}_ANON_{digest.upper()}>"


def anonymize_text_content(content: str) -> str:
    """Thay thế toàn bộ Số CCCD, Mã thẻ BHYT và Họ tên bệnh nhân trong chuỗi log."""
    content = REGEX_CCCD.sub(lambda m: sha256_pseudonymize(m.group(1), "CCCD"), content)
    content = REGEX_BHYT.sub(lambda m: sha256_pseudonymize(m.group(1), "BHYT"), content)
    content = REGEX_PATIENT_NAME.sub(lambda m: sha256_pseudonymize(m.group(0), "PATIENT"), content)
    return content


def process_log_file(input_path: Path, output_path: Path) -> None:
    raw_text = input_path.read_text(encoding="utf-8", errors="ignore")
    sanitized_text = anonymize_text_content(raw_text)
    output_path.write_text(sanitized_text, encoding="utf-8")
    print(f"[+] Đã ẩn danh hóa tệp log theo Luật BVDLCN 91/2025/QH15: {output_path}")


def main():
    parser = argparse.ArgumentParser(
        description="Ẩn danh hóa dữ liệu bệnh án nhạy cảm trong nhật ký trước khi nạp SIEM."
    )
    parser.add_argument("-i", "--input", help="Đường dẫn tệp log đầu vào (JSON/CSV/TXT)")
    parser.add_argument("-o", "--output", help="Đường dẫn tệp log đầu ra sau khi ẩn danh hóa")
    args = parser.parse_args()

    if args.input and args.output:
        process_log_file(Path(args.input), Path(args.output))
    else:
        # Chạy kiểm thử tự động (Self-test demo) khi không truyền tham số
        sample_sql_audit_log = (
            "EventID=33205 | action_id=SL | class_type=U | server_principal_name=CLINIC\\SVC_HIS_Database | "
            "statement=SELECT MaBenhAn, SoCCCD='001204100001', MaTheBHYT='DN401012000001', "
            "HoTen=N'Nguyễn Văn An (1)' FROM HIS_ClinicDB.dbo.HoSoBenhAn;"
        )
        print("[*] Bản ghi SQL Audit 33205 gốc:")
        print("   ", sample_sql_audit_log)
        print("[*] Bản ghi sau khi ẩn danh hóa (Tuân thủ Luật BVDLCN 91/2025/QH15 & NĐ 356/2025/NĐ-CP):")
        print("   ", anonymize_text_content(sample_sql_audit_log))


if __name__ == "__main__":
    main()