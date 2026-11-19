# Chuẩn hóa Đơn vị Đo lường Cảnh báo (Alert-Level Granularity) trong Ma trận Nhầm lẫn SIEM

---

## 1. Phân biệt Event-Level và Alert-Level Granularity

Khi đánh giá hiệu năng bộ luật phát hiện trên tập dữ liệu chuẩn $N = 100,000$ sự kiện (`.evtx`), có hai cấp độ đơn vị đo lường:
1. **Cấp độ Sự kiện thô (*Event-level*):** Đếm từng dòng log riêng lẻ khớp điều kiện.
2. **Cấp độ Cảnh báo sinh ra trên SIEM (*Alert-level / Aggregated Incident-level*):** Đếm số lượng cảnh báo (Alerts) đẩy lên bảng điều khiển của nhân viên trực sau khi quy tắc SIEM đã gom nhóm sự kiện theo cửa sổ thời gian.

Trong đồ án này, toàn bộ các thành phần của **Ma trận nhầm lẫn (Confusion Matrix)** qua 4 phiên bản `V1 -> V4` được chuẩn hóa đồng nhất theo **Số lượng Cảnh báo sinh ra trên SIEM (*Alert-level*)**:
* **$TP$ (True Positive):** Số kịch bản/chuỗi tấn công thực tế được hệ thống phát hiện và sinh cảnh báo đúng (Tối đa $TP = 3$ tương ứng với 3 kịch bản kiểm thử).
* **$FN$ (False Negative):** Số kịch bản tấn công lẩn tránh bị bộ luật bỏ lọt hoàn toàn (Không sinh cảnh báo).
* **$FP$ (False Positive):** Số lượng cảnh báo nhầm sinh ra từ lưu lượng nghiệp vụ hợp lệ của phòng khám mà nhân viên IT phải tốn thời gian phân loại.
* **$TN$ (True Negative):** Các sự kiện hợp lệ được hệ thống bỏ qua chính xác (Không sinh cảnh báo rác).

---

## 2. Công thức Thực nghiệm Áp dụng Xuyên suốt Đồ án

$$\text{Precision (\%)} = \frac{TP}{TP + FP} \times 100\%$$

$$\text{Recall (\%)} = \frac{TP}{TP + FN} \times 100\%$$

$$\text{Mức giảm Cảnh báo giả so với V2 (\%)} = \frac{FP_{V2} - FP_{V_i}}{FP_{V2}} \times 100\%$$