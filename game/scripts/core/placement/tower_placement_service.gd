class_name TowerPlacementService
extends RefCounted

var board: Board
var wallet: Wallet
var config: EconomyConfig
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
	new_basic_tower_type = GameTower.Type.SINGLE_TARGET
) -> void:
	assert(new_board != null, "Board is required.")
	assert(new_wallet != null, "Wallet is required.")

	board = new_board
	wallet = new_wallet
	config = new_config if new_config != null else EconomyConfig.new()
	tower_registry = new_tower_registry if new_tower_registry != null else TowerRegistry.new()
	basic_tower_type = new_basic_tower_type
	_id_factory = id_factory


func try_place_basic_tower(position: Vector2i) -> TowerPlacementResult:
	var tower_id := _next_tower_id()
	var placement_check := board.can_place_tower(position, tower_id)

	if not placement_check.succeeded:
		return TowerPlacementResult.placement_failure(placement_check, tower_id, position)

	if not wallet.can_spend(config.basic_tower_cost):
		var insufficient_result := TransactionResult.failure(
			TransactionResult.FailureReason.INSUFFICIENT_FUNDS,
			TransactionRecord.Reason.PLACE_TOWER,
			config.basic_tower_cost,
			wallet.gold,
			tower_id,
			"Need %d gold." % config.basic_tower_cost
		)
		return TowerPlacementResult.transaction_failure(
			TowerPlacementResult.FailureReason.INSUFFICIENT_FUNDS,
			insufficient_result,
			tower_id,
			position
		)

	var spend_result := wallet.spend(config.basic_tower_cost, TransactionRecord.Reason.PLACE_TOWER, tower_id)
	if not spend_result.succeeded:
		return TowerPlacementResult.transaction_failure(
			TowerPlacementResult.FailureReason.TRANSACTION_FAILED,
			spend_result,
			tower_id,
			position
		)

	var placement_result := board.place_tower(position, tower_id)
	if not placement_result.succeeded:
		wallet.earn(config.basic_tower_cost, TransactionRecord.Reason.REFUND, tower_id)
		return TowerPlacementResult.placement_failure(placement_result, tower_id, position)

	tower_registry.add_tower(GameTower.new(tower_id, basic_tower_type, 1, position))
	_advance_tower_id()
	return TowerPlacementResult.success(placement_result, spend_result, tower_id, position)


func _next_tower_id() -> String:
	if _id_factory.is_valid():
		return str(_id_factory.call())

	return "tower-%d" % _next_tower_index


func _advance_tower_id() -> void:
	if not _id_factory.is_valid():
		_next_tower_index += 1
