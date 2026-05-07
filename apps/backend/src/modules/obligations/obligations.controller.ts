import { Request, Response } from 'express';
import { ObligationsService } from './obligations.service';
import { ApiResponse } from '../../types/api.types';

const obligationsService = new ObligationsService();

export class ObligationsController {
  async getObligations(req: Request, res: Response) {
    try {
      const userId = (req as any).user.id;
      const type = req.query.type as any;
      const obligations = await obligationsService.getObligations(userId, type);
      res.json({ data: obligations });
    } catch (error: any) {
      res.status(500).json({ error: error.message });
    }
  }

  async createObligation(req: Request, res: Response) {
    try {
      const userId = (req as any).user.id;
      const obligation = await obligationsService.createObligation(userId, req.body);
      res.status(201).json({ data: obligation });
    } catch (error: any) {
      res.status(400).json({ error: error.message });
    }
  }

  async updateObligation(req: Request, res: Response) {
    try {
      const { id } = req.params;
      const userId = (req as any).user.id;
      const obligation = await obligationsService.updateObligation(id as string, userId, req.body);
      res.json({ data: obligation });
    } catch (error: any) {
      res.status(400).json({ error: error.message });
    }
  }

  async deleteObligation(req: Request, res: Response) {
    try {
      const { id } = req.params;
      const userId = (req as any).user.id;
      await obligationsService.deleteObligation(id as string, userId);
      res.status(204).send();
    } catch (error: any) {
      res.status(400).json({ error: error.message });
    }
  }

  async getSummary(req: Request, res: Response) {
    try {
      const userId = (req as any).user.id;
      const summary = await obligationsService.getObligationsSummary(userId);
      res.json({ data: summary });
    } catch (error: any) {
      res.status(500).json({ error: error.message });
    }
  }

  async markAsPaid(req: Request, res: Response) {
    try {
      const { id } = req.params;
      const userId = (req as any).user.id;
      const { amount } = req.body;
      const payment = await obligationsService.markAsPaid(id as string, userId, amount);
      res.json({ data: payment });
    } catch (error: any) {
      res.status(400).json({ error: error.message });
    }
  }
}
