function Set-PersistedCredential {
  [Cmdletbinding()]
  Param(
    [Parameter(Mandatory = $true, HelpMessage = 'Enter a Userame in either DOMAIN\UserName or UserName@Domain.tld format')]
    [string]$UserName,
    $Force
  )

  Begin {
  }

  Process {
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
      if (-not(Test-Path -Path $filename) -or $Force) {
        $Cred | Export-Clixml -Path $env:LOCALAPPDATA\$filename.clixml -Force
      } else {
        Write-Warning -Message 'Persistent credential already exists.  Either use Remove-PersistentCredential command first or Set-PersistentCredential with -Force parameter.'
      }
      $Cred
    } else {
      Throw 'UserName parameter needs to be in DOMAIN\User or User@Domain.tld format'
    }
  }

  End {
  }
}
