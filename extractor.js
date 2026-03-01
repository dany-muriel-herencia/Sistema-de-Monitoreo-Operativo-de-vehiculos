const fs = require('fs');
const path = require('path');

// Ruta global del proyecto
const rootDir = 'c:/laragon/www/Proyecto de flotas/Sistema-de-Monitoreo-Operativo-de-vehiculos/backend/infraestructura';

// Extensiones de archivos que quieres incluir
const fileExtensions = ['.dart', '.ts', '.html', '.css', '.md', '.java', '.kt', '.swift', '.xml', '.yaml', '.gradle', '.properties'];

// Nombres de carpetas que NO quieres procesar (Módulos y carpetas de sistema)
const ignoredFolders = [
  'node_modules', 
  'vendor', 
  '.git', 
  '.idea', 
  '.vscode', 
  'build', 
  'dist', 
  '.gradle'
];

// Archivo de salida
const outputFile = path.join(__dirname, 'codigoExtraido.txt');

/**
 * Función para recorrer carpetas ignorando módulos y carpetas pesadas
 */
function readDirectory(dir, collectedFiles = []) {
  const files = fs.readdirSync(dir);

  files.forEach((file) => {
    const fullPath = path.join(dir, file);
    const stat = fs.statSync(fullPath);

    if (stat.isDirectory()) {
      // ANÁLISIS LÓGICO: Si el nombre de la carpeta está en la lista negra, la saltamos
      if (ignoredFolders.includes(file)) {
        return; 
      }
      readDirectory(fullPath, collectedFiles);
    } else if (fileExtensions.includes(path.extname(file))) {
      collectedFiles.push(fullPath);
    }
  });

  return collectedFiles;
}

/**
 * Función para extraer el contenido de los archivos
 */
function extractContent(files) {
  let content = '';

  files.forEach((file) => {
    try {
      const fileContent = fs.readFileSync(file, 'utf8');
      // Usamos una cabecera más clara para separar archivos
      content += `\n\n// ==========================================\n`;
      content += `// ARCHIVO: ${file}\n`;
      content += `// ==========================================\n\n`;
      content += fileContent;
      content += `\n\n// ---- FIN DE ARCHIVO ----\n`;
    } catch (err) {
      console.error(`Error leyendo ${file}: ${err.message}`);
    }
  });

  return content;
}

// Ejecutar el proceso
console.log(`Iniciando extracción en: ${rootDir}...`);

if (fs.existsSync(rootDir)) {
  const filesToRead = readDirectory(rootDir);
  const extractedContent = extractContent(filesToRead);

  fs.writeFileSync(outputFile, extractedContent, 'utf8');
  console.log(`Proceso completado.`);
  console.log(`Total de archivos procesados: ${filesToRead.length}`);
  console.log(`Código guardado en: ${outputFile}`);
} else {
  console.error(`La ruta especificada no existe: ${rootDir}`);
}