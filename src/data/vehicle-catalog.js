/** Shared offline catalogue used by recognition confirmation and deterministic rarity scoring. */
export const VEHICLE_CATALOG = Object.freeze([
  {brand:'Toyota',model:'Supra',generation:'A80',bodyType:'coupe',baseValue:55000,speed:145,handling:78,durability:70,rarityScore:65,prestige:58,popularity:70,sportiness:90,collectability:86},
  {brand:'BMW',model:'M3',generation:'G80',bodyType:'sedan',baseValue:85000,speed:155,handling:80,durability:69,rarityScore:55,prestige:72,popularity:75,sportiness:86,collectability:72},
  {brand:'Porsche',model:'911',generation:'992',bodyType:'coupe',baseValue:140000,speed:185,handling:88,durability:72,rarityScore:74,prestige:90,popularity:55,sportiness:95,collectability:92},
  {brand:'Nissan',model:'GT-R',generation:'R35',bodyType:'coupe',baseValue:120000,speed:178,handling:83,durability:71,rarityScore:76,prestige:80,popularity:45,sportiness:98,collectability:94},
  {brand:'Ford',model:'Mustang',generation:'S650',bodyType:'coupe',baseValue:50000,speed:138,handling:72,durability:73,rarityScore:45,prestige:55,popularity:78,sportiness:84,collectability:70},
  {brand:'Bugatti',model:'Chiron',generation:'I',bodyType:'hypercar',baseValue:3200000,speed:261,handling:86,durability:58,rarityScore:100,prestige:100,popularity:1,sportiness:100,collectability:100},
  {brand:'Lamborghini',model:'Huracán',generation:'EVO',bodyType:'supercar',baseValue:260000,speed:201,handling:91,durability:62,rarityScore:94,prestige:100,popularity:18,sportiness:100,collectability:100},
  {brand:'Tesla',model:'Model S',generation:'Plaid',bodyType:'sedan',baseValue:90000,speed:170,handling:76,durability:65,rarityScore:40,prestige:70,popularity:82,sportiness:78,collectability:62}
]);
export const CAR_COLORS = Object.freeze(['Белый','Чёрный','Серый','Серебристый','Красный','Синий','Жёлтый','Зелёный','Оранжевый','Фиолетовый']);
export const COLOR_HEX = Object.freeze({Белый:'#f5f5f5',Чёрный:'#21252d',Серый:'#9aa0a8',Серебристый:'#c8cbd0',Красный:'#d94444',Синий:'#4ba8ff',Жёлтый:'#ffd700',Зелёный:'#46b96f',Оранжевый:'#ff8a3d',Фиолетовый:'#b77cff'});
export const RACE_MAPS = Object.freeze([
  {id:'city-dry',name:'Ночной город',weather:'Ясно',surface:'Асфальт',obstacles:2,handlingModifier:0},
  {id:'coast-rain',name:'Прибрежный шторм',weather:'Дождь',surface:'Мокрый асфальт',obstacles:4,handlingModifier:-12},
  {id:'mountain-fog',name:'Горный перевал',weather:'Туман',surface:'Гравий',obstacles:5,handlingModifier:-18}
]);
