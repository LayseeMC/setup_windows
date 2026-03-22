# 管理者権限の確認
if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Error "管理者権限で実行してください。"
    exit
}

Write-Host "セットアップを開始します..." -ForegroundColor Cyan

# --- 確実なレジストリ編集のためのヘルパー関数 ---
function Set-RegKey {
    param($Path, $Name, $Value, $Type="DWord")
    if (!(Test-Path $Path)) { New-Item -Path $Path -Force -ErrorAction SilentlyContinue | Out-Null }
    Set-ItemProperty -Path $Path -Name $Name -Value $Value -Type $Type -Force -ErrorAction SilentlyContinue
}

# --- 1. 電源とスリープの設定 ---
Write-Host "電源とスリープの設定を適用中..."
powercfg /change monitor-timeout-ac 15
powercfg /change monitor-timeout-dc 15
powercfg /change standby-timeout-ac 45
powercfg /change standby-timeout-dc 45
# カバーを閉じた時の動作：何もしない (AC/DC)
powercfg /setacvalueindex SCHEME_CURRENT 4f971e89-eebd-4455-a8de-9e59040e7347 5ca83367-6e45-459f-a27b-476b1d01c936 0
powercfg /setdcvalueindex SCHEME_CURRENT 4f971e89-eebd-4455-a8de-9e59040e7347 5ca83367-6e45-459f-a27b-476b1d01c936 0
powercfg /setactive SCHEME_CURRENT
# 高速スタートアップを無効化
Set-RegKey "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Power" "HiberbootEnabled" 0
# 電源モード（AC：最適なパフォーマンス、DC：バランス）
Set-RegKey "HKLM:\SYSTEM\CurrentControlSet\Control\Power\User\PowerSchemes" "ActiveOverlayAcPowerScheme" "ded574b5-45a0-4f42-8737-46345c09c238" "String"
Set-RegKey "HKLM:\SYSTEM\CurrentControlSet\Control\Power\User\PowerSchemes" "ActiveOverlayDcPowerScheme" "00000000-0000-0000-0000-000000000000" "String"

# --- 2. 不要なアプリケーションの削除 ---
Write-Host "指定されたアプリケーションを削除中..."
$appsToRemove = @(
    "Microsoft.WindowsCalculator",
    "Microsoft.WindowsCamera",
    "*Dolby*",
    "Microsoft.Windows.ParentalControls",
    "Microsoft.MicrosoftOfficeHub",
    "Clipchamp.Clipchamp",
    "MicrosoftTeams",
    "Microsoft.Todos",
    "Microsoft.OutlookForWindows",
    "Microsoft.PowerAutomateDesktop",
    "RealtekSemiConductorCorp.RealtekAudioControl",
    "Microsoft.ScreenSketch",
    "Microsoft.MicrosoftSolitaireCollection",
    "Microsoft.WindowsSoundRecorder",
    "Microsoft.MicrosoftStickyNotes",
    "Microsoft.BingWeather",
    "Microsoft.XboxApp",
    "Microsoft.XboxGamingOverlay",
    "Microsoft.XboxIdentityProvider",
    "LinkedInforWindows"
)
foreach ($app in $appsToRemove) {
    Get-AppxPackage -Name $app -AllUsers | Remove-AppxPackage -AllUsers -ErrorAction SilentlyContinue
}
# OneDriveの削除
$oneDriveUninstaller = "$env:SystemRoot\SysWOW64\OneDriveSetup.exe"
if (Test-Path $oneDriveUninstaller) {
    Start-Process -FilePath $oneDriveUninstaller -ArgumentList "/uninstall" -Wait -NoNewWindow
}

# --- 3. WindowsのUIおよびシステム設定 ---
Write-Host "システム設定を適用中..."
# ダークモードに変更
Set-RegKey "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize" "AppsUseLightTheme" 0
Set-RegKey "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize" "SystemUsesLightTheme" 0
# 透明効果をオフ
Set-RegKey "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize" "EnableTransparency" 0
# 動的ライティングをオフ
Set-RegKey "HKCU:\Software\Microsoft\Lighting" "AmbientLightingEnabled" 0
# ロック画面には天気を表示しない
Set-RegKey "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" "SubscribedContent-338387Enabled" 0
# サインイン画面にロック画面の背景画像を表示するをオフ
Set-RegKey "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System" "DisableLogonBackgroundImage" 1
# 最近追加したアプリ、よく使うアプリを表示するをオフ
Set-RegKey "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" "Start_ShowRecentApps" 0
Set-RegKey "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" "Start_ShowFrequentApps" 0
# スタートで推奨されるファイル、エクスプローラで最近使用したファイル、ジャンプリスト内の項目を表示するをオフ
Set-RegKey "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" "Start_TrackDocs" 0
Set-RegKey "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" "Start_TrackProgs" 0
# ヒント、ショートカット、新しいアプリなどのおすすめを表示しない
Set-RegKey "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" "SubscribedContent-338389Enabled" 0
Set-RegKey "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" "SubscribedContent-310093Enabled" 0
Set-RegKey "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" "SubscribedContent-338388Enabled" 0
# アカウントに関連する通知を表示をオフ
Set-RegKey "HKCU:\Software\Microsoft\Windows\CurrentVersion\Notifications\Settings\Windows.SystemToast.AccountAction" "Enabled" 0
# タスクバーの検索は検索アイコンのみを表示
Set-RegKey "HKCU:\Software\Microsoft\Windows\CurrentVersion\Search" "SearchboxTaskbarMode" 1
# タスクビュー、ウィジェットはオフ
Set-RegKey "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" "ShowTaskViewButton" 0
Set-RegKey "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" "TaskbarDa" 0
# タスクバーのタスクの終了を右クリックで有効にするをオン
Set-RegKey "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" "TaskbarEndTask" 1
# タスクバーにバッテリーの残量%表示はオフ
Set-RegKey "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" "ShowBatteryPercentage" 0
# エクスプローラ：ファイル拡張子を表示、完全なパスを表示、空のドライブを表示
Set-RegKey "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" "HideFileExt" 0
Set-RegKey "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\CabinetState" "FullPath" 1
Set-RegKey "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" "HideDrivesWithNoMedia" 0
# コントローラーがgamebarを開くことを許可しない / サポートされているアプリでガイドボタンのアクションをトリガーをオフ
Set-RegKey "HKCU:\SOFTWARE\Microsoft\GameBar" "UseNexusForGameBarEnabled" 0
Set-RegKey "HKCU:\SOFTWARE\Microsoft\GameBar" "CustomForegroundActive" 0
# リモートアシスタント、リモートデスクトップを許可しない
Set-RegKey "HKLM:\SYSTEM\CurrentControlSet\Control\Remote Assistance" "fAllowToGetHelp" 0
Set-RegKey "HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server" "fDenyTSConnections" 1
# 視覚効果のスクロールバーを常に表示するをオフ (1=自動的に非表示)
Set-RegKey "HKCU:\Control Panel\Accessibility" "DynamicScrollbars" 1
# アニメーション効果をオフ
Set-RegKey "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects" "VisualFXSetting" 2
Set-RegKey "HKCU:\Control Panel\Desktop" "MinAnimate" "0" "String"
# 固定キー機能をオフ
Set-RegKey "HKCU:\Control Panel\Accessibility\StickyKeys" "Flags" "506" "String"
# マウスポインターの精度をオフ
Set-RegKey "HKCU:\Control Panel\Mouse" "MouseSpeed" "1" "String"
Set-RegKey "HKCU:\Control Panel\Mouse" "MouseThreshold1" "0" "String"
Set-RegKey "HKCU:\Control Panel\Mouse" "MouseThreshold2" "0" "String"
# 検索のハイライトを表示するをオフ
Set-RegKey "HKCU:\Software\Microsoft\Windows\CurrentVersion\SearchSettings" "IsDynamicSearchBoxEnabled" 0

# タスクバーを自動的に隠すをオン（バイナリデータの直接編集）
$stuckRects3Path = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\StuckRects3"
if (Test-Path $stuckRects3Path) {
    $settings = (Get-ItemProperty -Path $stuckRects3Path -Name "Settings" -ErrorAction SilentlyContinue).Settings
    if ($settings) {
        $settings[8] = 3
        Set-ItemProperty -Path $stuckRects3Path -Name "Settings" -Value $settings -Force
    }
}

# --- 4. アプリケーションのインストール ---
Write-Host "アプリケーションのインストールを開始します..." -ForegroundColor Yellow

# インストールするアプリのリスト (Winget ID)
$appsToInstall = @(
    "Arturia.MiniFuseControlCenter",
    "Nvidia.NvidiaApp",
    "Logitech.GHUB"
)

foreach ($appId in $appsToInstall) {
    Write-Host "Installing: $appId" -ForegroundColor Cyan
    # --accept-package-agreements: ライセンス条項に自動同意
    # --accept-source-agreements: ソース条項に自動同意
    winget install --id $appId --silent --accept-package-agreements --accept-source-agreements --error-action silentlycontinue
}

Write-Host "すべてのセットアップが完了しました。設定を完全に反映させるため、コンピュータを再起動してください。" -ForegroundColor Green
