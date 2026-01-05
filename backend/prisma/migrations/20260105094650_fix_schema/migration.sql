-- CreateIndex
CREATE INDEX "CallLog_callerId_idx" ON "CallLog"("callerId");

-- CreateIndex
CREATE INDEX "CallLog_receiverId_idx" ON "CallLog"("receiverId");

-- CreateIndex
CREATE INDEX "CallLog_conversationId_idx" ON "CallLog"("conversationId");
