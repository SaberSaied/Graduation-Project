import { Request, Response, NextFunction } from 'express';
import * as categoriesService from './categories.service';

export async function getCategories(req: Request, res: Response, next: NextFunction) {
  try {
    const categories = await categoriesService.getCategories(req.user!.id);
    res.json({ data: categories });
  } catch (error) {
    next(error);
  }
}

export async function createCategory(req: Request, res: Response, next: NextFunction) {
  try {
    const category = await categoriesService.createCategory(req.user!.id, req.body);
    res.status(201).json({ data: category, message: 'Category created successfully' });
  } catch (error) {
    next(error);
  }
}

export async function updateCategory(req: Request, res: Response, next: NextFunction) {
  try {
    const id = req.params.id as string;
    const category = await categoriesService.updateCategory(id, req.user!.id, req.body);
    res.json({ data: category, message: 'Category updated successfully' });
  } catch (error) {
    next(error);
  }
}

export async function deleteCategory(req: Request, res: Response, next: NextFunction) {
  try {
    const id = req.params.id as string;
    await categoriesService.deleteCategory(id, req.user!.id);
    res.json({ message: 'Category deleted successfully' });
  } catch (error) {
    next(error);
  }
}
