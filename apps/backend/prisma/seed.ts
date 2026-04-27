import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

const defaultCategories = [
  // EXPENSE categories
  { name: 'Food & Dining', icon: '🍔', color: '#FF6B6B', type: 'EXPENSE' as const, isDefault: true },
  { name: 'Transportation', icon: '🚗', color: '#4ECDC4', type: 'EXPENSE' as const, isDefault: true },
  { name: 'Shopping', icon: '🛍️', color: '#FFE66D', type: 'EXPENSE' as const, isDefault: true },
  { name: 'Entertainment', icon: '🎬', color: '#A855F7', type: 'EXPENSE' as const, isDefault: true },
  { name: 'Bills & Utilities', icon: '💡', color: '#F97316', type: 'EXPENSE' as const, isDefault: true },
  { name: 'Health & Medical', icon: '🏥', color: '#EF4444', type: 'EXPENSE' as const, isDefault: true },
  { name: 'Education', icon: '📚', color: '#3B82F6', type: 'EXPENSE' as const, isDefault: true },
  { name: 'Housing & Rent', icon: '🏠', color: '#8B5CF6', type: 'EXPENSE' as const, isDefault: true },
  { name: 'Insurance', icon: '🛡️', color: '#06B6D4', type: 'EXPENSE' as const, isDefault: true },
  { name: 'Personal Care', icon: '💅', color: '#EC4899', type: 'EXPENSE' as const, isDefault: true },
  { name: 'Gifts & Donations', icon: '🎁', color: '#F43F5E', type: 'EXPENSE' as const, isDefault: true },
  { name: 'Subscriptions', icon: '📱', color: '#6366F1', type: 'EXPENSE' as const, isDefault: true },
  { name: 'Travel', icon: '✈️', color: '#14B8A6', type: 'EXPENSE' as const, isDefault: true },
  { name: 'Other Expense', icon: '📦', color: '#6B7280', type: 'EXPENSE' as const, isDefault: true },

  // INCOME categories
  { name: 'Salary', icon: '💰', color: '#00C896', type: 'INCOME' as const, isDefault: true },
  { name: 'Freelance', icon: '💻', color: '#10B981', type: 'INCOME' as const, isDefault: true },
  { name: 'Investments', icon: '📈', color: '#059669', type: 'INCOME' as const, isDefault: true },
  { name: 'Business', icon: '🏢', color: '#047857', type: 'INCOME' as const, isDefault: true },
  { name: 'Rental Income', icon: '🏘️', color: '#34D399', type: 'INCOME' as const, isDefault: true },
  { name: 'Side Hustle', icon: '🔧', color: '#6EE7B7', type: 'INCOME' as const, isDefault: true },
  { name: 'Gifts Received', icon: '🎉', color: '#A7F3D0', type: 'INCOME' as const, isDefault: true },
  { name: 'Other Income', icon: '💵', color: '#D1FAE5', type: 'INCOME' as const, isDefault: true },
];

async function main() {
  console.log('🌱 Seeding default categories...');

  for (const category of defaultCategories) {
    await prisma.category.upsert({
      where: {
        id: `default-${category.name.toLowerCase().replace(/[^a-z0-9]/g, '-')}`,
      },
      update: {},
      create: {
        id: `default-${category.name.toLowerCase().replace(/[^a-z0-9]/g, '-')}`,
        ...category,
      },
    });
  }

  console.log(`✅ Seeded ${defaultCategories.length} default categories`);
}

main()
  .catch((e) => {
    console.error('❌ Seed error:', e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
