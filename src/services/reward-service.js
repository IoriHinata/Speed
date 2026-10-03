const discovery={COMMON:{money:500,xp:25},UNCOMMON:{money:900,xp:45},RARE:{money:1500,xp:80},EPIC:{money:3000,xp:150},LEGENDARY:{money:7000,xp:300}};
export class RewardService { discovery(rarity){return discovery[rarity];} race(won){return {money:won?1500:500,xp:won?120:45};} chase(){return {money:1800,xp:160};} }
