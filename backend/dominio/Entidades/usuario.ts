export class usuario {
    private id: string;
    private nombre: string;
    private email: string;
    private contraseña: string;

    constructor(id: string, nombre: string, email: string, contraseña: string) {
        this.id = id;
        this.nombre = nombre;
        this.email = email;
        this.contraseña = contraseña;
    }

    login(email: string, contrasena: string): boolean {
        return this.email === email && this.contraseña === contrasena;
    }

    recuperarContraseña(email: string, nuevaContrasena: string): void {
        if (this.email !== email) {
            throw new Error("Email no coincide con el usuario");
        }
        this.contraseña = nuevaContrasena;
    }


    getId(): string { return this.id; }
    getNombre(): string { return this.nombre; }
    getEmail(): string { return this.email; }
}

