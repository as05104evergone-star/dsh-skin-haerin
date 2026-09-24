<#
  Haerin Skin - maintenance tool
  ---------------------------------------------------------------------------
  Regenerates the two derived inputs of the skin from the DSH client that is
  actually installed on this machine:

    1. haerin-skin/_upstream/{design-platform,gradient-shadow-text,scrollbar}.css
       The upstream token sheets. preview.html links them so the preview page
       paints with exactly the client's surfaces, borders and shadows.

    2. tools/map-{light,dark}.css
       Every `--dsw-alias-*` / `--dsw-specific-*` declaration of each mode,
       straight out of the upstream sheet. haerin.css embeds these two lists
       (see the "映射层" comment blocks) so that an explicit skin mode keeps
       working even when it disagrees with the client's own light/dark setting.

  Run this after a DSH update, then diff the generated maps against the ones
  embedded in haerin.css:

      pwsh -File tools\extract-upstream.ps1
      pwsh -File tools\extract-upstream.ps1 -Check

  ASCII-only on purpose: Windows PowerShell 5.1 reads .ps1 without a BOM as
  ANSI, so non-ASCII source would be mis-parsed on a non-UTF8 code page.
#>
#Requires -Version 5.1
[CmdletBinding()]
param(
  [switch]$Check,
  [string]$ClientPath
)

$ErrorActionPreference = 'Stop'
$Utf8 = New-Object System.Text.UTF8Encoding($false)

$SkinRoot = Split-Path -Parent $PSScriptRoot
$UpstreamDir = Join-Path $SkinRoot 'haerin-skin\_upstream'

function Read-Text([string]$Path) { return [System.IO.File]::ReadAllText($Path, $Utf8) }
function Write-Text([string]$Path, [string]$Text) { [System.IO.File]::WriteAllText($Path, $Text, $Utf8) }

function Find-ThemeBundle {
  if ($ClientPath) {
    if (-not (Test-Path -LiteralPath $ClientPath)) { throw "no such file: $ClientPath" }
    return (Resolve-Path -LiteralPath $ClientPath).Path
  }

  $roots = New-Object System.Collections.Generic.List[string]
  if ($env:DSH_HOME) {
    $profiles = Join-Path $env:DSH_HOME 'profiles'
    $roots.Add((Join-Path $profiles 'node_modules'))
    if (Test-Path -LiteralPath $profiles) {
      foreach ($dir in Get-ChildItem -LiteralPath $profiles -Directory -ErrorAction SilentlyContinue) {
        $roots.Add((Join-Path $dir.FullName 'node_modules'))
      }
    }
  }
  foreach ($base in @($env:DSH_DESKTOP_APP, (Join-Path (Split-Path -Parent $SkinRoot) 'DSH Desktop\resources\app'))) {
    if ($base) { $roots.Add((Join-Path $base 'node_modules')) }
  }

  foreach ($root in $roots) {
    $candidate = Join-Path $root '@deepseek-ai\dsh-client-ui-theme\lib\client.js'
    if (Test-Path -LiteralPath $candidate) { return (Resolve-Path -LiteralPath $candidate).Path }
  }
  throw 'could not locate @deepseek-ai/dsh-client-ui-theme/lib/client.js; pass -ClientPath'
}

$bundle = Find-ThemeBundle
Write-Host "theme bundle: $bundle"
$source = Read-Text $bundle

# The client bundle embeds each stylesheet as `var <name>_css_default = "...."`.
$pattern = 'var ([a-z_]+)_css_default = "((?:[^"\\]|\\.)*)";'
$sheets = @{}
foreach ($match in [regex]::Matches($source, $pattern)) {
  $name = $match.Groups[1].Value
  $body = $match.Groups[2].Value -replace '\\"', '"' -replace '\\\\', '\'
  $sheets[$name] = $body
}

$wanted = @{
  'design_platform'      = 'design-platform.css'
  'gradient_shadow_text' = 'gradient-shadow-text.css'
  'scrollbar'            = 'scrollbar.css'
}

if (-not $Check) {
  if (-not (Test-Path -LiteralPath $UpstreamDir)) { New-Item -ItemType Directory -Force -Path $UpstreamDir | Out-Null }
}

$changed = New-Object System.Collections.Generic.List[string]
foreach ($key in $wanted.Keys) {
  if (-not $sheets.ContainsKey($key)) { throw "theme bundle has no '$key' stylesheet" }
  $target = Join-Path $UpstreamDir $wanted[$key]
  $next = $sheets[$key]
  $previous = if (Test-Path -LiteralPath $target) { Read-Text $target } else { $null }
  if ($previous -ne $next) { $changed.Add($wanted[$key]) }
  if (-not $Check) { Write-Text $target $next }
  Write-Host ("  {0,-26} {1} chars{2}" -f $wanted[$key], $next.Length, $(if ($previous -ne $next) { '  <- updated' } else { '' }))
}

# Split the design-platform sheet into its light and dark halves and keep every
# alias / specific declaration, in source order.
$platform = $sheets['design_platform']
$decls = [regex]::Matches($platform, '--dsw-(?:alias|specific)-[a-z0-9-]+:[^;}]+')
if ($decls.Count -eq 0 -or $decls.Count % 2 -ne 0) {
  throw "unexpected token declaration count ($($decls.Count)); the upstream sheet changed shape"
}
$half = [int]($decls.Count / 2)
$light = @(); $dark = @()
for ($i = 0; $i -lt $decls.Count; $i++) {
  $line = '  ' + $decls[$i].Value + ';'
  if ($i -lt $half) { $light += $line } else { $dark += $line }
}

$lightNames = $light | ForEach-Object { ($_ -split ':')[0].Trim() }
$darkNames = $dark | ForEach-Object { ($_ -split ':')[0].Trim() }
if (Compare-Object $lightNames $darkNames) {
  throw 'light and dark token name sets differ; the upstream sheet changed shape'
}

foreach ($pair in @(@{ name = 'map-light.css'; lines = $light }, @{ name = 'map-dark.css'; lines = $dark })) {
  $target = Join-Path $PSScriptRoot $pair.name
  $next = ($pair.lines -join "`r`n") + "`r`n"
  $previous = if (Test-Path -LiteralPath $target) { Read-Text $target } else { $null }
  if ($previous -ne $next) { $changed.Add($pair.name) }
  if (-not $Check) { Write-Text $target $next }
  Write-Host ("  {0,-26} {1} tokens{2}" -f $pair.name, $pair.lines.Count, $(if ($previous -ne $next) { '  <- updated' } else { '' }))
}

Write-Host ''
if ($changed.Count -eq 0) {
  Write-Host 'everything up to date.' -ForegroundColor Green
  exit 0
}

Write-Host ("changed: " + ($changed -join ', ')) -ForegroundColor Yellow
if ($Check) {
  Write-Host 'run again without -Check to write the files.' -ForegroundColor Yellow
  exit 2
}
Write-Host 'Now diff tools\map-*.css against the "映射层" blocks in haerin-skin\haerin.css'
Write-Host 'and add or retarget whatever the upstream release changed.'
