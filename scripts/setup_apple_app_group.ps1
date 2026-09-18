# Huong dan bat App Group tren Apple Developer (Windows - chi can trinh duyet).
# Chay: powershell -ExecutionPolicy Bypass -File scripts/setup_apple_app_group.ps1

$AppGroupId = "group.com.example.ofocus"
$MainBundleId = "com.example.ofocus"
$ExtensionBundleId = "com.example.ofocus.LiveKit-Broadcast-Extension"

Write-Host ""
Write-Host "=== oFocus: Bat App Group cho iOS Screen Share ===" -ForegroundColor Cyan
Write-Host ""
Write-Host "Loi 'App Group chua duoc cau hinh' xay ra vi Apple chua cap quyen App Group"
Write-Host "cho provisioning profile tren iPhone. File entitlements trong repo KHONG du."
Write-Host ""
Write-Host "Ban CAN lam cac buoc sau tren trinh duyet (khong can Mac/Xcode):"
Write-Host ""

Write-Host "BUOC 1 - Tao App Group" -ForegroundColor Yellow
Write-Host "  1. Dang nhap https://developer.apple.com/account"
Write-Host "  2. Certificates, Identifiers & Profiles -> Identifiers"
Write-Host "  3. Bam (+) -> chon 'App Groups' -> Continue"
Write-Host "  4. Description: Ofocus Shared"
Write-Host "  5. Identifier: $AppGroupId"
Write-Host "  6. Register"
Write-Host ""

Write-Host "BUOC 2 - Bat App Group cho app chinh" -ForegroundColor Yellow
Write-Host "  1. Identifiers -> chon '$MainBundleId'"
Write-Host "     (neu chua co: (+) App IDs -> App -> Bundle ID: $MainBundleId)"
Write-Host "  2. Capabilities -> bat 'App Groups' -> Configure"
Write-Host "  3. Chon '$AppGroupId' -> Continue -> Save"
Write-Host ""

Write-Host "BUOC 3 - Bat App Group cho Broadcast Extension" -ForegroundColor Yellow
Write-Host "  1. Identifiers -> chon '$ExtensionBundleId'"
Write-Host "     (neu chua co: (+) App IDs -> App -> Bundle ID: $ExtensionBundleId)"
Write-Host "  2. Capabilities -> bat 'App Groups' -> Configure"
Write-Host "  3. Chon '$AppGroupId' -> Continue -> Save"
Write-Host ""

Write-Host "BUOC 4 - Tao lai Provisioning Profile" -ForegroundColor Yellow
Write-Host "  1. Profiles -> xoa profile Development/Ad Hoc cu (neu co)"
Write-Host "  2. (+) -> iOS App Development (hoac Ad Hoc)"
Write-Host "  3. Chon App ID '$MainBundleId'"
Write-Host "  4. Chon certificate + thiet bi iPhone"
Write-Host "  5. Ten profile -> Generate -> Download"
Write-Host "  6. Lam tuong tu cho '$ExtensionBundleId' (profile rieng cho extension)"
Write-Host ""

Write-Host "BUOC 5 - Build lai app co ky (signed)" -ForegroundColor Yellow
Write-Host "  - Dung Codemagic workflow 'ofocus-ios-device' (xem codemagic.yaml)"
Write-Host "  - Hoac nho nguoi co Mac build + cai IPA len iPhone"
Write-Host "  - KHONG dung build --no-codesign de test screen share tren may that"
Write-Host ""

Write-Host "BUOC 6 - Cai lai app tren iPhone" -ForegroundColor Yellow
Write-Host "  Go app cu -> cai ban moi -> thu lai Chia se man hinh"
Write-Host ""

$open = Read-Host "Mo trang Apple Developer Identifiers trong trinh duyet? (y/n)"
if ($open -eq "y" -or $open -eq "Y") {
    Start-Process "https://developer.apple.com/account/resources/identifiers/list"
}

Write-Host ""
Write-Host "Xong huong dan. Sau khi hoan tat tren Apple Developer, build signed moi chay duoc." -ForegroundColor Green
