Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force



$randomNumber = Get-Random -Minimum 10 -Maximum 100  # สุ่มตัวเลข 2 หลัก

# สร้างชื่อไฟล์โดยเพิ่มตัวเลข 2 หลักต่อท้าย
$rickyouFileName = "$env:TMP\rickyou_$randomNumber.vbs"
$volupFileName = "$env:TMP\volup_$randomNumber.vbs"

$rickyouVbs = @"
While True
    Dim oPlayer
    Set oPlayer = CreateObject("WMPlayer.OCX")
    oPlayer.URL = "$song"
    oPlayer.controls.play
    While oPlayer.playState <> 1 ' 1 = Stopped
        WScript.Sleep 100
    Wend
    oPlayer.close
Wend
"@
Set-Content -Path $rickyouFileName -Value $rickyouVbs

Start-Process -FilePath "wscript" -ArgumentList $rickyouFileName

exit