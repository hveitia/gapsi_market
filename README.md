# Gapsi Market

Aplicación de búsqueda de productos desarrollada en Flutter para el ejercicio
práctico de GAPSI. Consulta un catálogo de Walmart a través del servicio Axesso
en RapidAPI, pagina conforme el usuario hace scroll y conserva el historial de
búsquedas en el dispositivo.

---

## Entorno

| Herramienta | Versión |
| --- | --- |
| Flutter | 3.38.3 (stable) |
| Dart | 3.10.1 |

El proyecto está fijado a esta cadena de herramientas (`environment.sdk: ^3.10.1`).
Las versiones más recientes de `go_router` y `sqflite` requieren Dart `^3.12.0`,
por lo que el `pubspec` permanece en las versiones que este SDK puede resolver.
Actualizar el SDK es una decisión deliberada, no un efecto secundario de subir
una dependencia.

---

## Instalación

```bash
flutter pub get
```

### Llave de API

La aplicación consume RapidAPI, que exige una llave de suscripción. **La llave no
está en este repositorio y nunca lo estará**: se entrega por separado, por correo.

Se lee en tiempo de compilación mediante `String.fromEnvironment`, de modo que se
inyecta como bandera de compilación en lugar de almacenarse en un archivo:

```bash
flutter run --dart-define=RAPIDAPI_KEY=<llave>
```

La compilación para distribución funciona igual:

```bash
flutter build apk    --dart-define=RAPIDAPI_KEY=<llave>
flutter build ipa    --dart-define=RAPIDAPI_KEY=<llave>
```

Si la aplicación se ejecuta sin la bandera, igualmente compila y arranca, e
informa en pantalla que falta la llave en lugar de fallar con un error de red
opaco.

Las pruebas y el análisis estático no requieren la llave.

---

## Ejecución de las pruebas

```bash
flutter test       # pruebas unitarias y de widgets
flutter analyze    # análisis estático, no debe reportar incidencias
```

---

## Decisiones técnicas

Cada dependencia está anotada en `pubspec.yaml` con la razón por la que está
presente. El resumen siguiente explica las decisiones que dan forma a la
arquitectura.

### Manejo de estado — `flutter_bloc`

Bloc modela una pantalla como un flujo explícito de evento de entrada y estado de
salida. La búsqueda tiene los cuatro estados que pide el ejercicio (carga,
resultados, vacío y error) más la paginación superpuesta, y Bloc convierte eso en
un único estado enumerable en lugar de un conjunto de banderas booleanas que
pueden contradecirse entre sí. Además mantiene la lógica de negocio fuera de los
widgets, que es lo que permite probar las reglas de búsqueda y paginación sin
montar interfaz. `bloc_test` verifica la secuencia exacta de estados emitidos.

### Persistencia local — `sqflite` (SQLite)

El historial de búsquedas debe sobrevivir al reinicio de la aplicación. Se eligió
SQLite sobre un almacén de tipo clave-valor porque los datos son relacionales y se
consultan, no solo se leen de vuelta: el historial se ordena por recencia y se
deduplica por término, y los favoritos se relacionan con productos. Es también el
motor de almacenamiento que cualquier revisor puede inspeccionar sin herramientas
adicionales.

`AppDatabase` es dueña de una única conexión; cada módulo aporta su propia
migración, de forma que la propiedad del esquema permanece junto a la
funcionalidad que necesita la tabla.

### Red — `dio`

Se eligió sobre `http` por su cadena de interceptores. Las credenciales de
RapidAPI se adjuntan en un solo lugar, por lo que ninguna fuente de datos maneja
la llave y un endpoint nuevo no puede olvidarla. Dio expone además la cancelación
de peticiones, en la que se apoya la búsqueda con retardo para descartar las
peticiones en vuelo cuando cambia el término.

### Inyección de dependencias — `get_it`

Un localizador de servicios en lugar de un marco de generación de código: sin paso
de compilación adicional, y los blocs reciben sus colaboradores en vez de
construirlos, que es lo que permite probarlos contra dobles de prueba. La
instancia del localizador es un parámetro, de modo que las pruebas construyen un
grafo aislado en lugar de mutar estado global.

### Navegación — `go_router`

Mantenido por el equipo de Flutter. Su tabla de rutas declarativa mantiene la
navegación legible en un solo archivo, y su enlace `redirect` centraliza la
protección de rutas autenticadas en lugar de dispersarla por los widgets.

### Manejo de errores

Los fallos se modelan como una jerarquía `sealed` en `lib/shared/errors`. Al ser
sellada, agregar un caso rompe en tiempo de compilación todo `switch` que no sea
exhaustivo, en lugar de dejarlo pasar en tiempo de ejecución. Los fallos no
transportan texto para el usuario: declaran qué ocurrió y exponen `isRetryable`,
dejando la redacción a la capa de presentación.

Los fallos se lanzan como excepciones en lugar de devolverse envueltos en un tipo
resultado. Los servicios lanzan, los blocs capturan y emiten un estado de error:
es la forma que cualquier persona que revise Flutter lee de inmediato y no cuesta
una dependencia adicional. Como la jerarquía es sellada, un `switch` sobre el
fallo capturado sigue siendo exhaustivo, de modo que se conserva la garantía por
la que normalmente se recurre a un tipo resultado.

Esa regla aplica a lo excepcional. Los desenlaces esperados de una operación
—que una contraseña no coincida, que un correo ya esté registrado— no son
excepciones: se modelan como valor de retorno del propio servicio.

### Pruebas

`flutter_test` con `bloc_test` para las secuencias de estados, `mocktail` para
dobles de prueba con seguridad de nulos y sin generación de código, y
`sqflite_common_ffi` para ejecutar un motor SQLite real sobre la máquina
anfitriona, de modo que la capa de persistencia se ejercita en lugar de simularse.

---

## Estructura del proyecto

```
lib/
├── app.dart                  # widget de la aplicación
├── main.dart                 # punto de entrada: bindings, DI, router
├── configs/
│   ├── environment.dart      # configuración de tiempo de compilación
│   └── router/               # tabla de rutas y constantes de ruta
├── modules/
│   └── <funcionalidad>/
│       ├── bloc/             # eventos, estados y bloc
│       ├── contract/         # abstracciones de las que depende el bloc
│       ├── datasource/       # fuentes remota (API) y local (SQLite)
│       ├── domain/           # modelos
│       ├── presenter/        # vistas y widgets
│       └── service/          # implementación del contrato
└── shared/
    ├── database/             # conexión única a SQLite y migraciones
    ├── di/                   # localizador de servicios
    ├── errors/               # modelo de fallos y su mapeo
    └── network/              # cliente Dio e interceptores
```

Los módulos son autocontenidos: una funcionalidad aporta sus propias pantallas, su
propia migración de base de datos y sus propios registros. Nada en `shared/` ni en
`configs/` necesita saber qué funcionalidades existen.

---

## Análisis estático

`analysis_options.yaml` extiende `flutter_lints` con los modos estrictos del
lenguaje (`strict-casts`, `strict-inference`, `strict-raw-types`) y eleva
`unawaited_futures` a error. Las conversiones de tipo no seguras y el trabajo
asíncrono sin esperar fallan el análisis en lugar de aparecer en tiempo de
ejecución.
