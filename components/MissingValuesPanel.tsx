'use client';

import { BarChart, Bar, XAxis, YAxis, CartesianGrid, Tooltip, Legend, ResponsiveContainer, Cell } from 'recharts';
import { detectMissing } from '@/lib/dataProcessor';

interface MissingValuesPanelProps {
  data: any[];
  headers: string[];
}

export default function MissingValuesPanel({ data, headers }: MissingValuesPanelProps) {
  const missingAnalysis = headers.map(header => detectMissing(data, header));
  const totalMissing = missingAnalysis.reduce((sum, m) => sum + parseInt(m.missing), 0);
  const totalCells = data.length * headers.length;

  const chartData = missingAnalysis.map(m => ({
    column: m.column,
    missing: m.missing,
    present: data.length - m.missing,
  }));

  const colors = ['#ef4444', '#10b981'];

  return (
    <div className="space-y-6">
      {/* Overview Stats */}
      <div className="grid grid-cols-1 lg:grid-cols-4 gap-4">
        <div className="bg-white rounded-lg shadow p-6">
          <p className="text-gray-600 text-sm font-medium">Total Missing Values</p>
          <p className="text-3xl font-bold text-red-600 mt-2">{totalMissing}</p>
        </div>
        <div className="bg-white rounded-lg shadow p-6">
          <p className="text-gray-600 text-sm font-medium">Overall Missing %</p>
          <p className="text-3xl font-bold text-orange-600 mt-2">
            {((totalMissing / totalCells) * 100).toFixed(2)}%
          </p>
        </div>
        <div className="bg-white rounded-lg shadow p-6">
          <p className="text-gray-600 text-sm font-medium">Complete Records</p>
          <p className="text-3xl font-bold text-green-600 mt-2">
            {data.filter(row => headers.every(h => row[h] !== '' && row[h] !== undefined && row[h] !== null)).length}
          </p>
        </div>
        <div className="bg-white rounded-lg shadow p-6">
          <p className="text-gray-600 text-sm font-medium">Affected Variables</p>
          <p className="text-3xl font-bold text-blue-600 mt-2">
            {missingAnalysis.filter(m => m.missing > 0).length}
          </p>
        </div>
      </div>

      {/* Missing Values by Column */}
      <div className="bg-white rounded-lg shadow p-6">
        <h3 className="text-xl font-bold text-gray-800 mb-4">Missing Values by Variable</h3>
        <div className="overflow-x-auto">
          <table className="w-full text-sm">
            <thead className="bg-gray-100 border-b border-gray-300">
              <tr>
                <th className="px-4 py-2 text-left font-semibold text-gray-700">Variable</th>
                <th className="px-4 py-2 text-center font-semibold text-gray-700">Missing Count</th>
                <th className="px-4 py-2 text-center font-semibold text-gray-700">Present Count</th>
                <th className="px-4 py-2 text-right font-semibold text-gray-700">Missing %</th>
              </tr>
            </thead>
            <tbody>
              {missingAnalysis.map((m, idx) => (
                <tr key={idx} className="border-b border-gray-200 hover:bg-gray-50">
                  <td className="px-4 py-2 text-gray-800 font-medium">{m.column}</td>
                  <td className="px-4 py-2 text-center text-red-600 font-bold">{m.missing}</td>
                  <td className="px-4 py-2 text-center text-green-600 font-bold">{data.length - parseInt(m.missing)}</td>
                  <td className="px-4 py-2 text-right text-gray-700">
                    <div className="flex items-center justify-end gap-2">
                      <div className="w-20 bg-gray-200 rounded-full h-2">
                        <div
                          className={`h-2 rounded-full ${parseInt(m.missing) > 0 ? 'bg-red-500' : 'bg-green-500'}`}
                          style={{ width: `${(parseInt(m.missing) / data.length) * 100}%` }}
                        ></div>
                      </div>
                      <span className="font-medium">{m.percentage}%</span>
                    </div>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </div>

      {/* Chart */}
      <div className="bg-white rounded-lg shadow p-6">
        <h3 className="text-lg font-bold text-gray-800 mb-4">Distribution Chart</h3>
        <ResponsiveContainer width="100%" height={300}>
          <BarChart data={chartData}>
            <CartesianGrid strokeDasharray="3 3" />
            <XAxis dataKey="column" angle={-45} textAnchor="end" height={80} />
            <YAxis />
            <Tooltip />
            <Legend />
            <Bar dataKey="missing" fill="#ef4444" name="Missing" />
            <Bar dataKey="present" fill="#10b981" name="Present" />
          </BarChart>
        </ResponsiveContainer>
      </div>

      {/* Recommendations */}
      <div className="bg-yellow-50 rounded-lg shadow p-6">
        <h3 className="text-lg font-bold text-yellow-900 mb-2">Data Quality Notes</h3>
        <ul className="text-yellow-800 text-sm space-y-1">
          {missingAnalysis.map((m, idx) => (
            <li key={idx}>
              • <strong>{m.column}:</strong> {m.missing === '0' ? 'No missing values' : `${m.missing} missing value(s) (${m.percentage}%)`}
            </li>
          ))}
        </ul>
      </div>
    </div>
  );
}
