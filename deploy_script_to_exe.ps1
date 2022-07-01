# Copy config.ini from source to dist folder
Copy-Item .\Source\config.ini -Destination .\Dist\ -Recurse -force

# call ps2exe and give it the correct locations and arguments
Invoke-ps2exe .\Source\OCR-snip.ps1 .\Dist\OCR-snip.exe -noConsole -iconFile .\Source\icon.ico -title "OCR snip tool" -noOutput -noError