# Rebuild all brand assets from the platform-independent vector paths.
# Requires Windows PowerShell and the built-in System.Drawing assembly.
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing
$root = Split-Path $PSScriptRoot -Parent
$brand = Get-Content (Join-Path $root 'assets/branding/mark.json') -Raw | ConvertFrom-Json
function Write-AssetText($relative, $content) {
    $path = Join-Path $root $relative
    [System.IO.Directory]::CreateDirectory((Split-Path $path -Parent)) | Out-Null
    [System.IO.File]::WriteAllText($path, $content, [System.Text.UTF8Encoding]::new($false))
}
function Render-Mark($relative, [int]$size, [bool]$background, [float]$zoom = 1.0) {
    $bitmap = [System.Drawing.Bitmap]::new($size * 4, $size * 4)
    $g = [System.Drawing.Graphics]::FromImage($bitmap)
    $g.SmoothingMode = 'AntiAlias'
    if ($background) { $g.Clear([System.Drawing.ColorTranslator]::FromHtml($brand.background)) }
    $g.TranslateTransform($size * 2, $size * 2)
    $g.ScaleTransform($size * 4 / 108 * $zoom, $size * 4 / 108 * $zoom)
    $g.TranslateTransform(-54, -54)
    foreach ($part in $brand.paths) {
        $path = [System.Drawing.Drawing2D.GraphicsPath]::new()
        $tokens = $part.data.Split(' ')
        $i = 0; $x = 0.0; $y = 0.0
        while ($i -lt $tokens.Length) {
            $op = $tokens[$i++]
            switch ($op) {
                'M' { $x = [float]$tokens[$i++]; $y = [float]$tokens[$i++]; $path.StartFigure() }
                'L' {
                    $nx = [float]$tokens[$i++]; $ny = [float]$tokens[$i++]
                    $path.AddLine($x, $y, $nx, $ny); $x = $nx; $y = $ny
                }
                'C' {
                    $a = [float]$tokens[$i++]; $b = [float]$tokens[$i++]
                    $c = [float]$tokens[$i++]; $d = [float]$tokens[$i++]
                    $nx = [float]$tokens[$i++]; $ny = [float]$tokens[$i++]
                    $path.AddBezier($x, $y, $a, $b, $c, $d, $nx, $ny); $x = $nx; $y = $ny
                }
                'Z' { $path.CloseFigure() }
                default { throw "Unsupported vector command: $op" }
            }
        }
        $brush = [System.Drawing.SolidBrush]::new([System.Drawing.ColorTranslator]::FromHtml($part.color))
        $g.FillPath($brush, $path); $brush.Dispose(); $path.Dispose()
    }
    $output = [System.Drawing.Bitmap]::new($size, $size)
    $og = [System.Drawing.Graphics]::FromImage($output)
    $og.InterpolationMode = 'HighQualityBicubic'
    $og.DrawImage($bitmap, 0, 0, $size, $size)
    $target = Join-Path $root $relative
    [System.IO.Directory]::CreateDirectory((Split-Path $target -Parent)) | Out-Null
    $output.Save($target, [System.Drawing.Imaging.ImageFormat]::Png)
    $og.Dispose(); $output.Dispose(); $g.Dispose(); $bitmap.Dispose()
}
$svgPaths = ($brand.paths | ForEach-Object { '<path fill="{0}" d="{1}"/>' -f $_.color, $_.data }) -join "`n"
Write-AssetText 'assets/branding/allflag-mark.svg' ('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 108 108"><rect width="108" height="108" rx="24" fill="{0}"/>{1}</svg>' -f $brand.background, $svgPaths)
Render-Mark 'assets/branding/allflag-icon.png' 1024 $true 1.25
foreach ($entry in @(@('mdpi',48),@('hdpi',72),@('xhdpi',96),@('xxhdpi',144),@('xxxhdpi',192))) {
    Render-Mark "android/app/src/main/res/mipmap-$($entry[0])/ic_launcher.png" $entry[1] $true 1.25
    Render-Mark "android/app/src/main/res/drawable-$($entry[0])/brand_splash.png" ($entry[1] * 3) $true 1.0
}
$vectorPaths = ($brand.paths | ForEach-Object { '<path android:fillColor="{0}" android:pathData="{1}"/>' -f $_.color, $_.data }) -join "`n"
Write-AssetText 'android/app/src/main/res/drawable/ic_allflag_foreground.xml' ('<vector xmlns:android="http://schemas.android.com/apk/res/android" android:width="108dp" android:height="108dp" android:viewportWidth="108" android:viewportHeight="108">{0}</vector>' -f $vectorPaths)
Write-AssetText 'android/app/src/main/res/mipmap-anydpi-v26/ic_launcher.xml' '<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android"><background android:drawable="@color/brand_navy"/><foreground android:drawable="@drawable/ic_allflag_foreground"/></adaptive-icon>'
foreach ($mode in @('values','values-night')) {
    $surface = if ($mode -eq 'values') { '#F7F8FA' } else { '#0E1624' }
    Write-AssetText "android/app/src/main/res/$mode/colors.xml" "<resources><color name=`"brand_navy`">$($brand.background)</color><color name=`"launch_surface`">$surface</color></resources>"
}
foreach ($folder in @('drawable','drawable-v21')) {
    Write-AssetText "android/app/src/main/res/$folder/launch_background.xml" '<layer-list xmlns:android="http://schemas.android.com/apk/res/android"><item android:drawable="@color/launch_surface"/><item><bitmap android:gravity="center" android:src="@drawable/brand_splash"/></item></layer-list>'
}
foreach ($mode in @('values-v31','values-night-v31')) {
    $parent = if ($mode -eq 'values-v31') { '@android:style/Theme.Light.NoTitleBar' } else { '@android:style/Theme.Black.NoTitleBar' }
    Write-AssetText "android/app/src/main/res/$mode/styles.xml" "<resources><style name=`"LaunchTheme`" parent=`"$parent`"><item name=`"android:windowSplashScreenBackground`">@color/launch_surface</item><item name=`"android:windowSplashScreenAnimatedIcon`">@drawable/ic_allflag_foreground</item><item name=`"android:windowSplashScreenIconBackgroundColor`">@color/brand_navy</item><item name=`"android:windowBackground`">@drawable/launch_background</item></style></resources>"
}
$icons = Get-Content (Join-Path $root 'ios/Runner/Assets.xcassets/AppIcon.appiconset/Contents.json') -Raw | ConvertFrom-Json
foreach ($entry in $icons.images) {
    $size = [int]([double]::Parse($entry.size.Split('x')[0], [Globalization.CultureInfo]::InvariantCulture) * [int]$entry.scale.TrimEnd('x'))
    Render-Mark "ios/Runner/Assets.xcassets/AppIcon.appiconset/$($entry.filename)" $size $true 1.25
}
foreach ($scale in 1..3) {
    $suffix = if ($scale -eq 1) { '' } else { "@${scale}x" }
    Render-Mark "ios/Runner/Assets.xcassets/LaunchImage.imageset/LaunchImage$suffix.png" (144 * $scale) $true 1.0
}
Write-Output 'Generated AllFlag SVG, PNG, Android adaptive icons/splash and iOS icon/launch assets.'
