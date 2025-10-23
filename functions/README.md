Cloud Function: verifyAttendance

Esta función HTTPS valida una firma HMAC y crea un documento verificado en la colección `attendance_events`.

Despliegue rápido:

1. Instala Firebase CLI: `npm install -g firebase-tools` y autentícate `firebase login`.
2. Inicializa funciones (si aún no lo hiciste): `firebase init functions` y selecciona JS.
3. Configura la clave HMAC segura en Firebase config:

```
firebase functions:config:set hmac.secret="TU_SECRETO_AQUI"
```

4. Despliega solo la función:

```
cd functions
npm install
firebase deploy --only functions:verifyAttendance
```

5. Firebase te dará la URL HTTPS de la función; usa esa URL en la app para enviar el POST.
