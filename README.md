# 🎤 UltraStar Deluxe HTML Catalog Generator

Una solución automatizada en **PowerShell 7** para escanear carpetas de canciones de **UltraStar Delux**, extraer su metadata (Artista, Título, Categoría, Idioma, presencia de Audio/Video) y generar un **listado interactivo en HTML** optimizado para su visualización en pantallas de gran formato (Smart TVs / Monitores de Karaoke).
Una fácil solución cuando tienes una gran cantidad de canciones en UltraStar Deluxe.
---

## 🚀 Características Principales

* **Generación Automática de Metadata**: Procesa ficheros `.txt` de UltraStar para extraer etiquetas principales (`#ARTIST`, `#TITLE`, `#GENRE`, `#LANGUAGE`, etc.).
* **Interfaz HTML Adaptada a TV**: 
  * **Tipografía Escalada**: Diseñada para lecturas a larga distancia.
  * **Modo Claro / Oscuro**: Alternancia de temas persistente mediante un botón.
  * **Cabecera Estable**: El diseño del buscador y los controles permanecen inmóviles aunque cambien los resultados.
* **Alto Rendimiento y Carga Fluida**:
  * **Renderizado por Bloques (Scroll Infinito)**: Evita bloqueos del navegador cargando las filas dinámicamente.
  * **Búsqueda con *Debounce***: Filtrado en tiempo real sin congelar la interfaz.
* **Navegación Alfabética (`#`, `A-Z`)**:
  * Barra de acceso rápido a pie de página para saltar inmediatamente a los registros por su inicial.
  * Deshabilitación automática de caracteres sin resultados disponibles.

---

## 📋 Requisitos del Sistema

* **Sistema Operativo**: Windows 10
* **Entorno de Ejecución**: **PowerShell 7.x (Core)**  
  *(Nota: Diseñado y probado para PowerShell 7. No se garantiza compatibilidad completa con Windows PowerShell 5.1 preinstalado debido al manejo del encoding UTF-8).*

---

## 🛠️ Instalación y Uso

### 1. Clonar el repositorio
```bash
git clone [https://github.com/tu-usuario/ultrastar-catalog-generator.git](https://github.com/tu-usuario/ultrastar-catalog-generator.git)
cd ultrastar-catalog-generator