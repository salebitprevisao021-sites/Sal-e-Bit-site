import {NextResponse} from "next/server";
/** Checkout fica fechado até configurar um provedor, preço, URL de retorno e webhooks verificados. */
export async function POST(){
 const provider=process.env.MERCADOPAGO_ACCESS_TOKEN?"mercadopago":process.env.STRIPE_SECRET_KEY?"stripe":null;
 if(!provider)return NextResponse.json({error:"Checkout ainda não configurado. Defina as credenciais do provedor no ambiente do servidor."},{status:503});
 return NextResponse.json({error:"Integração do provedor selecionado ainda precisa ser implementada e validada antes de receber pagamentos.",provider},{status:501});
}
