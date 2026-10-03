import { Rarity } from '../domain/models.js';
const prestige = { Ferrari:28, Lamborghini:30, Porsche:20, McLaren:30, Bugatti:40, Toyota:3, Honda:4, BMW:12, Mercedes:15, Tesla:13, Mazda:5, Ford:6 };
const unusual = new Set(['#ffd700','#b77cff','#ff69b4','#00d4c7']);
/** Deterministic and data-driven scoring; catalogue fields may extend it. */
export class RarityService { calculate(v) { const score = (v.modelRarity??10) + (prestige[v.brand]??8) + Math.min(25, Math.floor((v.baseValue??0)/10000)) + (v.collectible??0) + (v.sportiness??Math.max(0,((v.speed??80)-100)/4)) + (unusual.has(v.color)?8:0) - (v.commonness??10); if(score>=65)return Rarity.LEGENDARY; if(score>=48)return Rarity.EPIC; if(score>=32)return Rarity.RARE; if(score>=18)return Rarity.UNCOMMON; return Rarity.COMMON; } }
