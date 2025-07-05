import { MigrationInterface, QueryRunner } from 'typeorm';

export class Migration1719376715473 implements MigrationInterface {
  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query('DROP TABLE "session"');
    await queryRunner.query('DROP TABLE "user"');
  }

  public async down(queryRunner: QueryRunner): Promise<void> {}
}
