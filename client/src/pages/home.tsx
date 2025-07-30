import { useLocation } from "wouter";
import UploadArea from "@/components/ui/upload-area";
import BottomNavigation from "@/components/ui/bottom-navigation";
import { WandSparkles, Menu } from "lucide-react";

export default function Home() {
  const [, setLocation] = useLocation();

  const handleFileSelect = (file: File) => {
    // Store file data in sessionStorage to pass to editor page
    const reader = new FileReader();
    reader.onload = (e) => {
      const fileData = {
        fileName: file.name,
        fileType: file.type,
        fileData: (e.target?.result as string).split(',')[1] // Remove data:image/jpeg;base64, prefix
      };
      sessionStorage.setItem('uploadedFile', JSON.stringify(fileData));
      setLocation('/editor');
    };
    reader.readAsDataURL(file);
  };

  const renderMainContent = () => {
    return <UploadArea onFileSelect={handleFileSelect} />;
  };

  return (
    <div className="bg-slate-50 min-h-screen font-sans">
      {/* Header */}
      <header className="bg-white shadow-sm border-b border-slate-200">
        <div className="max-w-md mx-auto px-4 py-3 flex items-center justify-between">
          <div className="flex items-center space-x-3">
            <div className="w-8 h-8 bg-gradient-to-br from-primary to-secondary rounded-lg flex items-center justify-center">
              <WandSparkles className="text-white text-sm" size={16} />
            </div>
            <h1 className="text-lg font-semibold text-slate-800">AI Image Editor</h1>
          </div>
          <button className="w-8 h-8 flex items-center justify-center text-slate-600">
            <Menu size={16} />
          </button>
        </div>
      </header>

      {/* Main Content */}
      <main className="max-w-md mx-auto px-4 pb-20">
        {renderMainContent()}

        {/* Features Section */}
        <section className="py-6">
          <h3 className="font-semibold text-slate-800 mb-4">Features</h3>
          <div className="grid grid-cols-2 gap-3">
            <div className="bg-white rounded-xl p-4 shadow-sm border border-slate-200">
              <div className="w-10 h-10 bg-primary/10 rounded-lg flex items-center justify-center mb-3">
                <i className="fas fa-cut text-primary"></i>
              </div>
              <h4 className="font-medium text-slate-800 mb-1">Auto Background</h4>
              <p className="text-xs text-slate-600">Remove backgrounds instantly with AI</p>
            </div>
            
            <div className="bg-white rounded-xl p-4 shadow-sm border border-slate-200">
              <div className="w-10 h-10 bg-secondary/10 rounded-lg flex items-center justify-center mb-3">
                <i className="fas fa-magic text-secondary"></i>
              </div>
              <h4 className="font-medium text-slate-800 mb-1">AI Processing</h4>
              <p className="text-xs text-slate-600">Fast and accurate AI processing</p>
            </div>
            
            <div className="bg-white rounded-xl p-4 shadow-sm border border-slate-200">
              <div className="w-10 h-10 bg-accent/10 rounded-lg flex items-center justify-center mb-3">
                <i className="fas fa-lightning-bolt text-accent"></i>
              </div>
              <h4 className="font-medium text-slate-800 mb-1">Fast Processing</h4>
              <p className="text-xs text-slate-600">Get results in seconds</p>
            </div>
            
            <div className="bg-white rounded-xl p-4 shadow-sm border border-slate-200">
              <div className="w-10 h-10 bg-green-500/10 rounded-lg flex items-center justify-center mb-3">
                <i className="fas fa-shield-alt text-green-500"></i>
              </div>
              <h4 className="font-medium text-slate-800 mb-1">High Quality</h4>
              <p className="text-xs text-slate-600">Professional-grade results</p>
            </div>
          </div>
        </section>
      </main>

      <BottomNavigation />
    </div>
  );
}
