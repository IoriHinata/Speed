export const VEHICLE_CATALOG = Object.freeze([
  {brand:'Toyota', model:'Corolla', generation:'E210', bodyType:'sedan', baseValue:24000, speed:105, handling:58, durability:76, modelRarity:4, commonness:22},
  {brand:'Honda', model:'Civic Type R', generation:'FL5', bodyType:'hatchback', baseValue:46000, speed:132, handling:78, durability:68, modelRarity:14, sportiness:13, commonness:10},
  {brand:'BMW', model:'M3 Competition', generation:'G80', bodyType:'sedan', baseValue:85000, speed:155, handling:80, durability:69, modelRarity:18, sportiness:20, collectible:7, commonness:8},
  {brand:'Porsche', model:'911 Carrera', generation:'992', bodyType:'coupe', baseValue:120000, speed:185, handling:88, durability:72, modelRarity:22, sportiness:24, collectible:12, commonness:5},
  {brand:'Ferrari', model:'296 GTB', generation:'I', bodyType:'supercar', baseValue:360000, speed:205, handling:92, durability:61, modelRarity:30, sportiness:32, collectible:18, commonness:2},
  {brand:'Bugatti', model:'Chiron', generation:'I', bodyType:'hypercar', baseValue:3200000, speed:261, handling:86, durability:58, modelRarity:42, sportiness:40, collectible:30, commonness:1}
]);
export const CAR_COLORS = Object.freeze(['#d94444','#4ba8ff','#f5f5f5','#21252d','#ffd700','#b77cff','#ff69b4','#00d4c7']);
export const RACE_MAPS = Object.freeze([
  {id:'city-dry',name:'Ночной город',weather:'Ясно',surface:'Асфальт',obstacles:2,handlingModifier:0},
  {id:'coast-rain',name:'Прибрежный шторм',weather:'Дождь',surface:'Мокрый асфальт',obstacles:4,handlingModifier:-12},
  {id:'mountain-fog',name:'Горный перевал',weather:'Туман',surface:'Гравий',obstacles:5,handlingModifier:-18}
]);
