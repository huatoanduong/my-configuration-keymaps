# PowerShell script to compare VS Code settings files and extract distinct properties from Cursor
# Author: AI Assistant
# Date: $(Get-Date -Format "yyyy-MM-dd")

Write-Host "Comparing VS Code settings files..." -ForegroundColor Blue
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

# Function to get distinct properties from Cursor file
function Get-DistinctProperties {
  param(
    [string]$CursorFile,
    [string]$VSCodeFile
  )
    
  try {
    # Read both JSON files and clean them
    Write-Host "Reading Cursor settings file..." -ForegroundColor Gray
    $cursorRaw = Get-Content $CursorFile -Raw
    $cursorClean = Remove-JsonComments -Content $cursorRaw
    $cursorSettings = $cursorClean | ConvertFrom-Json
        
    Write-Host "Reading VS Code settings file..." -ForegroundColor Gray
    $vscodeRaw = Get-Content $VSCodeFile -Raw
    $vscodeClean = Remove-JsonComments -Content $vscodeRaw
    $vscodeSettings = $vscodeClean | ConvertFrom-Json
        
    # Create a new object to store distinct properties
    $distinctSettings = @{}
        
    # Get all properties from Cursor file
    $cursorProps = $cursorSettings | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name
    Write-Host "Found $($cursorProps.Count) properties in Cursor file" -ForegroundColor Gray
        
    # Get all properties from VSCode file
    $vscodeProps = $vscodeSettings | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name
    Write-Host "Found $($vscodeProps.Count) properties in VS Code file" -ForegroundColor Gray
        
    # Check each property in Cursor file
    $distinctCount = 0
    foreach ($prop in $cursorProps) {
      # Check if property name exists in VSCode file (regardless of value)
      # if (-not $vscodeSettings.PSObject.Properties.Match($prop).Count) {
      if (-1 -eq $vscodeProps.indexOf($prop)) {
        # Property name only exists in Cursor file - keep it
        $distinctSettings[$prop] = $cursorSettings.$prop
        $distinctCount++
        Write-Host "Found distinct property: $prop" -ForegroundColor Green
      }
      # If property name exists in both files, skip it (it's a duplicate)
    }
        
    # Convert back to JSON and save
    $outputFile = "distinct-cursor-settings.json"
    $distinctSettings | ConvertTo-Json -Depth 10 | Out-File -FilePath $outputFile -Encoding UTF8
        
    Write-Host ""
    Write-Host "Distinct properties saved to: $outputFile" -ForegroundColor Yellow
    Write-Host "Total distinct properties found: $distinctCount" -ForegroundColor Cyan
        
    # Display summary of distinct properties
    Write-Host ""
    Write-Host "Distinct properties:" -ForegroundColor White
    $distinctSettings.Keys | Sort-Object | ForEach-Object { 
      Write-Host "  - $_" -ForegroundColor Gray 
    }
        
    return $distinctSettings
        
  }
  catch {
    Write-Host "Error: $_" -ForegroundColor Red
    throw
  }
}

# Main execution
try {
  # File paths
  $cursorFile = "cursor/setting-windows-vscode.json"
  $vscodeFile = "visual-studio-code/settings-windows.json"
    
  # Check if files exist
  if (-not (Test-Path $cursorFile)) {
    Write-Host "Error: Cursor file not found: $cursorFile" -ForegroundColor Red
    exit 1
  }
    
  if (-not (Test-Path $vscodeFile)) {
    Write-Host "Error: VS Code file not found: $vscodeFile" -ForegroundColor Red
    exit 1
  }
    
  Write-Host "Starting comparison..." -ForegroundColor Blue
  Write-Host "Cursor file: $cursorFile" -ForegroundColor Gray
  Write-Host "VS Code file: $vscodeFile" -ForegroundColor Gray
  Write-Host ""
    
  # Get distinct properties
  $result = Get-DistinctProperties -CursorFile $cursorFile -VSCodeFile $vscodeFile
    
  # Write the $result variable to a separate JSON file
  $resultFile = "./localignore/result-output.json"
  $result | ConvertTo-Json -Depth 10 | Out-File -FilePath $resultFile -Encoding UTF8
  Write-Host "Result variable saved to: $resultFile" -ForegroundColor Yellow
    
  Write-Host ""
  Write-Host "Script completed successfully!" -ForegroundColor Green
    
}
catch {
  Write-Host "Script failed with error: $_" -ForegroundColor Red
  exit 1
}
