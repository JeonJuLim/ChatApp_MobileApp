import { PrismaClient } from '@prisma/client';
import * as bcrypt from 'bcryptjs';

const prisma = new PrismaClient();

async function main() {
  const password = 'Test@12345';
  const passwordHash = await bcrypt.hash(password, 10);

  // =========================
  // USERS (upsert để chạy seed nhiều lần không lỗi)
  // =========================

  const u1 = await prisma.user.upsert({
    where: { email: 'tram1@gmail.com' },
    update: {},
    create: {
      username: 'tram1',
      fullName: 'Tram 1',
      email: 'tram1@gmail.com',

      // NOTE: nếu schema bạn KHÔNG có emailVerifiedAt mà là emailVerified(boolean)
      // thì đổi thành: emailVerified: true
      emailVerifiedAt: new Date(),

      authProvider: 'password',
      passwordHash,

      phoneVerifyRequired: false,
      status: 'online',
      avatarUrl: 'https://i.pravatar.cc/300?img=15',
    },
  });

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
    where: { email: 'mailinh@test.com' },
    update: {},
    create: {
      username: 'mailinh',
      fullName: 'Mai Linh',
      email: 'mailinh@test.com',
      emailVerifiedAt: new Date(),

      authProvider: 'password',
      passwordHash,

      phoneVerifyRequired: false,
      status: 'online',
      avatarUrl: 'https://i.pravatar.cc/300?img=12',
    },
  });

  const u4 = await prisma.user.upsert({
    where: { email: 'linhnga@test.com' },
    update: {},
    create: {
      username: 'linhnga',
      fullName: 'Linh Nga',
      email: 'linhnga@test.com',
      emailVerifiedAt: new Date(),

      authProvider: 'password',
      passwordHash,

      phoneVerifyRequired: false,
      status: 'online',
      avatarUrl: 'https://i.pravatar.cc/300?img=18',
    },
  });

  // ✅ FIX CHÍNH: tạo luôn user khiem1_44078 nếu chưa có
  const khiemUser = await prisma.user.upsert({
    where: { username: 'khiem1_44078' },
    update: {},
    create: {
      username: 'khiem1_44078',
      fullName: 'Dang Hoang Khiem',
      email: 'khiem1_44078@test.com',
      emailVerifiedAt: new Date(),

      authProvider: 'password',
      passwordHash,

      phoneVerifyRequired: false,
      status: 'online',
      avatarUrl: 'https://i.pravatar.cc/300?img=20',
    },
  });

  // =========================
  // GROUP CONVERSATION
  // =========================
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

  // ✅ tránh nhân đôi messages cho group mỗi lần seed
  const groupMsgCount = await prisma.message.count({
    where: { conversationId: 'seed-group-1' },
  });

  if (groupMsgCount === 0) {
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
  }

  // =========================
  // DIRECT CONVERSATION: u1 <-> u2
  // =========================
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

  const c1Count = await prisma.message.count({ where: { conversationId: c1.id } });
  if (c1Count === 0) {
    await prisma.message.create({
      data: {
        conversationId: c1.id,
        senderId: u1.id,
        content: 'Hello từ tram1@gmail.com',
        type: 'text',
      },
    });
  }

  // ================================
  // CONTACT + DIRECT CHAT: tram1 <-> khiem1_44078
  // ================================
  const tramUser = await prisma.user.findUnique({ where: { username: 'tram1' } });
  if (!tramUser) throw new Error('User tram1 not found (unexpected).');

  // 1) đảm bảo contact 2 chiều
  await prisma.contact.createMany({
    data: [
      { ownerId: tramUser.id, contactId: khiemUser.id },
      { ownerId: khiemUser.id, contactId: tramUser.id },
    ],
    skipDuplicates: true,
  });

  // 2) check direct conversation giữa 2 user (tránh match nhầm group)
  const existedDirect = await prisma.conversation.findFirst({
    where: {
      type: 'direct',
      AND: [
        { members: { some: { userId: khiemUser.id } } },
        { members: { some: { userId: tramUser.id } } },
        { members: { every: { userId: { in: [khiemUser.id, tramUser.id] } } } },
      ],
    },
  });

  const directConv = existedDirect
    ? existedDirect
    : await prisma.conversation.create({
        data: {
          type: 'direct',
          createdBy: khiemUser.id,
          members: {
            create: [
              { userId: khiemUser.id, role: 'member' },
              { userId: tramUser.id, role: 'member' },
            ],
          },
        },
      });

  // 3) seed message nếu chưa có
  const dmCount = await prisma.message.count({
    where: { conversationId: directConv.id },
  });

  if (dmCount === 0) {
    await prisma.message.createMany({
      data: [
        {
          conversationId: directConv.id,
          senderId: khiemUser.id,
          type: 'text',
          content: 'Chào Trâm 👋',
        },
        {
          conversationId: directConv.id,
          senderId: tramUser.id,
          type: 'text',
          content: 'Hi Khiêm, mình test chat nha 😄',
        },
        {
          conversationId: directConv.id,
          senderId: khiemUser.id,
          type: 'text',
          content: 'OK, chat chạy ổn rồi 👍',
        },
      ],
    });
  }

  console.log('✅ Seed OK');
  console.log('Login test:');
  console.log('Email:', 'tram1@gmail.com');
  console.log('Password:', password);
  console.log('Extra user:', 'khiem1_44078 / same password');
}

main()
  .catch((e) => {
    console.error('❌ Seed failed:', e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
