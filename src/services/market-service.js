const LISTINGS = Object.freeze([
  {id:'market-gr86', brand:'Toyota', model:'GR86', generation:'ZN8', bodyType:'coupe', color:'#4ba8ff', rarity:'RARE', baseValue:32000, currentValue:29800, speed:128, handling:71, durability:70},
  {id:'market-mx5', brand:'Mazda', model:'MX-5', generation:'ND', bodyType:'convertible', color:'#ff5555', rarity:'UNCOMMON', baseValue:26000, currentValue:23000, speed:118, handling:79, durability:62}
]);
export class MarketService {
  listings() { return LISTINGS; }
  salePrice(vehicle) { return Math.floor(vehicle.currentValue * .5); }
  sell(player, id, economy) { const vehicle=player.vehicles.find(v=>v.id===id); if(!vehicle) throw new Error('Автомобиль не найден'); if(vehicle.lockedBy||vehicle.status==='IN_CHASE'||vehicle.status==='STOLEN') throw new Error('Автомобиль нельзя продать сейчас'); const credited=economy.credit(player,this.salePrice(vehicle),'market_sale'); return {...credited,vehicles:credited.vehicles.filter(v=>v.id!==id)}; }
  buy(player, listing, createVehicle, economy) { if (!listing || !this.listings().some((item) => item.id === listing.id)) throw new Error('Лот рынка недоступен'); const paid=economy.debit(player, listing.currentValue, 'market_purchase'); return {...paid, vehicles:[...paid.vehicles, createVehicle(listing)]}; }
}
