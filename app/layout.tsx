import type { Metadata } from "next";
import "./globals.css";

export const metadata: Metadata = {
  title: "Medical Statistical Analysis",
  description: "Interactive interface for medical data statistical analysis",
};

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html lang="en">
      <body className="bg-gray-50">
        {children}
      </body>
    </html>
  );
}
