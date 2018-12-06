#
#
#  SCOM Management Pack Creator v2.0
#  By Dujon Walsham
# 
#  Version 1.0 Release Notes
#  - Creates XML for each individual part of the Management Pack
#  - Creates Classes
#  - Creates Monitors (Two State Event Monitor Currently)
#  - Creates Rules (Two State Event Rule Currently)
#  - Creates Discoveries (PowerShell, VBScript, WMI & Registry)
#  - Creates Views (State View, Performance, Override and Event View)
#  - Creates Folders
#  
#  Version 2.0 Release Notes
#
#  - Dynamically detects all classes for easier selection for the MP creation
#  - Create all Views
#  - Create Relationships & Computer Rollups
#  - Create additional monitors & rules
#  - Add Alert Supression parameters
#  - Add custom probes i.e. Monitor Based on Scripts via PowerShell with overridable parameters
###################################################################################################################################################

  # Create New Class
 Function New-SCOMMPClass
 {
 
 # Builds the XML structure for the Class
 Add-Content $MPClassFile "<ManagementPackFragment SchemaVersion=""2.0"" xmlns:xsd=""http://www.w3.org/2001/XMLSchema"">`n <TypeDefinitions>`n  <EntityTypes>`n   <ClassTypes>`n   </ClassTypes>`n</EntityTypes>`n<SecureReferences>`n</SecureReferences>`n </TypeDefinitions>`n <LanguagePacks>`n  <LanguagePack ID=""ENU"" IsDefault=""true"">`n   <DisplayStrings>`n    </DisplayStrings>`n  </LanguagePack>`n </LanguagePacks>`n</ManagementPackFragment> "
 }


Function Add-SCOMMPClass
 {
  Param (
  [String]$ClassName = $(Read-Host -Prompt "Name of Class"),
  [String]$ClassType = $(Write-Host "Type of Class";Write-Host ""; Write-host "1. Windows Computer"
  Write-Host "2. Windows Application Component";Write-Host "3. Windows Local Application"; Write-Host "4. Unix Computer"; Write-Host "5. Computer Group"; Write-Host "6. Instance Group"; Write-Host "7. Computer Health Rollup";Read-Host -Prompt "Select Option"),
  [String]$ClassDescription = $(Write-Host ""; Read-Host   -Prompt "Description of Class"),
  [String]$Abstract = $(Write-Host ""; Read-Host -Prompt "Is this an abstract class which will be used a base class. true or false (Must be lowercase) Default is false"),
  [String]$Hosted = $(Read-Host -Prompt "Is this class hosted by another class. true or false (Must be lowercase) Default is true"),
  [String]$Singleton = $(Read-Host -Prompt "Is this a singleton class where only one instance will exist. true or false (Must be lowercase) Default is false"),
  [String]$MPClassFile = $(Read-Host -Prompt "Where to save class file")
  )

  # Default Values

   If ($Abstract -eq "")
   {$Abstract = "false"}

   If ($Hosted -eq "")
   {$Hosted = "true"}

   If ($Singleton -eq "")
   {$Singleton = "false"}

  # Sets ClassType
  If ($ClassType -eq "1") {$ClassType = "Windows!Microsoft.Windows.ComputerRole"}
  If ($ClassType -eq "2") {$ClassType = "Windows!Microsoft.Windows.ApplicationComponent"}
  If ($ClassType -eq "3") {$ClassType = "Windows!Microsoft.Windows.LocalApplication"}
  If ($ClassType -eq "4") {$ClassType = "Unix!Microsoft.Unix.ComputerRole"}
  If ($ClassType -eq "5") {$ClassType = "SC!Microsoft.SystemCenter.ComputerGroup"}
  If ($ClassType -eq "6") {$ClassType = "MSIL!Microsoft.SystemCenter.InstanceGroup"}
  If ($ClassType -eq "7") {$ClassType = "System!System.ComputerRole"}

  # Formats the Class Name to the relevant format for the XML to handle the Class name
  $ClassID = $ClassName -replace " ", "."
  $ClassContent = Get-Content $MPClassFile

  # Writes the Class Type information in the class file
  $FindLastClassTypeLine = Select-String $MPClassFile -pattern "</ClassTypes>" | ForEach-Object {$_.LineNumber -2}
  $ClassContent[$FindLastClassTypeLine] += "`n    <ClassType ID=""$classID"" Base=""$ClassType"" Accessibility=""Internal"" Abstract=""$Abstract"" Hosted=""$Hosted"" Singleton=""$Singleton"">`n   </ClassType>"
  $ClassContent | Set-Content $MPClassFile

  # Reloads the Class XML file with the new changes
  $ClassContent = Get-Content $MPClassFile
  
  # Writes the DisplayStrings to the XML so SCOM can read the display names correctly
  $FindLastDisplayStringLine = Select-String $MPClassFile -pattern "</DisplayStrings>" | ForEach-Object {$_.LineNumber -2}
  $ClassContent[$FindLastDisplayStringLine] += "`n    <DisplayString ElementID=""$ClassID"">`n     <Name>$ClassName</Name>`n     <Description>$ClassDescription</Description>`n    </DisplayString>"
  $ClassContent | Set-Content $MPClassFile
  } 

Function Add-SCOMMPClassProperty
  {
   Param (
  [String]$PropertyName = $(Read-Host -Prompt "Name of Property"),
  [String]$PropertyType = $(Write-Host "Type of Property"; Write-Host ""; Write-Host "1. int"; Write-Host "2. decimal"; Write-Host "3. double"; Write-Host "4. string"; Write-Host "5. datetime"; Write-Host "6. guid"; Write-Host "7. bool"; Write-Host "8. enum"; Write-Host "9. richtext"; Write-Host "10. binary"; Read-Host -Prompt "Select Option"),
  [String]$KeyValue = $(Write-Host ""; Read-Host "Is this a key value - true or false"),
  [String]$PropertyDescription = $(Write-Host "";Read-Host -Prompt "Description of Property"),
  [String]$AffectedClassID = $(Write-Host ""; $ClassesDetection = ((Get-Content $MPClassFile) -match "<DisplayString ElementID" -notmatch "SubElementID") -replace "<DisplayString ElementID=""", "" -replace """", "" -replace ">", ""
  ;Write-Host "Class which the property will be added to"; For($i=0;$i -le $ClassesDetection.Count -1; $i++) {Write-Host $i. $ClassesDetection[$i].trim()}; Read-Host -Prompt "Select Option"),
  [String]$MPClassFile = $(Read-Host -Prompt "Class file location")
  )

  # Sets Property Type
  If ($PropertyType -eq "1") {$PropertyType = "int"}
  If ($PropertyType -eq "2") {$PropertyType = "decimal"}
  If ($PropertyType -eq "3") {$PropertyType = "double"}
  If ($PropertyType -eq "4") {$PropertyType = "string"}
  If ($PropertyType -eq "5") {$PropertyType = "datetime"}
  If ($PropertyType -eq "6") {$PropertyType = "guid"}
  If ($PropertyType -eq "7") {$PropertyType = "bool"}
  If ($PropertyType -eq "8") {$PropertyType = "enum"}
  If ($PropertyType -eq "9") {$PropertyType = "richtext"}
  If ($PropertyType -eq "10") {$PropertyType = "binary"}

  # Sets Parent Class
  For($i=0;$i -le $ClassesDetection.Count -1; $i++) {
   If ($AffectedClassID -eq $i) {$AffectedClassID = $ClassesDetection[$i].trim()}}

  # Formats the Property Name to the relevant format for the XML to handle the Property name
  $AffectedClassID = $AffectedClassID -replace " ", "."
  $PropertyID = $PropertyName -replace " ", "."
  $ClassContent = Get-Content $MPClassFile

  # Writes the DisplayStrings to the XML so SCOM can read the display names correctly
  $FindLastDisplayStringLine = Select-String $MPClassFile -pattern "</DisplayStrings>" | ForEach-Object {$_.LineNumber -2}
  $ClassContent[$FindLastDisplayStringLine] += "`n    <DisplayString ElementID=""$AffectedClassID"" SubElementID=""$PropertyID"">`n     <Name>$PropertyName</Name>`n     <Description>$PropertyDescription</Description>`n    </DisplayString>"
  $ClassContent | Set-Content $MPClassFile

  # Adds the Property to the Class within the XML file
  (Get-Content $MPClassFile) | 
     Foreach-Object {
         $_ 
         if ($_ -match "<Classtype ID=""$AffectedClassID""") 
         {
             
             "     <Property ID=""$PropertyID"" Key=""$KeyValue"" Type=""$PropertyType""/>"
         }
     } | Set-Content $MPClassFile
     
  }

  Function Add-SCOMMPRunAsAccount
 {
  Param (
  [String]$SecureReferenceName = $(Read-Host -Prompt "Name of Run As Account"),
  [String]$SecureReferenceDescription = $(Read-Host -Prompt "Description of Run As Account"),
  [String]$MPClassFile = $(Read-Host -Prompt "Class file location")
  )

  # Formats the Secure Reference Name to the relevant format for the XML to handle the Secure Reference name
  $SecureReferenceID = $SecureReferenceName -replace " ", "."
  $ClassContent = Get-Content $MPClassFile

  # Adds the Secure Reference (Run As Account) to the management pack
  $FindLastSecureReferenceLine = Select-String $MPClassFile -pattern "</SecureReferences>" | ForEach-Object {$_.LineNumber -2}
  $ClassContent[$FindLastSecureReferenceLine] += "`n  <SecureReference ID=""$SecureReferenceID"" Accessibility=""Internal"" Context=""System!System.Entity"" />"
  $ClassContent | Set-Content $MPClassFile

  # Reloads the Class XML file with the new changes
  $ClassContent = Get-Content $MPClassFile

  # Writes the DisplayStrings to the XML so SCOM can read the display names correctly
  $FindLastDisplayStringLine = Select-String $MPClassFile -pattern "</DisplayStrings>" | ForEach-Object {$_.LineNumber -2}
  $ClassContent[$FindLastDisplayStringLine] += "`n    <DisplayString ElementID=""$SecureReferenceID"">`n     <Name>$SecureReferenceName</Name>`n     <Description>$SecureReferenceDescription</Description>`n    </DisplayString>"
  $ClassContent | Set-Content $MPClassFile

}

#Edit Class File

Function Edit-SCOMMPClass
 {
 While($True) {
 [int]$xMenuChoiceA = 0
 while ( $xMenuChoiceA -lt 1 -or $xMenuChoiceA -gt 4 ){
 Write-host "1. Create New Class"
 Write-host "2. Create New Property"
 Write-Host "3. Create Run As Account"
 Write-Host "4. Exit"

[Int]$xMenuChoiceA = read-host "Please enter an option 1 to 4..." }
 Switch( $xMenuChoiceA ){
   1{Write-Host ""; Add-SCOMMPClass -MPClassFile $MPClassFile; Write-Host ""}
   2{Write-Host ""; Add-SCOMMPClassProperty -MPClassFile $MPClassFile; Write-Host ""}
   3{Write-Host ""; Add-SCOMMPRunAsAccount -MPClassFile $MPClassFile; Write-Host ""}
   4{Return}
   }
 }
 } 

 Function New-SCOMMPRelationShip
 {
 # Builds the XML structure for the Class
 Add-Content $MPRelationshipFile "<ManagementPackFragment SchemaVersion=""2.0"" xmlns:xsd=""http://www.w3.org/2001/XMLSchema"">`n <TypeDefinitions>`n  <EntityTypes>`n      <RelationshipTypes>`n        </RelationshipTypes>`n    </EntityTypes>`n  </TypeDefinitions>`n  <LanguagePacks>`n    <LanguagePack ID=""ENU"" IsDefault=""true"">`n      <DisplayStrings>`n      </DisplayStrings>`n    </LanguagePack>`n  </LanguagePacks>`n</ManagementPackFragment>"
 }

 Function Add-SCOMMPRelationship
 {
 PARAM(
  [String]$RelationshipName = $(Read-Host -Prompt "Name of Relationship ID"),
  [String]$RelationshipDescription = $(Read-Host -Prompt "Description of Relationship"),
  [String]$Abstract = $(Read-Host -Prompt "Is this an abstract class which will be used a base class. true or false (Must be lowercase) Default is false"),
  [String]$Accessibility = $(Read-Host -Prompt "Will the accessibility be Internal or Public"),
  [String]$SourceType = $(Write-Host ""; $ClassesDetection = ((Get-Content $MPClassFile) -match "<DisplayString ElementID" -notmatch "SubElementID") -replace "<DisplayString ElementID=""", "" -replace """", "" -replace ">", ""
  ;Write-Host "Enter the source class ID"; For($i=0;$i -le $ClassesDetection.Count -1; $i++) {Write-Host $i. $ClassesDetection[$i].trim()}; Read-Host -Prompt "Select Option"),
  [String]$TargetType = $(Write-Host ""; $ClassesDetection = ((Get-Content $MPClassFile) -match "<DisplayString ElementID" -notmatch "SubElementID") -replace "<DisplayString ElementID=""", "" -replace """", "" -replace ">", ""
  ;Write-Host "Enter the target ID"; For($i=0;$i -le $ClassesDetection.Count -1; $i++) {Write-Host $i. $ClassesDetection[$i].trim()}; Read-Host -Prompt "Select Option"),
  [String]$MPRelationshipFile = $(Read-Host -Prompt "Where to save class file")
  )

   # Default Values

   If ($Abstract -eq "")
   {$Abstract = "false"}

   If ($Accessibility -eq "")
   {$Accessibility = "Internal"}

  # Sets SourceID Class
  For($i=0;$i -le $ClassesDetection.Count -1; $i++) {
   If ($SourceType -eq $i) {$SourceType = $ClassesDetection[$i].trim()}}

     # Sets Target ID Class
  For($i=0;$i -le $ClassesDetection.Count -1; $i++) {
   If ($TargetType -eq $i) {$TargetType = $ClassesDetection[$i].trim()}}

  # Formats the Class Name to the relevant format for the XML to handle the Class name
  $RelationshipID = $RelationshipName -replace " ", "."
  $ClassContent = Get-Content $MPRelationshipFile

  # Writes the Class Type information in the class file
  $FindLastRelationshipTypeLine = Select-String $MPRelationshipFile -pattern "</RelationshipTypes>" | ForEach-Object {$_.LineNumber -2}
  $ClassContent[$FindLastRelationshipTypeLine] += "`n        <RelationshipType ID=""$RelationshipID"" Base=""System!System.Containment"" Abstract=""$Abstract"" Accessibility=""$Accessibility"">`n          <Source ID=""Source"" Type=""$SourceType""/>`n          <Target ID=""Target"" Type=""$TargetType""/>`n        </RelationshipType>"
  $ClassContent | Set-Content $MPRelationshipFile

  # Reloads the Class XML file with the new changes
  $ClassContent = Get-Content $MPRelationshipFile

  # Writes the DisplayStrings to the XML so SCOM can read the display names correctly
  $FindLastDisplayStringLine = Select-String $MPRelationshipFile -pattern "</DisplayStrings>" | ForEach-Object {$_.LineNumber -2}
  $ClassContent[$FindLastDisplayStringLine] += "`n    <DisplayString ElementID=""$RelationshipID"">`n     <Name>$RelationshipName</Name>`n     <Description>$RelationshipDescription</Description>`n    </DisplayString>"
  $ClassContent | Set-Content $MPRelationshipFile
 }


 Function New-SCOMMPDiscovery
  {
  Param (
  [String]$DiscoveryTarget = $(Read-Host -Prompt "Class ID which discovery is targeted to"),
  [String]$MPDiscoveryFile = $(Read-Host -Prompt "Where will the discovery file be saved")
  )

  # Wrties variable values which are specific to Visual Studios
  $IncludeFileContent = "$" + "IncludeFileContent"
  $MPElement = "$" + "MPElement"
  $Target =  "$" + "Target"

  # Writes the XML structure of the Discovery
  Add-Content $MPDiscoveryFile "<ManagementPackFragment SchemaVersion=""2.0"" xmlns:xsd=""http://www.w3.org/2001/XMLSchema"">`n  <Monitoring>`n   <Discoveries>`n     <Category>Discovery</Category>`n        <DiscoveryTypes>`n        </DiscoveryTypes>`n        </DataSource>`n      </Discovery>`n    </Discoveries>`n  </Monitoring>`n  <LanguagePacks>`n    <LanguagePack ID=""ENU"" IsDefault=""true"">`n      <DisplayStrings>`n      </DisplayStrings>`n    </LanguagePack>`n  </LanguagePacks>`n</ManagementPackFragment>"
  }

  Function Add-SCOMMPPowerShellDiscovery
  {
  Param (
  [String]$DiscoveryName = $(Read-Host -Prompt "Name of Discovery"),
  [String]$DiscoveryTarget = $(Read-Host -Prompt "Discovery Target - i.e. Enter ClassID if using nested custom class or base such as Windows!Microsoft.Windows.Computer"),
  [String]$DiscoveryDescription = $(Read-Host -Prompt "Description of discovery"),
  [String]$DiscoveryClass = $(Write-Host ""; $ClassesDetection = ((Get-Content $MPClassFile) -match "<DisplayString ElementID" -notmatch "SubElementID") -replace "<DisplayString ElementID=""", "" -replace """", "" -replace ">", ""
  ;Write-Host "Class ID that that the discovery is targeted to"; For($i=0;$i -le $ClassesDetection.Count -1; $i++) {Write-Host $i. $ClassesDetection[$i].trim()}; Read-Host -Prompt "Select Option"),
  [String]$DiscoveryRunAsAccount = $(Write-Host ""; $RunAsAccountDetection = ((Get-Content $MPClassFile) -match "<DisplayString ElementID" -notmatch "SubElementID") -replace "<DisplayString ElementID=""", "" -replace """", "" -replace ">", ""
  ;Write-Host "Discovery Run As Account"; For($i=0;$i -le $RunAsAccountDetection.Count -1; $i++) {Write-Host $i. $RunAsAccountDetection[$i].trim()}; Read-Host -Prompt "Select Option"),
  [String]$IntervalSeconds = $(Read-Host -Prompt "Interval Seconds"),
  [Parameter(Mandatory=$false)][String]$SyncTime = $(Read-Host -Prompt "Sync Time. Leave blank if not needed"),
  [String]$ScriptName = $(Read-Host -Prompt "Script Name"),
  [String]$ScriptBody = $(Read-Host -Prompt "Script Body"),
  [String]$TimeoutSeconds = $(Read-Host -Prompt "Timeout Seconds"),
  [String]$MPClassFile = $(Read-Host -Prompt "Where the Class file is located"),
  [String]$MPDiscoveryFile = $(Read-Host -Prompt "Where will the discovery file be saved"),
  [String]$ClassID = (Read-Host -Prompt "ClassID used in previously created class")
 )

    # Sets Discovery Target
  For($i=0;$i -le $ClassesDetection.Count -1; $i++) {
   If ($DiscoveryTarget -eq $i) {$DiscoveryTarget = $ClassesDetection[$i].trim()}}

  # Sets Run As Account
  For($i=0;$i -le $RunAsAccountDetection.Count -1; $i++) {
   If ($DiscoveryRunAsAccount -eq $i) {$DiscoveryRunAsAccount = $RunAsAccountDetection[$i].trim()}}
  
  # Wrties variable values which are specific to Visual Studios
  $Target = "$" + "Target"
  $Data = "$" + "Data"
  $MPElement = "$" + "MPElement"
  $IncludeFileContent = "$" + "IncludeFileContent"
  #$ClassID = $ClassID -replace " ", "."

  # Formats the Secure Reference Name to the relevant format for the XML to handle the Secure Reference name
  $DiscoveryID = $DiscoveryName -replace " ", "."
  $ClassContent = Get-Content $MPDiscoveryFile

  # Writes the Discovery ID to the XML Management Pack
  $FindCategoryLine = Select-String $MPDiscoveryFile -pattern "<Category>" | ForEach-Object {$_.LineNumber -2}
  $ClassContent[$FindCategoryLine] += "`n      <Discovery ID=""$DiscoveryName"" Target=""$DiscoveryTarget"" Enabled=""true"" ConfirmDelivery=""false"" Remotable=""true"" Priority=""Normal"">"
  $ClassContent | Set-Content $MPDiscoveryFile

  # Reloads the Class XML file with the new changes
  $ClassContent = Get-Content $MPDiscoveryFile

  # Writes the DisplayStrings to the XML so SCOM can read the display names correctly
  $FindLastDisplayStringLine = Select-String $MPDiscoveryFile -pattern "</DisplayStrings>" | ForEach-Object {$_.LineNumber -2}
  $ClassContent[$FindLastDisplayStringLine] += "`n    <DisplayString ElementID=""$DiscoveryID"">`n     <Name>$DiscoveryName</Name>`n     <Description>$DiscoveryDescription</Description>`n    </DisplayString>"
  $ClassContent | Set-Content $MPDiscoveryFile

  # Reloads the Class XML file with the new changes
  $ClassContent = Get-Content $MPDiscoveryFile

  # Writes the Discovery Class
  $FindDiscoveryTypesLine = Select-String $MPDiscoveryFile -pattern "</DiscoveryTypes>" | ForEach-Object {$_.LineNumber -2}
  $ClassContent[$FindDiscoveryTypesLine] += "`n          <DiscoveryClass TypeID=""$DiscoveryClass"">`n          </DiscoveryClass>"
  $ClassContent | Set-Content $MPDiscoveryFile

   # Reloads the Class XML file with the new changes
  $ClassContent = Get-Content $MPDiscoveryFile

  # Retrieves the details for the Class created previously 
  $MPClassContent = Get-Content $MPClassFile

  # Finds all of the properties which were created from that particular class by searching the class.xml file
  $FindProperties = ((Get-Content $MPClassFile) -match "<DisplayString ElementID=""$ClassID"" SubElementID") -replace "<DisplayString ElementID=""$ClassID"" SubElementID", "<Property PropertyID" -replace ">", " />"

  # Adds all of the properties which were discovered in the Class previously created to the Discovery Class
  $FindDiscoveryClassLine = Select-String $MPDiscoveryFile -pattern "</DiscoveryClass" | ForEach-Object {$_.LineNumber -2}
  $ClassContent[$FindDiscoveryClassLine] += "`n          $FindProperties"
  $ClassContent | Set-Content $MPDiscoveryFile

  # Reloads the Class XML file with the new changes
  $ClassContent = Get-Content $MPDiscoveryFile
  
  # Edits the DataSource line to prepare for it being a PowerShell Discovery
  $FindDiscoveryTypesLine = Select-String $MPDiscoveryFile -pattern "</DiscoveryTypes" | ForEach-Object {$_.LineNumber -1}
  $ClassContent[$FindDiscoveryTypesLine] += "`n             <DataSource ID=""DS"" TypeID=""Windows!Microsoft.Windows.TimedPowerShell.DiscoveryProvider"" RunAs=""$DiscoveryRunAsAccount"">"
  $ClassContent | Set-Content $MPDiscoveryFile
  
  # Reloads the Class XML file with the new changes
  $ClassContent = Get-Content $MPDiscoveryFile

  # Adds the PowerShell Discovery Configuration to the XML
  $FindDataSourceLine = Select-String $MPDiscoveryFile -pattern "<DataSource" | ForEach-Object {$_.LineNumber -1}
  $ClassContent[$FindDataSourceLine] += "`n          <IntervalSeconds>$IntervalSeconds</IntervalSeconds>`n          <SyncTime>$SyncTime</SyncTime>`n          <ScriptName>$ScriptName</ScriptName>`n          <ScriptBody>$IncludeFileContent/$ScriptBody$</ScriptBody>"
  $ClassContent | Set-Content $MPDiscoveryFile
  

  # Reloads the Class XML file with the new changes
  $ClassContent = Get-Content $MPDiscoveryFile

  #Writes the PowerShell Script Parameters
  $FindScriptBodyLine = Select-String $MPDiscoveryFile -pattern "<ScriptBody>" | ForEach-Object {$_.LineNumber -1}
  $ClassContent[$FindScriptBodyLine] += "`n       <Parameters>`n            <Parameter>`n              <Name>sourceID</Name>`n              <Value>$MPElement$</Value>`n            </Parameter>`n            <Parameter>`n              <Name>managedEntityID</Name>`n              <Value>$Target/Id$</Value>`n            </Parameter>`n            <Parameter>`n              <Name>computerName</Name>`n              <Value>$Target/Host/Property[Type=""Windows!Microsoft.Windows.Computer""]/PrincipalName$</Value>`n            </Parameter>`n          </Parameters>`n          <TimeoutSeconds>$TimeoutSeconds</TimeoutSeconds>"
  $ClassContent | Set-Content $MPDiscoveryFile

  }

  Function Add-SCOMMPRegistryDiscovery
  {
  Param (
  [String]$DiscoveryName = $(Read-Host -Prompt "Name of Discovery"),
  [String]$DiscoveryTarget = $(Read-Host -Prompt "Discovery Target - i.e. Enter ClassID if using nested custom class or base such as Windows!Microsoft.Windows.Computer"),
  [String]$DiscoveryDescription = $(Read-Host -Prompt "Description of discovery"),
  [String]$DiscoveryClass = $(Write-Host ""; $ClassesDetection = ((Get-Content $MPClassFile) -match "<DisplayString ElementID" -notmatch "SubElementID") -replace "<DisplayString ElementID=""", "" -replace """", "" -replace ">", ""
  ;Write-Host "Class ID that that the discovery is targeted to"; For($i=0;$i -le $ClassesDetection.Count -1; $i++) {Write-Host $i. $ClassesDetection[$i].trim()}; Read-Host -Prompt "Select Option"),
  [String]$DiscoveryRunAsAccount = $(Write-Host ""; $RunAsAccountDetection = ((Get-Content $MPClassFile) -match "<DisplayString ElementID" -notmatch "SubElementID") -replace "<DisplayString ElementID=""", "" -replace """", "" -replace ">", ""
  ;Write-Host "Discovery Run As Account"; For($i=0;$i -le $RunAsAccountDetection.Count -1; $i++) {Write-Host $i. $RunAsAccountDetection[$i].trim()}; Read-Host -Prompt "Select Option"),
  [String]$Frequency = $(Read-Host -Prompt "Frequency (seconds)"),
  [String]$MPClassFile = $(Read-Host -Prompt "Where the Class file is located"),
  [String]$MPDiscoveryFile = $(Read-Host -Prompt "Where will the discovery file be saved"),
  [String]$ClassID = (Read-Host -Prompt "ClassID used in previously created class")
  )

    # Sets Discovery Target
  For($i=0;$i -le $ClassesDetection.Count -1; $i++) {
   If ($DiscoveryTarget -eq $i) {$DiscoveryTarget = $ClassesDetection[$i].trim()}}

  # Sets Run As Account
  For($i=0;$i -le $RunAsAccountDetection.Count -1; $i++) {
   If ($DiscoveryRunAsAccount -eq $i) {$DiscoveryRunAsAccount = $RunAsAccountDetection[$i].trim()}}

  # Wrties variable values which are specific to Visual Studios
  $Target = "$" + "Target"
  $MPElement = "$" + "MPElement"
  $ClassContent = Get-Content $MPDiscoveryFile
  $DiscoveryID = $DiscoveryName -replace " ", "."

  # Writes the Discovery ID to the XML Management Pack
  $FindCategoryLine = Select-String $MPDiscoveryFile -pattern "<Category>" | ForEach-Object {$_.LineNumber -2}
  $ClassContent[$FindCategoryLine] += "`n      <Discovery ID=""$DiscoveryName"" Target=""$DiscoveryTarget"" Enabled=""true"" ConfirmDelivery=""false"" Remotable=""true"" Priority=""Normal"">"
  $ClassContent | Set-Content $MPDiscoveryFile

  # Reloads the Class XML file with the new changes
  $ClassContent = Get-Content $MPDiscoveryFile

  # Writes the DisplayStrings to the XML so SCOM can read the display names correctly
  $FindLastDisplayStringLine = Select-String $MPDiscoveryFile -pattern "</DisplayStrings>" | ForEach-Object {$_.LineNumber -2}
  $ClassContent[$FindLastDisplayStringLine] += "`n    <DisplayString ElementID=""$DiscoveryID"">`n     <Name>$DiscoveryName</Name>`n     <Description>$DiscoveryDescription</Description>`n    </DisplayString>"
  $ClassContent | Set-Content $MPDiscoveryFile

  # Reloads the Class XML file with the new changes
  $ClassContent = Get-Content $MPDiscoveryFile

  # Writes the Discovery Class
  $FindDiscoveryTypesLine = Select-String $MPDiscoveryFile -pattern "</DiscoveryTypes>" | ForEach-Object {$_.LineNumber -2}
  $ClassContent[$FindDiscoveryTypesLine] += "`n          <DiscoveryClass TypeID=""$DiscoveryClass"">`n          </DiscoveryClass>"
  $ClassContent | Set-Content $MPDiscoveryFile

  # Reloads the Class XML file with the new changes
  $ClassContent = Get-Content $MPDiscoveryFile

  # Retrieves the details for the Class created previously 
  $MPClassContent = Get-Content $MPClassFile

  # Finds all of the properties which were created from that particular class by searching the class.xml file
  $FindProperties = ((Get-Content $MPClassFile) -match "<DisplayString ElementID=""$ClassID"" SubElementID") -replace "<DisplayString ElementID=""$ClassID"" SubElementID", "<Property PropertyID" -replace ">", " />"

  # Adds all of the properties which were discovered in the Class previously created to the Discovery Class
  $FindDiscoveryClassLine = Select-String $MPDiscoveryFile -pattern "</DiscoveryClass" | ForEach-Object {$_.LineNumber -2}
  $ClassContent[$FindDiscoveryClassLine] += "`n          $FindProperties"
  $ClassContent | Set-Content $MPDiscoveryFile

  # Reloads the Class XML file with the new changes
  $ClassContent = Get-Content $MPDiscoveryFile

  # Edits the DataSource line to prepare for it being a PowerShell Discovery
  $FindDiscoveryTypesLine = Select-String $MPDiscoveryFile -pattern "</DiscoveryTypes" | ForEach-Object {$_.LineNumber -1}
  $ClassContent[$FindDiscoveryTypesLine] += "`n             <DataSource ID=""DS"" TypeID=""Windows!Microsoft.Windows.FilteredRegistryDiscoveryProvider"" RunAs=""$DiscoveryRunAsAccount"">"
  $ClassContent | Set-Content $MPDiscoveryFile
  
  # Reloads the Class XML file with the new changes
  $ClassContent = Get-Content $MPDiscoveryFile

  # Adds the Registry Discovery Configuration to the XML
  $FindDataSourceLine = Select-String $MPDiscoveryFile -pattern "<DataSource" | ForEach-Object {$_.LineNumber -1}
  $ClassContent[$FindDataSourceLine] += "`n   <ComputerName>$Target/Property[Type=""$DiscoveryTarget""]/NetworkName$</ComputerName>`n        <RegistryAttributeDefinitions>`n      </RegistryAttributeDefinitions>`n      <Frequency>$Frequency</Frequency>`n      <ClassId>$MPElement[Name=""$ClassID""]$</ClassId>`n      <InstanceSettings>`n        <Settings>`n          <Setting>`n            <Name>$MPElement[Name=""Windows!Microsoft.Windows.Computer""]/PrincipalName$</Name>`n            <Value>$Target/Property[Type=""Windows!Microsoft.Windows.Computer""]/PrincipalName$</Value>`n          </Setting>`n        </Settings>`n      </InstanceSettings>"
  $ClassContent | Set-Content $MPDiscoveryFile

  # Reloads the Class XML file with the new changes
  $ClassContent = Get-Content $MPDiscoveryFile

  }

  Function Add-SCOMMPRegistryKey
  {
  Param (
  [String]$AttributeName = $(Read-Host -Prompt "Name of Attribute - Note: If doing keyexists then type KeyExists, if discovering registry attribute type name of PropertyName discovered above"),
  [String]$RegistryPath = $(Read-Host -Prompt "Registry path of property? Prefixed with HKLM - If looking for a key specify whole path and key name"),
  [String]$PathType = $(Read-Host -Prompt "Path Type i.e. 0 - to check Key Exists, 1 - Key value to be retrieved  "),
  [String]$AttributeType = $(Read-Host -Prompt "Attribute Type i.e. 0 - Boolean, 1- String, 2 - Integer, 3 - Float"),
  [String]$ClassID = $(Read-Host -Prompt "ClassID which this will point to")
  )

  # Reloads the Class XML file with the new changes
  $Data = "$" + "Data"
  $ClassContent = Get-Content $MPDiscoveryFile

  # Write Registry Key Attribute
  $FindRegistryAttributeDefinitionLine = Select-String $MPDiscoveryFile -pattern "</RegistryAttributeDefinitions>" | ForEach-Object {$_.LineNumber -2}
  $ClassContent[$FindRegistryAttributeDefinitionLine] += "`n        <RegistryAttributeDefinition>`n            <AttributeName>$AttributeName</AttributeName>`n            <Path>$RegistryPath</Path>`n            <PathType>$PathType</PathType>`n            <AttributeType>$AttributeType</AttributeType>`n        </RegistryAttributeDefinition>"
  $ClassContent | Set-Content $MPDiscoveryFile

  # Reloads the Class XML file with the new changes
   $ClassContent = Get-Content $MPDiscoveryFile

 If ($PathType -eq "0")
  {
    # Write Expression
    $FindInstanceSettingsLine = Select-String $MPDiscoveryFile -pattern "</InstanceSettings>" | ForEach-Object {$_.LineNumber -1}
    $ClassContent[$FindInstanceSettingsLine] += "`n            <Expression>`n              <SimpleExpression>`n                <ValueExpression>`n                      <XPathQuery Type=""Boolean"">Values/$AttributeName</XPathQuery>`n                </ValueExpression>`n                  <Operator>Equal</Operator>`n                  <ValueExpression>`n                    <Value Type=""Boolean"">true</Value>`n                  </ValueExpression>`n              </SimpleExpression>`n            </Expression>"
    $ClassContent | Set-Content $MPDiscoveryFile

     # Reloads the Class XML file with the new changes
     $ClassContent = Get-Content $MPDiscoveryFile
    }
   Else
  {
     # Write Instance Value
    $FindSettingsLine = Select-String $MPDiscoveryFile -pattern "</Settings>" | ForEach-Object {$_.LineNumber -2}
    $ClassContent[$FindSettingsLine] += "`n          <Setting>`n            <Name>$MPElement[Name=""$ClassID""]/$AttributeName$</Name>`n            <Value>$Data/Values/$AttributeName$</Value>`n          </Setting>"
    $ClassContent | Set-Content $MPDiscoveryFile

     # Reloads the Class XML file with the new changes
     $ClassContent = Get-Content $MPDiscoveryFile
    }
}

  Function Edit-SCOMMPAddRegistry
  {

   While($True) {
 [int]$xMenuChoiceA = 0
 while ( $xMenuChoiceA -lt 1 -or $xMenuChoiceA -gt 2 ){
 Write-host "1. Add Registry Attribute"
 Write-host "2. Exit"

[Int]$xMenuChoiceA = read-host "Please enter an option 1 to 2..."
 }
 Switch( $xMenuChoiceA ){
   1{Add-SCOMMPRegistryKey -ClassID $ClassID}
   2{Return}
   }
 }
  }

  Function Add-SCOMMPWMIDiscovery
  {
  Param (
  [String]$DiscoveryName = $(Read-Host -Prompt "Name of Discovery"),
  [String]$DiscoveryTarget = $(Read-Host -Prompt "Discovery Target - i.e. Enter ClassID if using nested custom class or base such as Windows!Microsoft.Windows.Computer"),
  [String]$DiscoveryDescription = $(Read-Host -Prompt "Description of discovery"),
  [String]$DiscoveryClass = $(Write-Host ""; $ClassesDetection = ((Get-Content $MPClassFile) -match "<DisplayString ElementID" -notmatch "SubElementID") -replace "<DisplayString ElementID=""", "" -replace """", "" -replace ">", ""
  ;Write-Host "Class ID that that the discovery is targeted to"; For($i=0;$i -le $ClassesDetection.Count -1; $i++) {Write-Host $i. $ClassesDetection[$i].trim()}; Read-Host -Prompt "Select Option"),
  [String]$DiscoveryRunAsAccount = $(Write-Host ""; $RunAsAccountDetection = ((Get-Content $MPClassFile) -match "<DisplayString ElementID" -notmatch "SubElementID") -replace "<DisplayString ElementID=""", "" -replace """", "" -replace ">", ""
  ;Write-Host "Discovery Run As Account"; For($i=0;$i -le $RunAsAccountDetection.Count -1; $i++) {Write-Host $i. $RunAsAccountDetection[$i].trim()}; Read-Host -Prompt "Select Option"),
  [String]$Namespace = $(Read-Host -Prompt "Namespace to connect to"),
  [String]$Query = $(Read-Host -Prompt "Type the WMI query to use"),
  [String]$Frequency = $(Read-Host -Prompt "Frequency (seconds)"),
  [String]$ClassID = $(Read-Host -Prompt "ClassID which this will point to")
  )
  
    # Sets Discovery Target
  For($i=0;$i -le $ClassesDetection.Count -1; $i++) {
   If ($DiscoveryTarget -eq $i) {$DiscoveryTarget = $ClassesDetection[$i].trim()}}

  # Sets Run As Account
  For($i=0;$i -le $RunAsAccountDetection.Count -1; $i++) {
   If ($DiscoveryRunAsAccount -eq $i) {$DiscoveryRunAsAccount = $RunAsAccountDetection[$i].trim()}}

  # Reloads the Class XML file with the new changes
  $Target = "$" + "Target"
  $MPElement = "$" + "MPElement"
  $Data = "$" + "Data"
  $DiscoveryID = $DiscoveryName -replace " ", ""
  $ClassContent = Get-Content $MPDiscoveryFile

  # Writes the Discovery ID to the XML Management Pack
  $FindCategoryLine = Select-String $MPDiscoveryFile -pattern "<Category>" | ForEach-Object {$_.LineNumber -2}
  $ClassContent[$FindCategoryLine] += "`n      <Discovery ID=""$DiscoveryName"" Target=""$DiscoveryTarget"" Enabled=""true"" ConfirmDelivery=""false"" Remotable=""true"" Priority=""Normal"">"
  $ClassContent | Set-Content $MPDiscoveryFile

  # Reloads the Class XML file with the new changes
  $ClassContent = Get-Content $MPDiscoveryFile

   # Writes the DisplayStrings to the XML so SCOM can read the display names correctly
  $FindLastDisplayStringLine = Select-String $MPDiscoveryFile -pattern "</DisplayStrings>" | ForEach-Object {$_.LineNumber -2}
  $ClassContent[$FindLastDisplayStringLine] += "`n    <DisplayString ElementID=""$DiscoveryID"">`n     <Name>$DiscoveryName</Name>`n     <Description>$DiscoveryDescription</Description>`n    </DisplayString>"
  $ClassContent | Set-Content $MPDiscoveryFile

   # Reloads the Class XML file with the new changes
  $ClassContent = Get-Content $MPDiscoveryFile

  # Writes the Discovery Class
  $FindDiscoveryTypesLine = Select-String $MPDiscoveryFile -pattern "</DiscoveryTypes>" | ForEach-Object {$_.LineNumber -2}
  $ClassContent[$FindDiscoveryTypesLine] += "`n          <DiscoveryClass TypeID=""$DiscoveryClass"">`n          </DiscoveryClass>"
  $ClassContent | Set-Content $MPDiscoveryFile

   # Reloads the Class XML file with the new changes
  $ClassContent = Get-Content $MPDiscoveryFile

  # Retrieves the details for the Class created previously 
  $MPClassContent = Get-Content $MPClassFile

  # Finds all of the properties which were created from that particular class by searching the class.xml file
  $FindProperties = ((Get-Content $MPClassFile) -match "<DisplayString ElementID=""$ClassID"" SubElementID") -replace "<DisplayString ElementID=""$ClassID"" SubElementID", "<Property PropertyID" -replace ">", " />"

  # Adds all of the properties which were discovered in the Class previously created to the Discovery Class
  $FindDiscoveryClassLine = Select-String $MPDiscoveryFile -pattern "</DiscoveryClass" | ForEach-Object {$_.LineNumber -2}
  $ClassContent[$FindDiscoveryClassLine] += "`n          $FindProperties"
  $ClassContent | Set-Content $MPDiscoveryFile

  # Edits the DataSource line to prepare for it being a WMI Discovery
  $FindDiscoveryTypesLine = Select-String $MPDiscoveryFile -pattern "</DiscoveryTypes" | ForEach-Object {$_.LineNumber -2}
  $ClassContent[$FindDiscoveryTypesLine] += "`n             <DataSource ID=""DS"" TypeID=""Windows!Microsoft.Windows.WmiProviderWithClassSnapshotDataMapper"" RunAs=""$DiscoveryRunAsAccount"">"
  $ClassContent | Set-Content $MPDiscoveryFile
  
  # Reloads the Class XML file with the new changes
  $ClassContent = Get-Content $MPDiscoveryFile

  # Adds the WMI Discovery Configuration to the XML
  $FindDataSourceLine = Select-String $MPDiscoveryFile -pattern "<DataSource" | ForEach-Object {$_.LineNumber -1}
  $ClassContent[$FindDataSourceLine] += "`n          <NameSpace>$NameSpace</NameSpace>`n          <Query>$Query</Query>`n          <Frequency>$Frequency</Frequency>`n          <ClassId>$MPElement[Name=""$ClassID""]$</ClassId>"
  $ClassContent | Set-Content $MPDiscoveryFile

  # Reloads the Class XML file with the new changes
  $ClassContent = Get-Content $MPDiscoveryFile

  #Writes the WMI Parameters
  $FindClassIDLine = Select-String $MPDiscoveryFile -pattern "<ClassID>" | ForEach-Object {$_.LineNumber -1}
  $ClassContent[$FindClassIDLine] += "`n       <InstanceSettings>`n            <Settings>`n              <Setting>`n              <Name>$MPElement[Name=""Windows!Microsoft.Windows.Computer""]/PrincipalName$</Name>`n            <Value>$Target/Host/Property[Type=""Windows!Microsoft.Windows.Computer""]/PrincipalName$</Value>`n            </Setting>`n              <Setting>`n              <Name>$MPElement[Name=""System!System.Entity""]/DisplayName$</Name>`n            <Value>$Target/Host/Property[Type=""Windows!Microsoft.Windows.Computer""]/PrincipalName$</Value>`n            </Setting>`n              </Settings>`n              </InstanceSettings>"
  $ClassContent | Set-Content $MPDiscoveryFile
  }

  Function Add-SCOMMPVBScriptDiscovery
  {
  Param (
  [String]$ClassID = $(Read-Host -Prompt "ClassID"),
  [String]$DiscoveryName = $(Read-Host -Prompt "Name of Discovery"),
  [String]$DiscoveryTarget = $(Read-Host "Discovery Target - i.e. Enter ClassID if using nested custom class or base such as Windows!Microsoft.Windows.Computer"),
  [String]$DiscoveryDescription = $(Read-Host -Prompt "Description of discovery"),
  [String]$DiscoveryClass = $(Write-Host ""; $ClassesDetection = ((Get-Content $MPClassFile) -match "<DisplayString ElementID" -notmatch "SubElementID") -replace "<DisplayString ElementID=""", "" -replace """", "" -replace ">", ""
  ;Write-Host "Class ID that that the discovery is targeted to"; For($i=0;$i -le $ClassesDetection.Count -1; $i++) {Write-Host $i. $ClassesDetection[$i].trim()}; Read-Host -Prompt "Select Option"),
  [String]$DiscoveryRunAsAccount = $(Write-Host ""; $RunAsAccountDetection = ((Get-Content $MPClassFile) -match "<DisplayString ElementID" -notmatch "SubElementID") -replace "<DisplayString ElementID=""", "" -replace """", "" -replace ">", ""
  ;Write-Host "Discovery Run As Account"; For($i=0;$i -le $RunAsAccountDetection.Count -1; $i++) {Write-Host $i. $RunAsAccountDetection[$i].trim()}; Read-Host -Prompt "Select Option"),
  [String]$IntervalSeconds = $(Read-Host -Prompt "Interval Seconds"),
  [Parameter(Mandatory=$false)][String]$SyncTime = $(Read-Host -Prompt "Sync Time"),
  [String]$MPClassFile = $(Read-Host -Prompt "MP Class File"),
  [String]$MPDiscoveryFile = $(Read-Host -Prompt "MP Discovery File"),
  [String]$ScriptName = $(Read-Host -Prompt "Script Name"),
  [String]$TimeoutSeconds = $(Read-Host -Prompt "Timeout Seconds")
  )

    # Sets Discovery Target
  For($i=0;$i -le $ClassesDetection.Count -1; $i++) {
   If ($DiscoveryTarget -eq $i) {$DiscoveryTarget = $ClassesDetection[$i].trim()}}

  # Sets Run As Account
  For($i=0;$i -le $RunAsAccountDetection.Count -1; $i++) {
   If ($DiscoveryRunAsAccount -eq $i) {$DiscoveryRunAsAccount = $RunAsAccountDetection[$i].trim()}}

  # Reloads the Class XML file with the new changes
  $Target = "$" + "Target"
  $MPElement = "$" + "MPElement"
  $Data = "$" + "Data"
  $DiscoveryID = $DiscoveryName -replace " ", ""
  $IncludeFileContent = "$" + "IncludeFileContent"
  $ClassContent = Get-Content $MPDiscoveryFile

  # Writes the Discovery ID to the XML Management Pack
  $FindCategoryLine = Select-String $MPDiscoveryFile -pattern "<Category>" | ForEach-Object {$_.LineNumber -2}
  $ClassContent[$FindCategoryLine] += "`n      <Discovery ID=""$DiscoveryName"" Target=""$DiscoveryTarget"" Enabled=""true"" ConfirmDelivery=""false"" Remotable=""true"" Priority=""Normal"">"
  $ClassContent | Set-Content $MPDiscoveryFile

  # Reloads the Class XML file with the new changes
  $ClassContent = Get-Content $MPDiscoveryFile

   # Writes the DisplayStrings to the XML so SCOM can read the display names correctly
  $FindLastDisplayStringLine = Select-String $MPDiscoveryFile -pattern "</DisplayStrings>" | ForEach-Object {$_.LineNumber -2}
  $ClassContent[$FindLastDisplayStringLine] += "`n    <DisplayString ElementID=""$DiscoveryID"">`n     <Name>$DiscoveryName</Name>`n     <Description>$DiscoveryDescription</Description>`n    </DisplayString>"
  $ClassContent | Set-Content $MPDiscoveryFile

   # Reloads the Class XML file with the new changes
  $ClassContent = Get-Content $MPDiscoveryFile

  # Writes the Discovery Class
  $FindDiscoveryTypesLine = Select-String $MPDiscoveryFile -pattern "</DiscoveryTypes>" | ForEach-Object {$_.LineNumber -2}
  $ClassContent[$FindDiscoveryTypesLine] += "`n          <DiscoveryClass TypeID=""$DiscoveryClass"">`n          </DiscoveryClass>"
  $ClassContent | Set-Content $MPDiscoveryFile

   # Reloads the Class XML file with the new changes
  $ClassContent = Get-Content $MPDiscoveryFile

  # Retrieves the details for the Class created previously 
  $MPClassContent = Get-Content $MPClassFile

  # Finds all of the properties which were created from that particular class by searching the class.xml file
  $FindProperties = ((Get-Content $MPClassFile) -match "<DisplayString ElementID=""$ClassID"" SubElementID") -replace "<DisplayString ElementID=""$ClassID"" SubElementID", "<Property PropertyID" -replace ">", " />"

  # Adds all of the properties which were discovered in the Class previously created to the Discovery Class
  $FindDiscoveryClassLine = Select-String $MPDiscoveryFile -pattern "</DiscoveryClass" | ForEach-Object {$_.LineNumber -2}
  $ClassContent[$FindDiscoveryClassLine] += "`n          $FindProperties"
  $ClassContent | Set-Content $MPDiscoveryFile

  # Edits the DataSource line to prepare for it being a WMI Discovery
  $FindDiscoveryTypesLine = Select-String $MPDiscoveryFile -pattern "</DiscoveryTypes" | ForEach-Object {$_.LineNumber -2}
  $ClassContent[$FindDiscoveryTypesLine] += "`n             <DataSource ID=""DS"" TypeID=""Windows!Microsoft.Windows.TimedScript.DiscoveryProvider"" RunAs=""$DiscoveryRunAsAccount"">"
  $ClassContent | Set-Content $MPDiscoveryFile
  
  # Reloads the Class XML file with the new changes
  $ClassContent = Get-Content $MPDiscoveryFile

  # Adds the VBScript Discovery Configuration to the XML
  $FindDataSourceLine = Select-String $MPDiscoveryFile -pattern "<DataSource" | ForEach-Object {$_.LineNumber -1}
  $ClassContent[$FindDataSourceLine] += "`n          <IntervalSeconds>$IntervalSeconds</IntervalSeconds>`n          <SyncTime>$SyncTime</SyncTime>`n          <ScriptName>$ScriptName</ScriptName>`n          <Arguments>$MPElement$ $Target/Id$ $Target/Host/Property[Type=""Windows!Microsoft.Windows.Computer""]/PrincipalName$</Arguments>`n         <ScriptBody>$IncludeFileContent/$ScriptName$</ScriptBody>`n         <TimeoutSeconds>$TimeoutSeconds</TimeoutSeconds>"
  $ClassContent | Set-Content $MPDiscoveryFile

  # Reloads the Class XML file with the new changes
  $ClassContent = Get-Content $MPDiscoveryFile

  #Writes the VBScript Parameters
  #$FindClassIDLine = Select-String $MPDiscoveryFile -pattern "<ClassID>" | ForEach-Object {$_.LineNumber -1}
  #$ClassContent[$FindClassIDLine] += "`n       <InstanceSettings>`n            <Settings>`n              <Setting>`n              <Name>$MPElement[Name=""Windows!Microsoft.Windows.Computer""]/PrincipalName$</Name>`n            <Value>$Target/Host/Property[Type=""Windows!Microsoft.Windows.Computer""]/PrincipalName$</Value>`n            <Parameter>`n              <Name>managedEntityID</Name>`n              <Value>$Target/Id$</Value>`n            </Parameter>`n            <Parameter>`n              <Name>computerName</Name>`n              <Value>$Target/Host/Property[Type=""$DiscoveryTarget""]/PrincipalName$</Value>`n            </Parameter>`n          </Parameters>`n          <TimeoutSeconds>$TimeoutSeconds</TimeoutSeconds>"
  #$ClassContent | Set-Content $MPDiscoveryFile
  
  } 


  Function Add-SCOMMPComputerGroupDiscovery
  {
  Param (
  [String]$DiscoveryID = $(Read-Host -Prompt "Name of Discovery"),
  [String]$DiscoveryTarget = $(Read-Host -Prompt "Class ID which discovery is targeted to"),
  [String]$DiscoveryDescription = $(Read-Host -Prompt "Description of discovery"),
  [String]$ClassID = $(Write-Host ""; $ClassesDetection = ((Get-Content $MPClassFile) -match "<DisplayString ElementID" -notmatch "SubElementID") -replace "<DisplayString ElementID=""", "" -replace """", "" -replace ">", ""
  ;Write-Host "Class ID it will point to"; For($i=0;$i -le $ClassesDetection.Count -1; $i++) {Write-Host $i. $ClassesDetection[$i].trim()}; Read-Host -Prompt "Select Option"),
  [String]$MPDiscoveryFile = $(Read-Host -Prompt "Where will the discovery file be saved")
  )

    # Sets Target
    For($i=0;$i -le $ClassesDetection.Count -1; $i++) {
   If ($ClassID -eq $i) {$ClassID = $ClassesDetection[$i].trim()}}

  # Reloads the Class XML file with the new changes
  $MPElement = "$" + "MPElement"
  $DiscoveryName = $DiscoveryID.replace("."," ")
  $ClassContent = Get-Content $MPDiscoveryFile

  # Write Computer Group Discovery
  $FindDiscoveriesLine = Select-String $MPDiscoveryFile -pattern "</Discoveries>" | ForEach-Object {$_.LineNumber -2}
  $ClassContent[$FindDiscoveriesLine] += "`n      <Discovery ID=""$DiscoveryID"" Target=""$DiscoveryTarget"" Enabled=""false"" ConfirmDelivery=""false"" Remotable=""true"" Priority=""Normal"">`n        <Category>Discovery</Category>`n        <DiscoveryTypes />`n        <DataSource ID=""DS"" TypeID=""SC!Microsoft.SystemCenter.GroupPopulator"">`n          <RuleId>$MPElement$</RuleId>`n          <GroupInstanceId>$MPElement[Name=""$DiscoveryName""]$</GroupInstanceId>`n          <MembershipRules>`n            <MembershipRule>`n              <MonitoringClass>$MPElement[Name=""Windows!Microsoft.Windows.Computer""]$</MonitoringClass>`n              <RelationshipClass>$MPElement[Name=""SC!Microsoft.SystemCenter.ComputerGroupContainsComputer""]$</RelationshipClass>`n              <Expression>`n                <Contains>`n                  <MonitoringClass>$MPElement[Name=""$ClassID""]$</MonitoringClass>`n                </Contains>`n              </Expression>`n            </MembershipRule>`n          </MembershipRules>`n        </DataSource>`n      </Discovery>"
  $ClassContent | Set-Content $MPDiscoveryFile

  # Reloads the Class XML file with the new changes
  $ClassContent = Get-Content $MPDiscoveryFile

  # Writes the DisplayStrings to the XML so SCOM can read the display names correctly
  $FindLastDisplayStringLine = Select-String $MPDiscoveryFile -pattern "</DisplayStrings>" | ForEach-Object {$_.LineNumber -2}
  $ClassContent[$FindLastDisplayStringLine] += "`n    <DisplayString ElementID=""$DiscoveryID"">`n     <Name>$DiscoveryName</Name>`n     <Description>$DiscoveryDescription</Description>`n    </DisplayString>"
  $ClassContent | Set-Content $MPDiscoveryFile
  
  # Reloads the Class XML file with the new changes  
  $ClassContent = Get-Content $MPDiscoveryFile

  }

  Function Add-SCOMMPInstanceGroupDiscovery
  {
  Param (
  [String]$DiscoveryID = $(Read-Host -Prompt "Name of Discovery"),
  [String]$DiscoveryTarget = $(Read-Host -Prompt "Class ID which discovery is targeted to"),
  [String]$DiscoveryDescription = $(Read-Host -Prompt "Description of discovery"),
  [String]$ClassID = $(Write-Host ""; $ClassesDetection = ((Get-Content $MPClassFile) -match "<DisplayString ElementID" -notmatch "SubElementID") -replace "<DisplayString ElementID=""", "" -replace """", "" -replace ">", ""
  ;Write-Host "Class ID it will point to"; For($i=0;$i -le $ClassesDetection.Count -1; $i++) {Write-Host $i. $ClassesDetection[$i].trim()}; Read-Host -Prompt "Select Option"),
  [String]$MPDiscoveryFile = $(Read-Host -Prompt "Where will the discovery file be saved")
  )

      # Sets Target
    For($i=0;$i -le $ClassesDetection.Count -1; $i++) {
   If ($ClassID -eq $i) {$ClassID = $ClassesDetection[$i].trim()}}

  # Reloads the Class XML file with the new changes
  $MPElement = "$" + "MPElement"
  $DiscoveryName = $DiscoveryID.replace("."," ")
  $ClassContent = Get-Content $MPDiscoveryFile

  # Write Computer Group Discovery
  $FindDiscoveriesLine = Select-String $MPDiscoveryFile -pattern "</Discoveries>" | ForEach-Object {$_.LineNumber -2}
  $ClassContent[$FindDiscoveriesLine] += "`n      <Discovery ID=""$DiscoveryID"" Target=""$DiscoveryTarget"" Enabled=""false"" ConfirmDelivery=""false"" Remotable=""true"" Priority=""Normal"">`n        <Category>Discovery</Category>`n        <DiscoveryTypes />`n        <DataSource ID=""DS"" TypeID=""SC!Microsoft.SystemCenter.GroupPopulator"">`n          <RuleId>$MPElement$</RuleId>`n          <GroupInstanceId>$MPElement[Name=""$DiscoveryName""]$</GroupInstanceId>`n          <MembershipRules>`n            <MembershipRule>`n              <MonitoringClass>$MPElement[Name=""Windows!Microsoft.Windows.Computer""]$</MonitoringClass>`n              <RelationshipClass>$MPElement[Name=""MSIL!Microsoft.SystemCenter.InstanceGroupContainsEntities""]$</RelationshipClass>`n              <Expression>`n                <Contains>`n                  <MonitoringClass>$MPElement[Name=""$ClassID""]$</MonitoringClass>`n                </Contains>`n              </Expression>`n            </MembershipRule>`n          </MembershipRules>`n        </DataSource>`n      </Discovery>"
  $ClassContent | Set-Content $MPDiscoveryFile

  # Reloads the Class XML file with the new changes
  $ClassContent = Get-Content $MPDiscoveryFile

  # Writes the DisplayStrings to the XML so SCOM can read the display names correctly
  $FindLastDisplayStringLine = Select-String $MPDiscoveryFile -pattern "</DisplayStrings>" | ForEach-Object {$_.LineNumber -2}
  $ClassContent[$FindLastDisplayStringLine] += "`n    <DisplayString ElementID=""$DiscoveryID"">`n     <Name>$DiscoveryName</Name>`n     <Description>$DiscoveryDescription</Description>`n    </DisplayString>"
  $ClassContent | Set-Content $MPDiscoveryFile
  
  # Reloads the Class XML file with the new changes
  $ClassContent = Get-Content $MPDiscoveryFile

  }


  Function Create-PowerShellScript 
{
Param (
[String]$ScriptName = (Read-Host -Prompt "Script Name"),
[String]$MPClassFile = (Read-Host -Prompt "Class file created previously to use script to discover")
)

# Wrties variable values which are specific to Visual Studios
$Instance = "$" + "instance"
$SourceID = "$" + "sourceid"
$ManagedEntityId = "$" + "managedEntityId"
$Computername = "$" + "computerName"
$api = "$" + "api"
$discoveryData = "$" + "discoveryData"

# Writes the PowerShell Discovery script logic
Add-Content $ScriptName "param($sourceId,$managedEntityId,$computerName)`n `n$api = new-object -comObject 'MOM.ScriptAPI'`n$discoveryData = $api.CreateDiscoveryData(0, $SourceId, $ManagedEntityId)"
Add-Content $ScriptName "`n$Instance = $discoveryData.CreateClassInstance(""$MPElement[Name='$ClassID']$"")`n$instance.AddProperty(""$MPElement[Name='Windows!Microsoft.Windows.Computer']/PrincipalName$"", $computerName) "
Add-Content $ScriptName "`n <Insert Script Here>"
ForEach ($line in $PropertiesDetection) {Add-Content $ScriptName "`n$Instance.AddProperty(""$MPElement[Name='$ClassID']/$line$,#Add Variable Here to Discovery this property#"")"}
Add-Content $ScriptName "`n$discoveryData.AddInstance($instance)"
Add-Content $ScriptName "`n$discoveryData"

Write-Host "Edit the PowerShell script to contain your script portion for the discovery. Start from under the $Discoverydata line" -ForegroundColor Yellow
Write-Host "The Script will contain the properties lines. Make sure you add the variable next to the "\," and comments character to assure that the property will be discovered by your script portion" -ForegroundColor Yellow

}

Function Create-VBScript
{
Param (
[String]$ScriptName = (Read-Host -Prompt "Script Name"),
[String]$MPClassFile = (Read-Host -Prompt "Class file created previously to use script to discover")
)

# Wrties variable values which are specific to Visual Studios
$Instance = "$" + "instance"
$SourceID = "$" + "sourceid"
$ManagedEntityId = "$" + "managedEntityId"
$Computername = "$" + "computerName"
$api = "$" + "api"
$discoveryData = "$" + "discoveryData"
$MPElement = "$" + "MPElement"

# Write VBScript
Add-Content $ScriptName "SourceId = WScript.Arguments(0)"
Add-Content $ScriptName "ManagedEntityId = WScript.Arguments(1)"
Add-Content $ScriptName "sComputerName = WScript.Arguments(2)"
Add-Content $ScriptName "`nSet oAPI = CreateObject(""MOM.ScriptAPI"")"
Add-Content $ScriptName "Set oDiscoveryData = oAPI.CreateDiscoveryData(0, SourceId, ManagedEntityId)"
Add-Content $ScriptName "`nFor i = 1 to 3"
Add-Content $ScriptName "Set oInstance = oDiscoveryData.CreateClassInstance (""$MPElement[Name='$ClassID']$"") "
Add-Content $ScriptName "oInstance.AddProperty ""$MPElement[Name='Windows!Microsoft.Windows.Computer']/PrincipalName$"", sComputerName"
ForEach ($line in $PropertiesDetection) {Add-Content $ScriptName "oInstance.AddProperty ""$MPElement[Name='$ClassID']/$line$"","}

Write-Host "Edit the VB script to contain your script portion for the discovery. Start from under the Discoverydata line" -ForegroundColor Yellow
Write-Host "The Script will contain the properties lines. Make sure you add the variable next to the "\," and comments character to assure that the property will be discovered by your script portion" -ForegroundColor Yellow

}

Function Edit-SCOMMPDiscovery
{
   While($True) {
 [int]$xMenuChoiceA = 0
 while ( $xMenuChoiceA -lt 1 -or $xMenuChoiceA -gt 5 ){
 Write-host "1. Add PowerShell Discovery"
 Write-host "2. Add VBScript Discovery"
 Write-Host "3. Add WMI Discovery"
 Write-Host "4. Add Registry Discovery"
 Write-Host "5. Exit"

[Int]$xMenuChoiceA = read-host "Please enter an option 1 to 5..."
 }
 Switch( $xMenuChoiceA ){
   1{Add-SCOMMPPowerShellDiscovery -MPDiscoveryFile $MPDiscoveryFile; Create-PowerShellScript}
   2{Add-SCOMMPVBScriptDiscovery -MPDiscoveryFile $MPDiscoveryFile; Create-VBScript}
   3{Add-SCOMMPWMIDiscovery -MPDiscoveryFile $MPDiscoveryFile}
   4{Add-SCOMMPRegistryDiscovery -MPDiscoveryFile $MPDiscoveryFile; Edit-SCOMMPAddRegistry}
   5{Return}
   }
 }

}

Function New-SCOMMPView
{
Param (
[String]$MPViewFile = $(Read-Host -Prompt "Where the View File will be created")
)

Add-Content $MPViewFile "<ManagementPackFragment SchemaVersion=""2.0"" xmlns:xsd=""http://www.w3.org/2001/XMLSchema"">`n  <Presentation>`n    <Views>`n    </Views>`n    <FolderItems>`n    </FolderItems>`n  </Presentation>`n  <LanguagePacks>`n   <LanguagePack ID=""ENU"" IsDefault=""true"">`n    <DisplayStrings>`n      </DisplayStrings>`n    </LanguagePack>`n  </LanguagePacks>`n</ManagementPackFragment>"

}

Function Add-SCOMMPView
{
Param (
[String]$ViewName = $(Read-Host -Prompt "Name of view"),
[String]$ViewTarget = $(Write-Host ""; $ClassesDetection = ((Get-Content $MPClassFile) -match "<DisplayString ElementID" -notmatch "SubElementID") -replace "<DisplayString ElementID=""", "" -replace """", "" -replace ">", ""
;Write-Host "Which class will the view display"; For($i=0;$i -le $ClassesDetection.Count -1; $i++) {Write-Host $i. $ClassesDetection[$i].trim()}; Read-Host -Prompt "Select Option"),
[String]$ViewType = $(Write-Host "Type of view to create" ;Write-Host ""; Write-host "1. Alert View"
  Write-Host "2. Dashboard View";Write-Host "3. Diagram View"; Write-Host "4. Event View"; Write-Host "5. Inventory View"; Write-Host "6. Managed Object View"; Write-Host "7. Performance View";Write-Host "8. Overrides Summary View";Write-Host "9. State View";Write-Host "10. State Detail View"; Write-Host "11. Task Status View";Write-Host "12. URL View";Read-Host -Prompt "Select Option"),
[String]$FolderID = $(Write-Host ""; $FolderDetection = ((Get-Content $MPFolderFile) -match "<DisplayString ElementID" -notmatch "SubElementID") -replace "<DisplayString ElementID=""", "" -replace """", "" -replace ">", ""
;Write-Host "Which folder will the view be placed"; For($i=0;$i -le $FolderDetection.Count -1; $i++) {Write-Host $i. $FolderDetection[$i].trim()}; Read-Host -Prompt "Select Option"),
[String]$MPViewFile = $(Read-Host -Prompt "Where the View File will be created")
)

    # Sets View Target
  For($i=0;$i -le $ClassesDetection.Count -1; $i++) {
   If ($ViewTarget -eq $i) {$ViewTarget = $ClassesDetection[$i].trim()}}

   # Sets Folder Parent
  For($i=0;$i -le $FolderDetection.Count -1; $i++) {
   If ($FolderID -eq $i) {$FolderID = $FolderDetection[$i].trim()}}

 # Wrties variable values which are specific to Visual Studios
 $ViewID = $ViewName -replace " ", "."
 $ClassContent = Get-Content $MPViewFile
 $ViewTarget = $ViewTarget -replace " ", "."

 # Writes the view XML to the management pack

  # Sets ViewType
  If ($ViewType -eq "1") {
   $ViewType = "SC!Microsoft.SystemCenter.AlertViewType"
   $FindViewsline = Select-String $MPViewFile -pattern "</views>" | ForEach-Object {$_.LineNumber -2}
   $ClassContent[$FindViewsline] += "`n      <View ID=""$ViewID"" Accessibility=""Internal"" Target=""$ViewTarget"" TypeID=""$ViewType"" Visible=""true"">`n        <Category>Operations</Category>`n        <Criteria>`n          <!--Use Error, Warning or Success for Severity-->`n          <!--To use multiple severities copy the Severity line and add another severity-->`n          <!--If wanting to display everything delete from <SeverityList> to </SeverityList>-->`n          <SeverityList>`n            <Severity>Error</Severity>`n          </SeverityList>`n          <!--Use High, Medium or Low for Priority-->`n          <!--To use multiple priorities copy the Priority line and add another Priority-->`n          <!--If wanting to display everything delete from <PriorityList> to </PriorityList>-->`n          <PriorityList>`n            <Priority>Medium</Priority>`n          </PriorityList>`n          <!--Enter the resolution state number to the <State> switch display only those resolution states-->`n          <!--To use multiple resolution states copy the State line and add another state-->`n          <!--If wanting to display everything delete from <ResolutionState> to </ResolutionState>-->`n          <ResolutionState>`n            <State>0</State>`n          </ResolutionState>`n        </Criteria>`n      </View>"
   $ClassContent | Set-Content $MPViewFile
   Write-Host "You can add Resolution States, Severity and Priority filtering to the XML in the switches within Visual Studio" -ForegroundColor Yellow
   }

  If ($ViewType -eq "2") {
   $ViewType = "SC!Microsoft.SystemCenter.DashboardViewType"
   $FindViewsline = Select-String $MPViewFile -pattern "</views>" | ForEach-Object {$_.LineNumber -2}
   $ClassContent[$FindViewsline] += "`n      <View ID=""$ViewID"" Accessibility=""Internal"" Target=""$ViewTarget"" TypeID=""$ViewType"" Visible=""true"">`n        <Category>Operations</Category>`n      </View>"
   $ClassContent | Set-Content $MPViewFile
  }
  
  If ($ViewType -eq "3") {
   $ViewType = "SC!Microsoft.SystemCenter.DiagramViewType"
   $FindViewsline = Select-String $MPViewFile -pattern "</views>" | ForEach-Object {$_.LineNumber -2}
   $ClassContent[$FindViewsline] += "`n      <View ID=""$ViewID"" Accessibility=""Internal"" Target=""$ViewTarget"" TypeID=""$ViewType"" Visible=""true"">`n        <Category>Operations</Category>`n      </View>"
   $ClassContent | Set-Content $MPViewFile
  }
  
  If ($ViewType -eq "4") {
   $ViewType = "SC!Microsoft.SystemCenter.EventViewType"
   $FindViewsline = Select-String $MPViewFile -pattern "</views>" | ForEach-Object {$_.LineNumber -2}
   $ClassContent[$FindViewsline] += "`n      <View ID=""$ViewID"" Accessibility=""Internal"" Target=""$ViewTarget"" TypeID=""$ViewType"" Visible=""true"">`n        <Category>Operations</Category>`n        <Criteria>`n          <EventNumberList>`n            <EventNumber></EventNumber>`n          </Criteria>      </View>"
   $ClassContent | Set-Content $MPViewFile
   Write-Host "You can add the Event number filtering to the XML in the switches within Visual Studio" -ForegroundColor Yellow
  }
  
  If ($ViewType -eq "5") {
   $ViewType = "SC!Microsoft.SystemCenter.InventoryViewType"
   $FindViewsline = Select-String $MPViewFile -pattern "</views>" | ForEach-Object {$_.LineNumber -2}
   $ClassContent[$FindViewsline] += "`n      <View ID=""$ViewID"" Accessibility=""Internal"" Target=""$ViewTarget"" TypeID=""$ViewType"" Visible=""true"">`n        <Category>Operations</Category>`n      </View>"
   $ClassContent | Set-Content $MPViewFile  
  }
  
  If ($ViewType -eq "6") {
   $ViewType = "SC!Microsoft.SystemCenter.ManagedObjectViewType"
   $FindViewsline = Select-String $MPViewFile -pattern "</views>" | ForEach-Object {$_.LineNumber -2}
   $ClassContent[$FindViewsline] += "`n      <View ID=""$ViewID"" Accessibility=""Internal"" Target=""$ViewTarget"" TypeID=""$ViewType"" Visible=""true"">`n        <Category>Operations</Category>`n      </View>"
   $ClassContent | Set-Content $MPViewFile  }
  
  If ($ViewType -eq "7") {
   $ViewType = "SC!Microsoft.SystemCenter.PerformanceViewType"
   $FindViewsline = Select-String $MPViewFile -pattern "</views>" | ForEach-Object {$_.LineNumber -2}
   $ClassContent[$FindViewsline] += "`n      <View ID=""$ViewID"" Accessibility=""Internal"" Target=""$ViewTarget"" TypeID=""$ViewType"" Visible=""true"">`n        <Category>Operations</Category>`n        <Criteria>`n          <Object></Object>`n          <Instance>test</Instance>`n          <Counter></Counter>`n        </Criteria>`n      </View>"
   $ClassContent | Set-Content $MPViewFile
   }
  
  If ($ViewType -eq "8") {
   $ViewType = "SC!Microsoft.SystemCenter.OverridesSummaryViewType"
   $FindViewsline = Select-String $MPViewFile -pattern "</views>" | ForEach-Object {$_.LineNumber -2}
   $ClassContent[$FindViewsline] += "`n      <View ID=""$ViewID"" Accessibility=""Internal"" Target=""$ViewTarget"" TypeID=""$ViewType"" Visible=""true"">`n        <Category>Operations</Category>`n      </View>"
   $ClassContent | Set-Content $MPViewFile
   }
  
  If ($ViewType -eq "9") {
   $ViewType = "SC!Microsoft.SystemCenter.StateViewType"
   $FindViewsline = Select-String $MPViewFile -pattern "</views>" | ForEach-Object {$_.LineNumber -2}
   $ClassContent[$FindViewsline] += "`n      <View ID=""$ViewID"" Accessibility=""Internal"" Target=""$ViewTarget"" TypeID=""$ViewType"" Visible=""true"">`n        <Category>Operations</Category>`n        <Criteria>`n          <!--Use Red (Error), Yellow (Warning), Green (Healthy) for the severity-->`n          <!--To use multiple severities copy the Severity line and add another severity-->`n          <!--If wanting to display everything delete from <SeverityList> to </SeverityList>-->`n                    <SeverityList>`n            <Severity>Red</Severity>`n          </SeverityList>`n          <!--Use true or false to display machines in maintenance mode-->`n          <InMaintenanceMode>true</InMaintenanceMode>`n        </Criteria>      </View>"
   $ClassContent | Set-Content $MPViewFile
   Write-Host "You can add the Severity and if you want to show devices in maintenance mode (true or false) to the XML in the switches within Visual Studio" -ForegroundColor Yellow
  }

  If ($ViewType -eq "10") {
  $ViewType = "SC!Microsoft.SystemCenter.StateDetailDefinitionViewType"
  $FindViewsline = Select-String $MPViewFile -pattern "</views>" | ForEach-Object {$_.LineNumber -2}
  $ClassContent[$FindViewsline] += "`n      <View ID=""$ViewID"" Accessibility=""Internal"" Target=""$ViewTarget"" TypeID=""$ViewType"" Visible=""true"">`n        <Category>Operations</Category>`n      </View>"
  $ClassContent | Set-Content $MPViewFile
  }
  
  If ($ViewType -eq "11") {
  $ViewType = "SC!Microsoft.SystemCenter.TaskStatusViewType"
  $FindViewsline = Select-String $MPViewFile -pattern "</views>" | ForEach-Object {$_.LineNumber -2}
  $ClassContent[$FindViewsline] += "`n      <View ID=""$ViewID"" Accessibility=""Internal"" Target=""$ViewTarget"" TypeID=""$ViewType"" Visible=""true"">`n        <Category>Operations</Category>`n        <Criteria>`n           <!--Use Succeeded, Scheduled, Startred or Failed for filtering of your Task Status -->`n       <!--If needing to add more filters copy the status lines and paste underneath -->`          <StatusList>`n            <Status>Scheduled</Status>`n          </StatusList>`n        </Criteria>`n      </View>"
  $ClassContent | Set-Content $MPViewFile
  }
  
  If ($ViewType -eq "12") {
  $ViewType = "SC!Microsoft.SystemCenter.UrlViewType"
  $URL = Read-Host "Type in the website"
  $URL = $URL -replace ":","%3A" -replace "/","%2F"
  $FindViewsline = Select-String $MPViewFile -pattern "</views>" | ForEach-Object {$_.LineNumber -2}
  $ClassContent[$FindViewsline] += "`n      <View ID=""$ViewID"" Accessibility=""Internal"" Target=""$ViewTarget"" TypeID=""$ViewType"" Visible=""true"">`n        <Category>Operations</Category>`n        <Criteria>`n          <Url>$URL</Url>`n        </Criteria>`n      </View>"
  $ClassContent | Set-Content $MPViewFile
  }

 # Reload content
 $ClassContent = Get-Content $MPViewFile

 # Writes the DisplayStrings to the XML so SCOM can read the display names correctly
 $FindLastDisplayStringLine = Select-String $MPViewFile -pattern "</DisplayStrings>" | ForEach-Object {$_.LineNumber -2}
 $ClassContent[$FindLastDisplayStringLine] += "`n    <DisplayString ElementID=""$ViewID"">`n     <Name>$ViewName</Name>`n     <Description>$ViewDescription</Description>`n    </DisplayString>"
 $ClassContent | Set-Content $MPViewFile

 #Reload content
 $ClassContent = Get-Content $MPViewFile

 # Writes the View to be placed in a specific folder
 $FindFolderItemsLine = Select-String $MPViewFile -pattern "</FolderItems>" | ForEach-Object {$_.LineNumber -2}
 $ClassContent[$FindFolderItemsLine] += "`n      <FolderItem ElementID=""$ViewID"" Folder=""$FolderID"" ID=""$ViewID.folderitem"" />"
 $ClassContent | Set-Content $MPViewFile

}

Function New-SCOMMPFolder
{
Param (
[String]$MPFolderFile = $(Read-Host -Prompt "Where the folder File will be created")
)

Add-Content $MPFolderFile "<ManagementPackFragment SchemaVersion=""2.0"" xmlns:xsd=""http://www.w3.org/2001/XMLSchema"">`n  <Presentation>`n    <Folders>`n    </Folders>`n    <FolderItems>`n    </FolderItems>`n  </Presentation>`n  <LanguagePacks>`n   <LanguagePack ID=""ENU"" IsDefault=""true"">`n            <DisplayStrings>`n      </DisplayStrings>`n    </LanguagePack>`n  </LanguagePacks>`n</ManagementPackFragment>"

}

Function Add-SCOMMPFolder
{
Param (
[String]$FolderName = $(Read-Host -Prompt "Name of folder"),
[String]$FolderParent = $(Write-Host ""; $FolderDetection = ((Get-Content $MPFolderFile) -match "<DisplayString ElementID" -notmatch "SubElementID") -replace "<DisplayString ElementID=""", "" -replace """", "" -replace ">", ""
;Write-Host "Where will the folder be placed"; For($i=0;$i -le $FolderDetection.Count -1; $i++) {Write-Host $i. $FolderDetection[$i].trim()}; Read-Host -Prompt "Select Option - if left blank default will be on the SCOM Console root"),
[String]$MPFolderFile = $(Read-Host -Prompt "Where the folder File will be created")
)

 # Sets Folder Parent
  If ($FolderParent -eq $Null) {$FolderParent = "SC!Microsoft.SystemCenter.Monitoring.ViewFolder.Root"}

      # Sets Folder Parent
  For($i=0;$i -le $FolderParent.Count -1; $i++) {
   If ($FolderParent -eq $i) {$FolderParent = $FolderDetection[$i].trim()}}

 # Wrties variable values which are specific to Visual Studios
 $FolderID = $FolderName -replace " ", "."
 $ClassContent = Get-Content $MPFolderFile

 # Writes the Folder XML to the management pack
 $FindFoldersline = Select-String $MPFolderFile -pattern "</Folders>" | ForEach-Object {$_.LineNumber -2}
 $ClassContent[$FindFoldersline] += "`n      <Folder ID=""$FolderID"" Accessibility=""Internal"" ParentFolder=""$FolderParent"" />"
 $ClassContent | Set-Content $MPFolderFile

 #Reload content
 $ClassContent = Get-Content $MPFolderFile

 # Writes the DisplayStrings to the XML so SCOM can read the display names correctly
 $FindLastDisplayStringLine = Select-String $MPFolderFile -pattern "</DisplayStrings>" | ForEach-Object {$_.LineNumber -2}
 $ClassContent[$FindLastDisplayStringLine] += "`n    <DisplayString ElementID=""$FolderID"">`n     <Name>$FolderName</Name>`n     <Description>$FolderDescription</Description>`n    </DisplayString>"
 $ClassContent | Set-Content $MPFolderFile

} 

Function Edit-SCOMMPViewsFolders
{


 While($True) {
 [int]$xMenuChoiceA = 0
 while ( $xMenuChoiceA -lt 1 -or $xMenuChoiceA -gt 3 ){
 Write-host "1. Create New View"
 Write-host "2. Create New Folder"
 Write-Host "3. Exit"

[Int]$xMenuChoiceA = read-host "Please enter an option 1 to 3..." }
 Switch( $xMenuChoiceA ){
   1{Add-SCOMMPView -MPViewFile $MPViewFile}
   2{Add-SCOMMPFolder -MPFolderFile $MPFolderFile}
   3{Return}
   }
 }
}

Function New-SCOMMPMonitorRule
{
Param (
[String]$MPMonitorRuleFile = $(Read-Host -Prompt "Where will the xml file be saved")
)
Add-Content $MPMonitorRuleFile "<ManagementPackFragment SchemaVersion=""2.0"" xmlns:xsd=""http://www.w3.org/2001/XMLSchema"">`n  <Monitoring>`n   <Rules>`n   </Rules>`n    <Monitors>`n </Monitors>`n</Monitoring>`n   <Presentation>`n    <StringResources>`n   </StringResources>`n  </Presentation>`n  <LanguagePacks>`n    <LanguagePack ID=""ENU"" IsDefault=""true"">`n      <DisplayStrings>`n      </DisplayStrings>`n    </LanguagePack>`n  </LanguagePacks>`n</ManagementPackFragment>"
}

Function New-SCOMMPCustomProbeAction
{

$MPCustomProbeActionFile = "$Filelocation\$ManagementPackName.CustomProbeActionFile.xml"
$MPCustomDataSourceFile = "$FileLocation\$ManagementPackName.CustomDataSourceFile.xml"
$MPCustomMonitorTypeFile = "$FileLocation\$ManagementPackName.CustomMonitorTypeFile.xml"

Add-Content $MPCustomProbeActionFile "<ManagementPackFragment SchemaVersion=""2.0"" xmlns:xsd=""http://www.w3.org/2001/XMLSchema"">`n  <TypeDefinitions>`n    <ModuleTypes>`n    </ModuleTypes>`n  </TypeDefinitions>`n</ManagementPackFragment>"
Add-Content $MPCustomDataSourceFile "<ManagementPackFragment SchemaVersion=""2.0"" xmlns:xsd=""http://www.w3.org/2001/XMLSchema"">`n  <TypeDefinitions>`n    <ModuleTypes>`n    </ModuleTypes>`n  </TypeDefinitions>`n</ManagementPackFragment>"
Add-Content $MPCustomMonitorTypeFile "<ManagementPackFragment SchemaVersion=""2.0"" xmlns:xsd=""http://www.w3.org/2001/XMLSchema"">`n  <TypeDefinitions>`n    <MonitorTypes>`n    </MonitorTypes>`n  </TypeDefinitions>`n</ManagementPackFragment>"
}

Function Add-SCOMMPCustomProbeAction
{
Param (
[String]$CustomModuleName = $(Read-Host "Name of your custom probe data source"),
[String]$MonitorTarget = $(Write-Host ""; $ClassesDetection = ((Get-Content $MPClassFile) -match "<DisplayString ElementID" -notmatch "SubElementID") -replace "<DisplayString ElementID=""", "" -replace """", "" -replace ">", ""
  ;Write-Host "Class that your custom probe will connect to"; For($i=0;$i -le $ClassesDetection.Count -1; $i++) {Write-Host $i. $ClassesDetection[$i].trim()}; Read-Host -Prompt "Select Option - if wanting to use a generic target such as WindowsComputer then type full Target Name"),
[String]$RunAsAccount = $(Write-Host ""; $RunAsAccountDetection = ((Get-Content $MPClassFile) -match "<DisplayString ElementID" -notmatch "SubElementID") -replace "<DisplayString ElementID=""", "" -replace """", "" -replace ">", ""
  ;Write-Host "Choose Run As Account"; For($i=0;$i -le $RunAsAccountDetection.Count -1; $i++) {Write-Host $i. $RunAsAccountDetection[$i].trim()}; Read-Host -Prompt "Select Option - if you dont wish to use a RunAs Account then leave blank"),
[String]$AlertName = $(Read-Host -Prompt "Name of the Alert"),
[String]$AlertMessage = $(Read-Host -Prompt "Alert message to display"),
[String]$TimeoutSeconds = $(Read-Host "Timeout Seconds")
)


$MPCustomProbeActionFile = "$Filelocation\$ManagementPackName.CustomProbeActionFile.xml"
$MPCustomDataSourceFile = "$FileLocation\$ManagementPackName.CustomDataSourceFile.xml"
$MPCustomMonitorTypeFile = "$FileLocation\$ManagementPackName.CustomMonitorTypeFile.xml"

   # Sets Monitor Target
  For($i=0;$i -le $ClassesDetection.Count -1; $i++) {
   If ($MonitorTarget -eq $i) {$MonitorTarget = $ClassesDetection[$i].trim()}}

        # Sets Run As Account
  For($i=0;$i -le $RunAsAccountDetection.Count -1; $i++) {
   If ($RunAsAccount -eq $i) {$RunAsAccount = $RunAsAccountDetection[$i].trim()}}


# Write PowerShell Script Template
$Instance = "$" + "instance"
$SourceID = "$" + "sourceid"
$ManagedEntityId = "$" + "managedEntityId"
$Computername = "$" + "computerName"
$api = "$" + "api"
$testsuccessful = "$" + "testsuccessful"
$bag = "$" + "bag"
$IncludeFileContent = "$" + "IncludeFileContent"
$ScriptName = "$FileLocation\$ManagementPackName.TimedPSScript.ps1"
$MPID = $ManagementPackName -replace " ","."
$PSScriptName = "$MPID.TimedPSScript.ps1"

Add-Content $ScriptName "param($computerName)`n$api = new-object -comObject 'MOM.ScriptAPI'`n$api.LogScriptEvent('$PSScriptName',20,4,$computername)`n$bag = $api.CreatePropertybag()`n$bag.AddValue('ComputerName',$Computername)`n <InsertScriptLogicHere>`n If ($testsuccessful -eq $true)`n {$bag.AddValue('Result','Good')}`n else`n {$bag.AddValue('Result','Bad')}`n $bag"

Write-Host "Edit the PowerShell script to contain your script portion for the custom probe when you attach a monitor to it. Start from under the $bag.Add Value line" -ForegroundColor Yellow
Write-Host "There is an IF statement containing a variable called $Testusccessful which can be replaced with anything but is used to verify if there is an error for an alert to be generated or healthy for an alert to be closed" -ForegroundColor Yellow

# Wrties variable values which are specific to Visual Studios
$Target = "$" + "Target"
$Config = "$" + "Config"
$ID = $ManagementPackName -replace " ","."
$ProbeActionModuleID = "$ID.ProbeAction.PowerShellScript"
$DataSourceModuleID = "$ID.DataSource.PowerShellScript"
$UnitMonitorTypeID = "$ID.MonitorType"
$ClassContent = Get-Content $MPCustomProbeActionFile

# Write Probe Module Type
$FindModuleTypesLine = Select-String $MPCustomProbeActionFile -pattern "</ModuleTypes>" | ForEach-Object {$_.LineNumber -2}
$ClassContent[$FindModuleTypesLine] += "`n      <ProbeActionModuleType ID=""$ProbeActionModuleID"" Accessibility=""Internal"" Batching=""false"" PassThrough=""false"" RunAs=""$RunAsAccount"">`n        <Configuration>`n          <xsd:element minOccurs=""1"" name=""ComputerName"" type=""xsd:string"" />`n        </Configuration>`n        <ModuleImplementation Isolation=""Any"">`n          <Composite>`n            <MemberModules>`n              <ProbeAction ID=""PSScript"" TypeID=""Windows!Microsoft.Windows.PowerShellPropertyBagProbe"">`n               <ScriptName>$PSScriptName</ScriptName>`n                <ScriptBody>$IncludeFileContent/$PSScriptName$</ScriptBody>`n                 <Parameters>`n                  <Parameter>`n                    <Name>ComputerName</Name>`n                    <Value>$Config/ComputerName$</Value>`n                  </Parameter>`n                 </Parameters>`n                 <TimeoutSeconds>$TimeoutSeconds</TimeoutSeconds>`n               </ProbeAction>`n            </MemberModules>`n            <Composition>`n              <Node ID=""PSScript"" />`n            </Composition>`n          </Composite>`n        </ModuleImplementation>`n        <OutputType>System!System.PropertyBagData</OutputType>`n        <InputType>System!System.BaseData</InputType>`n      </ProbeActionModuleType>"
$ClassContent | Set-Content $MPCustomProbeActionFile
#$ClassContent[$FindModuleTypesLine] += "`n      <DataSourceModuleType ID=""$CustomModuleID"" Accessibility=""Internal"" Batching=""false"" RunAs=""$RunAsAccount"">`n              <Configuration>`n              </Configuration>`n          <xsd:element minOccurs=""1"" name=""IntervalSeconds"" type=""xsd:integer"" />`n          <xsd:element minOccurs=""0"" name=""SyncTime"" type=""xsd:string"" />`n          <xsd:element minOccurs=""1"" name=""ComputerName"" type=""xsd:string"" />`n        </Configuration>              <OverrideableParameters>`n          <OverrideableParameter ID=""IntervalSeconds"" Selector=""$Config/IntervalSeconds$"" ParameterType=""int"" />`n          <OverrideableParameter ID=""SyncTime"" Selector=""$Config/SyncTime$"" ParameterType=""string"" />                </OverrideableParameters>`n                <ModuleImplementation Isolation=""Any"">`n                  <Composite>`n                    <MemberModules>`n                      <DataSource ID=""Schedule"" TypeID=""System!System.SimpleScheduler"">`n                      `n<IntervalSeconds>$Config/IntervalSeconds$</IntervalSeconds>`n                <SyncTime>$SyncTime</SyncTime>`n              </DataSource>`n              <ProbeAction ID=""Probe"" TypeID=""$CustomModuleID"">`n                <ComputerName>$Config/ComputerName$</ComputerName>`n              </ProbeAction>`n            </MemberModules>`n            <Composition>`n              <Node ID=""Probe"">`n                <Node ID=""Schedule"" />`n              </Node>`n            </Composition>`n          </Composite>`n        </ModuleImplementation>`n        <OutputType>System!System.PropertyBagData</OutputType>`n      </DataSourceModuleType>`n      <ProbeActionModuleType ID=""$CustomModuleID"" Accessibility=""Internal"" Batching=""false"" PassThrough=""false"" RunAs=""$RunAsAccount"">`n        <Configuration>`n          <xsd:element minOccurs=""1"" name=""ComputerName"" type=""xsd:string"" />`n        </Configuration>`n        <ModuleImplementation Isolation=""Any"">`n          <Composite>`n            <MemberModules>`n              <ProbeAction ID=""PSScript"" TypeID=""Windows!Microsoft.Windows.PowerShellPropertyBagProbe"">`n               <ScriptName>$PSScriptName</ScriptName>`n                `n<ScriptBody>$IncludeFileContent/$PSScriptName</ScriptBody>`n                 <Parameters>`n                  <Parameter>`n                    <Name>ComputerName</Name>`n                    <Value>$Config/ComputerName$</Value>`n                  </Parameter>`n                 </Parameters>`n                 <TimeoutSeconds>$TimeoutSeconds</TimeoutSeconds>`n               </ProbeAction>`n            </MemberModules>`n            <Composition>`n              <Node ID=""PSScript"" />`n            </Composition>`n          </Composite>`n        </ModuleImplementation>`n        <OutputType>System!System.PropertyBagData</OutputType>`n        <InputType>System!System.BaseData</InputType>`n      </ProbeActionModuleType>`n    </ModuleTypes>`n     <MonitorTypes>`n       <UnitMonitorType ID=""$CustomModuleID"" Accessibility=""Internal"" RunAs=""$RunAsAccount"">`n         <MonitorTypeStates>`n           <MonitorTypeState ID=""Success"" NoDetection=""false""/>`n           <MonitorTypeState ID=""Failure"" NoDetection=""false""/>`n         </MonitorTypeStates>`n         <Configuration>`n           <xsd:element minOccurs=""1"" name=""ComputerName"" type=""xsd.string"" />`n           <xsd:element minOccurs=""1"" name=""IntervalSeconds"" type=""xsd.integer"" />`n           <xsd:element minOccurs=""1"" name=""SyncTime"" type=""xsd.string"" />`n         </Configuration>`n         <OverrideableParameters>`n           <OverrideableParameter ID=""IntervalSeconds"" Selector=""$Config/IntervalSeconds$"" ParameterType=""int""/>`n         </OverrideableParameters>`n         <MonitorImplementation>`n           <MemberModules>`n             <DataSource ID=""DataSource"" TypeID=""$CustomModuleID"">`n               <IntervalSeconds>$Config/IntervalSeconds$</IntervalSeconds>`n               <SyncTime>$Config/SyncTime$</SyncTime>`n               <ComputerName>$Config/ComputerName$</ComputerName>`n             </DataSource>`n             <ProbeAction ID=""PassThru"" TypeID=""System!System.PassThroughProbe"" />`n             <ProbeAction ID=""Probe"" TypeID=""$CustomModuleID"">`n               <ComputerName>$Config/ComputerName$</ComputerName>`n             </ProbeAction>`n               <ConditionDetection ID=""FilterSuccess"" TypeID=""System!System.ExpressionFilter"">`n               <Expression>`n                 <SimpleExpression>`n                   <ValueExpression>`n                     <XPathQuery Type=""String"">Property[@Name='Result']</XPathQuery>`n                   </ValueExpression>`n                   <Operator>Equal</Operator>`n                   <ValueExpression>`n                     <Value Type=""String"">Good</Value>`n                   </ValueExpression>`n                 </SimpleExpression>`n               </Expression>`n             </ConditionDetection>`n<ConditionDetection ID=""FilterFailure"" TypeID=""System!System.ExpressionFilter"">`n               <Expression>`n                 <SimpleExpression>`n                   <ValueExpression>`n                     <XPathQuery Type=""String"">Property[@Name='Result']</XPathQuery>`n                   </ValueExpression>`n                   <Operator>Equal</Operator>`n                   <ValueExpression>`n                     <Value Type=""String"">Bad</Value>`n                   </ValueExpression>`n                 </SimpleExpression>`n               </Expression>`n             </ConditionDetection>`n           </MemberModules>`n           <RegularDetections>`n             <RegularDetection MonitorTypeStateID=""Success"">`n               <Node ID=""FilterSuccess"">`n                 <Node ID=""DataSource"" />`n               </Node>`n             </RegularDetection>`n             <RegularDetection MonitorTypeStateID=""Failure"">`n               <Node ID=""FilterFailure"">`n                 <Node ID=""DataSource"" />`n               </Node>`n             </RegularDetection>`n           </RegularDetections>`n           <OnDemandDetections>`n             <OnDemandDetection MonitorTypeStateID=""Success"">`n               <Node ID=""FilterSuccess"">`n                 <Node ID=""Probe"">`n                   <Node ID=""PassThru"" />`n                 </Node>`n               </Node>`n             </OnDemandDetection>`n             <OnDemandDetection MonitorTypeStateID=""Failure"">`n               <Node ID=""FilterFailure"">`n                 <Node ID=""Probe"">`n                   <Node ID=""PassThru"" />`n                 </Node>`n               </Node>`n             </OnDemandDetection>`n           </OnDemandDetections>`n         </MonitorImplementation>`n       </UnitMonitorType>`n     </MonitorTypes>"

# Load DataSource XML File
$ClassContent = Get-Content $MPCustomDataSourceFile

# Write Data Source Module Type
$FindModuleTypesLine = Select-String $MPCustomDataSourceFile -pattern "</ModuleTypes>" | ForEach-Object {$_.LineNumber -2}
$ClassContent[$FindModuleTypesLine] += "`n<DataSourceModuleType ID=""$DataSourceModuleID"" Accessibility=""Internal"" Batching=""false"" RunAs=""$RunAsAccount"">`n              <Configuration>`n              <xsd:element minOccurs=""1"" name=""IntervalSeconds"" type=""xsd:integer"" />`n          <xsd:element minOccurs=""0"" name=""SyncTime"" type=""xsd:string"" />`n          <xsd:element minOccurs=""1"" name=""ComputerName"" type=""xsd:string"" />`n        </Configuration>`n              <OverrideableParameters>`n          <OverrideableParameter ID=""IntervalSeconds"" Selector=""$Config/IntervalSeconds$"" ParameterType=""int"" />`n          <OverrideableParameter ID=""SyncTime"" Selector=""$Config/SyncTime$"" ParameterType=""string"" />`n                </OverrideableParameters>`n                <ModuleImplementation Isolation=""Any"">`n                  <Composite>`n                    <MemberModules>`n                      <DataSource ID=""Schedule"" TypeID=""System!System.SimpleScheduler"">`n                      <IntervalSeconds>$Config/IntervalSeconds$</IntervalSeconds>`n                <SyncTime>$SyncTime</SyncTime>`n              </DataSource>`n              <ProbeAction ID=""Probe"" TypeID=""$ProbeActionModuleID"">`n                <ComputerName>$Config/ComputerName$</ComputerName>`n              </ProbeAction>`n            </MemberModules>`n            <Composition>`n              <Node ID=""Probe"">`n                <Node ID=""Schedule"" />`n              </Node>`n            </Composition>`n          </Composite>`n        </ModuleImplementation>`n        <OutputType>System!System.PropertyBagData</OutputType>`n      </DataSourceModuleType>"
$ClassContent | Set-Content $MPCustomDataSourceFile

# Load Unit Montior Type File
$ClassContent = Get-Content $MPCustomMonitorTypeFile

# Write Unit Monitor Type File
$FindMonitorTypesLine = Select-String $MPCustomMonitorTypeFile -pattern "</MonitorTypes>" | ForEach-Object {$_.LineNumber -2}
$ClassContent[$FindMonitorTypesLine] += "`n       <UnitMonitorType ID=""$UnitMonitorTypeID"" Accessibility=""Internal"" RunAs=""$RunAsAccount"">`n         <MonitorTypeStates>`n           <MonitorTypeState ID=""Success"" NoDetection=""false""/>`n           <MonitorTypeState ID=""Failure"" NoDetection=""false""/>`n         </MonitorTypeStates>`n         <Configuration>`n           <xsd:element minOccurs=""1"" name=""ComputerName"" type=""xsd:string"" />`n           <xsd:element minOccurs=""1"" name=""IntervalSeconds"" type=""xsd:integer"" />`n           <xsd:element minOccurs=""1"" name=""SyncTime"" type=""xsd:string"" />`n         </Configuration>`n         <OverrideableParameters>`n           <OverrideableParameter ID=""IntervalSeconds"" Selector=""$Config/IntervalSeconds$"" ParameterType=""int""/>`n          <OverrideableParameter ID=""SyncTime"" Selector=""$Config/SyncTime$"" ParameterType=""string""/>`n         </OverrideableParameters>`n         <MonitorImplementation>`n           <MemberModules>`n             <DataSource ID=""DataSource"" TypeID=""$DataSourceModuleID"">`n               <IntervalSeconds>$Config/IntervalSeconds$</IntervalSeconds>`n               <SyncTime>$Config/SyncTime$</SyncTime>`n               <ComputerName>$Config/ComputerName$</ComputerName>`n             </DataSource>`n             <ProbeAction ID=""PassThru"" TypeID=""System!System.PassThroughProbe"" />`n             <ProbeAction ID=""Probe"" TypeID=""$ProbeActionModuleID"">`n               <ComputerName>$Config/ComputerName$</ComputerName>`n             </ProbeAction>`n               <ConditionDetection ID=""FilterSuccess"" TypeID=""System!System.ExpressionFilter"">`n               <Expression>`n                 <SimpleExpression>`n                   <ValueExpression>`n                     <XPathQuery Type=""String"">Property[@Name='Result']</XPathQuery>`n                   </ValueExpression>`n                   <Operator>Equal</Operator>`n                   <ValueExpression>`n                     <Value Type=""String"">Good</Value>`n                   </ValueExpression>`n                 </SimpleExpression>`n               </Expression>`n             </ConditionDetection>`n<ConditionDetection ID=""FilterFailure"" TypeID=""System!System.ExpressionFilter"">`n               <Expression>`n                 <SimpleExpression>`n                   <ValueExpression>`n                     <XPathQuery Type=""String"">Property[@Name='Result']</XPathQuery>`n                   </ValueExpression>`n                   <Operator>Equal</Operator>`n                   <ValueExpression>`n                     <Value Type=""String"">Bad</Value>`n                   </ValueExpression>`n                 </SimpleExpression>`n               </Expression>`n             </ConditionDetection>`n           </MemberModules>`n           <RegularDetections>`n             <RegularDetection MonitorTypeStateID=""Success"">`n               <Node ID=""FilterSuccess"">`n                 <Node ID=""DataSource"" />`n               </Node>`n             </RegularDetection>`n             <RegularDetection MonitorTypeStateID=""Failure"">`n               <Node ID=""FilterFailure"">`n                 <Node ID=""DataSource"" />`n               </Node>`n             </RegularDetection>`n           </RegularDetections>`n           <OnDemandDetections>`n             <OnDemandDetection MonitorTypeStateID=""Success"">`n               <Node ID=""FilterSuccess"">`n                 <Node ID=""Probe"">`n                   <Node ID=""PassThru"" />`n                 </Node>`n               </Node>`n             </OnDemandDetection>`n             <OnDemandDetection MonitorTypeStateID=""Failure"">`n               <Node ID=""FilterFailure"">`n                 <Node ID=""Probe"">`n                   <Node ID=""PassThru"" />`n                 </Node>`n               </Node>`n             </OnDemandDetection>`n           </OnDemandDetections>`n         </MonitorImplementation>`n       </UnitMonitorType>"
$ClassContent | Set-Content $MPCustomMonitorTypeFile

# Write Monitor to monitor file
$MonitorName = "$ManagementPackName PSScriptMonitor"
$MonitorEnabled = "true"
$MonitorRunAsAccount = $RunAsAccount
$AlertOnState = "Error"
$AlertPriority = "Normal"
$IntervalSeconds = "300"
$MonitorID = $MonitorName -replace " ", "."
$AlertMessageID = "$MonitorID.AlertMessage"
$Target = "$" + "Target"
$Data = "$" + "Data"
$ClassContent = Get-Content $MPMonitorRuleFile

# Write Monitor
$FindMonitorsLine = Select-String $MPMonitorRuleFile -pattern "</Monitors>" | ForEach-Object {$_.LineNumber -2}
$ClassContent[$FindMonitorsLine] += "`n      <UnitMonitor ID=""$MonitorID"" Accessibility=""Internal"" Enabled=""$MonitorEnabled"" Target=""$MonitorTarget"" ParentMonitorID=""Health!System.Health.AvailabilityState"" Remotable=""true"" Priority=""Normal"" TypeID=""$UnitMonitorTypeID"" ConfirmDelivery=""false"" RunAs=""$MonitorRunAsAccount"">`n        <Category>PerformanceHealth</Category>`n        <AlertSettings AlertMessage=""$AlertMessageID"">`n          <AlertOnState>$AlertOnState</AlertOnState>`n          <AutoResolve>true</AutoResolve>`n          <AlertPriority>$AlertPriority</AlertPriority>`n          <AlertSeverity>MatchMonitorHealth</AlertSeverity>`n        </AlertSettings>`n        <OperationalStates>`n          <OperationalState ID=""Success"" MonitorTypeStateID=""Success"" HealthState=""Success"" />`n          <OperationalState ID=""Failure"" MonitorTypeStateID=""Failure"" HealthState=""Error"" />`n        </OperationalStates>`n        <Configuration>`n          <ComputerName>$Target/Host/Property[Type=""Windows!Microsoft.Windows.Computer""]/PrincipalName$</ComputerName>`n          <IntervalSeconds>$IntervalSeconds</IntervalSeconds>`n          <SyncTime />`n        </Configuration>`n      </UnitMonitor>"
$ClassContent | Set-Content $MPMonitorRuleFile

# Reload XML File
$ClassContent = Get-Content $MPMonitorRuleFile

# Write String Resources
$FindStringResourcesLine = Select-String $MPMonitorRuleFile -pattern "</StringResources>" | ForEach-Object {$_.LineNumber -2}
$ClassContent[$FindStringResourcesLine] += "`n<StringResource ID=""$AlertMessageID"" />"
$ClassContent | Set-Content $MPMonitorRuleFile

# Reload XML File
$ClassContent = Get-Content $MPMonitorRuleFile

# Write display strings
$FindLastDisplayStringLine = Select-String $MPMonitorRuleFile -pattern "</DisplayStrings>" | ForEach-Object {$_.LineNumber -2}
$ClassContent[$FindLastDisplayStringLine] += "`n    <DisplayString ElementID=""$MonitorID"">`n     <Name>$MonitorName</Name>`n     <Description>$MonitorDescription</Description>`n    </DisplayString>`n    <DisplayString ElementID=""$AlertMessageID"">`n     <Name>$AlertName</Name>`n     <Description>$AlertMessage</Description>`n    </DisplayString>`n    <DisplayString ElementID=""$MonitorID"" SubElementID=""Success"">`n     <Name>Success</Name>`n     <Description>Success</Description>`n    </DisplayString>`n    <DisplayString ElementID=""$MonitorID"" SubElementID=""Failure"">`n     <Name>Failure</Name>`n     <Description>Failure</Description>`n    </DisplayString>"
$ClassContent | Set-Content $MPMonitorRuleFile

}

Function Add-SCOMMPWindowsEventMonitor
{
Param (
[String]$MonitorName = $(Read-Host -Prompt "Name of the Monitor"),
[String]$MonitorEnabled = $(Read-Host -Prompt "Is the Monitor enabled (true or false in lowercase)"),
[String]$MonitorTarget = $(Write-Host ""; $ClassesDetection = ((Get-Content $MPClassFile) -match "<DisplayString ElementID" -notmatch "SubElementID") -replace "<DisplayString ElementID=""", "" -replace """", "" -replace ">", ""
  ;Write-Host "Monitor Target"; For($i=0;$i -le $ClassesDetection.Count -1; $i++) {Write-Host $i. $ClassesDetection[$i].trim()}; Read-Host -Prompt "Select Option - if wanting to use a generic target such as WindowsComputer then type full Target Name"),
[String]$MonitorRunAsAccount = $(Write-Host ""; $RunAsAccountDetection = ((Get-Content $MPClassFile) -match "<DisplayString ElementID" -notmatch "SubElementID") -replace "<DisplayString ElementID=""", "" -replace """", "" -replace ">", ""
  ;Write-Host "Run As Account"; For($i=0;$i -le $RunAsAccountDetection.Count -1; $i++) {Write-Host $i. $RunAsAccountDetection[$i].trim()}; Read-Host -Prompt "Select Option - if you dont wish to use a RunAs Account then leave blank"),
[String]$AlertOnState = $(Read-Host -Prompt "What health status should the monitor alert on? Error or Warning"),
[String]$AlertPriority = $(Read-Host -Prompt "Alert Priority - High, Normal or Low"),
[String]$AlertSeverity = $(Read-Host -Prompt "Alert Severity (Error or Warning)"),
[String]$AlertName = $(Read-Host -Prompt "Name of the Alert"),
#[String]$AlertMessage = $(Read-Host -Prompt "Alert message to display"),
[String]$UnhealthyLogName = $(Read-Host -Prompt "Name of Unhealthy Event log"),
[String]$UnhealthyEventDisplayNumber = $(Read-Host -Prompt "Unhealthy EventID Number"),
[String]$UnhealthyPublisherName = $(Read-Host -Prompt "Name of Unhealthy Source"),
[String]$HealthyLogName = $(Read-Host -Prompt "Name of healthy Event log"),
[String]$HealthyEventDisplayNumber = $(Read-Host -Prompt "healthy EventID Number"),
[String]$HealthyPublisherName = $(Read-Host -Prompt "Name of healthy Source"),
[String]$MPMonitorRuleFile = $(Read-Host -Prompt "Where will the xml file be saved")
)
 
 # Sets Monitor Target
 If ($MonitorTarget -eq "WindowsComputer") {$MonitorTarget = "Windows!Microsoft.Windows.ComputerRole"}
 If ($MonitorTarget -eq "WindowsApplicationComponent") {$MonitorTarget = "Windows!Microsoft.Windows.ApplicationComponent"}
 If ($MonitorTarget -eq "WindowsLocalApplication") {$MonitorTarget = "Windows!Microsoft.Windows.LocalApplication"}
 If ($MonitorTarget -eq "UnixComputer") {$MonitorTarget = "Unix!Microsoft.Unix.ComputerRole"}
 If ($MonitorTarget -eq "ComputerGroup") {$MonitorTarget = "SC!Microsoft.SystemCenter.ComputerGroup"}
 If ($MonitorTarget -eq "InstanceGroup") {$MonitorTarget = "SCIG!Microsoft.SystemCenter.InstanceGroup"}

   # Sets Monitor Target
  For($i=0;$i -le $ClassesDetection.Count -1; $i++) {
   If ($MonitorTarget -eq $i) {$MonitorTarget = $ClassesDetection[$i].trim()}}

        # Sets Run As Account
  For($i=0;$i -le $RunAsAccountDetection.Count -1; $i++) {
   If ($MonitorRunAsAccount -eq $i) {$MonitorRunAsAccount = $RunAsAccountDetection[$i].trim()}}

# Wrties variable values which are specific to Visual Studios
$Target = "$" + "Target"
$Data = "$" + "Data"
$ClassContent = Get-Content $MPMonitorRuleFile
$MonitorID = $MonitorName -replace " ", "."
$AlertMessageID = "$MonitorID.AlertMessage"

# Write Monitor
$FindMonitorsLine = Select-String $MPMonitorRuleFile -pattern "</Monitors>" | ForEach-Object {$_.LineNumber -2}
$ClassContent[$FindMonitorsLine] += "`n      <UnitMonitor ID=""$MonitorID"" Accessibility=""Internal"" Enabled=""$MonitorEnabled"" Target=""$MonitorTarget"" ParentMonitorID=""Health!System.Health.AvailabilityState"" Remotable=""true"" Priority=""Normal"" TypeID=""Windows!Microsoft.Windows.2SingleEventLog2StateMonitorType"" ConfirmDelivery=""false"" RunAs=""$MonitorRunAsAccount"">`n        <Category>AvailabilityHealth</Category>`n        <AlertSettings AlertMessage=""$AlertMessageID"">`n          <AlertOnState>$AlertOnState</AlertOnState>`n          <AutoResolve>true</AutoResolve>`n          <AlertPriority>$AlertPriority</AlertPriority>`n          <AlertSeverity>MatchMonitorHealth</AlertSeverity>`n          <AlertParameters>`n            <!--To add additional parameters for this monitor copy the XML line underneath as AlertParameter2-->`n            <!--If needing more variables delete ""EventDescription"" and replace with PublisherName/EventSourceName/Channel/LoggingComputer/EventNumer/EventCategory as examples-->`n            <!--To display in alert message find the AlertMessageID below in the DisplayStrings section and add the AlertParameter number in brackets for example {0] is AlertParameter1 and upwards-->            <AlertParameter1>$Data/Context/EventDescription$</AlertParameter1>`n          </AlertParameters>`n          </AlertSettings>`n        <OperationalStates>`n          <OperationalState ID=""FirstEventRaised"" MonitorTypeStateID=""FirstEventRaised"" HealthState=""$AlertSeverity"" />`n          <OperationalState ID=""SecondEventRaised"" MonitorTypeStateID=""SecondEventRaised"" HealthState=""Success"" />`n        </OperationalStates>`n        <Configuration>`n          <FirstComputerName>$Target/Host/Property[Type=""Windows!Microsoft.Windows.Computer""]/NetworkName$</FirstComputerName>`n          <FirstLogName>$UnhealthyLogName</FirstLogName>`n          <FirstExpression>`n            <And>`n              <Expression>`n                <SimpleExpression>`n                  <ValueExpression>`n                    <XPathQuery Type=""UnsignedInteger"">EventDisplayNumber</XPathQuery> `n                  </ValueExpression>`n                  <Operator>Equal</Operator>`n                  <ValueExpression>`n                    <Value Type=""UnsignedInteger"">$UnhealthyEventDisplayNumber</Value>`n                  </ValueExpression>`n                </SimpleExpression>`n              </Expression>`n              <Expression>`n                <SimpleExpression>`n                  <ValueExpression>`n                    <XPathQuery Type=""String"">PublisherName</XPathQuery>`n                  </ValueExpression>`n                  <Operator>Equal</Operator>`n                  <ValueExpression>`n                    <Value Type=""String"">$UnhealthyPublisherName</Value>`n                  </ValueExpression>`n                </SimpleExpression>`n              </Expression>`n              <Expression>`n              </Expression>`n            </And>`n          </FirstExpression>`n          <SecondComputerName>$Target/Host/Property[Type=""Windows!Microsoft.Windows.Computer""]/NetworkName$</SecondComputerName>`n          <SecondLogName>$HealthyLogName</SecondLogName>`n          <SecondExpression>`n            <And>`n              <Expression>`n                <SimpleExpression>`n                  <ValueExpression>`n                    <XPathQuery Type=""UnsignedInteger"">EventDisplayNumber</XPathQuery>`n                  </ValueExpression>`n                  <Operator>Equal</Operator>`n                  <ValueExpression>`n                    <Value Type=""UnsignedInteger"">$HealthyEventDisplayNumber</Value>`n                  </ValueExpression>`n                </SimpleExpression>`n              </Expression>`n              <Expression>`n                <SimpleExpression>`n                  <ValueExpression>`n                    <XPathQuery Type=""String"">PublisherName</XPathQuery>`n                  </ValueExpression>`n                  <Operator>Equal</Operator>`n                  <ValueExpression>`n                    <Value Type=""String"">$HealthyPublisherName</Value>`n                  </ValueExpression>`n                </SimpleExpression>`n              </Expression>`n              <Expression>`n              </Expression>`n            </And>`n          </SecondExpression>`n        </Configuration>`n      </UnitMonitor>"
$ClassContent | Set-Content $MPMonitorRuleFile

# Reload XML File
$ClassContent = Get-Content $MPMonitorRuleFile

# Write String Resources
$FindStringResourcesLine = Select-String $MPMonitorRuleFile -pattern "</StringResources>" | ForEach-Object {$_.LineNumber -2}
$ClassContent[$FindStringResourcesLine] += "`n<StringResource ID=""$AlertMessageID"" />"
$ClassContent | Set-Content $MPMonitorRuleFile

# Reload XML File 
$ClassContent = Get-Content $MPMonitorRuleFile

# Write display strings
$FindLastDisplayStringLine = Select-String $MPMonitorRuleFile -pattern "</DisplayStrings>" | ForEach-Object {$_.LineNumber -2}
$ClassContent[$FindLastDisplayStringLine] += "`n    <DisplayString ElementID=""$MonitorID"">`n     <Name>$MonitorName</Name>`n     <Description>$MonitorDescription</Description>`n    </DisplayString>`n    <DisplayString ElementID=""$AlertMessageID"">`n     <Name>$AlertName</Name>`n     <Description>Event Description: {0}</Description>`n    </DisplayString>`n    <DisplayString ElementID=""$MonitorID"" SubElementID=""FirstEventRaised"">`n     <Name>FirstEventRaised</Name>`n     <Description>FirstEventRaised</Description>`n    </DisplayString>`n    <DisplayString ElementID=""$MonitorID"" SubElementID=""SecondEventRaised"">`n     <Name>SecondEventRaised</Name>`n     <Description>SecondEventRaised</Description>`n    </DisplayString>"
$ClassContent | Set-Content $MPMonitorRuleFile

}

Function Add-SCOMMPWindowsServiceMonitor
{
Param (
[String]$MonitorName = $(Read-Host -Prompt "Name of the Monitor"),
[String]$MonitorEnabled = $(Read-Host -Prompt "Is the Monitor enabled (true or false in lowercase)"),
[String]$MonitorTarget = $(Write-Host ""; $ClassesDetection = ((Get-Content $MPClassFile) -match "<DisplayString ElementID" -notmatch "SubElementID") -replace "<DisplayString ElementID=""", "" -replace """", "" -replace ">", ""
  ;Write-Host "Monitor Target"; For($i=0;$i -le $ClassesDetection.Count -1; $i++) {Write-Host $i. $ClassesDetection[$i].trim()}; Read-Host -Prompt "Select Option - if wanting to use a generic target such as WindowsComputer then type full Target Name"),
[String]$MonitorRunAsAccount = $(Write-Host ""; $RunAsAccountDetection = ((Get-Content $MPClassFile) -match "<DisplayString ElementID" -notmatch "SubElementID") -replace "<DisplayString ElementID=""", "" -replace """", "" -replace ">", ""
  ;Write-Host "Run As Account"; For($i=0;$i -le $RunAsAccountDetection.Count -1; $i++) {Write-Host $i. $RunAsAccountDetection[$i].trim()}; Read-Host -Prompt "Select Option - if you dont wish to use a RunAs Account then leave blank"),
[String]$AlertOnState = $(Read-Host -Prompt "What health status should the monitor alert on? Error or Warning"),
[String]$AlertName = $(Read-Host -Prompt "Name of the Alert"),
[String]$AlertMessage = $(Read-Host -Prompt "Alert message to display"),
[String]$AlertPriority = $(Read-Host -Prompt "Alert Priority - High, Normal or Low"),
[String]$AlertSeverity = $(Read-Host -Prompt "Alert Severity (Error or Warning)"),
[String]$ServiceName = $(Read-Host -Prompt "Name of the service to be monitored i.e. Use Get-Service or command line to get service name abbreviation"),
[String]$AlertOnAuto = $(Read-Host -Prompt "Alert only if service is automatic - true or false"),
[String]$MPMonitorRuleFile = $(Read-Host -Prompt "Where will the xml file be saved")
)


# Sets Monitor Target
If ($MonitorTarget -eq "All Windows Computers") {$MonitorTarget = "SystemCenter!Microsoft.SystemCenter.AllComputersGroup"}

   # Sets Monitor Target
  For($i=0;$i -le $ClassesDetection.Count -1; $i++) {
   If ($MonitorTarget -eq $i) {$MonitorTarget = $ClassesDetection[$i].trim()}}

        # Sets Run As Account
  For($i=0;$i -le $RunAsAccountDetection.Count -1; $i++) {
   If ($MonitorRunAsAccount -eq $i) {$MonitorRunAsAccount = $RunAsAccountDetection[$i].trim()}}

# Wrties variable values which are specific to Visual Studios
$Target = "$" + "Target"
$Data = "$" + "Data"
$ClassContent = Get-Content $MPMonitorRuleFile
$MonitorID = $MonitorName -replace " ", "."
$AlertMessageID = "$MonitorID.AlertMessage"

# Write Monitor
$FindMonitorsLine = Select-String $MPMonitorRuleFile -pattern "</Monitors>" | ForEach-Object {$_.LineNumber -2}
$ClassContent[$FindMonitorsLine] += "`n      <UnitMonitor ID=""$MonitorID"" Accessibility=""Internal"" Enabled=""$MonitorEnabled"" Target=""$MonitorTarget"" ParentMonitorID=""Health!System.Health.AvailabilityState"" Remotable=""true"" Priority=""Normal"" TypeID=""Windows!Microsoft.Windows.CheckNTServiceStateMonitorType"" ConfirmDelivery=""false"" RunAs=""$MonitorRunAsAccount"">`n        <Category>AvailabilityHealth</Category>`n        <AlertSettings AlertMessage=""$AlertMessageID"">`n          <AlertOnState>$AlertOnState</AlertOnState>`n          <AutoResolve>true</AutoResolve>`n          <AlertPriority>$AlertPriority</AlertPriority>`n          <AlertSeverity>MatchMonitorHealth</AlertSeverity>`n          <AlertParameters>`n            <AlertParameter1>$Target/Host/Property[Type=""Windows!Microsoft.Windows.Computer""]/NetworkName$</AlertParameter1>`n          </AlertParameters>`n                  </AlertSettings>`n        <OperationalStates>`n          <OperationalState ID=""FirstEventRaised"" MonitorTypeStateID=""Running"" HealthState=""Success"" />`n          <OperationalState ID=""SecondEventRaised"" MonitorTypeStateID=""NotRunning"" HealthState=""Error"" />`n        </OperationalStates>`n        <Configuration>`n          <ComputerName>$Target/Host/Property[Type=""Windows!Microsoft.Windows.Computer""]/NetworkName$</ComputerName>`n          <ServiceName>$ServiceName</ServiceName>`n          <CheckStartupType>$AlertonAuto</CheckStartupType>`n        </Configuration>`n      </UnitMonitor>"
$ClassContent | Set-Content $MPMonitorRuleFile

# Reload XML File
$ClassContent = Get-Content $MPMonitorRuleFile

# Write String Resources
$FindStringResourcesLine = Select-String $MPMonitorRuleFile -pattern "</StringResources>" | ForEach-Object {$_.LineNumber -2}
$ClassContent[$FindStringResourcesLine] += "`n<StringResource ID=""$AlertMessageID"" />"
$ClassContent | Set-Content $MPMonitorRuleFile

# Reload XML File
$ClassContent = Get-Content $MPMonitorRuleFile

# Write display strings
$FindLastDisplayStringLine = Select-String $MPMonitorRuleFile -pattern "</DisplayStrings>" | ForEach-Object {$_.LineNumber -2}
$ClassContent[$FindLastDisplayStringLine] += "`n    <DisplayString ElementID=""$MonitorID"">`n     <Name>$MonitorName</Name>`n     <Description>$MonitorDescription</Description>`n    </DisplayString>`n    <DisplayString ElementID=""$AlertMessageID"">`n     <Name>$AlertName</Name>`n     <Description>$AlertMessage</Description>`n    </DisplayString>`n    <DisplayString ElementID=""$MonitorID"" SubElementID=""FirstEventRaised"">`n     <Name>FirstEventRaised</Name>`n     <Description>FirstEventRaised</Description>`n    </DisplayString>`n    <DisplayString ElementID=""$MonitorID"" SubElementID=""SecondEventRaised"">`n     <Name>SecondEventRaised</Name>`n     <Description>SecondEventRaised</Description>`n    </DisplayString>"
$ClassContent | Set-Content $MPMonitorRuleFile

}

Function Add-SCOMMPWindowsServiceCPUPerformanceMonitor
{
Param (
[String]$MonitorName = $(Read-Host -Prompt "Name of the Monitor"),
[String]$MonitorEnabled = $(Read-Host -Prompt "Is the Monitor enabled (true or false in lowercase)"),
[String]$MonitorTarget = $(Write-Host ""; $ClassesDetection = ((Get-Content $MPClassFile) -match "<DisplayString ElementID" -notmatch "SubElementID") -replace "<DisplayString ElementID=""", "" -replace """", "" -replace ">", ""
  ;Write-Host "Monitor Target"; For($i=0;$i -le $ClassesDetection.Count -1; $i++) {Write-Host $i. $ClassesDetection[$i].trim()}; Read-Host -Prompt "Select Option - if wanting to use a generic target such as WindowsComputer then type full Target Name"),
[String]$MonitorRunAsAccount = $(Write-Host ""; $RunAsAccountDetection = ((Get-Content $MPClassFile) -match "<DisplayString ElementID" -notmatch "SubElementID") -replace "<DisplayString ElementID=""", "" -replace """", "" -replace ">", ""
  ;Write-Host "Run As Account"; For($i=0;$i -le $RunAsAccountDetection.Count -1; $i++) {Write-Host $i. $RunAsAccountDetection[$i].trim()}; Read-Host -Prompt "Select Option - if you dont wish to use a RunAs Account then leave blank"),
[String]$AlertOnState = $(Read-Host -Prompt "What health status should the monitor alert on? Error or Warning"),
[String]$AlertName = $(Read-Host -Prompt "Name of the Alert"),
[String]$AlertMessage = $(Read-Host -Prompt "Alert message to display"),
[String]$AlertPriority = $(Read-Host -Prompt "Alert Priority - High, Normal or Low"),
[String]$AlertSeverity = $(Read-Host -Prompt "Alert Severity (Error or Warning)"),
[String]$AlertOnAuto = $(Read-Host -Prompt "Alert only if service is automatic - true or false"),
[String]$ServiceName = $(Read-Host -Prompt "Name of the service to be monitored i.e. Use Get-Service or command line to get service name abbreviation"),
[String]$Frequency = $(Read-Host -Prompt "Frequency in seconds where it will check the performance"),
[String]$Threshold = $(Read-Host -Prompt "Threshold limit in percentage"),
[String]$NumSamples = $(Read-Host -Prompt "Number of samples to compare with"),
[String]$MPMonitorRuleFile = $(Read-Host -Prompt "Where will the xml file be saved")
)

   # Sets Monitor Target
  For($i=0;$i -le $ClassesDetection.Count -1; $i++) {
   If ($MonitorTarget -eq $i) {$MonitorTarget = $ClassesDetection[$i].trim()}}

        # Sets Run As Account
  For($i=0;$i -le $RunAsAccountDetection.Count -1; $i++) {
   If ($MonitorRunAsAccount -eq $i) {$MonitorRunAsAccount = $RunAsAccountDetection[$i].trim()}}

# Wrties variable values which are specific to Visual Studios
$Target = "$" + "Target"
$Data = "$" + "Data"
$ClassContent = Get-Content $MPMonitorRuleFile
$MonitorID = $MonitorName -replace " ", "."
$AlertMessageID = "$MonitorID.AlertMessage"

# Write Monitor
$FindMonitorsLine = Select-String $MPMonitorRuleFile -pattern "</Monitors>" | ForEach-Object {$_.LineNumber -2}
$ClassContent[$FindMonitorsLine] += "`n      <UnitMonitor ID=""$MonitorID"" Accessibility=""Internal"" Enabled=""$MonitorEnabled"" Target=""$MonitorTarget"" ParentMonitorID=""Health!System.Health.PerformanceState"" Remotable=""true"" Priority=""Normal"" TypeID=""MSNL!Microsoft.SystemCenter.NTService.ConsecutiveSamplesThreshold.ErrorOnTooHigh"" ConfirmDelivery=""false"" RunAs=""$MonitorRunAsAccount"">`n        <Category>PerformanceHealth</Category>`n        <AlertSettings AlertMessage=""$AlertMessageID"">`n          <AlertOnState>$AlertOnState</AlertOnState>`n          <AutoResolve>true</AutoResolve>`n          <AlertPriority>$AlertPriority</AlertPriority>`n          <AlertSeverity>MatchMonitorHealth</AlertSeverity>`n          <AlertParameters>`n                        <AlertParameter1>$Target/Host/Property[Type=""Windows!Microsoft.Windows.Computer""]/NetworkName$</AlertParameter1>`n          </AlertParameters>`n                  </AlertSettings>`n        <OperationalStates>`n          <OperationalState ID=""OK"" MonitorTypeStateID=""SampleCountNormal"" HealthState=""Success"" />`n          <OperationalState ID=""Error"" MonitorTypeStateID=""SampleCountTooHigh"" HealthState=""Error"" />`n        </OperationalStates>`n        <Configuration>`n          <ServiceName>$ServiceName</ServiceName>`n          <ObjectName>Process</ObjectName>`n          <CounterName>Percent Processor Time</CounterName>`n          <InstanceProperty>Name</InstanceProperty>`n          <ValueProperty>PercentProcessorTime</ValueProperty>`n          <Frequency>$Frequency</Frequency>`n          <ScaleBy>$Target/Host/Property[Type=""Windows!Microsoft.Windows.Computer""]/LogicalProcessors$</ScaleBy>`n          <Threshold>$Threshold</Threshold>`n          <NumSamples>$NumSamples</NumSamples>`n        </Configuration>`n      </UnitMonitor>"
$ClassContent | Set-Content $MPMonitorRuleFile

# Reload XML File
$ClassContent = Get-Content $MPMonitorRuleFile

# Write String Resources
$FindStringResourcesLine = Select-String $MPMonitorRuleFile -pattern "</StringResources>" | ForEach-Object {$_.LineNumber -2}
$ClassContent[$FindStringResourcesLine] += "`n<StringResource ID=""$AlertMessageID"" />"
$ClassContent | Set-Content $MPMonitorRuleFile

# Reload XML File
$ClassContent = Get-Content $MPMonitorRuleFile

# Write display strings
$FindLastDisplayStringLine = Select-String $MPMonitorRuleFile -pattern "</DisplayStrings>" | ForEach-Object {$_.LineNumber -2}
$ClassContent[$FindLastDisplayStringLine] += "`n    <DisplayString ElementID=""$MonitorID"">`n     <Name>$MonitorName</Name>`n     <Description>$MonitorDescription</Description>`n    </DisplayString>`n    <DisplayString ElementID=""$AlertMessageID"">`n     <Name>$AlertName</Name>`n     <Description>$AlertMessage</Description>`n    </DisplayString>`n    <DisplayString ElementID=""$MonitorID"" SubElementID=""OK"">`n     <Name>SampleCountNormal</Name>`n     <Description>SampleCountNormal</Description>`n    </DisplayString>`n    <DisplayString ElementID=""$MonitorID"" SubElementID=""Error"">`n     <Name>SampleCountTooHigh</Name>`n     <Description>SampleCountTooHigh</Description>`n    </DisplayString>"
$ClassContent | Set-Content $MPMonitorRuleFile


}

Function Add-SCOMMPWindowsServiceMemoryPerformanceMonitor
{
Param (
[String]$MonitorName = $(Read-Host -Prompt "Name of the Monitor"),
[String]$MonitorEnabled = $(Read-Host -Prompt "Is the Monitor enabled (true or false in lowercase)"),
[String]$MonitorTarget = $(Write-Host ""; $ClassesDetection = ((Get-Content $MPClassFile) -match "<DisplayString ElementID" -notmatch "SubElementID") -replace "<DisplayString ElementID=""", "" -replace """", "" -replace ">", ""
  ;Write-Host "Monitor Target"; For($i=0;$i -le $ClassesDetection.Count -1; $i++) {Write-Host $i. $ClassesDetection[$i].trim()}; Read-Host -Prompt "Select Option - if wanting to use a generic target such as WindowsComputer then type full Target Name"),
[String]$MonitorRunAsAccount = $(Write-Host ""; $RunAsAccountDetection = ((Get-Content $MPClassFile) -match "<DisplayString ElementID" -notmatch "SubElementID") -replace "<DisplayString ElementID=""", "" -replace """", "" -replace ">", ""
  ;Write-Host "Run As Account"; For($i=0;$i -le $RunAsAccountDetection.Count -1; $i++) {Write-Host $i. $RunAsAccountDetection[$i].trim()}; Read-Host -Prompt "Select Option - if you dont wish to use a RunAs Account then leave blank"),
[String]$AlertOnState = $(Read-Host -Prompt "What health status should the monitor alert on? Error or Warning"),
[String]$AlertName = $(Read-Host -Prompt "Name of the Alert"),
[String]$AlertMessage = $(Read-Host -Prompt "Alert message to display"),
[String]$AlertPriority = $(Read-Host -Prompt "Alert Priority - High, Normal or Low"),
[String]$AlertSeverity = $(Read-Host -Prompt "Alert Severity (Error or Warning)"),
[String]$AlertOnAuto = $(Read-Host -Prompt "Alert only if service is automatic - true or false"),
[String]$ServiceName = $(Read-Host -Prompt "Name of the service to be monitored i.e. Use Get-Service or command line to get service name abbreviation"),
[String]$Frequency = $(Read-Host -Prompt "Frequency in seconds where it will check the performance"),
[String]$Threshold = $(Read-Host -Prompt "Threshold limit in bytes"),
[String]$NumSamples = $(Read-Host -Prompt "Number of samples to compare with"),
[String]$MPMonitorRuleFile = $(Read-Host -Prompt "Where will the xml file be saved")
)

   # Sets Monitor Target
  For($i=0;$i -le $ClassesDetection.Count -1; $i++) {
   If ($MonitorTarget -eq $i) {$MonitorTarget = $ClassesDetection[$i].trim()}}

        # Sets Run As Account
  For($i=0;$i -le $RunAsAccountDetection.Count -1; $i++) {
   If ($MonitorRunAsAccount -eq $i) {$MonitorRunAsAccount = $RunAsAccountDetection[$i].trim()}}

# Wrties variable values which are specific to Visual Studios
$Target = "$" + "Target"
$Data = "$" + "Data"
$ClassContent = Get-Content $MPMonitorRuleFile
$MonitorID = $MonitorName -replace " ", "."
$AlertMessageID = "$MonitorID.AlertMessage"

# Write Monitor
$FindMonitorsLine = Select-String $MPMonitorRuleFile -pattern "</Monitors>" | ForEach-Object {$_.LineNumber -2}
$ClassContent[$FindMonitorsLine] += "`n      <UnitMonitor ID=""$MonitorID"" Accessibility=""Internal"" Enabled=""$MonitorEnabled"" Target=""$MonitorTarget"" ParentMonitorID=""Health!System.Health.PerformanceState"" Remotable=""true"" Priority=""Normal"" TypeID=""MSNL!Microsoft.SystemCenter.NTService.ConsecutiveSamplesThreshold.ErrorOnTooHigh"" ConfirmDelivery=""false"" RunAs=""$MonitorRunAsAccount"">`n        <Category>PerformanceHealth</Category>`n        <AlertSettings AlertMessage=""$AlertMessageID"">`n          <AlertOnState>$AlertOnState</AlertOnState>`n          <AutoResolve>true</AutoResolve>`n          <AlertPriority>$AlertPriority</AlertPriority>`n          <AlertSeverity>MatchMonitorHealth</AlertSeverity>`n          <AlertParameters>`n                        <AlertParameter1>$Target/Host/Property[Type=""Windows!Microsoft.Windows.Computer""]/NetworkName$</AlertParameter1>`n          </AlertParameters>`n                  </AlertSettings>`n        <OperationalStates>`n          <OperationalState ID=""OK"" MonitorTypeStateID=""SampleCountNormal"" HealthState=""Success"" />`n          <OperationalState ID=""Error"" MonitorTypeStateID=""SampleCountTooHigh"" HealthState=""Error"" />`n        </OperationalStates>`n        <Configuration>`n          <ServiceName>$ServiceName</ServiceName>`n          <ObjectName>Process</ObjectName>`n          <CounterName>Private Bytes</CounterName>`n          <InstanceProperty>Name</InstanceProperty>`n          <ValueProperty>PrivateBytes</ValueProperty>`n          <Frequency>$Frequency</Frequency>`n          <ScaleBy>$Target/Host/Property[Type=""Windows!Microsoft.Windows.Computer""]/LogicalProcessors$</ScaleBy>`n          <Threshold>$Threshold</Threshold>`n          <NumSamples>$NumSamples</NumSamples>`n        </Configuration>`n      </UnitMonitor>"
$ClassContent | Set-Content $MPMonitorRuleFile

# Reload XML File
$ClassContent = Get-Content $MPMonitorRuleFile

# Write String Resources
$FindStringResourcesLine = Select-String $MPMonitorRuleFile -pattern "</StringResources>" | ForEach-Object {$_.LineNumber -2}
$ClassContent[$FindStringResourcesLine] += "`n<StringResource ID=""$AlertMessageID"" />"
$ClassContent | Set-Content $MPMonitorRuleFile

# Reload XML File
$ClassContent = Get-Content $MPMonitorRuleFile

# Write display strings
$FindLastDisplayStringLine = Select-String $MPMonitorRuleFile -pattern "</DisplayStrings>" | ForEach-Object {$_.LineNumber -2}
$ClassContent[$FindLastDisplayStringLine] += "`n    <DisplayString ElementID=""$MonitorID"">`n     <Name>$MonitorName</Name>`n     <Description>$MonitorDescription</Description>`n    </DisplayString>`n    <DisplayString ElementID=""$AlertMessageID"">`n     <Name>$AlertName</Name>`n     <Description>$AlertMessage</Description>`n    </DisplayString>`n    <DisplayString ElementID=""$MonitorID"" SubElementID=""OK"">`n     <Name>SampleCountNormal</Name>`n     <Description>SampleCountNormal</Description>`n    </DisplayString>`n    <DisplayString ElementID=""$MonitorID"" SubElementID=""Error"">`n     <Name>SampleCountTooHigh</Name>`n     <Description>SampleCountTooHigh</Description>`n    </DisplayString>"
$ClassContent | Set-Content $MPMonitorRuleFile


}

Function Add-SCOMMPWindowsGenericLogMonitor
{
Param (
[String]$MonitorName = $(Read-Host -Prompt "Name of the Monitor"),
[String]$MonitorEnabled = $(Read-Host -Prompt "Is the Monitor enabled (true or false in lowercase)"),
[String]$MonitorTarget = $(Write-Host ""; $ClassesDetection = ((Get-Content $MPClassFile) -match "<DisplayString ElementID" -notmatch "SubElementID") -replace "<DisplayString ElementID=""", "" -replace """", "" -replace ">", ""
  ;Write-Host "Monitor Target"; For($i=0;$i -le $ClassesDetection.Count -1; $i++) {Write-Host $i. $ClassesDetection[$i].trim()}; Read-Host -Prompt "Select Option - if wanting to use a generic target such as WindowsComputer then type full Target Name"),
[String]$MonitorRunAsAccount = $(Write-Host ""; $RunAsAccountDetection = ((Get-Content $MPClassFile) -match "<DisplayString ElementID" -notmatch "SubElementID") -replace "<DisplayString ElementID=""", "" -replace """", "" -replace ">", ""
  ;Write-Host "Run As Account"; For($i=0;$i -le $RunAsAccountDetection.Count -1; $i++) {Write-Host $i. $RunAsAccountDetection[$i].trim()}; Read-Host -Prompt "Select Option - if you dont wish to use a RunAs Account then leave blank"),
[String]$AlertOnState = $(Read-Host -Prompt "What health status should the monitor alert on? Error or Warning"),
[String]$AlertName = $(Read-Host -Prompt "Name of the Alert"),
[String]$AlertMessage = $(Read-Host -Prompt "Alert message to display"),
[String]$AlertPriority = $(Read-Host -Prompt "Alert Priority - High, Normal or Low"),
[String]$AlertSeverity = $(Read-Host -Prompt "Alert Severity (Error or Warning)"),
[String]$LogFileDirectory = $(Read-Host -Prompt "Location of the Log files"),
[String]$LogPattern = $(Read-Host -Prompt "File extension or log file name - use wildcards if wanting to monitor more than one"),
[String]$LogIsUTF8 = $(Read-Host -Prompt "Is the log file a UTF8 log - true or false"),
[String]$ErrorMessagePattern = $(Read-Host -Prompt "Error code or message to look for "),
[String]$MPMonitorRuleFile = $(Read-Host -Prompt "Where will the xml file be saved")
)

   # Sets Monitor Target
  For($i=0;$i -le $ClassesDetection.Count -1; $i++) {
   If ($MonitorTarget -eq $i) {$MonitorTarget = $ClassesDetection[$i].trim()}}
     # Sets Run As Account
  For($i=0;$i -le $RunAsAccountDetection.Count -1; $i++) {
   If ($MonitorRunAsAccount -eq $i) {$MonitorRunAsAccount = $RunAsAccountDetection[$i].trim()}}

# Wrties variable values which are specific to Visual Studios
$Target = "$" + "Target"
$Data = "$" + "Data"
$ClassContent = Get-Content $MPMonitorRuleFile
$MonitorID = $MonitorName -replace " ", "."
$AlertMessageID = "$MonitorID.AlertMessage"

# Write Monitor
$FindMonitorsLine = Select-String $MPMonitorRuleFile -pattern "</Monitors>" | ForEach-Object {$_.LineNumber -2}
$ClassContent[$FindMonitorsLine] += "`n      <UnitMonitor ID=""$MonitorID"" Accessibility=""Internal"" Enabled=""$MonitorEnabled"" Target=""$MonitorTarget"" ParentMonitorID=""Health!System.Health.AvailabilityState"" Remotable=""true"" Priority=""Normal"" TypeID=""SAL!System.ApplicationLog.GenericLog.SingleEventManualReset2StateMonitorType"" ConfirmDelivery=""false"" RunAs=""$MonitorRunAsAccount"">`n        <Category>PerformanceHealth</Category>`n        <AlertSettings AlertMessage=""$AlertMessageID"">`n          <AlertOnState>$AlertOnState</AlertOnState>`n          <AutoResolve>true</AutoResolve>`n          <AlertPriority>$AlertPriority</AlertPriority>`n          <AlertSeverity>MatchMonitorHealth</AlertSeverity>`n</AlertSettings>`n        <OperationalStates>`n          <OperationalState ID=""Error"" MonitorTypeStateID=""EventRaised"" HealthState=""Error"" />`n          <OperationalState ID=""OK"" MonitorTypeStateID=""ManualResetEventRaised"" HealthState=""Success"" />`n        </OperationalStates>`n        <Configuration>`n          <LogFileDirectory>C:\ProgramData\Metron\Logs</LogFileDirectory>`n          <LogFilePattern>$LogPattern</LogFilePattern>`n          <LogIsUTF8>$LogIsUTF8</LogIsUTF8>`n          <Expression>`n            <RegExExpression>`n              <ValueExpression>`n                <XPathQuery Type=""String"">Params/Param[1]</XPathQuery>`n              </ValueExpression>`n              <Operator>ContainsSubstring</Operator>`n              <Pattern>$ErrorMessagePattern</Pattern>`n            </RegExExpression>`n          </Expression>`n          </Configuration>`n      </UnitMonitor>"
$ClassContent | Set-Content $MPMonitorRuleFile

# Reload XML File
$ClassContent = Get-Content $MPMonitorRuleFile

# Write String Resources
$FindStringResourcesLine = Select-String $MPMonitorRuleFile -pattern "</StringResources>" | ForEach-Object {$_.LineNumber -2}
$ClassContent[$FindStringResourcesLine] += "`n<StringResource ID=""$AlertMessageID"" />"
$ClassContent | Set-Content $MPMonitorRuleFile

# Reload XML File
$ClassContent = Get-Content $MPMonitorRuleFile

# Write display strings
$FindLastDisplayStringLine = Select-String $MPMonitorRuleFile -pattern "</DisplayStrings>" | ForEach-Object {$_.LineNumber -2}
$ClassContent[$FindLastDisplayStringLine] += "`n    <DisplayString ElementID=""$MonitorID"">`n     <Name>$MonitorName</Name>`n     <Description>$MonitorDescription</Description>`n    </DisplayString>`n    <DisplayString ElementID=""$AlertMessageID"">`n     <Name>$AlertName</Name>`n     <Description>$AlertMessage</Description>`n    </DisplayString>`n    <DisplayString ElementID=""$MonitorID"" SubElementID=""Error"">`n     <Name>EventRaised</Name>`n     <Description>EventRaised</Description>`n    </DisplayString>`n    <DisplayString ElementID=""$MonitorID"" SubElementID=""OK"">`n     <Name>ManualEventRaised</Name>`n     <Description>ManualEventRaised</Description>`n    </DisplayString>"
$ClassContent | Set-Content $MPMonitorRuleFile

}

Function Add-SCOMMPPerformanceMonitor
{
Param (
[String]$MonitorName = $(Read-Host -Prompt "Name of the Monitor"),
[String]$MonitorEnabled = $(Read-Host -Prompt "Is the Monitor enabled (true or false in lowercase)"),
[String]$MonitorTarget = $(Write-Host ""; $ClassesDetection = ((Get-Content $MPClassFile) -match "<DisplayString ElementID" -notmatch "SubElementID") -replace "<DisplayString ElementID=""", "" -replace """", "" -replace ">", ""
  ;Write-Host "Monitor Target"; For($i=0;$i -le $ClassesDetection.Count -1; $i++) {Write-Host $i. $ClassesDetection[$i].trim()}; Read-Host -Prompt "Select Option - if wanting to use a generic target such as WindowsComputer then type full Target Name"),
[String]$MonitorRunAsAccount = $(Write-Host ""; $RunAsAccountDetection = ((Get-Content $MPClassFile) -match "<DisplayString ElementID" -notmatch "SubElementID") -replace "<DisplayString ElementID=""", "" -replace """", "" -replace ">", ""
  ;Write-Host "Run As Account"; For($i=0;$i -le $RunAsAccountDetection.Count -1; $i++) {Write-Host $i. $RunAsAccountDetection[$i].trim()}; Read-Host -Prompt "Select Option - if you dont wish to use a RunAs Account then leave blank"),
[String]$ComputerName = $(Read-Host -Prompt "Computer name variable"),
[String]$CounterName = $(Read-Host -Prompt "Name of performance counter"),
[String]$ObjectName = $(Read-Host -Prompt "Name of performance object"),
[String]$InstanceName = $(Read-Host -Prompt "Instance property"),
[String]$AllInstances = $(Read-Host -Prompt "All Instances - true or false"),
[String]$Frequency = $(Read-Host -Prompt "Frequency"),
[String]$Threshold = $(Read-Host -Prompt "Threshold percentage value"),
[String]$AlertOnState = $(Read-Host -Prompt "What health status should the monitor alert on? Error or Warning"),
#[String]$AlertMessage = $(Read -Host -Prompt "Alert message"),
[String]$AlertPriority = $(Read-Host -Prompt "Alert Priority - High, Normal or Low"),
[String]$AlertSeverity = $(Read-Host -Prompt "Alert Severity (Error or Warning)"),
[String]$MPMonitorRuleFile = $(Read-Host -Prompt "Where will the xml file be saved"))


   # Sets Monitor Target
  For($i=0;$i -le $ClassesDetection.Count -1; $i++) {
   If ($MonitorTarget -eq $i) {$MonitorTarget = $ClassesDetection[$i].trim()}}

        # Sets Run As Account
  For($i=0;$i -le $RunAsAccountDetection.Count -1; $i++) {
   If ($MonitorRunAsAccount -eq $i) {$MonitorRunAsAccount = $RunAsAccountDetection[$i].trim()}}

# Wrties variable values which are specific to Visual Studios
$Target = "$" + "Target"
$Data = "$" + "Data"
$MonitorID = $MonitorName -replace " ", "."
$AlertMessageID = "$MonitorID.AlertMessage"
$ClassContent = Get-Content $MPMonitorRuleFile

# Write Monitor
$FindMonitorsLine = Select-String $MPMonitorRuleFile -pattern "</Monitors>" | ForEach-Object {$_.LineNumber -2}
$ClassContent[$FindMonitorsLine] += "`n      <UnitMonitor ID=""$MonitorID"" Accessibility=""Internal"" Enabled=""$MonitorEnabled"" Target=""$MonitorTarget"" ParentMonitorID=""Health!System.Health.PerformanceState"" Remotable=""true"" Priority=""Normal"" TypeID=""Performance!System.Performance.ThresholdMonitorType"" ConfirmDelivery=""false"" RunAs=""$MonitorRunAsAccount"">`n        <Category>PerformanceHealth</Category>`n        <AlertSettings AlertMessage=""$AlertMessageID"">`n          <AlertOnState>$AlertOnState</AlertOnState>`n          <AutoResolve>true</AutoResolve>`n          <AlertPriority>$AlertPriority</AlertPriority>`n          <AlertSeverity>MatchMonitorHealth</AlertSeverity>`n          <AlertParameters>`n            <AlertParameter1>$Data[Default='']/Context/InstanceName$</AlertParameter1>`n            <AlertParameter2>$Data[Default='']/Context/ObjectName$</AlertParameter2>`n            <AlertParameter3>$Data[Default='']/Context/CounterName$</AlertParameter3>`n            <AlertParameter4>$Data[Default='']/Context/Value$</AlertParameter4>`n            <AlertParameter5>$Data[Default='']/Context/TimeSampled$</AlertParameter5>`n          </AlertParameters>`n                  </AlertSettings>`n        <OperationalStates>`n          <OperationalState ID=""OK"" MonitorTypeStateID=""UnderThreshold"" HealthState=""Success"" />`n          <OperationalState ID=""Error"" MonitorTypeStateID=""OverThreshold"" HealthState=""Error"" />`n        </OperationalStates>`n        <Configuration>`n          <ComputerName>$ComputerName</ComputerName>`n          <CounterName>$CounterName</CounterName>`n          <ObjectName>$Objectname</ObjectName>`n          <InstanceName>$InstanceName</InstanceName>`n          <AllInstances>$AllInstances</AllInstances>`n          <Frequency>$Frequency</Frequency>`n          <Threshold>$Threshold</Threshold>`n          </Configuration>`n      </UnitMonitor>"
$ClassContent | Set-Content $MPMonitorRuleFile

# Reload XML File
$ClassContent = Get-Content $MPMonitorRuleFile

# Write String Resources
$FindStringResourcesLine = Select-String $MPMonitorRuleFile -pattern "</StringResources>" | ForEach-Object {$_.LineNumber -2}
$ClassContent[$FindStringResourcesLine] += "`n<StringResource ID=""$AlertMessageID"" />"
$ClassContent | Set-Content $MPMonitorRuleFile

# Reload XML File
$ClassContent = Get-Content $MPMonitorRuleFile

# Write display strings
$FindLastDisplayStringLine = Select-String $MPMonitorRuleFile -pattern "</DisplayStrings>" | ForEach-Object {$_.LineNumber -2}
$ClassContent[$FindLastDisplayStringLine] += "`n    <DisplayString ElementID=""$MonitorID"">`n     <Name>$MonitorName</Name>`n     <Description>$MonitorDescription</Description>`n    </DisplayString>`n    <DisplayString ElementID=""$AlertMessageID"">`n     <Name>$AlertName</Name>`n     <Description>Instance Name: {0}`n Object Name {1}`n Counter Name: {2}`n Value: {3}`n Time Sampled: {4}</Description>`n    </DisplayString>`n    <DisplayString ElementID=""$MonitorID"" SubElementID=""OK"">`n     <Name>UnderThreshold</Name>`n     <Description>UnderThreshold</Description>`n    </DisplayString>`n    <DisplayString ElementID=""$MonitorID"" SubElementID=""Error"">`n     <Name>OverThreshold</Name>`n     <Description>OverThreshold</Description>`n    </DisplayString>"
$ClassContent | Set-Content $MPMonitorRuleFile
}

Function Add-SCOMMPWindowsEventRule
{
Param (
[String]$RuleName = $(Read-Host -Prompt "Name of the Rule"),
[String]$RuleEnabled = $(Read-Host -Prompt "Is the rule enabled"),
[String]$RuleTarget = $(Write-Host ""; $ClassesDetection = ((Get-Content $MPClassFile) -match "<DisplayString ElementID" -notmatch "SubElementID") -replace "<DisplayString ElementID=""", "" -replace """", "" -replace ">", ""
  ;Write-Host "Rule Target"; For($i=0;$i -le $ClassesDetection.Count -1; $i++) {Write-Host $i. $ClassesDetection[$i].trim()}; Read-Host -Prompt "Select Option - if wanting to use a generic target such as WindowsComputer then type full Target Name"),
#[String]$RuleType = $(Read-Host -Prompt "Rule type"),
[String]$RuleRunAsAccount = $(Write-Host ""; $RunAsAccountDetection = ((Get-Content $MPClassFile) -match "<DisplayString ElementID" -notmatch "SubElementID") -replace "<DisplayString ElementID=""", "" -replace """", "" -replace ">", ""
  ;Write-Host "Run As Account"; For($i=0;$i -le $RunAsAccountDetection.Count -1; $i++) {Write-Host $i. $RunAsAccountDetection[$i].trim()}; Read-Host -Prompt "Select Option - if you dont wish to use a RunAs Account then leave blank"),
[String]$LogName = $(Read-Host -Prompt "Name of Event log"),
[String]$EventDisplayNumber = $(Read-Host -Prompt "EventID Number"),
[String]$PublisherName = $(Read-Host -Prompt "Name of Source"),
[String]$AlertName = $(Read-Host -Prompt "Name of the Alert"),
#[String]$AlertMessage = $(Read-Host -Prompt "Alert message to display"),
[String]$Priority = $(Read-Host -Prompt "Priority Level (1 = high, 2 = Normal, 3 = Low"),
[String]$Severity = $(Read-Host -Prompt "Severity Level (1 = Critical, 2 = Warning, 3 = Information"),
[String]$MPMonitorRuleFile = $(Read-Host -Prompt "Where will the xml file be saved")
)

 # Sets Rule Target
 If ($RuleTarget -eq "WindowsComputer") {$RuleTarget = "Windows!Microsoft.Windows.ComputerRole"}
 If ($RuleTarget -eq "WindowsApplicationComponent") {$RuleTarget = "Windows!Microsoft.Windows.ApplicationComponent"}
 If ($RuleTarget -eq "WindowsLocalApplication") {$RuleTarget = "Windows!Microsoft.Windows.LocalApplication"}
 If ($RuleTarget -eq "UnixComputer") {$RuleTarget = "Unix!Microsoft.Unix.ComputerRole"}
 If ($RuleTarget -eq "ComputerGroup") {$RuleTarget = "SC!Microsoft.SystemCenter.ComputerGroup"}
 If ($RuleTarget -eq "InstanceGroup") {$RuleTarget = "SCIG!Microsoft.SystemCenter.InstanceGroup"}

    # Sets Rule Target
  For($i=0;$i -le $ClassesDetection.Count -1; $i++) {
   If ($RuleTarget -eq $i) {$RuleTarget = $ClassesDetection[$i].trim()}}

     # Sets Run As Account
  For($i=0;$i -le $RunAsAccountDetection.Count -1; $i++) {
   If ($RuleRunAsAccount -eq $i) {$RuleRunAsAccount = $RunAsAccountDetection[$i].trim()}}

# Wrties variable values which are specific to Visual Studios
$Data = "$" + "Data"
$MPElement = "$" + "MPElement"
$RuleID = $RuleName -replace " ", "."
$AlertMessageID = "$RuleID.AlertMessage"
$ClassContent = Get-Content $MPMonitorRuleFile

# Write Rule
$FindRulesLine = Select-String $MPMonitorRuleFile -pattern "</Rules>" | ForEach-Object {$_.LineNumber -2}
$ClassContent[$FindRulesLine] += "`n      <Rule ID=""$RuleID"" Target=""$RuleTarget"" Enabled=""$RuleEnabled"" ConfirmDelivery=""false"" Remotable=""true"" Priority=""Normal"" DiscardLevel=""100"">`n        <Category>Alert</Category>`n        <DataSources>`n          <DataSource ID=""DS"" TypeID=""Windows!Microsoft.Windows.EventProvider"" RunAs=""$RuleRunAsAccount"">`n             <LogName>$LogName</LogName>`n            <Expression>`n              <And>`n                <Expression>`n                  <SimpleExpression>`n                    <ValueExpression>`n                      <XPathQuery>Channel</XPathQuery>`n                    </ValueExpression>`n                    <Operator>Equal</Operator>`n                    <ValueExpression>`n                      <Value>$LogName</Value>`n                    </ValueExpression>`n                  </SimpleExpression>`n                </Expression>`n                <Expression>`n                  <SimpleExpression>`n                    <ValueExpression>`n                      <XPathQuery>EventDisplayNumber</XPathQuery>`n                    </ValueExpression>`n                    <Operator>Equal</Operator>`n                    <ValueExpression>`n                      <Value>$EventDisplayNumber</Value>`n                    </ValueExpression>`n     </SimpleExpression>`n     </Expression>`n                <Expression>`n                  <SimpleExpression>`n                    <ValueExpression>`n                      <XPathQuery>PublisherName</XPathQuery>`n                    </ValueExpression>`n                    <Operator>Equal</Operator>`n                    <ValueExpression>`n                      <Value>$PublisherName</Value>`n                    </ValueExpression>`n                  </SimpleExpression>`n                </Expression>`n              </And>`n            </Expression>`n          </DataSource>`n        </DataSources>`n        <ConditionDetection ID=""CD"" TypeID=""System!System.ExpressionFilter"" RunAs=""$RuleRunAsAccount"">`n          <Expression>`n            <RegExExpression>`n              <ValueExpression>`n                <XPathQuery>PublisherName</XPathQuery>`n              </ValueExpression>`n              <Operator>MatchesRegularExpression</Operator>`n              <Pattern>$PublisherName</Pattern>`n            </RegExExpression>`n          </Expression>`n        </ConditionDetection>`n        <WriteActions>`n          <WriteAction ID=""Alert"" TypeID=""Health!System.Health.GenerateAlert"">`n            <Priority>$Priority</Priority>`n            <Severity>$Severity</Severity>`n            <AlertMessageId>$MPElement[Name=""$AlertMessageID""]$</AlertMessageId>`n            <AlertParameters>`n              <AlertParameter1>$Data/EventDescription$</AlertParameter1>`n            </AlertParameters>`n               <Suppression>`n              <SuppressionValue>$Data/EventDescription$</SuppressionValue>`n            </Suppression>`n          </WriteAction>`n        </WriteActions>`n      </Rule>"
$ClassContent | Set-Content $MPMonitorRuleFile

# Reload XML File
$ClassContent = Get-Content $MPMonitorRuleFile

# Write String Resources
$FindStringResourcesLine = Select-String $MPMonitorRuleFile -pattern "</StringResources>" | ForEach-Object {$_.LineNumber -2}
$ClassContent[$FindStringResourcesLine] += "`n<StringResource ID=""$AlertMessageID"" />"
$ClassContent | Set-Content $MPMonitorRuleFile

# Reload XML File
$ClassContent = Get-Content $MPMonitorRuleFile

# Write display strings
$FindLastDisplayStringLine = Select-String $MPMonitorRuleFile -pattern "</DisplayStrings>" | ForEach-Object {$_.LineNumber -2}
$ClassContent[$FindLastDisplayStringLine] += "`n    <DisplayString ElementID=""$RuleID"">`n     <Name>$RuleName</Name>`n     <Description></Description>`n    </DisplayString>`n    <DisplayString ElementID=""$AlertMessageID"">`n     <Name>$AlertName</Name>`n     <Description>Event Description: {0} </Description>`n    </DisplayString>"
$ClassContent | Set-Content $MPMonitorRuleFile


}

Function Add-SCOMMPWindowsPowerShellScriptRule
{
Param (
[String]$RuleName = $(Read-Host -Prompt "Name of the Rule"),
[String]$RuleDescription = $(Read-Host -Prompt "Description of the Rule"),
[String]$RuleEnabled = $(Read-Host -Prompt "Is the rule enabled"),
[String]$RuleTarget = $(Write-Host ""; $ClassesDetection = ((Get-Content $MPClassFile) -match "<DisplayString ElementID" -notmatch "SubElementID") -replace "<DisplayString ElementID=""", "" -replace """", "" -replace ">", ""
  ;Write-Host "Rule Target"; For($i=0;$i -le $ClassesDetection.Count -1; $i++) {Write-Host $i. $ClassesDetection[$i].trim()}; Read-Host -Prompt "Select Option - if wanting to use a generic target such as WindowsComputer then type full Target Name"),
[String]$RuleRunAsAccount = $(Write-Host ""; $RunAsAccountDetection = ((Get-Content $MPClassFile) -match "<DisplayString ElementID" -notmatch "SubElementID") -replace "<DisplayString ElementID=""", "" -replace """", "" -replace ">", ""
  ;Write-Host "Run As Account"; For($i=0;$i -le $RunAsAccountDetection.Count -1; $i++) {Write-Host $i. $RunAsAccountDetection[$i].trim()}; Read-Host -Prompt "Select Option - if you dont wish to use a RunAs Account then leave blank"),
[String]$AlertName = $(Read-Host -Prompt "Name of the Alert"),
[String]$AlertMessage = $(Read-Host -Prompt "Alert message to display"),
[String]$ScriptName = $(Read-Host -Prompt "Name of the PowerShell script"),
[String]$Priority = $(Read-Host -Prompt "Priority Level (1 = high, 2 = Normal, 3 = Low"),
[String]$Severity = $(Read-Host -Prompt "Severity Level (1 = Critical, 2 = Warning, 3 = Information"),
[String]$IntervalSeconds = $(Read-Host -Prompt "Interval Seconds"),
[Parameter(Mandatory=$false)][String]$SyncTime = $(Read-Host -Prompt "Sync Time. Leave blank if not needed"),
[String]$TimeoutSeconds = $(Read-Host -Prompt "Timeout Seconds"),
[String]$MPMonitorRuleFile = $(Read-Host -Prompt "Where will the xml file be saved")
)

 # Sets Rule Target
 If ($RuleTarget -eq "WindowsComputer") {$RuleTarget = "Windows!Microsoft.Windows.ComputerRole"}
 If ($RuleTarget -eq "WindowsApplicationComponent") {$RuleTarget = "Windows!Microsoft.Windows.ApplicationComponent"}
 If ($RuleTarget -eq "WindowsLocalApplication") {$RuleTarget = "Windows!Microsoft.Windows.LocalApplication"}
 If ($RuleTarget -eq "UnixComputer") {$RuleTarget = "Unix!Microsoft.Unix.ComputerRole"}
 If ($RuleTarget -eq "ComputerGroup") {$RuleTarget = "SC!Microsoft.SystemCenter.ComputerGroup"}
 If ($RuleTarget -eq "InstanceGroup") {$RuleTarget = "SCIG!Microsoft.SystemCenter.InstanceGroup"}

   # Sets Rule Target
  For($i=0;$i -le $ClassesDetection.Count -1; $i++) {
   If ($RuleTarget -eq $i) {$RuleTarget = $ClassesDetection[$i].trim()}}

  # Sets Run As Account
  For($i=0;$i -le $RunAsAccountDetection.Count -1; $i++) {
   If ($RuleRunAsAccount -eq $i) {$RuleRunAsAccount = $RunAsAccountDetection[$i].trim()}}

# Create PowerShell Script variables
$ScriptName = $ScriptName + ".ps1" -replace " ", "."
$RuleID = $RuleName -replace " ","."
$AlertMessageID = "$RuleID.AlertMessage"
$IncludeFileContent = "$" + "IncludeFileContent"
$ScriptBody = "$IncludeFileContent/$ScriptName$"
$ClassContent = Get-Content $MPMonitorRuleFile
Write-Host "Ensure to create your PowerShell script in Visual Studios which contains the same name you have entered" -ForegroundColor Yellow
Write-Host ""

# Write Rule
$FindRulesLine = Select-String $MPMonitorRuleFile -pattern "</Rules>" | ForEach-Object {$_.LineNumber -2}
$ClassContent[$FindRulesLine] += "`n      <Rule ID=""$RuleID"" Target=""$RuleTarget"" Enabled=""$RuleEnabled"" ConfirmDelivery=""false"" Remotable=""true"" Priority=""Normal"" DiscardLevel=""100"">`n        <Category>Alert</Category>`n        <DataSources>`n          <DataSource ID=""Scheduler"" TypeID=""System!System.Scheduler"" RunAs=""$RuleRunAsAccount"">`n      <Scheduler>`n        <SimpleReccuringSchedule>`n          <Interval>$IntervalSeconds</Interval>`n          <SyncTime>$SyncTime</SyncTime>`n      </SimpleReccuringSchedule>`n      <ExcludeDates />`n    </Scheduler></DataSource>`n        </DataSources>`n    <WriteActions>`n          <WriteAction ID=""ExecuteScript"" TypeID=""Windows!Microsoft.Windows.PowerShellPropertyBagWriteAction"">`n        <ScriptName>$ScriptName</ScriptName>`n        <ScriptBody>$ScriptBody</ScriptBody`n        <TimeoutSeconds>$TimeoutSeconds</TimeoutSeconds>`n      </WriteAction>`n        </WriteActions>`n      </Rule>"
$ClassContent | Set-Content $MPMonitorRuleFile

# Reload XML File
$ClassContent = Get-Content $MPMonitorRuleFile

# Write String Resources
$FindStringResourcesLine = Select-String $MPMonitorRuleFile -pattern "</StringResources>" | ForEach-Object {$_.LineNumber -2}
$ClassContent[$FindStringResourcesLine] += "`n<StringResource ID=""$AlertMessageID"" />"
$ClassContent | Set-Content $MPMonitorRuleFile

# Reload XML File
$ClassContent = Get-Content $MPMonitorRuleFile

# Write display strings
$FindLastDisplayStringLine = Select-String $MPMonitorRuleFile -pattern "</DisplayStrings>" | ForEach-Object {$_.LineNumber -2}
$ClassContent[$FindLastDisplayStringLine] += "`n    <DisplayString ElementID=""$RuleID"">`n     <Name>$RuleName</Name>`n     <Description>$RuleDescription</Description>`n    </DisplayString>`n    <DisplayString ElementID=""$AlertMessageID"">`n     <Name>$AlertName</Name>`n     <Description>$AlertMessage</Description>`n    </DisplayString>"
$ClassContent | Set-Content $MPMonitorRuleFile

} 

Function Add-SCOMMPPerformanceRule
{
PARAM (
[String]$RuleName = $(Read-Host -Prompt "Name of the Rule"),
[String]$RuleEnabled = $(Read-Host -Prompt "Is the rule enabled"),
[String]$RuleTarget = $(Write-Host ""; $ClassesDetection = ((Get-Content $MPClassFile) -match "<DisplayString ElementID" -notmatch "SubElementID") -replace "<DisplayString ElementID=""", "" -replace """", "" -replace ">", ""
  ;Write-Host "Rule Target"; For($i=0;$i -le $ClassesDetection.Count -1; $i++) {Write-Host $i. $ClassesDetection[$i].trim()}; Read-Host -Prompt "Select Option - if wanting to use a generic target such as WindowsComputer then type full Target Name"),
[String]$RuleRunAsAccount = $(Write-Host ""; $RunAsAccountDetection = ((Get-Content $MPClassFile) -match "<DisplayString ElementID" -notmatch "SubElementID") -replace "<DisplayString ElementID=""", "" -replace """", "" -replace ">", ""
  ;Write-Host "Run As Account"; For($i=0;$i -le $RunAsAccountDetection.Count -1; $i++) {Write-Host $i. $RunAsAccountDetection[$i].trim()}; Read-Host -Prompt "Select Option - if you dont wish to use a RunAs Account then leave blank"),
[String]$AlertName = $(Read-Host -Prompt "Name of the Alert"),
[String]$AlertMessage = $(Read-Host -Prompt "Alert message to display"),
[String]$ComputerName = $(Read-Host -Prompt "Computer name variable"),
[String]$CounterName = $(Read-Host -Prompt "Name of performance counter"),
[String]$ObjectName = $(Read-Host -Prompt "Name of performance object"),
[String]$AllInstances = $(Read-Host -Prompt "All Instances"),
[String]$Frequency = $(Read-Host -Prompt "Frequency"),
[String]$Threshold = $(Read-Host -Prompt "Threshold value"),
[String]$InstanceProperty = $(Read-Host -Prompt "Instance property"),
[String]$Tolerance = $(Read-Host -Prompt "Tolerance"),
[String]$MaxSampleSeparation = $(Read-Host -Prompt "Max Sample Separation value"),
[String]$MPMonitorRuleFile = $(Read-Host -Prompt "Where will the xml file be saved")
)

   # Sets Rule Target
  For($i=0;$i -le $ClassesDetection.Count -1; $i++) {
   If ($RuleTarget -eq $i) {$RuleTarget = $ClassesDetection[$i].trim()}}

  # Sets Run As Account
  For($i=0;$i -le $RunAsAccountDetection.Count -1; $i++) {
   If ($RuleRunAsAccount -eq $i) {$RuleRunAsAccount = $RunAsAccountDetection[$i].trim()}}

# Wrties variable values which are specific to Visual Studios
$Data = "$" + "Data"
$MPElement = "$" + "MPElement"
$RuleID = $RuleName -replace " ", "."
$AlertMessageID = "$RuleID.AlertMessage"
$ClassContent = Get-Content $MPMonitorRuleFile

# Write Rule
$FindRulesLine = Select-String $MPMonitorRuleFile -pattern "</Rules>" | ForEach-Object {$_.LineNumber -2}
$ClassContent[$FindRulesLine] += "`n      <Rule ID=""$RuleID"" Target=""$RuleTarget"" Enabled=""$RuleEnabled"" ConfirmDelivery=""false"" Remotable=""true"" Priority=""Normal"" DiscardLevel=""100"">`n        <Category>PerformanceCollection</Category>`n        <DataSources>`n          <DataSource ID=""DS"" TypeID=""Perf!System.Performance.OptimizedDataProvider"" RunAs=""$RuleRunAsAccount"">`n      <ComputerName>$ComputerName</ComputerName>`n          <CounterName>$Countername</CounterName>`n          <ObjectName>$ObjectName</ObjectName>`n          <InstanceName>$InstanceName</InstanceName>`n          <AllInstances>$AllInstances</AllInstances>`n          <Frequency>$Frequency</Frequency>`n          <Tolerance>$Tolerance</Tolerance>`n          <ToleranceType>Percentage</ToleranceType>`n          <MaximumSampleSeparation>$MaxSampleSeparation</MaximumSampleSeparation>`n        </DataSource>`n      </DataSources>`n              <WriteActions>`n          <WriteAction ID=""WriteToDB"" TypeID=""SC!Microsoft.SystemCenter.CollectPerformanceData"" />`n        <WriteAction ID=""WriteToDW"" TypeID=""MSDL!Microsoft.SystemCenter.DataWarehouse.PublishPerformanceData"" />`n             </WriteActions>`n      </Rule>"
$ClassContent | Set-Content $MPMonitorRuleFile

# Reload XML File
$ClassContent = Get-Content $MPMonitorRuleFile

# Write String Resources
$FindStringResourcesLine = Select-String $MPMonitorRuleFile -pattern "</StringResources>" | ForEach-Object {$_.LineNumber -2}
$ClassContent[$FindStringResourcesLine] += "`n<StringResource ID=""$AlertMessageID"" />"
$ClassContent | Set-Content $MPMonitorRuleFile

# Reload XML File
$ClassContent = Get-Content $MPMonitorRuleFile

# Write display strings
$FindLastDisplayStringLine = Select-String $MPMonitorRuleFile -pattern "</DisplayStrings>" | ForEach-Object {$_.LineNumber -2}
$ClassContent[$FindLastDisplayStringLine] += "`n    <DisplayString ElementID=""$RuleID"">`n     <Name>$RuleName</Name>`n     <Description>$RuleDescription</Description>`n    </DisplayString>`n    <DisplayString ElementID=""$AlertMessageID"">`n     <Name>$AlertName</Name>`n     <Description>$AlertMessage</Description>`n    </DisplayString>"
$ClassContent | Set-Content $MPMonitorRuleFile


}

  Function Edit-SCOMMPMonitorRule
  {

   While($True) {
 [int]$xMenuChoiceA = 0
 while ( $xMenuChoiceA -lt 1 -or $xMenuChoiceA -gt 11 ){
 Write-host "1. Add Windows Event Monitor"
 Write-Host "2. Add Windows Service Monitor"
 Write-Host "3. Add Windows Service CPU Performance Monitor"
 Write-Host "4. Add Windows Service Memory Performance Monitor"
 Write-Host "5. Add Windows Generic Log Monitor"
 Write-Host "6. Add Windows PowerShell Script Monitor"
 Write-Host "7. Add Windows Performance Monitor"
 Write-host "8. Add Windows Event Rule"
 Write-Host "9. Add Windows PowerShell Script Rule"
 Write-Host "10. Add Windows Performance Rule"
 Write-Host "11. Exit"

[Int]$xMenuChoiceA = read-host "Please enter an option 1 to 11..."
 }
 Switch( $xMenuChoiceA ){
   1{Add-SCOMMPWindowsEventMonitor -MPMonitorRuleFile $MPMonitorRuleFile}
   2{Add-SCOMMPWindowsServiceMonitor -MPMonitorRuleFile $MPMonitorRuleFile}
   3{Add-SCOMMPWindowsServiceCPUPerformanceMonitor -MPMonitorRuleFile $MPMonitorRuleFile}
   4{Add-SCOMMPWindowsServiceMemoryPerformanceMonitor -MPMonitorRuleFile $MPMonitorRuleFile}
   5{Add-SCOMMPWindowsGenericLogMonitor -MPMonitorRuleFile $MPMonitorRuleFile}
   6{New-SCOMMPCustomProbeAction; Add-SCOMMPCustomProbeAction}
   7{Add-SCOMMPPerformanceMonitor -MPMonitorRuleFile $MPMonitorRuleFile}
   8{Add-SCOMMPWindowsEventRule -MPMonitorRuleFile $MPMonitorRuleFile}
   9{Add-SCOMMPWindowsPowerShellScriptRule -MPMonitorRuleFile $MPMonitorRuleFile}
   10{Add-SCOMMPPerformanceRule -MPMonitorRuleFile $MPMonitorRuleFile}
   11{Return}
   }
 }
  }

Function Reload-SCOMManagementPack
{
PARAM (
[Parameter(Mandatory=$false)][String]$MPClassFile = $(Read-Host -Prompt "Location of Class File"),
[Parameter(Mandatory=$false)][String]$MPDiscoveryFile = $(Read-Host -Prompt "Location of Discovery File"),
[Parameter(Mandatory=$false)][String]$MPFolderFile = $(Read-Host -Prompt "Location of Folder File"),
[Parameter(Mandatory=$false)][String]$MPViewFile = $(Read-Host -Prompt "Location of View File"),
[Parameter(Mandatory=$false)][String]$MPMonitorRuleFile = $(Read-Host -Prompt "Location of Monitors & Rules File"),
[Parameter(Mandatory=$false)][String]$MPRelationShipFile = $(Read-Host -Prompt "Location of Relationship File"),
[Parameter(Mandatory=$false)][String]$MPCustomProbeActionFile = $(Read-Host -Prompt "Location of Custom Probe Action File"),
[Parameter(Mandatory=$false)][String]$MPCustomDataSourceFile = $(Read-Host -Prompt "Location of Data Source File"),
[Parameter(Mandatory=$false)][String]$MPCustomMonitorTypeFile = $(Read-Host -Prompt "Location of Unit Monitor Type File")
)


 While($True) {
 [int]$xMenuChoiceA = 0
 while ( $xMenuChoiceA -lt 1 -or $xMenuChoiceA -gt 23 ){
 Write-host "1. Add Classes"
 Write-Host "2. Add Class Property"
 Write-Host "3. Add Run As Account"
 Write-Host "4. Add PowerShell Discovery"
 Write-Host "5. Add VBScript Discovery"
 Write-Host "6. Add WMI Discovery"
 Write-Host "7. Add Registry Discovery"
 Write-Host "8. Add ComputerGroup Discovery"
 Write-Host "9. Add InstanceGroup Discovery"
 Write-Host "10. Add relationship"
 Write-Host "11. Add View"
 Write-Host "12. Add Folder"
 Write-host "13. Add Windows Event Monitor"
 Write-Host "14. Add Windows Service Monitor"
 Write-Host "15. Add Windows Service CPU Performance Monitor"
 Write-Host "16. Add Windows Service Memory Performance Monitor"
 Write-Host "17. Add Windows Generic Log Monitor"
 Write-Host "18. Add Windows PowerShell Script Monitor"
 Write-Host "19. Add Windows Performance Monitor"
 Write-host "20. Add Windows Event Rule"
 Write-Host "21. Add Windows PowerShell Script Rule"
 Write-Host "22. Add Windows Performance Rule"
 Write-Host "23. Exit"

[Int]$xMenuChoiceA = read-host "Please enter an option 1 to 23..."
 }
 Switch( $xMenuChoiceA ){
   1{Add-SCOMMPClass -MPClassFile $MPClassFile}
   2{Add-SCOMMPClassProperty -MPClassFile $MPClassFile}
   3{Add-SCOMMPRunAsAccount -MPClassFile $MPClassFile}
   4{Add-SCOMMPPowerShellDiscovery -MPDiscoveryFile $MPDiscoveryFile -MPClassFile $MPClassFile; Create-PowerShellScript -MPClassFile $MPClassFile}
   5{Add-SCOMMPVBScriptDiscovery -MPDiscoveryFile $MPDiscoveryFile -MPClassFile $MPClassFile; Create-VBScript -MPClassFile $MPClassFile}
   6{Add-SCOMMPWMIDiscovery -MPDiscoveryFile $MPDiscoveryFile -MPClassFile $MPClassFile}
   7{Add-SCOMMPRegistryDiscovery -MPDiscoveryFile $MPDiscoveryFile -MPClassFile $MPClassFile; Edti-SCOMMPRegistry}
   8{Add-SCOMMPComputerGroupDiscovery -MPDiscoveryFile $MPDiscoveryFile}
   9{Add-SCOMMPInstanceGroupDiscovery -MPDiscoveryFile $MPDiscoveryFile}
   10{Add-SCOMMPRelationship -MPRelationshipFile $MPRelationShipFile}
   11{Add-SCOMMPView -MPViewFile $MPViewFile}
   12{Add-SCOMMPFolder -MPFolderFile $MPFolderFile}
   13{Add-SCOMMPWindowsEventMonitor -MPMonitorRuleFile $MPMonitorRuleFile}
   14{Add-SCOMMPWindowsServiceMonitor -MPMonitorRuleFile $MPMonitorRuleFile}
   15{Add-SCOMMPWindowsServiceCPUPerformanceMonitor -MPMonitorRuleFile $MPMonitorRuleFile}
   16{Add-SCOMMPWindowsServiceMemoryPerformanceMonitor -MPMonitorRuleFile $MPMonitorRuleFile}
   17{Add-SCOMMPWindowsGenericLogMonitor -MPMonitorRuleFile $MPMonitorRuleFile}
   18{New-SCOMMPCustomProbeAction; Add-SCOMMPCustomProbeAction}
   19{Add-SCOMMPPerformanceMonitor -MPMonitorRuleFile $MPMonitorRuleFile}
   20{Add-SCOMMPWindowsEventRule -MPMonitorRuleFile $MPMonitorRuleFile}
   21{Add-SCOMMPWindowsPowerShellScriptRule -MPMonitorRuleFile $MPMonitorRuleFile}
   22{Add-SCOMMPPerformanceRule -MPMonitorRuleFile $MPMonitorRuleFile}
   23{Return}
   }

} 
}
  #####################################################################################################################################

  #Create SCOM Management Pack

  # Questions to create SCOM Management Pack
  cls
  Write-Host "Welcome to the SCOM Managament Pack Creation Script" -ForegroundColor Green
  Write-Host ""
  Write-Host "There will be a series of questions to help build the management pack and will output seperate files for you to copy the XML code and add into Visual Studios" -ForegroundColor Green
  Write-Host ""
  Write-Host "Note: If creating an Instance Group make sure that you add the SystemCenter.InstanceGroup.Library management pack to your references in Visual Studios" -ForegroundColor Yellow
  Write-Host "Note: If creating a Registry Discovery make sure that you add the System.AdminItem.Library & System.Software.Library management pack to your references in Visual Studios" -ForegroundColor Yellow  
  Write-Host "Note: If creating any Service Monitors make sure that you add the Microsoft.SystemCenter.NTService.Library management pack to your references in Visual Studios" -ForegroundColor Yellow
  Write-Host "Note: If creating any Generic log Monitors make sure that you add the System.ApplicationLog.Library management pack to your references in Visual Studios" -ForegroundColor Yellow
  Write-Host "Note: If creating any performance Monitors make sure that you add the System.Performance.Library management pack to your references in Visual Studios" -ForegroundColor Yellow  
  Write-Host "These management packs can be found in C:\Program Files (x86)\System Center Authoring Extensions\Reference and select the appropriate folder on your SCOM version" -ForegroundColor Yellow
  Write-Host ""
  Write-Host ""

  $ManagementPackName = Read-Host "Name of Management Pack"

  Write-Host ""
  Write-Host "OS Platform of your management Pack"
  Write-host "1. Windows Management Pack"
  Write-Host "2. Unix Management Pack"
  $Platformtype =  Read-Host "Select Option."

      switch ( $PlatformType )
    {
        1 { $PlatformType = "Windows!Microsoft.Windows.ComputerRole"  }
        2 { $PlatformType = "Unix!Microsoft.Unix.ComputerRole"   }
    }

    Write-Host ""
    Write-Host "Discovery method for your management pack"
    Write-host "1. PowerShell"
    Write-Host "2. Registry"
    Write-Host "3. WMI"
    Write-Host "4. VBScript"
    $DiscoveryMethod =  Read-Host "Select Option"

      switch ( $DiscoveryMethod )
    {
   1{$DiscoveryMethod = "Windows!Microsoft.Windows.TimedPowerShell.DiscoveryProvider"; $FriendlyDiscoveryName = "PowerShell"}
   2{$DiscoveryMethod = "Windows!Microsoft.Windows.FilteredRegistryDiscoveryProvider";$FriendlyDiscoveryName = "Registry"}
   3{$DiscoveryMethod = "Windows!Microsoft.Windows.WmiProviderWithClassSnapshotDataMapper";$FriendlyDiscoveryName = "WMI"}
   4{$DiscoveryMethod = "Windows!Microsoft.Windows.TimedScript.DiscoveryProvider";$FriendlyDiscoveryName = "VBScript"}
    }

  Write-Host ""
  $FileLocation = Read-Host "Where will the files be saved"

 Write-Host ""
 Write-Host ""
 Write-Host Management Pack Name will be $ManagementPackName
 Write-Host Management Pack will be using $FriendlyDiscoveryName as its discovery method
 Write-Host Location of the XML files will be placed in $FileLocation
 Write-Host
 $Proceed = Read-Host "OK to Proceed with Management Pack creation?"
 If ($Proceed -eq "No") {break}
 
 ###################################################################################################################################

  # Create Class File

 cls
  Write-Host "Writing Class file for management pack" -ForegroundColor Green

  $MPClassFile = "$FileLocation\$ManagementPackName.class.xml"
  New-SCOMMPClass -MPClassFile $MPClassFile

  $MPClassFileExists = Get-Item $MPClassFile
  If ($MPClassFileExists -ne $null) {Write-Host "Class file successfully created" -ForegroundColor Yellow}

  Write-Host ""
  Write-Host "Now you will be asked to add your Classes and Properties" -ForegroundColor Yellow
  
  Edit-SCOMMPClass

    $RelationshipClassOption = Read-Host "Do you require to create a relationship between classes i.e health rollup"
  If ($RelationshipClassOption -eq "Yes")
   {$MPRelationshipfile = "$FileLocation\$ManagementPackName.Relationship.xml"; New-SCOMMPRelationShip; Add-SCOMMPRelationship -MPRelationshipFile $MPRelationshipfile}

  $ClassesDetection = ((Get-Content $MPClassFile) -match "<DisplayString ElementID" -notmatch "SubElementID") -replace "<DisplayString ElementID=""", "" -replace """", "" -replace ">", ""
  $ClassesDetection = $ClassesDetection.trim()

  Write-Host ""
  Write-Host "The following classes have been detected" -ForegroundColor Green
  For($i=0;$i -le $ClassesDetection.Count -1; $i++) {Write-Host $i. $ClassesDetection[$i]}
  Write-Host ""
  $ClassIDPropertyExtract = Read-Host "Which class do you wish to extract properties from?"

  # Set ClassIDPropertyExtract
    For($i=0;$i -le $ClassesDetection.Count -1; $i++) {
   If ($ClassIDPropertyExtract -eq $i) {$ClassIDPropertyExtract = $ClassesDetection[$i]}}


  $PropertiesDetection = ((Get-Content $MPClassFile) -match "<DisplayString ElementID=""$ClassIDPropertyExtract"" SubElementID") -replace "<DisplayString ElementID=""$ClassIDPropertyExtract"" SubElementID=""","" -replace """", "" -replace ">", ""
  $PropertiesDetection = $PropertiesDetection.trim()
  $RunAsAccount = ((Get-Content $MPClassFile) -match "<DisplayString ElementID" -match "Account") -replace "<DisplayString ElementID=""", "" -replace """", "" -replace ">", ""
  $RunAsAccount = $RunAsAccount.trim()
  
  Write-Host ""
  Write-Host "The following classes have been detected" -ForegroundColor Green
  For($i=0;$i -le $ClassesDetection.Count -1; $i++) {Write-Host $i. $ClassesDetection[$i]}
  Write-Host ""
  $ClassID = Read-Host "Which class do you wish to create a discovery for"

    # Set ClassIDPropertyExtract
    For($i=0;$i -le $ClassesDetection.Count -1; $i++) {
   If ($ClassID -eq $i) {$ClassID = $ClassesDetection[$i]}}
  
  $ComputerGroupCreation = Read-Host "Do you wish to create a ComptuerGroup?"
  If ($ComputerGroupCreation -eq "Yes")
  {Add-SCOMMPClass -MPClassFile $MPClassFile -ClassName "$ClassID.ComputerGroup" -ClassType "5" -ClassDescription "Computer group for $ClassID" -Abstract "false" -Hosted "false" -Singleton "true"}
  
  $InstanceGroupCreation = Read-Host "Do you wish to create a InstanceGroup?"
  If ($InstanceGroupCreation -eq "Yes")
  {Add-SCOMMPClass -MPClassFile $MPClassFile -ClassName "$ClassID.InstanceGroup" -ClassType "6" -ClassDescription "Instance group for $ClassID" -Abstract "false" -Hosted "false" -Singleton "true"}
  
####################################################################################################################################

  # Create Discovery File

  Write-Host ""
  Write-Host "Writing Discovery file for management pack" -ForegroundColor Green

  $MPDiscoveryFile = "$FileLocation\$ManagementPackName.Discovery.xml"
  New-SCOMMPDiscovery -MPDiscoveryFile $MPDiscoveryFile -DiscoveryTarget ($PlatformType -replace "role","")
  
  $MPDiscoveryFileExists = Get-Item $MPDiscoveryFile
  If ($MPDiscoveryFileExists -ne $null) {Write-Host "Discovery file successfully created" -ForegroundColor Yellow}

  If ($DiscoveryMethod -eq "Windows!Microsoft.Windows.TimedPowerShell.DiscoveryProvider") {
   Add-SCOMMPPowerShellDiscovery -MPClassFile $MPClassFile -MPDiscoveryFile $MPDiscoveryFile -ClassID $ClassID -DiscoveryName "$ClassID.PowerShell.Discovery" -DiscoveryClass $ClassID -ScriptName "$ClassID.Discovery.ps1" -ScriptBody "$ClassID.Discovery.ps1" -DiscoveryRunAsAccount $RunAsAccount -DiscoveryTarget $PlatformType
   Create-PowerShellScript -ScriptName "$FileLocation\$ClassID.Discovery.ps1" -MPClassFile $MPClassFile
   }
  If ($DiscoveryMethod -eq "Windows!Microsoft.Windows.FilteredRegistryDiscoveryProvider") {
     Add-SCOMMPRegistryDiscovery -MPClassFile $MPClassFile -MPDiscoveryFile $MPDiscoveryFile -ClassID $ClassID -DiscoveryName "$ClassID.Registry.Discovery" -DiscoveryClass $ClassID -DiscoveryRunAsAccount $RunAsAccount -DiscoveryTarget ($PlatformType -replace "role","")
     Write-Host ""
     Write-Host "The following propeties have been detected which can be used as Attribute Name" -ForegroundColor Green
     Write-Host ""
     Write-Host $PropertiesDetection
     Write-Host ""
     Edit-SCOMMPAddRegistry
     }
  If ($DiscoveryMethod -eq "Windows!Microsoft.Windows.TimedScript.DiscoveryProvider") {
   Add-SCOMMPVBScriptDiscovery -MPClassFile $MPClassFile -MPDiscoveryFile $MPDiscoveryFile -ClassID $ClassID -DiscoveryName "$ClassID.VBSCript.Discovery" -DiscoveryClass $ClassID -ScriptName "$ClassID.Discovery.vbs" -DiscoveryRunAsAccount $RunAsAccount -DiscoveryTarget $PlatformType
   Create-VBScript -ScriptName "$FileLocation\$ClassID.Discovery.vbs" -MPClassFile $MPClassFile
   }
  If ($DiscoveryMethod -eq "Windows!Microsoft.Windows.WmiProviderWithClassSnapshotDataMapper") {
   Add-SCOMMPWMIDiscovery -MPClassFile $MPClassFile -MPDiscoveryFile $MPDiscoveryFile -ClassID $ClassID -DiscoveryName "$ClassID.WMI.Discovery" -DiscoveryClass $ClassID -DiscoveryRunAsAccount $RunAsAccount -DiscoveryTarget $PlatformType
   }
   
   If ($ComputerGroupCreation -eq "Yes")
   {Add-SCOMMPComputerGroupDiscovery -MPDiscoveryFile $MPDiscoveryFile -DiscoveryID "$ClassID.$FriendlyDiscoveryName.ComputerGroupDiscovery" -DiscoveryTarget $PlatformType -ClassID $ClassID -DiscoveryDescription "Computer group for $ClassID"}

   If ($InstanceGroupCreation -eq "Yes")
   {Add-SCOMMPInstanceGroupDiscovery -MPDiscoveryFile $MPDiscoveryFile -DiscoveryID "$ClassID.$FriendlyDiscoveryName.InstanceGroupDiscovery" -DiscoveryTarget $PlatformType -ClassID $ClassID -DiscoveryDescription "Computer group for $ClassID"}
  
  $AdditionalDiscoveries = Read-Host "Do you wish to create more discoveries"
  If ($AdditionalDiscoveries -eq "Yes")
   {Edit-SCOMMPDiscovery}

########################################################################################################################################

  # Create Folder File

  Write-Host ""
  Write-Host "Writing Folder file for management pack" -ForegroundColor Green
  $MPFolderFile = "$FileLocation\$ManagementPackName.Folder.xml"
  New-SCOMMPFolder -MPFolderFile $MPFolderFile

  $MPFolderFileExists = Get-Item $MPFolderFile
  If ($MPFolderFileExists -ne $null) {Write-Host "Folder file successfully created" -ForegroundColor Yellow}

  Add-SCOMMPFolder -MPFolderFile $MPFolderFile -FolderID "$ClassID.Folder" -FolderName $ManagementPackName -FolderParent "SC!Microsoft.SystemCenter.Monitoring.ViewFolder.Root"

#######################################################################################################################################

  # Create View File

  Write-Host ""
  Write-Host "Writing view file for management pack" -ForegroundColor Green
  $MPViewFile = "$FileLocation\$ManagementPackName.View.xml"
  New-SCOMMPView -MPViewFile $MPViewFile

  $MPViewFileExists = Get-Item $MPViewFile
  If ($MPViewFileExists -ne $null) {Write-Host "View file successfully created" -ForegroundColor Yellow}

  #Add-SCOMMPView -MPViewFile $MPViewFile -ViewID "$ClassID.View" -FolderID "$ClassID.Folder"

 ###############################################################################################################################################

 # Oppourtunity to add more to management packs

   $AddViewsorFolders = Read-Host "Do you wish to add views or folders"
   If ($AddViewsorFolders -eq "Yes")
    {Edit-SCOMMPViewsFolders}


  $AddMonitorsorRules = Read-Host "Do you wish to add monitors or rules"
  If ($AddMonitorsorRules -eq "Yes")
   {  Write-Host ""
  Write-Host "Writing Monitor & Rules file for management pack" -ForegroundColor Green
   $MPMonitorRuleFile = "$FileLocation\$ManagementPackName.MonitorRules.xml"
   New-SCOMMPMonitorRule -MPMonitorRuleFile $MPMonitorRuleFile; $MPMonitorRuleFileExists = Get-Item $MPMonitorRuleFile; Edit-SCOMMPMonitorRule
   
  If ($MPMonitorRuleFileExists -ne $null) {Write-Host "Monitor & Rules successfully created" -ForegroundColor Yellow; Edit-SCOMMPMonitorRule}
   }
        
 ###############################################################################################################################################
 
 # Management Pack Creation Completed

 Write-Host ""
 Write-Host "Management Pack is now created. Please create a visual studios project and copy the information from the files created from this script" -ForegroundColor Green 



