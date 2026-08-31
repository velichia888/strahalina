import "dotenv/config";
import { PrismaClient } from "@prisma/client";
import { hashPassword } from "../src/utils/password";

const prisma = new PrismaClient();

/**
 * Bootstraps (or promotes) the one admin account this app needs to
 * manage listings/updates and see every buyer conversation. No public
 * admin-signup endpoint exists on purpose — this script, run manually
 * against a real DATABASE_URL, is the only way to create or grant
 * isAdmin.
 */
async function main() {
  const email = process.env.ADMIN_BOOTSTRAP_EMAIL;
  const password = process.env.ADMIN_BOOTSTRAP_PASSWORD;
  if (!email || !password) {
    throw new Error("Set ADMIN_BOOTSTRAP_EMAIL and ADMIN_BOOTSTRAP_PASSWORD before running the seed script");
  }

  const existing = await prisma.user.findUnique({ where: { email } });
  if (existing) {
    await prisma.user.update({ where: { id: existing.id }, data: { isAdmin: true } });
    console.log(`Promoted existing user ${email} to admin.`);
    return;
  }

  const passwordHash = await hashPassword(password);
  await prisma.user.create({
    data: { email, passwordHash, displayName: "Admin", isAdmin: true },
  });
  console.log(`Created admin user ${email}.`);
}

main()
  .catch((err) => {
    console.error(err);
    process.exit(1);
  })
  .finally(() => prisma.$disconnect());
