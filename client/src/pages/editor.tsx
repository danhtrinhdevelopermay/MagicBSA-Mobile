import { useState, useEffect } from "react";
import { useLocation } from "wouter";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { ImageJob } from "@shared/schema";
import ImageEditor from "@/components/ui/image-editor";
import ProcessingOverlay from "@/components/ui/processing-overlay";
import ResultsView from "@/components/ui/results-view";
import BottomNavigation from "@/components/ui/bottom-navigation";
import { apiRequest } from "@/lib/queryClient";
import { useToast } from "@/hooks/use-toast";
import { WandSparkles, ArrowLeft } from "lucide-react";
import { Button } from "@/components/ui/button";

export default function Editor() {
  const [, setLocation] = useLocation();
  const [currentJob, setCurrentJob] = useState<ImageJob | null>(null);
  const [selectedFile, setSelectedFile] = useState<File | null>(null);
  const [selectedOperation, setSelectedOperation] = useState<string>("");
  const { toast } = useToast();
  const queryClient = useQueryClient();

  // Get the file from sessionStorage when component mounts
  useEffect(() => {
    const storedFileData = sessionStorage.getItem('uploadedFile');
    if (storedFileData) {
      const { fileName, fileType, fileData, operation } = JSON.parse(storedFileData);
      // Convert base64 back to File
      const byteCharacters = atob(fileData);
      const byteNumbers = new Array(byteCharacters.length);
      for (let i = 0; i < byteCharacters.length; i++) {
        byteNumbers[i] = byteCharacters.charCodeAt(i);
      }
      const byteArray = new Uint8Array(byteNumbers);
      const file = new File([byteArray], fileName, { type: fileType });
      setSelectedFile(file);
      setSelectedOperation(operation || "");
    } else {
      // If no file data, redirect back to home
      setLocation('/');
    }
  }, [setLocation]);

  // Mutation for creating a new job
  const createJobMutation = useMutation({
    mutationFn: async ({ file, operation }: { file: File; operation: string }) => {
      const formData = new FormData();
      formData.append('image', file);
      formData.append('operation', operation);
      
      const response = await apiRequest('POST', '/api/jobs', formData);
      return await response.json();
    },
    onSuccess: (job: ImageJob) => {
      setCurrentJob(job);
      queryClient.invalidateQueries({ queryKey: ['/api/jobs'] });
    },
    onError: (error) => {
      toast({
        title: "Upload Failed",
        description: error instanceof Error ? error.message : "Failed to upload image",
        variant: "destructive",
      });
    },
  });

  // Mutation for cleanup processing with mask
  const cleanupMutation = useMutation({
    mutationFn: async ({ imageFile, maskBlob }: { imageFile: File; maskBlob: Blob }) => {
      const formData = new FormData();
      formData.append('image', imageFile);
      formData.append('mask', maskBlob, 'mask.png');
      
      const response = await fetch('/api/cleanup', {
        method: 'POST',
        body: formData,
      });
      
      if (!response.ok) {
        const errorData = await response.json().catch(() => ({ message: 'Unknown error' }));
        throw new Error(errorData.message || 'Cleanup processing failed');
      }
      
      return response.blob();
    },
    onSuccess: (processedBlob) => {
      // Create a URL for the processed image
      const processedUrl = URL.createObjectURL(processedBlob);
      
      // Create a fake job object for consistency with other operations
      const now = new Date();
      const fakeJob: ImageJob = {
        id: 'cleanup-' + Date.now(),
        originalImageUrl: URL.createObjectURL(selectedFile!),
        processedImageUrl: processedUrl,
        operation: 'cleanup',
        status: 'completed',
        errorMessage: null,
        metadata: {
          originalName: selectedFile!.name,
          fileSize: selectedFile!.size,
          mimeType: selectedFile!.type
        },
        createdAt: now,
        updatedAt: now
      };
      
      setCurrentJob(fakeJob);
      
      toast({
        title: "Cleanup Complete",
        description: "Objects have been successfully removed from your image!",
      });
    },
    onError: (error) => {
      toast({
        title: "Cleanup Failed",
        description: error instanceof Error ? error.message : "Failed to process cleanup",
        variant: "destructive",
      });
    },
  });

  // Mutation for processing a job
  const processJobMutation = useMutation({
    mutationFn: async (jobId: string) => {
      const response = await apiRequest('POST', `/api/jobs/${jobId}/process`);
      return await response.json();
    },
    onSuccess: (job: ImageJob) => {
      setCurrentJob(job);
      queryClient.invalidateQueries({ queryKey: ['/api/jobs'] });
      
      if (job.status === 'completed') {
        toast({
          title: "Processing Complete",
          description: "Your image has been processed successfully!",
        });
      } else if (job.status === 'failed') {
        toast({
          title: "Processing Failed",
          description: job.errorMessage || "Failed to process image",
          variant: "destructive",
        });
      }
    },
    onError: (error) => {
      toast({
        title: "Processing Failed",
        description: error instanceof Error ? error.message : "Failed to process image",
        variant: "destructive",
      });
    },
  });

  // Query to poll job status when processing
  const { data: jobStatus } = useQuery<ImageJob>({
    queryKey: ['/api/jobs', currentJob?.id],
    enabled: !!currentJob && currentJob.status === 'processing',
    refetchInterval: 1000,
  });

  // Update current job when status changes
  if (jobStatus && currentJob && jobStatus.id === currentJob.id) {
    if (jobStatus.status !== currentJob.status) {
      setCurrentJob(jobStatus);
    }
  }

  // Auto-start processing when file and operation are ready
  useEffect(() => {
    if (selectedFile && selectedOperation && selectedOperation !== 'cleanup') {
      createJobMutation.mutate({ file: selectedFile, operation: selectedOperation }, {
        onSuccess: (job) => {
          // Automatically start processing
          processJobMutation.mutate(job.id);
        }
      });
    }
  }, [selectedFile, selectedOperation, createJobMutation, processJobMutation]);

  const handleProcessImage = (operation: string, maskBlob?: Blob) => {
    if (!selectedFile) return;
    
    // Handle cleanup with mask differently
    if (operation === 'cleanup' && maskBlob) {
      cleanupMutation.mutate({ imageFile: selectedFile, maskBlob });
      return;
    }
    
    // Handle other operations normally
    createJobMutation.mutate({ file: selectedFile, operation }, {
      onSuccess: (job) => {
        // Automatically start processing
        processJobMutation.mutate(job.id);
      }
    });
  };

  const handleStartOver = () => {
    setCurrentJob(null);
    setSelectedFile(null);
    sessionStorage.removeItem('uploadedFile');
    if (selectedOperation) {
      sessionStorage.setItem('selectedOperation', selectedOperation);
      setLocation('/upload');
    } else {
      setLocation('/');
    }
  };

  const handleGoBack = () => {
    sessionStorage.removeItem('uploadedFile');
    if (selectedOperation) {
      sessionStorage.setItem('selectedOperation', selectedOperation);
      setLocation('/upload');
    } else {
      setLocation('/');
    }
  };

  const renderMainContent = () => {
    if (currentJob?.status === 'completed' && currentJob.processedImageUrl) {
      return (
        <ResultsView
          originalImageUrl={currentJob.originalImageUrl}
          processedImageUrl={currentJob.processedImageUrl}
          operation={currentJob.operation}
          onStartOver={handleStartOver}
        />
      );
    }

    if (currentJob?.status === 'processing' || processJobMutation.isPending || cleanupMutation.isPending) {
      return <ProcessingOverlay operation={currentJob?.operation || 'cleanup'} />;
    }

    if (selectedFile) {
      // Only show ImageEditor for cleanup operation, others auto-process
      if (selectedOperation === 'cleanup') {
        return (
          <ImageEditor
            file={selectedFile}
            onProcessImage={handleProcessImage}
            isProcessing={createJobMutation.isPending || cleanupMutation.isPending}
          />
        );
      } else {
        // For other operations, show processing immediately
        return <ProcessingOverlay operation={selectedOperation as any} />;
      }
    }

    return null;
  };

  return (
    <div className="bg-slate-50 min-h-screen font-sans">
      {/* Header */}
      <header className="bg-white shadow-sm border-b border-slate-200">
        <div className="max-w-md mx-auto px-4 py-3 flex items-center justify-between">
          <div className="flex items-center space-x-3">
            <Button
              onClick={handleGoBack}
              variant="ghost"
              size="sm"
              className="w-8 h-8 p-0 text-slate-600"
            >
              <ArrowLeft size={16} />
            </Button>
            <div className="w-8 h-8 bg-gradient-to-br from-primary to-secondary rounded-lg flex items-center justify-center">
              <WandSparkles className="text-white text-sm" size={16} />
            </div>
            <h1 className="text-lg font-semibold text-slate-800">AI Image Editor</h1>
          </div>
        </div>
      </header>

      {/* Main Content */}
      <main className="max-w-md mx-auto px-4 pb-20">
        {renderMainContent()}
      </main>

      <BottomNavigation />
    </div>
  );
}