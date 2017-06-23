########## Global Settings ########################

$computer = gc env:computername
$ipV4 = Test-Connection -ComputerName (hostname) -Count 1  | Select -ExpandProperty IPV4Address
$applicationName = "Gatekeeper"
$processName = "cmd.exe"
$siteCode = "LLCR"
$siteName = "Legoland, CA"
$applicationFolder = "D:\Gatekeeper\"
$dropboxFolder = "C:\Users\synertia\Dropbox\"
$dropboxLink = "Https://www.dropbox.com/sh/smtgcwo66g1lyyt/AABBUlEHvtY3DaQ4gCDWbo66a?dl=0"
$applicationExecutable = "gatekeeper.bat"
$maxFileAge = 5

########### Email and text Alert recipiants - comma separated #############

$notificationEmailRecipiants = "jonathan.lewis@magicmemories.com"
$notificationTextRecipiants = "4157947109@txt.att.net"

########## End of Global settings ##################


### Location where images are searched
$imagesSourceFolder = "$($applicationFolder + "ftp\")"

### Folder where we can search for all images incoming that are not getting processed
$imagesDestinationFolder = "$applicationFolder$("tmp\")"


Function checkIfResponsive {
  if((get-process "cmd.exe").Responding){
    'App running'
  }else{
    'App hung, restarting application'
	backupAndRestore
  }
}

Function getCameraFolderName {
  $pattern = 'capture.1.address = '  
  $content = Get-Content $($applicationFolder + "\conf\gatekeeper.conf") | Out-String
  $startIndex = $content.indexof($pattern)
  
  ### Split off the head
  $content = $content.Remove(0,($startIndex))
  $endIndex = $content.indexof("`r")
  return $content.Substring(20,($endIndex - 20))
}



Function getTimestamp {
  return Get-Date -UFormat "%Y-%m-%d-T%H%M_UTC%Z"
}

Function createBackup {
  $backupFolder = "$dropboxFolder$applicationName-Incidents\$applicationName-incident-$(getTimestamp)"
  Copy-Item $applicationFolder $backupFolder -recurse
  "Backup of $applicationFolder has been created at $backupFolder"
}

Function moveImageFiles {
  GCI $imagesSourceFolder -Include "*.jpg" -Recurse |
  % {
    Move-Item -Path $_.FullName -Destination $gatekeeperCameraFolder -Force -ErrorAction:SilentlyContinue
    }
  "Image files moved for reprocessing from $imagesSourceFolder to $gatekeeperCameraFolder."
}

Function backupAndRestore {
  TASKKILL /IM $processName
  createBackup
  moveImageFiles
  start-process $applicationFolder$applicationExecutable
}

Function checkFileAgesInFolder {
  
  "Checking... $Args"
  $list = Get-ChildItem $Args[0] -Filter *.jpg -Recurse
  if ($list -ne $Null) {
	  foreach($file in $list) {
		$contentName = Get-Item $file.FullName
		$contentCreateTime = $file.CreationTime
		$contentAgeInMinutes = $($(Get-Date) - $contentCreateTime).Minutes
	#	"Image $contentName is $contentAgeInMinutes minutes old."
		if ($contentAgeInMinutes -gt ($maxFileAge * 2)) {
		"$contentName was $contentAgeInMinutes minutes old and had to be deleted..."
		Remove-Item $contentName
		continue
		} elseIf ($contentAgeInMinutes -gt $maxFileAge -or $contentAgeInMinutes -eq $maxFileAge) {
		"On $ipV4 Hostname: $computer. It took $contentAgeInMinutes minutes to send $contentName.  Restarting $applicationName."
		backupAndRestore
		sendEmailAlert
		sendTextAlert
		break
		}
	 }
  }
}

Function sendEmailAlert {
  ##############  Email Settings ########## 
  
  $From = "mmtech.notifications@gmail.com"
  
  $To = $notificationEmailRecipiants
  
  $Cc = "jonnydphoto@gmail.com"
  
  $Subject = "$siteCode Incident on $ipV4 - $computer with $applicationName"
  
  $Body = "There was an incident at $siteName with $applicationName on $ipV4 - $computer at $(getTimestamp)."
  $Body += "<br>The current state of $applicationName has been copied to <a href=$dropboxLink>Dropbox</a> for debugging." 
  $Body += "<br>This is an automatically generated message."
  
  $CredUser = "mmtech.notifications@gmail.com"
  $CredPassword = "N0t1fyM3"
  $emailMessage = New-Object System.Net.Mail.MailMessage
  $emailMessage.From = $From
  $emailMessage.To.Add( $To )
  $emailMessage.Subject = $Subject
  $emailMessage.IsBodyHtml = $true
  $emailMessage.body = $Body

  $SMTPServer = "SMTP.gmail.com" 
  $SMTPClient = New-Object Net.Mail.SmtpClient($SmtpServer, 587) 
  $SMTPClient.EnableSsl = $true 
  $SMTPClient.Credentials = New-Object System.Net.NetworkCredential($CredUser, $CredPassword)
  $SMTPClient.Send($emailMessage)
  
  ########## End Email Settings ###############
}

Function sendTextAlert {
    ##############  Text Settings ########## 
  
  $From = "mmtech.notifications@gmail.com"
  
  $To = $notificationTextRecipiants
  
  $Cc = "jonnydphoto@gmail.com"
  
  $Subject = "$siteCode Incident $ipV4 - $applicationName"
  
  $Body = "$siteName - $applicationName on $ipV4."
  $Body += " Current state of $applicationName copied to $dropboxLink for debugging"
  
  $CredUser = "mmtech.notifications@gmail.com"
  $CredPassword = "N0t1fyM3"
  $emailMessage = New-Object System.Net.Mail.MailMessage
  $emailMessage.From = $From
  $emailMessage.To.Add( $To )
  $emailMessage.Subject = $Subject
  $emailMessage.body = $Body

  $SMTPServer = "SMTP.gmail.com" 
  $SMTPClient = New-Object Net.Mail.SmtpClient($SmtpServer, 587) 
  $SMTPClient.EnableSsl = $true 
  $SMTPClient.Credentials = New-Object System.Net.NetworkCredential($CredUser, $CredPassword)
  $SMTPClient.Send($emailMessage)
  
  ########## End Email Settings ###############
  
  #Send-MailMessage -From $From -to $To -Cc $Cc -Subject $Subject -Body $Body -SmtpServer $SMTPServer -UseSsl -BodyAsHtml -Credential $mycreds

}

### Name of a camera device folder in tmp
$gatekeeperCameraFolder = "$imagesDestinationFolder$(getCameraFolderName)"




"Application monitoring started.  Watching $imagesSourceFolder and $imagesDestinationFolder and their subfolders..."
"Any images older than $maxFileAge will trigger an application backup and restart."
"Pending images willl be sent to $gatekeeperCameraFolder for reprocessing."

####################
### Program loop ###

while ($true) {
  checkFileAgesInFolder $gatekeeperCameraFolder
  checkFileAgesInFolder $imagesSourceFolder
  SLEEP ($maxFileAge * 60)
	}

####################




