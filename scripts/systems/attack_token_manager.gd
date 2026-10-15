class_name AttackTokenManager
extends Node

## Manages enemy attack tokens for crowd fights (Section 5a).
## Ensures crowded encounters are fair by limiting concurrent attacking enemies.

static var active_tokens: int = 0
static var max_concurrent_attacks: int = 2

static func request_attack_token() -> bool:
	if active_tokens < max_concurrent_attacks:
		active_tokens += 1
		return true
	return false

static func release_attack_token() -> void:
	active_tokens = max(0, active_tokens - 1)
