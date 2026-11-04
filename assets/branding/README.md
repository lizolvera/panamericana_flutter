# Icono de Panamericana Clientes

Diseño vectorial del continente con la paleta de lib/ui/theme/app_colors.dart:
- Vino #7E2F31 para el fondo (color principal de botones y encabezados).
- Blanco cálido #FDFCFB para el mapa.

Costas e islas de Natural Earth 1:110m (dominio público), sin fronteras políticas.
Incluye Norteamérica, Centroamérica, Sudamérica, Groenlandia y principales islas.
La silueta se ajusta al círculo seguro del icono adaptativo de Android.
Fuente: https://github.com/nvkelso/natural-earth-vector/blob/master/geojson/ne_110m_land.geojson
Licencia: https://www.naturalearthdata.com/about/terms-of-use/
El SVG es la fuente editable. google-play-icon-512.png es el icono cuadrado opaco
para subir manualmente en la ficha de Play Store. No lleva esquinas redondeadas:
Android y Google Play aplican sus propias máscaras.

Android incluye PNG por densidad para equipos anteriores a API 26, icono adaptativo
para API 26+ y capa monocromática para iconos temáticos. El icono de la ficha en
Play Console es independiente del icono instalado; actualizarlo en la ficha.
El nombre temporal del paquete con (unreviewed) depende de la configuración y
revisión de Play Console y no se elimina cambiando el icono del AAB.

Para regenerar los PNG con ImageMagick:

    convert -background none assets/branding/panamericana-icon.svg -resize 512x512 -depth 8 PNG32:assets/branding/google-play-icon-512.png

Usar tamaños 48, 72, 96, 144 y 192 para mipmap mdpi, hdpi, xhdpi, xxhdpi y xxxhdpi.

El nombre PANAMERICANA utiliza DejaVu Sans Bold convertido a contornos vectoriales
para conservar su aspecto en Android sin depender de fuentes instaladas.
