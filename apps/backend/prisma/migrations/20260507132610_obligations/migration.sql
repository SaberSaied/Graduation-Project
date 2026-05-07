-- CreateEnum
CREATE TYPE "ObligationStatus" AS ENUM ('PAID', 'UPCOMING', 'OVERDUE', 'PAUSED');

-- CreateEnum
CREATE TYPE "ObligationType" AS ENUM ('SUBSCRIPTION', 'BILL', 'DEBT', 'LOAN', 'INSTALLMENT');

-- CreateEnum
CREATE TYPE "ReminderType" AS ENUM ('PUSH', 'IN_APP', 'DASHBOARD');

-- CreateEnum
CREATE TYPE "PaymentStatus" AS ENUM ('COMPLETED', 'PENDING', 'FAILED');

-- CreateTable
CREATE TABLE "financial_obligations" (
    "id" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "categoryId" TEXT,
    "title" TEXT NOT NULL,
    "description" TEXT,
    "amount" DOUBLE PRECISION NOT NULL,
    "currency" TEXT NOT NULL,
    "type" "ObligationType" NOT NULL,
    "status" "ObligationStatus" NOT NULL DEFAULT 'UPCOMING',
    "dueDate" TIMESTAMP(3),
    "isRecurring" BOOLEAN NOT NULL DEFAULT false,
    "recurringType" "RecurringType",
    "startDate" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "endDate" TIMESTAMP(3),
    "autoRenew" BOOLEAN DEFAULT true,
    "totalAmount" DOUBLE PRECISION,
    "remainingAmount" DOUBLE PRECISION,
    "interestRate" DOUBLE PRECISION,
    "lenderInfo" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "financial_obligations_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "bill_reminders" (
    "id" TEXT NOT NULL,
    "obligationId" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "reminderDate" TIMESTAMP(3) NOT NULL,
    "isSent" BOOLEAN NOT NULL DEFAULT false,
    "type" "ReminderType" NOT NULL DEFAULT 'IN_APP',

    CONSTRAINT "bill_reminders_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "obligation_payments" (
    "id" TEXT NOT NULL,
    "obligationId" TEXT NOT NULL,
    "transactionId" TEXT,
    "amount" DOUBLE PRECISION NOT NULL,
    "paymentDate" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "status" "PaymentStatus" NOT NULL DEFAULT 'COMPLETED',

    CONSTRAINT "obligation_payments_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "obligation_payments_transactionId_key" ON "obligation_payments"("transactionId");

-- AddForeignKey
ALTER TABLE "financial_obligations" ADD CONSTRAINT "financial_obligations_userId_fkey" FOREIGN KEY ("userId") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "financial_obligations" ADD CONSTRAINT "financial_obligations_categoryId_fkey" FOREIGN KEY ("categoryId") REFERENCES "categories"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "bill_reminders" ADD CONSTRAINT "bill_reminders_obligationId_fkey" FOREIGN KEY ("obligationId") REFERENCES "financial_obligations"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "bill_reminders" ADD CONSTRAINT "bill_reminders_userId_fkey" FOREIGN KEY ("userId") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "obligation_payments" ADD CONSTRAINT "obligation_payments_obligationId_fkey" FOREIGN KEY ("obligationId") REFERENCES "financial_obligations"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "obligation_payments" ADD CONSTRAINT "obligation_payments_transactionId_fkey" FOREIGN KEY ("transactionId") REFERENCES "transactions"("id") ON DELETE SET NULL ON UPDATE CASCADE;
