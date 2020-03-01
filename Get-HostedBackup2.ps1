#Import functions
. .\Send-Email.ps1
. .\New-TemporaryDirectory.ps1
. .\Write-Log.ps1
. .\Read-Config.ps1
. .\New-Password.ps1
. .\Invoke-MysqlQuery.ps1
. .\Update-VcRedist.ps1
#Backup and Upload Function
function Get-HostedBackup {
  [CmdletBinding()]
  param(
    #Testing is used for local Azure Storage Emulation
    [Parameter(Mandatory = $false)]
    [switch]
    $IsTest
  )
  try {

    $ErrorActionPreference = "stop";
    # $DebugPreference = "continue";
    # $VerbosePreference = "continue";
    # $WarningPreference = "continue";

    Write-Output "All Logging and information will be in C:\Logs\MYSQL2BLOB.log";
    #Create/Read Config file
    Read-Config | Out-Null;

    Write-Log -Message "Checking for required modules";
    if ($PSVersionTable.PSVersion -lt '6.2') {
      Install-PackageProvider -Name NuGet -Force | Out-Null;
    }

    if (-not (Get-InstalledModule Az -ErrorAction SilentlyContinue)) {
      Write-Log -Message "Installing Az";
      Install-Module -Name Az -Force -AllowClobber | Out-Null;
      Import-Module -Name Az;
    };

    Import-Module -Name Az;

    # Download, install, and run Storage Emulator if using Testing Switch
    if ($IsTest) {

      if (Test-Path "C:\Program Files (x86)\Microsoft SDKs\Azure\Storage Emulator\AzureStorageEmulator.exe") {
        # get AzureStorageEmulator process
        $StorageEmulator = Get-Process AzureStorageEmulator.exe -ErrorAction SilentlyContinue
        if ($StorageEmulator) {
          # try gracefully first
          $StorageEmulator.CloseMainWindow()
          # kill after five seconds
          Start-Sleep 5
          if (-not $StorageEmulator.HasExited) {
            $StorageEmulator | Stop-Process -Force
          }
        }
        Remove-Variable StorageEmulator
        Start-Process "C:\Program Files (x86)\Microsoft SDKs\Azure\Storage Emulator\AzureStorageEmulator.exe" -ArgumentList "start";
      }

      Write-Log -Message "Downloading Azure Storage Emulator for local testing"
      Invoke-WebRequest -UseBasicParsing -Uri "https://go.microsoft.com/fwlink/?linkid=717179&clcid=0x409" -OutFile "$ENV:USERPROFILE\Downloads\storageemulator.msi";
      Start-Process -FilePath "$ENV:USERPROFILE\Downloads\storageemulator.msi" -Wait -ArgumentList '/quiet /l* emulatorinstalllog.txt';
      Write-Log -Message "Starting Azure Storage Emulator";
      Start-Process "C:\Program Files (x86)\Microsoft SDKs\Azure\Storage Emulator\AzureStorageEmulator.exe" -ArgumentList "init" -Wait;
      Start-Process "C:\Program Files (x86)\Microsoft SDKs\Azure\Storage Emulator\AzureStorageEmulator.exe" -ArgumentList "start";
    }

    # Check if MySQL is installed
    if (-not (Test-Path "C:\Program Files\MySQL2\*\bin")) {
      #Download MySQL
      try {
        $SqlLocation = "C:\Program Files\";
        $MySQLFolder = New-Item -Path "$SqlLocation\MySQL2" -ItemType Directory -Force;
        Write-Log -Message "Downloading MySQL And Adding to Path";
        Invoke-WebRequest -UseBasicParsing -Uri "https://dev.mysql.com/get/Downloads/MySQL-5.7/mysql-5.7.28-winx64.zip" -OutFile "$MySQLFolder\mysql.zip";
        Expand-Archive -Path "$MySQLFolder\mysql.zip" -Force -DestinationPath "$MySQLFolder";
        #Install visualstudio redistributables
        Write-Log -Message "Installing Visual Studio C++ Redistributables";
        Update-VcRedist
      }
      catch {
        Write-Log -Message "Looks like we can't download MySQL.";
        Write-Log -Message "Please send this error to Support: $_";
        throw;
      }
    }

    #Temporaily add to path
    if ($Env:Path -notlike "*mysql2*") {
      $mysqlpath = Resolve-Path "C:\Program Files\MySQL2\*\bin";
      $Env:Path += ";$mysqlpath";
      $oldpath = (Get-ItemProperty -Path 'Registry::HKEY_LOCAL_MACHINE\System\CurrentControlSet\Control\Session Manager\Environment' -Name PATH).path
      $newpath = "$oldpath;$mysqlpath";
      Set-ItemProperty -Path 'Registry::HKEY_LOCAL_MACHINE\System\CurrentControlSet\Control\Session Manager\Environment' -Name PATH -Value $newPath;
    }

    # if azcopy not found, download it
    if (-not (Test-Path "c:\program files\azcopy\*\azcopy.exe")) {
      try {
        New-Item -Path 'C:\Program Files\azcopy' -ItemType Directory -Force;
        Invoke-WebRequest -UseBasicParsing -Uri "https://aka.ms/downloadazcopy-v10-windows" -OutFile "c:\program files\azcopy\azcopy.zip";
        Expand-Archive -Path "c:\program files\azcopy\azcopy.zip" -DestinationPath "c:\program files\azcopy\" -Force;
        $AzCopyExe = Get-ChildItem -Path "c:\program files\azcopy\*\azcopy.exe" -Recurse;
      } catch {
        Write-Log -Message "Looks like we can't download the azcopy file.";
        Write-Log -Message "Please send this error to Support: $_";
        throw;
      }
    }

    $AzCopyExe = Get-ChildItem -Path "c:\program files\azcopy\*\azcopy.exe" -Recurse;

    #Add azcopy.exe to path
    if ($env:path -notlike "*azcopy*") {
      $azcopypath = $($AzCopyExe.FullName)
      $env:Path += ";$azcopypath"
    }

    #Create temporary directory to store MySQL dumps
    $BackupDestination = New-TemporaryDirectory;
    Write-Log -Message "Temporary file location set to: `'$($BackupDestination.FullName)`'";
    Write-Log -Message "Querying MySQL server to get a list of databases";

    #password and username for database query
    $pass = ConvertTo-SecureString -AsPlainText $DatabasePassword -Force;
    $CredentialObject = New-Object System.Management.Automation.PSCredential ($databaseUserShort,$pass)

    #Get All Database names 
    $query = 'SELECT schema_name FROM information_schema.schemata;';
    $Databases = Invoke-MySQLQuery -ComputerName $DatabaseServer -Credential $CredentialObject -Query $query -Verbose;

    #Create Connection to Azure
    if ($IsTest) {
      $ConnectionString = 'DefaultEndpointsProtocol=http;AccountName=devstoreaccount1;AccountKey=Eby8vdM02xNOcqFlqUwJPLlmEtlCDXJ1OUzFT50uSRZ6IFsuFq2UVErCz4I6tq/K1SZFPTOtr/KBHBeksoGMGw==;BlobEndpoint=http://127.0.0.1:10000/devstoreaccount1;'
      $storage_account = New-AzStorageContext -Local;
    } else {
      $ConnectionString = 'REDACTED';
      $storage_account = New-AzStorageContext -ConnectionString $ConnectionString;
    }

    # Loop through each database and get rid of the ones we do not need to backup
    $filteredDatabases = $Databases | Where-Object { $_.schema_name -notlike "information_schema*" -and $_.schema_name -notlike "sys*" -and $_.schema_name -notlike "performance_schema" -and $_.schema_name -notlike "mysql*" };

    foreach ($database in $filteredDatabases) {
      #Assign variables for use later (should be cleaned up)
      $databaseName = $database.schema_name;
      $SchoolName = $DatabaseName;

      Write-Log -Message "Now Grabbing Database Backup";

      #Get the current date and time to use as a unqiue file name
      $suffix = (Get-Date).ToString("yyyyMMdd-HHmmss");

      $DatabaseBackupName = "$($SchoolName)_$($suffix).sql";
      $ZipFileName = "$($SchoolName)_$($suffix).zip";

      try {
        #try to grab dump and redirect all errors to stdout
        $err = @((mysqldump -u $($DatabaseUser) --password=$($DatabasePassword) -h $($DatabaseServer) -P 3306 --extended-insert --routines $($DatabaseName) | Out-File $("$($BackupDestination.FullName)\$DatabaseBackupName") -Encoding ascii));
        if ($err | Select-String "Got Error") {
          if (Test-Path $DatabaseName) {
            Remove-Item $DatabaseName;
          }
          if (Test-Path $DatabaseBackupName) {
            Remove-Item $DatabaseBackupName;
          }
          throw "MySQL Dump failed";
        }

        # Zip the .sql to a .zip
        Compress-Archive -Path (Join-Path -Path $BackupDestination.FullName -ChildPath $DatabaseBackupName) -DestinationPath "$($BackupDestination.FullName)\$ZipFileName";
        Write-Log -Message "Finished taking the backup.";
        Write-Log -Message "Now uploading backup to container.";

        #start sending stuff to Azure
        Write-Log -Message "Now Connecting to Azure Blob Storage for container $databaseName";
        if ($databaseName -eq 'backing_server') {
          $databaseName = 'backingserver';
        }
        $container_name = $databaseName;
        try {
          #Check if container exist
          Get-AzStorageContainer -Context $storage_account -Container $container_name;
        }
        catch {
          Write-Log -Message "Creating storage container";
          try {
            New-AzStorageContainer -Name "$container_name" -Context $storage_account;
          }
          catch {
            Write-Log -Message "Looks like something went wrong. See here: $_";
            throw;
          }
        }

        #Generate SAS Key for each container
        $Now = Get-Date;
        $SASKEY = New-AzStorageContainerSASToken -Name $container_name -Context $storage_account -Permission rwdl -StartTime $now.AddHours(-1) -ExpiryTime $now.adddays(1);

        #Copy data to instance storage
        Write-Log -Message "Sending files to the Azure containers.";

        #Send backup
        if ($IsTest) {
          $AZCOPYOUTPUT = &$AzCopyExe copy `"$($BackupDestination)\$ZipFileName`" `"http://127.0.0.1:10000/devstoreaccount1/$($container_name)/databasebackup/$($ZipFileName)$($SASKEY)`" --recursive --from-to=LocalBlob
        } else {
          $AZCOPYOUTPUT = &$AzCopyExe copy `"$($BackupDestination)\$ZipFileName`" `"https://REDACTED/$($container_name)/databasebackup/$($ZipFileName)$($SASKEY)`" --recursive
        }
        if ($AZCOPYOUTPUT -like "*error*")
        {
          Write-Log -Message "Error Uploading Azure Databases: $AZCOPYOUTPUT"
          throw "Error uploading azure databases: $AZCOPYOUTPUT"
        }

      }
      catch {
        Write-Log -Message "Hmm looks like we can't grab the backup, see error below:";
        Write-Log -Message "$_";
        throw;
      }
    }
  } catch {
    Write-Log -Message "Something Went Wrong, sending email alert to REDACTED";
    Write-Log -Message "Please see error $_";

    #Send an email if something went wrong
    Send-Email;

  }
  finally {

    # Always cleanup the temp folder
    if (Test-Path $BackupDestination | Out-Null) {
      Remove-Item $BackupDestination -Force -Recurse | Out-Null;
    }
  }
}
Get-HostedBackup;
