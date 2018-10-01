
$ErrorLog = "C:\USERScriptErrors.txt"

Rename-Computer -NewName "__HOSTNAME__" | out-file "$ErrorLog"

net user Administrator "__ADMINPW__" | out-file "$ErrorLog"

$url = "https://raw.githubusercontent.com/ansible/ansible/devel/examples/scripts/ConfigureRemotingForAnsible.ps1"
$output = "C:\ConfigureRemotingForAnsible.ps1"

Invoke-WebRequest -Uri $url -OutFile $output | out-file "$ErrorLog"

powershell.exe -File $output -CertValidityDays 100 
