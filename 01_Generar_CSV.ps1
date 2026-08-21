# ==============================================================================
# SCRIPT 1: Procesar canciones UltraStar y exportar a CSV (Fix Encoding)
# ==============================================================================

# Obtener la ruta del script
$scriptDir = if ($PSScriptRoot) { $PSScriptRoot } else { Split-Path -Parent -Path $MyInvocation.MyCommand.Definition }
$docsDir   = Join-Path -Path $scriptDir -ChildPath "docs"

if (-not (Test-Path -LiteralPath $docsDir)) {
    New-Item -ItemType Directory -Path $docsDir | Out-Null
}

$songsDir = "C:\UltraStar canciones"
$dupDir   = "C:\UltraStar canciones duplicadas"

$outputMain = Join-Path -Path $docsDir -ChildPath "listado_ultrastar.csv"
$outputDup  = Join-Path -Path $docsDir -ChildPath "duplicados_ultrastar.csv"

if (-not (Test-Path -LiteralPath $dupDir)) {
    New-Item -ItemType Directory -Path $dupDir | Out-Null
}

$mainList = [System.Collections.Generic.List[PSObject]]::new()
$dupList  = [System.Collections.Generic.List[PSObject]]::new()
$duplicates = @{}
$duplicateCount = 0

$files = Get-ChildItem -LiteralPath $songsDir -Recurse -Filter *.txt
$total = $files.Count
$index = 0

# Función auxiliar para leer texto sin romper eñes ni tildes
function Read-TextFileSafe {
    param([string]$path)
    $bytes = [System.IO.File]::ReadAllBytes($path)

    # Respetar BOM explícito y validar UTF-8 de forma estricta antes del fallback ANSI.
    if ($bytes.Length -ge 3 -and $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF) {
        return [System.Text.Encoding]::UTF8.GetString($bytes, 3, $bytes.Length - 3) -split "`r?`n"
    }
    if ($bytes.Length -ge 2 -and $bytes[0] -eq 0xFF -and $bytes[1] -eq 0xFE) {
        return [System.Text.Encoding]::Unicode.GetString($bytes, 2, $bytes.Length - 2) -split "`r?`n"
    }
    if ($bytes.Length -ge 2 -and $bytes[0] -eq 0xFE -and $bytes[1] -eq 0xFF) {
        return [System.Text.Encoding]::BigEndianUnicode.GetString($bytes, 2, $bytes.Length - 2) -split "`r?`n"
    }

    $strictUtf8 = [System.Text.UTF8Encoding]::new($false, $true)
    try {
        return $strictUtf8.GetString($bytes) -split "`r?`n"
    }
    catch [System.Text.DecoderFallbackException] {
        $ansi = [System.Text.Encoding]::GetEncoding(1252)
        return $ansi.GetString($bytes) -split "`r?`n"
    }
}

foreach ($f in $files) {
    $index++
    $percent = [int](($index / [Math]::Max(1, $total)) * 100)
    $safeName = $f.Name -replace ":", "_"
    Write-Progress -Activity "Procesando canciones UltraStar" -Status "Procesando ${index} de ${total} - ${safeName}" -PercentComplete $percent

    $file = $f.FullName
    $folder = Split-Path $file -Leaf

    $lines = Read-TextFileSafe -path $file

    function Get-FieldSafe {
        param([string]$pattern)
        $line = $lines | Where-Object { $_ -like $pattern } | Select-Object -First 1
        if ([string]::IsNullOrWhiteSpace($line)) { return "N/A" }
        $parts = $line.Split(":", 2)
        if ($parts.Count -lt 2) { return "N/A" }
        return $parts[1].Trim()
    }

    $title    = Get-FieldSafe "#TITLE:*"
    $artist   = Get-FieldSafe "#ARTIST:*"
    $duration = Get-FieldSafe "#LENGTH:*"
    $category = Get-FieldSafe "#GENRE:*"
    $language = Get-FieldSafe "#LANGUAGE:*"

    $lyricsPath = $file
    $parentDir  = Split-Path $file -Parent

    $musicFile = Get-ChildItem -LiteralPath $parentDir -File -ErrorAction SilentlyContinue |
                 Where-Object { $_.Extension -in ".mp3", ".ogg", ".wav", ".flac" } | Select-Object -First 1
    $musicPath = if ($musicFile) { $musicFile.FullName } else { "N/A" }

    $videoFile = Get-ChildItem -LiteralPath $parentDir -File -ErrorAction SilentlyContinue |
                 Where-Object { $_.Extension -in ".mp4", ".avi", ".mkv", ".webm" } | Select-Object -First 1
    $videoPath = if ($videoFile) { $videoFile.FullName } else { "N/A" }

    $key = "$title|$artist"
    $isMulti = $f.Name -like "*[MULTI]*"

    if ($duplicates.ContainsKey($key) -and -not $isMulti) {
        $duplicates[$key] += 1
        $duplicateCount++

        $dupList.Add([PSCustomObject]@{
            Artista   = $artist
            Titulo    = $title
            Duracion  = $duration
            Categoria = $category
            Idioma    = $language
            Carpeta   = $folder
            Letra     = $lyricsPath
            Cancion   = $musicPath
            Video     = $videoPath
            Veces     = $duplicates[$key]
        })
    }
    else {
        $duplicates[$key] = 1
    }

    $mainList.Add([PSCustomObject]@{
        Artista   = $artist
        Titulo    = $title
        Duracion  = $duration
        Categoria = $category
        Idioma    = $language
        Carpeta   = $folder
        Letra     = $lyricsPath
        Cancion   = $musicPath
        Video     = $videoPath
    })
}

Write-Progress -Activity "Procesando canciones UltraStar" -Completed

# Ordenar y exportar con BOM para que Excel detecte UTF-8 correctamente.
$mainListSorted = $mainList | Sort-Object Artista, Titulo
$dupListSorted  = $dupList  | Sort-Object Artista, Titulo

$utf8Bom = [System.Text.UTF8Encoding]::new($true)
$mainCsv = @($mainListSorted | ConvertTo-Csv -Delimiter ";" -NoTypeInformation)
$dupCsv  = @($dupListSorted  | ConvertTo-Csv -Delimiter ";" -NoTypeInformation)

# ConvertTo-Csv no devuelve líneas cuando la colección está vacía.
if ($mainCsv.Count -eq 0) {
    $mainCsv = @('"Artista";"Titulo";"Duracion";"Categoria";"Idioma";"Carpeta";"Letra";"Cancion";"Video"')
}
if ($dupCsv.Count -eq 0) {
    $dupCsv = @('"Artista";"Titulo";"Duracion";"Categoria";"Idioma";"Carpeta";"Letra";"Cancion";"Video";"Veces"')
}

[System.IO.File]::WriteAllLines($outputMain, [string[]]$mainCsv, $utf8Bom)
[System.IO.File]::WriteAllLines($outputDup, [string[]]$dupCsv, $utf8Bom)

Write-Host "CSV principal guardado correctamente en: $outputMain" -ForegroundColor Green
Write-Host "CSV duplicados guardado correctamente en: $outputDup" -ForegroundColor Green