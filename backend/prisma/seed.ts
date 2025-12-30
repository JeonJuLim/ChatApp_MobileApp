import { PrismaClient } from '@prisma/client';
const prisma = new PrismaClient();

async function main() {
  // ===== USERS =====
  const u1 = await prisma.user.upsert({
    where: { id: 'u1' },
    update: {},
    create: {
      id: 'u1',
      username: 'u1',
      fullName: 'User One',
      authProvider: 'phone',
    },
  });

  const u2 = await prisma.user.upsert({
    where: { id: 'u2' },
    update: {},
    create: {
      id: 'u2',
      username: 'u2',
      fullName: 'User Two',
      authProvider: 'phone',
    },
  });

  // ===== CONVERSATION =====
  const c1 = await prisma.conversation.upsert({
    where: { id: 'c1' },
    update: {},
    create: {
      id: 'c1',
      type: 'direct',
      createdBy: u1.id,
      members: {
        create: [
          { userId: u1.id, role: 'member' },
          { userId: u2.id, role: 'member' },
        ],
      },
    },
  });

  // ===== MESSAGE =====
  await prisma.message.create({
    data: {
      conversationId: c1.id,
      senderId: u1.id,
      content: 'Hello từ u1',
      type: 'text',
    },
  });

  console.log('✅ Seed OK');
}

main()
  .catch(console.error)
  .finally(() => prisma.$disconnect());
