import { useState, useRef, useEffect, useCallback } from "react";
import { Button } from "./button";
import { Brush, RotateCcw, Check } from "lucide-react";

interface MaskDrawingProps {
  imageFile: File;
  onMaskComplete: (maskBlob: Blob) => void;
  onCancel: () => void;
}

export default function MaskDrawing({ imageFile, onMaskComplete, onCancel }: MaskDrawingProps) {
  const canvasRef = useRef<HTMLCanvasElement>(null);
  const maskCanvasRef = useRef<HTMLCanvasElement>(null);
  const [isDrawing, setIsDrawing] = useState(false);
  const [brushSize, setBrushSize] = useState(20);
  const [imageLoaded, setImageLoaded] = useState(false);
  const [image, setImage] = useState<HTMLImageElement | null>(null);

  useEffect(() => {
    const canvas = canvasRef.current;
    const maskCanvas = maskCanvasRef.current;
    if (!canvas || !maskCanvas) return;

    const img = new Image();
    img.onload = () => {
      setImage(img);
      
      // Set canvas size to match image
      canvas.width = img.width;
      canvas.height = img.height;
      maskCanvas.width = img.width;
      maskCanvas.height = img.height;
      
      // Draw image on main canvas
      const ctx = canvas.getContext('2d');
      if (ctx) {
        ctx.drawImage(img, 0, 0);
      }
      
      // Initialize mask canvas with black background
      const maskCtx = maskCanvas.getContext('2d');
      if (maskCtx) {
        maskCtx.fillStyle = '#000000';
        maskCtx.fillRect(0, 0, maskCanvas.width, maskCanvas.height);
      }
      
      setImageLoaded(true);
    };
    
    img.src = URL.createObjectURL(imageFile);
    
    return () => {
      URL.revokeObjectURL(img.src);
    };
  }, [imageFile]);

  const getCanvasCoordinates = useCallback((e: React.MouseEvent<HTMLCanvasElement>) => {
    const canvas = canvasRef.current;
    if (!canvas) return { x: 0, y: 0 };
    
    const rect = canvas.getBoundingClientRect();
    const scaleX = canvas.width / rect.width;
    const scaleY = canvas.height / rect.height;
    
    return {
      x: (e.clientX - rect.left) * scaleX,
      y: (e.clientY - rect.top) * scaleY
    };
  }, []);

  const drawOnMask = useCallback((x: number, y: number) => {
    const maskCanvas = maskCanvasRef.current;
    const canvas = canvasRef.current;
    if (!maskCanvas || !canvas) return;
    
    const maskCtx = maskCanvas.getContext('2d');
    const ctx = canvas.getContext('2d');
    if (!maskCtx || !ctx) return;
    
    // Draw white circle on mask (white = remove area)
    maskCtx.fillStyle = '#FFFFFF';
    maskCtx.beginPath();
    maskCtx.arc(x, y, brushSize / 2, 0, 2 * Math.PI);
    maskCtx.fill();
    
    // Draw red overlay on main canvas for visual feedback
    ctx.globalAlpha = 0.5;
    ctx.fillStyle = '#FF0000';
    ctx.beginPath();
    ctx.arc(x, y, brushSize / 2, 0, 2 * Math.PI);
    ctx.fill();
    ctx.globalAlpha = 1.0;
  }, [brushSize]);

  const handleMouseDown = useCallback((e: React.MouseEvent<HTMLCanvasElement>) => {
    setIsDrawing(true);
    const { x, y } = getCanvasCoordinates(e);
    drawOnMask(x, y);
  }, [getCanvasCoordinates, drawOnMask]);

  const handleMouseMove = useCallback((e: React.MouseEvent<HTMLCanvasElement>) => {
    if (!isDrawing) return;
    const { x, y } = getCanvasCoordinates(e);
    drawOnMask(x, y);
  }, [isDrawing, getCanvasCoordinates, drawOnMask]);

  const handleMouseUp = useCallback(() => {
    setIsDrawing(false);
  }, []);

  const clearMask = useCallback(() => {
    const canvas = canvasRef.current;
    const maskCanvas = maskCanvasRef.current;
    if (!canvas || !maskCanvas || !image) return;
    
    // Clear main canvas and redraw image
    const ctx = canvas.getContext('2d');
    if (ctx) {
      ctx.clearRect(0, 0, canvas.width, canvas.height);
      ctx.drawImage(image, 0, 0);
    }
    
    // Clear mask canvas and fill with black
    const maskCtx = maskCanvas.getContext('2d');
    if (maskCtx) {
      maskCtx.fillStyle = '#000000';
      maskCtx.fillRect(0, 0, maskCanvas.width, maskCanvas.height);
    }
  }, [image]);

  const completeMask = useCallback(() => {
    const maskCanvas = maskCanvasRef.current;
    if (!maskCanvas) return;
    
    maskCanvas.toBlob((blob) => {
      if (blob) {
        onMaskComplete(blob);
      }
    }, 'image/png');
  }, [onMaskComplete]);

  if (!imageLoaded) {
    return (
      <div className="flex items-center justify-center h-64">
        <div className="text-slate-600">Đang tải ảnh...</div>
      </div>
    );
  }

  return (
    <div className="bg-white rounded-2xl p-6 shadow-sm border border-slate-200">
      <h3 className="font-semibold text-slate-800 mb-4 text-center">
        Vẽ vùng cần xóa
      </h3>
      
      {/* Brush size control */}
      <div className="mb-4">
        <label className="block text-sm font-medium text-slate-700 mb-2">
          Kích thước cọ: {brushSize}px
        </label>
        <input
          type="range"
          min="5"
          max="50"
          value={brushSize}
          onChange={(e) => setBrushSize(Number(e.target.value))}
          className="w-full h-2 bg-slate-200 rounded-lg appearance-none cursor-pointer"
        />
      </div>

      {/* Canvas for drawing */}
      <div className="mb-4 border border-slate-300 rounded-lg overflow-hidden">
        <canvas
          ref={canvasRef}
          className="max-w-full max-h-96 cursor-crosshair"
          style={{ display: 'block', width: '100%', height: 'auto' }}
          onMouseDown={handleMouseDown}
          onMouseMove={handleMouseMove}
          onMouseUp={handleMouseUp}
          onMouseLeave={handleMouseUp}
        />
      </div>

      {/* Hidden mask canvas */}
      <canvas
        ref={maskCanvasRef}
        style={{ display: 'none' }}
      />

      {/* Instructions */}
      <div className="mb-4 p-3 bg-blue-50 rounded-lg">
        <p className="text-sm text-blue-700">
          <strong>Hướng dẫn:</strong> Vẽ lên những vùng bạn muốn xóa. 
          Vùng đỏ sẽ được AI xử lý và loại bỏ khỏi ảnh.
        </p>
      </div>

      {/* Action buttons */}
      <div className="flex gap-3">
        <Button
          onClick={clearMask}
          variant="outline"
          className="flex-1 flex items-center justify-center space-x-2"
        >
          <RotateCcw size={16} />
          <span>Xóa hết</span>
        </Button>
        
        <Button
          onClick={onCancel}
          variant="outline"
          className="flex-1"
        >
          Hủy
        </Button>
        
        <Button
          onClick={completeMask}
          className="flex-1 bg-gradient-to-r from-purple-500 to-purple-600 text-white flex items-center justify-center space-x-2"
        >
          <Check size={16} />
          <span>Xử lý</span>
        </Button>
      </div>
    </div>
  );
}