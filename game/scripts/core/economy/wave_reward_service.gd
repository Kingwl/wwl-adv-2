class_name WaveRewardService
extends RefCounted

var wallet: Wallet


func _init(new_wallet: Wallet) -> void:
	assert(new_wallet != null, "Wallet is required.")

	wallet = new_wallet


func apply_clear_events(wave_clear_events: Array) -> Array:
	var transaction_results := []

	for candidate in wave_clear_events:
		var clear_event := candidate as WaveClearEvent
		if clear_event == null or clear_event.reward_gold <= 0:
			continue

		transaction_results.append(
			wallet.earn(
				clear_event.reward_gold,
				TransactionRecord.Reason.CLEAR_WAVE,
				clear_event.wave_id
			)
		)

	return transaction_results
