'use client';

import { useState } from 'react';
import { BarChart, Bar, XAxis, YAxis, CartesianGrid, Tooltip, Legend, ResponsiveContainer } from 'recharts';
import { calculateStats } from '@/lib/dataProcessor';

interface StatisticsPanelProps {
  data: any[];
  headers: string[];
}

export default function StatisticsPanel({ data, headers }: StatisticsPanelProps) {
  const [selectedColumn, setSelectedColumn] = useState<string>(headers[0] || '');

  if (!selectedColumn) {
    return <div className="bg-white rounded-lg shadow p-6 text-gray-600">No numeric columns available</div>;
  }

  const values = data
    .map(row => Number(row[selectedColumn]))
    .filter(v => !isNaN(v));

  const stats = calculateStats(values);

  // Create histogram data
  const min = Math.floor(stats.min);
  const max = Math.ceil(stats.max);
  const binCount = Math.ceil(Math.sqrt(values.length));
  const binSize = (max - min) / binCount;

  const bins = Array.from({ length: binCount }, (_, i) => {
    const binStart = min + i * binSize;
    const binEnd = binStart + binSize;
    const count = values.filter(v => v >= binStart && v < binEnd).length;
    return {
      range: `${binStart.toFixed(0)}-${binEnd.toFixed(0)}`,
      count,
    };
  });

  return (
    <div className="space-y-6">
      {/* Column Selector */}
      <div className="bg-white rounded-lg shadow p-6">
        <h3 className="text-xl font-bold text-gray-800 mb-4">Descriptive Statistics</h3>
        <label className="block text-sm font-medium text-gray-700 mb-2">Select Variable</label>
        <select 
          value={selectedColumn}
          onChange={(e) => setSelectedColumn(e.target.value)}
          className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
        >
          {headers.map(col => <option key={col} value={col}>{col}</option>)}
        </select>
      </div>

      {/* Statistics Grid */}
      <div className="grid grid-cols-2 lg:grid-cols-4 gap-4">
        <StatCard label="Mean" value={stats.mean} />
        <StatCard label="Median" value={stats.median} />
        <StatCard label="Std Dev" value={stats.stdev} />
        <StatCard label="Variance" value={stats.variance} />
        <StatCard label="Min" value={stats.min} />
        <StatCard label="Max" value={stats.max} />
        <StatCard label="Count" value={stats.count} />
        <StatCard label="Range" value={stats.max - stats.min} />
      </div>

      {/* Histogram */}
      <div className="bg-white rounded-lg shadow p-6">
        <h3 className="text-lg font-bold text-gray-800 mb-4">Distribution Histogram</h3>
        <ResponsiveContainer width="100%" height={300}>
          <BarChart data={bins}>
            <CartesianGrid strokeDasharray="3 3" />
            <XAxis dataKey="range" angle={-45} textAnchor="end" height={80} />
            <YAxis />
            <Tooltip />
            <Bar dataKey="count" fill="#3b82f6" />
          </BarChart>
        </ResponsiveContainer>
      </div>

      {/* Statistics Table */}
      <div className="bg-white rounded-lg shadow p-6">
        <h3 className="text-lg font-bold text-gray-800 mb-4">Summary</h3>
        <div className="grid grid-cols-2 gap-4">
          <div>
            <p className="text-gray-600 text-sm">Observation Count</p>
            <p className="text-2xl font-bold text-gray-900">{stats.count}</p>
          </div>
          <div>
            <p className="text-gray-600 text-sm">Mean Value</p>
            <p className="text-2xl font-bold text-blue-600">{stats.mean}</p>
          </div>
          <div>
            <p className="text-gray-600 text-sm">Median Value</p>
            <p className="text-2xl font-bold text-green-600">{stats.median}</p>
          </div>
          <div>
            <p className="text-gray-600 text-sm">Standard Deviation</p>
            <p className="text-2xl font-bold text-purple-600">{stats.stdev}</p>
          </div>
        </div>
      </div>
    </div>
  );
}

function StatCard({ label, value }: { label: string; value: number }) {
  return (
    <div className="bg-white rounded-lg shadow p-4">
      <p className="text-gray-600 text-sm font-medium">{label}</p>
      <p className="text-2xl font-bold text-gray-900 mt-1">
        {typeof value === 'number' ? value.toFixed(2) : value}
      </p>
    </div>
  );
}
