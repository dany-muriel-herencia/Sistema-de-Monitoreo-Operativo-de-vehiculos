export class PuntoGeo {
    private id: string;
    private latitud: number;
    private longitud: number;
    private orden: number;
    private descripcion: string;

    constructor(id: string, latitud: number, longitud: number, orden: number, descripcion: string) {
        this.id = id;
        this.latitud = latitud;
        this.longitud = longitud;
        this.orden = orden;
        this.descripcion = descripcion;
    }


    calcularDistancia(otroPunto: PuntoGeo): number {
        const R = 6371000; 
        const lat1 = this.latitud * Math.PI / 180;
        const lat2 = otroPunto.latitud * Math.PI / 180;
        const dLat = (otroPunto.latitud - this.latitud) * Math.PI / 180;
        const dLon = (otroPunto.longitud - this.longitud) * Math.PI / 180;

        const a = Math.sin(dLat / 2) * Math.sin(dLat / 2)
            + Math.cos(lat1) * Math.cos(lat2)
            * Math.sin(dLon / 2) * Math.sin(dLon / 2);

        const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
        return R * c; 
    }

    getId(): string { return this.id; }
    getLatitud(): number { return this.latitud; }
    getLongitud(): number { return this.longitud; }
    getOrden(): number { return this.orden; }
    getDescripcion(): string { return this.descripcion; }
}