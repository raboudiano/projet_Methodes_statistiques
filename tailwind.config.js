/** @type {import('tailwindcss').Config} */
export default {
  content: [
    "./app/**/*.{js,ts,jsx,tsx}",
    "./components/**/*.{js,ts,jsx,tsx}",
  ],
  theme: {
    extend: {
      colors: {
        primary: "#0066cc",
        secondary: "#f0f4f8",
        accent: "#ff6b6b",
      },
    },
  },
  plugins: [],
}
