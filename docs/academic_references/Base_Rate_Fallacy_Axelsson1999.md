# Base-Rate Fallacy và bài toán báo động giả trong phát hiện xâm nhập

// phần nền lý thuyết cho lập luận "tại sao phải tinh chỉnh luật cho chặt thay vì cứ nới rộng để bắt cho hết". số liệu V2 ở dưới là số minh họa dự kiến, k phải số đo thật. Khi chạy xong replay, đếm được TP/FP/FN thật thì thay vào.

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
- P(A|¬I) = FPR: xác suất báo nhầm trên một sự kiện hợp lệ.

Theo Bayes, độ chính xác của cảnh báo đẩy lên màn hình SOC chính là:

$$P(I \mid A) = \text{Precision} = \frac{P(I)\,P(A\mid I)}{P(I)\,P(A\mid I) + P(\neg I)\,P(A\mid \neg I)} = \frac{TP}{TP + FP}$$

Điểm mấu chốt: vì P(¬I) rất lớn, chỉ cần FPR nhỉnh lên một chút là FP tuyệt đối đã đủ
nhấn chìm TP, kéo Precision sụp. Đó là lý do nới luật để tăng Recall gần như luôn phải
trả giá bằng Precision.

## 4. Minh họa dự kiến cho luật V2 (CHƯA PHẢI SỐ ĐO THẬT)

Ví dụ giả định, trên tập 100.000 sự kiện, nếu V2 bắt trúng cả 3 kịch bản (TP=3, FN=0) nhưng báo nhầm FP=5.420 do bắt luôn hoạt động giao ca và đồng bộ XML BHYT:

- FPR xấp xỉ 5.420 / 99.997 ≈ 5,42%
- Precision = 3 / (3 + 5.420) ≈ 0,055% ≈ 0,06%

Recall 100% nhưng Precision dưới 0,1%: là Alert Fatigue.
Mục tiêu của V3 (ngưỡng, cửa sổ trượt) và V4 (whitelist ngữ cảnh) là kéo mẫu số FP xuống để Precision tăng mà Recall tụt không đáng kể. Số thật sẽ điền sau khi replay.

## 5. Đọc thêm 

- Axelsson, TISSEC 2000 (bản gốc, bắt buộc có trong lit review).
- R. Sommer and V. Paxson, "Outside the Closed World: On Using Machine Learning for Network Intrusion Detection", IEEE S&P 2010. Bàn sâu vì sao đánh giá IDS thực tế lại khó, base rate và chi phí false positive ở góc vận hành. DOI: 10.1109/SP.2010.25.
Link: https://www.icir.org/robin/papers/oakland10-ml.pdf