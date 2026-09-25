<#
.SYNOPSIS
  protect-paths.ps1 - PreToolUse hook (matcher "Edit|Write|MultiEdit|NotebookEdit") for Windows.

.DESCRIPTION
  PowerShell equivalent of protect-paths.sh. Blocks edits to any path matching a
  glob listed in .claude/protected-paths.txt (one per line, '#' comments).

  Pattern rules (paths relative to the project root, '/' separators):
    api/v1/**            everything under api/v1/  ('*' and '**' both cross '/')
    *.lock               any file ending .lock at any depth (no '/' => basename match)
    .github/workflows/   trailing slash => directory prefix
    CODEOWNERS           exact file

  Wiring:
    "command": "pwsh -NoProfile -File \"${CLAUDE_PROJECT_DIR}/.claude/hooks/protect-paths.ps1\""

  exit 0 = allow, exit 2 = block (stderr is the reason shown to Claude).

.EXAMPLE
  '{"tool_input":{"file_path":"api/v1/Foo.java"}}' | pwsh -NoProfile -File .\protect-paths.ps1; $LASTEXITCODE
#>

$ErrorActionPreference = 'Stop'

$projectDir = if ($env:CLAUDE_PROJECT_DIR) { $env:CLAUDE_PROJECT_DIR } else { (Get-Location).Path }
$listFile   = if ($env:PROTECTED_PATHS_FILE) { $env:PROTECTED_PATHS_FILE } else { Join-Path $projectDir '.claude/protected-paths.txt' }

# No list file -> nothing protected.
if (-not (Test-Path -LiteralPath $listFile)) { exit 0 }

# --- Parse stdin; fail closed on malformed input.
try {
    $hookInput = [Console]::In.ReadToEnd() | ConvertFrom-Json
} catch {
    [Console]::Error.WriteLine('protect-paths: cannot parse hook input. Blocking to be safe.')
    exit 2
}

$target = $null
if ($hookInput.tool_input) {
    $target = $hookInput.tool_input.file_path
    if (-not $target) { $target = $hookInput.tool_input.notebook_path }
}
if ([string]::IsNullOrWhiteSpace($target)) { exit 0 }

# --- Normalize to project-relative, forward slashes, case-insensitive (Windows FS).
function Normalize([string]$p) { return ($p -replace '\\', '/').TrimEnd('/') }
$t = Normalize $target
$p = Normalize $projectDir
$rel = if ($t.StartsWith("$p/", [StringComparison]::OrdinalIgnoreCase)) { $t.Substring($p.Length + 1) } else { $t -replace '^\./', '' }
$base = ($rel -split '/')[-1]

# Convert a glob to an anchored regex: '**' and '*' => '.*', '?' => '.'
function GlobToRegex([string]$g) {
    $escaped = [Regex]::Escape($g) -replace '\\\*\\\*', '.*' -replace '\\\*', '.*' -replace '\\\?', '.'
    return "^$escaped$"
}

foreach ($line in Get-Content -LiteralPath $listFile) {
    $pat = ($line -replace '#.*$', '').Trim()
    if (-not $pat) { continue }

    $hit = $false
    if ($pat.EndsWith('/')) {
        $hit = $rel.StartsWith($pat, [StringComparison]::OrdinalIgnoreCase)
    } else {
        $rx  = GlobToRegex $pat
        $hit = $rel -imatch $rx
        if (-not $hit -and -not $pat.Contains('/')) { $hit = $base -imatch $rx }
    }

    if ($hit) {
        [Console]::Error.WriteLine(@"
BLOCKED by protect-paths: '$rel' matches protected pattern '$pat' in .claude/protected-paths.txt.
This path is protected (frozen API, generated code, or controlled config).
If the change is genuinely required, stop and ask the code owner; changes here go through a
human-authored PR with code-owner approval. Do not try to work around this block.
"@)
        exit 2
    }
}

exit 0
