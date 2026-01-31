@echo off
echo === File Comparison ===
echo Original file: ORIGINAL-NameRankTitles.rbxm
echo Generated file: tools/LuauExporter/test-output.rbxm
echo.

echo Checking file sizes:
for %%A in (ORIGINAL-NameRankTitles.rbxm) do set "originalSize=%%~zA bytes"
for %%B in (tools/LuauExporter/test-output.rbxm) do set "generatedSize=%%~zB bytes"
echo Original: %originalSize%
echo Generated: %generatedSize%
echo.

echo First 20 bytes:
echo Original:
powershell -Command "$bytes = [System.IO.File]::ReadAllBytes('ORIGINAL-NameRankTitles.rbxm'); $bytes[0..19] | ForEach-Object { $_.ToString('X2') }"
echo Generated:
powershell -Command "$bytes = [System.IO.File]::ReadAllBytes('tools/LuauExporter/test-output.rbxm'); $bytes[0..19] | ForEach-Object { $_.ToString('X2') }"
