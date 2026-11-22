# Đối chiếu GOAD-Light gốc và bản tùy biến cho phòng khám

File này ghi lại tôi đã lấy gì từ GOAD-Light, sửa gì, bỏ gì để ra được môi trường  lab phòng khám trong đồ án.

Repo gốc: https://github.com/Orange-Cyberdefense/GOAD
Thư mục GOAD-Light: https://github.com/Orange-Cyberdefense/GOAD/tree/main/ad/GOAD-Light

## 1. GOAD-Light là gì

GOAD có nhiều bản. Bản GOAD-Light là bản rút gọn gồm 3 máy ảo, 1 rừng (forest) 2 miền:

- `dc01` (hostname `kingslanding`, miền cha `sevenkingdoms.local`), có cài ADCS.
- `dc02` (hostname `winterfell`, miền con `north.sevenkingdoms.local`), là Domain Controller miền con.
- `srv02` (hostname `castelblack`, thuộc miền con `north`), là member server chạy MSSQL, IIS, WebDAV và vài SMB share phân quyền lỏng.

Phần cấu hình nằm ở hai chỗ:
- Dữ liệu lab: `ad/GOAD-Light/data/config.json` (file này chỉ có 1 khóa gốc là `lab`, các host và domain lồng bên trong, độ dài khoảng 250 đến 300 dòng).
- Kịch bản triển khai: các role trong `ansible/roles/` đọc dữ liệu từ `config.json` rồi áp lên máy ảo.

Link để kiểm chứng:
- inventory: https://github.com/Orange-Cyberdefense/GOAD/blob/main/ad/GOAD-Light/data/inventory
- config.json: https://github.com/Orange-Cyberdefense/GOAD/blob/main/ad/GOAD-Light/data/config.json
- Bài viết của tác giả (Mayfly) giải thích kiến trúc: https://mayfly277.github.io/

Chú ý: tài khoản dịch vụ SQL dính Kerberoasting trong GOAD-Light là một service account gắn SPN `MSSQLSvc/...` (trong config là `sql_svc`), chứ không phải `jon.snow`. Vì vậy tôi mô tả bản tùy biến là "kế thừa đúng tài khoản dịch vụ SQL có SPN của GOAD-Light và đổi tên thành SVC_HIS_Database".

### Cách tôi triển khai: dựng mới `clinic.local` từ đầu, không deploy nguyên GOAD rồi xóa

Tôi chọn **viết lại các cấu hình lỗ hổng trọng tâm của GOAD-Light vào một miền `clinic.local` dựng mới từ đầu** (bằng các script trong `iac_goad_light_custom/aws_powershell_bootstrap/`), thay vì deploy nguyên GOAD-Light rồi xóa bớt. Lý do:
- Trọng tâm đồ án là phần tùy biến y tế, không phải chạy GOAD mặc định. Deploy nguyên GOAD rồi xóa tốn tiền AWS và kéo theo nhiều role (ADCS, trust, IIS...) không dùng mà vẫn phải giải thích.
- File keep.md + discard.md này là bằng chứng tôi đã đọc và hiểu `config.json`/các role của GOAD-Light để biết cái gì cần giữ (SPN Kerberoast, MSSQL leo quyền, SMB lỏng) và cái gì bỏ.

-> Tôi không deploy GOAD-Light nguyên bản mà tái hiện các misconfiguration cốt lõi của nó trong một miền clinic.local sạch, đối chiếu từng mục ở keep.md/discard.md.

## 2. Kiến trúc bản tùy biến của tôi (GOAD-Light Clinic Edition)

> Lấy vai trò DC01 và SRV02 của GOAD-Light, gộp về một miền duy nhất `clinic.local`
> (bỏ miền con dc02/north và quan hệ trust), rồi thêm một máy trạm WS01 làm máy phòng khám
> (Patient Zero và nơi sinh lưu lượng nền). Đây đúng với kiến trúc 3 nút trong PGNV
> (Nội dung 3): DC01, SRV02 (HIS: SQL + SMB), WS01.

3 máy là 3 máy riêng biệt, không gộp DC và SRV vào chung một node.

## 3. Bảng Giữ / Sửa / Bỏ (bám theo những gì GOAD-Light thật sự có)

| Thành phần trong GOAD-Light gốc | Quyết định | Trong bản phòng khám |
| --- | --- | --- |
| Cơ chế tạo Forest + OU (role `domain_controller`, `ad`) | Giữ, đổi tên | Forest `clinic.local`, 6 OU phòng ban (BacSi, YTa, LeTan, IT_Admin, ServiceAccounts, ClinicComputers) |
| Miền con `north` trên dc02 + trust cha-con | Bỏ | Chỉ 1 miền `clinic.local`, máy thứ 3 đổi thành WS01 |
| Tài khoản dịch vụ SQL gắn SPN `MSSQLSvc` (Kerberoasting) | Giữ cơ chế, đổi tên, thêm cờ mã hóa | `SVC_HIS_Database` gắn SPN `MSSQLSvc/SRV02.clinic.local:1433`, bật cả RC4 và AES để test 0x17 vs 0x12 |
| SMB share phân quyền lỏng trên srv02 | Giữ cơ chế, đổi nội dung | Share `\\SRV02\BenhAn$` chứa file XML BHYT theo QĐ 130 và 4750 |
| MSSQL trên srv02 (leo quyền, xp_cmdshell) | Giữ lỗ hổng, thêm dữ liệu | CSDL `HIS_ClinicDB`, bảng `HoSoBenhAn`, cấp quyền cho `SVC_HIS_Database` |
| ADCS trên dc01 (ESC templates) | Bỏ | Phòng khám dùng chữ ký số công cộng theo TT13, không tự dựng PKI nội bộ |
| IIS + WebDAV trên srv02 (webshell) | Bỏ | Đồ án đi theo hướng định danh AD và CSDL, không qua lỗ hổng web |

Những thứ tôi **thêm vào** mà GOAD-Light gốc không có (vì gốc là lab cho Red Team, không bật giám sát):

- Máy trạm WS01 và khoảng 200 định danh nhân sự y tế để sinh lưu lượng nền.
- Bật telemetry phía phòng thủ: Registry `15 Field Engineering` (Event ID 1644), `auditpol` cho 4769/4624/4625, Sysmon, và SQL Server Audit đẩy vào Application Log (Event ID 33205, 15457).
- Bộ script sinh nhiễu nghiệp vụ (giao ca, đồng bộ XML BHYT) và script ẩn danh hóa log.

## 4. Nguồn tham khảo

- GOAD và kiến trúc GOAD-Light: repo và blog Mayfly ở trên.
- Kerberoasting 0x17 vs 0x12: The Hacker Recipes (https://www.thehacker.recipes/ad/movement/kerberos/kerberoast) và Rubeus (https://github.com/GhostPack/Rubeus).
- Luật Sigma Kerberoasting gốc mà V1 kế thừa: https://github.com/SigmaHQ/sigma/blob/master/rules/windows/builtin/security/win_security_kerberoasting.yml
- Log truy vấn LDAP tốn kém (Event ID 1644): https://techcommunity.microsoft.com/t5/core-infrastructure-and-security/how-to-find-expensive-inefficient-and-long-running-ldap-queries/ba-p/257859
- SQL Server Audit và Event ID 33205: https://learn.microsoft.com/en-us/sql/relational-databases/security/auditing/sql-server-audit-records