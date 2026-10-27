<#
.SYNOPSIS
    Gathers system inventory and health metrics from local or remote computers.
.DESCRIPTION
    This script queries CIM classes to retrieve OS details, hardware specs, and disk usage. 
    It handles offline computers gracefully and exports the data to a CSV and HTML report.
.AUTHOR
    Nelson Tanyi - MSSA(Server and Cloud Administration) Participant
#>


 function Get-SystemHealthReport {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [Alias('Name', 'DNSHostName')]
        [string[]]$ComputerName = $env:COMPUTERNAME,

        [Parameter(Mandatory = $false)]
        [string]$OutputPath = "$env:USERPROFILE\Desktop\SysAdminReports"
    )
    

    begin {
        # Create output directory if it doesn't exist
        if (-not (Test-Path -Path $OutputPath)) {
            New-Item -ItemType Directory -Path $OutputPath -Force | Out-Null
        }
        
        # Array to hold our final report objects
        $ReportData = @()
        Write-Verbose "Starting system health report generation..."
    }

    process {
        foreach ($computer in $ComputerName) {
            Write-Verbose "Processing: $computer"
            
            try {
                # 1. Get OS Info
                $os = Get-CimInstance -ClassName Win32_OperatingSystem -ComputerName $computer -ErrorAction Stop
                
                # 2. Get Hardware Info
                $cs = Get-CimInstance -ClassName Win32_ComputerSystem -ComputerName $computer -ErrorAction Stop
                
                # 3. Get Disk Info (Filter for DriveType 3 = Local Disk)
                $disks = Get-CimInstance -ClassName Win32_LogicalDisk -Filter "DriveType=3" -ComputerName $computer -ErrorAction Stop
                
                # Calculate Uptime
                $uptime = (Get-Date) - $os.LastBootUpTime
                
                # Calculate Total Disk Size and Free Space (in GB)
                $totalDiskGB = [math]::Round(($disks | Measure-Object -Property Size -Sum).Sum / 1GB, 2)
                $freeDiskGB = [math]::Round(($disks | Measure-Object -Property FreeSpace -Sum).Sum / 1GB, 2)
                $freeDiskPercent = [math]::Round(($freeDiskGB / $totalDiskGB) * 100, 2)

                # Create a custom object for this computer
                $reportObject = [pscustomobject]@{
                    ComputerName   = $computer
                    Status         = "Online"
                    OSVersion      = $os.Caption
                    LastBootUp     = $os.LastBootUpTime
                    UptimeDays     = $uptime.Days
                    Manufacturer   = $cs.Manufacturer
                    Model          = $cs.Model
                    TotalRAM_GB    = [math]::Round($cs.TotalPhysicalMemory / 1GB, 2)
                    TotalDisk_GB   = $totalDiskGB
                    FreeDisk_GB    = $freeDiskGB
                    FreeDisk_Percent = "$freeDiskPercent%"
                }
                
                $ReportData += $reportObject
                Write-Host "Successfully gathered data from $computer" -ForegroundColor Green

            } catch {
                # If the computer is offline or access is denied, log it gracefully
                Write-Warning "Failed to connect to $computer. Error: $($_.Exception.Message)"
                
                $reportObject = [pscustomobject]@{
                    ComputerName   = $computer
                    Status         = "Offline/Error"
                    OSVersion      = "N/A"
                    LastBootUp     = "N/A"
                    UptimeDays     = "N/A"
                    Manufacturer   = "N/A"
                    Model          = "N/A"
                    TotalRAM_GB    = "N/A"
                    TotalDisk_GB   = "N/A"
                    FreeDisk_GB    = "N/A"
                    FreeDisk_Percent = "N/A"
                }
                $ReportData += $reportObject
            }
        }
    }

end {
        $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
        $csvFile = Join-Path -Path $OutputPath -ChildPath "SystemHealth_$timestamp.csv"
        $htmlFile = Join-Path -Path $OutputPath -ChildPath "SystemHealth_$timestamp.html"

        # Export to CSV
        $ReportData | Export-Csv -Path $csvFile -NoTypeInformation -Encoding UTF8
        Write-Host "CSV Report saved to: $csvFile" -ForegroundColor Cyan

        # Export to HTML with some basic styling
        $htmlHeader = @"
        <style>
            body { font-family: Arial, sans-serif; }
            table { border-collapse: collapse; width: 100%; }
            th, td { border: 1px solid #dddddd; text-align: left; padding: 8px; }
            th { background-color: #0078D7; color: white; }
            .Offline { background-color: #ffcccc; }
        </style>
        <h2>System Health & Inventory Report</h2>
        <p>Generated on: $(Get-Date)</p>
"@
        $ReportData | ConvertTo-Html -Head $htmlHeader | Out-File -FilePath $htmlFile
        Write-Host "HTML Report saved to: $htmlFile" -ForegroundColor Cyan
    }
}
$LabComputers = @("tanyipc")
#$LabComputers = @("LON-CL1", "LON-DC1", "LON-SVR1")
Get-SystemHealthReport -ComputerName $LabComputers -Verbose


