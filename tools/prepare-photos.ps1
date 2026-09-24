<#
  Haerin Skin - photo preparation tool
  ---------------------------------------------------------------------------
  Bakes two "background plates" out of user supplied photos:

      art/day-photo.jpg     from -Day  <file>
      art/night-photo.jpg   from -Night <file>

  A raw photo cannot simply be dropped behind the UI: it is too contrasty and
  its edges cut hard against the wash. So each plate is composited here:

    1. optional downscale (height cap, keeps the file small)
    2. optional saturation pull (softens a photo without killing its colour)
    3. veil: a flat wash-coloured overlay that lowers contrast
    4. left fade: the photo dissolves into the wash towards the left edge, so
       the conversation column keeps a calm backdrop behind its text
    5. bottom fade: same, upwards from the bottom edge

  ASCII-only on purpose (Windows PowerShell 5.1 reads BOM-less .ps1 as ANSI).

  Usage:
      pwsh -File tools\prepare-photos.ps1 -Day "D:\pics\a.jpg" -Night "D:\pics\b.jpg"
      pwsh -File tools\prepare-photos.ps1 -Day "D:\pics\a.jpg" -DayVeil 30
#>
#Requires -Version 5.1
[CmdletBinding()]
param(
  [string]$Day,
  [string]$Night,
  [ValidateRange(0, 100)][int]$DayVeil = 40,
  [ValidateRange(0, 100)][int]$NightVeil = 26,
  [ValidateRange(0.0, 1.0)][double]$DaySaturation = 0.82,
  [ValidateRange(0.0, 1.0)][double]$NightSaturation = 1.0,
  [ValidateRange(0, 90)][int]$FadeLeft = 42,
  [ValidateRange(0, 40)][int]$FadeBottom = 14,
  [int]$MaxHeight = 1600,
  [ValidateRange(60, 100)][int]$Quality = 86
)

$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing

$SkinRoot = Split-Path -Parent $PSScriptRoot
$ArtDir = Join-Path $SkinRoot 'haerin-skin\art'
$Washes = @{ day = '#F4F8FD'; night = '#0B0A0A' }

function Convert-ToPlate {
  param(
    [Parameter(Mandatory)][string]$Source,
    [Parameter(Mandatory)][string]$Target,
    [Parameter(Mandatory)][string]$Wash,
    [Parameter(Mandatory)][int]$Veil,
    [Parameter(Mandatory)][double]$Saturation
  )

  if (-not (Test-Path -LiteralPath $Source)) { throw "no such photo: $Source" }

  $img = [System.Drawing.Image]::FromFile((Resolve-Path -LiteralPath $Source).Path)
  try {
    $scale = 1.0
    if ($MaxHeight -gt 0 -and $img.Height -gt $MaxHeight) { $scale = $MaxHeight / $img.Height }
    $w = [int][Math]::Round($img.Width * $scale)
    $h = [int][Math]::Round($img.Height * $scale)

    $canvas = New-Object System.Drawing.Bitmap($w, $h, [System.Drawing.Imaging.PixelFormat]::Format24bppRgb)
    $g = [System.Drawing.Graphics]::FromImage($canvas)
    try {
      $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
      $g.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
      $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
      $g.CompositingQuality = [System.Drawing.Drawing2D.CompositingQuality]::HighQuality

      $washColor = [System.Drawing.ColorTranslator]::FromHtml($Wash)
      $g.Clear($washColor)

      # --- photo, optionally desaturated -------------------------------------
      $dest = New-Object System.Drawing.Rectangle(0, 0, $w, $h)
      if ($Saturation -lt 1.0) {
        $inv = 1.0 - $Saturation
        $sr = $inv * 0.3086; $sg = $inv * 0.6094; $sb = $inv * 0.0820
        $cm = New-Object System.Drawing.Imaging.ColorMatrix
        $cm.Matrix00 = $sr + $Saturation; $cm.Matrix01 = $sr; $cm.Matrix02 = $sr
        $cm.Matrix10 = $sg; $cm.Matrix11 = $sg + $Saturation; $cm.Matrix12 = $sg
        $cm.Matrix20 = $sb; $cm.Matrix21 = $sb; $cm.Matrix22 = $sb + $Saturation
        $cm.Matrix33 = 1.0; $cm.Matrix44 = 1.0
        $ia = New-Object System.Drawing.Imaging.ImageAttributes
        $ia.SetColorMatrix($cm)
        $g.DrawImage($img, $dest, 0, 0, $img.Width, $img.Height, [System.Drawing.GraphicsUnit]::Pixel, $ia)
        $ia.Dispose()
      }
      else {
        $g.DrawImage($img, $dest, 0, 0, $img.Width, $img.Height, [System.Drawing.GraphicsUnit]::Pixel)
      }

      # --- veil: flat wash over everything ----------------------------------
      if ($Veil -gt 0) {
        $veilColor = [System.Drawing.Color]::FromArgb([int]($Veil * 2.55), $washColor)
        $brush = New-Object System.Drawing.SolidBrush($veilColor)
        $g.FillRectangle($brush, 0, 0, $w, $h)
        $brush.Dispose()
      }

      # --- left fade ---------------------------------------------------------
      if ($FadeLeft -gt 0) {
        $fx = [single]([Math]::Max(1, [int]($w * $FadeLeft / 100.0)))
        $rect = New-Object System.Drawing.RectangleF(0, 0, $fx, $h)
        $brush = New-Object System.Drawing.Drawing2D.LinearGradientBrush($rect, $washColor, $washColor, [single]0, $false)
        $blend = New-Object System.Drawing.Drawing2D.ColorBlend(2)
        $blend.Colors = @(
          [System.Drawing.Color]::FromArgb(255, $washColor),
          [System.Drawing.Color]::FromArgb(0, $washColor)
        )
        $blend.Positions = @([single]0.0, [single]1.0)
        $brush.InterpolationColors = $blend
        $g.FillRectangle($brush, $rect)
        $brush.Dispose()
      }

      # --- bottom fade -------------------------------------------------------
      if ($FadeBottom -gt 0) {
        $fy = [single]([Math]::Max(1, [int]($h * $FadeBottom / 100.0)))
        # 注意：逗号比 - 结合得更紧，`Rect(0, $h - $fy, ...)` 会被解析成数组相减，
        # 所以这里显式用 -ArgumentList 并给减法加括号。
        $rect = New-Object System.Drawing.RectangleF -ArgumentList @(0, ($h - $fy), $w, $fy)
        $brush = New-Object System.Drawing.Drawing2D.LinearGradientBrush($rect, $washColor, $washColor, [single]90, $false)
        $blend = New-Object System.Drawing.Drawing2D.ColorBlend(2)
        $blend.Colors = @(
          [System.Drawing.Color]::FromArgb(0, $washColor),
          [System.Drawing.Color]::FromArgb(255, $washColor)
        )
        $blend.Positions = @([single]0.0, [single]1.0)
        $brush.InterpolationColors = $blend
        $g.FillRectangle($brush, $rect)
        $brush.Dispose()
      }
    }
    finally { $g.Dispose() }

    if (-not (Test-Path -LiteralPath $ArtDir)) { New-Item -ItemType Directory -Force -Path $ArtDir | Out-Null }

    $codec = [System.Drawing.Imaging.ImageCodecInfo]::GetImageEncoders() | Where-Object { $_.MimeType -eq 'image/jpeg' }
    $params = New-Object System.Drawing.Imaging.EncoderParameters(1)
    $params.Param[0] = New-Object System.Drawing.Imaging.EncoderParameter([System.Drawing.Imaging.Encoder]::Quality, [int]$Quality)
    $canvas.Save($Target, $codec, $params)
    $params.Dispose()
    $canvas.Dispose()

    Write-Host ("  {0,-18} {1}x{2}  {3:N0} KB" -f (Split-Path -Leaf $Target), $w, $h, ((Get-Item $Target).Length / 1KB))
  }
  finally { $img.Dispose() }
}

Write-Host ''
Write-Host 'Haerin skin - baking background plates' -ForegroundColor Magenta
Write-Host ('-' * 60)

if ($Day) {
  Convert-ToPlate -Source $Day -Target (Join-Path $ArtDir 'day-photo.jpg') -Wash $Washes.day -Veil $DayVeil -Saturation $DaySaturation
}
if ($Night) {
  Convert-ToPlate -Source $Night -Target (Join-Path $ArtDir 'night-photo.jpg') -Wash $Washes.night -Veil $NightVeil -Saturation $NightSaturation
}
if (-not $Day -and -not $Night) {
  Write-Host 'nothing to do: pass -Day and/or -Night' -ForegroundColor Yellow
  exit 1
}

Write-Host ('-' * 60)
Write-Host 'now run install.cmd to copy art\ into the client.' -ForegroundColor Green
