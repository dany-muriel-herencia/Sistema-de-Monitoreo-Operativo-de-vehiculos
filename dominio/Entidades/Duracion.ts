
export class Duracion{
    private horas : number;
    private minutos : number;
    constructor(horas : number, minutos : number){

        this.horas = horas;
        this.minutos = minutos;
        
        if(horas < 0 || minutos < 0 || minutos >= 60){
        this.horas = horas;
        this.minutos = minutos;
        }else{
            //base de datos con los datos aproximados de la duracion de cada ruta

        }
    }
}

