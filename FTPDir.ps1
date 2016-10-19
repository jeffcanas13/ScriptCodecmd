param (
    [string]$ftp = "ftp://ftptarget.com",
    [string]$user = "user",
    [string]$pass = "pass",
    [string]$folder = "FTPFolder",
    [string]$target = "",
    [string]$errorFile = ""
)

    #SET CREDENTIALS
    $credentials = new-object System.Net.NetworkCredential($user, $pass)

    function Get-FtpDir ($url,$credentials) {
        $request = [Net.WebRequest]::Create($url)
        $request.Method = [System.Net.WebRequestMethods+FTP]::ListDirectory
        if ($credentials) { $request.Credentials = $credentials }
        $response = $request.GetResponse()
        $reader = New-Object IO.StreamReader $response.GetResponseStream() 
        $reader.ReadToEnd()
        $reader.Close()
        $response.Close()
    }

    #SET FOLDER PATH
    $folderPath = $ftp + "" + $folder + "/"

    try 
    {
      $Allfiles=Get-FTPDir -url $folderPath -credentials $credentials
      $files = ($Allfiles -split "`r`n")

      $files 

      $webclient = New-Object System.Net.WebClient 
      $webclient.Credentials = New-Object System.Net.NetworkCredential($user,$pass) 
      $counter = 0
      foreach ($file in ($files | where {$_ -like "*.*"})){
        $source=$folderPath + $file  
        $dest = $target + $file 
        $counter++
        $counter
        Write-host "Source: " $source
        Write-host "Target: " $dest
        try {
            $webclient.DownloadFile($source, $dest)
        }
        catch 
        {
          if ($errorFile -eq "") {
            throw "Failed to download file '{0}/{1}'. The error was {2}." -f $source, $dest, $_
          }
          $cmerror="CMERROR=true";
          $cmerrordesc="CMERRORDESC=Failed to download file '{0}/{1}'. The error was {2}." -f $ftpFolder, $file, $_
          $cmerror>$errorFile
          $cmerrordesc>>$errorFile
          write-host $cmerrordesc
        }
      }
    } 
    catch 
    {
      if ($errorFile -eq "") {
        throw "Failure on code move ftp folder '{0}'. The error was {1}." -f $folderPath, $_
      }
      $cmerror="CMERROR=true";
      $cmerrordesc="CMERRORDESC=Failure on code move ftp folder '{0}'. The error was {1}." -f $folderPath, $_
      $cmerror>$errorFile
      $cmerrordesc>>$errorFile
      write-host $cmerrordesc
    }
