# Kịch bản 2: Kerberoasting hạ cấp RC4 (0x17) vs OpSec AES256 (0x12)

| File | Vai trò | Event | Tool cần | Luật bắt |
| --- | --- | --- | --- | --- |
| `attack_rc4_downgrade_0x17.ps1` | 2A: ép vé RC4 0x17 (dễ crack) | 4769, etype 0x17 | **Rubeus.exe** (ngoài) | V1 bắt |
| `evasion_aes256_opsec_0x12.ps1` | 2B: xin vé AES256 0x12 | 4769, etype 0x12 | Không (native .NET) | V1 bỏ lọt, V2/V3/V4 bắt |

## Vì sao pha 2A cần Rubeus còn 2B thì không

Tài khoản `SVC_HIS_Database` được cấu hình hỗ trợ cả RC4 lẫn AES (trong `Import-ClinicADUsers.ps1`: `Set-ADUser -KerberosEncryptionType RC4,AES128,AES256`). Khi một client Windows Server 2022 xin vé TGS cho SPN đó, KDC sẽ chọn thuật toán MẠNH NHẤT cả hai bên cùng hỗ trợ, tức AES256 (0x12). Nên:

- **Pha 2B (evasion 0x12):** xin vé bằng `.NET KerberosRequestorSecurityToken` là tự nhiên ra 0x12. Zero tooling. Đây chính là cái né được luật V1 (V1 chỉ lọc 0x17).
- **Pha 2A (default 0x17):** muốn ép KDC HẠ CẤP xuống RC4 (0x17) trên một tài khoản vốn hỗ trợ AES thì native không làm được. Phải dùng Rubeus với `/tgtdeleg /rc4opsec`: kỹ thuật lạm dụng GSS-API để xin một TGT ủy quyền, buộc DC cấp vé RC4 trên tài khoản có bật RC4. RC4 crack offline nhanh hơn nhiều so với AES, nên kẻ tấn công thích 0x17 nếu không ngại bị bắt.

Chú ý: khoảng cách giữa 2A và 2B cho thấy điểm yếu nằm ở LUẬT chứ không phải ở hành vi tấn công. V1 kế thừa từ SigmaHQ lọc 4769 theo CA TicketOptions 0x40810000 (có dạng Rubeus/tool hay set) VÀ TicketEncryptionType 0x17. Pha 2B né được vì xin vé 0x12. Lưu ý 0x40810000 cũng là một dấu hiệu yếu (vé TGS Windows thường có TicketOptions khác), nên điểm yếu thật sự vẫn là phụ thuộc chữ ký, đó là lý do V3 (ngưỡng tần suất vé 4769 tới một user-SPN) và V4 (whitelist ngữ cảnh) mới là hướng phát hiện bền.

## Cách lấy Rubeus.exe (dependency ngoài)

1. Tải release hoặc tự build từ `https://github.com/GhostPack/Rubeus`.
2. Trước khi copy vào máy, chạy `Add-MpPreference -ExclusionPath "C:\Tools"` (các script bootstrap đã làm). Defender gắn cờ Rubeus là hacktool, đây là hành vi đúng của Defender, không phải lỗi.
3. Đặt `Rubeus.exe` vào `C:\Tools\`. Nếu không có file, `attack_rc4_downgrade_0x17.ps1` sẽ cảnh báo và bỏ qua pha 2A (vẫn chạy được 2B).

Nếu không muốn dùng tool ngoài chút nào: có thể demo chỉ pha 2B (0x12) và trình bày 2A ở mức lý thuyết, nhưng như vậy bảng Trade-off của SC2 sẽ thiếu một dòng "default bị V1 bắt". Khuyên nên dùng Rubeus cho đủ cặp default/evasion.
