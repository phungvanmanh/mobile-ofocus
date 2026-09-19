# Cau hinh Google Sign-In cho iOS (Info.plist).
# iOS can OAuth client loai iOS (Bundle ID com.example.ofocus), khong dung Web client.
#
# 1. Google Cloud Console -> Credentials -> OAuth client ID -> iOS
# 2. powershell -ExecutionPolicy Bypass -File scripts/configure_google_signin_ios.ps1 `
#      -IosClientId "651542608792-XXXX.apps.googleusercontent.com"
# 3. flutter run --dart-define=GOOGLE_IOS_CLIENT_ID=651542608792-XXXX.apps.googleusercontent.com

param(
    [Parameter(Mandatory = $true)]
    [string]$IosClientId
)

$ErrorActionPreference = "Stop"
$InfoPlist = (Resolve-Path (Join-Path $PSScriptRoot "..\ios\Runner\Info.plist")).Path

if ($IosClientId -notmatch '\.apps\.googleusercontent\.com$') {
    Write-Error "IosClientId phai ket thuc bang .apps.googleusercontent.com"
}

$suffix = ".apps.googleusercontent.com"
$core = $IosClientId.Substring(0, $IosClientId.Length - $suffix.Length)
$Reversed = "com.googleusercontent.apps.$core"

$content = Get-Content -Path $InfoPlist -Raw -Encoding UTF8
if ($content -notmatch 'REPLACE_WITH_IOS_CLIENT_ID') {
    Write-Host "Info.plist da duoc cau hinh truoc do. Ghi de GIDClientID / URL scheme..." -ForegroundColor Yellow
}

$content = $content.Replace('REPLACE_WITH_IOS_CLIENT_ID', $IosClientId)
$content = $content.Replace('REPLACE_WITH_REVERSED_CLIENT_ID', $Reversed)

# Ghi de lan chay sau (placeholder da mat)
$content = $content -replace '(?<=<key>GIDClientID</key>\r?\n\t<string>)[^<]+(?=</string>)', $IosClientId
$content = $content -replace '(?<=<key>CFBundleURLSchemes</key>\r?\n\t\t\t<array>\r?\n\t\t\t\t<string>)[^<]+(?=</string>)', $Reversed

Set-Content -Path $InfoPlist -Value $content -Encoding UTF8 -NoNewline

Write-Host ""
Write-Host "Da cap nhat ios/Runner/Info.plist" -ForegroundColor Green
Write-Host "  GIDClientID: $IosClientId"
Write-Host "  URL scheme:  $Reversed"
Write-Host ""
Write-Host "Chay app:" -ForegroundColor Cyan
Write-Host "  flutter run --dart-define=GOOGLE_IOS_CLIENT_ID=$IosClientId"
Write-Host ""
