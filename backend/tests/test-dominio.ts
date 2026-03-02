import { ListarVehiculos } from "../aplicacion/casosUso/ListarVehiculos";
import { IVehiculoRepositorio } from "../dominio/Repositorios/IVehiculoRepositorio";
import { Vehiculo } from "../dominio/Entidades/Vehiculo";
import { EstadoVehiculo } from "../dominio/emuns/EstadoVehiculo";

// 1. Creamos un "Simulador" de base de datos (Mock)
class VehiculoRepositorioMock implements Partial<IVehiculoRepositorio> {
    async obtenerTodos(): Promise<Vehiculo[]> {
        return [
            new Vehiculo(1, "Toyota", "ABC-123", "Hilux", 5, 1000, EstadoVehiculo.DISPONIBLE, 2022),
            new Vehiculo(2, "Volvo", "XYZ-789", "FH16", 20, 5000, EstadoVehiculo.EN_MANTENIMIENTO, 2021)
        ];
    }
}

// 2. Función de prueba
async function probarDominio() {
    console.log("🧪 Iniciando prueba de dominio...");

    const repoMock = new VehiculoRepositorioMock() as IVehiculoRepositorio;
    const casoUso = new ListarVehiculos(repoMock);

    try {
        const vehiculos = await casoUso.ejecutar();

        console.log(`✅ Éxito: Se recuperaron ${vehiculos.length} vehículos.`);

        vehiculos.forEach(v => {
            console.log(`   - [${v.getPlaca()}] ${v.getMarca()} ${v.getModelo()} (Estado: ${v.getEstado()})`);
        });

    } catch (error) {
        console.error("❌ La prueba falló:", error);
    }
}

probarDominio();