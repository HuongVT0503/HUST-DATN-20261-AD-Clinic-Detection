# Cơ sở học thuật cho bộ sinh nhiễu nghiệp vụ (Business Noise Generator)

// File này lưu vết nguồn cho phần script sinh lưu lượng nền hợp lệ của phòng khám (Invoke-DoctorShiftChange, Invoke-HISXmlSync).
// Các nguồn dưới đây đã kiểm chứng link/số hiệu vào ngày 22/11/2026. Trước khi đưa vào quyển vẫn nên mở lại kiểm tra nguồn gốc một lần nữa.

## 1. Trụ cột phương pháp luận: mô phỏng hành vi người dùng (GHOSTS)

Bộ script của đồ án này là "một GHOSTS-lite viết tay cho ngành y tế".

- GHOSTS (CMU/SEI): framework sinh NPC tạo lưu lượng mạng hiện thực, mục tiêu là khiến người quan sát không phân biệt được hoạt động do người hay máy tạo ra.
- Trích dẫn: D. Updyke, G. Dobson, T. Podnar, L. Osterritter, B. Earl, A. Cerini "GHOSTS in the Machine: A Framework for Cyber-Warfare Exercise NPC Simulation." Technical Report CMU/SEI-2018-TR-005, Software Engineering Institute, Carnegie Mellon University, Dec 2018.
- DOI: 10.1184/R1/12363029.v1
- Trang SEI: https://www.sei.cmu.edu/library/ghosts-in-the-machine-a-framework-for-cyber-warfare-exercise-npc-simulation/
- Mã nguồn: https://github.com/cmu-sei/GHOSTS ; tài liệu: https://cmu-sei.github.io/GHOSTS

## 2. Dataset có cả benign + attack gán nhãn theo thời gian

Source cho quy trình "trộn nhiễu hợp lệ + tấn công rồi gán nhãn tĩnh theo timestamp", và cho tỉ lệ sự kiện tấn công thấp so với nền hợp lệ.

- ATLASv2: dataset log Windows Security Audit + Sysmon + DNS, gồm 4 ngày benign rồi 1 ngày tấn công với 10 kịch bản, gán nhãn theo mốc thời gian. Đúng mô hình static labeling trong đồ án.
  - A. Riddle, K. Westfall, A. Bates. "ATLASv2: ATLAS Attack Engagements, Version 2." University of Illinois Urbana-Champaign, arXiv:2401.01341 (2023/2024).
  - https://arxiv.org/abs/2401.01341

- HIKARI-2021: dataset chứa cả benign và synthetic attack, nêu rõ yêu cầu khi tự sinh dataset.
  - A. Ferriyan, A. H. Thamrin, K. Takeda, J. Murai. "Generating Network Intrusion Detection Dataset Based on Real and Encrypted Synthetic Attack Traffic." Applied Sciences, 2021, 11(17), 7868.
  - DOI: 10.3390/app11177868 ; https://www.mdpi.com/2076-3417/11/17/7868

## 3. Vì sao False Positive là vấn đề trung tâm (nền lý thuyết đánh đổi)

- S. Axelsson. "The Base-Rate Fallacy and the Difficulty of Intrusion Detection." (1999/2000).
  Chi tiết và cách dùng: xem Base_Rate_Fallacy_Axelsson1999.md.

## 4. Bối cảnh an ninh y tế (ngữ cảnh thực tế cho noise + 3 kịch bản)

- CISA #StopRansomware: Healthcare and Public Health (HPH) Sector. Ransomware lây qua Active Directory, tài khoản dùng chung. Dùng để lấy TTP cho kịch bản và biện minh tính cấp thiết.
  - https://www.cisa.gov/stopransomware/healthcare-and-public-health-sector
  - Advisory AA20-302A (Ryuk/Conti nhắm ngành y tế): https://www.cisa.gov/news-events/cybersecurity-advisories/aa20-302a
- Bối cảnh pháp lý Việt Nam (vì sao phòng khám phải giám sát, cấm xóa bệnh án đã ký): Thông tư 13/2025/TT-BYT, Luật 91/2025/QH15, QĐ 130 & 4750/QĐ-BYT. Xem thư mục docs/legal_compliance_2025_2026/.

## 4b. Bối cảnh phòng khám VN: CÁI GÌ CÓ NGUỒN, CÁI GÌ LÀ GIẢ ĐỊNH

**Có nguồn (văn bản thật, trích được):**
- Bệnh án điện tử phải phân quyền truy cập và lưu vết thao tác: Thông tư 13/2025/TT-BYT (ngày 06/06/2025, hiệu lực 21/07/2025). thuvienphapluat.vn + bản tin: bệnh án điện tử "hỗ trợ tra cứu trực tiếp, phân quyền truy cập và lưu vết thao tác"; tiêu chí TT13 gồm "Bảo đảm quyền riêng tư, bảo mật và kiểm tra truy vết".
- Phải xuất dữ liệu XML giám định BHYT theo QĐ 130/QĐ-BYT (18/01/2023) và QĐ 4750/QĐ-BYT (29/12/2023), gửi chính thức từ 01/7/2024 lên Cổng tiếp nhận giám định BHYT: https://gdbhyt.baohiemxahoi.gov.vn
  Khi tiếp đón, cơ sở KCB phải tra cứu thẻ BHYT trên Cổng giám định BHYT. (Công văn 3646/BYT-BH 2024, 3549/BYT-BH 2024). Từ 26/6/2025 có thí điểm ký số gói XML và đồng bộ theo thời gian thực.
- Rủi ro ransomware lây qua AD và tài khoản dùng chung trong ngành y tế: CISA AA20-302A.

**Là giả định mô hình hóa của tôi (KHÔNG có văn bản nguồn):**
- Giờ giao ca cụ thể 7h/12h/17h.
- Chu kỳ đồng bộ "mỗi 5 phút" (quy định chỉ bắt buộc gửi, không quy định 5 phút; tôi chọn cho lab chạy nhanh).
- Máy trạm quầy tiếp đón/cấp cứu dùng chung giữa các ca (hợp lý về vận hành nhưng tôi không có nguồn VN cụ thể).

## 5. Map nguồn vào từng script

- Invoke-DoctorShiftChange (4624/4625): mục 1 (GHOSTS), mục 2 (ATLASv2/HIKARI), mục 4 (CISA, tài khoản dùng chung).
- Invoke-HISXmlSync (1644/33205/5140-5145): mục 1 (GHOSTS), mục 3 (Axelsson, nền SELECT khổng lồ), QĐ 130/4750.