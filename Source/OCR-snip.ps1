# Read ini file function 
# Source: https://stackoverflow.com/questions/43690336/powershell-to-read-single-value-from-simple-ini-file
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

###############################################################################
### Function to provide a graphical input box to accept input from
###############################################################################
# Source: https://github.com/n2501r/spiderzebra/blob/master/PowerShell/GUI_Text_Box.ps1
Function GUI_TextBox ($Input_Type){
    # Window size variables
    $WIDTH = 600
    $HEIGHT = 600
    $BORDER = 90
    $TEXTBOX_WIDTH = $WIDTH-$BORDER
    $TEXTBOX_HEIGHT = $HEIGHT-$BORDER

    ### Creating the form with the Windows forms namespace
    Add-Type -AssemblyName System.Windows.Forms
    Add-Type -AssemblyName System.Drawing
    $form = New-Object System.Windows.Forms.Form
    $form.Text = 'OCR snipping tool' ### Text to be displayed in the title
    $form.Size = New-Object System.Drawing.Size($WIDTH,$HEIGHT) ### Size of the window
    $form.StartPosition = 'CenterScreen'  ### Optional - specifies where the window should start
    #$form.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::FixedToolWindow  ### Optional - prevents resize of the window
    $form.Topmost = $true  ### Optional - Opens on top of other windows

    ### Putting a label above the text box
    $label = New-Object System.Windows.Forms.Label
    $label.Location = New-Object System.Drawing.Point(10,10) ### Location of where the label will be
    $label.AutoSize = $True
    $Font = New-Object System.Drawing.Font("Arial",12,[System.Drawing.FontStyle]::Bold) ### Formatting text for the label
    $label.Font = $Font
    $label.Text = $Input_Type ### Text of label, defined by the parameter that was used when the function is called
    $label.ForeColor = 'Black' ### Color of the label text
    $form.Controls.Add($label)

    ### Inserting the text box that will accept input
    $textBox = New-Object System.Windows.Forms.TextBox
    $textBox.Location = New-Object System.Drawing.Point(10,40) ### Location of the text box
    $textBox.Size = New-Object System.Drawing.Size($TEXTBOX_WIDTH,$TEXTBOX_HEIGHT) ### Size of the text box
    $textBox.Multiline = $true ### Allows multiple lines of data
    $textbox.AcceptsReturn = $true ### By hitting enter it creates a new line
    $textBox.ScrollBars = "Vertical" ### Allows for a vertical scroll bar if the list of text is too big for the window
    $textBox.Lines = $tesseractOutput
    $form.Controls.Add($textBox)

    $form.Add_Shown({$textBox.Select()}) ### Activates the form and sets the focus on it
    $result = $form.ShowDialog() ### Displays the form 
}

# Before start the clipboard is overwritten
Function Set-Clipboard-Initial-Error-Message
{
        Set-Clipboard -Value "***There was no image selected!***"
}

# Prepare the file write to disk
Function Create-Path-If-Not-Exists ($imageTempPath)
{ 
        If(!(test-path -PathType container $imageTempPath))
        {
        New-Item -Path "$imageTempPath" -ItemType Directory
        }
}

#################################
# SCRIPT START 
#################################
# Read ini file 
$iniFile = Get-IniFile config.ini
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

# Should the recognized text be shown instead of just copied to clipboard? (True of False)
$showOcrTextVar = $iniFile.tesseract_options.show_ocr_text

# Get the required tesseract languages
$tesseractLanguages= $iniFile.tesseract_options.languages

# Set the clipboard with the initial error message
Set-Clipboard-Initial-Error-Message

# Run the snipping tool, after which the image will be on the clipboard
# The | Out-Null trick is so the script doesn't continue
& "$snippingToolPath" "/clip" | Out-Null

# Save the image from clipboard to disk so it can be passed to Tesseract
$image = Get-Clipboard -Format Image
$image.save($tempImageFullPath)

# Call tesseract exe
# e.g.: tesseract input.jpg output_type -l language
$tesseractOutput = & "$tesseractPath" "$tempImageFullPath" "stdout" -l $tesseractLanguages 

#Check if the output is not empty -ne : not equal
if($tesseractOutput -ne $null -and $tesseractOutput -ne "")
{
        Set-Clipboard -Value $tesseractOutput
        ### Calls the text box function with a parameter and puts returned input in variable
        if ($showOcrTextVar -eq "True")
        {
        GUI_TextBox "OCR text: (already on clipboard)"
        }
} else {
        Set-Clipboard -Value "*** There was no readable text in the selected area ***"
        [System.Reflection.Assembly]::LoadWithPartialName('System.Windows.Forms')
        [System.Windows.Forms.MessageBox]::Show('There was no readable text in the selected area','WARNING')
}

# Delete the temporary image
if (Test-Path $tempImageFullPath) {
  Remove-Item $tempImageFullPath
}