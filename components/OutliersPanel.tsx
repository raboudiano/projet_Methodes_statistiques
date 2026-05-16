'use client';

import { useState } from 'react';
import { BarChart, Bar, XAxis, YAxis, CartesianGrid, Tooltip, Legend, ResponsiveContainer } from 'recharts';
import { detectOutliers } from '@/lib/dataProcessor';

interface OutliersPanelProps {
  data: any[];
  headers: string[];
}

export default function OutliersPanel({ data, headers }: OutliersPanelProps) {
  const [selectedColumn, setSelectedColumn] = useState<string>(headers[0] || '');

  if (!selectedColumn) {
    return <div className="bg-white rounded-lg shadow p-6 text-gray-600">No numeric columns available</div>;
  }

  const values = data
    .map(row => Number(row[selectedColumn]))
    .filter(v => !isNaN(v));

  const outlierInfo = detectOutliers(values);

  const outlierData = outlierInfo.values.map((v, i) => ({
    id: i + 1,
    value: v,
  }));

  const boxplotData = [
    {
      name: selectedColumn,
      min: Math.min(...values),
      q1: values.sort((a, b) => a - b)[Math.floor(values.length * 0.25)],
      median: values[Math.floor(values.length / 2)],
      q3: values.sort((a, b) => a - b)[Math.floor(values.length * 0.75)],
      max: Math.max(...values),
    },
  ];

  return (
    <div className="space-y-6">
      {/* Column Selector */}
      <div className="bg-white rounded-lg shadow p-6">
        <h3 className="text-xl font-bold text-gray-800 mb-4">Outlier Detection (IQR Method)</h3>
        <label className="block text-sm font-medium text-gray-700 mb-2">Select Variable</label>
        <select 
          value={selectedColumn}
          onChange={(e) => setSelectedColumn(e.target.value)}
          className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
        >
          {headers.map(col => <option key={col} value={col}>{col}</option>)}
        </select>
      </div>

      {/* Outlier Statistics */}
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-4">
        <div className="bg-white rounded-lg shadow p-6">
          <p className="text-gray-600 text-sm font-medium">Outliers Found</p>
          <p className="text-4xl font-bold text-red-600 mt-2">{outlierInfo.count}</p>
        </div>
        <div className="bg-white rounded-lg shadow p-6">
          <p className="text-gray-600 text-sm font-medium">Percentage</p>
          <p className="text-4xl font-bold text-orange-600 mt-2">{outlierInfo.percentage}%</p>
        </div>
        <div className="bg-white rounded-lg shadow p-6">
          <p className="text-gray-600 text-sm font-medium">Total Observations</p>
          <p className="text-4xl font-bold text-blue-600 mt-2">{values.length}</p>
        </div>
      </div>

      {/* Outlier Values */}
      {outlierInfo.count > 0 && (
        <div className="bg-white rounded-lg shadow p-6">
          <h3 className="text-lg font-bold text-gray-800 mb-4">Detected Outlier Values</h3>
          <div className="overflow-y-auto max-h-64">
            <div className="grid grid-cols-2 lg:grid-cols-4 gap-2">
              {outlierInfo.values.map((val, idx) => (
                <div key={idx} className="bg-red-50 border border-red-200 rounded p-2">
                  <p className="text-xs text-gray-600">Outlier #{idx + 1}</p>
                  <p className="text-lg font-bold text-red-600">{val.toFixed(2)}</p>
                </div>
              ))}
            </div>
          </div>
        </div>
      )}

      {/* Boxplot Visualization */}
      <div className="bg-white rounded-lg shadow p-6">
        <h3 className="text-lg font-bold text-gray-800 mb-4">Distribution Box Plot</h3>
        <div className="space-y-4">
          <ResponsiveContainer width="100%" height={200}>
            <BarChart data={boxplotData} margin={{ top: 20, right: 30, left: 0, bottom: 60 }}>
              <CartesianGrid strokeDasharray="3 3" />
              <XAxis dataKey="name" angle={-45} textAnchor="end" height={80} />
              <YAxis />
              <Tooltip />
              <Bar dataKey="min" fill="#90ee90" />
              <Bar dataKey="q1" fill="#87ceeb" />
              <Bar dataKey="median" fill="#ffd700" />
              <Bar dataKey="q3" fill="#87ceeb" />
              <Bar dataKey="max" fill="#90ee90" />
            </BarChart>
          </ResponsiveContainer>
          <div className="text-xs text-gray-600 space-y-1">
            <p><span className="inline-block w-4 h-4 bg-green-400 rounded mr-2"></span>Min/Max values</p>
            <p><span className="inline-block w-4 h-4 bg-blue-400 rounded mr-2"></span>Q1/Q3 (quartiles)</p>
            <p><span className="inline-block w-4 h-4 bg-yellow-400 rounded mr-2"></span>Median</p>
          </div>
        </div>
      </div>

      {/* Method Explanation */}
      <div className="bg-blue-50 rounded-lg shadow p-6">
        <h3 className="text-lg font-bold text-blue-900 mb-2">IQR Method Explanation</h3>
        <p className="text-blue-800 text-sm">
          The Interquartile Range (IQR) method identifies outliers as values that fall below Q1 - 1.5×IQR or above Q3 + 1.5×IQR, where Q1 is the 25th percentile and Q3 is the 75th percentile.
        </p>
      </div>
    </div>
  );
}
