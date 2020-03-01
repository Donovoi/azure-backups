# This Script will read the Json config. If none can be found, it will automatically create one and prompt for the values.

. .\New-Password.ps1
. .\Write-Log.ps1
function Read-Config {
  $ErrorActionPreference = "silentlycontinue";
  $DebugPreference = "silentlycontinue";
  $VerbosePreference = "silentlycontinue";
  $WarningPreference = "silentlycontinue";
  $ConfirmPreference = "None";

  try {
    Write-Log -Message "Trying to Read configuration file.";
    try {
      Write-Log -Message 'Getting content of config.json'
      $config = Get-Content -Path ".\config.json" -ErrorAction 'Stop' | ConvertFrom-Json
      $config = [pscustomobject]@{
        emailUserName = $config.emailAuthentication.emailUserName;
        emailServer = $config.emailAuthentication.emailServer;
        emailPort = $config.emailAuthentication.emailPort;
        databaseUser = $config.databaseConfig.databaseUser;
        databaseUserShort = $config.databaseConfig.databaseUserShort;
        databaseServer = $config.databaseConfig.databaseServer;
      }
      # return $config
    } catch {
      throw "Can't find the JSON configuration file. Creating a new one"
    }
    $config
    foreach ($configprop in $config.PsObject.Properties) {
      switch ($configprop.Name) {
        emailUserName { New-Variable -Name emailUserName -Visibility Public -Value $configprop.Value -Force -Passthru -Option AllScope -Scope Global; }
        emailServer { New-Variable -Name emailServer -Visibility Public -Value $configprop.Value -Force -Passthru -Option AllScope -Scope Global; }
        emailPort { New-Variable -Name emailPort -Visibility Public -Value $configprop.Value -Force -Passthru -Option AllScope -Scope Global; }
        databaseUser { New-Variable -Name databaseUser -Visibility Public -Value $configprop.Value -Force -Passthru -Option AllScope -Scope Global; }
        databaseUserShort { New-Variable -Name databaseUserShort -Visibility Public -Value $configprop.Value -Force -Passthru -Option AllScope -Scope Global; }
        databaseServer { New-Variable -Name databaseServer -Visibility Public -Value $configprop.Value -Force -Passthru -Option AllScope -Scope Global; }
        Default {}
      }
    }
    
    New-Password -ReadDatabasePassword;
    New-Password -ReadEmailPassword;
    Write-Log -Message "Stored config.json found."
  }
  catch {
    Write-Log -Message "Creating Configuration"
    $jsonString = @"
  {   
  "databaseConfig": {  
    "databaseUser" : "REDACTED.mysql.database.azure.com",
    "databaseUserShort" : "REDACTED@REDACTED",
    "databaseServer" : "REDACTED.mysql.database.azure.com"
  },  
  "emailAuthentication" : {  
    "emailUserName" : "REDACTED",
    "emailServer" : "REDACTED,
    "emailPort" : "REDACTED" 
  }  
  }  
"@
    $config = $jsonString | ConvertFrom-Json
    Write-Log -Message "Creating config.json file";
    $config | ConvertTo-Json | Set-Content -Path ".\config.json"
    
    try {
      New-Password -ReadDatabasePassword;
    }
    catch {
      $databasepass = Read-Host -AsSecureString "Please enter the password for the database";
      New-Password -DatabasePasswordSwitch -DatabasePasswordString $databasepass;
    } 
    

    try {
      New-Password -ReadEmailPassword;
    }
    catch {
      $emailpass = Read-Host -AsSecureString "Please enter the password for the account that will send alert emails";
      New-Password -EmailPasswordSwitch -EmailPasswordString $emailpass;
    }

    foreach ($configprop in $config.PsObject.Properties) {

      switch ($configprop.Name) {
        emailUserName { New-Variable -Name emailUserName -Visibility Public -Value $configprop.Value -Force -Passthru -Option AllScope -Scope Global; }
        emailServer { New-Variable -Name emailServer -Visibility Public -Value $configprop.Value -Force -Passthru -Option AllScope -Scope Global; }
        emailPort { New-Variable -Name emailPort -Visibility Public -Value $configprop.Value -Force -Passthru -Option AllScope -Scope Global; }
        databaseUser { New-Variable -Name databaseUser -Visibility Public -Value $configprop.Value -Force -Passthru -Option AllScope -Scope Global; }
        databaseServer { New-Variable -Name databaseServer -Visibility Public -Value $configprop.Value -Force -Passthru -Option AllScope -Scope Global; }
        Default {}
      }
    }
  }
}
