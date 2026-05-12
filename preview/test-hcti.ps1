$ErrorActionPreference = "Stop"
$envFile = Get-Content "D:\Prog\SMM\.env"
$userId = ($envFile | Where-Object { $_ -match "^HCTI_USER_ID=" }) -replace "^HCTI_USER_ID=", ""
$apiKey = ($envFile | Where-Object { $_ -match "^HCTI_API_KEY=" }) -replace "^HCTI_API_KEY=", ""

$tplPath = "D:\Prog\Постинг\docs\slide-templates\slide-02-big-number.html"
$varsPath = "D:\Prog\Постинг\preview\test-hcti-vars.json"

$html = Get-Content -LiteralPath $tplPath -Raw -Encoding UTF8
$varsJson = Get-Content -LiteralPath $varsPath -Raw -Encoding UTF8
$vars = $varsJson | ConvertFrom-Json

foreach ($prop in $vars.PSObject.Properties) {
  $token = "{{" + $prop.Name + "}}"
  $html = $html.Replace($token, $prop.Value)
}

$bodyMatch = [regex]::Match($html, "(?s)<body[^>]*>(.*?)</body>")
$bodyContent = $bodyMatch.Groups[1].Value
$styleMatch = [regex]::Match($html, "(?s)<style[^>]*>(.*?)</style>")
$cssContent = $styleMatch.Groups[1].Value

$pair = "${userId}:${apiKey}"
$basicAuth = [Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes($pair))

$payload = @{
  html = $bodyContent
  css = $cssContent
  google_fonts = "Anton|Inter:400,500,700,900|JetBrains+Mono:700"
  viewport_width = 1080
  viewport_height = 1350
  device_scale = 2
} | ConvertTo-Json -Depth 5

$payloadBytes = [System.Text.Encoding]::UTF8.GetBytes($payload)

Write-Output "[hcti] sending to hcti.io..."
$headers = @{
  "Authorization" = "Basic $basicAuth"
  "Content-Type" = "application/json; charset=utf-8"
}
try {
  $resp = Invoke-RestMethod -Uri "https://hcti.io/v1/image" -Headers $headers -Method Post -Body $payloadBytes
  Write-Output "[hcti] URL: $($resp.url)"
  $outPath = "D:\Prog\smm-posting-poc\hcti-test-slide-02.png"
  $wc = New-Object System.Net.WebClient
  $wc.DownloadFile($resp.url, $outPath)
  $wc.Dispose()
  Write-Output "[hcti] saved: $outPath ($((Get-Item $outPath).Length) bytes)"
} catch {
  Write-Output "STATUS: $($_.Exception.Response.StatusCode.value__)"
  Write-Output "ERR: $($_.Exception.Message)"
  if ($_.ErrorDetails) { Write-Output $_.ErrorDetails.Message }
}
