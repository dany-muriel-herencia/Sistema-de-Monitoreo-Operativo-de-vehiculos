export class usuario{
    private id : number;
    private nombre : string;
    private email : string;
    private contraseña : string;

    constructor(id : number, nombre : string, email : string, contraseña : string){
        this.id = id;
        this.nombre = nombre;
        this.email = email;
        this.contraseña = contraseña;
    } 
    login (email:string ,contrasena:string): boolean{
        if(this.email === email && this.contraseña === contrasena){
            return true;
        }        
        return false;
    }
    recuperarContraseña (email:string ,contrasena:string): void{
        ////falta copmpletar 
    }

}
