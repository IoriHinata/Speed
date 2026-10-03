/** Locks wagered cards so a card cannot be placed in more than one concurrent race. */
export class StakeService {
  create(player, cardId, opponentCardId, raceId = crypto.randomUUID()) {
    const card = player.vehicles.find((vehicle) => vehicle.id === cardId);
    if (!card) throw new Error('Автомобиль для ставки не найден');
    if (card.lockedBy) throw new Error('Эта карточка уже участвует в другой сделке или ставке');
    return {
      player: {...player, vehicles: player.vehicles.map((vehicle) => vehicle.id === cardId ? {...vehicle, lockedBy: raceId} : vehicle)},
      stake: {id: raceId, ownCardId: cardId, opponentCardId, confirmations: [], status: 'PENDING', expiresAt: Date.now() + 120000}
    };
  }

  confirm(stake, side) {
    if (stake.status !== 'PENDING' || stake.expiresAt < Date.now()) throw new Error('Ставка истекла');
    if (!['LOCAL', 'REMOTE'].includes(side)) throw new Error('Некорректное подтверждение ставки');
    const confirmations = [...new Set([...stake.confirmations, side])];
    return {...stake, confirmations, status: confirmations.length === 2 ? 'READY' : 'PENDING'};
  }

  settle(player, stake, won) {
    if (stake.status !== 'READY') throw new Error('Ставка не подтверждена обеими сторонами');
    return {...player, vehicles: player.vehicles.map((vehicle) => vehicle.id === stake.ownCardId ? {...vehicle, lockedBy: null, status: won ? vehicle.status : 'TRANSFER_PENDING'} : vehicle)};
  }

  cancel(player, stake) {
    return {...player, vehicles: player.vehicles.map((vehicle) => vehicle.id === stake.ownCardId ? {...vehicle, lockedBy: null} : vehicle)};
  }
}
