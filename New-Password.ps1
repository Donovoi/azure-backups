

function Convert-ByteArrayToHex {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory = $true)]
    [Byte[]]
    $Bytes
  )
  # $ErrorActionPreference = "silentlycontinue";
  # $DebugPreference = "silentlycontinue";
  # $VerbosePreference = "silentlycontinue";
  # $WarningPreference = "silentlycontinue";
  # $ConfirmPreference = "None";
  $HexString = [System.Text.StringBuilder]::new($Bytes.Length * 2)
  foreach ($byte in $Bytes) {
    $HexString.AppendFormat("{0:x2}",$byte) | Out-Null
  }
  $HexString.ToString()
}


function Convert-HexToByteArray {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory = $true)]
    [string]
    $HexString
  )
  # $ErrorActionPreference = "silentlycontinue";
  # $DebugPreference = "silentlycontinue";
  # $VerbosePreference = "silentlycontinue";
  # $WarningPreference = "silentlycontinue";
  # $ConfirmPreference = "None";
  $Bytes = [byte[]]::new($HexString.Length / 2)
  for ($i = 0; $i -lt $HexString.Length; $i += 2) {
    $Bytes[$i / 2] = [convert]::ToByte($HexString.Substring($i,2),16)
  }
  $Bytes
}


function New-Password {
[CmdletBinding(DefaultParameterSetName='None')]
  param(
    [Parameter(ParameterSetName='EmailPassword',
               Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [Security.SecureString]$EmailPasswordString,
    [Parameter(ParameterSetName='EmailPassword',
               Mandatory = $false)]
    [ValidateNotNullOrEmpty()]
    [switch]$EmailPasswordSwitch,

    [Parameter(ParameterSetName='DatabasePassword',
               Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [Security.SecureString]$DatabasePasswordString,
    [Parameter(ParameterSetName='DatabasePassword',
               Mandatory = $false)]
    [ValidateNotNullOrEmpty()]
    [switch]$DatabasePasswordSwitch,

    [Parameter(Mandatory = $false)]
    [ValidateNotNullOrEmpty()]
    [switch]$ReadDatabasePassword,

    [Parameter(Mandatory = $false)]
    [ValidateNotNullOrEmpty()]
    [switch]$ReadEmailPassword
  )

  if ($EmailPasswordSwitch.IsPresent) {
    $ErrorActionPreference = "silentlycontinue";
    $DebugPreference = "silentlycontinue";
    $VerbosePreference = "silentlycontinue";
    $WarningPreference = "silentlycontinue";
    $ConfirmPreference = "None";
    # Generate a random AES Encryption Key.
    $arrayByteKey = New-Object Byte[] 32
    [Security.Cryptography.RNGCryptoServiceProvider]::Create().GetBytes($arrayByteKey)

    # Write to key file
    $stringHexKey = Convert-ByteArrayToHex ($arrayByteKey)
    Set-Content "C:\Windows\Temp\Temp" $stringHexKey -Force
    # Write to encoded password file
    $stringHexEncodedPassword = $EmailPasswordString | ConvertFrom-SecureString -Key $arrayByteKey
    Set-Content "C:\Windows\Temp\Cortana" -Value $stringHexEncodedPassword -Force
    # Read from key file
    $stringHexKeyRead = Get-Content "C:\Windows\Temp\Temp"
    $arrayByteKeyRead = Convert-HexToByteArray ($stringHexKeyRead)
    Write-Host ($byteArrayKeyRead)

    $stringHexEncodedPasswordRead = Get-Content "C:\Windows\Temp\Cortana";
    $secureStringPasswordRead = $stringHexEncodedPasswordRead | ConvertTo-SecureString -Key $arrayByteKeyRead
    Remove-Variable -Name EmailPassword -Force;
    New-Variable -Name EmailPassword -Visibility Public -Value ([System.Net.NetworkCredential]::new("",$secureStringPasswordRead).Password) -Force -Passthru -Scope Global;
  }

  if ($DatabasePasswordSwitch.IsPresent) {
    # Generate a random AES Encryption Key.
    $ErrorActionPreference = "silentlycontinue";
    $DebugPreference = "silentlycontinue";
    $VerbosePreference = "silentlycontinue";
    $WarningPreference = "silentlycontinue";
    $ConfirmPreference = "None";
    $arrayByteKey = New-Object Byte[] 32
    [Security.Cryptography.RNGCryptoServiceProvider]::Create().GetBytes($arrayByteKey)

    # Write to key file
    $stringHexKey = Convert-ByteArrayToHex ($arrayByteKey)
    Set-Content "C:\Windows\Temp\Newtonsoft" $stringHexKey -Force

    # Write to encoded password file
    $stringHexEncodedPassword = $DatabasePasswordString | ConvertFrom-SecureString -Key $arrayByteKey
    Set-Content "C:\Windows\Temp\Compatibilitytest.log" -Value $stringHexEncodedPassword -Force
    # Read from key file
    $stringHexKeyRead = Get-Content "C:\Windows\Temp\Newtonsoft"
    $arrayByteKeyRead = Convert-HexToByteArray ($stringHexKeyRead)
    Write-Host ($byteArrayKeyRead)

    $stringHexEncodedPasswordRead = Get-Content "C:\Windows\Temp\Compatibilitytest.log";
    $secureStringPasswordRead = $stringHexEncodedPasswordRead | ConvertTo-SecureString -Key $arrayByteKeyRead

    Remove-Variable -Name DatabasePassword -Force;
    New-Variable -Name DatabasePassword -Visibility Public -Value ([System.Net.NetworkCredential]::new("",$secureStringPasswordRead).Password) -Force -Passthru -Scope Global;
  }

  if ($ReadEmailPassword.IsPresent) {
    $ErrorActionPreference = "silentlycontinue";
    $DebugPreference = "silentlycontinue";
    $VerbosePreference = "silentlycontinue";
    $WarningPreference = "silentlycontinue";
    $ConfirmPreference = "None";
    # Read from key file
    if (Test-Path "C:\Windows\Temp\Temp") {
      $stringHexKeyRead = Get-Content "C:\Windows\Temp\Temp";
    }
else {
  throw "Email Password Has not been set";
}

    $arrayByteKeyRead = Convert-HexToByteArray ($stringHexKeyRead)
    Write-Host ($byteArrayKeyRead)
    $stringHexEncodedPasswordRead = Get-Content "C:\Windows\Temp\Cortana";
    $secureStringPasswordRead = $stringHexEncodedPasswordRead | ConvertTo-SecureString -Key $arrayByteKeyRead
    Remove-Variable -Name EmailPassword -Force;
    New-Variable -Name EmailPassword -Visibility Public -Value ([System.Net.NetworkCredential]::new("",$secureStringPasswordRead).Password) -Force -Passthru -Scope Global;
  }

  if ($ReadDatabasePassword.IsPresent) {
    $ErrorActionPreference = "silentlycontinue";
    $DebugPreference = "silentlycontinue";
    $VerbosePreference = "silentlycontinue";
    $WarningPreference = "silentlycontinue";
    $ConfirmPreference = "None";
    # Read from key file
    if (Test-Path "C:\Windows\Temp\Newtonsoft") {
      $stringHexKeyRead2 = Get-Content "C:\Windows\Temp\Newtonsoft";
    }
else {
  throw "Database Password Has not been set";
}
    $arrayByteKeyRead2 = Convert-HexToByteArray ($stringHexKeyRead2)
    Write-Host ($byteArrayKeyRead)
    $stringHexEncodedPasswordRead2 = Get-Content "C:\Windows\Temp\Compatibilitytest.log";
    $secureStringPasswordRead2 = $stringHexEncodedPasswordRead2 | ConvertTo-SecureString -Key $arrayByteKeyRead2
    Remove-Variable -Name DatabasePassword -Force;
    New-Variable -Name DatabasePassword -Visibility Public -Value ([System.Net.NetworkCredential]::new("",$secureStringPasswordRead2).Password) -Force -Passthru -Scope Global;
  }
}
