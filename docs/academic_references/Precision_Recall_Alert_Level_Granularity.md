# Precision, Recall, đơn vị đếm ở mức cảnh báo (Alert-Level Granularity)

// chốt cách định nghĩa và đếm TP/FP/FN xuyên suốt 4 phiên bản luật, giải thích vì sao đếm ở mức cảnh báo chứ không phải mức log thô. Các con số minh họa cụ thể: xem bảng ở Base_Rate_Fallacy_Axelsson1999.md (không chép lại số ở đây).

## 1. Hai mức đếm: event-level và alert-level

Khi đánh giá trên tập 100.000 sự kiện .evtx, có hai cách đếm:

- Event-level: đếm từng dòng log khớp điều kiện.
- Alert-level (gộp nhóm): đếm số cảnh báo đẩy lên dashboard sau khi SIEM đã gom nhóm sự kiện theo cửa sổ thời gian (event aggregation).

Trong đồ án này tôi chuẩn hóa theo alert-level cho cả V1 đến V4, vì đây là con số mà nhân sự IT phòng khám thật sự phải xử lý mỗi sáng. Đây là lựa chọn có chủ đích, không phải mặc định.
"sao 100.000 log mà TP chỉ có 3" -> 1 chuỗi tấn công sau khi gộp sinh ra 1 cảnh báo gộp, nên TP tối đa bằng số kịch bản (3).
[Trong quyển phải chú thích: "đơn vị của TP, FP, FN là số lượng cảnh báo (alerts) sau event aggregation".]

## 2. Bốn thành phần và công thức

- TP: số kịch bản tấn công bị phát hiện đúng (tối đa 3).
- FN: số kịch bản lẩn tránh bị bỏ lọt (không sinh cảnh báo).
- FP: số cảnh báo nhầm sinh ra từ lưu lượng nghiệp vụ hợp lệ.
- TN: số sự kiện hợp lệ được bỏ qua chính xác.

Công thức:

    Precision = TP / (TP + FP)
    Recall    = TP / (TP + FN)
    Giam FP so voi V2 (%) = (FP_V2 - FP_Vi) / FP_V2 * 100

TN được định nghĩa cho đủ 4 ô của ma trận nhầm lẫn, nhưng không đưa vào công thức Precision/Recall. Lý do nằm ở nghịch lý Base-Rate (xem file Base_Rate_Fallacy): TN trong SOC là con số khổng lồ, nếu đưa vào các độ đo như Accuracy sẽ làm sai lệch hoàn toàn bức tranh, nên vận hành SOC chỉ dùng TP, FP, FN.

## 3. Vì sao dùng PR curve chứ không ROC

Với dữ liệu cực kì mất cân bằng (tấn công hiếm, nền hợp lệ áp đảo), đường ROC dễ gây hiểu nhầm vì FPR được chia cho mẫu số TN khổng lồ. Đường Precision-Recall phản ánh đúng hơn vì Precision dựa trên tỉ lệ TP trong số cảnh báo đẩy ra. Đây là lý do tôi trình bày sự dịch chuyển V1 đến V4 trên không gian PR. Source:

- J. Davis and M. Goadrich, "The Relationship Between Precision-Recall and ROC Curves", ICML 2006, pp. 233-240. DOI: 10.1145/1143844.1143874. Link PDF: https://www.biostat.wisc.edu/~page/rocpr.pdf
- T. Saito and M. Rehmsmeier, "The Precision-Recall Plot Is More Informative than the ROC Plot When Evaluating Binary Classifiers on Imbalanced Datasets", PLOS ONE 10(3): e0118432, 2015. DOI: 10.1371/journal.pone.0118432. Link: https://journals.plos.org/plosone/article?id=10.1371/journal.pone.0118432

[trong SOC thường ưu tiên Recall hơn Precision (bỏ lọt tấn công nguy hiểm hơn báo thừa), nên có thể cân nhắc F-beta với beta > 1 thay vì F1 khi tổng hợp. Note khi có số thật.]

## 4. lý thuyết ma trận nhầm lẫn và bối cảnh SOC

- Confusion Matrix, Precision, Recall: bất kỳ giáo trình học máy nào, hoặc tài liệu scikit-learn (https://scikit-learn.org/stable/modules/model_evaluation.html) đủ để trích định nghĩa gốc.
- Alert fatigue và lọc cảnh báo: W. U. Hassan et al., "NoDoze: Combatting Threat Alert Fatigue with Automated Provenance Triage", NDSS 2019. Link: https://www.ndss-symposium.org/ndss-paper/nodoze-combatting-threat-alert-fatigue-with-automated-provenance-triage/
- Góc Detection Engineering thực tiễn: SpecterOps "Funnel of Fidelity" (Jared Atkinson) và blog Anton Chuvakin về "Detection as Code" và đo lường SOC metrics.
