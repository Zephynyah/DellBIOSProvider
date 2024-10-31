##########################################################################
# DELL PROPRIETARY INFORMATION
#
# This software is confidential.  Dell Inc., or one of its subsidiaries, has supplied this
# software to you under the terms of a license agreement,nondisclosure agreement or both.
# You may not copy, disclose, or use this software except in accordance with those terms.
#
# Copyright 2020 Dell Inc. or its subsidiaries.  All Rights Reserved.
#
# DELL INC. MAKES NO REPRESENTATIONS OR WARRANTIES ABOUT THE SUITABILITY OF THE SOFTWARE,
# EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE IMPLIED WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE, OR NON-INFRINGEMENT.
# DELL SHALL NOT BE LIABLE FOR ANY DAMAGES SUFFERED BY LICENSEE AS A RESULT OF USING,
# MODIFYING OR DISTRIBUTING THIS SOFTWARE OR ITS DERIVATIVES.
#
#
#
##########################################################################

function Set-DellAutoOnForSelectDays {
<#
  .Synopsis 
    Configures the system's auto-on capabilities that control individual days
  .Description
    This CmdLet sets the Auto-on to select days and enables or disables the individual days
    to automatically power on the system on a pre fixed .
	If a BIOS password (Admin or System password) is set, supply it using the -Password parameter. 
  .Example
    Set-DellAutoonForSelectDays -Sunday "Enabled" -Monday "Disabled" -password $Password
  .Example
	Set-DellAutoonForSelectDays -Tuesday "Enabled"
  .Example
    Set-DellAutoOnForSelectDays -verbose
#>
[CmdletBinding()]
param(  
    [Alias("Sun")][System.String] $Sunday,
    [Alias("Mon")][System.String] $Monday,
    [Alias("Tue")][System.String] $Tuesday,
    [Alias("Wed")][System.String] $Wednesday,
    [Alias("Thu")][System.String] $Thursday,
    [Alias("Fri")][System.String] $Friday,
    [Alias("Sat")][System.String] $Saturday,
    [Alias("pw")][Parameter(Mandatory=$false)][System.String] $Password
  
 )

 BEGIN { 
        Write-Output "Set-DellAutoOnForSelectDays"
 }
 PROCESS {
    #the process block is called for each item in the pipeline and you can reference it via $_
    #Write-Output "in process"

    $pathToPowerManagement = 'DellSmbios' + ':\' + 'PowerManagement'
    
    
    $isAdminPWSet  = Get-Item -path DellSmbios:\Security\IsAdminPasswordSet
    $issystemPWSet = Get-Item -path DellSmbios:\Security\IsSystemPasswordSet

    if (($isAdminPWSet.CurrentValue -match 'True') -or ($issystemPWSet.CurrentValue -match 'True')) 
    {
        if ([string]::IsNullOrEmpty($Password)){
        Write-Warning "Specify the password using -password."
        return
        }
    }

    
    if ($Password){
        Set-Item -path $pathToPowerManagement\AutoOn -value "SelectDays" -password $Password -ErrorVariable ev
    }
    else{   Set-Item -path $pathToPowerManagement\AutoOn -value "SelectDays" -ErrorVariable ev}

	if ($ev){
              Write-Warning "$ev Error occured in $($ev.InvocationInfo.ScriptName)"  
			  return
	}		
	
    if ($PSBoundParameters.ContainsKey('Sunday')) {
        if ($password){    
                Set-Item -path DellSmbios:\PowerManagement\AutoOnSun -value $Sunday -password $Password -ErrorVariable ev
         }
         else {Set-Item -path DellSmbios:\PowerManagement\AutoOnSun -value $Sunday -ErrorVariable ev}
        
    }
    if ($PSBoundParameters.ContainsKey('Monday')) {
         if ($password){ 
            Set-Item -path $pathToPowerManagement\AutoOnMon -value $Monday -password $Password -ErrorVariable ev
         }
         else {Set-Item -path DellSmbios:\PowerManagement\AutoOnMon -value $Monday -ErrorVariable ev}
    }
    if ($PSBoundParameters.ContainsKey('Tuesday')) {
         if ($password){ 
            Set-Item -path $pathToPowerManagement\AutoOnTue -value $Tuesday -password $Password -ErrorVariable ev
         }
         else {Set-Item -path DellSmbios:\PowerManagement\AutoOnTue -value $Tuesday -ErrorVariable ev}
    }
    if ($PSBoundParameters.ContainsKey('Wednesday')) {
         if ($password){ 
            Set-Item -path $pathToPowerManagement\AutoOnWed -value $Wednesday -password $Password -ErrorVariable ev
         }
         else {Set-Item -path DellSmbios:\PowerManagement\AutoOnWed -value $Wednesday -ErrorVariable ev}
    }
    if ($PSBoundParameters.ContainsKey('Thursday')) {
         if ($password){ 
            Set-Item -path $pathToPowerManagement\AutoOnThur -value $Thursday -password $Password -ErrorVariable ev
         }
         else {Set-Item -path DellSmbios:\PowerManagement\AutoOnThur -value $Thursday -ErrorVariable ev}
    }
    if ($PSBoundParameters.ContainsKey('Friday')) {
         if ($password){ 
            Set-Item -path $pathToPowerManagement\AutoOnFri -value $Friday -password $Password -ErrorVariable ev
         }
         else {Set-Item -path DellSmbios:\PowerManagement\AutoOnFri -value $Friday -ErrorVariable ev}
    }
     if ($PSBoundParameters.ContainsKey('Saturday')) {
         if ($password){ 
            Set-Item -path $pathToPowerManagement\AutoOnSat -value $Saturday -password $Password -ErrorVariable ev
         }
         else {Set-Item -path DellSmbios:\PowerManagement\AutoOnSat -value $Saturday -ErrorVariable ev}
    }
    if ($ev){
              Write-Warning "$ev Error occured in $($ev.InvocationInfo.ScriptName)"    		
	}			
  }
  END{}

  }


# SIG # Begin signature block
# MIIutQYJKoZIhvcNAQcCoIIupjCCLqICAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCC6VY/PeABr0BXS
# xG6Gaqz2s5YFQnu5Tjmk+ampmgNdeaCCEugwggXfMIIEx6ADAgECAhBOQOQ3VO3m
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
# ejCCBGKgAwIBAgIQXppEwdVMjAFyZoUhC+DGojANBgkqhkiG9w0BAQsFADBjMQsw
# CQYDVQQGEwJVUzEWMBQGA1UEChMNRW50cnVzdCwgSW5jLjE8MDoGA1UEAxMzRW50
# cnVzdCBFeHRlbmRlZCBWYWxpZGF0aW9uIENvZGUgU2lnbmluZyBDQSAtIEVWQ1My
# MB4XDTI0MDIxNDIwNTQ0MloXDTI1MDIyNzIwNTQ0MVowgdUxCzAJBgNVBAYTAlVT
# MQ4wDAYDVQQIEwVUZXhhczETMBEGA1UEBxMKUm91bmQgUm9jazETMBEGCysGAQQB
# gjc8AgEDEwJVUzEZMBcGCysGAQQBgjc8AgECEwhEZWxhd2FyZTEfMB0GA1UEChMW
# RGVsbCBUZWNobm9sb2dpZXMgSW5jLjEdMBsGA1UEDxMUUHJpdmF0ZSBPcmdhbml6
# YXRpb24xEDAOBgNVBAUTBzUyODAzOTQxHzAdBgNVBAMTFkRlbGwgVGVjaG5vbG9n
# aWVzIEluYy4wggGiMA0GCSqGSIb3DQEBAQUAA4IBjwAwggGKAoIBgQDDo1XKkZwW
# xJ2HF9BoBTYk8SHvDp3z2FVdLQay6VKOSz+Xrohhe56UrKQOW/pePeBC+bj+GM0j
# R7bCZCx0X26sh6SKz3RgIRgc+QP3TRKu6disqSWIjIMKFmNegyQPJbDLaDMhvrVk
# j7qobtphs0OB/8N+hSkcTRmiphzDvjwTiYh6Bgt37pPDEvhz1tkZ/fhWWhp355lW
# FWYBPmxVS2vTKDRSQnLtJ31dltNBXalMW0ougqtJNVJTm1m9m8ZgkBtm2a2Ydgdg
# tYbgye5A0udl0HwcImgiDG1eAKNR1W4eG353UsS7n6IWG93QpF5L++2o7DDcDtBr
# 9qtVy3RjzWuzgYW5/wIvLkWS7UolX65tFfwKai617FikhrrqcgWcwfbKVrUA4nL3
# i4OL4718Y9T/8N39Knwp1+ZJx9hMiFVVCr6XteO0LQg18/NFjDzbuRXzX2adEzxm
# Fdbw3ZGLUfCYN2LQTa+ssOc2hAEumaiVRdntd2d5TaOHwXhsSaBMnh8CAwEAAaOC
# ATUwggExMAwGA1UdEwEB/wQCMAAwHQYDVR0OBBYEFHcDtMS/dbtrhMpavR1yYhFn
# +k1vMB8GA1UdIwQYMBaAFM6JT4JRqhWihGLKMSNh0mH7+P54MGcGCCsGAQUFBwEB
# BFswWTAjBggrBgEFBQcwAYYXaHR0cDovL29jc3AuZW50cnVzdC5uZXQwMgYIKwYB
# BQUHMAKGJmh0dHA6Ly9haWEuZW50cnVzdC5uZXQvZXZjczItY2hhaW4ucDdjMDEG
# A1UdHwQqMCgwJqAkoCKGIGh0dHA6Ly9jcmwuZW50cnVzdC5uZXQvZXZjczIuY3Js
# MA4GA1UdDwEB/wQEAwIHgDATBgNVHSUEDDAKBggrBgEFBQcDAzAgBgNVHSAEGTAX
# MAcGBWeBDAEDMAwGCmCGSAGG+mwKAQIwDQYJKoZIhvcNAQELBQADggIBABB9FgN1
# YzMm05EhuGuTIEQNOwq4VoETYArSR88RLDN9Dr8lu45+WghxE7MigaGKF8AEi6Z3
# diDeN+5TJOiBd6Zv2LDa3UfMpqf8GZm/L1pd5TF19s44NLbxlIad/yq/NbXFcWsc
# VNu4TtM/PdCg7E0ggh044pNllpR/Ofqqu2D/kV6TBMw2cgL24l5YZxat+hxfWBuw
# Rhtwu/kWiSIe0ad/vB4ChVPY7PvNuU/jCU7PlgXOUiIsPbLsheAoWjxAK+Vl/NYX
# 91T/eXBZ7A4McMoprqPeVkKti0OpC2zhb+3NFHjR/gSkVLkmwEh48ebsip6uqEBY
# KS9zj6P6g0P8HHlwNZMkQ4llOzjIsQriORfayBAmjDpsgHr0r3Q362+svyI//k1V
# HjX3WTTYO1tFfOl0LYVzcfOUj5OY04kH35Y+yi30DGJy2mG0qwlRSAfiDr1a8OpL
# eaxkwvN2R2Ml0s6Oiqq0lTuLNFRnl/tCxahaT8liOzFd2WU7I3L5IL0ufRMlbezA
# S453qkkX4Xtd7KtRDQnWU5IbzBg8Yswwv+DLNm2Ep7PHTU3t4GiF0O+oaDq83QaM
# ovN80wPcCce1PkUB9iSvOuBbbrODjlSFa6OVpLHnvDesW1L99YS8sOitcRnXoNXw
# HST4XAO+86tKYUw2XtjBapV1ND20AMhuaZ5KMIIGgzCCBGugAwIBAgIQNa+3e500
# H2r8j4RGqzE1KzANBgkqhkiG9w0BAQ0FADBpMQswCQYDVQQGEwJVUzEWMBQGA1UE
# CgwNRW50cnVzdCwgSW5jLjFCMEAGA1UEAww5RW50cnVzdCBDb2RlIFNpZ25pbmcg
# Um9vdCBDZXJ0aWZpY2F0aW9uIEF1dGhvcml0eSAtIENTQlIxMB4XDTIxMDUwNzE5
# MTk1MloXDTQwMTIyOTIzNTkwMFowYzELMAkGA1UEBhMCVVMxFjAUBgNVBAoTDUVu
# dHJ1c3QsIEluYy4xPDA6BgNVBAMTM0VudHJ1c3QgRXh0ZW5kZWQgVmFsaWRhdGlv
# biBDb2RlIFNpZ25pbmcgQ0EgLSBFVkNTMjCCAiIwDQYJKoZIhvcNAQEBBQADggIP
# ADCCAgoCggIBAL69pznJpX3sXWXx9Cuph9DnrRrFGjsYzuGhUY1y+s5YH1y4JEIP
# RtUxl9BKTeObMMm6l6ic/kU2zyeA53u4bsEkt9+ndNyF8qMkWEXMlJQ7AuvEjXxG
# 9VxmguOkwdMfrG4MUyMO1Dr62kLxg1RfNTJW8rV4m1cASB6pYWEnDnMDQ7bWcJL7
# 1IWaMMaz5ppeS+8dKthmqxZG/wvYD6aJSgJRV0E8QThOl8dRMm1njmahXk2fNSKv
# 1Wq3f0BfaDXMafrxBfDqhabqMoXLwcHKg2lFSQbcCWy6SWUZjPm3NyeMZJ414+Xs
# 5wegnahyvG+FOiymFk49nM8I5oL1RH0owL2JrWwv3C94eRHXHHBL3Z0ITF4u+o29
# p91j9n/wUjGEbjrY2VyFRJ5jBmnQhlh4iZuHu1gcpChsxv5pCpwerBFgal7JaWUu
# 7UMtafF4tzstNfKqT+If4wFvkEaq1agNBFegtKzjbb2dGyiAJ0bH2qpnlfHRh3vH
# yCXphAyPiTbSvjPhhcAz1aA8GYuvOPLlk4C/xsOre5PEPZ257kV2wNRobzBePLQ2
# +ddFQuASBoDbpSH85wV6KI20jmB798i1SkesFGaXoFppcjFXa1OEzWG6cwcVcDt7
# AfynP4wtPYeM+wjX5S8Xg36Cq08J8inhflV3ZZQFHVnUCt2TfuMUXeK7AgMBAAGj
# ggErMIIBJzASBgNVHRMBAf8ECDAGAQH/AgEAMB0GA1UdDgQWBBTOiU+CUaoVooRi
# yjEjYdJh+/j+eDAfBgNVHSMEGDAWgBSCutY9l86fz3Hokjev/bO1aTVXzzAzBggr
# BgEFBQcBAQQnMCUwIwYIKwYBBQUHMAGGF2h0dHA6Ly9vY3NwLmVudHJ1c3QubmV0
# MDEGA1UdHwQqMCgwJqAkoCKGIGh0dHA6Ly9jcmwuZW50cnVzdC5uZXQvY3NicjEu
# Y3JsMA4GA1UdDwEB/wQEAwIBhjATBgNVHSUEDDAKBggrBgEFBQcDAzBEBgNVHSAE
# PTA7MDAGBFUdIAAwKDAmBggrBgEFBQcCARYaaHR0cDovL3d3dy5lbnRydXN0Lm5l
# dC9ycGEwBwYFZ4EMAQMwDQYJKoZIhvcNAQENBQADggIBAD4AVLgq849mr2EWxFiT
# ZPRBi2RVjRs1M6GbkdirRsqrX7y+fnDk0tcHqJYH14bRVwoI0NB4Tfgq37IE85rh
# 13zwwQB6wUCh34qMt8u0HQFh8piapt24gwXKqSwW3JwtDv6nl+RQqZeVwUsqjFHj
# xALga3w1TVO8S5QTi1MYFl6mCqe4NMFssess5DF9DCzGfOGkVugtdtWyE3XqgwCu
# AHfGb6k97mMUgVAW/FtPEhkOWw+N6kvOBkyJS64gzI5HpnXWZe4vMOhdNI8fgk1c
# QqbyFExQIJwJonQkXDnYiTKFPK+M5Wqe5gQ6pRP/qh3NR0suAgW0ao/rhU+B7wrb
# fZ8pj6XCP1I4UkGVO7w+W1QwQiMJY95QjYk1RfqruA+Poq17ehGT8Y8ohHtoeUdq
# 6GQpTR/0HS9tHsiUhjzTWpl6a3yrNfcrOUtPuT8Wku8pjI2rrAEazHFEOctAPiAS
# zghw40f+3IDXCADRC2rqIbV5ZhfpaqpW3c0VeLEDwBStPkcYde0KU0syk83/gLGQ
# 1hPl5EF4Iu1BguUO37DOlSFF5osB0xn39CtVrNlWc2MQ4LigbctUlpigmSFRBqqm
# DDorY8t52kO50hLM3o9VeukJ8+Ka0yXBezaS2uDlUmfN4+ZUCqWd1HOj0y9dBmSF
# A3d/YNjCvHTJlZFot7d+YRl1MYIbIzCCGx8CAQEwdzBjMQswCQYDVQQGEwJVUzEW
# MBQGA1UEChMNRW50cnVzdCwgSW5jLjE8MDoGA1UEAxMzRW50cnVzdCBFeHRlbmRl
# ZCBWYWxpZGF0aW9uIENvZGUgU2lnbmluZyBDQSAtIEVWQ1MyAhBemkTB1UyMAXJm
# hSEL4MaiMA0GCWCGSAFlAwQCAQUAoIGaMBkGCSqGSIb3DQEJAzEMBgorBgEEAYI3
# AgEEMBwGCisGAQQBgjcCAQsxDjAMBgorBgEEAYI3AgEVMC4GCisGAQQBgjcCAQwx
# IDAeoByAGgBEAGUAbABsACAAUwBvAGwAdQB0AGkAbwBuMC8GCSqGSIb3DQEJBDEi
# BCDYR9u41D/fs0fAs/BHclXFiMo6jDT2FPtXT5wKxHtl6TANBgkqhkiG9w0BAQEF
# AASCAYCExPRP1erxrzEMIOjKX7zwKCOdVV57IvXJPatYa0jJHO2ePf7TvYFeOPLm
# EjRh35SapMSeT7lBBGTk5QrDHo2ysMRx4JlGZBJMtDSkPmKyIq3+C0pE0fWux9vb
# TfpA9xOpGV/zzxAN2r4jwYcDBafSlb41PtGO0A7rFEUcR3h0RUsif82hBVjedOAa
# RTEsXXXnOYxfKZV11HEMtR0Bl57G5JbrQsgUOfKe/9WcEYBRYofOYETcoNfHz6B8
# Y4wTmrlsMAoI2EtumC5Ar2zmvpf/jC0fz1aR3fp2O4Ca0rtCcSQbyhrY0EVo9uVX
# JiWp7cX08ye5yfm+Jh63vk7fO6qyi9yVXnLgXut4tgTOjagQOcOQhUs1wMQaiWFy
# 9e7c8QujOtcYTKyFn6wFBBSRV0TZu5OzWnrg7qaHJu29aTMbcvT49PjQ+WUcD+aS
# jzfMD1LfuyB3REAvsJEmNsoQEuE44Kd1NXJkUo9bryWkl3vXP0LnOEQlHPlBpbVR
# 5LVEcpOhghhgMIIYXAYKKwYBBAGCNwMDATGCGEwwghhIBgkqhkiG9w0BBwKgghg5
# MIIYNQIBAzENMAsGCWCGSAFlAwQCAzCB9AYLKoZIhvcNAQkQAQSggeQEgeEwgd4C
# AQEGCmCGSAGG+mwKAwUwMTANBglghkgBZQMEAgEFAAQgftkyZOxJxjyBs2yDQB8q
# l6M3esDO2cSm4t2x9148VCgCCQDAUsTlIBOYNhgPMjAyNDA0MTgwNzMyNTBaMAMC
# AQGgeaR3MHUxCzAJBgNVBAYTAkNBMRAwDgYDVQQIEwdPbnRhcmlvMQ8wDQYDVQQH
# EwZPdHRhd2ExFjAUBgNVBAoTDUVudHJ1c3QsIEluYy4xKzApBgNVBAMTIkVudHJ1
# c3QgVGltZXN0YW1wIEF1dGhvcml0eSAtIFRTQTKgghMOMIIF3zCCBMegAwIBAgIQ
# TkDkN1Tt5owAAAAAUdOUfzANBgkqhkiG9w0BAQsFADCBvjELMAkGA1UEBhMCVVMx
# FjAUBgNVBAoTDUVudHJ1c3QsIEluYy4xKDAmBgNVBAsTH1NlZSB3d3cuZW50cnVz
# dC5uZXQvbGVnYWwtdGVybXMxOTA3BgNVBAsTMChjKSAyMDA5IEVudHJ1c3QsIElu
# Yy4gLSBmb3IgYXV0aG9yaXplZCB1c2Ugb25seTEyMDAGA1UEAxMpRW50cnVzdCBS
# b290IENlcnRpZmljYXRpb24gQXV0aG9yaXR5IC0gRzIwHhcNMjEwNTA3MTU0MzQ1
# WhcNMzAxMTA3MTYxMzQ1WjBpMQswCQYDVQQGEwJVUzEWMBQGA1UECgwNRW50cnVz
# dCwgSW5jLjFCMEAGA1UEAww5RW50cnVzdCBDb2RlIFNpZ25pbmcgUm9vdCBDZXJ0
# aWZpY2F0aW9uIEF1dGhvcml0eSAtIENTQlIxMIICIjANBgkqhkiG9w0BAQEFAAOC
# Ag8AMIICCgKCAgEAp4GP9xRFtmJD8tiu0yVeSE9Rv8V9n1AcNdHWfmEqlBltJ0ak
# phpd91RRaoAixqhmdU1Ug8leaBur9ltksK2tIL1U70ZrbQLnRa519o6KuTIui7h3
# HFJNeYhfpToYyVAslyctv9oAfWN/7zLsRodj25qfw1ohNnv5m9XKoG5yLPzh8Z5w
# TQhWFW+Qq/tIurnXwYJ4hWUuf7XJwOIUtzcRQQbiiuCo9uV+tngFAcNg7U8HQS4K
# E0njkJt/3b36rL9kUdFcm7T1XOdc/zubpaAa130JssK3/24cvMh95ukr/HKzFOlK
# VRKEnEQldR32KvBPpSA9aCXrYZd8D+W2PfOuw8ERvBuOzOBHMF5CAIZx41isBspl
# H3uUpktXZwx+Xq14Z1tV417rx9jsTG6Gy/Pc+J+HqnJYEg99pvj4Qjk7PCzkMk1J
# jODhAMI4oJz6hD5B3G5WrsYaW/RnaAUBzRu/roe8nVP2Lui2a+SZ3sVPh1io0mUe
# yB/Vcm7uWRxXOwlyndfKt5DGzXtFkpFCA0x9P8ryqrjCDobzEJ9GLqRmhmhaaBhw
# KTgRgGBrikOjc2zjs2s3/+adZwGSht8vSNH7UGDVXP4h0wFCY/7vcLQXwI+o7tPB
# S18S6v39Lg6HRGDjqfTCGKPj/c4MhCIN86d42pPz2zjPuS8zxv8HPF6+RdMCAwEA
# AaOCASswggEnMA4GA1UdDwEB/wQEAwIBhjASBgNVHRMBAf8ECDAGAQH/AgEBMB0G
# A1UdJQQWMBQGCCsGAQUFBwMDBggrBgEFBQcDCDA7BgNVHSAENDAyMDAGBFUdIAAw
# KDAmBggrBgEFBQcCARYaaHR0cDovL3d3dy5lbnRydXN0Lm5ldC9ycGEwMwYIKwYB
# BQUHAQEEJzAlMCMGCCsGAQUFBzABhhdodHRwOi8vb2NzcC5lbnRydXN0Lm5ldDAw
# BgNVHR8EKTAnMCWgI6Ahhh9odHRwOi8vY3JsLmVudHJ1c3QubmV0L2cyY2EuY3Js
# MB0GA1UdDgQWBBSCutY9l86fz3Hokjev/bO1aTVXzzAfBgNVHSMEGDAWgBRqciZ6
# 0B7vfec7aVHUbI2fkBJmqzANBgkqhkiG9w0BAQsFAAOCAQEAH15BBLaDcCRTLFVz
# HWU6wOy0ewSYXlk4EwmkWZRCXlC/T2xuJSCQk1hADfUZtGLuJF7CAVgVAh0QCW+o
# 1PuSfjc4Pi8UfY8dQzZks2YTXxTMpXH3WyFLxpe+3JX8cH0RHNMh3dAkOSnF/goa
# pc97ee46b97cv+kR3RaDCNMsjX9NqBR5LwVhUjjrYPMUaH3LsoqtwJRc5CYOLIrd
# RsPO5FZRxVbjhbhNm0VyiwfxivtJuF/R8paBXWlSJPEII9LWIw/ri9d+i8GTa/rx
# YntY6VCbl24XiA3hxkOY14FhtoWdR+yxnq4/IDtDndiiHODUfAjCr3YG+GJmerb3
# +sivNTCCBm8wggRXoAMCAQICECW8K/MpyhB/Hqm6iIXUnTswDQYJKoZIhvcNAQEN
# BQAwaTELMAkGA1UEBhMCVVMxFjAUBgNVBAoMDUVudHJ1c3QsIEluYy4xQjBABgNV
# BAMMOUVudHJ1c3QgQ29kZSBTaWduaW5nIFJvb3QgQ2VydGlmaWNhdGlvbiBBdXRo
# b3JpdHkgLSBDU0JSMTAeFw0yMTA1MDcxOTIyMTRaFw00MDEyMjkyMzU5MDBaME4x
# CzAJBgNVBAYTAlVTMRYwFAYDVQQKEw1FbnRydXN0LCBJbmMuMScwJQYDVQQDEx5F
# bnRydXN0IFRpbWUgU3RhbXBpbmcgQ0EgLSBUUzIwggIiMA0GCSqGSIb3DQEBAQUA
# A4ICDwAwggIKAoICAQC1AyoGtoRPNMyeMb7qjsZ7biAkDwPXvYE2M+Zv0j67xJ6q
# oMxmXUJgNFHiLWGDujyeaLhLw2aOpd4rupstQaXe0MtXBS2I2cBGiG08NQ0ZkKy4
# DBnwTMXbRVvcO8K8jUQA4Dj//13IzwiaPdSy63uVw8SlAOBiAWRZX4zje4up+UW3
# xrCiCjdDuEaBq4Z+fy/e8F/rzSDMpS0x46gumZvgeN30212CY30wOYh+JAbmfGCE
# eMhcKeWVy/V7T89Y3JDPp6J7FFTE4DeYMMGbtq6cKfZrJUPnEmo+GYu+wOeB10ow
# CH58jd8880iTId6Bg2qdAD7XYLrRs2IIlum2SQA49Fx2Ddp3aj2gld4eocxZel6f
# z+l2XUDytRW1YGgs81rJI4PY9RpraSikttSuYgbeJkW93ulWd6rcZLBBzcwT8V1x
# dLKUCEtPMm5+cLh36dUyN8J63kIS6HEc4thiv6prQYYGW+ZpviYJ9JfC/kz0gHKE
# btvexQepjhWibeEb4AkP9aAHoLvEd3MJPAeTjQG1EmctTRm1uMXJEKtwz0L/pScd
# 1hLW5BhEYPs5XYS7ZrVTEp0DFIJlKbTsSXL9s0PlwwIpJLof+Li+XaO3Lqn8z2LZ
# +pfEE3jjVblaeoTr/7vPaYjAtvmLYIVBEFDHBRDSXnadPjXs9k+K+RJ7P68LNwID
# AQABo4IBLDCCASgwEgYDVR0TAQH/BAgwBgEB/wIBADAdBgNVHQ4EFgQUJg/wxEgI
# G83dkfVUVLazs/yZ8QgwHwYDVR0jBBgwFoAUgrrWPZfOn89x6JI3r/2ztWk1V88w
# MwYIKwYBBQUHAQEEJzAlMCMGCCsGAQUFBzABhhdodHRwOi8vb2NzcC5lbnRydXN0
# Lm5ldDAxBgNVHR8EKjAoMCagJKAihiBodHRwOi8vY3JsLmVudHJ1c3QubmV0L2Nz
# YnIxLmNybDAOBgNVHQ8BAf8EBAMCAYYwEwYDVR0lBAwwCgYIKwYBBQUHAwgwRQYD
# VR0gBD4wPDAwBgRVHSAAMCgwJgYIKwYBBQUHAgEWGmh0dHA6Ly93d3cuZW50cnVz
# dC5uZXQvcnBhMAgGBmeBDAEEAjANBgkqhkiG9w0BAQ0FAAOCAgEAdj1GaIVfCcDO
# yfjHuNd+p1w7C0ZzziJTizj2Ebp3xMKHIY8n2QyV6+hL5VzXkBVvqCosimrgIhE0
# efq9lnnIdhbNsUTqcVEPm1XJGHzVgnmc86a3k6kFOHICBpehqLJ5fl4I4m5seZqo
# h5TOf49VNkAPnz9R1Wa+e6uG5m6Huk5jXbHYjh/LZ8MNcNp665OyFITSPn2TPxYM
# NqBceQCfC27lhCrYiMFtBLc385KacOA7A/3NuyeCzi/8jeSyyr74JYXG7XTIPTVf
# OAk9eU/rG+BBXqV0gT9RFcD4SYiPursF1K1FgjN5wSWNX1Q9keS4nxeYAF2tKOVP
# Xxv7+FS1pcQk/PB2O/gNXsxHsMqqu25R31O1SRrxYIe3+f1pBnVfc9YRkPKAWI7l
# ww8DmIwEU7Mph98/97DpTFeBJER5aP4bNgfWZT3sb9bCtaphfGYG7NLlaYD4cZIu
# XOIRRhhFS9b6BWTvu94GykMlvd+NyQF0YYjb8MemPeMMcbx/S+fI4G7g2oD5AJ7A
# ayXVo7pcK/7EYCAUSgcjMeUay5FEspp7Q/FbmLUhS7gxOyJU7nlh95qUG2YnKsbf
# 4WVd73E55lAl/Yc0ua5dfCc752WT+CiEsW+GkyyTk7Zwr6HuyKRhqYQ7+wq3+Lht
# Ju5HTvVeBfqcDxF918uRrkMg9xVZY7wwgga0MIIEnKADAgECAhBbcCbMlvZ4GruF
# 9hH1bbtuMA0GCSqGSIb3DQEBDQUAME4xCzAJBgNVBAYTAlVTMRYwFAYDVQQKEw1F
# bnRydXN0LCBJbmMuMScwJQYDVQQDEx5FbnRydXN0IFRpbWUgU3RhbXBpbmcgQ0Eg
# LSBUUzIwHhcNMjQwMTE5MTY0NzQ3WhcNMzUwNDE4MDAwMDAwWjB1MQswCQYDVQQG
# EwJDQTEQMA4GA1UECBMHT250YXJpbzEPMA0GA1UEBxMGT3R0YXdhMRYwFAYDVQQK
# Ew1FbnRydXN0LCBJbmMuMSswKQYDVQQDEyJFbnRydXN0IFRpbWVzdGFtcCBBdXRo
# b3JpdHkgLSBUU0EyMIICIjANBgkqhkiG9w0BAQEFAAOCAg8AMIICCgKCAgEAqoYE
# OF6PaL+D9Vr9VJvFfTp1ncSnLU9t6dAFH1HjM7svXzqxllSK6Qh8NK2Jg1WknwLM
# IwvYG3pApMyfQuoTf3y44LdKAgXig0kEbwaGzXNBqYPUmGf69FIZeuNKWSiHVhdd
# SPGGkQu4ImTbQfldVLU1pG443AgNGlYYQMN+mDxCM4QNxaVhUc4gbU8Ay0LwqHUb
# 20b+Kdwbntf4GAVRdjCbdL2VHxlTZRVHLFZja+m6SKwKOLbBcv0gCqN0GmsHf9Hd
# rBfOtRzHeokM7G0cMI0F8K89l8w1tLUFA2a6nnb8OdrImtYSEuRBwoUiQPDLuojp
# 0ofCq8Y0O+WrDQAGDga1i3vRCyLaPKjJVnvwNQSW6llGjI/UoLWpg7DOhPtLROVB
# qBbzr9rRoCdw3wfvN/Oukc7UIX+GmNxe7o/A2kfbacoQuZGVgBVj8SsawpahH8L3
# PNT2fSQHJahUlG8KVdvbJENuLjuie0m7tdYYj9kEs77qx7VkmkvOUmEeKwUeYzdG
# nbHJ1V6HpOrXNLIhQhe4Oig6XqXtPv03F39jIPJ71l/K8xQ/4c7/ineUZm2JweDs
# fwRwOGQn9acXfU3KDIEbxeXxNsV6rn0ppEc1OPoN9FMDKQX8b6GLyc3xuIhA09Lb
# niUxrdfmWtgEtIS7BEZhZv9dMt780z58Thjvft8CAwEAAaOCAWUwggFhMAwGA1Ud
# EwEB/wQCMAAwHQYDVR0OBBYEFPV2GvgQmJKhG3epACzxlWICC3knMB8GA1UdIwQY
# MBaAFCYP8MRICBvN3ZH1VFS2s7P8mfEIMGgGCCsGAQUFBwEBBFwwWjAjBggrBgEF
# BQcwAYYXaHR0cDovL29jc3AuZW50cnVzdC5uZXQwMwYIKwYBBQUHMAKGJ2h0dHA6
# Ly9haWEuZW50cnVzdC5uZXQvdHMyLWNoYWluMjU2LnA3YzAxBgNVHR8EKjAoMCag
# JKAihiBodHRwOi8vY3JsLmVudHJ1c3QubmV0L3RzMmNhLmNybDAOBgNVHQ8BAf8E
# BAMCB4AwFgYDVR0lAQH/BAwwCgYIKwYBBQUHAwgwTAYDVR0gBEUwQzA3BgpghkgB
# hvpsCgEHMCkwJwYIKwYBBQUHAgEWG2h0dHBzOi8vd3d3LmVudHJ1c3QubmV0L3Jw
# YTAIBgZngQwBBAIwDQYJKoZIhvcNAQENBQADggIBAKmrfb8aAIVb3O1xJl6Ugq9c
# gkv6HDnFU7XDBt0DYH75YZpBIMKuQRcupUIIkQlelzCYgUXWsrWEPYvphwfaAT/g
# CFhnESCUHsAWjmN3vZtsBY09tcuaMalKXGIyohPOkJwNx5BPZ8PgqH+HhEvX8sEh
# DxDnF7n7vQnMvoqmAf5Ngk9pIJp1a+QN91AmU/wz9/4brqdqwKjrHq8i0z1gFZ+6
# 5NUppLVXn7Fl9rFMYdXSyNq3rKoYHyAYiqb49Qf5civ2Y9glnBb++5TfhnSiILTy
# CN8W7zmAdjqSsdCWg2rafFOJWRsNXPG7KfIhT2EsJIn4dgl/2WiQjlcMZNV2AHFZ
# 89SEyDyhiH+ob/O9bn+wqI7mk2zpFMV1HAwrzvIH+7Wu1EExv8HMaZgYrlsIj6tc
# ZLmEar1cOKHfT0K3S1tS0973O8ufb8JZQiJOCxi3Isgv/GoJhe1QKVF6xJRLtnFl
# ikqGmkt4S1aKod4vi5NbMsyhue+ptgzYBgsXML8Nb4+TrMsR9fHHAJ7QGdecX45U
# fGupQztj3MFEq72MOkPwcj8klc2EkV0hAA14aw1cIySfTK80yxRa3rHkRVD9r2+n
# BYKnc8/P6ZLqcyqx4d2iA+YgvB1nGlbCLvasX8pOgbDmWh1zz9IU81B4KAVOFW6F
# JPgzqIivdG30Us6MqISeMYIEFjCCBBICAQEwYjBOMQswCQYDVQQGEwJVUzEWMBQG
# A1UEChMNRW50cnVzdCwgSW5jLjEnMCUGA1UEAxMeRW50cnVzdCBUaW1lIFN0YW1w
# aW5nIENBIC0gVFMyAhBbcCbMlvZ4GruF9hH1bbtuMAsGCWCGSAFlAwQCA6CCAYkw
# GgYJKoZIhvcNAQkDMQ0GCyqGSIb3DQEJEAEEMBwGCSqGSIb3DQEJBTEPFw0yNDA0
# MTgwNzMyNTBaMCkGCSqGSIb3DQEJNDEcMBowCwYJYIZIAWUDBAIDoQsGCSqGSIb3
# DQEBDTBPBgkqhkiG9w0BCQQxQgRA8TUfbHVHMgSsnX41Y1gubfxcWjruz+FRlnxi
# +mUPVvlrVF59Gs8CvifQKcia+tBGlEyV4qs0w43iKYyc9yUVGDCB0AYLKoZIhvcN
# AQkQAi8xgcAwgb0wgbowgbcwCwYJYIZIAWUDBAIDBEA5EUIuFwI+qpkkmXQODsjo
# 0nLTVfxc9mz5EVavl1U05ICv07x8TFtX79H/vNt1FGXg1AVahU6bETnZ9+xV1f4k
# MGYwUqRQME4xCzAJBgNVBAYTAlVTMRYwFAYDVQQKEw1FbnRydXN0LCBJbmMuMScw
# JQYDVQQDEx5FbnRydXN0IFRpbWUgU3RhbXBpbmcgQ0EgLSBUUzICEFtwJsyW9nga
# u4X2EfVtu24wCwYJKoZIhvcNAQENBIICAF49tLNL7GoSeAWxiqaiwLuYxzIzcNXg
# yZpxXZbY7qeCWcWi6T03Dp/KDI8Wt3tr2bByAj8cydZRQ4TDEx7QStoVi0y1g1Di
# zuam1k5Y8gkPXQXLp9V+TSY2y3UZEn8vyoZU9qFD8Ts8fnUmxzX6jIKP6YOQehuk
# 2/4Qoh3y7FTDvVxzZ6RvVq1mrt3jz/1EY3g0NVFLrh1ChaxCiiCvv46pspp7ZLYQ
# PaovHuo3ZTYcQEZTCknXFuQCcqMJ4DGPxdxOahBSiAo9IwnUo+xegxY8Fss/QOHr
# OBCkEtRQzzaWtZzpoiAsxIPMvMmMeIUPuW86PuEMeFdtcbbQt2bn3oDvGsKND7Iv
# EkjrLIUf/OAVnXw7jt1sks/7drz8B0U/cZsTngY5SXB1+K2MibPcuMJI23DvjMx5
# xph/nqy1xCI+dAaUTAnRjrlTA2spiN+Xw9QrSfxJNYchI33dP6ZINYomSOWUBT1p
# 6tuZ2UlEbVLx8JajIKfIxMtSdkiJQqHSDVq/s+9oSGcFjWb+8Mnp9U3ZTxQwpiqk
# g5McMXnr0G4Ev50x5pROboJvKCHfDP6l9nY2q2EO8nkhwQblJ/+iP35Uf0KxHNmM
# +J39+kd1jtN6Awx8A0MjC6Ml89D/aIIDPqAhpiPEGcNYh1Fnn7xNBDuqimmG7JSW
# mAdrg98RawO6
# SIG # End signature block
