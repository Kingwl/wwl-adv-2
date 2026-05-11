class_name TowerPlacementService
extends RefCounted

var board: Board
var wallet: Wallet
var config: EconomyConfig
var tower_config: TowerConfig
var tower_registry: TowerRegistry
var basic_tower_type := GameTower.Type.SINGLE_TARGET

var _id_factory: Callable
var _next_tower_index := 1


func _init(
	new_board: Board,
	new_wallet: Wallet,
	new_config: EconomyConfig = null,
	id_factory: Callable = Callable(),
	new_tower_registry: TowerRegistry = null,
	new_basic_tower_type = GameTower.Type.SINGLE_TARGET,
	new_tower_config: TowerConfig = null
) -> void:
	assert(new_board != null, "Board is required.")
	assert(new_wallet != null, "Wallet is required.")

	board = new_board
	wallet = new_wallet
	config = new_config if new_config != null else EconomyConfig.new()
	tower_config = new_tower_config if new_tower_config != null else TowerConfig.new()
	tower_registry = new_tower_registry if new_tower_registry != null else TowerRegistry.new()
	basic_tower_type = new_basic_tower_type
	_id_factory = id_factory


func try_place_basic_tower(position: Vector2i) -> TowerPlacementResult:
	var tower_id := _next_tower_id()
	var build_cost := get_build_cost(basic_tower_type)
	var placement_check := board.can_place_tower(position, tower_id)

	if not placement_check.succeeded:
		return TowerPlacementResult.placement_failure(placement_check, tower_id, position)

	if not wallet.can_spend(build_cost):
		var insufficient_result := TransactionResult.failure(
			TransactionResult.FailureReason.INSUFFICIENT_FUNDS,
			TransactionRecord.Reason.PLACE_TOWER,
			build_cost,
			wallet.gold,
			tower_id,
			"Need %d gold." % build_cost
		)
		return TowerPlacementResult.transaction_failure(
			TowerPlacementResult.FailureReason.INSUFFICIENT_FUNDS,
			insufficient_result,
			tower_id,
			position
		)

	var spend_result := wallet.spend(build_cost, TransactionRecord.Reason.PLACE_TOWER, tower_id)
	if not spend_result.succeeded:
		return TowerPlacementResult.transaction_failure(
			TowerPlacementResult.FailureReason.TRANSACTION_FAILED,
			spend_result,
			tower_id,
			position
		)

	var placement_result := board.place_tower(position, tower_id)
	if not placement_result.succeeded:
		wallet.earn(build_cost, TransactionRecord.Reason.REFUND, tower_id)
		return TowerPlacementResult.placement_failure(placement_result, tower_id, position)

	tower_registry.add_tower(GameTower.new(tower_id, basic_tower_type, 1, position, build_cost))
	_advance_tower_id()
	return TowerPlacementResult.success(placement_result, spend_result, tower_id, position)


func try_upgrade_tower(tower_id: String) -> TowerUpgradeResult:
	var tower := tower_registry.get_tower(tower_id)
	if tower == null:
		return TowerUpgradeResult.tower_missing(tower_id)

	if not tower_config.can_upgrade(tower):
		return TowerUpgradeResult.max_tier(tower)

	var upgrade_cost := tower_config.get_upgrade_cost(tower.tower_type, tower.tier)
	var next_tier := tower.tier + 1
	if not wallet.can_spend(upgrade_cost):
		var insufficient_result := TransactionResult.failure(
			TransactionResult.FailureReason.INSUFFICIENT_FUNDS,
			TransactionRecord.Reason.UPGRADE_TOWER,
			upgrade_cost,
			wallet.gold,
			tower.id,
			"Need %d gold." % upgrade_cost
		)
		return TowerUpgradeResult.transaction_failure(
			TowerUpgradeResult.FailureReason.INSUFFICIENT_FUNDS,
			insufficient_result,
			tower,
			next_tier,
			upgrade_cost
		)

	var spend_result := wallet.spend(upgrade_cost, TransactionRecord.Reason.UPGRADE_TOWER, tower.id)
	if not spend_result.succeeded:
		return TowerUpgradeResult.transaction_failure(
			TowerUpgradeResult.FailureReason.TRANSACTION_FAILED,
			spend_result,
			tower,
			next_tier,
			upgrade_cost
		)

	var previous_tier := tower.tier
	tower.tier = next_tier
	tower.invested_gold += upgrade_cost
	var next_stats := tower_config.get_stats(tower.tower_type, tower.tier)
	tower.cooldown_remaining = minf(tower.cooldown_remaining, next_stats.attack_interval)
	return TowerUpgradeResult.success(tower, previous_tier, spend_result)


func try_remove_tower_at(position: Vector2i) -> TowerRemovalResult:
	var removal_check := _check_remove_tower_at(position)
	if not removal_check.succeeded:
		return TowerRemovalResult.board_failure(removal_check)

	var tower := tower_registry.get_tower(removal_check.removed_occupant_id)
	if tower == null:
		return TowerRemovalResult.tower_missing(position, removal_check.removed_occupant_id)

	var refund_amount := removal_refund_amount(tower)
	var removal_result := board.remove_tower(position, tower.id)
	if not removal_result.succeeded:
		return TowerRemovalResult.board_failure(removal_result)

	tower_registry.remove_tower(tower.id)
	var refund_result: TransactionResult = null
	if refund_amount > 0:
		refund_result = wallet.earn(refund_amount, TransactionRecord.Reason.REFUND, tower.id)
		if not refund_result.succeeded:
			return TowerRemovalResult.refund_failure(removal_result, refund_result, tower, refund_amount)

	return TowerRemovalResult.success(removal_result, refund_result, tower, refund_amount)


func removal_refund_amount(tower: GameTower) -> int:
	if tower == null:
		return 0

	return floori(float(tower.invested_gold) * config.tower_removal_refund_ratio)


func get_build_cost(tower_type: GameTower.Type) -> int:
	if tower_config == null:
		return config.basic_tower_cost

	return tower_config.get_build_cost(tower_type, config.basic_tower_cost)


func _next_tower_id() -> String:
	if _id_factory.is_valid():
		return str(_id_factory.call())

	return "tower-%d" % _next_tower_index


func _advance_tower_id() -> void:
	if not _id_factory.is_valid():
		_next_tower_index += 1


func _check_remove_tower_at(position: Vector2i) -> RemovalResult:
	if not board.is_in_bounds(position):
		return RemovalResult.failure(
			RemovalResult.FailureReason.OUT_OF_BOUNDS,
			"Cannot remove tower outside the board.",
			position
		)

	var occupant_id := board.get_occupant_id(position)
	if occupant_id.is_empty():
		return RemovalResult.failure(
			RemovalResult.FailureReason.EMPTY,
			"Slot does not contain a tower.",
			position
		)

	return RemovalResult.success(position, occupant_id)
