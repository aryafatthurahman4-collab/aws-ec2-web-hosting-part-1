# Shadcn UI + Tailwind CSS + Next.js — Referensi Lengkap

Aplikasi di repo ini **tidak memakai HTML/CSS mentah** untuk styling — semua memakai **Tailwind CSS utility classes** dan komponen **shadcn/ui** ( Radix UI + Tailwind ) di `app/components/ui/`.

---

## 1. Kenapa shadcn/ui + Tailwind

- **Tailwind CSS** = utility-first CSS; class di markup, hasil CSS diminifikasi saat build.
- **shadcn/ui** = kode komponen yang kamu *copy* ke repo (`components/ui/`), bukan dependency black-box. Bisa dimodifikasi penuh.
- **Radix UI** = primitive accessible (focus, keyboard, ARIA) di balik komponen shadcn.
- **Next.js App Router** = komponen interaktif butuh directive `"use client"`.

## 2. Instalasi (Next.js + Tailwind v4)

```bash
npx create-next-app@latest my-app --typescript --app
cd my-app
npm install tailwindcss @tailwindcss/postcss
```

`postcss.config.mjs`:

```js
export default { plugins: { '@tailwindcss/postcss': {} } };
```

`app/globals.css`:

```css
@import "tailwindcss";
```

`app/layout.tsx`:

```tsx
import './globals.css'
export default function RootLayout({ children }: { children: React.ReactNode }) {
  return <html lang="en"><body>{children}</body></html>
}
```

## 3. Tailwind v3 (kompatibilitas luas)

```bash
npm install -D tailwindcss@3 postcss autoprefixer
npx tailwindcss init -p
```

`tailwind.config.js`:

```js
module.exports = {
  content: [
    "./app/**/*.{js,ts,jsx,tsx,mdx}",
    "./pages/**/*.{js,ts,jsx,tsx,mdx}",
    "./components/**/*.{js,ts,jsx,tsx,mdx}",
  ],
  theme: { extend: {} },
  plugins: [],
}
```

`globals.css`:

```css
@tailwind base;
@tailwind components;
@tailwind utilities;
```

## 4. Memasang komponen shadcn

```bash
npx shadcn@latest init
npx shadcn@latest add button card dialog input label badge table
```

Contoh penggunaan:

```tsx
import { Button } from "@/components/ui/button"
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card"

export default function Page() {
  return (
    <main className="flex min-h-screen flex-col items-center justify-between p-24">
      <Card className="w-full max-w-md">
        <CardHeader><CardTitle>Welcome</CardTitle></CardHeader>
        <CardContent><Button>Deploy</Button></CardContent>
      </Card>
    </main>
  )
}
```

## 5. Blocks & ekosistem

- Block resmi: dashboard, login, sidebar — `npx shadcn add login-01`.
- Creative Tim: 430+ block berbasis shadcn/ui.
- `shadcn-ui-blocks`: install blok sekumpulan (hero, pricing).
- **shadcn-vue**: port untuk Vue 3 + TypeScript (Radix Vue / Reka UI).
- **Flowbite React**: komponen alternatif berbasis Tailwind.

## 6. Dark mode

v3:

```js
module.exports = { darkMode: 'class', /* ... */ }
```

v4:

```css
@import "tailwindcss";
@variant dark (&:where(.dark, .dark *));
```

Toggle: simpan preferensi di `localStorage`, tambah/hapus class `dark` di `<html>`. Tambahkan inline script di `<head>` untuk menghindari *flash* tema.

## 7. Best practice

- Import Tailwind & global style di **satu entry file** (root layout).
- Pakai class lengkap; Tailwind tidak bisa mendeteksi class dinamis — gunakan safelist.
- Pakai `prettier-plugin-tailwindcss` untuk urutan class konsisten.
- `.module.css` hanya untuk animasi kompleks; sisanya Tailwind.
- Perhatikan aksesibilitas (keyboard, screen reader, ARIA).
- Cek `next build` untuk memastikan Urutan CSS produksi benar.

## 8. Referensi

| Sumber | Link |
| --- | --- |
| shadcn/ui resmi | https://ui.shadcn.com |
| Repo shadcn/ui | https://github.com/shadcn-ui/ui |
| Next.js CSS docs | https://nextjs.org/docs/app/getting-started/css |
| Next.js CSS (Pages) | https://nextjs.org/docs/pages/getting-started/css |
| Tailwind v4 Next.js | https://tailwindcss.com/docs/guides/nextjs |
| Tailwind v3 Next.js | https://v3.tailwindcss.com/docs/guides/nextjs |
| Flowbite + Next.js | https://github.com/themesberg/flowbite/blob/main/content/getting-started/next-js.md |
| shadcn-vue | https://www.shadcn-vue.com |
| SitePoint Tailwind guide | https://www.sitepoint.com/tailwind-css-in-react-and-nextjs/ |
| Tailwind dark mode | https://tailwindcss.com/docs/dark-mode |
