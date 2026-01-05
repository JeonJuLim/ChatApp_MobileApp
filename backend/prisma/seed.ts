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
      status: 'online',
      avatarUrl: 'https://i.pravatar.cc/300?img=32',
    },
  });
const u3 = await prisma.user.upsert({
  where: { email: 'MaiLinh@test.com' },
  update: {},
  create: {
    username: 'Mai Linh',
    fullName: 'Mai Linh',
    email: 'MaiLinh@test.com',
    emailVerifiedAt: new Date(),
    authProvider: 'password',
    passwordHash,
    phoneVerifyRequired: false,
    status: 'online',
    avatarUrl: 'https://i.pravatar.cc/300?img=12',
  },
});

const u4 = await prisma.user.upsert({
  where: { email: 'LinhNga@test.com' },
  update: {},
  create: {
    username: 'Linh Nga',
    fullName: 'Linh Nga',
    email: 'LinhNga@test.com',
    emailVerifiedAt: new Date(),
    authProvider: 'password',
    passwordHash,
    phoneVerifyRequired: false,
    status: 'online',
    avatarUrl: 'https://i.pravatar.cc/300?img=18',
  },
});
await prisma.conversation.upsert({
  where: { id: 'seed-group-1' },
  update: {},
  create: {
    id: 'seed-group-1',
    type: 'group',
    name: 'Nhóm nấu xói',
    createdBy: u1.id,
    members: {
      create: [
        { userId: u1.id, role: 'admin' },
        { userId: u2.id, role: 'member' },
        { userId: u3.id, role: 'member' },
        { userId: u4.id, role: 'member' },
      ],
    },
  },
});

//
// 1) đảm bảo user khiem tồn tại
const khiem = await prisma.user.findUnique({
  where: { username: 'khiem1_44078' },
});
if (!khiem) {
  throw new Error('User khiem1_44078 not found. Seed user này trước.');
}

// 2) upsert tram1
const tram = await prisma.user.upsert({
  where: { username: 'tram1' },
  update: {},
  create: {
    username: 'tram1',
    fullName: 'Trâm',
    authProvider: 'phone',
    phoneVerifyRequired: false,
    // các field optional
    avatarUrl: null,
    status: null,
    gender: null,
    area: null,
    phoneE164: null,
    email: null,
    passwordHash: null,
  },
});

// 3) tạo quan hệ bạn bè 2 chiều (Contact)
await prisma.contact.createMany({
  data: [
    { ownerId: tram.id, contactId: khiem.id },
    { ownerId: khiem.id, contactId: tram.id },
  ],
  skipDuplicates: true,
});

console.log('Seed: created friendship tram1 <-> khiem1_44078');

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
await prisma.message.createMany({
  data: [
    {
      conversationId: 'seed-group-1',
      senderId: u2.id,
      content: 'Chào mọi người 👋',
      type: 'text',
    },
    {
      conversationId: 'seed-group-1',
      senderId: u3.id,
      content: 'Mình mới vào nhóm',
      type: 'text',
    },
  ],
});

  console.log('✅ Seed OK');
  console.log('Login test:');
  console.log('Email:', 'tram1@gmail.com');
  console.log('Password:', password);
}

main()
  .catch(console.error)
  .finally(() => prisma.$disconnect());
