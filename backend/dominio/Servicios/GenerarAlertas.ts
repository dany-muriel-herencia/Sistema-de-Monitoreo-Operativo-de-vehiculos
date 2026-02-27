import { TipoAlerta } from "../emuns/TipoAlerta";
import { AlertaRuta } from "../Entidades/AlertaRuta";


export class GenerarAlertas {


    crearAlerta(tipo: TipoAlerta, descripcion: string): AlertaRuta {
        const id = Math.random().toString(36).substr(2, 9);

        const ahora = new Date();

        const resuelto = false;

        if (descripcion.length < 5) {
            throw new Error("La descripción de la alerta debe ser más detallada.");
        }

        return new AlertaRuta(
            id,
            tipo,
            descripcion,
            ahora,
            resuelto
        );
    }


    esAlertaCritica(alerta: AlertaRuta): boolean {
        return alerta.getTipo() === TipoAlerta.EMERGENCIA ||
               alerta.getTipo() === TipoAlerta.FALLA_MECANICA;
    }
}
