# Cơ sở Toán học về Nghịch lý Tỷ lệ Cơ sở (Base-Rate Fallacy) trong Phát hiện Xâm nhập

> **Tài liệu học thuật gốc:** Stefan Axelsson (1999), *"The Base-Rate Fallacy and the Difficulty of Intrusion Detection"*, ACM Transactions on Information and System Security (TISSEC), Vol. 3, No. 3, pp. 186–205[cite: 1].

---

## 1. Bản chất Toán học theo Định lý Bayes trong Môi trường Y tế

Trong một phòng khám đa khoa quy mô vừa (~200 nhân sự), lưu lượng sự kiện hợp lệ $B$ (Benign: y bác sĩ đăng nhập đổi ca, phần mềm HIS đồng bộ XML BHYT, tra cứu bệnh án) chiếm tỷ trọng tuyệt đối so với số lượng sự kiện tấn công thực sự $I$ (Intrusion).

Gọi:
* $P(I)$ là xác suất tiên nghiệm (Base Rate) của một hành vi tấn công trong tổng tập nhật ký ($N = 100,000$ sự kiện).
* $P(A \mid I) = \text{Recall}$ (True Positive Rate): Xác suất hệ thống SIEM sinh cảnh báo $A$ khi có tấn công $I$.
* $P(A \mid \neg I) = \text{FPR}$ (False Positive Rate): Xác suất hệ thống SIEM báo động nhầm trên một sự kiện hợp lệ $\neg I$.

Theo định lý Bayes, xác suất một cảnh báo sinh ra trên màn hình SOC thực sự là tấn công — chính là chỉ số **Precision** $P(I \mid A)$ — được xác định bởi:

$$P(I \mid A) = \text{Precision} = \frac{P(I) \cdot P(A \mid I)}{P(I) \cdot P(A \mid I) + P(\neg I) \cdot P(A \mid \neg I)} = \frac{TP}{TP + FP}$$

## 2. Giải thích Hiện tượng Quá tải Cảnh báo (Alert Fatigue) ở Phiên bản Luật V2

Ở phiên bản **Luật V2 (Nới lỏng để bắt lẩn tránh)**, để đạt được $\text{Recall} = 100\%$ ($TP = 3, FN = 0$), bộ luật đã mở rộng điều kiện bắt trên toàn bộ `Event ID 1644`, `4769` và `33205`. Dù tỷ lệ báo động sai trên tổng số dòng log bình thường chỉ là:

$$\text{FPR}_{V2} = \frac{5,420}{99,997} \approx 5.42\%$$

Nhưng do mẫu số lưu lượng nền hợp lệ quá lớn ($99,997$ sự kiện), số lượng cảnh báo giả tuyệt đối ($FP = 5,420$) áp đảo hoàn toàn số cảnh báo thật ($TP = 3$), kéo chỉ số **Precision** tụt xuống mức:

$$\text{Precision}_{V2} = \frac{3}{3 + 5,420} \approx 0.0553\% \approx 0.06\%$$

Đây chính là minh chứng thực nghiệm của **Nghịch lý Base-Rate (Axelsson, 1999)**: để một hệ thống SIEM khả dụng cho đội ngũ IT kiêm nhiệm (2–3 người) tại phòng khám, việc **tối thiểu hóa mẫu số $FP$ thông qua ngưỡng cửa sổ trượt (V3) và bộ lọc ngữ cảnh nghiệp vụ (V4)** là yêu cầu bắt buộc.