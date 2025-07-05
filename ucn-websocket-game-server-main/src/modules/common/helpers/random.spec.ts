import { generateRandomString } from './random';

describe('#RandomHelper', () => {
  describe('generateRandomString', () => {
    it('generate a random string', () => {
      const result = generateRandomString();

      expect(result).toBeDefined();
      expect(typeof result).toBe('string');
      expect(result).toHaveProperty('length', 10);
    });

    it('generate a random string with a defined number', () => {
      const max = 50;

      const result = generateRandomString(max);

      expect(result).toBeDefined();
      expect(typeof result).toBe('string');
      expect(result).toHaveProperty('length', max);
    });
  });
});
