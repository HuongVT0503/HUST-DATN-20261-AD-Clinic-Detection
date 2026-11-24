#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
plot_precision_recall_tradeoff.py

Doc metrics_summary.csv (dau ra cua calculate_confusion_matrix.py) va ve 2 bieu do luu vao figures/:
  1) Dich chuyen V1->V4 tren khong gian Precision-Recall.
  2) Cot so False Positive theo phien ban (truc quan "giam nhieu").

Vi du:
  python3 -I plot_precision_recall_tradeoff.py --metrics metrics_summary.csv --outdir ../figures

"""
import argparse
import os
import sys
import pandas as pd
import matplotlib
matplotlib.use("Agg")  # khong can GUI
import matplotlib.pyplot as plt


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--metrics", default="metrics_summary.csv")
    ap.add_argument("--outdir", default="../figures")
    args = ap.parse_args()

    if not os.path.exists(args.metrics):
        sys.exit(f"[!] Khong thay {args.metrics}. Chay calculate_confusion_matrix.py truoc.")
    df = pd.read_csv(args.metrics)
    for c in ("rule_version", "precision", "recall", "FP"):
        if c not in df.columns:
            sys.exit(f"[!] {args.metrics} thieu cot '{c}'.")
    df = df.sort_values("rule_version").reset_index(drop=True)
    os.makedirs(args.outdir, exist_ok=True)

    # --- Bieu do 1: PR space ---
    fig, ax = plt.subplots(figsize=(6, 5))
    ax.plot(df["recall"], df["precision"], "-o", color="#2563eb")
    for _, r in df.iterrows():
        ax.annotate(str(r["rule_version"]), (r["recall"], r["precision"]),
                    textcoords="offset points", xytext=(6, 6))
    ax.set_xlabel("Recall")
    ax.set_ylabel("Precision")
    ax.set_title("Dich chuyen V1->V4 tren khong gian Precision-Recall")
    ax.set_xlim(-0.02, 1.05); ax.set_ylim(-0.02, 1.05)
    ax.grid(True, alpha=0.3)
    p1 = os.path.join(args.outdir, "precision_recall_tradeoff.png")
    fig.tight_layout(); fig.savefig(p1, dpi=150); plt.close(fig)

    # --- Bieu do 2: FP theo phien ban ---
    fig, ax = plt.subplots(figsize=(6, 4))
    ax.bar(df["rule_version"].astype(str), df["FP"], color="#dc2626")
    for i, v in enumerate(df["FP"]):
        ax.text(i, v, str(v), ha="center", va="bottom")
    ax.set_xlabel("Phien ban luat")
    ax.set_ylabel("So canh bao gia (FP)")
    ax.set_title("So luong False Positive theo phien ban")
    p2 = os.path.join(args.outdir, "false_positive_by_version.png")
    fig.tight_layout(); fig.savefig(p2, dpi=150); plt.close(fig)

    print(f"[+] Da luu:\n    {p1}\n    {p2}")


if __name__ == "__main__":
    main()
