/** Small deterministic top-down chase simulation used by the canvas-like chase UI. */
export class ChaseEngine {
  step(state, input) {
    const lane = Math.max(0, Math.min(2, state.lane + (input.left ? -1 : input.right ? 1 : 0)));
    const distance = Math.max(0, state.distance - Math.max(1, state.playerSpeed - state.targetSpeed + (input.boost ? 8 : 0)));
    const hit = state.obstacleLane === lane && !input.brake;
    const damage = Math.min(100, state.damage + (hit ? 12 : 0));
    return {...state, lane, distance, damage, ticks: state.ticks + 1, won: distance === 0, failed: damage >= 100 || state.ticks >= 20};
  }
}
