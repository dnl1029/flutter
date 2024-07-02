Write-Output "Moving assets..."
$sourceDir = "build\web\assets\assets"
$targetDir = "build\web\assets"

if (Test-Path $sourceDir) {
    if (-Not (Test-Path $targetDir)) {
        New-Item -ItemType Directory -Path $targetDir
    }
    Get-ChildItem -Path $sourceDir -Recurse | Move-Item -Destination $targetDir
    Remove-Item -Recurse -Force $sourceDir
    Write-Output "Assets moved."
} else {
    Write-Output "No assets to move."
}
