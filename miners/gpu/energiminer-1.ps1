##Miner Path Information
if ($nvidia.energiminer.path1) {$Path = "$($nvidia.energiminer.path1)"}
else {$Path = "None"}
if ($nvidia.energiminer.uri) {$Uri = "$($nvidia.energiminer.uri)"}
else {$Uri = "None"}
if ($nvidia.energiminer.minername) {$MinerName = "$($nvidia.energiminer.minername)"}
else {$MinerName = "None"}
if ($Platform -eq "linux") {$Build = "Tar"}
elseif ($Platform -eq "windows") {$Build = "Zip"}

$ConfigType = "NVIDIA1"

##Parse -GPUDevices
if ($NVIDIADevices1 -ne "none") {
    $GPUDevices1 = $NVIDIADevices1
    $GPUDevices1 = $GPUDevices1 -replace ',', ' '
    $Devices = $GPUDevices1
}
else {$Devices = "none"}
  
##Get Configuration File
$GetConfig = "$dir\config\miners\energiminer.json"
try {$Config = Get-Content $GetConfig | ConvertFrom-Json}
catch {Write-Warning "Warning: No config found at $GetConfig"}

##Export would be /path/to/[SWARMVERSION]/build/export##
$ExportDir = Join-Path $dir "build\export"

##Prestart actions before miner launch
$BE = "/usr/lib/x86_64-linux-gnu/libcurl-compat.so.3.0.0"
$Prestart = @()
$PreStart += "export LD_LIBRARY_PATH=$ExportDir"
$Config.$ConfigType.prestart | foreach {$Prestart += "$($_)"}
        
##Build Miner Settings
if ($CoinAlgo -eq $null) {
    $Config.$ConfigType.commands | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name | ForEach-Object {
        $MinerAlgo = $_
        $AlgoPools | Where Symbol -eq $MinerAlgo | foreach {
            if ($Algorithm -eq "$($_.Algorithm)" -and $Bad_Miners.$($_.Algorithm) -notcontains $Name) {
                if ($Config.$ConfigType.difficulty.$($_.Algorithm)) {$Diff = ",d=$($Config.$ConfigType.difficulty.$($_.Algorithm))"}else {$Diff = ""}
                [PSCustomObject]@{
                    Delay      = $Config.$ConfigType.delay
                    Platform   = $Platform
                    Symbol     = "$($_.Algorithm)"
                    MinerName  = $MinerName
                    Prestart   = $PreStart
                    Type       = $ConfigType
                    Path       = $Path
                    Devices    = $Devices
                    DeviceCall = "energiminer"
                    Arguments  = "-U stratum://$($_.User1).$($_.Pass1)@$($_.Algorithm).mine.zergpool.com:$($_.Port)"
                    HashRates  = [PSCustomObject]@{$($_.Algorithm) = $($Stats."$($Name)_$($_.Algorithm)_hashrate".Day)}
                    Quote      = if ($($Stats."$($Name)_$($_.Algorithm)_hashrate".Day)) {$($Stats."$($Name)_$($_.Algorithm)_hashrate".Day) * ($_.Price)}else {0}
                    PowerX     = [PSCustomObject]@{$($_.Algorithm) = if ($Watts.$($_.Algorithm)."$($ConfigType)_Watts") {$Watts.$($_.Algorithm)."$($ConfigType)_Watts"}elseif ($Watts.default."$($ConfigType)_Watts") {$Watts.default."$($ConfigType)_Watts"}else {0}}
                    ocpower    = if ($Config.$ConfigType.oc.$($_.Algorithm).power) {$Config.$ConfigType.oc.$($_.Algorithm).power}else {$OC."default_$($ConfigType)".Power}
                    occore     = if ($Config.$ConfigType.oc.$($_.Algorithm).core) {$Config.$ConfigType.oc.$($_.Algorithm).core}else {$OC."default_$($ConfigType)".core}
                    ocmem      = if ($Config.$ConfigType.oc.$($_.Algorithm).memory) {$Config.$ConfigType.oc.$($_.Algorithm).memory}else {$OC."default_$($ConfigType)".memory}
                    ocfans     = if ($Config.$ConfigType.oc.$($_.Algorithm).fans) {$Config.$ConfigType.oc.$($_.Algorithm).fans}else {$OC."default_$($ConfigType)".fans}
                    MinerPool  = "$($_.Name)"
                    FullName   = "$($_.Mining)"
                    Port       = 0
                    API        = "energiminer"
                    Wrap       = $false
                    URI        = $Uri
                    BUILD      = $Build
                    Algo       = "$($_.Algorithm)"
                    NewAlgo    = ''
                }
            }
        }
    }
}