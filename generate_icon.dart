import 'dart:io';
import 'package:image/image.dart';

void main() {
  // Create a 512x512 image
  final image = Image(width: 512, height: 512);

  // Fill background with dark navy (#0F1B23)
  fill(image, color: ColorRgb8(15, 27, 35));

  // Draw a lighter circle in the center
  fillCircle(image, x: 256, y: 256, radius: 180, color: ColorRgb8(56, 107, 126));

  // Draw some basic car-like shapes (a rectangle for the body, a smaller one for the roof)
  // Car roof
  fillRect(image, x1: 156, y1: 200, x2: 356, y2: 260, color: ColorRgb8(140, 224, 250));
  // Car body
  fillRect(image, x1: 100, y1: 260, x2: 412, y2: 320, color: ColorRgb8(140, 224, 250));
  
  // Wheels
  fillCircle(image, x: 160, y: 320, radius: 40, color: ColorRgb8(15, 27, 35));
  fillCircle(image, x: 352, y: 320, radius: 40, color: ColorRgb8(15, 27, 35));
  
  // Inner wheels
  fillCircle(image, x: 160, y: 320, radius: 20, color: ColorRgb8(140, 224, 250));
  fillCircle(image, x: 352, y: 320, radius: 20, color: ColorRgb8(140, 224, 250));

  // Draw text "MC"
  drawString(image, 'MC', font: arial48, x: 200, y: 100, color: ColorRgb8(255, 255, 255));

  // Ensure assets directory exists
  final assetsDir = Directory('assets');
  if (!assetsDir.existsSync()) {
    assetsDir.createSync();
  }

  // Save as PNG
  final pngBytes = encodePng(image);
  File('assets/icon.png').writeAsBytesSync(pngBytes);
  print('Icon generated successfully at assets/icon.png');
}
