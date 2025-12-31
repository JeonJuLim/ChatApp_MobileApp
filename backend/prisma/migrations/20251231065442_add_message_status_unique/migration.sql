/*
  Warnings:

  - A unique constraint covering the columns `[messageId,userId]` on the table `MessageStatus` will be added. If there are existing duplicate values, this will fail.

*/
-- CreateIndex
CREATE UNIQUE INDEX "MessageStatus_messageId_userId_key" ON "MessageStatus"("messageId", "userId");
