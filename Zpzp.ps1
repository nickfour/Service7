# เปลี่ยนสีข้อความเป็นสีเขียว
$Host.UI.RawUI.ForegroundColor = "Green"

# ดาวน์โหลดไฟล์จาก URL และบันทึกไปที่ temp/t.txt
Invoke-WebRequest -Uri "https://github.com/nickfour/Service7/raw/main/zpcypx.txt" -OutFile "$env:TEMP\zpzpp.txt"

cls

# แสดงเนื้อหาของไฟล์ที่ดาวน์โหลด
Get-Content "$env:TEMP\zpzpp.txt"

