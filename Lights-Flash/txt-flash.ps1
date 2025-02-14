param (
    [string]$FilePath = "test.txt",  # Default file path
    [int]$Delay = 200               # Default delay in milliseconds
)

# Add the Keyboard class before usage
Add-Type @"
using System;
using System.Runtime.InteropServices;

public class Keyboard {
    [DllImport("user32.dll", CharSet = CharSet.Auto, ExactSpelling = true)]
    public static extern short GetKeyState(int keyCode);

    [DllImport("user32.dll")]
    public static extern void keybd_event(byte bVk, byte bScan, uint dwFlags, UIntPtr dwExtraInfo);

    public const int KEYEVENTF_KEYUP = 0x2;
}
"@

# Check if the file exists
if (-Not (Test-Path $FilePath)) {
    Write-Host "Error: File '$FilePath' does not exist. Please provide a valid file path." -ForegroundColor Red
    exit
}

# Read the file and convert it to binary (1's and 0's)
$fileContent = Get-Content -Raw -Path $FilePath
if (-Not $fileContent) {
    Write-Host "Error: File '$FilePath' is empty or could not be read." -ForegroundColor Red
    exit
}

# Print the file content for verification
Write-Host "File Content: $fileContent" -ForegroundColor Cyan

# Convert the file content to binary
$binaryData = -join ([System.Text.Encoding]::UTF8.GetBytes($fileContent) | ForEach-Object { 
    [Convert]::ToString($_, 2).PadLeft(8, '0') 
})

# Print the binary data for verification
Write-Host "Binary Data: $binaryData" -ForegroundColor Yellow

# Function to toggle keys (Num Lock, Caps Lock, Scroll Lock)
function Toggle-Key {
    param (
        [string]$KeyName
    )
    # Get virtual key code for the key
    $virtualKey = switch ($KeyName) {
        "CapsLock" { 0x14 }
        "NumLock" { 0x90 }
        "ScrollLock" { 0x91 }
        default { return }
    }

    # Check current state of the key
    $keyState = [Keyboard]::GetKeyState($virtualKey)
    $isToggled = $keyState -band 0x01

    # Toggle the key to change its state
    [Keyboard]::keybd_event($virtualKey, 0, 0, [UIntPtr]::Zero)        # Key down
    [Keyboard]::keybd_event($virtualKey, 0, [Keyboard]::KEYEVENTF_KEYUP, [UIntPtr]::Zero)  # Key up

    # If the key was already toggled, toggle it again to reset its state
    if ($isToggled) {
        Start-Sleep -Milliseconds 50
        [Keyboard]::keybd_event($virtualKey, 0, 0, [UIntPtr]::Zero)    # Key down
        [Keyboard]::keybd_event($virtualKey, 0, [Keyboard]::KEYEVENTF_KEYUP, [UIntPtr]::Zero)  # Key up
    }
}

# Store the original states of Caps Lock, Num Lock, and Scroll Lock
$originalCapsLockState = [Keyboard]::GetKeyState(0x14) -band 0x01
$originalNumLockState = [Keyboard]::GetKeyState(0x90) -band 0x01
$originalScrollLockState = [Keyboard]::GetKeyState(0x91) -band 0x01

# Loop through each bit in the binary data and toggle LEDs
foreach ($bit in $binaryData.ToCharArray()) {
    if ($bit -eq '1') {
        Toggle-Key -KeyName "CapsLock"
    } else {
        Toggle-Key -KeyName "NumLock"
    }
    Start-Sleep -Milliseconds $Delay  # Adjust the delay dynamically
}

# Decode the binary back to characters for printing to console
$decodedText = [System.Text.Encoding]::UTF8.GetString(
    [System.Convert]::FromBase64String(
        [string]::Join("", $binaryData -split "(?<=\G.{8})")
    )
)
Write-Host "Decoded Text: $decodedText" -ForegroundColor Green

# Change Scroll Lock to the opposite of its original state
Toggle-Key -KeyName "ScrollLock"  # Scroll Lock was ON, turn it OFF

# Reset all locks to their original states only if needed
if ($originalCapsLockState -ne ([Keyboard]::GetKeyState(0x14) -band 0x01)) {
    Toggle-Key -KeyName "CapsLock"
}
if ($originalNumLockState -ne ([Keyboard]::GetKeyState(0x90) -band 0x01)) {
    Toggle-Key -KeyName "NumLock"
}
if ($originalScrollLockState -ne ([Keyboard]::GetKeyState(0x91) -band 0x01)) {
    Toggle-Key -KeyName "ScrollLock"
}
