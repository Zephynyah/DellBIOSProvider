# Import the helper functions

Import-Module $PSScriptRoot\..\..\Misc\helper.psm1 -Verbose:$false

function Get-TargetResource
{
	[CmdletBinding()]
	[OutputType([System.Collections.Hashtable])]
	param
	(
		[parameter(Mandatory = $true)]
		[System.String]
		$Category
	)

	#Write-Verbose "Use this cmdlet to deliver information about command processing."

	#Write-Debug "Use this cmdlet to write debug information while troubleshooting."


	<#
	$returnValue = @{
		Category = [System.String]
		Keypad = [System.String]
		Numlock = [System.String]		
		Fastboot = [System.String]
		FnLock = [System.String]
		FullScreenLogo = [System.String]
		FnLockMode = [System.String]
		Password = [System.String]
		SecurePassword = [System.String]
		PathToKey = [System.String]
		WarningsAndErr = [System.String]
		PowerWarn = [System.String]
		PntDevice = [System.String]
		ExternalHotKey = [System.String]
		PostF2Key = [System.String]
		PostF12Key = [System.String]
		PostHelpDeskKey = [System.String]
		RptKeyErr = [System.String]
		ExtPostTime = [System.String]
		SignOfLifeIndication = [System.String]
		WyseP25Access = [System.String]
	}

	$returnValue
	#>

   # Check if module DellBIOSprovider is already loaded. If not, load it.
   try{
    $bool = Confirm-DellPSDrive -verbose
    }
    catch 
    {
        write-Verbose $_
        $msg = "Get-TargetResource: $($_.Exception.Message)"
        Write-DellEventLog -Message $msg -EventID 1 -EntryType 'Error'
        write-Verbose "Exiting Get-TargetResource"
        return
    }
    if ($bool) {                      
        Write-Verbose "Dell PS-Drive DellSmbios is found."
    }
    else{
        $Message = “Get-TargetResource: Module DellBiosProvider was imported correctly."
        Write-DellEventLog -Message $Message -EventID 2 
    }

    $Get = get-childitem -path @("DellSmbios:\" + $Category)
     # Removing Verbose and Debug from output
    $PSBoundParameters.Remove("Verbose") | out-null
    $PSBoundParameters.Remove("Debug") | out-null

  
    $out = @{}   
    $Get | foreach-Object {$out.Add($_.Attribute, $_.CurrentValue)}
    $out.add('Category', $Category )
    $out
}


function Set-TargetResource
{
	[CmdletBinding()]
	param
	(
		[parameter(Mandatory = $true)]
		[System.String]
		$Category,

		[ValidateSet("Enabled","Disabled")]
		[System.String]
		$AdvancedMode,

		[System.String]
		$Password,

		[System.String]
		$SecurePassword,

		[System.String]
		$PathToKey
	)

    if (-not(CheckModuleLoaded)) {
        Write-Verbose -Message 'Required module DellBiosProvider does not exist. Exiting.'
        return $true
    }

    $DellPSDrive = get-psdrive -name Dellsmbios
    if ( !$DellPSDrive)
    {
        $Message = "Drive DellSmbios is not found. Exiting."
        Write-Verbose $Message
        Write-DellEventLog -Message $Message -EventID 3 -EntryType "Error"
        return $true
    }
    $attributes_desired = $PSBoundParameters
    $atts = $attributes_desired

    $pathToCategory = $DellPSDrive.Name + ':\' + $atts["Category"]
    
    Dir $pathToCategory -verbose

    $atts.Remove("Verbose") | out-null
    $atts.Remove("Category") | out-null
    $atts.Remove("Debug") | out-null
    $securePwd=$atts["SecurePassword"]
    $passwordSet=$atts["Password"]
    $atts.Remove("Password") | Out-Null
    $atts.Remove("SecurePassword") | Out-Null
    $pathToKey=$atts["PathToKey"]
	if(-Not [string]::IsNullOrEmpty($pathToKey))
	{  
		if(Test-Path $pathToKey)
		{
		$key=Get-Content $pathToKey
		}
		else
		{
		$key=""
		}
	}
    $atts.Remove("PathToKey") | Out-Null
    
    #foreach($a in Import-Csv((Get-DellBIOSEncryptionKey)))
    #{
   # $key+=$a
   # }
    $atts.Keys | foreach-object { 
                   # $atts[$_]
                    $path = $pathToCategory + '\' + $($_)
                    $value = $atts[$_]
		    if(-Not [string]::IsNullOrEmpty($securePwd))
		    {                
			$pasvar=ConvertTo-SecureString $securePwd.ToString() -Key $key
            Set-Item  -path $path -value $value -verbose -ErrorVariable ev -ErrorAction SilentlyContinue -PasswordSecure $pasvar
		    }

		    elseif(-Not [string]::IsNullOrEmpty($passwordSet))
		    {
			Set-Item  -path $path -value $value -verbose -ErrorVariable ev -ErrorAction SilentlyContinue -Password $passwordSet
		    }

		    else
		    {
			Set-Item  -path $path -value $value -verbose -ErrorVariable ev -ErrorAction SilentlyContinue
		    }
                    if ( $ev) { 
                        $cmdline = $ExecutionContext.InvokeCommand.ExpandString($ev.InvocationInfo.Line)
                        $Message = "An error occured in executing " + $cmdline + "`nError message: $($ev.ErrorDetails)"
                        Write-Verbose $Message
                        Write-DellEventLog -Message $Message -EventID 5 -EntryType "Error"
                    }
                    
                 }


}


function Test-TargetResource
{
	[CmdletBinding()]
	[OutputType([System.Boolean])]
	param
	(
		[parameter(Mandatory = $true)]
		[System.String]
		$Category,

		[ValidateSet("Enabled","Disabled")]
		[System.String]
		$AdvancedMode,

		[System.String]
		$Password,

		[System.String]
		$SecurePassword,

		[System.String]
		$PathToKey

	)
    $Get = Get-TargetResource $PSBoundParameters['Category'] -verbose

    New-DellEventLog
 
    $PSBoundParameters.Remove("Verbose") | out-null
    $PSBoundParameters.Remove("Debug") | out-null
    $PSBoundParameters.Remove("Category") | out-null
    $PSBoundParameters.Remove("Password") | out-null
    $PSBoundParameters.Remove("SecurePassword") | out-null

    $attributes_desired = $PSBoundParameters

    $bool = $true

    foreach ($config_att in  $PSBoundParameters.GetEnumerator())
    {
        if ($Get.ContainsKey($config_att.Key)) {
            $currentvalue = $Get[$config_att.Key]
            $currentvalue_nospace = $currentvalue -replace " ", ""
            if ($config_att.Value -ne $currentvalue_nospace){
                $bool = $false
                $drift  = "`nCurrentValue: $currentvalue_nospace`nDesiredValue: $($config_att.value)"
                $message = "Configuration is drifted in category $Category for $($config_att.Key). $drift"
                write-verbose $message
                Write-DellEventLog -Message $message -EventID 4 -EntryType Warning
            
            }
            else {
                write-Debug "Configuration is same for $config_att."
            }
    }
    else
    {
        $message = "Unsupported attribute $($config_att)"
        Write-Verbose $message
    }
   }
   return $bool
}


Export-ModuleMember -Function *-TargetResource


# SIG # Begin signature block
# MIIu0wYJKoZIhvcNAQcCoIIuxDCCLsACAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCAF6qnWCP9lQTCC
# Dv7bJQ0BKB1KKql0ynlvpmrIYQ464KCCEwIwggXfMIIEx6ADAgECAhBOQOQ3VO3m
# jAAAAABR05R/MA0GCSqGSIb3DQEBCwUAMIG+MQswCQYDVQQGEwJVUzEWMBQGA1UE
# ChMNRW50cnVzdCwgSW5jLjEoMCYGA1UECxMfU2VlIHd3dy5lbnRydXN0Lm5ldC9s
# ZWdhbC10ZXJtczE5MDcGA1UECxMwKGMpIDIwMDkgRW50cnVzdCwgSW5jLiAtIGZv
# ciBhdXRob3JpemVkIHVzZSBvbmx5MTIwMAYDVQQDEylFbnRydXN0IFJvb3QgQ2Vy
# dGlmaWNhdGlvbiBBdXRob3JpdHkgLSBHMjAeFw0yMTA1MDcxNTQzNDVaFw0zMDEx
# MDcxNjEzNDVaMGkxCzAJBgNVBAYTAlVTMRYwFAYDVQQKDA1FbnRydXN0LCBJbmMu
# MUIwQAYDVQQDDDlFbnRydXN0IENvZGUgU2lnbmluZyBSb290IENlcnRpZmljYXRp
# b24gQXV0aG9yaXR5IC0gQ1NCUjEwggIiMA0GCSqGSIb3DQEBAQUAA4ICDwAwggIK
# AoICAQCngY/3FEW2YkPy2K7TJV5IT1G/xX2fUBw10dZ+YSqUGW0nRqSmGl33VFFq
# gCLGqGZ1TVSDyV5oG6v2W2Swra0gvVTvRmttAudFrnX2joq5Mi6LuHccUk15iF+l
# OhjJUCyXJy2/2gB9Y3/vMuxGh2Pbmp/DWiE2e/mb1cqgbnIs/OHxnnBNCFYVb5Cr
# +0i6udfBgniFZS5/tcnA4hS3NxFBBuKK4Kj25X62eAUBw2DtTwdBLgoTSeOQm3/d
# vfqsv2RR0VybtPVc51z/O5uloBrXfQmywrf/bhy8yH3m6Sv8crMU6UpVEoScRCV1
# HfYq8E+lID1oJethl3wP5bY9867DwRG8G47M4EcwXkIAhnHjWKwGymUfe5SmS1dn
# DH5erXhnW1XjXuvH2OxMbobL89z4n4eqclgSD32m+PhCOTs8LOQyTUmM4OEAwjig
# nPqEPkHcblauxhpb9GdoBQHNG7+uh7ydU/Yu6LZr5JnexU+HWKjSZR7IH9Vybu5Z
# HFc7CXKd18q3kMbNe0WSkUIDTH0/yvKquMIOhvMQn0YupGaGaFpoGHApOBGAYGuK
# Q6NzbOOzazf/5p1nAZKG3y9I0ftQYNVc/iHTAUJj/u9wtBfAj6ju08FLXxLq/f0u
# DodEYOOp9MIYo+P9zgyEIg3zp3jak/PbOM+5LzPG/wc8Xr5F0wIDAQABo4IBKzCC
# AScwDgYDVR0PAQH/BAQDAgGGMBIGA1UdEwEB/wQIMAYBAf8CAQEwHQYDVR0lBBYw
# FAYIKwYBBQUHAwMGCCsGAQUFBwMIMDsGA1UdIAQ0MDIwMAYEVR0gADAoMCYGCCsG
# AQUFBwIBFhpodHRwOi8vd3d3LmVudHJ1c3QubmV0L3JwYTAzBggrBgEFBQcBAQQn
# MCUwIwYIKwYBBQUHMAGGF2h0dHA6Ly9vY3NwLmVudHJ1c3QubmV0MDAGA1UdHwQp
# MCcwJaAjoCGGH2h0dHA6Ly9jcmwuZW50cnVzdC5uZXQvZzJjYS5jcmwwHQYDVR0O
# BBYEFIK61j2Xzp/PceiSN6/9s7VpNVfPMB8GA1UdIwQYMBaAFGpyJnrQHu995ztp
# UdRsjZ+QEmarMA0GCSqGSIb3DQEBCwUAA4IBAQAfXkEEtoNwJFMsVXMdZTrA7LR7
# BJheWTgTCaRZlEJeUL9PbG4lIJCTWEAN9Rm0Yu4kXsIBWBUCHRAJb6jU+5J+Nzg+
# LxR9jx1DNmSzZhNfFMylcfdbIUvGl77clfxwfREc0yHd0CQ5KcX+Chqlz3t57jpv
# 3ty/6RHdFoMI0yyNf02oFHkvBWFSOOtg8xRofcuyiq3AlFzkJg4sit1Gw87kVlHF
# VuOFuE2bRXKLB/GK+0m4X9HyloFdaVIk8Qgj0tYjD+uL136LwZNr+vFie1jpUJuX
# bheIDeHGQ5jXgWG2hZ1H7LGerj8gO0Od2KIc4NR8CMKvdgb4YmZ6tvf6yK81MIIG
# gzCCBGugAwIBAgIQNa+3e500H2r8j4RGqzE1KzANBgkqhkiG9w0BAQ0FADBpMQsw
# CQYDVQQGEwJVUzEWMBQGA1UECgwNRW50cnVzdCwgSW5jLjFCMEAGA1UEAww5RW50
# cnVzdCBDb2RlIFNpZ25pbmcgUm9vdCBDZXJ0aWZpY2F0aW9uIEF1dGhvcml0eSAt
# IENTQlIxMB4XDTIxMDUwNzE5MTk1MloXDTQwMTIyOTIzNTkwMFowYzELMAkGA1UE
# BhMCVVMxFjAUBgNVBAoTDUVudHJ1c3QsIEluYy4xPDA6BgNVBAMTM0VudHJ1c3Qg
# RXh0ZW5kZWQgVmFsaWRhdGlvbiBDb2RlIFNpZ25pbmcgQ0EgLSBFVkNTMjCCAiIw
# DQYJKoZIhvcNAQEBBQADggIPADCCAgoCggIBAL69pznJpX3sXWXx9Cuph9DnrRrF
# GjsYzuGhUY1y+s5YH1y4JEIPRtUxl9BKTeObMMm6l6ic/kU2zyeA53u4bsEkt9+n
# dNyF8qMkWEXMlJQ7AuvEjXxG9VxmguOkwdMfrG4MUyMO1Dr62kLxg1RfNTJW8rV4
# m1cASB6pYWEnDnMDQ7bWcJL71IWaMMaz5ppeS+8dKthmqxZG/wvYD6aJSgJRV0E8
# QThOl8dRMm1njmahXk2fNSKv1Wq3f0BfaDXMafrxBfDqhabqMoXLwcHKg2lFSQbc
# CWy6SWUZjPm3NyeMZJ414+Xs5wegnahyvG+FOiymFk49nM8I5oL1RH0owL2JrWwv
# 3C94eRHXHHBL3Z0ITF4u+o29p91j9n/wUjGEbjrY2VyFRJ5jBmnQhlh4iZuHu1gc
# pChsxv5pCpwerBFgal7JaWUu7UMtafF4tzstNfKqT+If4wFvkEaq1agNBFegtKzj
# bb2dGyiAJ0bH2qpnlfHRh3vHyCXphAyPiTbSvjPhhcAz1aA8GYuvOPLlk4C/xsOr
# e5PEPZ257kV2wNRobzBePLQ2+ddFQuASBoDbpSH85wV6KI20jmB798i1SkesFGaX
# oFppcjFXa1OEzWG6cwcVcDt7AfynP4wtPYeM+wjX5S8Xg36Cq08J8inhflV3ZZQF
# HVnUCt2TfuMUXeK7AgMBAAGjggErMIIBJzASBgNVHRMBAf8ECDAGAQH/AgEAMB0G
# A1UdDgQWBBTOiU+CUaoVooRiyjEjYdJh+/j+eDAfBgNVHSMEGDAWgBSCutY9l86f
# z3Hokjev/bO1aTVXzzAzBggrBgEFBQcBAQQnMCUwIwYIKwYBBQUHMAGGF2h0dHA6
# Ly9vY3NwLmVudHJ1c3QubmV0MDEGA1UdHwQqMCgwJqAkoCKGIGh0dHA6Ly9jcmwu
# ZW50cnVzdC5uZXQvY3NicjEuY3JsMA4GA1UdDwEB/wQEAwIBhjATBgNVHSUEDDAK
# BggrBgEFBQcDAzBEBgNVHSAEPTA7MDAGBFUdIAAwKDAmBggrBgEFBQcCARYaaHR0
# cDovL3d3dy5lbnRydXN0Lm5ldC9ycGEwBwYFZ4EMAQMwDQYJKoZIhvcNAQENBQAD
# ggIBAD4AVLgq849mr2EWxFiTZPRBi2RVjRs1M6GbkdirRsqrX7y+fnDk0tcHqJYH
# 14bRVwoI0NB4Tfgq37IE85rh13zwwQB6wUCh34qMt8u0HQFh8piapt24gwXKqSwW
# 3JwtDv6nl+RQqZeVwUsqjFHjxALga3w1TVO8S5QTi1MYFl6mCqe4NMFssess5DF9
# DCzGfOGkVugtdtWyE3XqgwCuAHfGb6k97mMUgVAW/FtPEhkOWw+N6kvOBkyJS64g
# zI5HpnXWZe4vMOhdNI8fgk1cQqbyFExQIJwJonQkXDnYiTKFPK+M5Wqe5gQ6pRP/
# qh3NR0suAgW0ao/rhU+B7wrbfZ8pj6XCP1I4UkGVO7w+W1QwQiMJY95QjYk1Rfqr
# uA+Poq17ehGT8Y8ohHtoeUdq6GQpTR/0HS9tHsiUhjzTWpl6a3yrNfcrOUtPuT8W
# ku8pjI2rrAEazHFEOctAPiASzghw40f+3IDXCADRC2rqIbV5ZhfpaqpW3c0VeLED
# wBStPkcYde0KU0syk83/gLGQ1hPl5EF4Iu1BguUO37DOlSFF5osB0xn39CtVrNlW
# c2MQ4LigbctUlpigmSFRBqqmDDorY8t52kO50hLM3o9VeukJ8+Ka0yXBezaS2uDl
# UmfN4+ZUCqWd1HOj0y9dBmSFA3d/YNjCvHTJlZFot7d+YRl1MIIGlDCCBHygAwIB
# AgIQfLeNpTYQ7xit6Aq3XVt49TANBgkqhkiG9w0BAQsFADBjMQswCQYDVQQGEwJV
# UzEWMBQGA1UEChMNRW50cnVzdCwgSW5jLjE8MDoGA1UEAxMzRW50cnVzdCBFeHRl
# bmRlZCBWYWxpZGF0aW9uIENvZGUgU2lnbmluZyBDQSAtIEVWQ1MyMB4XDTIzMTEy
# MjE4MTI0NFoXDTI0MTExNzE4MTI0M1owge8xCzAJBgNVBAYTAlVTMQ4wDAYDVQQI
# EwVUZXhhczETMBEGA1UEBxMKUm91bmQgUm9jazETMBEGCysGAQQBgjc8AgEDEwJV
# UzEZMBcGCysGAQQBgjc8AgECEwhEZWxhd2FyZTEfMB0GA1UEChMWRGVsbCBUZWNo
# bm9sb2dpZXMgSW5jLjEdMBsGA1UEDxMUUHJpdmF0ZSBPcmdhbml6YXRpb24xGDAW
# BgNVBAsTD0NsaWVudCBTb2Z0d2FyZTEQMA4GA1UEBRMHNTI4MDM5NDEfMB0GA1UE
# AxMWRGVsbCBUZWNobm9sb2dpZXMgSW5jLjCCAaIwDQYJKoZIhvcNAQEBBQADggGP
# ADCCAYoCggGBALmW9IlCjy/PBE5ZGADPVlIbsNS6S1FCnWSd1/hB10YM3Qc0n5CJ
# 2cHiOKgUiTm61a7Qzh7m67+IQzMMpBHHMBHQJsr71W4U2EiOnOHNAm403oM8MBNb
# cOhC6cknoO1DjeL1VNTIffhn9oGZvg0XXQca7vB3gqC1IoAcksg0CWh5M4D8V9X+
# X3aAjFB6MWOiiInFq2GQeH/Pc35PoSb4i/ArpzDCp1Uqlz6fDbKkRIlDII0HbXuH
# PJvNUxIg3Ki9i9/mng3FnLJ2X7Y0gPyuvkniJNi21d9mr9VOSk3HvXHZq1YdRLRb
# rj8WtgwprmlRrnAGbaFhPPkUG2xPDOU9COzcayb6ghfZnXK4UU88pcQDEXNLWTmD
# 63ygETmuGexzCQ8pp1kbt/cXKN/xAkxGFpyNpJPOjrm8uXNpyjpy3iwaTkaNcsEr
# z0bP51nEYdSKosODq2nbLnbmFXgj9we2pvix6zeHhYKl9TRlPbAsccqiTRBBhGkj
# MAb9aPvpy1fiIQIDAQABo4IBNTCCATEwDAYDVR0TAQH/BAIwADAdBgNVHQ4EFgQU
# 96wO+HUdY4Gik830JkyxIJ5lRg4wHwYDVR0jBBgwFoAUzolPglGqFaKEYsoxI2HS
# Yfv4/ngwZwYIKwYBBQUHAQEEWzBZMCMGCCsGAQUFBzABhhdodHRwOi8vb2NzcC5l
# bnRydXN0Lm5ldDAyBggrBgEFBQcwAoYmaHR0cDovL2FpYS5lbnRydXN0Lm5ldC9l
# dmNzMi1jaGFpbi5wN2MwMQYDVR0fBCowKDAmoCSgIoYgaHR0cDovL2NybC5lbnRy
# dXN0Lm5ldC9ldmNzMi5jcmwwDgYDVR0PAQH/BAQDAgeAMBMGA1UdJQQMMAoGCCsG
# AQUFBwMDMCAGA1UdIAQZMBcwBwYFZ4EMAQMwDAYKYIZIAYb6bAoBAjANBgkqhkiG
# 9w0BAQsFAAOCAgEAJaPgxf52Qx0bZY+xlNtpkPMudPhaEcommXI8S7HpTLWMuUM4
# 1VK5zP9Gn+8FvBJdh0ChuBKhcyjje3/3Mkv63XA/2L8XyfMzksMR3FTz0t5arrCa
# ojmwRANDojFAhd//v7MbCDDotvGDl7VUTdILo5Zsi7Vb53965JaJVMJu7/rbA6mK
# fGzw1LENLwHdN9vhQblicnwTZbp0OdhN0BX1KNg1Z+GWBQmSx19c69oMYvC//M8u
# DEFrdnEkNQoh3bFE0ybjoV0K0aH0GB1de9LbHOEuzyKiFNtIbl7ssxD8IP3IXVSk
# 7gfFhPaNxBqLcM5aOSf5/9UGnXRuCEx8Co+nS9RG+8r3uLEXq+5cSijZdi5z9hz6
# bwv/uLeOj0u09CAC6gB2BtT35Pli4jzrdce46iFijtaryiCSVBBDoJ2PQx8BixYM
# c0lvgBiBoSOhs9W93VS5nxTRze2l8XP7J6p8mscuhdScr3Vned1uyVY5dvWjk/YB
# Ie7pwxzc/vZ5/LDJtdrQ1rUDnX29XuKVgmgkXfiwaPiyEKFNHrMwog853rGzqcyk
# yngRfGTvUng9iBZHs6Uhg2m5eA2NkscyV1qVv/n7AcTlrf9gqAB4U7No3qNBdbCl
# YdCfzjwKYUXURawJf42LLiLtBDt0u9rTFspNQEpLZDHaxTgGp/uNgd/0DAYxghsn
# MIIbIwIBATB3MGMxCzAJBgNVBAYTAlVTMRYwFAYDVQQKEw1FbnRydXN0LCBJbmMu
# MTwwOgYDVQQDEzNFbnRydXN0IEV4dGVuZGVkIFZhbGlkYXRpb24gQ29kZSBTaWdu
# aW5nIENBIC0gRVZDUzICEHy3jaU2EO8YregKt11bePUwDQYJYIZIAWUDBAIBBQCg
# gZowGQYJKoZIhvcNAQkDMQwGCisGAQQBgjcCAQQwHAYKKwYBBAGCNwIBCzEOMAwG
# CisGAQQBgjcCARUwLgYKKwYBBAGCNwIBDDEgMB6gHIAaAEQAZQBsAGwAIABTAG8A
# bAB1AHQAaQBvAG4wLwYJKoZIhvcNAQkEMSIEIM688qD0tyHVZD0932JKsjssLzzn
# PUyN8kxtxof3DXohMA0GCSqGSIb3DQEBAQUABIIBgDi8UbcY3UGnRAZ+y+RIg0Jr
# x5mtwF4C3s1rb/bTxoxcAT9O5QHb1BjGDBTlBIa59Mm3TglDFJq6e4pGnsfIyrz1
# 48E6ypkVTakbz62jMp3bf/BK2iy8+v3jMQspVxgDUu6k7lpfDP25KT64Tfhv9QuS
# zdc1SztUp1S9VdirmhPT+L+On6wBZ1kEW1M3nKccxzQjZugKMyxDDiyG3ZGbZHiF
# iIDjUoJAQgPHX9GAjxnoaRWuQLRPrZia/1U5Blv1faeXQArxaAEugPmbeUyDcpHW
# nn/zhBlAYwHODHDWNUGggJ/5mPrMxbhHG4VlqQ7RlzNVn54TMdVufwkKtU9dpnuL
# O/23c3U2l/iiy78edSlroq+O7w7u2QYMDBi0yy3mRvBuyDC5GnZcQa+mYz+db8zF
# ChfhOk9VMjM93nwfZLK7U/8sxsjByQqpP7d46F12JdJXmmLBykQG6YH0yUTm0Er8
# xRAgKR7nX08OddFJR1I5wYJA1k6wCsnBYX3gwzXoSaGCGGQwghhgBgorBgEEAYI3
# AwMBMYIYUDCCGEwGCSqGSIb3DQEHAqCCGD0wghg5AgEDMQ0wCwYJYIZIAWUDBAID
# MIH0BgsqhkiG9w0BCRABBKCB5ASB4TCB3gIBAQYKYIZIAYb6bAoDBTAxMA0GCWCG
# SAFlAwQCAQUABCCJQ1q/oysanVRb8Bblr1VwTkn3FAV2UnMoiyJ2zq41EwIJAKDo
# Ml+DF+FPGA8yMDI0MTAyMjA0MTQzOFowAwIBAaB5pHcwdTELMAkGA1UEBhMCQ0Ex
# EDAOBgNVBAgTB09udGFyaW8xDzANBgNVBAcTBk90dGF3YTEWMBQGA1UEChMNRW50
# cnVzdCwgSW5jLjErMCkGA1UEAxMiRW50cnVzdCBUaW1lc3RhbXAgQXV0aG9yaXR5
# IC0gVFNBMqCCEw4wggXfMIIEx6ADAgECAhBOQOQ3VO3mjAAAAABR05R/MA0GCSqG
# SIb3DQEBCwUAMIG+MQswCQYDVQQGEwJVUzEWMBQGA1UEChMNRW50cnVzdCwgSW5j
# LjEoMCYGA1UECxMfU2VlIHd3dy5lbnRydXN0Lm5ldC9sZWdhbC10ZXJtczE5MDcG
# A1UECxMwKGMpIDIwMDkgRW50cnVzdCwgSW5jLiAtIGZvciBhdXRob3JpemVkIHVz
# ZSBvbmx5MTIwMAYDVQQDEylFbnRydXN0IFJvb3QgQ2VydGlmaWNhdGlvbiBBdXRo
# b3JpdHkgLSBHMjAeFw0yMTA1MDcxNTQzNDVaFw0zMDExMDcxNjEzNDVaMGkxCzAJ
# BgNVBAYTAlVTMRYwFAYDVQQKDA1FbnRydXN0LCBJbmMuMUIwQAYDVQQDDDlFbnRy
# dXN0IENvZGUgU2lnbmluZyBSb290IENlcnRpZmljYXRpb24gQXV0aG9yaXR5IC0g
# Q1NCUjEwggIiMA0GCSqGSIb3DQEBAQUAA4ICDwAwggIKAoICAQCngY/3FEW2YkPy
# 2K7TJV5IT1G/xX2fUBw10dZ+YSqUGW0nRqSmGl33VFFqgCLGqGZ1TVSDyV5oG6v2
# W2Swra0gvVTvRmttAudFrnX2joq5Mi6LuHccUk15iF+lOhjJUCyXJy2/2gB9Y3/v
# MuxGh2Pbmp/DWiE2e/mb1cqgbnIs/OHxnnBNCFYVb5Cr+0i6udfBgniFZS5/tcnA
# 4hS3NxFBBuKK4Kj25X62eAUBw2DtTwdBLgoTSeOQm3/dvfqsv2RR0VybtPVc51z/
# O5uloBrXfQmywrf/bhy8yH3m6Sv8crMU6UpVEoScRCV1HfYq8E+lID1oJethl3wP
# 5bY9867DwRG8G47M4EcwXkIAhnHjWKwGymUfe5SmS1dnDH5erXhnW1XjXuvH2OxM
# bobL89z4n4eqclgSD32m+PhCOTs8LOQyTUmM4OEAwjignPqEPkHcblauxhpb9Gdo
# BQHNG7+uh7ydU/Yu6LZr5JnexU+HWKjSZR7IH9Vybu5ZHFc7CXKd18q3kMbNe0WS
# kUIDTH0/yvKquMIOhvMQn0YupGaGaFpoGHApOBGAYGuKQ6NzbOOzazf/5p1nAZKG
# 3y9I0ftQYNVc/iHTAUJj/u9wtBfAj6ju08FLXxLq/f0uDodEYOOp9MIYo+P9zgyE
# Ig3zp3jak/PbOM+5LzPG/wc8Xr5F0wIDAQABo4IBKzCCAScwDgYDVR0PAQH/BAQD
# AgGGMBIGA1UdEwEB/wQIMAYBAf8CAQEwHQYDVR0lBBYwFAYIKwYBBQUHAwMGCCsG
# AQUFBwMIMDsGA1UdIAQ0MDIwMAYEVR0gADAoMCYGCCsGAQUFBwIBFhpodHRwOi8v
# d3d3LmVudHJ1c3QubmV0L3JwYTAzBggrBgEFBQcBAQQnMCUwIwYIKwYBBQUHMAGG
# F2h0dHA6Ly9vY3NwLmVudHJ1c3QubmV0MDAGA1UdHwQpMCcwJaAjoCGGH2h0dHA6
# Ly9jcmwuZW50cnVzdC5uZXQvZzJjYS5jcmwwHQYDVR0OBBYEFIK61j2Xzp/PceiS
# N6/9s7VpNVfPMB8GA1UdIwQYMBaAFGpyJnrQHu995ztpUdRsjZ+QEmarMA0GCSqG
# SIb3DQEBCwUAA4IBAQAfXkEEtoNwJFMsVXMdZTrA7LR7BJheWTgTCaRZlEJeUL9P
# bG4lIJCTWEAN9Rm0Yu4kXsIBWBUCHRAJb6jU+5J+Nzg+LxR9jx1DNmSzZhNfFMyl
# cfdbIUvGl77clfxwfREc0yHd0CQ5KcX+Chqlz3t57jpv3ty/6RHdFoMI0yyNf02o
# FHkvBWFSOOtg8xRofcuyiq3AlFzkJg4sit1Gw87kVlHFVuOFuE2bRXKLB/GK+0m4
# X9HyloFdaVIk8Qgj0tYjD+uL136LwZNr+vFie1jpUJuXbheIDeHGQ5jXgWG2hZ1H
# 7LGerj8gO0Od2KIc4NR8CMKvdgb4YmZ6tvf6yK81MIIGbzCCBFegAwIBAgIQJbwr
# 8ynKEH8eqbqIhdSdOzANBgkqhkiG9w0BAQ0FADBpMQswCQYDVQQGEwJVUzEWMBQG
# A1UECgwNRW50cnVzdCwgSW5jLjFCMEAGA1UEAww5RW50cnVzdCBDb2RlIFNpZ25p
# bmcgUm9vdCBDZXJ0aWZpY2F0aW9uIEF1dGhvcml0eSAtIENTQlIxMB4XDTIxMDUw
# NzE5MjIxNFoXDTQwMTIyOTIzNTkwMFowTjELMAkGA1UEBhMCVVMxFjAUBgNVBAoT
# DUVudHJ1c3QsIEluYy4xJzAlBgNVBAMTHkVudHJ1c3QgVGltZSBTdGFtcGluZyBD
# QSAtIFRTMjCCAiIwDQYJKoZIhvcNAQEBBQADggIPADCCAgoCggIBALUDKga2hE80
# zJ4xvuqOxntuICQPA9e9gTYz5m/SPrvEnqqgzGZdQmA0UeItYYO6PJ5ouEvDZo6l
# 3iu6my1Bpd7Qy1cFLYjZwEaIbTw1DRmQrLgMGfBMxdtFW9w7wryNRADgOP//XcjP
# CJo91LLre5XDxKUA4GIBZFlfjON7i6n5RbfGsKIKN0O4RoGrhn5/L97wX+vNIMyl
# LTHjqC6Zm+B43fTbXYJjfTA5iH4kBuZ8YIR4yFwp5ZXL9XtPz1jckM+nonsUVMTg
# N5gwwZu2rpwp9mslQ+cSaj4Zi77A54HXSjAIfnyN3zzzSJMh3oGDap0APtdgutGz
# YgiW6bZJADj0XHYN2ndqPaCV3h6hzFl6Xp/P6XZdQPK1FbVgaCzzWskjg9j1Gmtp
# KKS21K5iBt4mRb3e6VZ3qtxksEHNzBPxXXF0spQIS08ybn5wuHfp1TI3wnreQhLo
# cRzi2GK/qmtBhgZb5mm+Jgn0l8L+TPSAcoRu297FB6mOFaJt4RvgCQ/1oAegu8R3
# cwk8B5ONAbUSZy1NGbW4xckQq3DPQv+lJx3WEtbkGERg+zldhLtmtVMSnQMUgmUp
# tOxJcv2zQ+XDAikkuh/4uL5do7cuqfzPYtn6l8QTeONVuVp6hOv/u89piMC2+Ytg
# hUEQUMcFENJedp0+Nez2T4r5Ens/rws3AgMBAAGjggEsMIIBKDASBgNVHRMBAf8E
# CDAGAQH/AgEAMB0GA1UdDgQWBBQmD/DESAgbzd2R9VRUtrOz/JnxCDAfBgNVHSME
# GDAWgBSCutY9l86fz3Hokjev/bO1aTVXzzAzBggrBgEFBQcBAQQnMCUwIwYIKwYB
# BQUHMAGGF2h0dHA6Ly9vY3NwLmVudHJ1c3QubmV0MDEGA1UdHwQqMCgwJqAkoCKG
# IGh0dHA6Ly9jcmwuZW50cnVzdC5uZXQvY3NicjEuY3JsMA4GA1UdDwEB/wQEAwIB
# hjATBgNVHSUEDDAKBggrBgEFBQcDCDBFBgNVHSAEPjA8MDAGBFUdIAAwKDAmBggr
# BgEFBQcCARYaaHR0cDovL3d3dy5lbnRydXN0Lm5ldC9ycGEwCAYGZ4EMAQQCMA0G
# CSqGSIb3DQEBDQUAA4ICAQB2PUZohV8JwM7J+Me4136nXDsLRnPOIlOLOPYRunfE
# wochjyfZDJXr6EvlXNeQFW+oKiyKauAiETR5+r2Wech2Fs2xROpxUQ+bVckYfNWC
# eZzzpreTqQU4cgIGl6Gosnl+Xgjibmx5mqiHlM5/j1U2QA+fP1HVZr57q4bmboe6
# TmNdsdiOH8tnww1w2nrrk7IUhNI+fZM/Fgw2oFx5AJ8LbuWEKtiIwW0Etzfzkppw
# 4DsD/c27J4LOL/yN5LLKvvglhcbtdMg9NV84CT15T+sb4EFepXSBP1EVwPhJiI+6
# uwXUrUWCM3nBJY1fVD2R5LifF5gAXa0o5U9fG/v4VLWlxCT88HY7+A1ezEewyqq7
# blHfU7VJGvFgh7f5/WkGdV9z1hGQ8oBYjuXDDwOYjARTsymH3z/3sOlMV4EkRHlo
# /hs2B9ZlPexv1sK1qmF8Zgbs0uVpgPhxki5c4hFGGEVL1voFZO+73gbKQyW9343J
# AXRhiNvwx6Y94wxxvH9L58jgbuDagPkAnsBrJdWjulwr/sRgIBRKByMx5RrLkUSy
# mntD8VuYtSFLuDE7IlTueWH3mpQbZicqxt/hZV3vcTnmUCX9hzS5rl18JzvnZZP4
# KISxb4aTLJOTtnCvoe7IpGGphDv7Crf4uG0m7kdO9V4F+pwPEX3Xy5GuQyD3FVlj
# vDCCBrQwggScoAMCAQICEFtwJsyW9ngau4X2EfVtu24wDQYJKoZIhvcNAQENBQAw
# TjELMAkGA1UEBhMCVVMxFjAUBgNVBAoTDUVudHJ1c3QsIEluYy4xJzAlBgNVBAMT
# HkVudHJ1c3QgVGltZSBTdGFtcGluZyBDQSAtIFRTMjAeFw0yNDAxMTkxNjQ3NDda
# Fw0zNTA0MTgwMDAwMDBaMHUxCzAJBgNVBAYTAkNBMRAwDgYDVQQIEwdPbnRhcmlv
# MQ8wDQYDVQQHEwZPdHRhd2ExFjAUBgNVBAoTDUVudHJ1c3QsIEluYy4xKzApBgNV
# BAMTIkVudHJ1c3QgVGltZXN0YW1wIEF1dGhvcml0eSAtIFRTQTIwggIiMA0GCSqG
# SIb3DQEBAQUAA4ICDwAwggIKAoICAQCqhgQ4Xo9ov4P1Wv1Um8V9OnWdxKctT23p
# 0AUfUeMzuy9fOrGWVIrpCHw0rYmDVaSfAswjC9gbekCkzJ9C6hN/fLjgt0oCBeKD
# SQRvBobNc0Gpg9SYZ/r0Uhl640pZKIdWF11I8YaRC7giZNtB+V1UtTWkbjjcCA0a
# VhhAw36YPEIzhA3FpWFRziBtTwDLQvCodRvbRv4p3Bue1/gYBVF2MJt0vZUfGVNl
# FUcsVmNr6bpIrAo4tsFy/SAKo3Qaawd/0d2sF861HMd6iQzsbRwwjQXwrz2XzDW0
# tQUDZrqedvw52sia1hIS5EHChSJA8Mu6iOnSh8KrxjQ75asNAAYOBrWLe9ELIto8
# qMlWe/A1BJbqWUaMj9SgtamDsM6E+0tE5UGoFvOv2tGgJ3DfB+83866RztQhf4aY
# 3F7uj8DaR9tpyhC5kZWAFWPxKxrClqEfwvc81PZ9JAclqFSUbwpV29skQ24uO6J7
# Sbu11hiP2QSzvurHtWSaS85SYR4rBR5jN0adscnVXoek6tc0siFCF7g6KDpepe0+
# /TcXf2Mg8nvWX8rzFD/hzv+Kd5RmbYnB4Ox/BHA4ZCf1pxd9TcoMgRvF5fE2xXqu
# fSmkRzU4+g30UwMpBfxvoYvJzfG4iEDT0tueJTGt1+Za2AS0hLsERmFm/10y3vzT
# PnxOGO9+3wIDAQABo4IBZTCCAWEwDAYDVR0TAQH/BAIwADAdBgNVHQ4EFgQU9XYa
# +BCYkqEbd6kALPGVYgILeScwHwYDVR0jBBgwFoAUJg/wxEgIG83dkfVUVLazs/yZ
# 8QgwaAYIKwYBBQUHAQEEXDBaMCMGCCsGAQUFBzABhhdodHRwOi8vb2NzcC5lbnRy
# dXN0Lm5ldDAzBggrBgEFBQcwAoYnaHR0cDovL2FpYS5lbnRydXN0Lm5ldC90czIt
# Y2hhaW4yNTYucDdjMDEGA1UdHwQqMCgwJqAkoCKGIGh0dHA6Ly9jcmwuZW50cnVz
# dC5uZXQvdHMyY2EuY3JsMA4GA1UdDwEB/wQEAwIHgDAWBgNVHSUBAf8EDDAKBggr
# BgEFBQcDCDBMBgNVHSAERTBDMDcGCmCGSAGG+mwKAQcwKTAnBggrBgEFBQcCARYb
# aHR0cHM6Ly93d3cuZW50cnVzdC5uZXQvcnBhMAgGBmeBDAEEAjANBgkqhkiG9w0B
# AQ0FAAOCAgEAqat9vxoAhVvc7XEmXpSCr1yCS/ocOcVTtcMG3QNgfvlhmkEgwq5B
# Fy6lQgiRCV6XMJiBRdaytYQ9i+mHB9oBP+AIWGcRIJQewBaOY3e9m2wFjT21y5ox
# qUpcYjKiE86QnA3HkE9nw+Cof4eES9fywSEPEOcXufu9Ccy+iqYB/k2CT2kgmnVr
# 5A33UCZT/DP3/huup2rAqOseryLTPWAVn7rk1SmktVefsWX2sUxh1dLI2resqhgf
# IBiKpvj1B/lyK/Zj2CWcFv77lN+GdKIgtPII3xbvOYB2OpKx0JaDatp8U4lZGw1c
# 8bsp8iFPYSwkifh2CX/ZaJCOVwxk1XYAcVnz1ITIPKGIf6hv871uf7CojuaTbOkU
# xXUcDCvO8gf7ta7UQTG/wcxpmBiuWwiPq1xkuYRqvVw4od9PQrdLW1LT3vc7y59v
# wllCIk4LGLciyC/8agmF7VApUXrElEu2cWWKSoaaS3hLVoqh3i+Lk1syzKG576m2
# DNgGCxcwvw1vj5OsyxH18ccAntAZ15xfjlR8a6lDO2PcwUSrvYw6Q/ByPySVzYSR
# XSEADXhrDVwjJJ9MrzTLFFreseRFUP2vb6cFgqdzz8/pkupzKrHh3aID5iC8HWca
# VsIu9qxfyk6BsOZaHXPP0hTzUHgoBU4VboUk+DOoiK90bfRSzoyohJ4xggQaMIIE
# FgIBATBiME4xCzAJBgNVBAYTAlVTMRYwFAYDVQQKEw1FbnRydXN0LCBJbmMuMScw
# JQYDVQQDEx5FbnRydXN0IFRpbWUgU3RhbXBpbmcgQ0EgLSBUUzICEFtwJsyW9nga
# u4X2EfVtu24wCwYJYIZIAWUDBAIDoIIBizAaBgkqhkiG9w0BCQMxDQYLKoZIhvcN
# AQkQAQQwHAYJKoZIhvcNAQkFMQ8XDTI0MTAyMjA0MTQzOFowKwYJKoZIhvcNAQk0
# MR4wHDALBglghkgBZQMEAgOhDQYJKoZIhvcNAQENBQAwTwYJKoZIhvcNAQkEMUIE
# QOmwy2bxPU59NaZ9ypb+TnIk/kDtAJuFGyTX2bcKb4VpQgjL6WhjMu1sukF9jhYg
# 0vIrI79YXM5y6AWEq2kBdjEwgdAGCyqGSIb3DQEJEAIvMYHAMIG9MIG6MIG3MAsG
# CWCGSAFlAwQCAwRAORFCLhcCPqqZJJl0Dg7I6NJy01X8XPZs+RFWr5dVNOSAr9O8
# fExbV+/R/7zbdRRl4NQFWoVOmxE52ffsVdX+JDBmMFKkUDBOMQswCQYDVQQGEwJV
# UzEWMBQGA1UEChMNRW50cnVzdCwgSW5jLjEnMCUGA1UEAxMeRW50cnVzdCBUaW1l
# IFN0YW1waW5nIENBIC0gVFMyAhBbcCbMlvZ4GruF9hH1bbtuMA0GCSqGSIb3DQEB
# DQUABIICACMI847xxJu0beUQmXvijHNwi55ilUgYSfYo1YFqTaG3jv7HaQsf5cQU
# eqkbUfJCYwM7/dnvtD6rzPU9y/iRa19n0nmUxufEcGaX0673cJbeEc9t3GEAOMgn
# rY3y462Xanngk/TIjDjxXZ8NcTRitOo04FsEf8X0CMm/MpSnOWcXLle9Lou7WLOO
# vU2MvgxTmY+1Rgc+5lTC6F4xQjm7l8jkGZJG+3uBvmxDFvFS35+1r4vh5dfkg19k
# krONw7CCWjplGOwGxwDWhsEHdD15LbOGSt19oO3CJ6yGGx5lPPYA2tHOaMziGy/8
# SPlmZKrHgrdyuXUswSX2BTKX8U2t4FmuQoZF51wNW4cLHseRbneXzq5pz4MCKc3a
# 3BVDXJnA/ErdFfGWpteaUwQvzlRdqLYmJWRFpMt7XBxRAjlcp+AxWCEXjM4Gf/W2
# 0QIWulgyzMZS9qZSUPSsiG7GPUURXxqnKiHMRE9MV7+/uBOxs534LUjJv5D+Q8KP
# J5pU2gdGGU7CHQ9xKfZyTy1LRZISAYWo5HomiPLNOo+tIxjE6iaS7OvfVkdgfVSm
# BsZl+9GIqJqfXcPlCtbcZ3xSOLj6LcdU9BYwy9PdvwyQVhq3vAuMtgSBVz6eHa57
# v9WwCfVTwsTLnJohL1wamJh+p8OZM255M0FqK0+UqKs3pF8KIC7y
# SIG # End signature block
