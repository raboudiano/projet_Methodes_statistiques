// Parse CSV data
export function parseCSV(csvContent: string) {
  const lines = csvContent.trim().split('\n');
  const headers = lines[0].split(';').map(h => h.trim());
  
  const data = lines.slice(1).map(line => {
    const values = line.split(';').map(v => v.trim());
    const obj: Record<string, any> = {};
    headers.forEach((header, index) => {
      const value = values[index];
      obj[header] = isNaN(Number(value)) ? value : Number(value);
    });
    return obj;
  });
  
  return { headers, data };
}

// Calculate statistics
export function calculateStats(values: number[]) {
  const sorted = [...values].sort((a, b) => a - b);
  const mean = values.reduce((a, b) => a + b, 0) / values.length;
  const variance = values.reduce((a, b) => a + Math.pow(b - mean, 2), 0) / values.length;
  const stdev = Math.sqrt(variance);
  
  return {
    count: values.length,
    mean: parseFloat(mean.toFixed(2)),
    median: sorted[Math.floor(sorted.length / 2)],
    min: Math.min(...values),
    max: Math.max(...values),
    stdev: parseFloat(stdev.toFixed(2)),
    variance: parseFloat(variance.toFixed(2)),
  };
}

// Detect missing values
export function detectMissing(data: any[], column: string) {
  const missing = data.filter(row => !row[column] || row[column] === '').length;
  return {
    column,
    missing,
    percentage: ((missing / data.length) * 100).toFixed(2),
  };
}

// Detect outliers using IQR method
export function detectOutliers(values: number[]) {
  const sorted = [...values].sort((a, b) => a - b);
  const q1 = sorted[Math.floor(sorted.length * 0.25)];
  const q3 = sorted[Math.floor(sorted.length * 0.75)];
  const iqr = q3 - q1;
  
  const lower = q1 - 1.5 * iqr;
  const upper = q3 + 1.5 * iqr;
  
  const outliers = values.filter(v => v < lower || v > upper);
  
  return {
    count: outliers.length,
    percentage: ((outliers.length / values.length) * 100).toFixed(2),
    values: outliers,
  };
}

// Calculate correlation
export function calculateCorrelation(values1: number[], values2: number[]) {
  const n = Math.min(values1.length, values2.length);
  const mean1 = values1.reduce((a, b) => a + b, 0) / n;
  const mean2 = values2.reduce((a, b) => a + b, 0) / n;
  
  let numerator = 0;
  let denominator1 = 0;
  let denominator2 = 0;
  
  for (let i = 0; i < n; i++) {
    const diff1 = values1[i] - mean1;
    const diff2 = values2[i] - mean2;
    numerator += diff1 * diff2;
    denominator1 += diff1 * diff1;
    denominator2 += diff2 * diff2;
  }
  
  const correlation = numerator / Math.sqrt(denominator1 * denominator2);
  return parseFloat(correlation.toFixed(3));
}
