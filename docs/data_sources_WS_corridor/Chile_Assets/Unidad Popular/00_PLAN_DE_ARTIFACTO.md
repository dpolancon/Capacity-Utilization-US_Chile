# Plan del artefacto en Markdown

## Objetivo

Convertir el apunte en un sistema reutilizable, no en un simple volcado lineal de texto. La idea es que cada componente tenga una función distinta y enlazada.

## Arquitectura propuesta

```text
unidad-popular-artifact/
├── README.md
├── 00_PLAN_DE_ARTIFACTO.md
├── 01_NOTA_MAESTRA.md
├── 02_MAPA_ARGUMENTAL.md
├── 03_LEDGER_DE_FUENTES.md
├── 04_BIBLIOGRAFIA_Y_AUDITORIA.md
├── 05_REGISTRO_DE_TABLAS_Y_FIGURAS.md
├── 06_PROXIMOS_PASOS.md
├── assets/
│   └── README.md
└── source/
    └── apunte_HistoriaSocial_19571973.pdf
```

## Lógica interna

### 1. `01_NOTA_MAESTRA.md`
Archivo principal. Conserva la narrativa, pero con front matter, secciones limpias, conceptos clave y enlaces internos.

### 2. `02_MAPA_ARGUMENTAL.md`
Sirve como reverse outline. Cada sección responde:
- cuál es la afirmación central,
- cuál es el mecanismo,
- cuál es la evidencia,
- qué fuentes la sostienen.

### 3. `03_LEDGER_DE_FUENTES.md`
No es una bibliografía normal. Es un ledger funcional:
- tipo de fuente,
- rol analítico,
- secciones donde opera,
- prioridad,
- estatus bibliográfico.

### 4. `04_BIBLIOGRAFIA_Y_AUDITORIA.md`
Divide las referencias en:
- obras citadas directamente,
- citas indirectas / de segunda mano,
- menciones conceptuales aún no resueltas,
- observaciones de limpieza bibliográfica.

### 5. `05_REGISTRO_DE_TABLAS_Y_FIGURAS.md`
Convierte tablas y figuras en objetos reutilizables para:
- clases,
- diapositivas,
- papers,
- comparación con otros casos.

### 6. `06_PROXIMOS_PASOS.md`
Mantiene el backlog editorial:
- completar referencias,
- separar bibliografía primaria/secundaria,
- poblar assets,
- crear variantes para docencia o paper.

## Cuándo conviene usar un solo archivo y cuándo varios

### Un solo archivo
Conviene si solo quieres leer, imprimir o compartir un apunte estable.

### Varios archivos conectados
Conviene si quieres:
- reutilizar secciones en otros textos,
- preservar trazabilidad de fuentes,
- convertirlo en base para clases, papers o capítulos,
- actualizar bibliografía sin tocar el texto central,
- separar evidencia visual del argumento.

## Recomendación operativa

Usa **varios archivos conectados** como sistema base. Luego, si necesitas una versión compacta, exporta una edición unificada a partir del conjunto.
