param(
  [int]$Seed = 42,
  [string]$Out = "D:\Prog\smm-posting-poc\poc-slide-02-26pct.png"
)
# Ensure target dir
$outDir = Split-Path -Parent $Out
if (-not (Test-Path $outDir)) { New-Item -ItemType Directory -Path $outDir -Force | Out-Null }
$ErrorActionPreference = "Stop"
$token = (Get-Content "D:\Prog\SMM\.env" | Where-Object { $_ -match "^REPLICATE_API_TOKEN=" }) -replace "^REPLICATE_API_TOKEN=", ""

# LOCKED STYLE PREFIX — будет одинаковый для всех слайдов карусели
$lockedPrefix = @"
Square 4:5 social media slide, retrofuturistic 1980s vaporwave aesthetic, deep purple background hex 1a0d3a, vibrant yellow accent hex e8f045, white sans-serif text, subtle pixelated geometric grid texture overlay covering entire canvas, low-poly wireframe horizon line in distance, atmospheric purple haze with radial gradient glow, very subtle CRT scanline horizontal lines, minimal flat 2D illustration style, sci-fi blueprint feel, single dominant element composition, NO photographs, NO people faces, NO realistic 3D rendering, brand-consistent media slide
"@

# PER-SLIDE CONTENT — варьируется
$slideContent = @"
Main element: massive bold yellow number "26%" rendered very large in upper-left quadrant, taking 40% of canvas. Below the number: clean white text reading "всех увольнений в США в апреле 2026 — напрямую из-за ИИ". Yellow horizontal accent bar under the text. Secondary smaller yellow text "21 490 рабочих мест" in middle area with white subtitle "за один месяц". Bottom corners: small white rounded pill with black text "2/7" bottom-left, small white rounded pill with black text "TRAFFNEWS" bottom-right. Centered small white text "Подробнее на traffnews.com" between pills. Top-left small monospace text "Сокращения 2026", top-right "2026". Exact text rendering critical — display only these exact characters: 26%, 21 490, 2/7, TRAFFNEWS, 2026.
"@

$fullPrompt = "$lockedPrefix`n`n$slideContent"
Write-Output "[poc] prompt length: $($fullPrompt.Length) chars"

$body = @{
  input = @{
    prompt = $fullPrompt
    size = "1024x1280"
    style = "digital_illustration"
  }
} | ConvertTo-Json -Depth 5

$headers = @{
  "Authorization" = "Bearer $token"
  "Content-Type" = "application/json"
  "Prefer" = "wait"
}

Write-Output "[poc] submitting to Recraft v3..."
$bodyBytes = [System.Text.Encoding]::UTF8.GetBytes($body)
$resp = Invoke-RestMethod -Uri "https://api.replicate.com/v1/models/recraft-ai/recraft-v3/predictions" -Method Post -Headers $headers -Body $bodyBytes -ContentType "application/json; charset=utf-8"
Write-Output "[poc] status=$($resp.status) id=$($resp.id)"

$tries = 0
while ($resp.status -ne "succeeded" -and $resp.status -ne "failed" -and $tries -lt 90) {
  Start-Sleep -Seconds 2
  $resp = Invoke-RestMethod -Uri "https://api.replicate.com/v1/predictions/$($resp.id)" -Headers $headers
  $tries++
}

if ($resp.status -ne "succeeded") {
  Write-Output "[poc] FAILED status=$($resp.status) error=$($resp.error)"
  $resp | ConvertTo-Json -Depth 5
  exit 1
}

$url = if ($resp.output -is [array]) { $resp.output[0] } else { $resp.output }
Write-Output "[poc] output url: $url"

# Determine output ext (webp/png) from url
$ext = [System.IO.Path]::GetExtension($url)
if ($ext -eq "") { $ext = ".webp" }
$tempOut = [System.IO.Path]::ChangeExtension($Out, $ext.TrimStart("."))

# Download to ASCII temp path via WebClient, then Copy-Item -LiteralPath (Cyrillic-safe move)
$ascTemp = "C:\Windows\Temp\replicate_dl_$([Guid]::NewGuid().ToString('N')).webp"
$wc = New-Object System.Net.WebClient
$wc.DownloadFile($url, $ascTemp)
$wc.Dispose()
Write-Output "[poc] downloaded to ASCII path: $ascTemp ($((Get-Item $ascTemp).Length) bytes)"
Copy-Item -LiteralPath $ascTemp -Destination $tempOut -Force
Remove-Item -LiteralPath $ascTemp -Force
Write-Output "[poc] moved to target: $tempOut"

# Convert to PNG if webp
if ($ext -eq ".webp") {
  & ffmpeg -y -hide_banner -loglevel error -i $tempOut $Out
  if ($LASTEXITCODE -eq 0) {
    Remove-Item $tempOut
    Write-Output "[poc] converted to PNG: $Out ($((Get-Item $Out).Length) bytes)"
  } else {
    Write-Output "[poc] ffmpeg failed, keeping webp at: $tempOut"
  }
} else {
  if ($tempOut -ne $Out) { Move-Item $tempOut $Out -Force }
  Write-Output "[poc] saved: $Out"
}
Write-Output "[poc] metrics: $($resp.metrics | ConvertTo-Json -Compress)"
