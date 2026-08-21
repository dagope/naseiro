# ==============================================================================
# SCRIPT 2: Leer CSV y generar HTML interactivo (Fix Modo Oscuro + TV + Abecedario)
# ==============================================================================

$scriptDir  = if ($PSScriptRoot) { $PSScriptRoot } else { Split-Path -Parent -Path $MyInvocation.MyCommand.Definition }
$docsDir    = Join-Path -Path $scriptDir -ChildPath "docs"
$csvFile    = Join-Path -Path $docsDir -ChildPath "listado_ultrastar.csv"
$outputHtml = Join-Path -Path $docsDir -ChildPath "index.html"

if (-not (Test-Path -LiteralPath $docsDir)) {
    New-Item -ItemType Directory -Path $docsDir | Out-Null
}

if (-not (Test-Path -LiteralPath $csvFile)) {
    Write-Error "No se encuentra el archivo CSV: $csvFile. Ejecuta primero 1_Generar_CSV.ps1"
    exit
}

Write-Host "Cargando archivo CSV desde: $csvFile" -ForegroundColor Cyan
$csvData = Import-Csv -LiteralPath $csvFile -Delimiter ";" -Encoding UTF8

if ($null -eq $csvData -or $csvData.Count -eq 0) {
    Write-Warning "El archivo CSV está vacío."
    exit
}

# Convertir lista a JSON comprimido
$jsonDataRaw = [PSCustomObject[]]$csvData | ConvertTo-Json -Depth 5 -Compress
if (-not $jsonDataRaw -or $jsonDataRaw -eq "null") { $jsonDataRaw = "[]" }

$htmlContent = @"
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Listado UltraStar</title>
    <style>
        :root {
            --bg-color: #f4f6f9;
            --card-bg: #ffffff;
            --text-color: #212529;
            --text-secondary: #64748b;
            --border-color: #cbd5e1;
            --primary-color: #2563eb;
            --header-bg: #1e293b;
            --header-text: #ffffff;
            --input-bg: #ffffff;
            --hover-row: #e2e8f0;
            --even-row: #f8fafc;
            --alphabet-bg: #1e293b;
            --alphabet-btn-bg: #334155;
            --alphabet-btn-text: #ffffff;
        }

        [data-theme="dark"] {
            --bg-color: #0f172a;
            --card-bg: #1e293b;
            --text-color: #f8fafc;
            --text-secondary: #94a3b8;
            --border-color: #334155;
            --primary-color: #3b82f6;
            --header-bg: #0f172a;
            --header-text: #f8fafc;
            --input-bg: #334155;
            --hover-row: #334155;
            --even-row: #1e293b;
            --alphabet-bg: #0f172a;
            --alphabet-btn-bg: #1e293b;
            --alphabet-btn-text: #f8fafc;
        }

        body {
            font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Arial, sans-serif;
            margin: 0;
            padding: 16px;
            padding-bottom: 58px;
            background-color: var(--bg-color);
            color: var(--text-color);
            transition: background-color 0.3s, color 0.3s;
            font-size: 18px;
        }

        .container {
            width: 100%;
            max-width: 1800px;
            margin: 0 auto;
            box-sizing: border-box;
        }

        header {
            position: sticky;
            top: 0;
            z-index: 90;
            display: flex;
            align-items: flex-start;
            gap: 14px;
            margin-bottom: 20px;
            background: var(--card-bg);
            padding: 10px 14px;
            border-radius: 0 0 12px 12px;
            box-shadow: 0 4px 10px rgba(0, 0, 0, 0.15);
            width: 100%;
            box-sizing: border-box;
        }

        h1 {
            margin: 0;
            font-size: clamp(1.1rem, 2vw, 1.5rem);
            font-weight: 800;
            white-space: nowrap;
        }

        .controls {
            display: flex;
            align-items: center;
            gap: 12px;
            flex: 1;
            min-width: 0;
            justify-content: flex-end;
            flex-wrap: wrap;
        }

        .search-container {
            position: relative;
            flex: 1 1 260px;
            min-width: 200px;
        }

        input[type="text"], select {
            padding: 14px 18px;
            font-size: 1.1rem;
            border: 2px solid var(--border-color);
            border-radius: 10px;
            background-color: var(--input-bg);
            color: var(--text-color);
            outline: none;
            box-sizing: border-box;
            transition: border-color 0.2s;
        }

        #searchBox { width: 100%; min-width: 0; }

        .filter-group {
            display: flex;
            align-items: center;
            gap: 10px;
            font-size: 1.1rem;
            font-weight: 600;
            white-space: nowrap;
            flex: 0 0 104px;
        }

        #multiFilter {
            width: 100%;
            min-width: 0;
        }

        .theme-btn {
            background: none;
            border: 2px solid var(--border-color);
            padding: 12px 18px;
            border-radius: 10px;
            cursor: pointer;
            color: var(--text-color);
            font-size: 1.3rem;
            display: flex;
            align-items: center;
            justify-content: center;
            transition: background-color 0.2s;
        }

        .theme-btn:hover { background-color: var(--hover-row); }

        .stats {
            width: 100%;
            margin: -12px 4px 12px;
            font-size: 0.78rem;
            white-space: nowrap;
            color: var(--text-secondary);
            font-weight: 600;
        }

        .table-responsive {
            background: var(--card-bg);
            border-radius: 16px;
            box-shadow: 0 4px 10px rgba(0, 0, 0, 0.15);
            overflow-x: auto;
            width: 100%;
            box-sizing: border-box;
            height: calc(100vh - 150px);
            height: calc(100dvh - 150px);
            min-height: 240px;
            overflow-y: auto;
        }

        table {
            width: 100%;
            table-layout: fixed;
            border-collapse: collapse;
            text-align: left;
            font-size: 1.15rem;
            min-width: 760px;
        }

        th {
            position: sticky;
            top: 0;
            z-index: 10;
            background-color: var(--header-bg);
            color: var(--header-text);
            font-weight: 700;
            font-size: 1.2rem;
            padding: 18px 14px;
            cursor: pointer;
            user-select: none;
            white-space: nowrap;
            overflow: hidden;
            text-overflow: ellipsis;
        }

        th:nth-child(1) { width: 25%; }
        th:nth-child(2) { width: 25%; }
        th:nth-child(3) { width: 17%; }
        th:nth-child(4) { width: 13%; }
        th:nth-child(5) { width: 10%; }
        th:nth-child(6) { width: 10%; }

        th::after {
            content: ' \21C5';
            opacity: 0.4;
            font-size: 0.9rem;
        }

        th.sort-asc::after { content: ' \2191'; opacity: 1; color: #60a5fa; }
        th.sort-desc::after { content: ' \2193'; opacity: 1; color: #60a5fa; }

        td {
            padding: 16px 14px;
            border-bottom: 1px solid var(--border-color);
            white-space: nowrap;
            overflow: hidden;
            text-overflow: ellipsis;
        }

        tr:nth-child(even) { background-color: var(--even-row); }
        tr:hover { background-color: var(--hover-row); }

        .badge {
            display: inline-block;
            padding: 4px 8px;
            font-size: 1.2rem;
            line-height: 1;
            border-radius: 8px;
            font-weight: 700;
        }

        .badge-ok { background-color: #dcfce7; color: #166534; }
        .badge-na { background-color: #fee2e2; color: #991b1b; }

        .alphabet-bar {
            position: fixed;
            bottom: 0;
            left: 0;
            right: 0;
            background-color: var(--alphabet-bg);
            padding: 10px 16px;
            display: flex;
            justify-content: center;
            align-items: center;
            gap: clamp(1px, 0.4vw, 6px);
            box-shadow: 0 -4px 12px rgba(0, 0, 0, 0.25);
            z-index: 100;
            flex-wrap: nowrap;
            overflow: hidden;
        }

        .alpha-btn {
            background-color: var(--alphabet-btn-bg);
            color: var(--alphabet-btn-text);
            border: none;
            padding: clamp(4px, 0.6vw, 8px) clamp(2px, 0.6vw, 12px);
            font-size: clamp(0.72rem, 1.5vw, 1.1rem);
            font-weight: 700;
            border-radius: 6px;
            cursor: pointer;
            transition: all 0.2s ease-in-out;
            flex: 1 1 0;
            min-width: 0;
            text-align: center;
            white-space: nowrap;
        }

        .alpha-btn:hover:not(:disabled) {
            background-color: var(--primary-color);
            transform: scale(1.15);
        }

        .alpha-btn:disabled {
            opacity: 0.25;
            cursor: not-allowed;
            background-color: #475569;
        }

        footer {
            position: fixed;
            bottom: 0;
            left: 0;
            right: 0;
            z-index: 80;
            background-color: var(--card-bg);
            color: var(--text-secondary);
            text-align: center;
            font-size: 0.95rem;
            padding: 9px 8px;
            box-shadow: 0 -2px 8px rgba(0, 0, 0, 0.12);
        }

        @media (max-width: 700px) {
            body { padding: 0 8px 42px; font-size: 16px; }
            header { gap: 8px; padding: 8px; margin-bottom: 10px; }
            h1 { font-size: 1rem; }
            .controls { gap: 6px; }
            .search-container { flex: 1 1 200px; min-width: 180px; }
            input[type="text"], select { padding: 9px 8px; font-size: 0.9rem; }
            .filter-group { gap: 4px; font-size: 0; flex: 0 0 82px; }
            .theme-btn { padding: 8px 10px; font-size: 1.1rem; }
            .table-responsive {
                height: calc(100vh - 108px);
                height: calc(100dvh - 108px);
                min-height: 220px;
                border-radius: 12px;
            }
            table { min-width: 680px; font-size: 0.95rem; }
            th { font-size: 1rem; padding: 13px 10px; }
            td { padding: 12px 10px; }
            .badge { padding: 4px 6px; font-size: 1rem; }
            .alphabet-bar { display: none; }
            footer { font-size: 0.8rem; padding: 7px 5px; }
        }

        @media (min-width: 701px) and (max-width: 760px) {
            .alphabet-bar { display: none; }
        }
    </style>
</head>
<body>

<div class="container">
    <header>
        <h1>Listado UltraStar</h1>
        
        <div class="controls">
            <div class="search-container">
                <input id="searchBox" type="text" placeholder="Buscar artista, título, género..." autocomplete="off">
            </div>

            <div class="filter-group">
                <select id="multiFilter" aria-label="Filtrar por número de cantantes">
                    <option value="" disabled selected hidden>Multi</option>
                    <option value="todos">Todos</option>
                    <option value="single">Solo un cantante</option>
                    <option value="multi">Mas de uno</option>
                </select>
            </div>

            <button id="themeToggle" class="theme-btn" title="Cambiar tema">🌙</button>
        </div>

    </header>

    <div class="stats" id="counter">Cargando datos...</div>

    <div class="table-responsive" id="scrollContainer">
        <table id="songsTable">
            <thead>
                <tr>
                    <th data-col="Artista">Artista</th>
                    <th data-col="Titulo">Título</th>
                    <th data-col="Categoria">Categoría</th>
                    <th data-col="Idioma">Idioma</th>
                    <th data-col="Cancion">Audio</th>
                    <th data-col="Video">Video</th>
                </tr>
            </thead>
            <tbody></tbody>
        </table>
    </div>
</div>

<footer>Feito con &hearts; polos romeiros do folgueiro.</footer>

<div class="alphabet-bar" id="alphabetBar"></div>

<script id="songs-data" type="application/json">
$jsonDataRaw
</script>

<script>
document.addEventListener("DOMContentLoaded", function() {
    let rawData = [];
    try {
        const jsonText = document.getElementById("songs-data").textContent;
        rawData = JSON.parse(jsonText);
    } catch (err) {
        console.error("Error al parsear el JSON:", err);
        document.getElementById("counter").innerText = "Error cargando los datos.";
        return;
    }

    let filteredData = [];
    let currentSort = { col: "Artista", asc: true };
    
    const BATCH_SIZE = 60;
    let currentlyRendered = 0;

    const tbody = document.querySelector("#songsTable tbody");
    const counter = document.getElementById("counter");
    const scrollContainer = document.getElementById("scrollContainer");
    const alphabetBar = document.getElementById("alphabetBar");
    const themeBtn = document.getElementById("themeToggle");

    // Corrección del cambio de tema Claro / Oscuro
    function setTheme(theme) {
        if (theme === "dark") {
            document.documentElement.setAttribute("data-theme", "dark");
            themeBtn.innerText = "☀️";
            localStorage.setItem("theme", "dark");
        } else {
            document.documentElement.removeAttribute("data-theme");
            themeBtn.innerText = "🌙";
            localStorage.setItem("theme", "light");
        }
    }

    const savedTheme = localStorage.getItem("theme") || "light";
    setTheme(savedTheme);

    themeBtn.addEventListener("click", () => {
        const currentTheme = document.documentElement.getAttribute("data-theme");
        if (currentTheme === "dark") {
            setTheme("light");
        } else {
            setTheme("dark");
        }
    });

    function escapeHtml(str) {
        if (!str) return "";
        return String(str)
            .replace(/&/g, "&amp;")
            .replace(/</g, "&lt;")
            .replace(/>/g, "&gt;")
            .replace(/"/g, "&quot;")
            .replace(/'/g, "&#039;");
    }

    function getInitialChar(str) {
        if (!str) return "#";
        const char = str.trim().charAt(0).toUpperCase().normalize("NFD").replace(/[\u0300-\u036f]/g, "");
        return (char >= "A" && char <= "Z") ? char : "#";
    }

    function normalizeSearchText(str) {
        return String(str || "")
            .normalize("NFD")
            .replace(/[\u0300-\u036f]/g, "")
            .toLowerCase();
    }

    function renderNextBatch() {
        if (currentlyRendered >= filteredData.length) return;

        const nextLimit = Math.min(currentlyRendered + BATCH_SIZE, filteredData.length);
        const fragment = document.createDocumentFragment();

        for (let i = currentlyRendered; i < nextLimit; i++) {
            const r = filteredData[i];
            const tr = document.createElement("tr");
            tr.setAttribute("data-index", i);

            const audioBadge = (r.Cancion && r.Cancion !== 'N/A') 
                ? '<span class="badge badge-ok" title="Audio OK" aria-label="Audio OK">&#128077;</span>' 
                : '<span class="badge badge-na" title="Sin Audio" aria-label="Sin Audio">&#9888;</span>';
            const videoBadge = (r.Video && r.Video !== 'N/A') 
                ? '<span class="badge badge-ok" title="Video OK" aria-label="Video OK">&#128077;</span>' 
                : '<span class="badge badge-na" title="Sin Video" aria-label="Sin Video">&#9888;</span>';

            tr.innerHTML = 
                '<td title="' + escapeHtml(r.Artista) + '"><strong>' + escapeHtml(r.Artista) + '</strong></td>' +
                '<td title="' + escapeHtml(r.Titulo) + '">' + escapeHtml(r.Titulo) + '</td>' +
                '<td title="' + escapeHtml(r.Categoria) + '">' + escapeHtml(r.Categoria) + '</td>' +
                '<td title="' + escapeHtml(r.Idioma) + '">' + escapeHtml(r.Idioma) + '</td>' +
                '<td>' + audioBadge + '</td>' +
                '<td>' + videoBadge + '</td>';

            fragment.appendChild(tr);
        }

        tbody.appendChild(fragment);
        currentlyRendered = nextLimit;
    }

    function updateAlphabetButtons() {
        const availableChars = new Set();
        
        filteredData.forEach(r => {
            const val = r[currentSort.col] || "";
            availableChars.add(getInitialChar(val));
        });

        const buttons = alphabetBar.querySelectorAll(".alpha-btn");
        buttons.forEach(btn => {
            const char = btn.getAttribute("data-char");
            btn.disabled = !availableChars.has(char);
        });
    }

    function buildAlphabetBar() {
        alphabetBar.innerHTML = "";
        const chars = ["#", ... "ABCDEFGHIJKLMNOPQRSTUVWXYZ".split("")];

        chars.forEach(char => {
            const btn = document.createElement("button");
            btn.className = "alpha-btn";
            btn.textContent = char;
            btn.setAttribute("data-char", char);

            btn.addEventListener("click", () => scrollToChar(char));
            alphabetBar.appendChild(btn);
        });
    }

    function scrollToChar(char) {
        const targetIndex = filteredData.findIndex(r => {
            const val = r[currentSort.col] || "";
            return getInitialChar(val) === char;
        });

        if (targetIndex === -1) return;

        while (currentlyRendered <= targetIndex) {
            renderNextBatch();
        }

        const targetRow = tbody.querySelector('tr[data-index="' + targetIndex + '"]');
        if (targetRow) {
            targetRow.scrollIntoView({ behavior: "smooth", block: "start" });
        }
    }

    function resetAndRender() {
        tbody.innerHTML = "";
        currentlyRendered = 0;
        scrollContainer.scrollTop = 0;

        counter.innerText = "Canciones: " + filteredData.length + " de " + rawData.length;

        if (filteredData.length === 0) {
            tbody.innerHTML = '<tr><td colspan="6" style="text-align:center; padding:30px; color:var(--text-secondary);">No se encontraron canciones</td></tr>';
            updateAlphabetButtons();
            return;
        }

        renderNextBatch();
        updateAlphabetButtons();
    }

    function applyFiltersAndSort() {
        const q = normalizeSearchText(document.getElementById("searchBox").value).trim();
        const multiVal = document.getElementById("multiFilter").value;

        filteredData = rawData.filter(function(r) {
            const isMulti = (r.Carpeta || "").toUpperCase().includes("[MULTI]");
            if (multiVal === "single" && isMulti) {
                return false;
            }
            if (multiVal === "multi" && !isMulti) {
                return false;
            }
            if (!q) return true;
                 return normalizeSearchText(r.Artista).includes(q) ||
                     normalizeSearchText(r.Titulo).includes(q) ||
                     normalizeSearchText(r.Categoria).includes(q) ||
                     normalizeSearchText(r.Idioma).includes(q) ||
                     normalizeSearchText(r.Carpeta).includes(q);
        });

        filteredData.sort(function(a, b) {
            const va = (a[currentSort.col] || "").toLowerCase();
            const vb = (b[currentSort.col] || "").toLowerCase();
            if (va < vb) return currentSort.asc ? -1 : 1;
            if (va > vb) return currentSort.asc ? 1 : -1;
            return 0;
        });

        resetAndRender();
    }

    function debounce(func, wait) {
        let timeout;
        return function(...args) {
            clearTimeout(timeout);
            timeout = setTimeout(() => func.apply(this, args), wait);
        };
    }

    scrollContainer.addEventListener("scroll", function() {
        if (scrollContainer.scrollTop + scrollContainer.clientHeight >= scrollContainer.scrollHeight - 120) {
            renderNextBatch();
        }
    });

    document.getElementById("searchBox").addEventListener("input", debounce(applyFiltersAndSort, 150));
    document.getElementById("multiFilter").addEventListener("change", applyFiltersAndSort);

    const headers = document.querySelectorAll("#songsTable th");
    headers.forEach(function(th) {
        th.addEventListener("click", function() {
            const col = th.getAttribute("data-col");
            if (currentSort.col === col) {
                currentSort.asc = !currentSort.asc;
            } else {
                currentSort.col = col;
                currentSort.asc = true;
            }

            headers.forEach(function(h) { h.classList.remove("sort-asc", "sort-desc"); });
            th.classList.add(currentSort.asc ? "sort-asc" : "sort-desc");

            applyFiltersAndSort();
        });
    });

    const defaultTh = document.querySelector('th[data-col="Artista"]');
    if (defaultTh) defaultTh.classList.add("sort-asc");

    buildAlphabetBar();
    applyFiltersAndSort();
});
</script>

</body>
</html>
"@

$utf8NoBom = New-Object System.Text.UTF8Encoding($false)
[System.IO.File]::WriteAllText($outputHtml, $htmlContent, $utf8NoBom)

Write-Host "HTML actualizado con corrección de modo oscuro guardado en: $outputHtml" -ForegroundColor Green