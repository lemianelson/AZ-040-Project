$computer = "LON-DC1"
$OS = Get-CimInstance -class Win32_OperatingSystem -ComputerName $computer


$cDrive = Get-CimInstance -class Win32_LogicalDisk -Filter "DeviceID='C:'"


$uptime = $OS.LocalDateTime - $OS.lastBootUpTime



$info = [PSCustomObject]@{
    computername = $computer
    OS = $OS.Caption
    LastBootUpTime = $OS.lastBootUpTime
    CDriveSize = $cDrive.Size
    CDriveFreeSpace = $cDrive.FreeSpace
    CDriveFreeSpaceGB = [math]::Round(($cDrive.freeSpace / 1GB), 2)
    UptimeHours = [math]::Round($uptime.TotalHours, 2)
}
write-output $info