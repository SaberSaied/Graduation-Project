import { Router } from 'express';
import { requireAuth } from '../../middleware/auth.middleware';
import { getCategories, createCategory, updateCategory, deleteCategory } from './categories.controller';

export const categoriesRouter: Router = Router();

categoriesRouter.use(requireAuth);

categoriesRouter.get('/', getCategories);
categoriesRouter.post('/', createCategory);
categoriesRouter.patch('/:id', updateCategory);
categoriesRouter.delete('/:id', deleteCategory);
