


 class PuntoGeo {
    private id : number;
    private latitud : number ;
    private longitud : number ;
    private orden : number ;
    private descripcion : string ;
    constructor(id : number, latitud : number, longitud : number, orden : number, descripcion : string){
        this.id = id;
        this.latitud = latitud;
        this.longitud = longitud;
        this.orden = orden;
        this.descripcion = descripcion;
    }
    calcularDistancia(otroPunto : PuntoGeo) : number {
        //falta completar
        return 0;
    } 
}