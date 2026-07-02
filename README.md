# d87-garage

Un script de garajes avanzado, optimizado y moderno para servidores FiveM. 
Diseñado desde cero para soportar múltiples frameworks de manera nativa y ofrecer una experiencia de usuario (UX) inmersiva y sin conflictos mediante un sistema de zonas separadas.

## ✨ Características Principales

* **Compatibilidad Multi-Framework**: Soporta `QBCore`, `Qbox (qbx)`, `ESX Legacy` y `Standalone` de forma nativa mediante un sistema de *bridge* automático. No tienes que cambiar nada, el script detecta tu base.
* **Arquitectura de 3 Zonas**: A diferencia de otros scripts donde todo ocurre en un mismo círculo, `d87-garage` separa cada garaje en 3 coordenadas distintas para evitar conflictos:
  1. `Menú` (Solo a pie): Para abrir la interfaz e interactuar.
  2. `Entrada` (En vehículo): Punto físico donde conduces el coche para guardarlo.
  3. `Salida` (Spawn): Punto físico donde el vehículo aparece al sacarlo.
* **Interfaz NUI Moderna**: Diseño espectacular estilo *Glassmorphism* (cristal translúcido), animaciones suaves, barras de progreso de daños y gasolina, e insignias de estado dinámicas.
* **Buscador en Tiempo Real**: Encuentra vehículos rápidamente por placa o nombre directamente desde la interfaz.
* **Depósitos e Impound**: Sistema de incautación integrado. Configura garajes especiales tipo `depot` donde los jugadores deben pagar (una tarifa base o un % del valor del vehículo) para recuperar coches perdidos o incautados.
* **Soporte para Trabajos y Bandas**: Crea garajes exclusivos para la policía, mecánicos, mafias, etc., fácilmente desde la configuración.
* **Alta Optimización**: Uso de `lib.points` de *ox_lib* para la creación de zonas, asegurando un impacto nulo (0.00ms) en el rendimiento del cliente.
* **Todo en un Solo Config**: Un archivo `config.lua` limpio y unificado donde puedes modificar absolutamente todo (blips, marcadores, precios, NUI, colores, teclas).

## 📦 Dependencias Obligatorias

Asegúrate de tener instalados e iniciados estos recursos antes que `d87-garage`:
* `ox_lib` (Obligatorio para zonas, callbacks y UI fallback)
* `oxmysql` (Obligatorio para guardar/cargar vehículos en la base de datos)

## 🛠️ Instalación

1. Descarga los archivos y colócalos en tu carpeta `resources`, dentro de `[scripts]` o `[d87]`.
2. Renombra la carpeta a `d87-garage` (asegúrate de que no tenga mayúsculas).
3. Abre el archivo `config/config.lua` y configura las opciones a tu gusto (Framework, tecla de interacción, precios, garajes, color de la interfaz, etc.).
4. Añade `ensure d87-garage` a tu `server.cfg` (asegúrate de que esté debajo de `ox_lib` y `oxmysql`).

### Notas de Base de Datos
Por defecto, el script asume que usas la tabla `player_vehicles` (estándar en QBCore/QBX) o `owned_vehicles` (ESX). Si los nombres de tus columnas son diferentes (por ejemplo, tu columna de placa se llama `plate` en vez de `plate`), puedes mapearlos fácilmente en la sección `Config.database` dentro de `config.lua`.

## ⚙️ Configuración de un Garaje (Ejemplo)

```lua
mis_garajes = {
    playa = {
        label       = 'Garaje de la Playa',
        type        = GarageType.PUBLIC,     -- Tipos: PUBLIC, DEPOT, JOB, GANG, PRIVATE
        vehicleType = VehicleType.CAR,       -- Tipos: CAR, AIR, SEA, ALL
        blip        = { name = 'Parking Playa', sprite = 357, color = 3 },
        -- Coordenadas separadas:
        menu        = vec4(-1184.21, -1509.65, 4.65, 303.72), -- Donde interactúas
        entry       = vec4(-1184.4, -1501.88, 4.39, 214.7),   -- Donde aparcas
        exit        = vec4(-1180.0, -1505.0, 4.39, 214.7),    -- Dónde sale
    }
}
```

## 🎨 Personalización de la Interfaz

Puedes cambiar el color principal de la interfaz muy fácilmente desde `config.lua`:
```lua
ui = {
    theme          = 'dark',    
    accentColor    = '#00d4ff', -- Cambia este HEX para adaptar la NUI al color de tu servidor
}
```

## 📝 Licencia / Autor
*   **Autor Oficial:** `Drako87/Dracatt`. Basado en ideas de estructura de QBX pero reescrito desde cero con interfaz propia y soporte universal.
