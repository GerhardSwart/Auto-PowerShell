function SettingsFilePath {
    return "$env:USERPROFILE\someCompPowerShellSetting.xml"
}

function encodeString ($string) {
    $result = ConvertTo-SecureString $string -AsPlainText -Force | ConvertFrom-SecureString
    return $result
}

function decodeString ($encruptedString) {
    $secretStuff = $encruptedString | ConvertTo-SecureString
    return [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR((($secretStuff))))
}

function OpenXMLFile {
    [xml]$xml = New-Object System.Xml.XmlDocument

    if ([System.IO.File]::Exists($(SettingsFilePath)) -eq $True) {
        $xml.Load($(SettingsFilePath))
        return $xml

    } else {
        $settings = $xml.CreateNode("element","Settings",$null)
        $xml.AppendChild($settings)
    
        $xml.save($(SettingsFilePath))

        return $xml
    }
}

function GetUserSetting ($settingName) {    
    $xml = OpenXMLFile($(SettingsFilePath))
    $settingsNode = $xml.SelectSingleNode('Settings') 

    try {
        $setting = $settingsNode.item($settingName)
        if ($setting -eq $null) {
            return $null
        } else {
            return $setting.InnerText
        }
    } catch {
        return $null
    }
}

function SetUserSetting ($settingName, $value) {
    $xml = OpenXMLFile($(SettingsFilePath))
    $settingsNode = $xml.SelectSingleNode('Settings') 

     $setting = $settingsNode.item($settingName)
     if ($setting -eq $null) {
        $setting = $xml.CreateNode("element", $settingName, $null)
        $settingsNode.AppendChild($setting)
        $setting.InnerText = $value

     } else {
        $setting = $value
     }

    $xml.Save($(SettingsFilePath));
    return $setting
}


