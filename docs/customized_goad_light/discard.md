# Những phần của GOAD-Light tôi bỏ và lý do

File này chỉ rõ tôi bỏ những thành phần nào của GOAD-Light gốc và vì sao, để tập trung vào 3 kịch bản trong PGNV (dò quét ADSI, Kerberoasting, lạm dụng CSDL bệnh án). 
tôi liệt kê những file trong GOAD-Light, dựa trên inventory và config.json của repo gốc.

Kiểm chứng:
- inventory: https://github.com/Orange-Cyberdefense/GOAD/blob/main/ad/GOAD-Light/data/inventory
- config.json: https://github.com/Orange-Cyberdefense/GOAD/blob/main/ad/GOAD-Light/data/config.json

## 1. Miền con dc02 (north.sevenkingdoms.local) và quan hệ trust

GOAD-Light gốc có `dc02` làm Domain Controller miền con, kèm trust cha-con với `dc01`. Phần này phục vụ các kịch bản tấn công kiểu SID History, Golden/Diamond Ticket xuyên miền.

Lý do bỏ: phòng khám vừa và nhỏ chỉ chạy một miền nội bộ duy nhất -> gộp về `clinic.local` và dùng chính máy ảo thứ 3 làm máy trạm WS01, đúng kiến trúc 3 nút trong PGNV.

## 2. ADCS trên dc01

GOAD-Light gốc cài ADCS trên dc01 với các mẫu chứng chỉ lỗi (ESC) để luyện tấn công PKI.

Lý do bỏ: không nằm trong 3 kịch bản PGNV. Ngoài ra ở Việt Nam, bệnh án điện tử theo Thông tư 13/2025/TT-BYT thường ký bằng chữ ký số (USB token, SmartCA) tích hợp trong phần mềm HIS, chứ phòng khám nhỏ ít khi tự dựng CA nội bộ. Bỏ ADCS cũng giúp máy nhẹ hơn và không sinh log ngoài phạm vi phân tích.

## 3. IIS và WebDAV trên srv02

GOAD-Light gốc cho srv02 chạy IIS (có cấu hình cho phép upload webshell) và WebDAV.

Lý do bỏ: đường tấn công của đồ án đi qua định danh Active Directory và quyền truy cập CSDL (Kerberoast tài khoản dịch vụ, rồi đăng nhập SQL đọc/sửa/xóa bệnh án), không đi qua lỗ hổng tầng web. Giữ IIS lại chỉ làm nhiễu và tăng bề mặt ngoài phạm vi.

## 4. Những role hạ tầng của Vagrant/VirtualBox

GOAD-Light gốc chạy qua Vagrant và Ansible với mạng Host-Only `192.168.56.0/24` (IP tĩnh, 2 card mạng). tôi không dùng nguyên pipeline này khi chạy trên AWS EC2 vì:

- AWS VPC tự cấp IP và định tuyến, chỉ cần 1 card mạng. Ép IP tĩnh `192.168.56.x` lên EC2 sẽ làm đứt RDP.
- tôi cài trực tiếp bằng PowerShell qua RDP để không phải dựng thêm máy Jumpbox Ubuntu.

File Vagrant và Ansible tôi vẫn giữ trong `iac_goad_light_custom/` cho ai có server RAM lớn muốn dựng lại bằng VirtualBox, còn luồng chính chạy trên AWS.

## 5. Vài điểm cần làm rõ

- **LAPS:** GOAD-Light không bật LAPS (các nhóm `[laps_*]` để trống, `use_laps` = false)
- **GPO / delegation / chuỗi ACL phức tạp:** config.json của GOAD-Light không có các khối riêng tên `gpos`, `delegations`. Phần ACL nằm lồng trong từng domain, không phải một khối lớn ở cấp cao nhất.
- **Những thứ tôi giữ cơ chế:** tạo forest và OU, service account có SPN để Kerberoast, AS-REP roasting, SMB share phân quyền lỏng, và MSSQL có đường leo quyền. Chi tiết xem file keep.md.