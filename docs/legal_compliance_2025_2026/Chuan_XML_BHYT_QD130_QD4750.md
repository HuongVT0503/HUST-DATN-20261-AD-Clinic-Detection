# Chuẩn dữ liệu đầu ra XML BHYT (Quyết định 130/QĐ-BYT và 4750/QĐ-BYT)

Căn cứ nghiệp vụ cho bộ sinh nhiễu đồng bộ XML BHYT.
Áp dụng cho: `01_clinic_lab_and_noise/business_noise_generators/Invoke-HISXmlSync_QD130_QD4750.ps1` và `03_siem_rules_v1_to_v4/`.

## 1. Thông tin văn bản

| Thuộc tính | Quyết định 130/QĐ-BYT | Quyết định 4750/QĐ-BYT |
| --- | --- | --- |
| Cơ quan ban hành | Bộ Y tế | Bộ Y tế |
| Số hiệu | 130/QĐ-BYT | 4750/QĐ-BYT |
| Ngày ban hành | 18/01/2023 | 29/12/2023 |
| Người ký | Thứ trưởng Trần Văn Thuấn | (tra cứu bản gốc trước khi cite) |
| Hiệu lực | Kể từ ngày ký | Kể từ ngày ký |
| Nội dung | Quy định chuẩn và định dạng dữ liệu đầu ra (XML) phục vụ quản lý, giám định, thanh toán chi phí khám chữa bệnh BHYT | Sửa đổi, bổ sung một số điều của Quyết định 130/QĐ-BYT |

Chuỗi sửa đổi: Quyết định 4210/QĐ-BYT (2017) được thay bởi 130/QĐ-BYT (18/01/2023), rồi 130 được sửa đổi bổ sung bởi 4750/QĐ-BYT (29/12/2023), tiếp đó 3176/QĐ-BYT (29/12/2024) sửa đổi 4750, và 1931/QĐ-BYT (29/06/2026) sửa đổi 3176. Cite 130 và 4750 là ổn cho cấu trúc XML cơ bản; nếu muốn mốc mới nhất thì nhắc thêm 3176/2024 và 1931/2026.

## 2. Bản chất nghiệp vụ trích chuyển XML tại phòng khám

Mọi cơ sở khám chữa bệnh có hợp đồng BHYT phải trích xuất dữ liệu từ phần mềm HIS ra tệp XML theo chuẩn 130 và 4750 sau mỗi lượt khám hoặc kết thúc điều trị, rồi gửi lên Cổng tiếp nhận dữ liệu Hệ thống thông tin giám định BHYT. Một số bảng chỉ tiêu cốt lõi:

- XML1 (tổng hợp KCB): `MA_LK`, `MA_BN`, `HO_TEN`, `SO_CCCD`, `MA_THE_BHYT`, `MA_BENH_CHINH` (ICD-10), `NGAY_VAO`, `NGAY_RA`, tổng chi phí.
- XML2 (chi tiết thuốc): danh mục thuốc, hàm lượng, liều, bác sĩ kê đơn (`MA_BAC_SI`).
- XML3 (dịch vụ kỹ thuật, vật tư): xét nghiệm (LIS), chẩn đoán hình ảnh (PACS), thủ thuật.
- XML4, XML5: cận lâm sàng, diễn biến lâm sàng.
- XML7, XML8, XML9: giấy ra viện, tóm tắt hồ sơ, giấy nghỉ hưởng BHXH.
- XML13, XML14: giấy chuyển tuyến, giấy hẹn khám lại (chuẩn hóa theo 4750).

## 3. Ánh xạ sang lưu lượng hệ thống (nguồn nhiễu nền)

Để tự động xuất và đồng bộ dữ liệu, phòng khám thường dùng tài khoản dịch vụ chạy ngầm (trong đồ án là `SVC_HIS_Sync` hoặc `SVC_HIS_Database`). Đây là nguồn gây nhiễu nền hợp lệ lớn nhất, và là lý do sinh cảnh báo giả nếu luật SIEM không tinh chỉnh:

| Bước nghiệp vụ | Hoạt động kỹ thuật | Event ID | Vì sao gây cảnh báo giả ở V2/V3 |
| --- | --- | --- | --- |
| Xác thực dịch vụ định kỳ | `SVC_HIS_Sync` xin vé Kerberos TGS tới `DC01` để kết nối `MSSQLSvc/SRV02.clinic.local:1433` và SMB | 4769 (TicketEncryptionType 0x12 AES256), 4624 (Logon Type 3) | V2 nới điều kiện bắt Kerberoasting AES 0x12 làm hàng loạt 4769 hợp lệ bị bắt nhầm |
| Tra cứu định danh bác sĩ | HIS truy vấn LDAP lên `DC01` để đối chiếu tài khoản `BS_*`, khoa phòng, quyền ký số | 1644 (LDAP Search) | V2 bắt mọi truy vấn LDAP để chống dò quét AD làm truy vấn hợp lệ của HIS bị nhầm là công cụ recon |
| Truy vấn CSDL hàng loạt | Dịch vụ chạy nhiều SELECT trên các bảng bệnh án để gom dữ liệu xuất XML, tăng đột biến cuối ca | 33205 (action SELECT) trong Application Log | V2/V3 đặt ngưỡng đếm SELECT để bắt trích xuất dữ liệu làm tác vụ tổng hợp XML cuối ngày vượt ngưỡng |
| Ghi và chia sẻ tệp XML | Đẩy tệp vào `\\SRV02\BenhAn$` cho cổng ký số và phần mềm giám định đọc | 5140, 5145 (truy cập share) | Trùng hành vi giao thức với kỹ thuật thu thập từ share (MITRE ATT&CK T1039) |

## 4. Nguyên tắc tách nhiễu và tấn công ở luật V4

Script `Invoke-HISXmlSync_QD130_QD4750.ps1` thể hiện chu kỳ cổng tự động xuất và đồng bộ dữ liệu: chạy định kỳ dưới quyền tài khoản dịch vụ, xác thực Kerberos AES256 (0x12), chạy SELECT các bản ghi mới trên `SRV02`, tạo tệp cấu trúc thẻ chuẩn rồi lưu vào `\\SRV02\BenhAn$`. Dữ liệu nhạy cảm trong kiểm thử đều là dữ liệu giả lập và được băm ẩn danh qua `anonymize_sensitive_emr_logs.py` trước khi vào ELK.

Luật V4 dùng phễu hai lớp:

1. Whitelist theo ngữ cảnh chặt cho thao tác đọc (SELECT, 4769): chỉ loại trừ khi đồng thời đúng tài khoản `SVC_HIS_Sync`, đúng IP `SRV02`, và chỉ dừng ở truy vấn đọc theo mẫu kết xuất XML. Nếu `SVC_HIS_Sync` xin vé hoặc đăng nhập SQL từ máy trạm `WS01` thì bắn cảnh báo ngay.
2. Chốt chặn cho thao tác phá hủy và vô hiệu hóa phòng thủ: nghiệp vụ XML theo 130 và 4750 là chỉ đọc và trích xuất, không bao giờ DELETE/DROP/TRUNCATE bệnh án, không bật `xp_cmdshell` (15457), không tắt Audit (33205 STATE OFF). Vì vậy nhánh giám sát toàn vẹn bệnh án không whitelist cho ai cả; kể cả kẻ tấn công dùng chính `SVC_HIS_Sync` để xóa bệnh án hay tắt Audit thì vẫn bị bắt.

Lưu ý: các con số tỷ lệ giảm cảnh báo là minh họa dự kiến, điền số thật sau khi replay.

## 5. Nguồn tra cứu

- Quyết định 130/QĐ-BYT (TVPL): https://thuvienphapluat.vn/van-ban/the-thao-y-te/Quyet-dinh-130-QD-BYT-2023-chuan-dinh-dang-du-lieu-dau-ra-phuc-vu-quan-ly-chi-phi-kham-chua-benh-553072.aspx
- Quyết định 130 bản PDF (LuatVietnam): https://luatvietnam.vn/y-te/quyet-dinh-130-qd-byt-241607-d1.html

## 6. Trích dẫn chuẩn IEEE

```text
[1] Bộ Y tế, "Quyết định quy định chuẩn và định dạng dữ liệu đầu ra phục vụ việc quản lý, giám định, thanh toán chi phí khám bệnh, chữa bệnh và giải quyết các chế độ liên quan," Quyết định số 130/QĐ-BYT, Hà Nội, Việt Nam, ngày 18/01/2023.
[2] Bộ Y tế, "Quyết định sửa đổi, bổ sung một số điều của Quyết định số 130/QĐ-BYT," Quyết định số 4750/QĐ-BYT, Hà Nội, Việt Nam, ngày 29/12/2023.
[3] Bộ Y tế, "Quyết định sửa đổi, bổ sung Quyết định số 4750/QĐ-BYT," Quyết định số 3176/QĐ-BYT, Hà Nội, Việt Nam, ngày 29/12/2024.
```