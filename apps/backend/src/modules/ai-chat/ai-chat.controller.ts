import { Request, Response, NextFunction } from 'express';
import * as aiChatService from './ai-chat.service';

export async function sendMessage(req: Request, res: Response, next: NextFunction) {
  try {
    const { message, sessionId } = req.body;
    const file = req.file;
    console.log(message, sessionId, file);
    const result = await aiChatService.processMessage(req.user!.id, message, sessionId, file);
    res.json({ data: result });
  } catch (error) {
    next(error);
  }
}

export async function getSessions(req: Request, res: Response, next: NextFunction) {
  try {
    const sessions = await aiChatService.getChatSessions(req.user!.id);
    res.json({ data: sessions });
  } catch (error) {
    next(error);
  }
}

export async function getSession(req: Request, res: Response, next: NextFunction) {
  try {
    const id = req.params.id as string;
    const session = await aiChatService.getChatSession(id, req.user!.id);
    res.json({ data: session });
  } catch (error) {
    next(error);
  }
}

export async function deleteSession(req: Request, res: Response, next: NextFunction) {
  try {
    const id = req.params.id as string;
    await aiChatService.deleteChatSession(id, req.user!.id);
    res.json({ message: 'Chat session deleted successfully' });
  } catch (error) {
    next(error);
  }
}

export async function simulateTransaction(req: Request, res: Response, next: NextFunction) {
  try {
    const result = await aiChatService.simulateTransactionImpact(req.user!.id, req.body);
    res.json({ data: result });
  } catch (error) {
    next(error);
  }
}
