import { PrismaClient } from "@prisma/client";
import bcrypt from "bcryptjs";

const prisma = new PrismaClient();

async function main() {
  const password = "Test@12345"; // password test cho Flutter
  const passwordHash = await bcrypt.hash(password, 10);

  const user = await prisma.user.upsert({
    where: { username: "tram" },
    update: {
      fullName: "Tram",
      avatarUrl: "https://i.pravatar.cc/300?img=47",
      status: "online",

      authProvider: "password",
      googleSub: null,

      phoneE164: "+84909998877",
      phoneVerifyRequired: false,
      phoneVerifiedAt: new Date(),

      email: "tram.fake@testmail.com",
      emailVerifiedAt: new Date(),

      passwordHash,
    },
    create: {
      username: "tram",
      fullName: "Tram",
      avatarUrl: "https://i.pravatar.cc/300?img=47",
      status: "online",

      authProvider: "password",
      googleSub: null,

      phoneE164: "+84909998877",
      phoneVerifyRequired: false,
      phoneVerifiedAt: new Date(),

      email: "tram.fake@testmail.com",
      emailVerifiedAt: new Date(),

      passwordHash,
    },
  });

  console.log("Seeded user:");
  console.log({
    id: user.id,
    username: user.username,
    fullName: user.fullName,
    phone: user.phoneE164,
    email: user.email,
    password, // để login test Flutter
  });
}

main()
  .catch((e) => {
    console.error(e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
