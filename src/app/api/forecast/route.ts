import { NextRequest, NextResponse } from "next/server";
import { PEAKS } from "@/lib/peaks";
import { getPeakForecast, scorePeak, type Sport, type Level } from "@/lib/boia021";

// Cada consulta depende do pico, modalidade e nível enviados na URL.
// Evita que a CDN reutilize a resposta de um pico para os demais.
export const dynamic = "force-dynamic";

export async function GET(request: NextRequest) {
  const id = request.nextUrl.searchParams.get("peak");
  const sport = (request.nextUrl.searchParams.get("sport") || "Surf") as Sport;
  const level = (request.nextUrl.searchParams.get("level") || "Iniciante") as Level;

  if (
    !["Surf", "Bodyboard", "Bodysurf", "Skimboard"].includes(sport) ||
    !["Iniciante", "Intermediário", "Avançado"].includes(level)
  ) {
    return NextResponse.json(
      { error: "Parâmetros inválidos" },
      { status: 400, headers: { "Cache-Control": "no-store" } }
    );
  }

  const peak = PEAKS.find((item) => item.id === id);
  if (!peak) {
    return NextResponse.json(
      { error: "Pico não encontrado" },
      { status: 404, headers: { "Cache-Control": "no-store" } }
    );
  }

  try {
    const raw = await getPeakForecast(peak);
    const height = raw.marine.height ?? 0;
    const period = raw.marine.period ?? 0;
    const direction = raw.marine.direction ?? 0;
    const wind = raw.weather.wind ?? 0;
    const windDirection = raw.weather.windDirection ?? 0;

    const result = scorePeak(
      {
        peak,
        height,
        period,
        direction,
        wind,
        windDirection,
        waterTemp: raw.weather.waterTemp,
      },
      sport,
      level
    );

    return NextResponse.json(result, {
      headers: { "Cache-Control": "no-store, max-age=0" },
    });
  } catch {
    return NextResponse.json(
      { error: "Modelos de previsão temporariamente indisponíveis" },
      { status: 502, headers: { "Cache-Control": "no-store" } }
    );
  }
}
