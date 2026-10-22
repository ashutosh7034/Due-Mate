# Generates the Deadline launcher icon set and the white notification icon.
# Uses inline C# (GDI+) so no extra tooling is required. Safe to re-run.
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing

$code = @'
using System;
using System.Drawing;
using System.Drawing.Drawing2D;
using System.Drawing.Imaging;
using System.IO;

public static class DeadlineIcons
{
    static readonly Color Navy  = Color.FromArgb(255, 27, 42, 74);
    static readonly Color Green = Color.FromArgb(255, 46, 158, 107);
    static readonly Color White = Color.White;

    static GraphicsPath Rounded(RectangleF r, float radius)
    {
        var p = new GraphicsPath();
        float d = radius * 2f;
        p.AddArc(r.X, r.Y, d, d, 180, 90);
        p.AddArc(r.Right - d, r.Y, d, d, 270, 90);
        p.AddArc(r.Right - d, r.Bottom - d, d, d, 0, 90);
        p.AddArc(r.X, r.Bottom - d, d, d, 90, 90);
        p.CloseFigure();
        return p;
    }

    public static void Launcher(int size, string outPath)
    {
        using (var bmp = new Bitmap(size, size))
        using (var g = Graphics.FromImage(bmp))
        {
            g.SmoothingMode = SmoothingMode.AntiAlias;
            g.Clear(Color.Transparent);
            float s = size;

            float inset = s * 0.03f;
            using (var path = Rounded(new RectangleF(inset, inset, s - 2 * inset, s - 2 * inset), s * 0.24f))
            using (var brush = new SolidBrush(Navy))
                g.FillPath(brush, path);

            // Clock ring
            float pad = s * 0.24f;
            using (var pen = new Pen(White, s * 0.055f))
                g.DrawEllipse(pen, pad, pad, s - 2 * pad, s - 2 * pad);

            // Clock hands
            float cx = s / 2f, cy = s / 2f;
            using (var handPen = new Pen(White, s * 0.06f))
            {
                handPen.StartCap = LineCap.Round;
                handPen.EndCap = LineCap.Round;
                g.DrawLine(handPen, cx, cy, cx, cy - s * 0.13f);
                g.DrawLine(handPen, cx, cy, cx + s * 0.11f, cy + s * 0.02f);
            }

            // Green check badge, lower-right
            float bsize = s * 0.42f;
            float bx = s - bsize - s * 0.10f;
            float by = s - bsize - s * 0.10f;
            using (var whiteBrush = new SolidBrush(White))
                g.FillEllipse(whiteBrush, bx, by, bsize, bsize);
            float ip = s * 0.045f;
            var gb = new RectangleF(bx + ip, by + ip, bsize - 2 * ip, bsize - 2 * ip);
            using (var greenBrush = new SolidBrush(Green))
                g.FillEllipse(greenBrush, gb);
            using (var chk = new Pen(White, s * 0.035f))
            {
                chk.StartCap = LineCap.Round;
                chk.EndCap = LineCap.Round;
                var pts = new[]
                {
                    new PointF(gb.X + gb.Width * 0.24f, gb.Y + gb.Height * 0.52f),
                    new PointF(gb.X + gb.Width * 0.43f, gb.Y + gb.Height * 0.72f),
                    new PointF(gb.X + gb.Width * 0.78f, gb.Y + gb.Height * 0.30f),
                };
                g.DrawLines(chk, pts);
            }

            bmp.Save(outPath, ImageFormat.Png);
        }
    }

    public static void Notification(int size, string outPath)
    {
        using (var bmp = new Bitmap(size, size))
        using (var g = Graphics.FromImage(bmp))
        {
            g.SmoothingMode = SmoothingMode.AntiAlias;
            g.Clear(Color.Transparent);
            float s = size;

            float pad = s * 0.14f;
            using (var pen = new Pen(White, s * 0.10f))
                g.DrawEllipse(pen, pad, pad, s - 2 * pad, s - 2 * pad);

            float cx = s / 2f, cy = s / 2f;
            using (var handPen = new Pen(White, s * 0.11f))
            {
                handPen.StartCap = LineCap.Round;
                handPen.EndCap = LineCap.Round;
                g.DrawLine(handPen, cx, cy, cx, cy - s * 0.20f);
                g.DrawLine(handPen, cx, cy, cx + s * 0.17f, cy + s * 0.03f);
            }

            bmp.Save(outPath, ImageFormat.Png);
        }
    }

    // Draw the launcher art on a transparent canvas at scale, used for the
    // adaptive-icon foreground layer.
    public static void Adaptive(int canvas, string outPath, string tempDir)
    {
        int inner = (int)(canvas * 0.62);
        int off = (canvas - inner) / 2;
        string tmp = Path.Combine(tempDir, "deadline_fg_tmp.png");
        Launcher(inner, tmp);
        using (var bmp = new Bitmap(canvas, canvas))
        using (var g = Graphics.FromImage(bmp))
        {
            g.SmoothingMode = SmoothingMode.AntiAlias;
            g.Clear(Color.Transparent);
            using (var src = Image.FromFile(tmp))
                g.DrawImage(src, off, off, inner, inner);
            bmp.Save(outPath, ImageFormat.Png);
        }
        File.Delete(tmp);
    }
}
'@

Add-Type -TypeDefinition $code -ReferencedAssemblies System.Drawing

$root = Split-Path -Parent $PSScriptRoot
$res  = Join-Path $root 'android\app\src\main\res'

$launcher = @{ 'mdpi' = 48; 'hdpi' = 72; 'xhdpi' = 96; 'xxhdpi' = 144; 'xxxhdpi' = 192 }
foreach ($k in $launcher.Keys) {
    $dir = Join-Path $res "mipmap-$k"
    [DeadlineIcons]::Launcher($launcher[$k], (Join-Path $dir 'ic_launcher.png'))
}

$adaptive = @{ 'mdpi' = 108; 'hdpi' = 162; 'xhdpi' = 216; 'xxhdpi' = 324; 'xxxhdpi' = 432 }
foreach ($k in $adaptive.Keys) {
    $dir = Join-Path $res "mipmap-$k"
    if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir | Out-Null }
    [DeadlineIcons]::Adaptive($adaptive[$k], (Join-Path $dir 'ic_launcher_foreground.png'), $env:TEMP)
}

$notif = @{ 'mdpi' = 24; 'hdpi' = 36; 'xhdpi' = 48; 'xxhdpi' = 72; 'xxxhdpi' = 96 }
foreach ($k in $notif.Keys) {
    $dir = Join-Path $res "drawable-$k"
    if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir | Out-Null }
    [DeadlineIcons]::Notification($notif[$k], (Join-Path $dir 'ic_stat_deadline.png'))
}

Write-Output "Icons generated."
