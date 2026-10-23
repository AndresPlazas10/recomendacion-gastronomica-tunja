import { env } from "./env";
import { getSupabaseClient } from "./supabase";

export type EventoTipo =
  | "busqueda"
  | "ver_restaurante"
  | "ver_plato"
  | "recomendacion_impresion"
  | "clic_recomendacion";

export type EventoEntrada = {
  tipo: EventoTipo;
  entidad_tipo: "restaurante" | "plato" | "consulta";
  entidad_id?: string;
  origen?: "busqueda" | "recomendacion" | "catalogo";
  sesion_id: string;
  termino?: string;
  filtros?: Record<string, unknown>;
  recomendacion_id?: string;
  request_id?: string;
  modelo_version?: string;
  posicion?: number;
  creado_en?: string;
};

export async function registrarEventos(eventos: EventoEntrada[]): Promise<void> {
  if (eventos.length === 0) return;
  if (eventos.length > 50) {
    throw new Error("Se pueden registrar hasta 50 eventos por solicitud.");
  }

  const { data, error } = await getSupabaseClient().auth.getSession();
  if (error || !data.session?.access_token) {
    throw new Error("Inicia sesión para registrar interacciones.");
  }

  const respuesta = await fetch(`${env.apiUrl}/v1/eventos`, {
    method: "POST",
    headers: {
      Authorization: `Bearer ${data.session.access_token}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify({ eventos }),
  });

  if (respuesta.status === 403) {
    throw new Error("Se requiere consentimiento vigente para registrar interacciones.");
  }
  if (!respuesta.ok) {
    throw new Error("No fue posible registrar las interacciones.");
  }
}
