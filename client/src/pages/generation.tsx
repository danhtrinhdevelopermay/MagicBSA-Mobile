import { useLocation } from "wouter";
import { WandSparkles, Menu, ArrowLeft } from "lucide-react";
import { Button } from "@/components/ui/button";
import videoRemoveBackground from "@/assets/videos/remove-backgroud_1753967097264.mp4";
import videoCleanup from "@/assets/videos/cleanup_1753967097307.mp4";
import videoRemoveText from "@/assets/videos/remove-text-demo_1753967115580.mp4";
import videoExpandImage from "@/assets/videos/expand-image_1753967097228.mp4";
import videoUpscaling from "@/assets/videos/Upscaling_1753967097288.mp4";
import videoReimagine from "@/assets/videos/reimagine_1753967115596.mp4";
import videoTextToImage from "@/assets/videos/text-to-image_1753967115529.mp4";
import videoProductPhoto from "@/assets/videos/anh-san-pham_1753967115564.mp4";

interface FeatureCard {
  id: string;
  title: string;
  description: string;
  videoSrc: string;
  operation: string;
  gradient: string;
}

const features: FeatureCard[] = [
  {
    id: "remove-background",
    title: "Remove Background",
    description: "Xóa nền ảnh tự động với AI chất lượng cao",
    videoSrc: videoRemoveBackground,
    operation: "remove_background",
    gradient: "from-blue-500 to-blue-600"
  },
  {
    id: "cleanup",
    title: "Object Removal",
    description: "Xóa vật thể không mong muốn khỏi ảnh",
    videoSrc: videoCleanup,
    operation: "cleanup",
    gradient: "from-purple-500 to-purple-600"
  },
  {
    id: "remove-text",
    title: "Remove Text",
    description: "Xóa chữ viết trên ảnh một cách tự nhiên",
    videoSrc: videoRemoveText,
    operation: "remove_text",
    gradient: "from-green-500 to-green-600"
  },
  {
    id: "expand-image", 
    title: "Expand Image",
    description: "Mở rộng ảnh với AI tạo nội dung mới",
    videoSrc: videoExpandImage,
    operation: "uncrop",
    gradient: "from-orange-500 to-orange-600"
  },
  {
    id: "upscaling",
    title: "Image Upscaling", 
    description: "Tăng độ phân giải ảnh lên gấp đôi",
    videoSrc: videoUpscaling,
    operation: "upscaling",
    gradient: "from-red-500 to-red-600"
  },
  {
    id: "reimagine",
    title: "Reimagine",
    description: "Tái tạo ảnh với phong cách hoàn toàn mới",
    videoSrc: videoReimagine, 
    operation: "reimagine",
    gradient: "from-pink-500 to-pink-600"
  },
  {
    id: "text-to-image",
    title: "Text to Image",
    description: "Tạo ảnh từ mô tả văn bản",
    videoSrc: videoTextToImage,
    operation: "text_to_image", 
    gradient: "from-indigo-500 to-indigo-600"
  },
  {
    id: "product-photography",
    title: "Product Photo",
    description: "Tạo ảnh sản phẩm chuyên nghiệp",
    videoSrc: videoProductPhoto,
    operation: "product_photography",
    gradient: "from-teal-500 to-teal-600"
  }
];

export default function Generation() {
  const [, setLocation] = useLocation();

  const handleFeatureClick = (operation: string) => {
    // Store selected operation in sessionStorage and navigate to upload page
    sessionStorage.setItem('selectedOperation', operation);
    setLocation('/upload');
  };

  const handleBackClick = () => {
    setLocation('/');
  };

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
            <h1 className="text-lg font-semibold text-slate-800">AI Features</h1>
          </div>
          <button className="w-8 h-8 flex items-center justify-center text-slate-600">
            <Menu size={16} />
          </button>
        </div>
      </header>

      {/* Main Content */}
      <main className="max-w-md mx-auto px-4 pb-20">
        <div className="py-6">
          <h2 className="text-xl font-bold text-slate-800 mb-2">Choose AI Feature</h2>
          <p className="text-slate-600 mb-6">Select the feature you want to use for your image</p>
          
          {/* Feature Cards Grid */}
          <div className="grid grid-cols-1 gap-4">
            {features.map((feature) => (
              <div
                key={feature.id}
                onClick={() => handleFeatureClick(feature.operation)}
                className="bg-white rounded-2xl overflow-hidden shadow-sm border border-slate-200 cursor-pointer hover:shadow-lg transition-all duration-300 hover:scale-[1.02]"
              >
                {/* Video Section */}
                <div className="relative aspect-video bg-slate-100">
                  <video
                    className="w-full h-full object-cover"
                    autoPlay
                    loop
                    muted
                    playsInline
                  >
                    <source src={feature.videoSrc} type="video/mp4" />
                    <div className="w-full h-full bg-gradient-to-br from-slate-200 to-slate-300 flex items-center justify-center">
                      <span className="text-slate-500 text-sm">Video not supported</span>
                    </div>
                  </video>
                  
                  {/* Gradient overlay */}
                  <div className={`absolute inset-0 bg-gradient-to-t ${feature.gradient} opacity-20`} />
                  
                  {/* Play indicator */}
                  <div className="absolute top-3 right-3">
                    <div className="w-8 h-8 bg-black/20 backdrop-blur-sm rounded-full flex items-center justify-center">
                      <div className="w-0 h-0 border-l-[6px] border-l-white border-y-[4px] border-y-transparent ml-0.5" />
                    </div>
                  </div>
                </div>
                
                {/* Content Section */}
                <div className="p-4">
                  <h3 className="font-semibold text-slate-800 mb-1">{feature.title}</h3>
                  <p className="text-sm text-slate-600 mb-3">{feature.description}</p>
                  
                  {/* CTA Button */}
                  <Button
                    className={`w-full bg-gradient-to-r ${feature.gradient} text-white py-2.5 rounded-xl font-medium hover:shadow-lg transition-all`}
                  >
                    Try Now
                  </Button>
                </div>
              </div>
            ))}
          </div>
        </div>
      </main>
    </div>
  );
}