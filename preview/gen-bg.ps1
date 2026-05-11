param(
  [string]$Prompt = "retrofuturistic 1980s vaporwave aesthetic, abstract perspective grid receding to horizon, distant pixelated mountains in wireframe, dark deep purple background #1a0d3a, subtle yellow accent lines #e8f045, low contrast atmospheric haze, 1:1 square, NO text, NO logos, NO people, NO objects, minimal composition for use as background overlay, sci-fi blueprint feel",
  [string]$Out = "D:\Prog\Постинг\preview\bg-retrofuture-01.png",
  [string]$Model = "black-forest-labs/flux-schnell"
)
$ErrorActionPreference = "Stop"
$token = (Get-Content "D:\Prog\SMM\.env" | Where-Object { $_ -match "^REPLICATE_API_TOKEN=" }) -replace "^REPLICATE_API_TOKEN=", ""

$body = @{
  input = @{
    prompt = $Prompt
    aspect_ratio = "4:5"
    num_outputs = 1
    output_format = "png"
    output_quality = 90
    disable_safety_checker = $false
    go_fast = $true
  }
} | ConvertTo-Json -Depth 5

Write-Output "[gen-bg] submitting prediction (model=$Model)..."
$headers = @{
  "Authorization" = "Bearer $token"
  "Content-Type" = "application/json"
  "Prefer" = "wait"
}
$resp = Invoke-RestMethod -Uri "https://api.replicate.com/v1/models/$Model/predictions" -Method Post -Headers $headers -Body $body
Write-Output "[gen-bg] status=$($resp.status) id=$($resp.id)"

# Poll if not done
$tries = 0
while ($resp.status -ne "succeeded" -and $resp.status -ne "failed" -and $tries -lt 60) {
  Start-Sleep -Seconds 2
  $resp = Invoke-RestMethod -Uri "https://api.replicate.com/v1/predictions/$($resp.id)" -Headers $headers
  $tries++
}
if ($resp.status -ne "succeeded") {
  Write-Output "[gen-bg] FAILED status=$($resp.status) error=$($resp.error)"
  exit 1
}

$url = if ($resp.output -is [array]) { $resp.output[0] } else { $resp.output }
Write-Output "[gen-bg] output url: $url"
Invoke-WebRequest -Uri $url -OutFile $Out
Write-Output "[gen-bg] saved: $Out ($((Get-Item $Out).Length) bytes)"
