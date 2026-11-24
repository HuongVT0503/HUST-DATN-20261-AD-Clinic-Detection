#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
calculate_confusion_matrix.py

Tu cac file canh bao DA GAN NHAN (output of label_alerts_from_ground_truth.py), tinh Confusion
Matrix o MUC ALERT-LEVEL/KICH BAN cho tung phien ban luat V1-V4 va xuat bang so sanh (Trade-off).

ĐINH NGHIA DUNG TRONG DO AN:
  - Don vi dem la SO LUONG CANH BAO (alerts) sau khi gom nhom su kien (event aggregation).
  - TP = so KICH BAN tan cong bi phat hien dung (moi kich bao co >=1 canh bao TP -> tinh 1). Toi da = so kich ban.
  - FN = so kich ban tan cong bi bo lot (khong co canh bao TP nao).
  - FP = so canh bao nham sinh tu luu luong nghiep vu hop le (dem RAW; phan anh khoi luong cong viec du thua cua IT).
  - TN: khong cho vao cong thuc (xem Base_Rate_Fallacy): Precision = TP/(TP+FP); Recall = TP/(TP+FN).

ĐAU VAO:
  --labeled   Mot/nhieu CSV da gan nhan. Moi file phai co cot: rule_version, label (TP/FP), matched_scenario. (Chay label_... cho tung alerts_iteration_v*.csv truoc.)
  --scenarios So kich ban tan cong co the phat hien (mac dinh 3). Dung lam mau so cua Recall.  (Hoac truyen --scenario-list SC1 SC2 SC3 de liet ke ro.)

ĐAU RA:
  --out       metrics_summary.csv (rule_version, TP, FN, FP, precision, recall) - de plot doc.

Vi du:
  python3 -I calculate_confusion_matrix.py \
      --labeled alerts_iteration_v1_labeled.csv alerts_iteration_v2_labeled.csv \
                alerts_iteration_v3_labeled.csv alerts_iteration_v4_labeled.csv \
      --scenario-list SC1 SC2 SC3 --out metrics_summary.csv
"""
import argparse
import sys
import pandas as pd


def fam(x):
    return str(x).split("-")[0].strip().upper()


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--labeled", nargs="+", required=True)
    ap.add_argument("--scenarios", type=int, default=3)
    ap.add_argument("--scenario-list", nargs="*", default=None,
                    help="Danh sach kich ban (vd SC1 SC2 SC3). Neu co, mau so Recall = do dai list.")
    ap.add_argument("--out", default="metrics_summary.csv")
    args = ap.parse_args()

    frames = []
    for f in args.labeled:
        df = pd.read_csv(f)
        for c in ("rule_version", "label"):
            if c not in df.columns:
                sys.exit(f"[!] {f} thieu cot '{c}' (chay label_alerts_from_ground_truth.py truoc).")
        if "matched_scenario" not in df.columns:
            df["matched_scenario"] = ""
        frames.append(df)
    data = pd.concat(frames, ignore_index=True)

    scen_set = set(s.upper() for s in args.scenario_list) if args.scenario_list else None
    total_scen = len(scen_set) if scen_set else args.scenarios

    rows = []
    for ver, g in data.groupby("rule_version"):
        tp_alerts = (g["label"] == "TP").sum()
        fp = int((g["label"] == "FP").sum())
        # Gop TP ve muc kich ban: moi nhom kich ban co >=1 TP -> phat hien
        detected = set(fam(s) for s in g.loc[g["label"] == "TP", "matched_scenario"] if str(s).strip())
        if scen_set:
            detected &= scen_set
        tp = len(detected)
        fn = total_scen - tp
        precision = tp / (tp + fp) if (tp + fp) > 0 else 0.0
        recall = tp / (tp + fn) if (tp + fn) > 0 else 0.0
        rows.append({
            "rule_version": ver,
            "TP": tp, "FN": fn, "FP": fp,
            "TP_alerts_raw": int(tp_alerts),
            "precision": round(precision, 4),
            "recall": round(recall, 4),
            "scenarios_detected": ",".join(sorted(detected)) if detected else "",
        })

    out = pd.DataFrame(rows).sort_values("rule_version").reset_index(drop=True)
    out.to_csv(args.out, index=False)
    pd.set_option("display.width", 140)
    print("[+] Bang Trade-off (alert-level):")
    print(out.to_string(index=False))
    print(f"\n[+] Da ghi {args.out}")
    print(f"    (Mau so Recall = {total_scen} kich ban. TP_alerts_raw = so dong canh bao trung,")
    print("     chi de tham khao; TP dung trong Precision/Recall la so KICH BAN phat hien.)")


if __name__ == "__main__":
    main()
