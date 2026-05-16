'use client';

import { useState } from 'react';
import { BarChart, Bar, LineChart, Line, ScatterChart, Scatter, XAxis, YAxis, CartesianGrid, Tooltip, Legend, ResponsiveContainer, ComposedChart } from 'recharts';
import { Menu, X } from 'lucide-react';
import DataLoader from './DataLoader';
import StatisticsPanel from './StatisticsPanel';
import CorrelationPanel from './CorrelationPanel';
import OutliersPanel from './OutliersPanel';
import MissingValuesPanel from './MissingValuesPanel';

interface DataState {
  headers: string[];
  data: any[];
  loaded: boolean;
}

export default function Dashboard() {
  const [dataState, setDataState] = useState<DataState>({
    headers: [],
    data: [],
    loaded: false,
  });
  
  const [activeTab, setActiveTab] = useState<string>('overview');
  const [selectedColumns, setSelectedColumns] = useState<string[]>([]);
  const [sidebarOpen, setSidebarOpen] = useState(true);

  const handleDataLoad = (headers: string[], data: any[]) => {
    setDataState({ headers, data, loaded: true });
    setSelectedColumns(headers.filter(h => !isNaN(Number(data[0]?.[h]))).slice(0, 2));
  };

  const numericColumns = dataState.headers.filter(h => 
    dataState.data.length > 0 && !isNaN(Number(dataState.data[0][h]))
  );

  const categoricalColumns = dataState.headers.filter(h =>
    dataState.data.length > 0 && isNaN(Number(dataState.data[0][h]))
  );

  return (
    <div className="flex h-screen bg-gray-900">
      {/* Sidebar */}
      <aside className={`${sidebarOpen ? 'w-64' : 'w-20'} bg-gray-800 text-white transition-all duration-300 border-r border-gray-700`}>
        <div className="h-20 flex items-center justify-between px-4 border-b border-gray-700">
          {sidebarOpen && <h1 className="text-xl font-bold">MediStats</h1>}
          <button onClick={() => setSidebarOpen(!sidebarOpen)} className="p-2 hover:bg-gray-700 rounded">
            {sidebarOpen ? <X size={20} /> : <Menu size={20} />}
          </button>
        </div>
        
        <nav className="p-4 space-y-2">
          {[
            { id: 'overview', label: 'Overview', icon: '📊' },
            { id: 'descriptive', label: 'Descriptive Stats', icon: '📈' },
            { id: 'missing', label: 'Missing Values', icon: '⚠️' },
            { id: 'outliers', label: 'Outliers', icon: '🎯' },
            { id: 'correlation', label: 'Correlation', icon: '🔗' },
            { id: 'comparison', label: 'Comparison', icon: '⚖️' },
          ].map(tab => (
            <button
              key={tab.id}
              onClick={() => setActiveTab(tab.id)}
              className={`w-full text-left px-4 py-2 rounded transition ${
                activeTab === tab.id 
                  ? 'bg-blue-600 text-white' 
                  : 'hover:bg-gray-700'
              }`}
            >
              {sidebarOpen ? `${tab.icon} ${tab.label}` : tab.icon}
            </button>
          ))}
        </nav>
      </aside>

      {/* Main Content */}
      <main className="flex-1 overflow-auto">
        <div className="bg-gray-800 border-b border-gray-700 p-6">
          <h2 className="text-3xl font-bold text-white">Medical Statistical Analysis</h2>
          <p className="text-gray-400 mt-1">Interactive analysis interface for patients&apos; medical data</p>
        </div>

        <div className="p-8">
          {!dataState.loaded ? (
            <DataLoader onDataLoad={handleDataLoad} />
          ) : (
            <>
              {/* Data Info */}
              <div className="grid grid-cols-4 gap-4 mb-8">
                <div className="bg-white rounded-lg shadow p-6">
                  <div className="text-gray-600 text-sm font-medium">Total Records</div>
                  <div className="text-4xl font-bold text-blue-600 mt-2">{dataState.data.length}</div>
                </div>
                <div className="bg-white rounded-lg shadow p-6">
                  <div className="text-gray-600 text-sm font-medium">Numeric Variables</div>
                  <div className="text-4xl font-bold text-green-600 mt-2">{numericColumns.length}</div>
                </div>
                <div className="bg-white rounded-lg shadow p-6">
                  <div className="text-gray-600 text-sm font-medium">Categorical Variables</div>
                  <div className="text-4xl font-bold text-purple-600 mt-2">{categoricalColumns.length}</div>
                </div>
                <div className="bg-white rounded-lg shadow p-6">
                  <div className="text-gray-600 text-sm font-medium">Total Variables</div>
                  <div className="text-4xl font-bold text-orange-600 mt-2">{dataState.headers.length}</div>
                </div>
              </div>

              {/* Tab Content */}
              {activeTab === 'overview' && <OverviewTab data={dataState.data} headers={dataState.headers} />}
              {activeTab === 'descriptive' && <StatisticsPanel data={dataState.data} headers={numericColumns} />}
              {activeTab === 'missing' && <MissingValuesPanel data={dataState.data} headers={dataState.headers} />}
              {activeTab === 'outliers' && <OutliersPanel data={dataState.data} headers={numericColumns} />}
              {activeTab === 'correlation' && <CorrelationPanel data={dataState.data} headers={numericColumns} />}
              {activeTab === 'comparison' && <ComparisonTab data={dataState.data} numericCols={numericColumns} categoricalCols={categoricalColumns} />}
            </>
          )}
        </div>
      </main>
    </div>
  );
}

function OverviewTab({ data, headers }: { data: any[], headers: string[] }) {
  const firstFewRows = data.slice(0, 5);
  
  return (
    <div className="bg-white rounded-lg shadow p-6">
      <h3 className="text-xl font-bold text-gray-800 mb-4">Data Preview</h3>
      <div className="overflow-x-auto">
        <table className="w-full text-sm">
          <thead className="bg-gray-100 border-b border-gray-300">
            <tr>
              {headers.map(h => <th key={h} className="px-4 py-2 text-left font-semibold text-gray-700">{h}</th>)}
            </tr>
          </thead>
          <tbody>
            {firstFewRows.map((row, idx) => (
              <tr key={idx} className="border-b border-gray-200 hover:bg-gray-50">
                {headers.map(h => (
                  <td key={h} className="px-4 py-2 text-gray-600">{row[h]}</td>
                ))}
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </div>
  );
}

function ComparisonTab({ data, numericCols, categoricalCols }: { data: any[], numericCols: string[], categoricalCols: string[] }) {
  const [selectedNumeric, setSelectedNumeric] = useState<string>(numericCols[0] || '');
  const [selectedCategory, setSelectedCategory] = useState<string>(categoricalCols[0] || '');

  if (!selectedNumeric || !selectedCategory) {
    return <div className="bg-white rounded-lg shadow p-6 text-gray-600">No numeric or categorical variables available</div>;
  }

  const groupedData = data.reduce((acc: any, row) => {
    const category = row[selectedCategory];
    if (!acc[category]) acc[category] = [];
    acc[category].push(Number(row[selectedNumeric]));
    return acc;
  }, {});

  const comparisonData = Object.entries(groupedData).map(([category, values]: [string, any]) => ({
    category,
    mean: (values.reduce((a: number, b: number) => a + b, 0) / values.length).toFixed(2),
    count: values.length,
  }));

  return (
    <div className="space-y-6">
      <div className="bg-white rounded-lg shadow p-6">
        <h3 className="text-xl font-bold text-gray-800 mb-4">Group Comparison</h3>
        <div className="grid grid-cols-2 gap-4 mb-6">
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-2">Numeric Variable</label>
            <select 
              value={selectedNumeric}
              onChange={(e) => setSelectedNumeric(e.target.value)}
              className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
            >
              {numericCols.map(col => <option key={col} value={col}>{col}</option>)}
            </select>
          </div>
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-2">Categorical Variable</label>
            <select 
              value={selectedCategory}
              onChange={(e) => setSelectedCategory(e.target.value)}
              className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
            >
              {categoricalCols.map(col => <option key={col} value={col}>{col}</option>)}
            </select>
          </div>
        </div>
        
        <ResponsiveContainer width="100%" height={300}>
          <BarChart data={comparisonData}>
            <CartesianGrid strokeDasharray="3 3" />
            <XAxis dataKey="category" />
            <YAxis />
            <Tooltip />
            <Bar dataKey="mean" fill="#3b82f6" />
          </BarChart>
        </ResponsiveContainer>
      </div>
    </div>
  );
}
