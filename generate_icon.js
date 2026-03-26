const { createCanvas } = require('canvas');
const fs = require('fs');
const path = require('path');

// Create a 1024x1024 icon
const size = 1024;
const canvas = createCanvas(size, size);
const ctx = canvas.getContext('2d');

// Background - dark navy with gradient
const bgGrad = ctx.createLinearGradient(0, 0, size, size);
bgGrad.addColorStop(0, '#0F1B23');
bgGrad.addColorStop(1, '#1E2B34');
ctx.fillStyle = bgGrad;
ctx.beginPath();
ctx.roundRect(0, 0, size, size, 180);
ctx.fill();

// Outer glow circle
ctx.beginPath();
ctx.arc(size/2, size/2 - 30, 320, 0, Math.PI * 2);
ctx.fillStyle = 'rgba(140, 224, 250, 0.08)';
ctx.fill();

// Car body - sleek silhouette
ctx.save();
ctx.translate(size/2, size/2 - 20);

// Car body main shape
ctx.beginPath();
ctx.moveTo(-250, 60);
ctx.lineTo(-220, 60);
ctx.quadraticCurveTo(-200, -20, -130, -60);
ctx.lineTo(-60, -100);
ctx.quadraticCurveTo(-20, -120, 40, -120);
ctx.lineTo(100, -120);
ctx.quadraticCurveTo(160, -120, 180, -80);
ctx.lineTo(220, -20);
ctx.quadraticCurveTo(260, 0, 260, 60);
ctx.lineTo(-250, 60);
ctx.closePath();

const carGrad = ctx.createLinearGradient(-250, -120, 260, 60);
carGrad.addColorStop(0, '#8CE0FA');
carGrad.addColorStop(1, '#5BA8C8');
ctx.fillStyle = carGrad;
ctx.fill();

// Window
ctx.beginPath();
ctx.moveTo(-100, -50);
ctx.lineTo(-50, -95);
ctx.quadraticCurveTo(-20, -108, 30, -108);
ctx.lineTo(90, -108);
ctx.quadraticCurveTo(130, -108, 150, -75);
ctx.lineTo(180, -30);
ctx.lineTo(-110, -30);
ctx.closePath();
ctx.fillStyle = 'rgba(15, 27, 35, 0.7)';
ctx.fill();

// Window divider
ctx.beginPath();
ctx.moveTo(20, -108);
ctx.lineTo(15, -30);
ctx.lineWidth = 8;
ctx.strokeStyle = '#5BA8C8';
ctx.stroke();

// Wheels
ctx.beginPath();
ctx.arc(-140, 70, 55, 0, Math.PI * 2);
ctx.fillStyle = '#0F1B23';
ctx.fill();
ctx.beginPath();
ctx.arc(-140, 70, 38, 0, Math.PI * 2);
ctx.fillStyle = '#386B7E';
ctx.fill();
ctx.beginPath();
ctx.arc(-140, 70, 18, 0, Math.PI * 2);
ctx.fillStyle = '#8CE0FA';
ctx.fill();

ctx.beginPath();
ctx.arc(170, 70, 55, 0, Math.PI * 2);
ctx.fillStyle = '#0F1B23';
ctx.fill();
ctx.beginPath();
ctx.arc(170, 70, 38, 0, Math.PI * 2);
ctx.fillStyle = '#386B7E';
ctx.fill();
ctx.beginPath();
ctx.arc(170, 70, 18, 0, Math.PI * 2);
ctx.fillStyle = '#8CE0FA';
ctx.fill();

// Sparkle effects
ctx.restore();

// Sparkle 1 - top right
function drawSparkle(cx, cy, outerR, innerR, points, color) {
  ctx.beginPath();
  for (let i = 0; i < points * 2; i++) {
    const r = i % 2 === 0 ? outerR : innerR;
    const angle = (Math.PI * i) / points - Math.PI / 2;
    const x = cx + r * Math.cos(angle);
    const y = cy + r * Math.sin(angle);
    if (i === 0) ctx.moveTo(x, y);
    else ctx.lineTo(x, y);
  }
  ctx.closePath();
  ctx.fillStyle = color;
  ctx.fill();
}

drawSparkle(730, 250, 45, 15, 4, '#8CE0FA');
drawSparkle(780, 320, 25, 8, 4, 'rgba(140, 224, 250, 0.6)');
drawSparkle(310, 280, 30, 10, 4, 'rgba(140, 224, 250, 0.4)');

// "MC" text at bottom
ctx.font = 'bold 80px Arial';
ctx.textAlign = 'center';
ctx.fillStyle = 'rgba(140, 224, 250, 0.9)';
ctx.fillText('MC', size/2, size - 140);

// Save
const buffer = canvas.toBuffer('image/png');
const outPath = path.join(__dirname, 'app_icon.png');
fs.writeFileSync(outPath, buffer);
console.log('Icon saved to:', outPath);
