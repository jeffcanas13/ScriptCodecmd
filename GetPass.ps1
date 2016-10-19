param (
    [string]$user = "",
    [string]$userType = ""
)
$regkey = 'HKLM:\SOFTWARE\CSC\ITO\Users';
$scriptPath = split-path -parent $MyInvocation.MyCommand.Definition;
$filename = $scriptPath + "\DefaultUserType.txt";
if ($userType -eq "") {
    if ($user -eq "") {
        If (Test-Path $filename) {
            $userType = Get-Content $filename;
        } else {
            write-host "Error: -user or -userType must be specified."
            return;
        }
    }
}
if ($user -eq "") {
    $user = (Get-ItemProperty -Path $regkey -Name $userType).$userType;
}
$reguserkey = $regkey + '\' + $user;
$keyStr = (Get-ItemProperty -Path $reguserkey -Name Key).Key
$key = [System.Text.Encoding]::ASCII.GetBytes($keyStr)
#$filename = $scriptPath + "\" + $user + ".txt";
#$encrypted = Get-Content $filename;
$encrypted = (Get-ItemProperty -Path $reguserkey -Name Password).Password
$password = ConvertTo-SecureString -string $encrypted -Key $key
$cred = new-object -typename System.Management.Automation.PSCredential -argumentlist $user,$password;
$plainPassword = $cred.GetNetworkCredential().Password;
write-host $plainPassword
