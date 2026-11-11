import type { Metadata, Viewport } from "next";
import { Geist, Geist_Mono } from "next/font/google";
import "./globals.css";

const siteUrl = process.env.NEXT_PUBLIC_SITE_URL ?? "http://localhost:3000";

const geistSans = Geist({
  variable: "--font-geist-sans",
  subsets: ["latin"],
  display: "swap",
});

const geistMono = Geist_Mono({
  variable: "--font-geist-mono",
  subsets: ["latin"],
  display: "swap",
});

export const metadata: Metadata = {
  metadataBase: new URL(siteUrl),
  title: {
    default: "EC2 Web Hosting Lab — Next.js Deployment Part 1",
    template: "%s · EC2 Web Hosting Lab",
  },
  description:
    "Lab deployment Next.js + Tailwind ke AWS EC2 dengan Docker, Nginx, HTTPS, Terraform, Helm, dan GitHub Actions.",
  keywords: [
    "AWS",
    "EC2",
    "Next.js",
    "Docker",
    "Terraform",
    "Kubernetes",
    "Helm",
    "GitHub Actions",
  ],
  openGraph: {
    title: "EC2 Web Hosting Lab",
    description:
      "Dari localhost ke AWS: Next.js, Docker, Nginx, HTTPS, Terraform, dan CI/CD.",
    type: "website",
    locale: "id_ID",
  },
  robots: { index: true, follow: true },
};

export const viewport: Viewport = {
  themeColor: "#fafafa",
  width: "device-width",
  initialScale: 1,
};

export default function RootLayout({
  children,
}: Readonly<{ children: React.ReactNode }>) {
  return (
    <html lang="id" suppressHydrationWarning>
      <body
        className={`${geistSans.variable} ${geistMono.variable} min-h-screen bg-background font-sans text-foreground antialiased`}
      >
        {children}
      </body>
    </html>
  );
}
