import { useEffect, useState } from "react";
import { useLocation } from "wouter";
import UploadArea from "@/components/ui/upload-area";
import { WandSparkles, ArrowLeft, Menu } from "lucide-react";
import { Button } from "@/components/ui/button";

const operationLabels: { [key: string]: string } = {
  remove_background: "Remove Background",
  cleanup: "Object Removal", 
  remove_text: "Remove Text",
  uncrop: "Expand Image",
  upscaling: "Image Upscaling",
  reimagine: "Reimagine",
  text_to_image: "Text to Image",
  product_photography: "Product Photo"
};

const operationDescriptions: { [key: string]: string } = {
  remove_background: "Upload your image to remove the background automatically",
  cleanup: "Upload your image and draw to mark objects you want to remove",
  remove_text: "Upload your image to remove text automatically",
  uncrop: "Upload your image to expand it with AI-generated content",
  upscaling: "Upload your image to increase its resolution",
  reimagine: "Upload your image to reimagine it in a new style",
  text_to_image: "Create an image from text description",
  product_photography: "Upload your product image for professional photography"
};

export default function Upload() {
  const [, setLocation] = useLocation();
  const [selectedOperation, setSelectedOperation] = useState<string>("");

  useEffect(() => {
    const operation = sessionStorage.getItem('selectedOperation');
    if (operation) {
      setSelectedOperation(operation);
    } else {
      // If no operation selected, redirect back to generation page
      setLocation('/generation');
    }
  }, [setLocation]);

  const handleFileSelect = (file: File) => {
    // Store file data and operation in sessionStorage to pass to editor page
    const reader = new FileReader();
    reader.onload = (e) => {
      const fileData = {
        fileName: file.name,
        fileType: file.type,
        fileData: (e.target?.result as string).split(',')[1], // Remove data:image/jpeg;base64, prefix
        operation: selectedOperation
      };
      sessionStorage.setItem('uploadedFile', JSON.stringify(fileData));
      setLocation('/editor');
    };
    reader.readAsDataURL(file);
  };

  const handleBackClick = () => {
    sessionStorage.removeItem('selectedOperation');
    setLocation('/generation');
  };

  if (!selectedOperation) {
    return null; // Loading or redirecting
  }

  return (
    <div className="bg-slate-50 min-h-screen font-sans">
      {/* Header */}
      <header className="bg-white shadow-sm border-b border-slate-200">
        <div className="max-w-md mx-auto px-4 py-3 flex items-center justify-between">
          <div className="flex items-center space-x-3">
            <Button
              variant="ghost"
              size="sm"
              onClick={handleBackClick}
              className="w-8 h-8 p-0 text-slate-600"
            >
              <ArrowLeft size={16} />
            </Button>
            <div className="w-8 h-8 bg-gradient-to-br from-primary to-secondary rounded-lg flex items-center justify-center">
              <WandSparkles className="text-white text-sm" size={16} />
            </div>
            <h1 className="text-lg font-semibold text-slate-800">{operationLabels[selectedOperation]}</h1>
          </div>
          <button className="w-8 h-8 flex items-center justify-center text-slate-600">
            <Menu size={16} />
          </button>
        </div>
      </header>

      {/* Main Content */}
      <main className="max-w-md mx-auto px-4 pb-20">
        <div className="py-6">
          <h2 className="text-xl font-bold text-slate-800 mb-2">Upload Your Image</h2>
          <p className="text-slate-600 mb-6">{operationDescriptions[selectedOperation]}</p>
          
          <UploadArea onFileSelect={handleFileSelect} />
          
          {/* Feature Info */}
          <div className="mt-6 bg-white rounded-xl p-4 shadow-sm border border-slate-200">
            <h3 className="font-semibold text-slate-800 mb-2">About {operationLabels[selectedOperation]}</h3>
            <div className="space-y-2 text-sm text-slate-600">
              {selectedOperation === 'remove_background' && (
                <>
                  <p>• Automatically detects and removes backgrounds</p>
                  <p>• Works best with clear subject separation</p>
                  <p>• Supports JPG, PNG, WEBP formats</p>
                </>
              )}
              {selectedOperation === 'cleanup' && (
                <>
                  <p>• Draw on objects you want to remove</p>
                  <p>• AI will intelligently fill the area</p>
                  <p>• Perfect for removing unwanted elements</p>
                </>
              )}
              {selectedOperation === 'remove_text' && (
                <>
                  <p>• Automatically detects and removes text</p>
                  <p>• Preserves image quality and background</p>
                  <p>• Works with various fonts and sizes</p>
                </>
              )}
              {selectedOperation === 'uncrop' && (
                <>
                  <p>• Expands image beyond original boundaries</p>
                  <p>• AI generates seamless extensions</p>
                  <p>• Perfect for creating wider compositions</p>
                </>
              )}
              {selectedOperation === 'upscaling' && (
                <>
                  <p>• Increases image resolution up to 2x</p>
                  <p>• Preserves and enhances details</p>
                  <p>• No quality loss during upscaling</p>
                </>
              )}
              {selectedOperation === 'reimagine' && (
                <>
                  <p>• Creates variations of your image</p>
                  <p>• Maintains core composition</p>
                  <p>• Explores different artistic styles</p>
                </>
              )}
              {selectedOperation === 'text_to_image' && (
                <>
                  <p>• Generate images from text descriptions</p>
                  <p>• High-quality AI artwork creation</p>
                  <p>• Support for detailed prompts</p>
                </>
              )}
              {selectedOperation === 'product_photography' && (
                <>
                  <p>• Professional product photography</p>
                  <p>• Clean backgrounds and lighting</p>
                  <p>• Perfect for e-commerce listings</p>
                </>
              )}
            </div>
          </div>
        </div>
      </main>
    </div>
  );
}