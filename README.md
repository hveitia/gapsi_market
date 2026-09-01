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

### Búsqueda y paginación

La búsqueda es el centro del ejercicio y sus reglas son propiedades del código,
no convenciones a recordar.

El texto que se escribe pasa por un *debounce*, de modo que una ráfaga de
pulsaciones se convierte en una sola petición, y el transformador es
`restartable`: si llega un término nuevo, el manejador del anterior se abandona
en lugar de competir por emitir. La petición en vuelo además se cancela, así una
respuesta lenta de un término viejo no puede caer encima de una más reciente.
Una cancelación es flujo normal y nunca se muestra como error.

Las páginas adicionales están protegidas dos veces. El transformador `droppable`
descarta los eventos repetidos que produce el desplazamiento cerca del final, y
el propio estado los rechaza mediante `canLoadMore`, que es falso mientras una
página está en curso y una vez que los resultados se agotaron.

Que un fallo al paginar no borre lo ya cargado no depende de recordar no
hacerlo: el fallo es un campo del estado que contiene los productos
(`SearchResults.pageLoad`), así que no existe un camino que reemplace uno por
otro.

### El servicio

El endpoint no responde con un documento de API: devuelve el estado completo de
la página de búsqueda de Walmart, alrededor de un megabyte por petición, con los
productos varios niveles por debajo. El mapeo se escribió contra respuestas
reales capturadas, y de esa medición salieron cuatro decisiones.

La respuesta trae un segundo bloque titulado *"Shop trending items"* cuyos
productos no tienen relación con la consulta, así que solo se lee el bloque de
la grilla. La grilla además viene rellenada con celdas sin identificador, nombre
ni imagen, que se descartan en lugar de dibujarse como tarjetas vacías.

El precio se resuelve por una cadena de alternativas porque **el mismo endpoint
responde con dos formas distintas según la página**. En unas, `priceDetails.priceLines`
viene poblado y las cadenas con formato están vacías; en otras esa lista no
existe y el valor solo aparece como texto. Leer una sola de las dos deja la mitad
del catálogo en cero.

El final de los resultados se deduce de que una página vuelva vacía, no de las
señales que trae la respuesta: `hasMorePages` es `false` incluso en la primera
página de catorce, y `maxPage` informa 14 en esa misma página y 1 en la
decimocuarta. Ambas se conservan solo como tope de seguridad.

Las páginas se solapan: una respuesta real repitió 14 de 45 productos de la
página anterior, por lo que los resultados se fusionan por identificador en
lugar de concatenarse.

### Caché de resultados

Medido contra el endpoint real, el primer byte llega entre ocho y diez segundos
después de la petición, con la conexión ya establecida en menos de medio
segundo. Esa espera es del servicio y no se puede reducir desde el cliente, pero
sí se puede evitar repetirla: las páginas de resultados se guardan localmente y
se sirven durante **veinte minutos**. El historial existe justamente para
invitar a repetir una búsqueda, así que ese camino se recorre seguido.

La vigencia forma parte de la consulta y no de una comprobación posterior, de
modo que una fila vencida ni siquiera se lee. Las filas expiradas se eliminan en
cada escritura, así la tabla permanece acotada sin que nada tenga que recordar
limpiarla.

Una página vacía nunca se guarda: es la señal de que los resultados se
terminaron, y conservarla congelaría esa respuesta durante toda la ventana. La
caché es una optimización y se comporta como tal: si no se puede leer, la
petición sale igual; si no se puede escribir, solo se pierde velocidad en la
búsqueda siguiente.

### Favoritos

Se guarda el producto completo, no solo su identificador. El servicio no ofrece
forma de consultar un producto individual, así que un favorito que conservara
únicamente una referencia no podría volver a mostrarse nunca; guardar los campos
además hace que la pantalla de favoritos funcione sin red.

La tabla llegó como una **segunda migración añadida a la lista**, no fusionada
con la primera: esa ya se ejecutó en bases de datos existentes, de modo que
ampliar el esquema significa agregar un paso después. La versión es la longitud
de la lista, así que avanzó sola.

### Pantalla de detalle

No realiza ninguna petición. El ejercicio indica que solo es necesario consultar
ese servicio, y la respuesta de búsqueda ya trae título, precio, imagen y
descripción, así que el producto viaja con la navegación. La pantalla abre de
inmediato y sigue funcionando sin red. Alrededor de uno de cada seis productos
llega sin descripción, y la pantalla lo dice en lugar de mostrar un bloque vacío.

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
│   ├── router/               # constructor del router y constantes de ruta
│   └── theme/                # tokens de color, tipografía y forma
├── modules/
│   ├── auth/                 # registro y acceso locales
│   ├── catalog/              # búsqueda, detalle e historial
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
