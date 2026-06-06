# PortMonitor

PortMonitor es una app ligera para macOS que vive en la barra de menu y muestra, en tiempo real, los puertos TCP locales que estan abiertos. Esta pensada para desarrollo: permite ver rapidamente que servicios estan escuchando, abrir un puerto en el navegador y terminar procesos que quedaron ocupando un puerto.

## Funcionalidad

- Muestra un icono permanente en la barra de menu de macOS.
- Escanea puertos TCP en estado `LISTEN` usando `lsof`.
- Lista los puertos activos con el nombre del proceso asociado.
- Ordena los resultados por numero de puerto.
- Deduplica entradas IPv4/IPv6 para que un mismo puerto no aparezca repetido.
- Filtra puertos efimeros y procesos de sistema comunes para mantener la lista enfocada en servidores locales utiles.
- Actualiza el indicador de la barra de menu cada 5 segundos.
- Muestra un punto verde en el icono cuando hay puertos activos.
- Refresca la lista al abrir el menu y tambien desde el boton de refrescar.
- Abre `http://localhost:<puerto>` en el navegador con un clic.
- Permite terminar el proceso asociado a un puerto con un clic.
- Avisa cuando un proceso no puede finalizarse por falta de permisos y sugiere el comando manual con `sudo kill -9`.
- Incluye una ventana de preferencias.
- Permite activar o desactivar el inicio automatico al iniciar sesion mediante `launchd`.
- Funciona como app accesoria: no ocupa espacio en el Dock.
- Incluye generador de icono `.icns` basado en SF Symbols.
- Incluye script de compilacion e instalacion para macOS.

## Uso

Al iniciar PortMonitor aparece un icono de red en la barra de menu. Si hay puertos activos, el icono muestra un punto verde.

Al abrir el menu se muestra la lista de puertos detectados. Cada fila incluye:

- Numero de puerto.
- Nombre del proceso.
- Boton para abrir el puerto en el navegador.
- Boton para finalizar el proceso.

En la parte inferior del menu hay accesos para:

- Abrir preferencias.
- Refrescar la lista manualmente.
- Salir de la app.

## Preferencias

La ventana de preferencias incluye la opcion **Lanzar al iniciar el sistema**. Al activarla, PortMonitor crea un archivo `LaunchAgent` en la cuenta del usuario para ejecutarse automaticamente al iniciar sesion grafica.

## Requisitos

- macOS 12.0 o superior.
- Swift toolchain / Xcode Command Line Tools.
- Arquitectura Apple Silicon para el build por defecto del script.

## Compilar e instalar

Desde la raiz del proyecto:

```sh
bash build.sh
```

El script:

1. Limpia el directorio `build/`.
2. Compila los archivos Swift de `Sources/`.
3. Crea el bundle `PortMonitor.app`.
4. Copia `Info.plist` y `AppIcon.icns`.
5. Instala la app en `/Applications/PortMonitor.app`.

Luego se puede abrir con:

```sh
open /Applications/PortMonitor.app
```

## Generar el icono

Si necesitas regenerar `AppIcon.icns`:

```sh
bash make_icon.sh
```

El script genera un icono de macOS a partir de un simbolo de red de SF Symbols y crea todos los tamanos requeridos para el `.icns`.

## Estructura del proyecto

```text
Sources/
  AppDelegate.swift
  LoginItemManager.swift
  MenuFooterView.swift
  PortMenuItemView.swift
  PortScanner.swift
  SettingsWindowController.swift
  StatusBarController.swift
  main.swift

AppIcon.icns
Info.plist
build.sh
make_icon.sh
```

## Notas

PortMonitor esta orientado a servidores locales y flujos de desarrollo. El escaneo excluye procesos de sistema o aplicaciones de fondo conocidos para evitar ruido en la lista. Si un proceso requiere privilegios elevados para terminarse, la app no intenta escalar permisos automaticamente: muestra una alerta con el comando manual sugerido.
