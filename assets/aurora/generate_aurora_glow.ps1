# Generates the Aetheris aurora glow texture: a white radial falloff on a
# transparent background, meant to be tinted at runtime (ImageColor3).
#
# Upload the result to Roblox (Creator Dashboard -> Development Items ->
# Images), then put the new rbxassetid:// into Constants.AuroraGlow (or call
# Aetheris.SetAuroraTexture). Until then the library keeps using its
# procedural layered-circle bloom, so nothing breaks.
#
#   powershell -ExecutionPolicy Bypass -File assets/aurora/generate_aurora_glow.ps1
#
# Falloff is the exponent applied to (1 - d): 2.4 reads as a soft, wide glow;
# lower it for a tighter core, raise it for an even fainter tail.

param(
	[int]$Size = 512,
	[double]$Falloff = 2.4,
	[string]$Out = (Join-Path $PSScriptRoot "aurora_glow.png")
)

Add-Type -AssemblyName System.Drawing

$source = @"
using System;
using System.Drawing;
using System.Drawing.Imaging;
using System.Runtime.InteropServices;

public static class AuroraGlow
{
    public static void Generate(string path, int size, double falloff)
    {
        using (var bmp = new Bitmap(size, size, PixelFormat.Format32bppArgb))
        {
            var data = bmp.LockBits(new Rectangle(0, 0, size, size), ImageLockMode.WriteOnly, PixelFormat.Format32bppArgb);
            var px = new int[size * size];
            double c = (size - 1) / 2.0;
            double r = size / 2.0;
            var rng = new Random(1);
            for (int y = 0; y < size; y++)
            {
                for (int x = 0; x < size; x++)
                {
                    double dx = (x - c) / r;
                    double dy = (y - c) / r;
                    double d = Math.Sqrt(dx * dx + dy * dy);
                    double a = d < 1.0 ? Math.Pow(1.0 - d, falloff) : 0.0;
                    int alpha = (int)Math.Round(a * 255.0);
                    // +-1 level dither: breaks 8-bit banding across the wide tail.
                    alpha += rng.Next(-1, 2);
                    if (alpha < 0) { alpha = 0; }
                    if (alpha > 255) { alpha = 255; }
                    px[y * size + x] = (alpha << 24) | (255 << 16) | (255 << 8) | 255;
                }
            }
            Marshal.Copy(px, 0, data.Scan0, px.Length);
            bmp.UnlockBits(data);
            bmp.Save(path, ImageFormat.Png);
        }
    }
}
"@

Add-Type -TypeDefinition $source -ReferencedAssemblies System.Drawing
[AuroraGlow]::Generate($Out, $Size, $Falloff)
Write-Output "wrote $Out ($Size x $Size, falloff $Falloff)"
