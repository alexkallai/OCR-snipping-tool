# OCR-snipping-tool
A productivity tool for Windows 10 and higher to just snip a part of the screen and then simply paste the recognized text where you need it
The tool captures the image, passes it to Tesseract, and the output of the character recogition is then put to clipboard

# Requirements
This tool uses Windows' Snipping tool to get the image, and Tesseract for character recognition
The paths should be configured in the .ini file for the Snipping tool exe, and the tesseract exe
It is recommended to use the installer version of Tesseract for Windows