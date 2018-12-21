function Get-PersistedCredential {
  [Cmdletbinding()]
  Param(
    [ValidateScript( {
        if ($_ -imatch '\.+\\[\dA-Z-_]+|[\dA-Z-]+\\[\dA-Z-_]+|[\dA-Z-_]+@[\.\dA-Z-]+') {
          $true
        } else {
          Throw 'UserName parameter needs to be in DOMAIN\UserName, .\UserName or UserName@Domain.tld format.'
        }
      })]
    [string]$UserName = '',
    [string]$Domain = '',
    [string]$Message = 'Enter credential',
    [switch]$List
  )

  Begin {
    $Cred = $null
    $filename = $null
  }

  Process {
    if ('' -ne $UserName -and '' -ne $Domain) {
      Throw 'The Username and Domain parameters cannot be used simultaneously.'
    }
    if ($List) {
      $PersistedCreds = @()
      $Files = Get-ChildItem -Path $env:LOCALAPPDATA -Filter "*.Clixml" -File
      $Files = $Files | Where-Object { $_.Name -match "_*.Clixml" } | Select-Object FullName, LastWriteTime
      if ($null -ne $Files) {
        foreach ($File in $Files) {
          $Cred = Import-Clixml $File.FullName

          $PCred = New-Object PSObject
          Add-Member -InputObject $PCred -MemberType NoteProperty -Name UserName -Value $Cred.UserName
          Add-Member -InputObject $PCred -MemberType NoteProperty -Name LastWriteTime -Value $File.LastWriteTime
          Add-Member -InputObject $PCred -MemberType NoteProperty -Name AgeInDays -Value (New-TimeSpan -Start $File.LastWriteTime -End (Get-Date)).Days

          $PersistedCreds += $PCred
        }
        return $PersistedCreds
      }
    }
    if ('' -ne $Domain) {
      $Files = Get-ChildItem -Path $env:LOCALAPPDATA -Filter "*.Clixml*" -File
      $File = $Files | Where-Object { $_.Name -match "_$Domain.Clixml" } | Select-Object FullName, LastWriteTime
      if ($null -ne $File) {
        if ($File.Count -gt 1) {
          Write-Warning -Message 'More than one item matches that domain - using first available.  Use -UserName option instead or clean up extraneous domain credentials.'
          $File = $Files | Where-Object { $_.Name -match "_$Domain.Clixml" } | Select-Object FullName, LastWriteTime -First 1
        }
        $Cred = Import-Clixml $File.FullName
        $Days = (New-TimeSpan -Start $File.LastWriteTime -End (Get-Date)).Days
        if ($Days -ge 30) {
          Write-Warning -Message ('[{0}] Persisted Credential is {1} days old.  You should remove or update it.' -f $Cred.UserName, $Days)
        }
        return $Cred
      }
    }
    if ('' -eq $UserName) {
      $UserName = Read-Host -Prompt 'Enter a username'
      if ($UserName -notmatch '\.+\\[\dA-Z-_]+|[\dA-Z-]+\\[\dA-Z-_]+|[\dA-Z-_]+@[\.\dA-Z-]+') {
        Throw 'UserName parameter needs to be in DOMAIN\UserName, .\UserName or UserName@Domain.tld format.'
      }
    }
    switch -regex ($UserName) {
      # .\UserName
      '\.+\\[\dA-Z-_]+' {
        $FileDomain = 'local'
        $User = $Username.Split('\')[1]
        $PromptUserName = $Username.Split('\')[1]
      }
      # DOMAIN\UserName
      '[\dA-Z-_]+\\[\dA-Z-_]+' {
        $FileDomain = $Username.Split('\')[0]
        $User = $Username.Split('\')[1]
        $PromptUserName = $UserName
      }
      # UserName@domain.tld
      '[\dA-Z-_]+@[\dA-Z-_]+[\.\dA-Z-_]+' {
        $User = $Username.Split('@')[0]
        $FileDomain = $Username.Split('@')[1]
        $PromptUserName = $UserName
      }
    }
    $filename = '{0}\{1}_{2}.Clixml' -f $env:LOCALAPPDATA, $User, $FileDomain
    if (Test-Path $filename) {
      $Cred = Import-Clixml $filename
    } else {
      if ($null -eq $Cred) {
        $Cred = Get-Credential -Message $Message -UserName $PromptUserName
      }
      $Cred | Export-Clixml -Path $filename
    }
    return $Cred
  }

  End {
  }
}
