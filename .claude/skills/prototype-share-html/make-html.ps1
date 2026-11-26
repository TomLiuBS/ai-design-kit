# Usage: powershell -NoProfile -File make-html.ps1 -Name <app>/<proto>/<version folder> [-OutName <file base name>] [-OutDir <folder>] [-RepoRoot <path>]
# Builds ONE standalone HTML file from generated/prototypes/<app>/<proto>/<version>/ and saves it on the user's Desktop.
# Local CSS / JS are inlined; local images (svg/png/...) referenced from HTML / CSS / JS are embedded as data: URIs.
# NOTE: keep this file ASCII-only (Windows PowerShell 5.1 reads BOM-less files as ANSI).
param(
  [Parameter(Mandatory = $true)][string]$Name,
  [string]$RepoRoot,
  [string]$OutDir,
  [string]$OutName
)
$ErrorActionPreference = 'Stop'
if (-not $RepoRoot) { $RepoRoot = (Resolve-Path (Join-Path (Split-Path $MyInvocation.MyCommand.Path) '..\..\..')).Path }
$utf8 = New-Object System.Text.UTF8Encoding($false)

# -Name is <app>/<proto>/<version folder>; a bare version folder name is also accepted (searched 3 levels under generated\prototypes)
$protoRoot = Join-Path $RepoRoot 'generated\prototypes'
$src = Join-Path $protoRoot ($Name -replace '/', '\')
if (-not (Test-Path (Join-Path $src 'index.html'))) {
  $hit = @(Get-ChildItem $protoRoot -Directory | ForEach-Object { Get-ChildItem $_.FullName -Directory } | ForEach-Object { Get-ChildItem $_.FullName -Directory } | Where-Object { $_.Name -eq $Name })
  if ($hit.Count -eq 1) { $src = $hit[0].FullName } elseif ($hit.Count -gt 1) { throw "ambiguous name: $Name (give <app>/<proto>/<version>)" }
}
$Name = Split-Path $src -Leaf
$indexPath = Join-Path $src 'index.html'
if (-not (Test-Path $indexPath)) { throw "index.html not found: $src" }

$desktop = if ($OutDir) { $OutDir } else { [Environment]::GetFolderPath('Desktop') }   # Desktop may be redirected to OneDrive; -OutDir is for testing
$base = "{0}_{1}" -f $(if ($OutName) { $OutName } else { $Name }), (Get-Date -Format yyyyMMdd)
$out = Join-Path $desktop "$base.html"
$n = 2
while (Test-Path $out) { $out = Join-Path $desktop ("{0}-{1}.html" -f $base, $n); $n++ }   # never overwrite an existing file

$mime = @{ '.svg' = 'image/svg+xml'; '.png' = 'image/png'; '.jpg' = 'image/jpeg'; '.jpeg' = 'image/jpeg'; '.gif' = 'image/gif'; '.webp' = 'image/webp'; '.woff2' = 'font/woff2'; '.woff' = 'font/woff'; '.ttf' = 'font/ttf' }
$extPat = 'svg|png|jpe?g|gif|webp|woff2?|ttf'
$script:embedded = @()
$script:warn = @()
$script:dyn = @{}   # path (relative to the prototype folder, with / separators) -> data URI, for dynamic JS paths

function Get-DataUri([string]$full) {
  $ext = [IO.Path]::GetExtension($full).ToLower()
  $b64 = [Convert]::ToBase64String([IO.File]::ReadAllBytes($full))
  return "data:$($mime[$ext]);base64,$b64"
}
function Test-Local([string]$ref) { return ($ref -notmatch '^(https?:|data:|//|#|mailto:)') }

# Embed a local file referenced from $fromDir. Returns the data URI, or $null when it cannot be resolved.
function Embed([string]$ref, [string]$fromDir, [string]$where) {
  if (-not (Test-Local $ref)) { return $null }
  $clean = ($ref -split '[?#]')[0]
  $full = [IO.Path]::GetFullPath((Join-Path $fromDir $clean))
  if (-not (Test-Path -LiteralPath $full -PathType Leaf)) { $script:warn += "$where : $ref (not found)"; return $null }
  $script:embedded += $full.Substring($RepoRoot.Length).TrimStart('\')
  return (Get-DataUri $full)
}

# url(...) in CSS -> data URI
function Convert-CssUrls([string]$css, [string]$fromDir, [string]$where) {
  return [regex]::Replace($css, "url\(\s*([""']?)([^""')]+)\1\s*\)", {
      param($m)
      $uri = Embed $m.Groups[2].Value.Trim() $fromDir $where
      if ($uri) { return "url(""$uri"")" } else { return $m.Value }
    })
}

# JS: quoted / template strings that point to local images -> data URIs; dynamic ones (with ${...}) -> lookup table
function Convert-Js([string]$js, [string]$protoDir) {
  # dynamic: path containing ${...} inside a template literal -> ${__ASSETS[`path`]}
  $js = [regex]::Replace($js, '(?<![\w/.\-])((?:[\w.\-]+/)*[\w.\-]*\$\{[^}]*\}[\w.\-/]*\.(?:' + $extPat + '))(?![\w])', {
      param($m)
      $p = $m.Groups[1].Value
      $glob = [regex]::Replace($p, '\$\{[^}]*\}', '*')
      $dirPart = Split-Path $glob
      $dirFull = Join-Path $protoDir $dirPart
      if (-not (Test-Path $dirFull)) { return $m.Value }
      $found = Get-ChildItem $dirFull -File | Where-Object { $_.Name -like (Split-Path $glob -Leaf) }
      foreach ($f in $found) {
        $key = ($f.FullName.Substring($protoDir.Length).TrimStart('\')).Replace('\', '/')
        if (-not $script:dyn.ContainsKey($key)) { $script:dyn[$key] = Get-DataUri $f.FullName; $script:embedded += $f.FullName.Substring($RepoRoot.Length).TrimStart('\') }
      }
      return ('${__ASSETS[`' + $p + '`]}')
    })
  # static: 'path' "path" `path` with no ${
  $js = [regex]::Replace($js, '(?<=["''`])((?:\.\./)*(?:[\w.\-]+/)+[\w.\-]+\.(?:' + $extPat + '))(?=["''`])', {
      param($m)
      $uri = Embed $m.Groups[1].Value $protoDir 'prototype js'
      if ($uri) { return $uri } else { return $m.Value }
    })
  return $js
}

$html = [IO.File]::ReadAllText($indexPath, $utf8)

# 1. <link rel="stylesheet" href="local.css"> -> <style>
$html = [regex]::Replace($html, '<link\s[^>]*rel="stylesheet"[^>]*>', {
    param($m)
    if ($m.Value -notmatch 'href="([^"]+)"') { return $m.Value }
    $ref = $Matches[1]
    if (-not (Test-Local $ref)) { return $m.Value }
    $full = [IO.Path]::GetFullPath((Join-Path $src $ref))
    if (-not (Test-Path $full)) { $script:warn += "index.html : $ref (not found)"; return $m.Value }
    $css = [IO.File]::ReadAllText($full, $utf8)
    $css = Convert-CssUrls $css (Split-Path $full) $ref
    $css = $css -replace '(?i)</style', '<\/style'
    $script:embedded += $full.Substring($RepoRoot.Length).TrimStart('\')
    return "<style>`n/* $ref */`n$css`n</style>"
  })

# 2. <script src="local.js"></script> -> inline <script>
$jsBlocks = @()
$html = [regex]::Replace($html, '<script\s+src="([^"]+)"\s*>\s*</script>', {
    param($m)
    $ref = $m.Groups[1].Value
    if (-not (Test-Local $ref)) { return $m.Value }
    $full = [IO.Path]::GetFullPath((Join-Path $src $ref))
    if (-not (Test-Path $full)) { $script:warn += "index.html : $ref (not found)"; return $m.Value }
    $js = Convert-Js ([IO.File]::ReadAllText($full, $utf8)) $src
    $js = $js -replace '(?i)</script', '<\/script'
    $script:embedded += $full.Substring($RepoRoot.Length).TrimStart('\')
    return "<script>`n$js`n</script>"
  })

# 3. src= / href= pointing to local images in the HTML, and url() in inline <style>
$html = [regex]::Replace($html, '(?<=\s(?:src|href)=")([^"]+\.(?:' + $extPat + ')(?:[?#][^"]*)?)(?=")', {
    param($m)
    $uri = Embed $m.Groups[1].Value $src 'index.html'
    if ($uri) { return $uri } else { return $m.Value }
  })

# 4. lookup table for dynamic JS paths (must run before the inlined scripts)
if ($script:dyn.Count -gt 0) {
  $entries = ($script:dyn.GetEnumerator() | Sort-Object Key | ForEach-Object { '"' + $_.Key + '":"' + $_.Value + '"' }) -join ",`n"
  $table = "<script>`nwindow.__ASSETS = {`n$entries`n};`n</script>`n"
  $idx = $html.IndexOf('<script>')
  if ($idx -ge 0) { $html = $html.Insert($idx, $table) } else { $html = $html.Replace('</body>', $table + '</body>') }
}

# 5. leftover relative references (warn only)
$markup = [regex]::Replace($html, '(?s)<(style|script)\b.*?</\1>', '')   # ignore CSS / JS text (comments may mention file names)
foreach ($m in [regex]::Matches($markup, '(?:src|href)="((?:\.\./|\./)?[\w][^":]*?\.(?:css|js))"')) { $script:warn += "index.html : $($m.Groups[1].Value) still referenced" }

[IO.File]::WriteAllText($out, $html, $utf8)

Write-Output "HTML: $out"
Write-Output ("Size: {0:N0} KB" -f ((Get-Item $out).Length / 1KB))
Write-Output ("Embedded files: " + $(if ($script:embedded) { ($script:embedded | Sort-Object -Unique).Count } else { 0 }))
if ($script:warn) { Write-Output "WARNINGS:"; $script:warn | Sort-Object -Unique | ForEach-Object { Write-Output "  $_" } }
