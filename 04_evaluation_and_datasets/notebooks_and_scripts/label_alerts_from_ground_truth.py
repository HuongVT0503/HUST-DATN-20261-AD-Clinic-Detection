#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
label_alerts_from_ground_truth.py

Gan nhan tinh (Static Labeling) cho cac canh bao xuat tu SIEM dua tren moc thoi gian ground truth.
Quy uoc (xem README_DATASET_MANIFEST.md): canh bao roi vao khoang [START, END] cua mot pha tan cong
-> True Positive (TP); canh bao ngoai moi khoang tan cong (sinh tu luu luong nen) -> False Positive (FP).

ĐAU VAO:
  --alerts        CSV canh bao xuat tu Kibana (1 dong = 1 canh bao). Can co:
                    - 1 cot thoi gian (mac dinh '@timestamp')
                    - 1 cot cho biet canh bao thuoc phien ban luat nao (mac dinh 'rule_version', vd V1..V4)
                  (Neu moi phien ban xuat 1 file rieng alerts_iteration_v*.csv thi chay script nay
                   cho tung file, truyen --force-version V1/V2/V3/V4.)
  --ground-truth  Mot hoac nhieu CSV dinh dang 'timestamp,scenario,phase' (START/END moi pha).
                  Vi du file WS01 C:\\ground_truth.csv. Voi SC3 (ground_truth_sql.log), hay chuyen
                  thanh CSV cung dinh dang truoc (vd: SC3-P4,START,<SYSDATETIME>).

ĐAU RA:
  --out           CSV giong --alerts nhung them cot: label (TP/FP), matched_scenario, matched_phase.

Vi du:
  python3 -I label_alerts_from_ground_truth.py \
      --alerts alerts_iteration_v1.csv --force-version V1 \
      --ground-truth ground_truth.csv ground_truth_sql.csv \
      --out alerts_iteration_v1_labeled.csv
"""
import argparse
import sys
import pandas as pd


def build_intervals(gt_files):
    """Doc cac file ground truth -> list cac khoang (scenario, start, end)."""
    frames = []
    for f in gt_files:
        df = pd.read_csv(f)
        need = {"timestamp", "scenario", "phase"}
        if not need.issubset(df.columns):
            sys.exit(f"[!] {f} thieu cot {need - set(df.columns)} (can: timestamp,scenario,phase)")
        df["timestamp"] = pd.to_datetime(df["timestamp"], utc=True, errors="coerce")
        frames.append(df)
    gt = pd.concat(frames, ignore_index=True)

    intervals = []
    # Ghep START -> END theo tung scenario, theo thu tu thoi gian
    for scen, g in gt.sort_values("timestamp").groupby("scenario"):
        starts = g[g["phase"].str.upper() == "START"]["timestamp"].tolist()
        ends = g[g["phase"].str.upper() == "END"]["timestamp"].tolist()
        for i, st in enumerate(starts):
            en = ends[i] if i < len(ends) else None
            if en is None:
                print(f"[i] {scen}: START khong co END tuong ung (bo qua khoang {st}).")
                continue
            intervals.append((scen, st, en))
    if not intervals:
        sys.exit("[!] Khong dung duoc khoang tan cong nao tu ground truth. Kiem tra START/END.")
    print(f"[+] Dung duoc {len(intervals)} khoang tan cong:")
    for scen, st, en in intervals:
        print(f"    {scen}: {st} -> {en}")
    return intervals


def scenario_family(scen):
    """SC1-1A, SC1-1B -> 'SC1'. Dung de doi chieu canh bao voi dung nhom kich ban khi can."""
    return str(scen).split("-")[0].strip().upper()


def main():
    ap = argparse.ArgumentParser(description="Gan nhan TP/FP cho canh bao SIEM theo ground truth.")
    ap.add_argument("--alerts", required=True, help="CSV canh bao xuat tu Kibana")
    ap.add_argument("--ground-truth", nargs="+", required=True, help="Mot/nhieu CSV timestamp,scenario,phase")
    ap.add_argument("--out", required=True, help="CSV ket qua co cot label")
    ap.add_argument("--time-col", default="@timestamp", help="Ten cot thoi gian trong file alerts")
    ap.add_argument("--version-col", default="rule_version", help="Ten cot phien ban luat")
    ap.add_argument("--force-version", default=None, help="Gan cung 1 phien ban (vd V1) neu file khong co cot do")
    ap.add_argument("--match-scenario", action="store_true",
                    help="Chi tinh TP khi canh bao trung dung nhom kich ban (can cot 'scenario' trong alerts).")
    args = ap.parse_args()

    intervals = build_intervals(args.ground_truth)

    alerts = pd.read_csv(args.alerts)
    if args.time_col not in alerts.columns:
        sys.exit(f"[!] File alerts khong co cot thoi gian '{args.time_col}'. Dung --time-col de chi dinh.")
    alerts[args.time_col] = pd.to_datetime(alerts[args.time_col], utc=True, errors="coerce")

    if args.force_version:
        alerts["rule_version"] = args.force_version
    elif args.version_col in alerts.columns:
        alerts["rule_version"] = alerts[args.version_col]
    else:
        alerts["rule_version"] = "UNKNOWN"

    labels, matched_scen, matched_phase = [], [], []
    for _, row in alerts.iterrows():
        t = row[args.time_col]
        hit = None
        if pd.notna(t):
            for scen, st, en in intervals:
                if st <= t <= en:
                    if args.match_scenario and "scenario" in alerts.columns:
                        if scenario_family(row.get("scenario", "")) != scenario_family(scen):
                            continue
                    hit = (scen, st, en)
                    break
        if hit:
            labels.append("TP"); matched_scen.append(hit[0]); matched_phase.append(f"{hit[1]}..{hit[2]}")
        else:
            labels.append("FP"); matched_scen.append(""); matched_phase.append("")

    alerts["label"] = labels
    alerts["matched_scenario"] = matched_scen
    alerts["matched_phase"] = matched_phase
    alerts.to_csv(args.out, index=False)

    n_tp = labels.count("TP"); n_fp = labels.count("FP")
    print(f"[+] Da ghi {args.out}: {len(labels)} canh bao -> TP(raw)={n_tp}, FP={n_fp}")
    print("    (TP 'raw' la so DONG canh bao trung khoang tan cong. TP muc alert-level/kich ban")
    print("     se duoc gop o calculate_confusion_matrix.py.)")


if __name__ == "__main__":
    main()
