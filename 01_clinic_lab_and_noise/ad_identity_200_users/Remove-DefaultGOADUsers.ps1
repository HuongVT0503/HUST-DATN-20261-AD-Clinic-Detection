<#
.SYNOPSIS
    Remove-DefaultGOADUsers.ps1
    Xóa toàn bộ các tài khoản, nhóm và Organizational Units (OUs) nhân vật phim
    mặc định của GOAD-Light (Game of Thrones) để làm sạch môi trường phòng khám.
.NOTES
    Đồ án Tốt nghiệp Kỳ 2026.1 - Sinh viên: Vũ Thúy Hường (MSSV: 20225135)
#>

$ErrorActionPreference = "SilentlyContinue"
Import-Module ActiveDirectory

Write-Host "[*] Đang rà soát và gỡ bỏ các định danh Game of Thrones mặc định của GOAD-Light..." -ForegroundColor Cyan

$DefaultGOADUsers = @(
    "robert.baratheon", "cersei.lannister", "jaime.lannister", "joffrey.baratheon",
    "tywin.lannister", "petyr.baelish", "varys", "pycelle", "renly.baratheon",
    "stannis.baratheon", "melisandre", "davos.seaworth", "barristan.selmy",
    "eddard.stark", "catelyn.stark", "robb.stark", "sansa.stark", "arya.stark",
    "brandon.stark", "rickon.stark", "hodor", "jeor.mormont", "jon.snow", "samwell.tarly"
)

foreach ($u in $DefaultGOADUsers) {
    if (Get-ADUser -Filter "SamAccountName -eq '$u'") {
        Remove-ADUser -Identity $u -Confirm:$false
        Write-Host "[-] Đã xóa tài khoản GOAD mặc định: $u" -ForegroundColor Yellow
    }
}

$DefaultGOADGroups = @(
    "Crownlands", "KingsLanding", "Dragonstone", "NarrowSea", "Baratheon",
    "Lannister", "Small Council", "Kingsguard", "Dragons", "Winterfell",
    "TheWall", "Stark", "NightWatch", "Mormont"
)

foreach ($g in $DefaultGOADGroups) {
    if (Get-ADGroup -Filter "Name -eq '$g'") {
        Remove-ADGroup -Identity $g -Confirm:$false
        Write-Host "[-] Đã xóa nhóm GOAD mặc định: $g" -ForegroundColor Yellow
    }
}

$DefaultGOADOUs = @("Crownlands", "KingsLanding", "Dragonstone", "NarrowSea", "Winterfell", "TheWall")
$DomainDN = (Get-ADDomain).DistinguishedName

foreach ($ou in $DefaultGOADOUs) {
    $ouDN = "OU=$ou,$DomainDN"
    if (Get-ADOrganizationalUnit -Filter "DistinguishedName -eq '$ouDN'") {
        Set-ADOrganizationalUnit -Identity $ouDN -ProtectedFromAccidentalDeletion $false
        Remove-ADOrganizationalUnit -Identity $ouDN -Recursive -Confirm:$false
        Write-Host "[-] Đã xóa OU GOAD mặc định: $ouDN" -ForegroundColor Yellow
    }
}

Write-Host "[+] Hoàn tất làm sạch các đối tượng mặc định của GOAD-Light!" -ForegroundColor Green