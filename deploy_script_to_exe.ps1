Function Create-Path-If-Not-Exists ($path)
{ 
        If(!(test-path -PathType container $path))
        {
        New-Item -Path "$path" -ItemType Directory
        }
}

$folderName = "OCR-snipping-tool"

# Create folder if it doesn't exist
Create-Path-If-Not-Exists("$folderName")

# Copy config.ini from source to dist folder
Copy-Item .\Source\config.ini -Destination .\$folderName\ -Recurse -force
Copy-Item .\README.md -Destination .\$folderName\ -Recurse -force

# call ps2exe and give it the correct locations and arguments
Invoke-ps2exe .\Source\OCR-snip.ps1 .\$folderName\OCR-snip.exe -noConsole -iconFile .\Source\icon.ico -title "OCR snip tool" -noOutput -noError

# Zip the deployment
Compress-Archive -Path .\$folderName -DestinationPath "$folderName.zip" -Force