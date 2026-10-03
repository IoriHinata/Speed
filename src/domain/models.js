export const BodyType = Object.freeze(['sedan','hatchback','coupe','convertible','wagon','suv','crossover','pickup','van','supercar','hypercar','motorcycle']);
export const Rarity = Object.freeze({ COMMON:'COMMON', UNCOMMON:'UNCOMMON', RARE:'RARE', EPIC:'EPIC', LEGENDARY:'LEGENDARY' });
export const VehicleStatus = Object.freeze({ GARAGED:'GARAGED', OUTSIDE:'OUTSIDE', STOLEN:'STOLEN', IN_CHASE:'IN_CHASE', RECOVERED:'RECOVERED' });
export const UpgradeType = Object.freeze({ ENGINE:'ENGINE', HANDLING:'HANDLING', BODY:'BODY' });
export const RARITY_META = Object.freeze({
  COMMON:{label:'Обычная', color:'#95a1ad'}, UNCOMMON:{label:'Необычная',color:'#57d48a'}, RARE:{label:'Редкая',color:'#4ba8ff'}, EPIC:{label:'Эпическая',color:'#b77cff'}, LEGENDARY:{label:'Легендарная',color:'#ffbd4a'}
});
export function createVehicle(data) { return Object.freeze({ id: crypto.randomUUID(), brand:data.brand, model:data.model, generation:data.generation ?? 'I', bodyType:data.bodyType, color:data.color ?? '#d94444', rarity:data.rarity, baseValue:data.baseValue, currentValue:data.currentValue ?? data.baseValue, speed:data.speed, handling:data.handling, durability:data.durability, maxSpeed:data.maxSpeed ?? data.speed + 30, maxHandling:data.maxHandling ?? data.handling + 30, maxDurability:data.maxDurability ?? data.durability + 30, level:1, experience:0, damage:0, photo:data.photo ?? null, discoveredAt:new Date().toISOString(), status:VehicleStatus.OUTSIDE, garageSlot:null, lockedBy:null }); }
export function createPlayer() { return { balance:2500, level:1, experience:0, garageSlots:5, vehicles:[], notifications:[], processedTransactions:[], theftCooldownUntil:0 }; }
