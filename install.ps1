<#
  海粼 Haerin · DSH Skin —— 安装器
  ---------------------------------------------------------------------------
  把皮肤挂到 DSH Web 壳（dist）上，不改动任何插件、不需要重新打包：

    <dist>/skin/haerin/haerin.css        调色板（昼 + 夜）
    <dist>/skin/haerin/haerin-boot.js    首帧引导（防止刷新闪白）
    <dist>/skin/haerin/haerin.js         右下角猫耳开关

  并在 <dist>/index.html 的 </head> 前插入三行引用（带标记，可重复执行）。

  用法：
    pwsh -File install.ps1                     # 安装 / 更新（自动探测 dist）
    pwsh -File install.ps1 -Action status      # 只看状态
    pwsh -File install.ps1 -Action uninstall   # 完整卸载
    pwsh -File install.ps1 -DistPath "D:\...\dsh-web-frontend\dist"   # 指定目标

  安装后在客户端里按托盘 →「重新加载界面」刷新一次即可看到皮肤；
  之后昼/夜切换是即时的，不需要再刷新。
#>
#Requires -Version 5.1
[CmdletBinding()]
param(
  [ValidateSet('install', 'uninstall', 'status')]
  [string]$Action = 'install',

  [string[]]$DistPath = @(),

  [switch]$Quiet
)

$ErrorActionPreference = 'Stop'
$Utf8 = New-Object System.Text.UTF8Encoding($false)

$SourceDir = Join-Path $PSScriptRoot 'haerin-skin'
$Assets = @('haerin.css', 'haerin-boot.js', 'haerin.js')
# 只比对注释里的标记词，不比对整行：注释尾巴带说明文字，而且 HTML 注释内部不能再出现 "--"。
$BeginToken = 'haerin-skin:begin'
$EndToken = 'haerin-skin:end'
$SkinSubPath = 'skin\haerin'

function Write-Info([string]$Text) { if (-not $Quiet) { Write-Host $Text } }

function Read-Text([string]$Path) { return [System.IO.File]::ReadAllText($Path, $Utf8) }

function Write-Text([string]$Path, [string]$Text) {
  [System.IO.File]::WriteAllText($Path, $Text, $Utf8)
}

function Get-SkinBlock {
  # 用 here-string 而不是 @(...) -join：PowerShell 里逗号比 + 结合得更紧，
  # `@($a + 'x', 'y')` 会被解析成 `$a + ('x','y')`，分隔符会被吃掉。
  # 说明文字必须留在 --> 里面，否则会被浏览器当成正文渲染出来。
  return @"
<!-- $BeginToken · 海粼皮肤 · 由 Skin\install.ps1 维护 -->
<link rel="stylesheet" href="./skin/haerin/haerin.css">
<script src="./skin/haerin/haerin-boot.js"></script>
<script src="./skin/haerin/haerin.js" defer></script>
<!-- $EndToken -->
"@
}

# 定位已存在的皮肤块：[开始注释起点, 结束注释终点]；找不到返回 $null。
function Find-SkinBlock([string]$Text) {
  $token = $Text.IndexOf($BeginToken)
  if ($token -lt 0) { return $null }
  $open = $Text.LastIndexOf('<!--', $token)
  if ($open -lt 0) { return $null }
  $endToken = $Text.IndexOf($EndToken, $token)
  if ($endToken -lt 0) { return $null }
  $close = $Text.IndexOf('-->', $endToken)
  if ($close -lt 0) { return $null }
  return @{ Start = $open; End = $close + 3 }
}

# --------------------------------------------------------------------- 探测 dist

function Get-DistCandidates {
  $list = New-Object System.Collections.Generic.List[string]

  foreach ($item in $DistPath) {
    if ($item) { $list.Add($item) }
  }

  $appRoots = New-Object System.Collections.Generic.List[string]
  if ($env:DSH_DESKTOP_APP) { $appRoots.Add($env:DSH_DESKTOP_APP) }
  $appRoots.Add((Join-Path $PSScriptRoot '..\DSH Desktop\resources\app'))
  foreach ($base in @($env:LOCALAPPDATA, $env:ProgramFiles, ${env:ProgramFiles(x86)})) {
    if (-not $base) { continue }
    $appRoots.Add((Join-Path $base 'Programs\DSH Desktop\resources\app'))
    $appRoots.Add((Join-Path $base 'DSH Desktop\resources\app'))
  }

  foreach ($root in $appRoots) {
    if ($root) { $list.Add((Join-Path $root 'node_modules\@deepseek-ai\dsh-web-frontend\dist')) }
  }

  # Profile 里那一份才是被 host 真正加载的（pnpm 安装在 ~/.dsh/profiles）
  if ($env:DSH_HOME) {
    $profiles = Join-Path $env:DSH_HOME 'profiles'
    if (Test-Path -LiteralPath $profiles) {
      $list.Add((Join-Path $profiles 'node_modules\@deepseek-ai\dsh-web-frontend\dist'))
      foreach ($dir in Get-ChildItem -LiteralPath $profiles -Directory -ErrorAction SilentlyContinue) {
        $list.Add((Join-Path $dir.FullName 'node_modules\@deepseek-ai\dsh-web-frontend\dist'))
      }
    }
  }

  $found = New-Object System.Collections.Generic.List[string]
  foreach ($candidate in $list) {
    if (-not $candidate) { continue }
    $index = Join-Path $candidate 'index.html'
    if (-not (Test-Path -LiteralPath $index)) { continue }
    $full = (Resolve-Path -LiteralPath $candidate).Path
    if (-not $found.Contains($full)) { $found.Add($full) }
  }
  return $found
}

# ------------------------------------------------------------------- 单点操作

function Get-DistState([string]$Dist) {
  $index = Join-Path $Dist 'index.html'
  $text = Read-Text $index
  $patched = $null -ne (Find-SkinBlock $text)
  $assetsPresent = $true
  foreach ($asset in $Assets) {
    if (-not (Test-Path -LiteralPath (Join-Path $Dist (Join-Path $SkinSubPath $asset)))) {
      $assetsPresent = $false
    }
  }
  return [pscustomobject]@{ Patched = $patched; Assets = $assetsPresent }
}

function Install-Into([string]$Dist) {
  # skin\haerin 归皮肤所有：整目录重建，免得改名/删掉的旧素材留在 dist 里
  $skinDir = Join-Path $Dist $SkinSubPath
  if (Test-Path -LiteralPath $skinDir) { Remove-Item -LiteralPath $skinDir -Recurse -Force }
  New-Item -ItemType Directory -Force -Path $skinDir | Out-Null
  foreach ($asset in $Assets) {
    $src = Join-Path $SourceDir $asset
    if (-not (Test-Path -LiteralPath $src)) { throw "缺少皮肤文件：$src" }
    Copy-Item -LiteralPath $src -Destination (Join-Path $skinDir $asset) -Force
  }
  # 可选素材目录（自绘 SVG + 用户自备照片），有就一起带过去
  $artSrc = Join-Path $SourceDir 'art'
  if (Test-Path -LiteralPath $artSrc) {
    $artDst = Join-Path $skinDir 'art'
    New-Item -ItemType Directory -Force -Path $artDst | Out-Null
    Copy-Item -Path (Join-Path $artSrc '*') -Destination $artDst -Recurse -Force
  }

  $index = Join-Path $Dist 'index.html'
  $backup = Join-Path $Dist 'index.html.haerin-orig'
  $text = Read-Text $index
  if (-not (Test-Path -LiteralPath $backup)) {
    Write-Text $backup $text
  }

  $block = Get-SkinBlock
  $found = Find-SkinBlock $text
  if ($found) {
    $text = $text.Substring(0, $found.Start) + $block + $text.Substring($found.End)
  }
  else {
    $anchor = '</head>'
    $at = $text.IndexOf($anchor, [System.StringComparison]::OrdinalIgnoreCase)
    if ($at -lt 0) { throw "index.html 里找不到 </head>：$index" }
    $text = $text.Substring(0, $at) + $block + "`n  " + $text.Substring($at)
  }
  Write-Text $index $text
}

function Uninstall-From([string]$Dist) {
  $index = Join-Path $Dist 'index.html'
  if (Test-Path -LiteralPath $index) {
    $text = Read-Text $index
    $found = Find-SkinBlock $text
    if ($found) {
      $head = $text.Substring(0, $found.Start).TrimEnd("`r", "`n", ' ', "`t")
      $tail = $text.Substring($found.End).TrimStart("`r", "`n")
      Write-Text $index ($head + "`n" + $tail)
    }
  }
  $skinDir = Join-Path $Dist $SkinSubPath
  if (Test-Path -LiteralPath $skinDir) {
    Remove-Item -LiteralPath $skinDir -Recurse -Force
  }
  $skinRoot = Join-Path $Dist 'skin'
  if ((Test-Path -LiteralPath $skinRoot) -and
      -not (Get-ChildItem -LiteralPath $skinRoot -Force -ErrorAction SilentlyContinue)) {
    Remove-Item -LiteralPath $skinRoot -Force
  }
  $backup = Join-Path $Dist 'index.html.haerin-orig'
  if (Test-Path -LiteralPath $backup) { Remove-Item -LiteralPath $backup -Force }
}

# ------------------------------------------------------------------------ 主流程

$dists = Get-DistCandidates

if ($dists.Count -eq 0) {
  Write-Host '没有找到 DSH Web 壳的 dist 目录。' -ForegroundColor Yellow
  Write-Host '请用 -DistPath 指定包含 index.html 的 dist 路径，例如：'
  Write-Host '  pwsh -File install.ps1 -DistPath "C:\Users\你\.dsh\profiles\node_modules\@deepseek-ai\dsh-web-frontend\dist"'
  exit 1
}

Write-Info ''
Write-Info '海粼 Haerin · DSH Skin' -ForegroundColor Magenta
Write-Info "动作：$Action    目标：$($dists.Count) 个 dist"
Write-Info ('-' * 72)

foreach ($dist in $dists) {
  switch ($Action) {
    'install' {
      Install-Into $dist
      Write-Host ('  [已安装] ' + $dist) -ForegroundColor Green
    }
    'uninstall' {
      Uninstall-From $dist
      Write-Host ('  [已卸载] ' + $dist) -ForegroundColor DarkGray
    }
    'status' {
      $state = Get-DistState $dist
      $mark = if ($state.Patched -and $state.Assets) { '已启用' } else { '未启用' }
      $color = if ($state.Patched -and $state.Assets) { 'Green' } else { 'DarkGray' }
      Write-Host ("  [$mark] " + $dist) -ForegroundColor $color
      Write-Host ("           index.html 标记：$($state.Patched)    皮肤文件就位：$($state.Assets)")
    }
  }
}

Write-Info ('-' * 72)

if ($Action -eq 'install') {
  Write-Info '接下来只需要刷新一次客户端界面（之后昼 / 夜切换都是即时的）：'
  Write-Info '  · 托盘图标右键 →「重新加载界面」'
  Write-Info '  · 或直接重启 DSH Desktop'
  Write-Info ''
  Write-Info '开关在窗口右下角：点击切换 昼 ⇄ 夜，右键跟随客户端外观，Shift+点击收起皮肤。'
}
elseif ($Action -eq 'uninstall') {
  Write-Info '已还原 index.html（备份 index.html.haerin-orig 也一并清理），刷新一次界面即可。'
}
