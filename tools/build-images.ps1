# =============================================================================
# Genera assets/img a partir de los flyers de "fotos productos".
# Sólo usa System.Drawing de .NET: no hace falta instalar nada.
#
#     powershell -ExecutionPolicy Bypass -File tools\build-images.ps1
#
# Todas las fotos salen a 900x1125 px (4:5), la proporción del marco de la
# galería. Los recortes apaisados (cartas de color, trío de joggers) se centran
# sobre un fondo tomado del propio flyer en vez de recortarse por los lados.
# =============================================================================

Add-Type -AssemblyName System.Drawing

$root = Split-Path -Parent $PSScriptRoot
$src  = Join-Path $root "fotos productos"
$out  = Join-Path $root "assets\img"
New-Item -ItemType Directory -Force -Path $out | Out-Null

$targetW = 900
$targetH = 1125

function Save-Jpeg($bitmap, $path, $quality) {
  $codec = [System.Drawing.Imaging.ImageCodecInfo]::GetImageEncoders() | Where-Object { $_.MimeType -eq 'image/jpeg' }
  $params = New-Object System.Drawing.Imaging.EncoderParameters(1)
  $params.Param[0] = New-Object System.Drawing.Imaging.EncoderParameter([System.Drawing.Imaging.Encoder]::Quality, [int64]$quality)
  $bitmap.Save($path, $codec, $params)
}

function New-Canvas($w, $h) {
  $canvas = New-Object System.Drawing.Bitmap($w, $h)
  $g = [System.Drawing.Graphics]::FromImage($canvas)
  $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
  $g.SmoothingMode     = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
  $g.PixelOffsetMode   = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
  return @($canvas, $g)
}

# $fit = $true  -> el recorte se centra completo y el resto se rellena.
# $fit = $false -> el recorte llena el marco (debe venir ya en 4:5).
function Export-Shot($file, $name, $x, $y, $w, $h, $fit) {
  $image = [System.Drawing.Image]::FromFile((Join-Path $src $file))
  $pair = New-Canvas $targetW $targetH
  $canvas = $pair[0]; $g = $pair[1]

  if ($fit) {
    $bmp = New-Object System.Drawing.Bitmap($image)
    $pad = $bmp.GetPixel($x + 3, $y + 3)    # fondo real del flyer en esa zona
    $bmp.Dispose()
    $g.Clear($pad)

    $scale = [Math]::Min($targetW / $w, $targetH / $h)
    $dw = [int]($w * $scale); $dh = [int]($h * $scale)
    $dest = New-Object System.Drawing.Rectangle([int](($targetW - $dw) / 2), [int](($targetH - $dh) / 2), $dw, $dh)
  } else {
    $dest = New-Object System.Drawing.Rectangle(0, 0, $targetW, $targetH)
  }

  $g.DrawImage($image, $dest, (New-Object System.Drawing.Rectangle($x, $y, $w, $h)), [System.Drawing.GraphicsUnit]::Pixel)
  Save-Jpeg $canvas (Join-Path $out "$name.jpg") 88
  "  {0,-22} [{1},{2} {3}x{4}]{5}" -f "$name.jpg", $x, $y, $w, $h, $(if ($fit) { " centrado" } else { "" })

  $g.Dispose(); $canvas.Dispose(); $image.Dispose()
}

"Blusa.png"
Export-Shot "Blusa.png" "blusa-1" 0   0   600 750 $false
Export-Shot "Blusa.png" "blusa-2" 0   450 600 750 $false
Export-Shot "Blusa.png" "blusa-3" 640 380 480 600 $false

"Vestido.png"
Export-Shot "Vestido.png" "vestido-1" 530 0   720 900  $false
Export-Shot "Vestido.png" "vestido-2" 540 340 640 800 $false
Export-Shot "Vestido.png" "vestido-3" 70  250 480 600 $false

"Pantalon.png"
Export-Shot "Pantalon.png" "pantalon-1" 620 0   600 750 $false
Export-Shot "Pantalon.png" "pantalon-2" 620 480 600 750 $false
Export-Shot "Pantalon.png" "pantalon-3" 50  440 570 712 $false

# ── Flyers completos para el carrusel del hero ───────────────────────────────
# No se recortan: se muestran enteros, sólo se reducen de peso. Los PNG de
# origen pesan ~2 MB cada uno y no sirven para una página.
function Export-Flyer($file, $name) {
  $image = [System.Drawing.Image]::FromFile((Join-Path $src $file))

  # 1.0 como double: con "1" entero, PowerShell elige Math::Min(int,int) y
  # redondea el factor de escala a 1, dejando el flyer en su tamaño original.
  $maxSide = 1100.0
  $scale = [Math]::Min(1.0, $maxSide / [Math]::Max($image.Width, $image.Height))
  $w = [int]($image.Width * $scale)
  $h = [int]($image.Height * $scale)

  $pair = New-Canvas $w $h
  $canvas = $pair[0]; $g = $pair[1]
  $g.DrawImage($image, (New-Object System.Drawing.Rectangle(0, 0, $w, $h)))
  Save-Jpeg $canvas (Join-Path $out "$name.jpg") 86
  "  {0,-22} {1}x{2} (flyer completo)" -f "$name.jpg", $w, $h

  $g.Dispose(); $canvas.Dispose(); $image.Dispose()
}

"Flyers para el carrusel"
Export-Flyer "Blusa.png" "flyer-blusa"
Export-Flyer "Vestido.png" "flyer-vestido"
Export-Flyer "Pantalon.png" "flyer-pantalon"

# El logo (assets/img/logo.png, logo.jpg, icon.png) se genera a partir de Logo.jpg
# en la raíz y ya no se toca desde este script.

""
"Listo. " + (Get-ChildItem $out).Count + " archivos en assets\img."
