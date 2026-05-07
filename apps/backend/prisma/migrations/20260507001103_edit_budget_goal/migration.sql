/*
  Warnings:

  - You are about to drop the column `month` on the `budgets` table. All the data in the column will be lost.
  - You are about to drop the column `year` on the `budgets` table. All the data in the column will be lost.
  - A unique constraint covering the columns `[userId,categoryId,period,startDate,endDate]` on the table `budgets` will be added. If there are existing duplicate values, this will fail.
  - A unique constraint covering the columns `[transactionId]` on the table `goal_contributions` will be added. If there are existing duplicate values, this will fail.

*/
-- CreateEnum
CREATE TYPE "BudgetPeriod" AS ENUM ('WEEKLY', 'MONTHLY', 'CUSTOM');

-- CreateEnum
CREATE TYPE "AutoSaveFrequency" AS ENUM ('DAILY', 'WEEKLY', 'MONTHLY');

-- DropIndex
DROP INDEX "budgets_userId_categoryId_month_year_key";

-- AlterTable
ALTER TABLE "budgets" DROP COLUMN "month",
DROP COLUMN "year",
ADD COLUMN     "alertThreshold" DOUBLE PRECISION NOT NULL DEFAULT 0.8,
ADD COLUMN     "endDate" TIMESTAMP(3),
ADD COLUMN     "period" "BudgetPeriod" NOT NULL DEFAULT 'MONTHLY',
ADD COLUMN     "startDate" TIMESTAMP(3);

-- AlterTable
ALTER TABLE "goal_contributions" ADD COLUMN     "transactionId" TEXT;

-- AlterTable
ALTER TABLE "goals" ADD COLUMN     "autoSaveAmount" DOUBLE PRECISION,
ADD COLUMN     "autoSaveFrequency" "AutoSaveFrequency",
ADD COLUMN     "autoSavePercentage" DOUBLE PRECISION;

-- CreateIndex
CREATE UNIQUE INDEX "budgets_userId_categoryId_period_startDate_endDate_key" ON "budgets"("userId", "categoryId", "period", "startDate", "endDate");

-- CreateIndex
CREATE UNIQUE INDEX "goal_contributions_transactionId_key" ON "goal_contributions"("transactionId");

-- AddForeignKey
ALTER TABLE "goal_contributions" ADD CONSTRAINT "goal_contributions_transactionId_fkey" FOREIGN KEY ("transactionId") REFERENCES "transactions"("id") ON DELETE SET NULL ON UPDATE CASCADE;
