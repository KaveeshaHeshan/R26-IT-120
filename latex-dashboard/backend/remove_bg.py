import sys
import subprocess
try:
    from PIL import Image
except ImportError:
    subprocess.check_call([sys.executable, "-m", "pip", "install", "pillow"])
    from PIL import Image

def make_transparent(input_path, output_path):
    img = Image.open(input_path).convert("RGBA")
    data = img.load()
    width, height = img.size
    
    # get background color from top-left pixel
    bg_color = data[0, 0]
    
    # We will make pixels close to bg_color transparent
    tolerance = 25
    for y in range(height):
        for x in range(width):
            r, g, b, a = data[x, y]
            if abs(r - bg_color[0]) < tolerance and \
               abs(g - bg_color[1]) < tolerance and \
               abs(b - bg_color[2]) < tolerance:
                data[x, y] = (r, g, b, 0)
                
    img.save(output_path, "PNG")

make_transparent(
    r"d:\4YS1\RP\START\KPI Dashboard\R26-IT-120\latex-dashboard\frontend\src\assets\logo.png",
    r"d:\4YS1\RP\START\KPI Dashboard\R26-IT-120\latex-dashboard\frontend\src\assets\logo_transparent.png"
)
print("Successfully created logo_transparent.png")
