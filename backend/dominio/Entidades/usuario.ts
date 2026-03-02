export class usuario {
    public id: string;
    public nombre: string;
    public email: string;
    public contraseña: string;
    public rol: string;

    constructor(id: string, nombre: string, email: string, contraseña: string, rol: string = 'conductor') {
        this.id = id;
        this.nombre = nombre;
        this.email = email;
        this.contraseña = contraseña;
        this.rol = rol;
    }

    login(email: string, contrasena: string): boolean {
        // Normalizamos el email para evitar errores por mayúsculas o espacios
        return this.email.toLowerCase().trim() === email.toLowerCase().trim() &&
            this.contraseña === contrasena;
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
    getContraseña(): string { return this.contraseña; }
    getRol(): string { return this.rol; }
}

