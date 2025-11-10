## Handles score submission and leaderboard fetching to the game's NodeJS backend
extends Node

signal score_submitted(success: bool, game_id: int, message: String)
signal current_period_leaderboard_fetched(leaderboard: Array, period_info: Dictionary)
signal fetch_failed(error: String)

const SERVER_URL: String = "http://localhost:3002"     # Change to production URL
const CLIENT_KEY = "one-in-the-pink-two-in-the-stink"  # Change to a unique production client key

var debug_mode: bool = false


func _ready() -> void:
	if debug_mode:
		print("[ScoreServer] Server URL: ", SERVER_URL)


func submit_score(play_session: PlaySession) -> void:
	if play_session.score <= 0:
		return
	
	if not PolkaGodot.is_wallet_connected():
		if debug_mode:
			print("[ScoreServer] Cannot submit score - wallet not connected")
		score_submitted.emit(false, 0, "Wallet not connected")
		return

	var player_address = PolkaGodot.get_wallet_address()
	if player_address.is_empty():
		if debug_mode:
			print("[ScoreServer] Cannot submit score - no wallet address")
		score_submitted.emit(false, 0, "No wallet address")
		return

	OnlineNotifier.create_score_submission_notification()
	
	# Extra metadata can be included here for verification.
	var metadata: Dictionary = {}
	
	# Timestamp the submission and create a hash to validate that the metadata JSON wasn't tampered with
	var timestamp = int(Time.get_unix_time_from_system())
	var hash_value = _create_hash(play_session.score, metadata, timestamp)

	# Build request body
	var request_body = {
		"address": player_address,
		"score": play_session.score,
		"metadata": metadata,
		"hash": hash_value,
		"timestamp": timestamp
	}

	if debug_mode:
		print("[ScoreServer] Submitting score:")
		print("  Address: ", player_address)
		print("  Score: ", play_session.score)
		print("  Metadata: ", metadata)
		print("  Hash: ", hash_value)
		
	var http = HTTPRequest.new()
	add_child(http)
	http.request_completed.connect(_on_score_submit_completed.bind(http))

	var json_body = JSON.stringify(request_body)
	var headers = ["Content-Type: application/json"]

	var error = http.request(SERVER_URL + "/game/submit-score", headers, HTTPClient.METHOD_POST, json_body)
	
	if error != OK:
		if debug_mode:
			print("[ScoreServer] HTTP request failed with error: ", error)
		score_submitted.emit(false, 0, "HTTP request failed")
		http.queue_free()


func _on_score_submit_completed(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray, req_node: HTTPRequest) -> void:
	if debug_mode:
		print("[ScoreServer] Score submission response: ", response_code)

	if response_code == 200:
		var json = JSON.new()
		var parse_result = json.parse(body.get_string_from_utf8())

		if parse_result == OK:
			var response = json.data
			if response.has("success") and response.success:
				var game_id = response.get("gameId", 0)
				if debug_mode:
					print("[ScoreServer] Score submitted successfully! Game ID: ", game_id)
					print("  Transaction: ", response.get("transactionHash", ""))

				score_submitted.emit(true, game_id, "Score submitted successfully")
			else:
				var error_msg = response.get("message", "Unknown error")
				if debug_mode:
					print("[ScoreServer] Score submission failed: ", error_msg)
				score_submitted.emit(false, 0, error_msg)
		else:
			if debug_mode:
				print("[ScoreServer] Failed to parse response JSON")
			score_submitted.emit(false, 0, "Invalid server response")
	else:
		# Try to parse error message
		var error_msg = "Server error"
		var json = JSON.new()
		if json.parse(body.get_string_from_utf8()) == OK:
			var response = json.data
			error_msg = response.get("message", response.get("error", "Server error"))

		if debug_mode:
			print("[ScoreServer] Score submission failed: ", error_msg, " (HTTP ", response_code, ")")
		score_submitted.emit(false, 0, error_msg)

	# Clean up HTTPRequest node
	if is_instance_valid(req_node):
		req_node.queue_free()


func fetch_current_period_leaderboard(num_scores: int = 10) -> void:
	if debug_mode:
		print("[ScoreServer] Fetching current period leaderboard: limit=", num_scores)
	
	var http = HTTPRequest.new()
	add_child(http)
	http.request_completed.connect(_on_current_period_leaderboard_fetched.bind(http))

	var url = "%s/game/current-period-leaderboard?limit=%d" % [SERVER_URL, num_scores]
	var error = http.request(url)
	
	if error != OK:
		if debug_mode:
			print("[ScoreServer] HTTP request failed with error: ", error)
		fetch_failed.emit("HTTP request failed")
		http.queue_free()


func _on_current_period_leaderboard_fetched(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray, req_node: HTTPRequest) -> void:
	if debug_mode:
		print("[ScoreServer] Current period leaderboard response: ", response_code)
	
	if response_code == 200:
		var json = JSON.new()
		var parse_result = json.parse(body.get_string_from_utf8())
	
		if parse_result == OK:
			var response = json.data
			var period_info = response.get("periodInfo", {})
			var leaderboard_data = response.get("leaderboard", {})
			var results = leaderboard_data.get("results", [])
			
			if debug_mode:
				print("[ScoreServer] Current period leaderboard fetched: ", results.size(), " entries")
				if period_info:
					print("  Period: %.2f hours since last reward" % period_info.get("hoursSinceLastReward", 0))
			
			current_period_leaderboard_fetched.emit(results, period_info)
		else:
			if debug_mode:
				print("[ScoreServer] Failed to parse leaderboard JSON")
			fetch_failed.emit("Invalid server response")
	else:
		var error_msg = "Server error"
		var json = JSON.new()
		if json.parse(body.get_string_from_utf8()) == OK:
			var response = json.data
			error_msg = response.get("message", response.get("error", "Server error"))

		if debug_mode:
			print("[ScoreServer] Current period leaderboard fetch failed: ", error_msg)
		fetch_failed.emit(error_msg)

	# Clean up the HTTPRequest node
	if req_node:
		req_node.queue_free()


func _create_hash(score: int, metadata: Dictionary, timestamp: int) -> String:
	var metadata_json = JSON.stringify(metadata)
	var data = "%d|%s|%s|%d" % [score, metadata_json, CLIENT_KEY, timestamp]

	# Use SHA-256 hashing
	var ctx = HashingContext.new()
	ctx.start(HashingContext.HASH_SHA256)
	ctx.update(data.to_utf8_buffer())
	var hash_bytes = ctx.finish()

	# Convert to hex string
	var hex_string = ""
	for byte in hash_bytes:
		hex_string += "%02x" % byte

	return hex_string
