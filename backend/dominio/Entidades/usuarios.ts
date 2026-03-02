export class Usuario {
    protected id: number | null;
    protected nombre: string;
    protected email: string;
    protected contrasena: string;
    protected rol: string;

    constructor(id: number | null, nombre: string, email: string, contrasena: string, rol: string = 'usuario') {
        this.id = id;
        this.nombre = nombre;
        this.email = email;
        this.contrasena = contrasena;
        this.rol = rol;
    }

    login(email: string, password: string): boolean {
        return this.email === email && this.contrasena === password;
    }

    recuperarContraseña(email: string, nuevaContrasena: string): void {
        if (this.email !== email) {
            throw new Error("Email no coincide con el usuario");
        }
        this.contrasena = nuevaContrasena;
    }

    getId(): number | null { return this.id; }
    getNombre(): string { return this.nombre; }
    getEmail(): string { return this.email; }
    getContrasena(): string { return this.contrasena; }
    getRol(): string { return this.rol; }
}
