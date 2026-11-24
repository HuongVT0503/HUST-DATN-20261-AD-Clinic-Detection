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

## 4. Khung bảng kết quả (CHƯA CÓ SỐ, điền sau khi replay)
Số thật sẽ đếm từ `04_evaluation_and_datasets/alerts_exported_csv/` sau khi replay .evtx qua từng phiên bản luật. Ở đây chỉ dựng sẵn khung và công thức.

Ký hiệu dùng chung cho cả repo (chỗ nào cần nhắc thì trỏ về đây, không tự chế số):
- N: tổng số sự kiện trong tập replay (đếm sau khi có .evtx).
- TP_Vi, FN_Vi, FP_Vi: số cảnh báo đúng / bỏ lọt / nhầm của phiên bản luật Vi, đếm ở mức alert-level.
- P_Vi = TP_Vi / (TP_Vi + FP_Vi) : Precision.
- R_Vi = TP_Vi / (TP_Vi + FN_Vi) : Recall.
- GiamFP_Vi = (FP_V2 - FP_Vi) / FP_V2 * 100% : phần trăm FP giảm so với V2.

| Phiên bản | TP | FN | FP (trên N log) | Precision | Recall | Kỳ vọng định tính |
| --- | --- | --- | --- | --- | --- | --- |
| V2 nới lỏng | TP_V2 | FN_V2 | FP_V2 | P_V2 | R_V2 | Recall cao, FP cao nhất (bùng nổ cảnh báo) |
| V3 ngưỡng   | TP_V3 | FN_V3 | FP_V3 | P_V3 | R_V3 | FP giảm nhờ ngưỡng / cửa sổ trượt |
| V4 ngữ cảnh | TP_V4 | FN_V4 | FP_V4 | P_V4 | R_V4 | FP thấp nhất nhờ whitelist, Recall tụt không đáng kể |

Giả thuyết cần kiểm chứng bằng số thật: nới luật để tăng Recall (V2) thì Precision tụt mạnh do FP tăng (base-rate); V3, V4 kéo FP xuống để Precision tăng mà Recall giữ gần nguyên.

## 5. Đọc thêm

- Axelsson, TISSEC 2000 (bản gốc, bắt buộc có trong lit review).
- R. Sommer and V. Paxson, "Outside the Closed World: On Using Machine Learning for Network Intrusion Detection", IEEE S&P 2010. DOI: 10.1109/SP.2010.25. Link: https://www.icir.org/robin/papers/oakland10-ml.pdf
