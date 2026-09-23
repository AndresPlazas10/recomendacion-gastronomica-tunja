import { useEffect, useState } from "react";
import { Pressable, StyleSheet, Text, View } from "react-native";
import { StatusBar } from "expo-status-bar";

import { env, envConfigurado } from "@/lib/env";

type Estado = "verificando" | "ok" | "error";

async function consultarApi(): Promise<Estado> {
  try {
    const respuesta = await fetch(`${env.apiUrl}/health`);
    return respuesta.ok ? "ok" : "error";
  } catch {
    return "error";
  }
}

export default function Inicio() {
  const [estadoApi, setEstadoApi] = useState<Estado>("verificando");

  useEffect(() => {
    let activo = true;
    void consultarApi().then((estado) => {
      if (activo) {
        setEstadoApi(estado);
      }
    });
    return () => {
      activo = false;
    };
  }, []);

  const verificarApi = async () => {
    setEstadoApi("verificando");
    setEstadoApi(await consultarApi());
  };

  return (
    <View style={styles.contenedor}>
      <StatusBar style="auto" />
      <Text style={styles.titulo}>Recomendación Gastronómica Tunja</Text>
      <Text style={styles.subtitulo}>Sprint 1 — base técnica</Text>

      <View style={styles.fila}>
        <Text style={styles.etiqueta}>API:</Text>
        <Text style={styles.valor}>{estadoApi}</Text>
      </View>
      <View style={styles.fila}>
        <Text style={styles.etiqueta}>Supabase:</Text>
        <Text style={styles.valor}>{envConfigurado ? "configurado" : "sin configurar"}</Text>
      </View>

      <Pressable style={styles.boton} onPress={verificarApi}>
        <Text style={styles.botonTexto}>Verificar API</Text>
      </Pressable>
    </View>
  );
}

const styles = StyleSheet.create({
  contenedor: {
    flex: 1,
    alignItems: "center",
    justifyContent: "center",
    padding: 24,
    gap: 12,
  },
  titulo: { fontSize: 22, fontWeight: "700", textAlign: "center" },
  subtitulo: { fontSize: 14, color: "#555", marginBottom: 12 },
  fila: { flexDirection: "row", gap: 8 },
  etiqueta: { fontWeight: "600" },
  valor: { color: "#0a7" },
  boton: {
    marginTop: 16,
    backgroundColor: "#0a7",
    paddingHorizontal: 20,
    paddingVertical: 10,
    borderRadius: 8,
  },
  botonTexto: { color: "#fff", fontWeight: "600" },
});
