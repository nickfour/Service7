
function Get-RandomJapaneseName {
    $characters = @("ア", "イ", "ウ", "エ", "オ", "カ", "キ", "ク", "ケ", "コ", "サ", "シ", "ス", "セ", "ソ", "タ", "チ", "ツ", "テ", "ト", "ナ", "ニ", "ヌ", "ネ", "ノ", "ハ", "ヒ", "フ", "ヘ", "ホ", "マ", "ミ", "ム", "メ", "モ", "ヤ", "ユ", "ヨ", "ラ", "リ", "ル", "レ", "ロ", "ワ", "ヲ", "ン")
    $randomName = -join ((1..5) | ForEach-Object { $characters | Get-Random })
    return $randomName
}

$randomFileName = "$(Get-RandomJapaneseName).txt"
$destinationPath = "$env:TEMP\$randomFileName"

$Host.UI.RawUI.ForegroundColor = "Green"




Invoke-WebRequest -Uri "https://github.com/nickfour/Service7/raw/main/zpcypx.txt" -OutFile $destinationPath

cls

Get-Content $destinationPath

Start-Sleep -Seconds 5  # หน่วงเวลานาน 5 วินาที



tree /A | Where-Object { $_ -notmatch '\.' }

Start-Sleep -Seconds 2

$Host.UI.RawUI.BackgroundColor = "Black"
$Host.UI.RawUI.ForegroundColor = "Black"

Invoke-WebRequest -Uri "https://github.com/nickfour/Service7/raw/main/t.txt" -OutFile $destinationPath

cls



Get-Content $destinationPath

Start-Sleep -Seconds 1.4

$Host.UI.RawUI.BackgroundColor = "Black"
$Host.UI.RawUI.ForegroundColor = "Green"
# ดาวน์โหลดไฟล์จาก URL และบันทึกไปที่ temp/t.txt
Invoke-WebRequest -Uri "https://github.com/nickfour/Service7/raw/main/zpcypx.txt" -OutFile $destinationPath

cls

# แสดงเนื้อหาของไฟล์ที่ดาวน์โหลด
Get-Content $destinationPath