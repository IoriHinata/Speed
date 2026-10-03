import {Rarity} from '../domain/models.js';
const brandPrestige={Bugatti:100,Lamborghini:100,Ferrari:96,Porsche:90,BMW:72,Toyota:58};
const commonColors=new Set(['Белый','Чёрный','Серый','Серебристый']);
/** Weighted, deterministic scoring. Catalogue entries are extensible without UI changes. */
export class RarityService {
  calculate(vehicle) {
    const rarityScore=vehicle.rarityScore??vehicle.modelRarity??25, prestige=vehicle.prestige??brandPrestige[vehicle.brand]??30, valueScore=Math.max(0,Math.min(100,Math.round(Math.log(Math.max(1,vehicle.baseValue??25000))/Math.log(500000)*100))), popularityInverse=100-(vehicle.popularity??vehicle.commonness??80), colorScore=commonColors.has(vehicle.color)?25:75, sportiness=vehicle.sportiness??40, collectability=vehicle.collectability??vehicle.collectible??25;
    const score=Math.round(rarityScore*.22+prestige*.18+valueScore*.15+popularityInverse*.12+colorScore*.08+sportiness*.10+collectability*.15);
    if(score>=82)return Rarity.LEGENDARY;if(score>=66)return Rarity.EPIC;if(score>=49)return Rarity.RARE;if(score>=31)return Rarity.UNCOMMON;return Rarity.COMMON;
  }
}
