# PowerShell script to compare VS Code settings files and extract distinct properties from Cursor
# Author: AI Assistant
# Date: $(Get-Date -Format "yyyy-MM-dd")

Write-Host "Comparing VS Code settings files..." -ForegroundColor Blue
Write-Host ""

# Function to get distinct properties from Cursor file
function Get-DistinctProperties {
    param(
        [string]$CursorFile,
        [string]$VSCodeFile
    )
    
    try {
        # Read both JSON files
        Write-Host "Reading Cursor settings file..." -ForegroundColor Gray
        $cursorSettings = Get-Content $CursorFile -Raw | ConvertFrom-Json
        
        Write-Host "Reading VS Code settings file..." -ForegroundColor Gray
        $vscodeSettings = Get-Content $VSCodeFile -Raw | ConvertFrom-Json
        
        # Create a new object to store distinct properties
        $distinctSettings = @{}
        
        # Get all properties from Cursor file
        $cursorProps = $cursorSettings | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name
        Write-Host "Found $($cursorProps.Count) properties in Cursor file" -ForegroundColor Gray
        
        # Check each property in Cursor file
        $distinctCount = 0
        foreach ($prop in $cursorProps) {
            $cursorValue = $cursorSettings.$prop
            $vscodeValue = $vscodeSettings.$prop
            
            # Check if property doesn't exist in VSCode or has different value
            if (-not $vscodeSettings.PSObject.Properties.Match($prop).Count -or 
                ($cursorValue -ne $vscodeValue)) {
                $distinctSettings[$prop] = $cursorValue
                $distinctCount++
                Write-Host "Found distinct property: $prop" -ForegroundColor Green
            }
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
        
    } catch {
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
    $resultFile = "result-output.json"
    $result | ConvertTo-Json -Depth 10 | Out-File -FilePath $resultFile -Encoding UTF8
    Write-Host "Result variable saved to: $resultFile" -ForegroundColor Yellow
    
    Write-Host ""
    Write-Host "Script completed successfully!" -ForegroundColor Green
    
} catch {
    Write-Host "Script failed with error: $_" -ForegroundColor Red
    exit 1
}
