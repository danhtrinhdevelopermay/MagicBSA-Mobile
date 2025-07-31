import { useLocation } from "wouter";
import BottomNavigation from "@/components/ui/bottom-navigation";
import { WandSparkles, Menu, ArrowRight, Sparkles } from "lucide-react";
import { Button } from "@/components/ui/button";

export default function Home() {
  const [, setLocation] = useLocation();

  const handleExploreFeatures = () => {
    setLocation('/generation');
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
        {/* Hero Section */}
        <section className="py-8 text-center">
          <div className="mb-6">
            <div className="w-20 h-20 bg-gradient-to-br from-primary to-secondary rounded-3xl mx-auto mb-4 flex items-center justify-center">
              <Sparkles className="text-white" size={32} />
            </div>
            <h2 className="text-2xl font-bold text-slate-800 mb-2">AI Image Editor</h2>
            <p className="text-slate-600">Transform your images with powerful AI tools</p>
          </div>
          
          <Button
            onClick={handleExploreFeatures}
            className="w-full bg-gradient-to-r from-primary to-secondary text-white py-4 rounded-2xl font-semibold text-lg flex items-center justify-center space-x-2 hover:shadow-lg transition-all mb-6"
          >
            <span>Explore AI Features</span>
            <ArrowRight size={20} />
          </Button>
        </section>

        {/* Features Overview */}
        <section className="py-6">
          <h3 className="font-semibold text-slate-800 mb-4">What You Can Do</h3>
          <div className="grid grid-cols-2 gap-3">
            <div className="bg-white rounded-xl p-4 shadow-sm border border-slate-200">
              <div className="w-10 h-10 bg-blue-500/10 rounded-lg flex items-center justify-center mb-3">
                <span className="text-blue-500 font-bold text-sm">BG</span>
              </div>
              <h4 className="font-medium text-slate-800 mb-1">Remove Background</h4>
              <p className="text-xs text-slate-600">AI-powered background removal</p>
            </div>
            
            <div className="bg-white rounded-xl p-4 shadow-sm border border-slate-200">
              <div className="w-10 h-10 bg-purple-500/10 rounded-lg flex items-center justify-center mb-3">
                <span className="text-purple-500 font-bold text-sm">✂️</span>
              </div>
              <h4 className="font-medium text-slate-800 mb-1">Object Removal</h4>
              <p className="text-xs text-slate-600">Remove unwanted objects</p>
            </div>
            
            <div className="bg-white rounded-xl p-4 shadow-sm border border-slate-200">
              <div className="w-10 h-10 bg-green-500/10 rounded-lg flex items-center justify-center mb-3">
                <span className="text-green-500 font-bold text-sm">T</span>
              </div>
              <h4 className="font-medium text-slate-800 mb-1">Text Removal</h4>
              <p className="text-xs text-slate-600">Clean text from images</p>
            </div>
            
            <div className="bg-white rounded-xl p-4 shadow-sm border border-slate-200">
              <div className="w-10 h-10 bg-red-500/10 rounded-lg flex items-center justify-center mb-3">
                <span className="text-red-500 font-bold text-sm">↗️</span>
              </div>
              <h4 className="font-medium text-slate-800 mb-1">Upscaling</h4>
              <p className="text-xs text-slate-600">Enhance image quality</p>
            </div>

            <div className="bg-white rounded-xl p-4 shadow-sm border border-slate-200">
              <div className="w-10 h-10 bg-orange-500/10 rounded-lg flex items-center justify-center mb-3">
                <span className="text-orange-500 font-bold text-sm">📐</span>
              </div>
              <h4 className="font-medium text-slate-800 mb-1">Expand Image</h4>
              <p className="text-xs text-slate-600">Extend image boundaries</p>
            </div>
            
            <div className="bg-white rounded-xl p-4 shadow-sm border border-slate-200">
              <div className="w-10 h-10 bg-pink-500/10 rounded-lg flex items-center justify-center mb-3">
                <span className="text-pink-500 font-bold text-sm">🎨</span>
              </div>
              <h4 className="font-medium text-slate-800 mb-1">Reimagine</h4>
              <p className="text-xs text-slate-600">AI creative variations</p>
            </div>

            <div className="bg-white rounded-xl p-4 shadow-sm border border-slate-200">
              <div className="w-10 h-10 bg-indigo-500/10 rounded-lg flex items-center justify-center mb-3">
                <span className="text-indigo-500 font-bold text-sm">💭</span>
              </div>
              <h4 className="font-medium text-slate-800 mb-1">Text to Image</h4>
              <p className="text-xs text-slate-600">Create from description</p>
            </div>
            
            <div className="bg-white rounded-xl p-4 shadow-sm border border-slate-200">
              <div className="w-10 h-10 bg-teal-500/10 rounded-lg flex items-center justify-center mb-3">
                <span className="text-teal-500 font-bold text-sm">📦</span>
              </div>
              <h4 className="font-medium text-slate-800 mb-1">Product Photo</h4>
              <p className="text-xs text-slate-600">Professional product shots</p>
            </div>
          </div>
        </section>
      </main>

      <BottomNavigation />
    </div>
  );
}
