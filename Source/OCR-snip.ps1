# Read ini file function from here: https://stackoverflow.com/questions/43690336/powershell-to-read-single-value-from-simple-ini-file
function Get-IniFile 
{  
    param(  
        [parameter(Mandatory = $true)] [string] $filePath  
    )  
    
    $anonymous = "NoSection"
  
    $ini = @{}  
    switch -regex -file $filePath  
    {  
        "^\[(.+)\]$" # Section  
        {  
            $section = $matches[1]  
            $ini[$section] = @{}  
            $CommentCount = 0  
        }  

        "^(;.*)$" # Comment  
        {  
            if (!($section))  
            {  
                $section = $anonymous  
                $ini[$section] = @{}  
            }  
            $value = $matches[1]  
            $CommentCount = $CommentCount + 1  
            $name = "Comment" + $CommentCount  
            $ini[$section][$name] = $value  
        }   

        "(.+?)\s*=\s*(.*)" # Key
        {
            if (!($section))
            {  
                $section = $anonymous
                $ini[$section] = @{}
            }  
            $name,$value = $matches[1..2]
            $ini[$section][$name] = $value
        }  
    }  

    return $ini
}

Function Set-Clipboard-Initial-Error-Message
{
        Set-Clipboard -Value "***There was no image selected!***"
}

Function Create-Path-If-Not-Exists ($imageTempPath)
{ 
        If(!(test-path -PathType container $imageTempPath))
        {
        New-Item -Path "$imageTempPath" -ItemType Directory
        }
}

# Read ini file 
$iniFile = Get-IniFile .\config.ini
# Get the tesseract exe location
$tesseractPath= $iniFile.paths.tesseract_exe
# Get the snipping tool exe location
$snippingToolPath= $iniFile.paths.snipping_tool_exe
# Get image temp path
$imageTempPath= $iniFile.paths.temp_image_path
# Create the path
Create-Path-If-Not-Exists($imageTempPath)
# Create temp image full path
$tempImageFullPath = -join("$imageTempPath", "\tempimage.png")

# Get the required tesseract languages
$tesseractLanguages= $iniFile.tesseract_options.languages

# Set the clipboard with the initial error message
Set-Clipboard-Initial-Error-Message

# Write-Output $tesseractPath
# Write-Output $snippingToolPath

# Run the snipping tool, after which the image will be on the clipboard
# The | Out-Null trick is so the script doesn't continue
& "$snippingToolPath" "/clip" | Out-Null
#Write-Output $LASTEXITCODE

$image = Get-Clipboard -Format Image
$image.save($tempImageFullPath)

# Call tesseract exe
# examples
# tesseract input.jpg stdout
# time tesseract images/bilingual.png - -l eng+hin
$tesseractOutput = & "$tesseractPath" "$tempImageFullPath" "stdout" -l $tesseractLanguages | Out-Null

Write-Output $tesseractOutput



# Delete the temporary image
#if (Test-Path $tempImageFullPath) {
#  Remove-Item $tempImageFullPath
#}