/*
  Warnings:

  - The values [lead,contacted,won,lost] on the enum `DealStage` will be removed. If these variants are still used in the database, this will fail.
  - The values [debt,investment,emergency,custom] on the enum `GoalType` will be removed. If these variants are still used in the database, this will fail.
  - The values [none] on the enum `RecurrenceType` will be removed. If these variants are still used in the database, this will fail.
  - The values [payment,meeting,deadline] on the enum `ReminderType` will be removed. If these variants are still used in the database, this will fail.
  - You are about to drop the column `account_mode` on the `contacts` table. All the data in the column will be lost.
  - You are about to drop the column `role` on the `contacts` table. All the data in the column will be lost.
  - You are about to drop the column `account_mode` on the `goals` table. All the data in the column will be lost.
  - You are about to drop the column `deadline` on the `goals` table. All the data in the column will be lost.
  - You are about to drop the column `contact_id` on the `reminders` table. All the data in the column will be lost.
  - You are about to drop the column `date` on the `reminders` table. All the data in the column will be lost.
  - You are about to drop the column `description` on the `reminders` table. All the data in the column will be lost.
  - You are about to drop the column `priority` on the `reminders` table. All the data in the column will be lost.
  - Added the required column `end_date` to the `goals` table without a default value. This is not possible if the table is not empty.
  - Added the required column `start_date` to the `goals` table without a default value. This is not possible if the table is not empty.
  - Added the required column `due_date` to the `reminders` table without a default value. This is not possible if the table is not empty.

*/
-- CreateEnum
CREATE TYPE "ContactType" AS ENUM ('lead', 'client');

-- CreateEnum
CREATE TYPE "ContactStatus" AS ENUM ('newLead', 'contacted', 'qualified', 'proposal', 'negotiation', 'won', 'lost', 'churned');

-- CreateEnum
CREATE TYPE "ContactSource" AS ENUM ('website', 'referral', 'social', 'cold', 'event', 'other');

-- AlterEnum
BEGIN;
CREATE TYPE "DealStage_new" AS ENUM ('discovery', 'qualification', 'proposal', 'negotiation', 'closedWon', 'closedLost');
ALTER TABLE "public"."deals" ALTER COLUMN "stage" DROP DEFAULT;
ALTER TABLE "deals" ALTER COLUMN "stage" TYPE "DealStage_new" USING ("stage"::text::"DealStage_new");
ALTER TYPE "DealStage" RENAME TO "DealStage_old";
ALTER TYPE "DealStage_new" RENAME TO "DealStage";
DROP TYPE "public"."DealStage_old";
ALTER TABLE "deals" ALTER COLUMN "stage" SET DEFAULT 'discovery';
COMMIT;

-- AlterEnum
BEGIN;
CREATE TYPE "GoalType_new" AS ENUM ('income', 'expense', 'savings', 'revenue', 'profit');
ALTER TABLE "goals" ALTER COLUMN "type" TYPE "GoalType_new" USING ("type"::text::"GoalType_new");
ALTER TYPE "GoalType" RENAME TO "GoalType_old";
ALTER TYPE "GoalType_new" RENAME TO "GoalType";
DROP TYPE "public"."GoalType_old";
COMMIT;

-- AlterEnum
BEGIN;
CREATE TYPE "RecurrenceType_new" AS ENUM ('once', 'daily', 'weekly', 'monthly', 'yearly');
ALTER TABLE "public"."transactions" ALTER COLUMN "recurrence" DROP DEFAULT;
ALTER TABLE "transactions" ALTER COLUMN "recurrence" TYPE "RecurrenceType_new" USING ("recurrence"::text::"RecurrenceType_new");
ALTER TYPE "RecurrenceType" RENAME TO "RecurrenceType_old";
ALTER TYPE "RecurrenceType_new" RENAME TO "RecurrenceType";
DROP TYPE "public"."RecurrenceType_old";
ALTER TABLE "transactions" ALTER COLUMN "recurrence" SET DEFAULT 'once';
COMMIT;

-- AlterEnum
BEGIN;
CREATE TYPE "ReminderType_new" AS ENUM ('invoiceDue', 'followUp', 'subscriptionRenewal', 'goalDeadline', 'custom');
ALTER TABLE "reminders" ALTER COLUMN "type" TYPE "ReminderType_new" USING ("type"::text::"ReminderType_new");
ALTER TYPE "ReminderType" RENAME TO "ReminderType_old";
ALTER TYPE "ReminderType_new" RENAME TO "ReminderType";
DROP TYPE "public"."ReminderType_old";
COMMIT;

-- DropForeignKey
ALTER TABLE "reminders" DROP CONSTRAINT "reminders_contact_id_fkey";

-- DropIndex
DROP INDEX "contacts_user_id_account_mode_idx";

-- DropIndex
DROP INDEX "reminders_user_id_date_idx";

-- AlterTable
ALTER TABLE "contacts" DROP COLUMN "account_mode",
DROP COLUMN "role",
ADD COLUMN     "last_contacted_at" TIMESTAMP(3),
ADD COLUMN     "source" "ContactSource" NOT NULL DEFAULT 'other',
ADD COLUMN     "status" "ContactStatus" NOT NULL DEFAULT 'newLead',
ADD COLUMN     "tags" TEXT[] DEFAULT ARRAY[]::TEXT[],
ADD COLUMN     "total_revenue" DOUBLE PRECISION NOT NULL DEFAULT 0,
ADD COLUMN     "type" "ContactType" NOT NULL DEFAULT 'lead';

-- AlterTable
ALTER TABLE "deals" ADD COLUMN     "contact_name" TEXT NOT NULL DEFAULT '',
ALTER COLUMN "stage" SET DEFAULT 'discovery',
ALTER COLUMN "probability" SET DEFAULT 10;

-- AlterTable
ALTER TABLE "goals" DROP COLUMN "account_mode",
DROP COLUMN "deadline",
ADD COLUMN     "end_date" TIMESTAMP(3) NOT NULL,
ADD COLUMN     "start_date" TIMESTAMP(3) NOT NULL;

-- AlterTable
ALTER TABLE "reminders" DROP COLUMN "contact_id",
DROP COLUMN "date",
DROP COLUMN "description",
DROP COLUMN "priority",
ADD COLUMN     "due_date" TIMESTAMP(3) NOT NULL,
ADD COLUMN     "linked_id" TEXT,
ADD COLUMN     "subtitle" TEXT;

-- AlterTable
ALTER TABLE "transactions" ADD COLUMN     "is_paid" BOOLEAN NOT NULL DEFAULT true,
ALTER COLUMN "recurrence" SET DEFAULT 'once';

-- DropEnum
DROP TYPE "ReminderPriority";

-- CreateIndex
CREATE INDEX "contacts_user_id_idx" ON "contacts"("user_id");

-- CreateIndex
CREATE INDEX "reminders_user_id_due_date_idx" ON "reminders"("user_id", "due_date");
