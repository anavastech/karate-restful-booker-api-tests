# Pruebas de API con Karate — Restful Booker

[![API Tests](https://github.com/anavastech/karate-restful-booker-api-tests/actions/workflows/api-tests.yml/badge.svg)](https://github.com/anavastech/karate-restful-booker-api-tests/actions/workflows/api-tests.yml)
[![Karate](https://img.shields.io/badge/Karate-1.5.2-2c3e50)](https://github.com/karatelabs/karate)
[![Java](https://img.shields.io/badge/Java-17-orange)](https://adoptium.net/)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

📊 **Último reporte de pruebas:** https://anavastech.github.io/karate-restful-booker-api-tests/

Suite de automatización de pruebas de API para [Restful Booker](https://restful-booker.herokuapp.com/apidoc/index.html),
construida con **Karate** y **JUnit 5**. Cubre todos los endpoints de la API con pruebas funcionales, negativas, de
contrato, data-driven y end-to-end; se ejecuta en paralelo en GitHub Actions todos los días y publica el reporte HTML en
GitHub Pages.

Restful Booker es una API pública de reservas de hotel creada para practicar pruebas de API. **Incluye bugs
intencionales**, por lo que parte de este proyecto los documenta como hallazgos (ver [Hallazgos](#hallazgos)).

---

## Stack tecnológico

| Herramienta | Propósito |
|---|---|
| Java 17 + Maven | Build y gestión de dependencias |
| [Karate 1.5.2](https://github.com/karatelabs/karate) (`io.karatelabs`) | DSL de pruebas de API, aserciones, validación de esquemas, reportes |
| JUnit 5 | Runner de pruebas (ejecución en paralelo) |
| GitHub Actions | CI en push / PR / ejecución diaria programada / ejecución manual |
| GitHub Pages | Publicación del reporte HTML de Karate |

## Estructura del proyecto

```
.
├── .github/workflows/api-tests.yml      # pipeline de CI + publicación del reporte
├── pom.xml
└── src/test/java
    ├── karate-config.js                 # baseUrl, credenciales y timeouts por entorno
    ├── logback-test.xml                 # consola limpia, log HTTP completo en target/karate.log
    ├── runners/TestRunner.java          # runner JUnit 5 en paralelo con filtro por tags
    ├── common
    │   ├── auth.feature                 # helper reutilizable para obtener el token (callonce)
    │   ├── create-booking.feature       # helper reutilizable para crear datos de prueba
    │   ├── basic-auth.js                # genera el header de Basic auth
    │   ├── data/                        # plantilla de payload, generador de datos, sets data-driven
    │   └── schemas/                     # contratos fuzzy-match (booking, booking creado, token, id)
    └── features
        ├── health/ping.feature
        ├── auth/auth.feature
        ├── booking/                     # get, create, update, partial-update, delete, filter
        └── e2e/booking-lifecycle.feature
```

## Decisiones de diseño

- **Comportamiento observado vs. comportamiento correcto.** Los escenarios de regresión validan lo que la API hace
  *realmente* hoy, verificado manualmente con `curl` antes de escribir cualquier prueba. Cuando ese comportamiento es
  incorrecto, un escenario `@bug` separado valida el comportamiento *correcto* y, por lo tanto, se espera que falle. Los
  escenarios `@bug` se excluyen de la ejecución por defecto y del CI. Si algún día la API se corrige, la prueba de
  regresión falla y la `@bug` pasa, lo que es una señal clara para actualizar la suite.
- **Pruebas independientes y seguras en paralelo.** Cada escenario crea su propio booking mediante
  `common/create-booking.feature`, usando nombres con sufijo UUID y fechas relativas al día actual (`data-generator.js`).
  Ningún escenario depende de otro ni de datos precargados, algo importante porque la API pública **se reinicia
  periódicamente** y la suite corre en 5 hilos.
- **Contratos reutilizables.** Los esquemas de respuesta están en `common/schemas/` como fuzzy matchers de Karate
  (`#string`, `#number`, `#boolean`, `##string` para campos opcionales, `#regex` para fechas ISO) y se reutilizan entre
  features.
- **Pruebas data-driven.** Los payloads válidos e inválidos están en archivos JSON y alimentan `Scenario Outline`s
  dinámicos (`Examples: | read('...json') |`), así que agregar un caso significa agregar un objeto JSON, no un escenario.
- **Autenticación.** El token se obtiene una sola vez por feature con `callonce`. Se cubren los dos modos de
  autenticación soportados: `Cookie: token=<token>` y `Authorization: Basic`.
- **Se verifican los efectos secundarios.** Las llamadas `PUT`/`PATCH`/`DELETE` rechazadas van seguidas de un `GET` que
  demuestra que el booking no fue modificado ni eliminado, y un `DELETE` exitoso se confirma con un `404`.
- **Sin configuración hardcodeada.** La URL base, las credenciales y el umbral de tiempo de respuesta vienen de
  `karate-config.js` y se pueden sobrescribir con propiedades del sistema o variables de entorno.
- **Tiempo de respuesta.** Los escenarios smoke validan `responseTime < maxResponseTime` (5000 ms por defecto). La API
  corre en un dyno compartido de Heroku con picos ocasionales de latencia, por lo que el umbral es tolerante a propósito y
  configurable.

## Ejecución local

**Requisitos:** JDK 17+ y Maven 3.8+.

```bash
# Suite completa (todo excepto @bug)
mvn test

# Por tag (coma = OR)
mvn test -Dtags=@smoke
mvn test -Dtags=@negative
mvn test -Dtags=@smoke,@e2e

# Ejecutar los defectos conocidos de la API (se espera que fallen)
mvn test -Dtags=@bug

# Elegir el entorno y el paralelismo
mvn test -Dkarate.env=local -Dthreads=3
```

El reporte se genera en `target/karate-reports/karate-summary.html`.

### Entornos y configuración

| Parámetro | Propiedad del sistema | Variable de entorno | Valor por defecto |
|---|---|---|---|
| Entorno | `-Dkarate.env` | — | `dev` |
| URL base | `-DbaseUrl` | `RB_BASE_URL` | `dev`: `https://restful-booker.herokuapp.com` · `local`: `http://localhost:3001` |
| Usuario | `-Dusername` | `RB_USERNAME` | `admin` |
| Contraseña | `-Dpassword` | `RB_PASSWORD` | `password123` |
| Tiempo máximo de respuesta (ms) | `-DmaxResponseTime` | `RB_MAX_RESPONSE_TIME` | `5000` |

Para ejecutar contra una instancia local: `docker run -p 3001:3001 mwinteringham/restfulbooker` y luego
`mvn test -Dkarate.env=local`.

### Tags

| Tag | Significado |
|---|---|
| `@smoke` | Validaciones críticas y rápidas (un camino feliz por endpoint + E2E) |
| `@regression` | Suite completa |
| `@negative` | Datos inválidos, autenticación ausente o inválida, recursos inexistentes |
| `@e2e` | Ciclo de vida completo de un booking |
| `@bug` | Documenta un defecto real de la API validando el comportamiento correcto; **falla a propósito** y se excluye por defecto |

## CI/CD

El [workflow](.github/workflows/api-tests.yml) se ejecuta en cada push y pull request a `main`, todos los días a las
06:00 UTC y bajo demanda (**Actions → API Tests → Run workflow**), donde se puede elegir qué tag ejecutar. El pipeline:

1. Configura Temurin JDK 17 con caché de Maven.
2. Ejecuta la suite (excluyendo `@bug`).
3. Sube `target/karate-reports` como artefacto del build.
4. Publica el reporte HTML en GitHub Pages (en `main`, incluso cuando fallan las pruebas, para que el reporte muestre qué
   se rompió).

## Cobertura de pruebas

47 escenarios de regresión + 20 escenarios `@bug`.

| Endpoint | Escenarios cubiertos |
|---|---|
| `GET /ping` | El health check responde (status, body, tiempo de respuesta) |
| `POST /auth` | Credenciales válidas devuelven un token (contrato) · contraseña incorrecta, usuario inexistente, credenciales vacías y body vacío no devuelven token · 🐞 un login inválido debería devolver 401 |
| `GET /booking` | Contrato del listado (`[{ bookingid }]`) |
| `GET /booking?…` | Filtro por firstname + lastname, solo por lastname, sin coincidencias → `[]`, rango de fechas que contiene el booking, rangos de fechas que lo excluyen · 🐞 el filtro `checkin` debería ser inclusivo |
| `GET /booking/{id}` | Booking existente (contrato + datos exactos + content type) · ids inexistentes (`2147483647`, `0`, `abc`) → 404 |
| `POST /booking` | Contrato de la respuesta · se persiste y se puede consultar · `additionalneeds` es opcional · outline data-driven con 4 sets de datos válidos · se rechazan 5 campos obligatorios faltantes · 🐞 12 payloads inválidos (campos faltantes, tipos incorrectos, fechas inválidas, precio negativo, checkout antes del checkin) deberían devolver 400 · 🐞 un body vacío debería devolver 400 · 🐞 la creación debería devolver 201 |
| `PUT /booking/{id}` | Actualización con token en cookie (verificada con GET) · actualización con Basic auth · sin token / token inválido / contraseña Basic incorrecta → 403 y booking sin cambios · body incompleto → 400 · 🐞 un id inexistente debería devolver 404 |
| `PATCH /booking/{id}` | Patch de varios campos conserva el resto · outline data-driven que modifica cada campo, incluido el objeto anidado `bookingdates` · sin token / token inválido → 403 y booking sin cambios · 🐞 un id inexistente debería devolver 404 |
| `DELETE /booking/{id}` | Eliminación con token y luego GET → 404 · sin token / token inválido → 403 y el booking sigue existiendo · 🐞 una eliminación exitosa debería devolver 200/204 · 🐞 eliminar dos veces debería devolver 404 |
| E2E | Auth → crear → consultar → actualizar → actualizar parcialmente → eliminar → confirmar 404 |

## Hallazgos

Comportamientos inesperados encontrados al explorar la API (primero manualmente con `curl`, luego automatizados). Los
marcados con 🐞 están cubiertos por un escenario `@bug` que falla.

| # | Petición | Esperado (buenas prácticas REST / documentación) | Real | Prueba |
|---|---|---|---|---|
| 1 | `POST /auth` con credenciales incorrectas o body vacío | `401 Unauthorized` | `200 OK` con `{"reason":"Bad credentials"}` | 🐞 |
| 2 | `POST /booking` (éxito) | `201 Created` (+ header `Location`) | `200 OK` | 🐞 |
| 3 | `POST /booking` sin un campo obligatorio, con body vacío o con `firstname` numérico | `400 Bad Request` con mensaje de validación | `500 Internal Server Error` | 🐞 |
| 4 | `POST /booking` con `"totalprice": "one hundred"` | `400` | `200`, se guarda como `"totalprice": null` | 🐞 |
| 5 | `POST /booking` con `"depositpaid": "yes"` | `400` | `200`, se convierte silenciosamente a `true` | 🐞 |
| 6 | `POST /booking` con `"checkin": "not-a-date"` | `400` | `200`, se guarda como `"0NaN-aN-aN"` | 🐞 |
| 7 | `POST /booking` con `"checkin": "2030-02-30"` | `400` | `200`, se corre silenciosamente a `2030-03-02` | 🐞 |
| 8 | `POST /booking` con checkout antes del checkin, o `totalprice` negativo | `400` | `200`, se acepta | 🐞 |
| 9 | `PUT` / `PATCH` / `DELETE` sobre un id inexistente (incluido eliminar dos veces) | `404 Not Found` | `405 Method Not Allowed` | 🐞 |
| 10 | `DELETE /booking/{id}` (éxito) | `200 OK` o `204 No Content` | `201 Created` | 🐞 |
| 11 | `GET /booking?checkin=YYYY-MM-DD` | Documentación: checkin **≥** fecha | Checkin **>** fecha (se excluyen los bookings que empiezan ese día) | 🐞 |
| 12 | `GET /booking?checkout=YYYY-MM-DD` | Documentación: checkout **≥** fecha | Checkout **≤** fecha (la documentación y la implementación no coinciden) | — |
| 13 | `GET /ping` | `200 OK` | `201 Created` | — |
| 14 | `PUT` / `PATCH` / `DELETE` sin credenciales | `401 Unauthorized` (sin credenciales) | `403 Forbidden` tanto sin token como con token inválido | — |
| 15 | `POST /booking` con `Accept: application/xml` | `Content-Type: application/xml` | Body XML servido como `Content-Type: text/html` | — |
| 16 | Cualquier respuesta de error | Error estructurado en JSON | Body en texto plano (`Not Found`, `Forbidden`, …) | — |

## Reporte

![Reporte HTML de Karate](docs/images/karate-report.png)

## Licencia

[MIT](LICENSE)
