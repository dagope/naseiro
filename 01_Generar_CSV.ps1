# ==============================================================================
# SCRIPT 1: Procesar canciones UltraStar y exportar a CSV (Fix Encoding)
# ==============================================================================

# Obtener la ruta del script
$scriptDir = if ($PSScriptRoot) { $PSScriptRoot } else { Split-Path -Parent -Path $MyInvocation.MyCommand.Definition }

$songsDir = "C:\UltraStar canciones"
$dupDir   = "C:\UltraStar canciones duplicadas"

$outputMain = Join-Path -Path $scriptDir -ChildPath "listado_ultrastar.csv"
$outputDup  = Join-Path -Path $scriptDir -ChildPath "duplicados_ultrastar.csv"

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
    
    # Detección simple de UTF-8
    $isUtf8 = $false
    if ($bytes.Length -ge 3 -and $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF) {
        $isUtf8 = $true
    } else {
        # Verificar secuencia UTF-8 válida
        $i = 0
        $validUtf8 = $true
        while ($i -lt $bytes.Length) {
            if ($bytes[$i] -gt 0x7F) {
                if (($bytes[$i] -band 0xE0) -eq 0xC0) { $i += 1 }
                elseif (($bytes[$i] -band 0xF0) -eq 0xE0) { $i += 2 }
                elseif (($bytes[$i] -band 0xF8) -eq 0xF0) { $i += 3 }
                else { $validUtf8 = $false; break }
            }
            $i++
        }
        $isUtf8 = $validUtf8
    }

    if ($isUtf8) {
        return [System.Text.Encoding]::UTF8.GetString($bytes) -split "`r?`n"
    } else {
        # Fallback a Windows-1252 / ANSI (mantiene eñes y tildes en archivos de texto antiguos)
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

# Ordenar y Exportar directamente con Export-Csv para evitar fallos de codificación
$mainListSorted = $mainList | Sort-Object Artista, Titulo
$dupListSorted  = $dupList  | Sort-Object Artista, Titulo

$mainListSorted | Export-Csv -LiteralPath $outputMain -Delimiter ";" -NoTypeInformation -Encoding UTF8
$dupListSorted  | Export-Csv -LiteralPath $outputDup  -Delimiter ";" -NoTypeInformation -Encoding UTF8

Write-Host "CSV principal guardado correctamente en: $outputMain" -ForegroundColor Green
Write-Host "CSV duplicados guardado correctamente en: $outputDup" -ForegroundColor Green