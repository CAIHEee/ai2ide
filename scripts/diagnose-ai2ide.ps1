param(
    [switch]$Json
)

$ErrorActionPreference = "SilentlyContinue"

function New-Check {
    param(
        [string]$Name,
        [string]$Status,
        [string]$Detail,
        [string]$Suggestion = ""
    )

    [pscustomobject]@{
        Name       = $Name
        Status     = $Status
        Detail     = $Detail
        Suggestion = $Suggestion
    }
}

function Test-AnyPath {
    param([string[]]$Paths)

    $found = @()
    foreach ($path in $Paths) {
        if ($path -and (Test-Path -LiteralPath $path)) {
            $found += (Resolve-Path -LiteralPath $path).Path
        }
    }
    return $found
}

function Get-JetBrainsVersionStatus {
    param([string]$Path)

    $leaf = Split-Path -Leaf $Path
    $match = [regex]::Match($leaf, "(20\d{2})\.(\d+)")
    if (-not $match.Success) {
        return [pscustomobject]@{
            Path    = $Path
            Version = "unknown"
            Ready   = $false
        }
    }

    $year = [int]$match.Groups[1].Value
    $minor = [int]$match.Groups[2].Value
    $ready = ($year -gt 2025) -or (($year -eq 2025) -and ($minor -ge 2))

    return [pscustomobject]@{
        Path    = $Path
        Version = "$year.$minor"
        Ready   = $ready
    }
}

function Find-JetBrainsIde {
    $productPattern = "^(IntelliJIdea|IdeaIC|PyCharm|WebStorm|PhpStorm|GoLand|Rider|CLion|RubyMine|DataGrip|AndroidStudio|IDEA)[\w .-]*(20\d{2}\.\d+)?$"
    $roots = @()

    if ($env:LOCALAPPDATA) {
        $roots += Join-Path $env:LOCALAPPDATA "Programs"
        $roots += Join-Path $env:LOCALAPPDATA "JetBrains"
    }

    if ($env:ProgramFiles) {
        $roots += Join-Path $env:ProgramFiles "JetBrains"
    }

    if (${env:ProgramFiles(x86)}) {
        $roots += Join-Path ${env:ProgramFiles(x86)} "JetBrains"
    }

    if ($env:APPDATA) {
        $roots += Join-Path $env:APPDATA "JetBrains\Toolbox\apps"
    }

    $idePaths = @()
    foreach ($root in ($roots | Where-Object { $_ } | Select-Object -Unique)) {
        if (Test-Path -LiteralPath $root) {
            $idePaths += Get-ChildItem -LiteralPath $root -Directory |
                Where-Object { $_.Name -match $productPattern } |
                Select-Object -ExpandProperty FullName

            $idePaths += Get-ChildItem -LiteralPath $root -Directory -Recurse -Depth 3 |
                Where-Object {
                    $_.Name -match $productPattern -and
                    $_.FullName -notmatch "\\index(\\|$)|\\system(\\|$)|\\log(\\|$)|\\plugins(\\|$)|\\projects(\\|$)"
                } |
                Select-Object -ExpandProperty FullName
        }
    }

    foreach ($entry in ($env:Path -split ";" | Where-Object { $_ })) {
        if ($entry -match "JetBrains|IntelliJ|PyCharm|WebStorm|PhpStorm|GoLand|Rider|CLion|RubyMine|DataGrip|AndroidStudio") {
            $path = $entry
            if ((Split-Path -Leaf $path) -eq "bin") {
                $path = Split-Path -Parent $path
            }
            $idePaths += $path
        }
    }

    return $idePaths |
        Where-Object { $_ -and (Test-Path -LiteralPath $_) } |
        Select-Object -Unique |
        ForEach-Object { Get-JetBrainsVersionStatus -Path $_ }
}

function Find-McpConfig {
    $candidates = @()

    if ($env:USERPROFILE) {
        $candidates += Join-Path $env:USERPROFILE ".codex\config.toml"
        $candidates += Join-Path $env:USERPROFILE ".codex\mcp.json"
        $candidates += Join-Path $env:USERPROFILE ".config\codex\config.toml"
        $candidates += Join-Path $env:USERPROFILE ".cursor\mcp.json"
        $candidates += Join-Path $env:USERPROFILE "AppData\Roaming\Cursor\User\mcp.json"
        $candidates += Join-Path $env:USERPROFILE "AppData\Roaming\Cursor\User\globalStorage\mcp.json"
        $candidates += Join-Path $env:USERPROFILE ".trae\mcp.json"
        $candidates += Join-Path $env:USERPROFILE "AppData\Roaming\Trae\User\mcp.json"
        $candidates += Join-Path $env:USERPROFILE ".config\claude\mcp.json"
        $candidates += Join-Path $env:USERPROFILE ".claude.json"
        $candidates += Join-Path $env:USERPROFILE "AppData\Roaming\Claude\claude_desktop_config.json"
    }

    $existing = Test-AnyPath -Paths $candidates
    $hits = @()
    foreach ($path in $existing) {
        $content = Get-Content -LiteralPath $path -Raw
        $hasJetBrains = $content -match "jetbrains|JetBrains|mcp-jetbrains|IDEA|PyCharm|WebStorm|IJ_MCP_SERVER_PORT|McpStdioRunnerKt|/sse"
        $usesStdioRunner = $content -match "McpStdioRunnerKt|IJ_MCP_SERVER_PORT"
        $usesLegacyProxy = $content -match "@jetbrains/mcp-proxy"
        $usesSse = $content -match '/sse'
        $hits += [pscustomobject]@{
            Path             = $path
            HasJetBrains     = [bool]$hasJetBrains
            UsesStdioRunner  = [bool]$usesStdioRunner
            UsesLegacyProxy  = [bool]$usesLegacyProxy
            UsesSse          = [bool]$usesSse
        }
    }

    return $hits
}

function Find-CodexPluginHints {
    $paths = @()
    $paths += Join-Path $PSScriptRoot "..\.codex-plugin\plugin.json"

    if ($env:USERPROFILE) {
        $paths += Join-Path $env:USERPROFILE "plugins\ai2ide\.codex-plugin\plugin.json"
        $paths += Join-Path $env:USERPROFILE ".agents\plugins\marketplace.json"
    }

    return Test-AnyPath -Paths $paths
}

$checks = @()

$checks += New-Check `
    -Name "Operating system" `
    -Status "INFO" `
    -Detail "$([System.Runtime.InteropServices.RuntimeInformation]::OSDescription) / PowerShell $($PSVersionTable.PSVersion)"

$pluginHints = Find-CodexPluginHints
if ($pluginHints.Count -gt 0) {
    $checks += New-Check `
        -Name "ai2ide plugin files" `
        -Status "OK" `
        -Detail ($pluginHints -join "; ")
} else {
    $checks += New-Check `
        -Name "ai2ide plugin files" `
        -Status "MISSING" `
        -Detail "No ai2ide plugin manifest or personal marketplace hint found." `
        -Suggestion "Run this script from the ai2ide plugin root or install the plugin into the Codex personal plugin directory."
}

$mcpConfigs = Find-McpConfig
if ($mcpConfigs.Count -eq 0) {
    $checks += New-Check `
        -Name "MCP configuration files" `
        -Status "MISSING" `
        -Detail "No common Codex/agent MCP config files were found." `
        -Suggestion "Open a JetBrains 2025.2+ IDE with MCP Server enabled and configure Codex from the IDE MCP Server settings."
} else {
    $withJetBrains = @($mcpConfigs | Where-Object { $_.HasJetBrains })
    if ($withJetBrains.Count -gt 0) {
        $details = ($withJetBrains | ForEach-Object {
            $modes = @()
            if ($_.UsesStdioRunner) { $modes += "JetBrains Stdio runner" }
            if ($_.UsesSse) { $modes += "SSE" }
            if ($_.UsesLegacyProxy) { $modes += "legacy proxy" }
            if ($modes.Count -eq 0) { $modes += "JetBrains trace" }
            "$($_.Path) [$($modes -join ', ')]"
        }) -join "; "
        $checks += New-Check `
            -Name "JetBrains MCP config trace" `
            -Status "OK" `
            -Detail $details
    } else {
        $checks += New-Check `
            -Name "JetBrains MCP config trace" `
            -Status "WARN" `
            -Detail (($mcpConfigs | ForEach-Object { $_.Path }) -join "; ") `
            -Suggestion "MCP config files exist, but no JetBrains-related entry was detected by text scan."
    }
}

$ides = @(Find-JetBrainsIde)
if ($ides.Count -gt 0) {
    $readyIdes = @($ides | Where-Object { $_.Ready })
    $unknownIdes = @($ides | Where-Object { $_.Version -eq "unknown" })
    $detail = ($ides | ForEach-Object {
        if ($_.Version -eq "unknown") {
            "$($_.Path) (version unknown)"
        } elseif ($_.Ready) {
            "$($_.Path) ($($_.Version), MCP-ready by version)"
        } else {
            "$($_.Path) ($($_.Version), below 2025.2)"
        }
    }) -join "; "

    $status = "WARN"
    $suggestion = "Open a JetBrains 2025.2+ IDE and enable MCP Server."
    if ($readyIdes.Count -gt 0) {
        $status = "OK"
        $suggestion = "Confirm MCP Server is enabled in the JetBrains IDE settings."
    } elseif ($unknownIdes.Count -gt 0) {
        $suggestion = "At least one JetBrains path was found, but the version could not be inferred from its folder name. Confirm manually that it is 2025.2 or newer."
    }

    $checks += New-Check `
        -Name "JetBrains IDE installs" `
        -Status $status `
        -Detail $detail `
        -Suggestion $suggestion
} else {
    $checks += New-Check `
        -Name "JetBrains IDE installs" `
        -Status "MISSING" `
        -Detail "No JetBrains IDE directories were found in common install locations." `
        -Suggestion "Install or open IntelliJ IDEA, PyCharm, WebStorm, or another JetBrains 2025.2+ IDE."
}

$checks += New-Check `
    -Name "Write safety" `
    -Status "INFO" `
    -Detail "This diagnostic is read-only. ai2ide itself is designed for a high-trust MCP mode where connected IDE tools may write or run project actions."

if ($Json) {
    $checks | ConvertTo-Json -Depth 4
    exit 0
}

Write-Host "ai2ide diagnostic report"
Write-Host "========================"
foreach ($check in $checks) {
    Write-Host ""
    Write-Host "[$($check.Status)] $($check.Name)"
    Write-Host "  $($check.Detail)"
    if ($check.Suggestion) {
        Write-Host "  Suggestion: $($check.Suggestion)"
    }
}

$bad = @($checks | Where-Object { $_.Status -in @("MISSING", "WARN") })
Write-Host ""
if ($bad.Count -eq 0) {
    Write-Host "Result: ai2ide prerequisites look ready from this read-only scan."
} else {
    Write-Host "Result: Review the warnings above before relying on JetBrains MCP from Codex."
}
