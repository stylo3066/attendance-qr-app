# Dashboard Web - Attendance QR

Este directorio contiene las páginas web del dashboard para la aplicación de control de asistencia.

## Configuración de GitHub Pages

Para que estas páginas funcionen correctamente, necesitas configurar GitHub Pages:

1. Ve a **Settings** del repositorio
2. Busca la sección **Pages** 
3. En **Source**, selecciona **Deploy from a branch**
4. En **Branch**, selecciona **master**
5. En **Folder**, cambia de **/ (root)** a **/docs**
6. Haz clic en **Save**

## URLs de las páginas

Una vez configurado GitHub Pages, las URLs serán:

- **Dashboard Principal**: https://stylo3066.github.io/attendance-qr-app/docs/dashboard.html
- **Generador de QR**: https://stylo3066.github.io/attendance-qr-app/docs/test-qr.html  
- **Pruebas del Sistema**: https://stylo3066.github.io/attendance-qr-app/docs/test-system.html

## Archivos incluidos

- `dashboard.html` - Dashboard ejecutivo con mock API
- `test-qr.html` - Generador y simulador de QR
- `test-system.html` - Página de diagnóstico del sistema
- `mock-api.js` - Sistema de API simulada para GitHub Pages
- `professors.js` - Base de datos de profesores
- `index.html` - Página de inicio

## Funcionalidad

El sistema incluye:
- ✅ Dashboard con mock API para funcionamiento offline
- ✅ Generador de códigos QR para profesores
- ✅ Sistema de diagnóstico y pruebas
- ✅ Almacenamiento local con localStorage
- ✅ Interfaz responsive para móvil y desktop