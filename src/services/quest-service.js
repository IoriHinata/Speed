const QUESTS = Object.freeze([
  {id:'first-scan',title:'Первый снимок',description:'Создайте карточку через камеру.',target:1,reward:{money:300,xp:60},metric:'discoveries'},
  {id:'garage-keeper',title:'Безопасное место',description:'Поставьте автомобиль в гараж.',target:1,reward:{money:200,xp:40},metric:'parked'},
  {id:'road-warrior',title:'Дорожный воин',description:'Завершите гонку с ботом.',target:1,reward:{money:250,xp:70},metric:'races'}
]);
export class QuestService {
  definitions() { return QUESTS; }
  progress(player, metric) { return player.questProgress?.[metric] ?? 0; }
  record(player, metric) { return {...player, questProgress:{...(player.questProgress??{}),[metric]:this.progress(player,metric)+1}}; }
  claim(player, id, economy, experience) { const quest=QUESTS.find(item=>item.id===id); if(!quest) throw new Error('Задание не найдено'); if((player.claimedQuests??[]).includes(id)) throw new Error('Награда уже получена'); if(this.progress(player,quest.metric)<quest.target) throw new Error('Задание ещё не выполнено'); let next={...player,claimedQuests:[...(player.claimedQuests??[]),id]}; next=economy.credit(next,quest.reward.money,`quest:${id}`); return experience.grant(next,quest.reward.xp,`quest:${id}`); }
}
