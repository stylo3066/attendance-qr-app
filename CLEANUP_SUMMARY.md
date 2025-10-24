# Resumen de limpieza — rama `online-clean-pruned`

Fecha: 24 de octubre de 2025

Este archivo resume los cambios hechos para dejar el repositorio optimizado para un despliegue "online" ( Dokku / servidores web ).

Ramas relevantes
- `online-clean` — contiene la versión en la que _se movieron_ los proyectos nativos y artefactos a `archive/` (backup disponible aquí).\
- `online-clean-pruned` — rama actual: se eliminaron `archive/` y `vercel-proxy/node_modules/` del árbol repo y se añadió `.gitignore` para evitar re-subirlos.

Qué se movió o eliminó
- Movido (en `online-clean`): carpetas y artefactos no necesarios para deploy web:
  - `.dart_tool`, `.idea`, `.vscode`, `android/`, `ios/`, `linux/`, `macos/`, `windows/`, `build/`, `lib/` (código Flutter), `test/`, `tools/`, archivos `.iml`, scripts de instalación local, caches, etc.
  - Motivo: son específicos para compilación nativa y aumentan mucho el tamaño; no son necesarios si vas a desplegar solo la parte web/server.

- Eliminado (en `online-clean-pruned`):
  - `archive/` (se había creado previamente y se limpió en esta rama).\
  - `vercel-proxy/node_modules/` (dependencias instaladas localmente).\
  - Se añadió a `.gitignore`: `/vercel-proxy/node_modules/` y `archive/`.
  - Motivo: reducir tamaño del repo y evitar subir dependencias ya resolvibles con `npm install` en el servidor.

Dónde recuperar archivos si hace falta
- Si necesitas recuperar `archive/` o cualquier archivo que movimos, están disponibles en la rama `online-clean` (remote) — puedes cambiar a esa rama o crear una rama desde ella.

Próximos pasos sugeridos para Dokku
1) Preparar la app para Dokku: normalmente Dokku hace deploy mediante `git push dokku <branch>:master`.
2) Crear remoto dokku (ejemplo):

   git remote add dokku dokku@tudominio.com:attendance-qr

3) Desplegar desde la rama reducida (por ejemplo `online-clean-pruned`):

   git push dokku online-clean-pruned:master

4) En el servidor Dokku, instala las dependencias necesarias para la parte `server/` o `vercel-proxy/` (por ejemplo Node.js). Si tu repo contiene un `package.json` en `server/` o `vercel-proxy/`, Dokku detectará automáticamente la buildpack Node.js si el `package.json` está en el root; si no, puedes usar un `Procfile` o un pequeño script que copie/instale desde la subcarpeta.

Notas y recomendaciones
- Mantén `online-clean` como rama de respaldo si aún quieres conservar todos los assets nativos y código Flutter.
- Si prefieres que `archive/` quede en remoto pero fuera de `master`, puedo crear una rama `archive-backup` desde `online-clean` y eliminar `archive/` del resto del historial.
- Antes de mergear `online-clean-pruned` a `master`, revisa el PR y verifica que `web/` y `server/` contengan todo lo necesario para el deploy (por ejemplo `package.json`, `start` script o `Procfile`).

Si quieres, hago ahora:
- Crear `archive-backup` desde `online-clean` y empujarla al remoto (backup seguro).\
- Crear el PR y/o mergear `online-clean-pruned` a `master`.\
- Generar un `Procfile` o ajustar `package.json` para Dokku según la estructura real del servidor.

— Fin del resumen —
