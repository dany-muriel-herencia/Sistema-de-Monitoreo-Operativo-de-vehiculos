export class Duracion {
    private horas: number;
    private minutos: number;

    constructor(horas: number, minutos: number) {
        if (horas < 0 || minutos < 0 || minutos >= 60) {
            throw new Error("Duración inválida: horas >= 0 y 0 <= minutos < 60");
        }
        this.horas = horas;
        this.minutos = minutos;
    }

    /** Duración total en minutos (útil para comparar y calcular) */
    enMinutos(): number {
        return this.horas * 60 + this.minutos;
    }

    /** Representación legible: "1h 30min" */
    toString(): string {
        if (this.horas === 0) return `${this.minutos} min`;
        if (this.minutos === 0) return `${this.horas} h`;
        return `${this.horas} h ${this.minutos} min`;
    }

    // ── Getters ─────────────────────────────────────────────────
    getHoras(): number { return this.horas; }
    getMinutos(): number { return this.minutos; }
}
