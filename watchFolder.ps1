### SET FOLDER TO WATCH + FILES TO WATCH + SUBFOLDERS YES/NO
    $watcher = New-Object System.IO.FileSystemWatcher
    $watcher.Path = "C:\Gatekeeper\images"
    $watcher.Filter = "*.jpg*"
    $watcher.IncludeSubdirectories = $true
    $watcher.EnableRaisingEvents = $true  

    $action = { $path = $Event.SourceEventArgs.FullPath
### DEFINE ACTIONS AFTER AN EVENT IS DETECTED
                $changeType = $Event.SourceEventArgs.ChangeType
				
                $logline = "$(Get-Date), $changeType, $path"
                Add-content "C:\Gatekeeper\log.txt" -value $logline
#				If ($($(Get-Date) - $Event.SourceEventArgs.CreationTime).Minutes -gt 2) {"$($(Get-Date) - $(gci filename).CreationTime).Minutes"}
				"$($(Get-Date) - $(gci $path).CreationTime).Minutes"
				
              }    
### DECIDE WHICH EVENTS SHOULD BE WATCHED 
    Register-ObjectEvent $watcher "Created" -Action $action
    Register-ObjectEvent $watcher "Changed" -Action $action
    Register-ObjectEvent $watcher "Deleted" -Action $action
    Register-ObjectEvent $watcher "Renamed" -Action $action
    while ($true) {sleep 5}
	

	
	Get-ChildItem "C:\Gatekeeper\images" -Filter *.jpg -Recurse | 
Foreach-Object {
    $contentName = Get-Content $_.FullName
	$contentCreateTime = Get-Content $_.CreationTime
	$contentAgeInMinutes = $($(Get-Date) - $contentCreateTime).Minutes
	"Image $contentName is $contentAgeInMinutes minutes old."
#	If ($contentAgeInMinutes -gt 2) {}
}
while ($true) {sleep 5}