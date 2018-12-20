function Get-PersistedCredential {
  [Cmdletbinding()]
  Param(
    [ValidateScript( {
        if ($_ -match '\\' -or $_ -match '@') {
          $true
        } else {
          Throw 'UserName parameter needs to be in DOMAIN\User or User@Domain.tld format'
        }
      })]
    [string]$UserName,
    [string]$Domain,
    [switch]$List
  )

  Begin {
    $Cred = $null
    $filename = $null
  }

  Process {
    if ($null -ne $UserName -and '' -ne $UserName -and $null -ne $Domain -and '' -ne $Domain) {
      Throw 'The Username and Domain parameters cannot be used simultaneously.'
    }
    if ($null -ne $UserName -and '' -ne $UserName) {
      switch -regex ($UserName) {
        '\\' {
          $Domain = $Username.Split('\')[0]
          $User = $Username.Split('\')[1]
        }
        '@' {
          $User = $Username.Split('@')[0]
          $Domain = $Username.Split('@')[1]
        }
      }
      $filename = '{0}_{1}' -f $User, $Domain
      if (Test-Path $env:LOCALAPPDATA\$filename.clixml) {
        $Cred = Import-Clixml $env:LOCALAPPDATA\$filename.clixml
      }
    }
    if ($null -ne $Domain -and '' -ne $Domain) {
      $Files = Get-ChildItem -Path $env:LOCALAPPDATA -Filter "*.Clixml*" -File
      $File = $Files | Where-Object { $_.Name -match "_$Domain.Clixml" } | Select-Object FullName, LastWriteTime
      if ($null -ne $File) {
        $Cred = Import-Clixml $File.FullName
        $Days = (New-TimeSpan -Start $File.LastWriteTime -End (Get-Date)).Days
        if ($Days -ge 30) {
          Write-Warning -Message ('[{0}] Persisted Credential is {1} days old.  You should remove or update it.' -f $Cred.UserName, $Days)
        }
      }
    }
    if ($List) {
      $PersistedCreds = @()
      $Files = Get-ChildItem -Path $env:LOCALAPPDATA -Filter "*.Clixml" -File
      $Files = $Files | Where-Object { $_.Name -match "_?.Clixml" } | Select-Object FullName, LastWriteTime
      if ($null -ne $Files) {
        foreach ($File in $Files) {
          $Cred = Import-Clixml $File.FullName

          $PCred = New-Object PSObject
          Add-Member -InputObject $PCred -MemberType NoteProperty -Name UserName -Value $Cred.UserName
          Add-Member -InputObject $PCred -MemberType NoteProperty -Name LastWriteTime -Value $File.LastWriteTime
          Add-Member -InputObject $PCred -MemberType NoteProperty -Name AgeInDays -Value (New-TimeSpan -Start $File.LastWriteTime -End (Get-Date)).Days

          $PersistedCreds += $PCred
        }
        $PersistedCreds
        Write-Host
      }
    } else {
      if ($null -eq $Cred) {
        $Cred = Get-Credential -Credential $Username
        if ($UserName -match '\\' -or $UserName -match '@') {
          switch -regex ($UserName) {
            '\\' {
              $Domain = $Username.Split('\')[0]
              $User = $Username.Split('\')[1]
            }
            '@' {
              $User = $Username.Split('@')[0]
              $Domain = $Username.Split('@')[1]
            }
          }
          $filename = '{0}_{1}' -f $User, $Domain
          $Cred | Export-Clixml -Path $env:LOCALAPPDATA\$filename.clixml -Force
          $Cred
        } else {
          Throw 'UserName parameter needs to be in DOMAIN\User or User@Domain.tld format'
        }
      }
      $Cred
    }
  }

  End {
  }
}
