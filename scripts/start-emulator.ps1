$ErrorActionPreference = 'Stop'

$configPath = Join-Path $PSScriptRoot 'emulator-config.json'
if (-not (Test-Path -LiteralPath $configPath)) {
    Write-Host "找不到配置文件: $configPath"
    exit 1
}

$config = Get-Content -LiteralPath $configPath -Raw | ConvertFrom-Json
$emulatorPath = [string]$config.emulatorPath

if (-not (Test-Path -LiteralPath $emulatorPath)) {
    Write-Host "找不到模拟器: $emulatorPath"
    exit 1
}

$choices = @()
foreach ($key in $config.avds.PSObject.Properties.Name) {
    $item = $config.avds.$key
    $choices += [pscustomobject]@{
        Key = $key
        Label = [string]$item.label
        Name = [string]$item.name
    }
}

Write-Host '请选择要启动的模拟器:'
foreach ($choice in $choices) {
    Write-Host "[$($choice.Key)] $($choice.Label) ($($choice.Name))"
}

$selectedKey = Read-Host '输入编号'
$selected = $choices | Where-Object { $_.Key -eq $selectedKey } | Select-Object -First 1
if (-not $selected) {
    Write-Host '无效选择'
    exit 1
}

$running = Get-Process -Name 'emulator' -ErrorAction SilentlyContinue
if ($running) {
    $answer = Read-Host '已有安卓模拟器在运行，是否先关闭它们再启动? [y/N]'
    if ($answer -match '^(y|yes)$') {
        $running | Stop-Process -Force
        Start-Sleep -Seconds 2
    }
}

Start-Process -FilePath $emulatorPath -ArgumentList @('-avd', $selected.Name)
