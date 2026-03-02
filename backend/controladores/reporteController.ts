import { Request, Response } from 'express';
import { ObtenerReportes } from '../aplicacion/casosUso/ObtenerReportes';

export class ReporteController {
    constructor(private obtenerReportesUC: ObtenerReportes) { }

    async obtenerResumen(req: Request, res: Response) {
        try {
            const data = await this.obtenerReportesUC.resumenGeneral();
            res.status(200).json(data);
        } catch (error: any) {
            res.status(500).json({ error: error.message });
        }
    }

    async exportar(req: Request, res: Response) {
        try {
            const csv = await this.obtenerReportesUC.exportarCSV();
            res.header('Content-Type', 'text/csv');
            res.attachment('reporte_viajes.csv');
            res.send(csv);
        } catch (error: any) {
            res.status(500).json({ error: error.message });
        }
    }
}
