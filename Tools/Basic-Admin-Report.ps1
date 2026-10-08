$system = get-CimInstance -ClassName Win32_OperatingSystem | 
Select-Object Name, Manufacturer, Model, Domain
$system

$system.Name
$system.Manufacturer
$system.Model
$system.Domain

$system | select-object Name, Manufacturer, Model

$system | Get-Member -MemberType Property
$system.NumberOfLogicalProcessors


$computerReport = $system |
    Select-Object Name, Manufacturer, Model, Domain,
                  NumberOfLogicalProcessors
$computerReport

$bios = Get-CimInstance -ClassName Win32_BIOS
$bios

$bios.Manufacturer
$bios.SMBIOSBIOSVersion
$bios.SerialNumber

$biosReport = $bios |
    Select-Object Manufacturer, SMBIOSBIOSVersion, SerialNumber
$biosReport

$reportProperties = @{
    ComputerName      = $system.Name
    Manufacturer      = $system.Manufacturer
    Model             = $system.Model
    Domain            = $system.Domain
    LogicalProcessors = $system.NumberOfLogicalProcessors
    BIOSManufacturer  = $bios.Manufacturer
    BIOSVersion       = $bios.SMBIOSBIOSVersion
    SerialNumber      = $bios.SerialNumber
}
$reportProperties


$reportProperties['LON-DC1']



$adminReport = [pscustomobject]$reportProperties
$adminReport


$adminReport | Get-Member -MemberType NoteProperty
$adminReport.ComputerName
$adminReport | Select-Object ComputerName, Model, BIOSVersion



$reportFolder = $env:USERPROFILE
$reportFolder

$adminReport |
    Export-Csv "$reportFolder\AdminReport.csv" -NoTypeInformation

$adminReport |
    Export-Csv "$reportFolder\AdminReport.csv" -NoTypeInformation

Import-Csv "$reportFolder\AdminReport.csv"


$adminReport | Select-Object ComputerName, Domain
$adminReport | Select-Object Domain, ComputerName

$adminReport |
    Export-Csv "$reportFolder\AdminReport.csv" -NoTypeInformation

Import-Csv "$reportFolder\AdminReport.csv"


Import-Csv "$reportFolder\AdminReport.csv"

$reportProperties = @{
    ComputerName      = $system.Name
    Manufacturer      = $system.Manufacturer
    Model             = $system.Model
    Domain            = $system.Domain
    LogicalProcessors = $system.NumberOfLogicalProcessors
    BIOSManufacturer  = $bios.Manufacturer
    BIOSVersion       = $bios.SMBIOSBIOSVersion
    SerialNumber      = $bios.SerialNumber
    BIOSReleaseDate   = $bios.ReleaseDate
}

