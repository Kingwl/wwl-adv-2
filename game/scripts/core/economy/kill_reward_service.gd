class_name KillRewardService
extends RefCounted

var wallet: Wallet


func _init(new_wallet: Wallet) -> void:
	assert(new_wallet != null, "Wallet is required.")

	wallet = new_wallet


func apply_death_events(death_events: Array) -> Array:
	var transaction_results := []

	for candidate in death_events:
		var death_event := candidate as EnemyDeathEvent
		if death_event == null or death_event.reward_gold <= 0:
			continue

		transaction_results.append(
			wallet.earn(
				death_event.reward_gold,
				TransactionRecord.Reason.KILL_ENEMY,
				death_event.enemy_id
			)
		)

	return transaction_results
