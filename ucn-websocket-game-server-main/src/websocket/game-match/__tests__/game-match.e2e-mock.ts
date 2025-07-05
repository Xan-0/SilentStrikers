export function getEnvVars(key: string): string {
  const obj: Record<string, string> = {
    VALIDATION_GAME_KEYS: 'A:SS;B:TT;C:U;D:V',
    default: '',
  };

  return obj[key] ?? obj.default;
}
