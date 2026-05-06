import { Request, Response, NextFunction } from 'express';
import * as aiCommandsService from './ai-commands.service';
import * as aiCommandsExecutor from './ai-commands.executor';
import { ProcessCommandSchema, ExecuteCommandsSchema } from './ai-commands.schema';

export async function processPrompt(req: Request, res: Response, next: NextFunction) {
  try {
    const { prompt } = ProcessCommandSchema.parse(req.body);
    const userId = (req as any).user.id;

    const response = await aiCommandsService.parseCommand(userId, prompt);

    res.json({
      status: 'success',
      data: response,
    });
  } catch (error) {
    next(error);
  }
}

export async function executeCommands(req: Request, res: Response, next: NextFunction) {
  try {
    const { actions } = ExecuteCommandsSchema.parse(req.body);
    const userId = (req as any).user.id;

    const results = await aiCommandsExecutor.executeBatchActions(userId, actions);

    res.json({
      status: 'success',
      data: {
        executed: results.length,
        results,
      },
    });
  } catch (error) {
    next(error);
  }
}
