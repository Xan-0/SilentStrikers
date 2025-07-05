import { randomInt } from 'crypto';

export const generateRandomString = (size: number = 10) => {
  const charset =
    'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-_.:,;{}[]()';
  const charsetLength = charset.length;

  let randomString = '';
  for (let i = 0; i < size; i++) {
    randomString += charset[randomInt(charsetLength)];
  }
  return randomString;
};
