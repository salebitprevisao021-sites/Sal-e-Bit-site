import type { Peak } from "./peaks";
export type Level = "Iniciante" | "Intermediário" | "Avançado";
export type Sport = "Surf" | "Bodyboard" | "Bodysurf" | "Skimboard";
export type Forecast = { peak: Peak; height: number; period: number; direction: number; wind: number; windDirection: number; waterTemp: number | null; score: number; safe: boolean; reasons: string[] };
const clamp = (n:number,min=0,max=10) => Math.max(min,Math.min(max,n));
const angleDiff = (a:number,b:number) => Math.abs(((a-b+540)%360)-180);

/** Nota heurística explicável (0–10); não substitui previsão local nem avisos oficiais. */
export function scorePeak(input: Omit<Forecast,"score"|"safe"|"reasons">, sport:Sport, level:Level):Forecast {
 const {peak,height,period,direction,wind,windDirection}=input;
 let score = clamp(3 + Math.min(period,16)*0.28 + Math.min(height,2.5)*0.7 - Math.max(0,wind-12)*0.13);
 const onshore = angleDiff(windDirection,(direction+180)%360);
 const offshore = onshore > 110;
 const reasons:string[]=[];
 if (sport==="Surf") { score += period>10?1.2:-0.4; score += offshore?1.0:-0.5; reasons.push(period>10?"Período longo favorece a formação":"Período curto"); reasons.push(offshore?"Vento com componente terral":"Vento pode prejudicar a superfície"); }
 if (sport==="Bodyboard") { score += height>0.8&&height<2.2?1.0:0.2; score += period>9?0.5:0; reasons.push("Energia e tamanho considerados; bancada precisa de confirmação local"); }
 if (sport==="Bodysurf"||sport==="Skimboard") { score += height<1.2?0.7:-0.3; reasons.push("Condição de beira estimada; confira maré e shorebreak no local"); }
 if (peak.id==="recreio-canto" && direction>=200 && direction<=240) { score *= 0.75; reasons.push("Redução de 25% para swell de sudoeste pela sombra do Pontal"); }
 const dangerous = height>1.8;
 const safe = !(level==="Iniciante" && dangerous);
 if (!safe) { score *= 0.45; reasons.push("Atenção: tamanho acima de 1,8 m para perfil iniciante"); }
 return {...input,score:Math.round(clamp(score)*10)/10,safe,reasons};
}

export async function getPeakForecast(peak:Peak):Promise<{marine:Record<string,number|null>;weather:Record<string,number|null>}> {
 const marineUrl = new URL("https://marine-api.open-meteo.com/v1/marine");
 marineUrl.search = new URLSearchParams({latitude:String(peak.lat),longitude:String(peak.lon),hourly:"swell_wave_height,swell_wave_period,swell_wave_direction,wind_wave_height",daily:"wave_height_max",forecast_days:"7",timezone:"America/Sao_Paulo"}).toString();
 const weatherUrl = new URL("https://api.open-meteo.com/v1/forecast");
 weatherUrl.search = new URLSearchParams({latitude:String(peak.lat),longitude:String(peak.lon),hourly:"wind_speed_10m,wind_direction_10m,temperature_2m",daily:"uv_index_max",forecast_days:"7",timezone:"America/Sao_Paulo"}).toString();
 const [m,w] = await Promise.all([fetch(marineUrl,{next:{revalidate:1800}}),fetch(weatherUrl,{next:{revalidate:1800}})]);
 if(!m.ok||!w.ok) throw new Error("Não foi possível consultar os modelos Open-Meteo.");
 const [marine,weather] = await Promise.all([m.json(),w.json()]);
 const first = (obj:any,key:string):number|null => obj?.hourly?.[key]?.[0] ?? null;
 return {marine:{height:first(marine,"swell_wave_height"),period:first(marine,"swell_wave_period"),direction:first(marine,"swell_wave_direction"),windWave:first(marine,"wind_wave_height")},weather:{wind:first(weather,"wind_speed_10m"),windDirection:first(weather,"wind_direction_10m"),waterTemp:null,airTemp:first(weather,"temperature_2m")}};
}
