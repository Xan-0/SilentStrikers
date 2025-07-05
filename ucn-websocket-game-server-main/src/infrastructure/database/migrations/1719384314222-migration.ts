import { MigrationInterface, QueryRunner } from 'typeorm';

export class Migration1719384314222 implements MigrationInterface {
  name = 'Migration1719384314222';

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(
      `ALTER TABLE "game" ADD "keyword" character varying NOT NULL`,
    );
    await queryRunner.query(`ALTER TABLE "score" ADD "game_id" uuid`);
    await queryRunner.query(
      `ALTER TABLE "score" ADD CONSTRAINT "FK_f823a852d476962438b5ad3bda8" FOREIGN KEY ("game_id") REFERENCES "game"("id") ON DELETE NO ACTION ON UPDATE NO ACTION`,
    );
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(
      `ALTER TABLE "score" DROP CONSTRAINT "FK_f823a852d476962438b5ad3bda8"`,
    );
    await queryRunner.query(`ALTER TABLE "score" DROP COLUMN "game_id"`);
    await queryRunner.query(`ALTER TABLE "game" DROP COLUMN "keyword"`);
  }
}
