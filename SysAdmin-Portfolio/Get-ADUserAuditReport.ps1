<#
.SYNOPSIS
    Audits Active Directory user accounts based on their status (Locked, Expired, Disabled).
.DESCRIPTION
    This script queries Active Directory for user accounts matching specific security states.
    It gathers relevant properties (LastLogonDate, PasswordExpired, etc.) and exports 
    the findings to a CSV and HTML report for IT auditing and compliance.
    "When run against the Adatum lab environment, the script successfully audited the domain and returned 0 locked accounts,
     indicating a healthy security state. 
     The script is designed to handle both populated results and empty results without throwing errors."
.Author
   Nelson Tanyi - MSSA Server and Cloud Administration Participant
#>

function Get-ADUserAuditReport {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [ValidateSet("LockedOut", "PasswordExpired", "Disabled", "All")]
        [string]$AccountStatus = "LockedOut",

        [Parameter(Mandatory = $false)]
        [string]$SearchBase = "DC=Adatum,DC=com",

        [Parameter(Mandatory = $false)]
        [string]$OutputPath = "$env:USERPROFILE\Desktop\ADAuditReports"
    )

    begin {
        # 1. Ensure the ActiveDirectory module is available
        if (-not (Get-Module -ListAvailable -Name ActiveDirectory)) {
            Write-Error "The ActiveDirectory module is not installed on this machine."
            return
        }
        Import-Module ActiveDirectory -ErrorAction Stop

        # 2. Create output directory if it doesn't exist
        if (-not (Test-Path -Path $OutputPath)) {
            New-Item -ItemType Directory -Path $OutputPath -Force | Out-Null
        }

        $AuditData = @()
        Write-Verbose "Starting AD User Audit for status: $AccountStatus"
    }
 process {
        try {
            Write-Verbose "Querying Active Directory for status: $AccountStatus"
            $users = @()

            # Use Search-ADAccount for LockedOut, Get-ADUser for others
            if ($AccountStatus -eq "LockedOut") {
                $users = Search-ADAccount -LockedOut -SearchBase $SearchBase -UsersOnly -ErrorAction Stop
            } 
            elseif ($AccountStatus -eq "PasswordExpired") {
                $users = Search-ADAccount -PasswordExpired -SearchBase $SearchBase -UsersOnly -ErrorAction Stop
            }
            else {
                # For "Disabled" or "All", Get-ADUser works perfectly
                if ($AccountStatus -eq "Disabled") {
                    $filter = { Enabled -eq $false }
                } else {
                    $filter = "*"
                }
                $users = Get-ADUser -Filter $filter -SearchBase $SearchBase -Properties LastLogonDate, PasswordExpired, LockedOut, EmailAddress -ErrorAction Stop
            }

            # Process each user into a clean custom object
            foreach ($user in $users) {
                # Note: Search-ADAccount returns slightly different properties, so we handle them safely
                $userObject = [pscustomobject]@{
                    SamAccountName   = $user.SamAccountName
                    DisplayName      = $user.Name
                    EmailAddress     = $user.EmailAddress
                    Enabled          = $user.Enabled
                    LockedOut        = $user.LockedOut
                    PasswordExpired  = $user.PasswordExpired
                    LastLogonDate    = if ($user.LastLogonDate) { $user.LastLogonDate.ToString('yyyy-MM-dd') } else { "Never" }
                    DistinguishedName= $user.DistinguishedName
                }
                $AuditData += $userObject
            }
        }
        catch {
            Write-Warning "Failed to query Active Directory. Error: $($_.Exception.Message)"
            return
        }
    }

    end {
        if ($AuditData.Count -eq 0) {
            Write-Host "No users found matching the criteria: $AccountStatus" -ForegroundColor Yellow
            return
        }

        # 6. Generate timestamps and file paths
        $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
        $csvFile = Join-Path -Path $OutputPath -ChildPath "ADAudit_$AccountStatus`_$timestamp.csv"
        $htmlFile = Join-Path -Path $OutputPath -ChildPath "ADAudit_$AccountStatus`_$timestamp.html"

        # 7. Export to CSV
        $AuditData | Export-Csv -Path $csvFile -NoTypeInformation -Encoding UTF8
        Write-Host "CSV Report saved to: $csvFile" -ForegroundColor Cyan
         # 8. Export to HTML with professional styling
        $htmlHeader = @"
        <style>
            body { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; margin: 20px; }
            h2 { color: #0078D7; }
            table { border-collapse: collapse; width: 100%; font-size: 14px; }
            th, td { border: 1px solid #dddddd; text-align: left; padding: 8px; }
            th { background-color: #0078D7; color: white; }
            tr:nth-child(even) { background-color: #f2f2f2; }
        </style>
        <h2>Active Directory User Audit Report</h2>
        <p><strong>Criteria:</strong> $AccountStatus | <strong>Generated:</strong> $(Get-Date)</p>
"@
        $AuditData | ConvertTo-Html -Head $htmlHeader | Out-File -FilePath $htmlFile
        Write-Host "HTML Report saved to: $htmlFile" -ForegroundColor Cyan
        
        # Output the data to the console as well
        return $AuditData
    }
}

Get-ADUserAuditReport -AccountStatus "LockedOut" -Verbose

# Get-ADUserAuditReport -AccountStatus "Disabled" -Verbose