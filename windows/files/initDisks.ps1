$disks = Get-Disk | Where partitionstyle -eq 'raw' | sort number

$count = 0
$labels = "data1","data2"

foreach ($disk in $disks) {
    $disk | 
    Initialize-Disk -PartitionStyle MBR -PassThru |
    New-Partition -UseMaximumSize |
    Format-Volume -FileSystem NTFS -NewFileSystemLabel $labels[$count] -Confirm:$false -Force
    $count++
}

if ($disks.Count() > 0) {
    $Partition = Get-Partition -DiskNumber $disks[0].Number
    New-Item -ItemType Directory -Path "C:\share"
    $Partition | Add-PartitionAccessPath -AccessPath "C:\Share"
}

