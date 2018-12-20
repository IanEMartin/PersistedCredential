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
      $filename = $Files | Where-Object { $_.Name -match "_$Domain.Clixml" } | Select-Object -ExpandProperty FullName
      if ($null -ne $filename) {
        $Cred = Import-Clixml $filename
      }
    }
    if ($List) {
      $PersistedCreds = @()
      $Files = Get-ChildItem -Path $env:LOCALAPPDATA -Filter "*.Clixml" -File
      $Files = $Files | Where-Object { $_.Name -match "_?.Clixml" } | Select-Object -ExpandProperty FullName
      if ($null -ne $Files) {
        foreach ($File in $Files) {
          $Cred = Import-Clixml $File
          $PersistedCreds += $Cred.UserName
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
