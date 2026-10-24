# Valois Clothing — landing page

Landing de una sola página para la Blusa Elegancia, el Vestido Navia y el pantalón, con la estructura
tomada de `https://emsa.solucionem.com/` y **todo el contenido en un solo JSON**:
no hay que tocar el HTML ni el CSS para cambiar textos, precios, colores o
productos.

El contenido salió de los flyers de `fotos productos/`, y las fotos de producto
son recortes de esos mismos flyers (ver *Fotos*, más abajo).

## Estructura de archivos

```
.
├── index.html              Esqueleto + copia de respaldo del JSON (generada)
├── data/
│   └── content.json        ← TODO el contenido editable
├── tools/
│   └── sync-content.js     Copia el JSON dentro de index.html
└── assets/
    ├── css/styles.css      Tokens, componentes y responsive
    ├── js/app.js           Lee el JSON y construye la página
    └── img/                Fotos (blusa-1.jpg, vestido-1.jpg, pantalon-1.jpg, logo.png…)
```

`index.html` solo declara tres puntos de montaje:

```html
<header data-render="nav"></header>
<main   data-render="main"></main>
<footer data-render="footer"></footer>
```

## Cómo verla

**Doble clic en `index.html`** funciona. También puedes servirla:

```bash
npx serve .          # o:  python -m http.server 8000
```

### Por qué hay dos copias del contenido

El navegador bloquea `fetch` cuando la página se abre como archivo local
(`file://`), así que el JSON no se puede leer por doble clic. Para que funcione
de las dos formas, `index.html` lleva una copia incrustada:

- **Servida por HTTP** → se lee `data/content.json` (la fuente).
- **Abierta con doble clic** → se lee la copia dentro de `index.html`.

Editas siempre `data/content.json`. Después ejecuta:

```bash
node tools/sync-content.js            # actualiza la copia en index.html
node tools/sync-content.js --check    # sólo avisa si está desfasada (sale 1)
```

Si te olvidas del script, la versión servida ya muestra tus cambios; la que se
abre por doble clic seguirá con el contenido anterior hasta que lo ejecutes.

## Secciones que arma el renderizador

| Orden | Sección | Fuente en el JSON |
|-------|---------|-------------------|
| 1 | Nav sticky con menú móvil | `nav`, `site` |
| 2 | Hero (logo, eyebrow, título, lead, 2 CTA, 3 badges) | `hero` |
| 3 | Producto 01 — Blusa Elegancia (fondo crema) | `products[0]` |
| 4 | Producto 02 — Vestido Navia (fondo oscuro, invertido) | `products[1]` |
| 5 | Producto 03 — Pantalón (fondo claro) | `products[2]` |
| 6 | Beneficios (4 tarjetas con icono) | `benefits` |
| 7 | Cómo comprar (3 pasos) | `steps` |
| 8 | Preguntas frecuentes (acordeón `<details>`) | `faq` |
| 9 | CTA final (fondo negro) | `cta` |
| 10 | Footer en 3 columnas + legal | `footer` |
| — | Botón flotante de WhatsApp | `fab` |

## Editar el contenido

### Cambiar el número de WhatsApp

```json
"whatsapp": {
  "number": "573127661561",
  "greeting": "¡Hola! 👋 Vengo de la página web y quiero información sobre:",
  "closing": "¿Me confirman precio y disponibilidad?"
}
```

Cada botón arma su propio mensaje: al producto se le anexan las opciones
seleccionadas en la ficha (`Estilo: Manga corta · Talla: M`), así el chat llega
con el contexto completo. El enlace se recalcula en cada clic.

### Añadir o quitar un producto

Agrega un objeto a `products`. Se renderiza solo, con su galería, sus grupos de
opciones y su caja de compra:

```json
{
  "id": "chaquetas",
  "theme": "cream",              // cream | light | dark
  "reverse": false,              // true = foto a la derecha
  "eyebrow": "Producto 04 — Abrigo",
  "title": "Chaquetas impermeables.",
  "lead": "Para el invierno de la ciudad.",
  "waProduct": "Chaquetas impermeables",
  "promo": { "text": "2x1", "style": "solid" },   // solid | light
  "description": "…",
  "gallery": [{ "src": "./assets/img/chaqueta1.jpg", "alt": "…" }],
  "options": [
    { "label": "Talla", "type": "chips", "values": ["S", "M", "L"] },
    { "label": "Color", "type": "swatches",
      "values": [{ "value": "Negro", "tone": "#17171A" }] }
  ],
  "specs": ["…"],
  "price": { "label": "Desde", "value": "$120.000" },
  "button": { "label": "Pedir información", "style": "dark" }
}
```

Reglas del renderizador:

- `type: "chips"` → botones de texto; `type: "swatches"` → círculos de color,
  donde `tone` es el hex que se pinta.
- La primera opción de cada grupo queda seleccionada.
- `specs: []` omite la lista de características (así está el producto 03).
- `price.small: true` reduce el tamaño cuando el valor es texto y no una cifra.
- Añade el nuevo `id` a `nav.links` y a `footer.columns` para que aparezca en los
  menús.

### Fotos

Las de `assets/img/` son recortes de los flyers de `fotos productos/`, hechos con
`tools/build-images.ps1` (PowerShell + System.Drawing, sin dependencias). Todos
salen a 900×1125 px (4:5), que es la proporción del marco de la galería:

| Archivo | Origen |
|---------|--------|
| `blusa-1/-2/-3.jpg` | recortes de `Blusa.png` |
| `vestido-1/-2/-3.jpg` | recortes de `Vestido.png` |
| `pantalon-1/-2/-3.jpg` | recortes de `Pantalon.png` |
| `logo.png` | wordmark de `Logo.png`, con el blanco convertido en transparencia |
| `logo.jpg` | el mismo logo sobre crema, para favicon y `og:image` |

Para reemplazarlas por fotos propias basta con sobrescribir el archivo, o apuntar
el `src` del JSON a otro nombre. En el JSON cada foto es
`{ "src": "…", "alt": "…" }`, y acepta un `"webp"` opcional que se sirve con
`<picture>` cuando exista. Si un archivo falta, el marco muestra el texto
alternativo sobre fondo crema en vez del icono de imagen rota.

## Detalles de la implementación

**CSS** — Paleta y métrica en variables sobre `:root`: crema `#f6f1e9`, tinta
`#1d1d1f`, acento sage `#5c7c73`, espresso `#4c2e21` y verde WhatsApp. Un solo
archivo, ordenado tokens → base → utilidades → componentes → secciones →
responsive. Breakpoints en 1000 / 860 / 720 px; el menú pasa a hamburguesa en
720 px.

**JS** — Sin dependencias. Escapa todo lo que viene del JSON antes de insertarlo,
y luego conecta: enlaces de WhatsApp, selectores de opción, galerías con fundido,
menú móvil, aparición al hacer scroll (`IntersectionObserver`) y el respaldo de
imágenes faltantes.

**Accesibilidad** — Skip link, `radiogroup` en los selectores, `aria-expanded` en
el menú, `sr-only` en las muestras de color, `aria-labelledby` por sección y
respeto a `prefers-reduced-motion`.
