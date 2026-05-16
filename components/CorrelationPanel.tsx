'use client';

import { useState } from 'react';
import { ScatterChart, Scatter, XAxis, YAxis, CartesianGrid, Tooltip, Legend, ResponsiveContainer } from 'recharts';
import { calculateCorrelation } from '@/lib/dataProcessor';

interface CorrelationPanelProps {
  data: any[];
  headers: string[];
}

export default function CorrelationPanel({ data, headers }: CorrelationPanelProps) {
  const [var1, setVar1] = useState<string>(headers[0] || '');
  const [var2, setVar2] = useState<string>(headers[1] || '');

  if (!var1 || !var2 || headers.length < 2) {
    return <div className="bg-white rounded-lg shadow p-6 text-gray-600">Need at least 2 numeric variables</div>;
  }

  const values1 = data.map(row => Number(row[var1])).filter(v => !isNaN(v));
  const values2 = data.map(row => Number(row[var2])).filter(v => !isNaN(v));

  const correlation = calculateCorrelation(values1, values2);

  const scatterData = values1.map((v1, i) => ({
    x: v1,
    y: values2[i],
  })).filter(d => !isNaN(d.x) && !isNaN(d.y));

  const getInterpretation = (corr: number) => {
    const absCorr = Math.abs(corr);
    if (absCorr < 0.3) return 'Weak';
    if (absCorr < 0.7) return 'Moderate';
    return 'Strong';
  };

  return (
    <div className="space-y-6">
      {/* Variable Selectors */}
      <div className="bg-white rounded-lg shadow p-6">
        <h3 className="text-xl font-bold text-gray-800 mb-4">Correlation Analysis</h3>
        <div className="grid grid-cols-2 gap-4">
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-2">Variable 1</label>
            <select 
              value={var1}
              onChange={(e) => setVar1(e.target.value)}
              className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
            >
              {headers.map(h => <option key={h} value={h}>{h}</option>)}
            </select>
          </div>
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-2">Variable 2</label>
            <select 
              value={var2}
              onChange={(e) => setVar2(e.target.value)}
              className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
            >
              {headers.map(h => <option key={h} value={h}>{h}</option>)}
            </select>
          </div>
        </div>
      </div>

      {/* Correlation Stats */}
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-4">
        <div className="bg-white rounded-lg shadow p-6">
          <p className="text-gray-600 text-sm">Correlation Coefficient</p>
          <p className="text-3xl font-bold text-blue-600 mt-2">{correlation.toFixed(3)}</p>
        </div>
        <div className="bg-white rounded-lg shadow p-6">
          <p className="text-gray-600 text-sm">Strength</p>
          <p className="text-3xl font-bold text-green-600 mt-2">{getInterpretation(correlation)}</p>
        </div>
        <div className="bg-white rounded-lg shadow p-6">
          <p className="text-gray-600 text-sm">Direction</p>
          <p className="text-3xl font-bold text-purple-600 mt-2">{correlation > 0 ? 'Positive' : 'Negative'}</p>
        </div>
      </div>

      {/* Scatter Plot */}
      <div className="bg-white rounded-lg shadow p-6">
        <h3 className="text-lg font-bold text-gray-800 mb-4">Scatter Plot</h3>
        <ResponsiveContainer width="100%" height={400}>
          <ScatterChart margin={{ top: 20, right: 20, bottom: 20, left: 20 }}>
            <CartesianGrid strokeDasharray="3 3" />
            <XAxis type="number" dataKey="x" name={var1} label={{ value: var1, position: 'insideBottomRight', offset: -5 }} />
            <YAxis type="number" dataKey="y" name={var2} label={{ value: var2, angle: -90, position: 'insideLeft' }} />
            <Tooltip cursor={{ strokeDasharray: '3 3' }} />
            <Scatter name={`${var1} vs ${var2}`} data={scatterData} fill="#3b82f6" />
          </ScatterChart>
        </ResponsiveContainer>
      </div>

      {/* Interpretation */}
      <div className="bg-blue-50 rounded-lg shadow p-6">
        <h3 className="text-lg font-bold text-blue-900 mb-2">Interpretation</h3>
        <p className="text-blue-800">
          The correlation coefficient of {correlation.toFixed(3)} indicates a <strong>{getInterpretation(correlation).toLowerCase()} {correlation > 0 ? 'positive' : 'negative'}</strong> relationship between {var1} and {var2}.
          {Math.abs(correlation) > 0.7 && ' This is a strong relationship.'}
          {Math.abs(correlation) > 0.3 && Math.abs(correlation) <= 0.7 && ' This is a moderate relationship.'}
          {Math.abs(correlation) <= 0.3 && ' There is little to no linear relationship.'}
        </p>
      </div>
    </div>
  );
}
