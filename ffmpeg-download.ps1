$url = "https://raw.githubusercontent.com/opencv/opencv_3rdparty/a66a24e9f410ae05da4baeeb8b451912664ce49c/ffmpeg/opencv_videoio_ffmpeg_64.dll"
$expected_md5 = "55c0bc8ad27db00116fabf06508de196"
$output = "$PSScriptRoot\bin\opencv_videoio_ffmpeg420_64.dll"

Write-Output ("=" * 120)
try {
    Get-content -Path "$PSScriptRoot\etc/licenses\ffmpeg-readme.txt" -ErrorAction 'Stop'
} catch {
    Write-Output "Refer to OpenCV FFmpeg wrapper readme notes about library usage / licensing details."
}
Write-Output ("=" * 120)
Write-Output ""

if(![System.IO.File]::Exists($output)) {
    try {
        [io.file]::OpenWrite($output).close()
    } catch {
        Write-Warning "Unable to write: $output"
        if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
            Write-Warning "Launching with 'Administrator' elevated privileges..."
            Pause
            Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
            exit
        } else {
            Write-Output "FATAL: Unable to write with elevated privileges: $output"
            Pause
            exit 1
        }
    }

    try {
        Write-Output ("Downloading: " + $output)
        Import-Module BitsTransfer
        $start_time = Get-Date
        Start-BitsTransfer -Source $url -Destination $output -ErrorAction 'Stop'
        Write-Output "Downloaded in $((Get-Date).Subtract($start_time).Seconds) seconds"
    } catch {
        $_ # Dump error
        try {
            Write-Output ("Downloading (second attempt): " + $output)
            $start_time = Get-Date
            Invoke-WebRequest -Uri $url -OutFile $output
            Write-Output "Downloaded in $((Get-Date).Subtract($start_time).Seconds) seconds"
        } catch {
            Write-Output ("Can't download file: " + $output)
            Write-Output ("URL: " + $url)
            Write-Output "You need to download this file manually. Stop"
            Pause
            Exit
        }
    }
} else {
    Write-Output ("File exists: " + $output)
    Write-Output ("Downloading is skipped. Remove this file and re-run this script to force downloading.")
}

if(![System.IO.File]::Exists($output)) {
    Write-Output ("Destination file not found: " + $output)
    Write-Output "Stop"
    Pause
    Exit
}

try {
    $hash = Get-FileHash $output -Algorithm MD5 -ErrorAction 'Stop'

    if($hash.Hash -eq $expected_md5) {
        Write-Output "MD5 check passed"
    } else {
        Write-Output ("MD5     : " + $hash.Hash.toLower())
        Write-Output ("Expected: " + $expected_md5)
        Write-Output "MD5 hash mismatch"
    }
} catch {
    $_ # Dump error
    Write-Output "Can't check MD5 hash (requires PowerShell 4+)"
}
Pause
Write-Output "Exit"
