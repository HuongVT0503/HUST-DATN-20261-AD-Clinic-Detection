# Base-Rate Fallacy và bài toán báo động giả trong phát hiện xâm nhập

// phần nền lý thuyết cho lập luận "tại sao phải tinh chỉnh luật cho chặt thay vì cứ nới rộng để bắt cho hết".
// File này cũng là nơi DUY NHẤT giữ bộ số minh họa (TP/FP/FN giả định). Các file khác khi cần
// nhắc tới số này thì trỏ về đây, không chép lại, tránh lặp con số y hệt ở nhiều chỗ.
// Số thật sẽ thay vào sau khi chạy replay và đếm TP/FP/FN.

## 1. Nguồn gốc và cách trích dẫn

Có hai bản của cùng một công trình, hay bị trích nhầm năm:

- Bản hội nghị (1999): S. Axelsson, "The Base-Rate Fallacy and its Implications for the Difficulty of Intrusion Detection", Proc. 6th ACM Conf. on Computer and Communications Security (CCS '99), 1999, pp. 1-7.
- Bản tạp chí mở rộng (2000): S. Axelsson, "The Base-Rate Fallacy and the Difficulty of Intrusion Detection", ACM Transactions on Information and System Security (TISSEC), vol. 3, no. 3, 2000, pp. 186-205. DOI: 10.1145/357830.357849.

Trong quyển nên cite bản TISSEC 2000 vì nó đầy đủ và có DOI.

Link đọc:
- Bản tạp chí: https://doi.org/10.1145/357830.357849
- Một bản PDF công khai: https://www.profsandhu.com/cs6393_s20/p186-axelsson.pdf

## 2. Ý chính của Axelsson

Axelsson chỉ ra rằng với một hệ phát hiện xâm nhập, yếu tố quyết định tính khả dụng không phải là tỉ lệ bắt trúng (detection rate) mà là tỉ lệ báo động giả (false alarm rate).
Lý do nằm ở định lý Bayes: trong một hệ thống thực, số sự kiện hợp lệ áp đảo hoàn toàn số sự kiện tấn công, nên xác suất một cảnh báo thực sự là tấn công, tức P(tấn công | cảnh báo), bị kéo xuống rất thấp ngay cả khi luật có độ nhạy cao.

Kết quả đáng nhớ: Axelsson lập luận rằng để P(tấn công | cảnh báo) đạt mức chấp nhận được, tỉ lệ báo động giả phải xuống cỡ 1/100000 hoặc thấp hơn. Đây chính là "base-rate fallacy": con người có xu hướng bỏ qua tỉ lệ nền (base rate) khi ước lượng xác suất.

## 3. Áp vào môi trường phòng khám

Trong phòng khám ~200 nhân sự, lưu lượng hợp lệ B (bác sĩ đăng nhập đổi ca, HIS đồng bộ XML BHYT, tra cứu bệnh án) chiếm gần như toàn bộ tập log, còn sự kiện tấn công I rất hiếm.

Gọi:
- P(I) là tỉ lệ nền của hành vi tấn công trong tổng log.
- P(A|I) = Recall: xác suất sinh cảnh báo khi có tấn công.
- P(A|khong I) = FPR: xác suất báo nhầm trên một sự kiện hợp lệ.

Theo Bayes, độ chính xác của cảnh báo đẩy lên màn hình SOC chính là Precision:

    Precision = P(I | A)
              = [ P(I) * P(A|I) ] / [ P(I) * P(A|I) + P(khong I) * P(A|khong I) ]
              = TP / (TP + FP)

Điểm mấu chốt: vì P(khong I) rất lớn, chỉ cần FPR nhỉnh lên một chút là FP sẽ nhiều hơn TP vô cùng nhiều, khiến Precision rất thấp. Đó là lý do nới luật để tăng Recall gần như luôn phải trả giá bằng Precision.

## 4. Minh họa dự kiến cho luật V2 (CHƯA PHẢI SỐ ĐO THẬT, nguồn số dùng chung cho cả repo)

Ví dụ giả định, trên tập 100.000 sự kiện, nếu V2 bắt trúng cả 3 kịch bản (TP=3, FN=0) nhưng báo nhầm FP=5.420 do bắt luôn hoạt động giao ca và đồng bộ XML BHYT:

- FPR xấp xỉ 5.420 / 99.997 = khoảng 5,42%
- Precision = 3 / (3 + 5.420) = khoảng 0,055% (làm tròn 0,06%)

Recall 100% nhưng Precision dưới 0,1%: là Alert Fatigue.
Mục tiêu của V3 (ngưỡng, cửa sổ trượt) và V4 (whitelist ngữ cảnh) là kéo mẫu số FP xuống để Precision tăng mà Recall tụt không đáng kể. Số thật sẽ điền sau khi replay.

Bảng minh họa (illustrative, chưa phải số đo thật) dùng xuyên suốt repo:

| Phiên bản | TP | FN | FP (trên 100.000 log) | Precision | Ghi chú |
| --- | --- | --- | --- | --- | --- |
| V2 nới lỏng | 3 | 0 | 5.420 | ~0,06% | bùng nổ FP |
| V3 ngưỡng | 3 | 0 | 185 | ~1,60% | giảm mạnh |
| V4 ngữ cảnh | 3 | 0 | 8 | ~27,27% | giảm ~99,85% FP so với V2 |

Các file khác (Precision_Recall..., Clinic_IT_Morning_Review_Playbook, legal docs) khi nhắc con số này thì ghi "xem bảng minh họa ở Base_Rate_Fallacy_Axelsson1999.md", không chép lại số.

## 5. Đọc thêm

- Axelsson, TISSEC 2000 (bản gốc, bắt buộc có trong lit review).
- R. Sommer and V. Paxson, "Outside the Closed World: On Using Machine Learning for Network Intrusion Detection", IEEE S&P 2010. DOI: 10.1109/SP.2010.25. Link: https://www.icir.org/robin/papers/oakland10-ml.pdf
