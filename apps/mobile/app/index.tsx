import { useEffect, useState } from "react";
import {
  ActivityIndicator,
  KeyboardAvoidingView,
  Platform,
  Pressable,
  StyleSheet,
  Text,
  TextInput,
  View,
} from "react-native";
import { StatusBar } from "expo-status-bar";

import { env, envConfigurado } from "@/lib/env";
import { getSupabaseClient } from "@/lib/supabase";

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
  const [correo, setCorreo] = useState("");
  const [contrasena, setContrasena] = useState("");
  const [confirmacion, setConfirmacion] = useState("");
  const [mensaje, setMensaje] = useState("");
  const [error, setError] = useState(false);
  const [registrando, setRegistrando] = useState(false);

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

  const registrarUsuario = async () => {
    setMensaje("");
    setError(false);

    const correoNormalizado = correo.trim().toLowerCase();
    if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(correoNormalizado)) {
      setError(true);
      setMensaje("Ingresa un correo electrónico válido.");
      return;
    }
    if (!contrasena) {
      setError(true);
      setMensaje("La contraseña es obligatoria.");
      return;
    }
    if (contrasena !== confirmacion) {
      setError(true);
      setMensaje("Las contraseñas no coinciden.");
      return;
    }

    setRegistrando(true);
    try {
      const { data, error: errorAuth } = await getSupabaseClient().auth.signUp({
        email: correoNormalizado,
        password: contrasena,
      });

      if (errorAuth) {
        setError(true);
        setMensaje(
          errorAuth.message.toLowerCase().includes("already")
            ? "No fue posible crear la cuenta con esos datos. Verifica si ya existe."
            : "No fue posible completar el registro. Revisa los datos e inténtalo nuevamente.",
        );
        return;
      }

      setError(false);
      setMensaje(
        data.session
          ? "Cuenta creada correctamente. Ya puedes continuar en la aplicación."
          : "Solicitud de registro creada. Revisa tu correo si Supabase requiere confirmación.",
      );
      setContrasena("");
      setConfirmacion("");
    } catch {
      setError(true);
      setMensaje("No fue posible conectar con el servicio de registro.");
    } finally {
      setRegistrando(false);
    }
  };

  return (
    <KeyboardAvoidingView
      style={styles.contenedor}
      behavior={Platform.OS === "ios" ? "padding" : undefined}
    >
      <StatusBar style="auto" />
      <Text style={styles.titulo}>Recomendación Gastronómica Tunja</Text>
      <Text style={styles.subtitulo}>Crea tu cuenta para comenzar</Text>

      <View style={styles.fila}>
        <Text style={styles.etiqueta}>API:</Text>
        <Text style={styles.valor}>{estadoApi}</Text>
      </View>
      <View style={styles.fila}>
        <Text style={styles.etiqueta}>Supabase:</Text>
        <Text style={styles.valor}>{envConfigurado ? "configurado" : "sin configurar"}</Text>
      </View>

      <TextInput
        style={styles.campo}
        autoCapitalize="none"
        autoComplete="email"
        keyboardType="email-address"
        onChangeText={setCorreo}
        placeholder="Correo electrónico"
        value={correo}
        editable={envConfigurado && !registrando}
        accessibilityLabel="Correo electrónico"
      />
      <TextInput
        style={styles.campo}
        autoCapitalize="none"
        autoComplete="new-password"
        onChangeText={setContrasena}
        placeholder="Contraseña"
        secureTextEntry
        value={contrasena}
        editable={envConfigurado && !registrando}
        accessibilityLabel="Contraseña"
      />
      <TextInput
        style={styles.campo}
        autoCapitalize="none"
        autoComplete="new-password"
        onChangeText={setConfirmacion}
        placeholder="Confirma la contraseña"
        secureTextEntry
        value={confirmacion}
        editable={envConfigurado && !registrando}
        accessibilityLabel="Confirma la contraseña"
      />

      {mensaje ? (
        <Text style={error ? styles.mensajeError : styles.mensajeExito} accessibilityRole="alert">
          {mensaje}
        </Text>
      ) : null}
      {!envConfigurado ? (
        <Text style={styles.aviso}>Configura Supabase en las variables EXPO_PUBLIC_* para registrarte.</Text>
      ) : null}

      <Pressable
        style={[styles.boton, (!envConfigurado || registrando) && styles.botonDeshabilitado]}
        onPress={() => void registrarUsuario()}
        disabled={!envConfigurado || registrando}
        accessibilityRole="button"
      >
        {registrando ? (
          <ActivityIndicator color="#fff" />
        ) : (
          <Text style={styles.botonTexto}>Crear cuenta</Text>
        )}
      </Pressable>

      <Pressable style={styles.boton} onPress={verificarApi}>
        <Text style={styles.botonTexto}>Verificar API</Text>
      </Pressable>
    </KeyboardAvoidingView>
  );
}

const styles = StyleSheet.create({
  contenedor: {
    flex: 1,
    alignItems: "center",
    justifyContent: "center",
    padding: 24,
    gap: 12,
    backgroundColor: "#fff",
  },
  titulo: { fontSize: 22, fontWeight: "700", textAlign: "center" },
  subtitulo: { fontSize: 14, color: "#555", marginBottom: 12 },
  fila: { flexDirection: "row", gap: 8 },
  etiqueta: { fontWeight: "600" },
  valor: { color: "#0a7" },
  campo: {
    width: "100%",
    borderWidth: 1,
    borderColor: "#aaa",
    borderRadius: 8,
    paddingHorizontal: 12,
    paddingVertical: 11,
    fontSize: 16,
  },
  boton: {
    marginTop: 16,
    backgroundColor: "#0a7",
    paddingHorizontal: 20,
    paddingVertical: 10,
    borderRadius: 8,
    minWidth: 160,
    alignItems: "center",
  },
  botonTexto: { color: "#fff", fontWeight: "600" },
  botonDeshabilitado: { opacity: 0.55 },
  mensajeError: { color: "#b42318", textAlign: "center" },
  mensajeExito: { color: "#067647", textAlign: "center" },
  aviso: { color: "#7a2e0e", textAlign: "center" },
});
