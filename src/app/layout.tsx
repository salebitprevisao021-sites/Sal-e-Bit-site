import type { Metadata, Viewport } from "next";
import "./globals.css";
export const metadata:Metadata={title:"Sal & Bit — Tecnologia Boia 021",description:"Previsão de surf e esportes de onda no Rio de Janeiro.",manifest:"/manifest.webmanifest",applicationName:"Sal & Bit"};
export const viewport:Viewport={themeColor:"#0A192F",width:"device-width",initialScale:1,maximumScale:1};
export default function RootLayout({children}:{children:React.ReactNode}){return <html lang="pt-BR"><body>{children}</body></html>}
