import {NextResponse} from "next/server";
export async function GET(){return NextResponse.json({status:"ok",service:"sal-e-bit",timestamp:new Date().toISOString(),supabaseConfigured:!!process.env.NEXT_PUBLIC_SUPABASE_URL});}
