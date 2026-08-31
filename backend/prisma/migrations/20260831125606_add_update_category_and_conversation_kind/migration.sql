-- CreateEnum
CREATE TYPE "UpdateCategory" AS ENUM ('general', 'market_insight', 'content');

-- CreateEnum
CREATE TYPE "ConversationKind" AS ENUM ('listing', 'consultation', 'investor_inquiry');

-- AlterTable
ALTER TABLE "conversations" ADD COLUMN     "kind" "ConversationKind" NOT NULL DEFAULT 'listing',
ALTER COLUMN "listingId" DROP NOT NULL;

-- AlterTable
ALTER TABLE "updates" ADD COLUMN     "category" "UpdateCategory" NOT NULL DEFAULT 'general',
ADD COLUMN     "externalVideoUrl" TEXT;

-- CreateIndex
CREATE INDEX "updates_category_idx" ON "updates"("category");
