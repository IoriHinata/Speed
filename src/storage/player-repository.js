const KEY='speed-haven-player-v1';
export class PlayerRepository { load(fallback){ try { const value=localStorage.getItem(KEY); return value?JSON.parse(value):fallback; } catch { return fallback; } } save(player){ localStorage.setItem(KEY,JSON.stringify(player)); return player; } }
