# Renders the WellnessHabitTrack logo (sun, two leaves and a figure) into the PNGs used by
# flutter_launcher_icons and flutter_native_splash. Run from the mobile/ folder:
#   powershell -ExecutionPolicy Bypass -File tool/generate_branding.ps1
Add-Type -AssemblyName System.Drawing

$out = Join-Path $PSScriptRoot '..\assets\branding'
New-Item -ItemType Directory -Force $out | Out-Null

function Color($hex) { [System.Drawing.ColorTranslator]::FromHtml($hex) }

# Design space is 1000x1000; $scale shrinks the mark inside the canvas.
function Draw-Logo($g, [int]$size, [double]$scale) {
    $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
    $unit = $size / 1000.0 * $scale
    $offset = ($size - 1000 * $unit) / 2
    $g.TranslateTransform([float]$offset, [float]$offset)
    $g.ScaleTransform([float]$unit, [float]$unit)

    $sun = New-Object System.Drawing.SolidBrush (Color '#F9A825')
    $g.FillEllipse($sun, 405, 170, 190, 190)

    $left = New-Object System.Drawing.Drawing2D.GraphicsPath
    $left.AddBezier(500, 780, 290, 760, 190, 570, 205, 400)
    $left.AddBezier(205, 400, 390, 420, 500, 570, 500, 780)
    $g.FillPath((New-Object System.Drawing.SolidBrush (Color '#9CCC65')), $left)

    $right = New-Object System.Drawing.Drawing2D.GraphicsPath
    $right.AddBezier(500, 780, 710, 760, 810, 570, 795, 400)
    $right.AddBezier(795, 400, 610, 420, 500, 570, 500, 780)
    $g.FillPath((New-Object System.Drawing.SolidBrush (Color '#66BB6A')), $right)

    $figure = New-Object System.Drawing.Drawing2D.GraphicsPath
    $figure.AddBezier(500, 800, 430, 690, 440, 580, 500, 530)
    $figure.AddBezier(500, 530, 560, 580, 570, 690, 500, 800)
    $gold = New-Object System.Drawing.SolidBrush (Color '#FFD54F')
    $g.FillPath($gold, $figure)
    $g.FillEllipse($gold, 455, 430, 90, 90)
    $g.ResetTransform()
}

function Save-Png([int]$size, [string]$name, [bool]$background, [double]$scale) {
    $bmp = New-Object System.Drawing.Bitmap $size, $size, ([System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $g.Clear([System.Drawing.Color]::Transparent)
    if ($background) {
        $rect = New-Object System.Drawing.Rectangle 0, 0, $size, $size
        $brush = New-Object System.Drawing.Drawing2D.LinearGradientBrush $rect, (Color '#1B5E20'), (Color '#43A047'), 45
        $g.FillRectangle($brush, $rect)
    }
    Draw-Logo $g $size $scale
    $g.Dispose()
    $bmp.Save((Join-Path $out $name), [System.Drawing.Imaging.ImageFormat]::Png)
    $bmp.Dispose()
    Write-Output "Wrote $name"
}

Save-Png 1024 'icon.png' $true 0.82
Save-Png 1024 'icon_foreground.png' $false 0.62
Save-Png 1152 'splash_logo.png' $false 0.5
