# PowerShell script to compare VS Code keybindings files
# Author: AI Assistant
# Date: $(Get-Date -Format "yyyy-MM-dd")

Write-Host "Comparing VS Code keybindings files..." -ForegroundColor Blue
Write-Host ""

# Function to clean JSON content by removing comments
function Remove-JsonComments {
  param([string]$Content)
    
  # Split content into lines for safer processing
  $lines = $Content -split "`n"
  $cleanLines = @()
    
  foreach ($line in $lines) {
    # Check if line contains only comments or is empty
    $trimmedLine = $line.Trim()
        
    # Skip empty lines and lines that are only comments
    if ($trimmedLine -eq '' -or $trimmedLine.StartsWith('//')) {
      continue
    }
        
    # Remove inline comments (// ...) but preserve the content before the comment
    if ($line.Contains('//')) {
      $commentIndex = $line.IndexOf('//')
      $cleanLine = $line.Substring(0, $commentIndex).TrimEnd()
            
      # Only add the line if it still has content after removing the comment
      if ($cleanLine -ne '') {
        $cleanLines += $cleanLine
      }
    }
    else {
      # Line has no comments, keep it as is
      $cleanLines += $line
    }
  }
    
  # Join lines back together
  $cleanContent = $cleanLines -join "`n"
    
  # Remove any trailing commas that might cause JSON parsing issues
  $cleanContent = $cleanContent -replace ',\s*}', '}'
  $cleanContent = $cleanContent -replace ',\s*]', ']'
    
  return $cleanContent
}

# Function to compare keybindings
function Compare-Keybindings {
  param(
    [string]$CursorFile,
    [string]$VSCodeFile
  )
    
  try {
    # Read both JSON files and clean them
    Write-Host "Reading Cursor keybindings file..." -ForegroundColor Gray
    $cursorRaw = Get-Content $CursorFile -Raw
    $cursorClean = Remove-JsonComments -Content $cursorRaw
    $cursorKeybindings = $cursorClean | ConvertFrom-Json
        
    Write-Host "Reading VS Code keybindings file..." -ForegroundColor Gray
    $vscodeRaw = Get-Content $VSCodeFile -Raw
    $vscodeClean = Remove-JsonComments -Content $vscodeRaw
    $vscodeKeybindings = $vscodeClean | ConvertFrom-Json
        
    Write-Host "Found $($cursorKeybindings.Count) keybindings in Cursor file" -ForegroundColor Gray
    Write-Host "Found $($vscodeKeybindings.Count) keybindings in VS Code file" -ForegroundColor Gray
    Write-Host ""
        
    # Create collections to store results
    $cursorOnly = @()
    $vscodeOnly = @()
    $matchingKeys = @()
    $conflicts = @()
        
    # Get all unique keys from both files
    $cursorKeys = $cursorKeybindings | Select-Object -ExpandProperty key | Sort-Object -Unique
    $vscodeKeys = $vscodeKeybindings | Select-Object -ExpandProperty key | Sort-Object -Unique
        
    Write-Host "Found $($cursorKeys.Count) unique keys in Cursor file" -ForegroundColor Gray
    Write-Host "Found $($vscodeKeys.Count) unique keys in VS Code file" -ForegroundColor Gray
    Write-Host ""
        
    # Find keys that exist only in Cursor
    foreach ($key in $cursorKeys) {
      if ($key -notin $vscodeKeys) {
        $keybinding = $cursorKeybindings | Where-Object { $_.key -eq $key } | Select-Object -First 1
        $cursorOnly += $keybinding
        Write-Host "Cursor only: $key -> $($keybinding.command)" -ForegroundColor Green
      }
    }
        
    # Find keys that exist only in VS Code
    foreach ($key in $vscodeKeys) {
      if ($key -notin $cursorKeys) {
        $keybinding = $vscodeKeybindings | Where-Object { $_.key -eq $key } | Select-Object -First 1
        $vscodeOnly += $keybinding
        Write-Host "VS Code only: $key -> $($keybinding.command)" -ForegroundColor Yellow
      }
    }
        
    # Find matching keys and analyze conflicts
    foreach ($key in $cursorKeys) {
      if ($key -in $vscodeKeys) {
        $cursorBinding = $cursorKeybindings | Where-Object { $_.key -eq $key }
        $vscodeBinding = $vscodeKeybindings | Where-Object { $_.key -eq $key }
                
        # Check for conflicts (same key, different commands)
        $cursorCommands = $cursorBinding | Select-Object -ExpandProperty command
        $vscodeCommands = $vscodeBinding | Select-Object -ExpandProperty command
                
        # Check if any commands start with "-" (disabled)
        $cursorDisabled = $cursorCommands | Where-Object { $_ -like "-*" }
        $vscodeDisabled = $vscodeCommands | Where-Object { $_ -like "-*" }
                
        $matchingKeys += @{
          key            = $key
          cursorBindings = $cursorBinding
          vscodeBindings = $vscodeBinding
          cursorDisabled = $cursorDisabled
          vscodeDisabled = $vscodeDisabled
        }
                
        Write-Host "Matching key: $key" -ForegroundColor Cyan
        Write-Host "  Cursor: $($cursorCommands -join ', ')" -ForegroundColor Gray
        Write-Host "  VS Code: $($vscodeCommands -join ', ')" -ForegroundColor Gray
                
        # Check for conflicts
        if ($cursorCommands -ne $vscodeCommands) {
          $conflicts += @{
            key            = $key
            cursorCommands = $cursorCommands
            vscodeCommands = $vscodeCommands
          }
          Write-Host "  ⚠️  CONFLICT: Different commands for same key!" -ForegroundColor Red
        }
                
        # Check for disabled commands
        if ($cursorDisabled) {
          Write-Host "  🚫 Cursor has disabled commands: $($cursorDisabled -join ', ')" -ForegroundColor Magenta
        }
        if ($vscodeDisabled) {
          Write-Host "  🚫 VS Code has disabled commands: $($vscodeDisabled -join ', ')" -ForegroundColor Magenta
        }
        Write-Host ""
      }
    }
        
    # Create results object
    $results = @{
      cursorOnly   = $cursorOnly
      vscodeOnly   = $vscodeOnly
      matchingKeys = $matchingKeys
      conflicts    = $conflicts
      summary      = @{
        totalCursorKeys   = $cursorKeys.Count
        totalVSCodeKeys   = $vscodeKeys.Count
        cursorOnlyCount   = $cursorOnly.Count
        vscodeOnlyCount   = $vscodeOnly.Count
        matchingKeysCount = $matchingKeys.Count
        conflictsCount    = $conflicts.Count
      }
    }
        
    # Display summary
    Write-Host ""
    Write-Host "=== COMPARISON SUMMARY ===" -ForegroundColor White
    Write-Host "Total unique keys in Cursor: $($cursorKeys.Count)" -ForegroundColor Cyan
    Write-Host "Total unique keys in VS Code: $($vscodeKeys.Count)" -ForegroundColor Cyan
    Write-Host "Keys only in Cursor: $($cursorOnly.Count)" -ForegroundColor Green
    Write-Host "Keys only in VS Code: $($vscodeOnly.Count)" -ForegroundColor Yellow
    Write-Host "Matching keys: $($matchingKeys.Count)" -ForegroundColor Blue
    Write-Host "Conflicts found: $($conflicts.Count)" -ForegroundColor Red
        
    return $results
        
  }
  catch {
    Write-Host "Error: $_" -ForegroundColor Red
    throw
  }
}

# Main execution
try {
  # File paths
  $cursorFile = "cursor/keybindings_windows.json"
  $vscodeFile = "visual-studio-code/keybindings-windows.json"
    
  # Check if files exist
  if (-not (Test-Path $cursorFile)) {
    Write-Host "Error: Cursor keybindings file not found: $cursorFile" -ForegroundColor Red
    exit 1
  }
    
  if (-not (Test-Path $vscodeFile)) {
    Write-Host "Error: VS Code keybindings file not found: $vscodeFile" -ForegroundColor Red
    exit 1
  }
    
  Write-Host "Starting keybindings comparison..." -ForegroundColor Blue
  Write-Host "Cursor file: $cursorFile" -ForegroundColor Gray
  Write-Host "VS Code file: $vscodeFile" -ForegroundColor Gray
  Write-Host ""
    
  # Compare keybindings
  $result = Compare-Keybindings -CursorFile $cursorFile -VSCodeFile $vscodeFile
    
  # Save detailed results
  $result | ConvertTo-Json -Depth 10 | Out-File -FilePath "./localignore/keybindings-comparison.json" -Encoding UTF8
  Write-Host "Detailed comparison saved to: keybindings-comparison.json" -ForegroundColor Yellow
    
  # Save summary
  $result.summary | ConvertTo-Json | Out-File -FilePath "./localignore/keybindings-summary.json" -Encoding UTF8
  Write-Host "Summary saved to: keybindings-summary.json" -ForegroundColor Yellow
    
  Write-Host ""
  Write-Host "Script completed successfully!" -ForegroundColor Green
    
}
catch {
  Write-Host "Script failed with error: $_" -ForegroundColor Red
  exit 1
}
