#  Azure MySQL Backups #

*This Article Contains the following:*

[Aim](#aim)  
[Solution](#solution)  
[Repository File/Folder Structure and Building Solution](#repository-filefolder-structure-and-building-solution)  

* [Folder Structure](#folder-structure)

* [Building](#building)  

[Testing](#testing)  

* [Prerequisites](#prerequisites)

* [Setting Up The Environment](#setting-up-the-environment)

* [Testing Methodology](#testing-methodology)

## Aim ##

___

The aim of this project is to provide a somewhat rudimentary backup solution for the hosted **Azure MySQL** **Databases**. This will achieve the following objectives:

1. Schedule backups of hosted databases, zip and store in an azure blob storage container.

2. Make the backups easy to retrieve for support staff, and the developers.

3. Be easy to expand upon, fix, and compile.

## Solution ##

___

The above objectives are realized through the following component:

### Get-HostedBackup2.exe ###

> MySQL Azure backups/out/Get-HostedBackup2.exe

This executable is the only component that needs to be on the server. It contains everything that is needed to backup data from the  Azure MySQL environment to the Azure Blob Storage.

**Get-HostedBackup2.exe** runs the following steps:

1. Check if the **config.json** exists in the current directory.

   * If the **config.json** does not exist, do the following:

      1. Create the **config.json** file with the default parameters stored in **Read-Config.ps1**

      2. Ask the user for a Database password

      3. Ask the user for an Email password (The account has to be able to send emails from Outlook).

         Change the email address in the **config.json**.  

         To change the password, you will need to delete four files:

         * `C:\Windows\Temp\Cortana`

         * `C:\Windows\Temp\Temp`

         * `C:\Windows\Temp\Newtonsoft`

         * `C:\Windows\Temp\Compatibilitytest.log`

         And then run the **Get-HostedBackup2.exe** again to be prompted for the new password.

      4. Create variables from the newly created **config.json**, including:

         * `$emailUserName`

         * `$emailServer`

         * `$emailPort`

         * `$databaseUser`

         * `$databaseServer`

2. Check if the server is using a PowerShell version less then 6.2, if so we will install the **Nuget** **Package Manager**.

3. Check if the **Azure PowerShell** module is installed, and install it if not.

4. Import the **Azure PowerShell** module so we can use it later.  

5. Check if MySQL has been added to path. If not then we will download it, add it to path, and install any missing **VC++ Redistributables**.

6. Check if the **Azcopy.exe** has been added to path, add it if it hasn't been added yet.

7. Create temporary directory to store backups. Using **New-TemporaryDirectory.ps1**.

   * This is a simple function that will create a temporary directory in the users **Temp** folder.

   * The temporary directory will have the name of a randomly generated **GUID**.

8. Next the script will get a list of databases, creating a new **PSCredential Object** using the password and username from the variables created when **Read-Config.ps1** was run.

9. Using the function **Invoke-MySQLQuery.ps1**, the script will get a list of all databases on the Azure server. **Invoke-MySQLQuery.ps1** does the following:

   1. Takes three parameters (This function can take many more, but for the purpose of the backup we will only use three), the **Name** of the server, the **PSCredential Object** created above, and the **Query** to run.

   2. **Invoke-MySQLQuery.ps1** will first check if MySQL drivers are installed. If not it will go and install them.

   3. Connect to the server, and run the query that had been provided previously.

   4. Return any results as rows so we can do further work on each row.

10. Create a new **Azure Storage Context** for use later.

11. With the list of databases retrieved in step 9, we will filter out the databases we do not need, such as:
    * **information_schema**

    * **sys**

    * **performance_schema**

    * **MySQL**

12. The script will then start a `foreach` loop on each database doing the following:

    1. Get the current date and time to use as a unqiue filename.

    2. Prepend the **Instance ID/Database Name** to the current date and time for each database backed up.

    3. Use **MySQLDump** to retrieve a copy of the database from the Azure server.

    4. Put the backup in the temporary backup location naming it as suggested above.

    5. Compress the MySQLDump into a Zip file. Making sure it keeps the same name as suggested above.

    6. Using the connection to Azure created earlier, the script will check if a storage container with the same name already exists, if not it will create one. Be aware that container names can only contain letters, numbers, and very few special symbols. So something like `backup_server` needs to be changed to `backupserver` or similar.

    7. Generate a new 24 hour SAS token for each container. This helps ensure that we are not giving the script, or anyone using it, permanent access to our **Azure Blob Storage**.

    8. Using **AzCopy.exe** send zipped backup to the container in a folder called `databasebackup`.

    9. If any errors occur catch the error, send an email to the configured email address, remove the temporary directory and stop the script.

    10. If Successful, still delete the temporary directory and stop the script when all databases have been uploaded.

## Repository File/Folder Structure and Building  Solution ##

___

### Folder Structure ###

All files/Folders are located in a Folder Called **MySQL Azure backups** and are detailed below:

* Out (folder) - This folder is the Output for the build process outlined below, it contains the following file:

  * **Get-HostedBackup2.exe** - The executable used to backup data (all other files in this folder can be deleted as they are automatically created when the build process is run).

* **Get-HostedBackup2.ps1** - One of the main PowerShell scripts that contain the code. Any code changes made to this file, means a build process will need to be done.

* **Invoke-MysqlQuery.ps1** - One of the main PowerShell scripts that contain the code. Any code changes made to this file, means a build process will need to be done.

* **New-Password.ps1** - One of the main PowerShell scripts that contain the code. Any code changes made to this file, means a build process will need to be done.

* **New-TemporaryDirectory.ps1** - One of the main PowerShell scripts that contain the code. Any code changes made to this file, means a build process will need to be done.

* **Read-Config.ps1** - One of the main PowerShell scripts that contain the code. Any code changes made to this file, means a build process will need to be done.

* **Send-Email.ps1** - One of the main PowerShell scripts that contain the code. Any code changes made to this file, means a build process will need to be done.

* **Update-VcRedist.ps1** - One of the main PowerShell scripts that contain the code. Any code changes made to this file, means a build process will need to be done.

* **Write-Log.ps1** - One of the main PowerShell scripts that contain the code. Any code changes made to this file, means a build process will need to be done.

* **package.psd1** - PowerShell Module Manifest for building **Get-HostedBackup2.exe**. Is important and needs to be kept in the repo.

* **README.md** - This Readme file.

### Building ###

If any code changes are made to any **ps1** file in the **MySQL Azure backups** folder, a new build will need to be run to produce a new version of **Get-HostedBackup2.exe**. Follow the steps below to do a build:

1. Install the PowerShellProTools Module by running the following command:
 ```Install-Module PowerShellProTools -Force; Import-Module PowerShellProTools;```

2. Navigate to the directory where **package.psd1** is being held.

4. Run the command:
   ```Merge-Package -Config package.psd1 -Verbose```

## Testing ##

___

To help with testing, and fixing any issues, below are the steps you will need to take to setup your testing environment to emulate a production environment.

### Prerequisites ###

Luckily there is not much to setup in regards to prerequisites as there is really only one executable to run. But you will need to ensure you have the following:

1. PowerShell 5.1. (does not work on anything newer or older)
2. [**Azure Storage Explorer**](https://azure.microsoft.com/en-us/features/storage-explorer/)
3. All files from this repository as mentioned above

### Setting up the Environment ###

 **Get-HostedBackup2.ps1** already comes with a built-in testing switch `$IsTest`.

 To activate this go to the bottom of **Get-HostedBackup2.ps1**, there you will need to replace the `Get-HostedBackup` command with the following:  
`Get-HostedBackup -IsTest -Verbose`

### Testing Methodology ###

Once the **Get-HostedBackup2.ps1** has been updated and saved ready for testing, the next this to do is to run the **Azure Storage Explore**, and make sure you have it open. It is also helpful to have the log ( via `C:\Logs\MYSQL2BLOB.log` ) open, in case of any errors.

Then, simply press `F5` to run the script or [compile](#building) it to an EXE and then run it.

There are few differences in **Get-HostedBackup2.ps1** when it is run with the `$IsTest`.

The biggest difference is that **Get-HostedBackup2.ps1** will simply download the **Azure Storage Emulator**, install it, initialize it, and start it.

Then instead of uploading the databases to the Azure Blob Storage, we will upload them locally to the **Azure Storage Emulator**.
