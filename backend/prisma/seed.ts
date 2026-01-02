import { PrismaClient } from '@prisma/client';
import * as bcrypt from 'bcryptjs';

const prisma = new PrismaClient();

async function main() {
  const password = 'Test@12345';
  const passwordHash = await bcrypt.hash(password, 10);

  // ===== USER 1: tram1@gmail.com =====
  const u1 = await prisma.user.upsert({
    where: { email: 'tram1@gmail.com' },
    update: {},
    create: {
      username: 'tram1',
      fullName: 'Tram 1',
      email: 'tram1@gmail.com',
      emailVerifiedAt: new Date(),

      authProvider: 'password',
      passwordHash,

      phoneVerifyRequired: false,
      status: 'online',
      avatarUrl: 'https://i.pravatar.cc/300?img=15',
    },
  });

  // ===== USER 2: user test =====
  const u2 = await prisma.user.upsert({
    where: { username: 'user2' },
    update: {},
    create: {
      username: 'user2',
      fullName: 'User Two',
      email: 'user2@test.com',
      emailVerifiedAt: new Date(),

      authProvider: 'password',
      passwordHash,

      phoneVerifyRequired: false,
      status: 'offline',
      avatarUrl: 'https://i.pravatar.cc/300?img=32',
    },
  });

  // ===== CONVERSATION (direct) =====
  const c1 = await prisma.conversation.upsert({
    where: { id: 'seed-conv-1' },
    update: {},
    create: {
      id: 'seed-conv-1',
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
      content: 'Hello từ tram1@gmail.com',
      type: 'text',
    },
  });

  console.log('✅ Seed OK');
  console.log('Login test:');
  console.log('Email:', 'tram1@gmail.com');
  console.log('Password:', password);
}

main()
  .catch(console.error)
  .finally(() => prisma.$disconnect());
