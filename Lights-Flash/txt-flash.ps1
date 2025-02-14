param (
    [string]$FilePath = "test.txt",  # Default file path
    [int]$Delay = 200               # Default delay in milliseconds
)

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

$binaryData = -join ([System.Text.Encoding]::UTF8.GetBytes($fileContent) | ForEach-Object { 
    [Convert]::ToString($_, 2).PadLeft(8, '0') 
})

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
    
    # Call Windows API functions
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

# Loop through each bit in the binary data and toggle LEDs
foreach ($bit in $binaryData.ToCharArray()) {
    if ($bit -eq '1') {
        Toggle-Key -KeyName "CapsLock"
    } else {
        Toggle-Key -KeyName "NumLock"
    }
    Start-Sleep -Milliseconds $Delay  # Adjust the delay dynamically
}

# Enable Scroll Lock at the end
Toggle-Key -KeyName "ScrollLock"
Write-Host "Scroll Lock has been enabled." -ForegroundColor Green
