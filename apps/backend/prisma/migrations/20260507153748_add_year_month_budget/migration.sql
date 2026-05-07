/*
  Warnings:

  - A unique constraint covering the columns `[userId,categoryId,month,year]` on the table `budgets` will be added. If there are existing duplicate values, this will fail.

*/
-- DropIndex
DROP INDEX "budgets_userId_categoryId_period_startDate_endDate_key";

-- AlterTable
ALTER TABLE "budgets" ADD COLUMN     "month" INTEGER,
ADD COLUMN     "year" INTEGER;

-- CreateIndex
CREATE UNIQUE INDEX "budgets_userId_categoryId_month_year_key" ON "budgets"("userId", "categoryId", "month", "year");
