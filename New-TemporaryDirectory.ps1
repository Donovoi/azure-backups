function New-TemporaryDirectory {
  $ErrorActionPreference = "silentlycontinue";
  $DebugPreference = "silentlycontinue";
  $VerbosePreference = "silentlycontinue";
  $WarningPreference = "silentlycontinue";
  $ConfirmPreference = "None";
  $parent = [System.IO.Path]::GetTempPath()
  [string]$name = [System.Guid]::NewGuid()
  New-Item -ItemType Directory -Path (Join-Path $parent $name)
}
