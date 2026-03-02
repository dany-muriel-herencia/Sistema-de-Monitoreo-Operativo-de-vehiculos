import { IRutaRepositorio } from "../../dominio/Repositorios/IRutaRepositorio";
import { Ruta } from "../../dominio/Entidades/Ruta";
import { PuntoGeo } from "../../dominio/Entidades/PuntoGeo";
import { Duracion } from "../../dominio/Entidades/Duracion";

export class CrearRuta {
    constructor(private rutaRepo: IRutaRepositorio) { }

    async ejecutar(req: {
        nombre: string,
        distanciaTotal: number,
        duracionEstimadaMinutos: number,
        puntos: { lat: number, lng: number, orden: number }[]
    }) {
        const puntos = req.puntos.map(p => new PuntoGeo(
            "", // El ID lo asigna la base de datos
            p.lat,
            p.lng,
            p.orden,
            ""
        ));

        const duracion = new Duracion(
            Math.floor(req.duracionEstimadaMinutos / 60),
            req.duracionEstimadaMinutos % 60
        );


        const nuevaRuta = new Ruta(
            "", // El ID lo asigna la base de datos
            req.nombre,
            req.distanciaTotal,
            duracion,
            puntos
        );

        await this.rutaRepo.guardar(nuevaRuta);
    }
}
