param(
  [string]$Out = "D:\Prog\smm-posting-poc\bg-clean-01.png"
)
$ErrorActionPreference = "Stop"
$token = (Get-Content "D:\Prog\SMM\.env" | Where-Object { $_ -match "^REPLICATE_API_TOKEN=" }) -replace "^REPLICATE_API_TOKEN=", ""

$outDir = Split-Path -Parent $Out
if (-not (Test-Path $outDir)) { New-Item -ItemType Directory -Path $outDir -Force | Out-Null }

$prompt = @"
Abstract retrofuturistic 1980s vaporwave background, deep dark purple base color hex 1a0d3a, low-poly wireframe mountain silhouettes on horizon, perspective grid floor receding to vanishing point, distant glowing sun semi-circle behind mountains in soft yellow hex e8f045, atmospheric purple haze, subtle starfield, very subtle CRT scanlines, sci-fi blueprint feel, minimal pure decorative texture, atmospheric and dark, ABSOLUTELY NO TEXT, NO LETTERS, NO NUMBERS, NO WORDS, NO TYPOGRAPHY, NO LOGOS, NO SYMBOLS WITH MEANING, NO PEOPLE, NO OBJECTS, purely abstract environmental background only, suitable as low-opacity decorative layer
"@

$body = @{
  input = @{
    prompt = $prompt
    size = "1024x1280"
    style = "digital_illustration"
  }
} | ConvertTo-Json -Depth 5

$headers = @{
  "Authorization" = "Bearer $token"
  "Content-Type" = "application/json"
  "Prefer" = "wait"
}

Write-Output "[clean-bg] submitting Recraft v3..."
$bodyBytes = [System.Text.Encoding]::UTF8.GetBytes($body)
$resp = Invoke-RestMethod -Uri "https://api.replicate.com/v1/models/recraft-ai/recraft-v3/predictions" -Method Post -Headers $headers -Body $bodyBytes -ContentType "application/json; charset=utf-8"

$tries = 0
while ($resp.status -ne "succeeded" -and $resp.status -ne "failed" -and $tries -lt 90) {
  Start-Sleep -Seconds 2
  $resp = Invoke-RestMethod -Uri "https://api.replicate.com/v1/predictions/$($resp.id)" -Headers $headers
  $tries++
}
if ($resp.status -ne "succeeded") { Write-Output "FAILED: $($resp.status)"; exit 1 }

$url = if ($resp.output -is [array]) { $resp.output[0] } else { $resp.output }
Write-Output "[clean-bg] url: $url"

$ascTemp = "C:\Windows\Temp\replicate_dl_$([Guid]::NewGuid().ToString('N')).webp"
$wc = New-Object System.Net.WebClient
$wc.DownloadFile($url, $ascTemp)
$wc.Dispose()
& ffmpeg -y -hide_banner -loglevel error -i $ascTemp $Out
Remove-Item $ascTemp -Force
Write-Output "[clean-bg] saved: $Out ($((Get-Item $Out).Length) bytes)"
