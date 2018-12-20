function Remove-PersistedCredential {
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
    [string]$Domain
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
        Remove-Item -Path $env:LOCALAPPDATA\$filename.clixml -Force
    }
  }
  if ($null -ne $Domain -and '' -ne $Domain) {
    $Files = Get-ChildItem -Path $env:LOCALAPPDATA -Filter "*.Clixml" -File
    $filename = $Files | Where-Object { $_.Name -match "_$Domain.Clixml" } | Select-Object -ExpandProperty FullName
    if ($null -ne $filename) {
      $Cred = Import-Clixml $filename
      Remove-Item -Path $env:LOCALAPPDATA\$filename.clixml -Force
    }
  }
  Write-Verbose -Message ('{0} persisted credential removed.' -f $Cred.UserName)
}

  End {
    $Cred = $null
    $Files = $null
    $filename = $null
  }
}
