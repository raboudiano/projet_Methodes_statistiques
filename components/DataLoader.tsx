'use client';

import { useRef, useState } from 'react';
import { Upload } from 'lucide-react';
import { parseCSV } from '@/lib/dataProcessor';

interface DataLoaderProps {
  onDataLoad: (headers: string[], data: any[]) => void;
}

export default function DataLoader({ onDataLoad }: DataLoaderProps) {
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string>('');
  const fileInputRef = useRef<HTMLInputElement>(null);

  const handleFile = async (file: File) => {
    if (!file.name.endsWith('.csv')) {
      setError('Please upload a CSV file');
      return;
    }

    setLoading(true);
    setError('');

    try {
      const text = await file.text();
      const { headers, data } = parseCSV(text);
      onDataLoad(headers, data);
    } catch (err) {
      setError('Error parsing CSV file');
    } finally {
      setLoading(false);
    }
  };

  const handleDrop = (e: React.DragEvent<HTMLDivElement>) => {
    e.preventDefault();
    e.stopPropagation();
    
    const files = e.dataTransfer.files;
    if (files.length > 0) {
      handleFile(files[0]);
    }
  };

  const handleLoadSample = async () => {
    try {
      const response = await fetch('/patients_medical_data.csv');
      const text = await response.text();
      const { headers, data } = parseCSV(text);
      onDataLoad(headers, data);
    } catch (err) {
      setError('Error loading sample data');
    }
  };

  return (
    <div className="max-w-2xl mx-auto">
      <div 
        onDrop={handleDrop}
        onDragOver={(e) => e.preventDefault()}
        className="border-2 border-dashed border-gray-300 rounded-lg p-12 text-center hover:border-blue-500 transition bg-gray-50"
      >
        <Upload className="mx-auto mb-4 text-gray-400" size={48} />
        <h3 className="text-xl font-semibold text-gray-800 mb-2">Upload Medical Data</h3>
        <p className="text-gray-600 mb-6">Drag and drop your CSV file here or click to browse</p>
        
        <input
          ref={fileInputRef}
          type="file"
          accept=".csv"
          onChange={(e) => e.target.files && handleFile(e.target.files[0])}
          className="hidden"
        />
        
        <button
          onClick={() => fileInputRef.current?.click()}
          disabled={loading}
          className="inline-block px-6 py-3 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition disabled:opacity-50 font-medium"
        >
          {loading ? 'Loading...' : 'Choose File'}
        </button>

        {error && <p className="text-red-600 mt-4 font-medium">{error}</p>}
      </div>

      <div className="mt-8 text-center">
        <p className="text-gray-600 mb-4">Or try with sample data:</p>
        <button
          onClick={handleLoadSample}
          className="px-6 py-2 bg-green-600 text-white rounded-lg hover:bg-green-700 transition font-medium"
        >
          Load Sample Data
        </button>
      </div>
    </div>
  );
}
