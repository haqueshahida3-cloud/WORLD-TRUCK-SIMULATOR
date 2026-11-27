extends Node
class_name WalletSystem

signal balance_changed(new_balance: float)
signal transaction_completed(description: String, amount: float)

@export_group("Starting Money")
@export var starting_money: float = 50000.0

@export_group("Economy")
@export var allow_negative_balance: bool = false

var balance: float = 0.0
var total_earned: float = 0.0
var total_spent: float = 0.0

var transaction_history: Array[Dictionary] = []


func _ready() -> void:
    add_to_group("wallet_system")
    balance = maxf(starting_money, 0.0)
    balance_changed.emit(balance)


# ============================================================
# ADD MONEY
# ============================================================

func add_money(amount: float, description: String = "Income") -> bool:

    if amount <= 0.0:
        return false

    balance += amount
    total_earned += amount

    _record_transaction(description, amount)
    balance_changed.emit(balance)

    return true


# ============================================================
# SPEND MONEY
# ============================================================

func spend_money(amount: float, description: String = "Purchase") -> bool:

    if amount <= 0.0:
        return false

    if not allow_negative_balance and balance < amount:
        return false

    balance -= amount
    total_spent += amount

    _record_transaction(description, -amount)
    balance_changed.emit(balance)

    return true


# ============================================================
# TRANSACTION HISTORY
# ============================================================

func _record_transaction(description: String, amount: float) -> void:

    var transaction := {
        "description": description,
        "amount": amount,
        "balance": balance,
        "timestamp": Time.get_datetime_string_from_system()
    }

    transaction_history.append(transaction)
    transaction_completed.emit(description, amount)


func get_transaction_history() -> Array[Dictionary]:
    return transaction_history.duplicate(true)


# ============================================================
# BALANCE INFORMATION
# ============================================================

func get_balance() -> float:
    return balance


func get_total_earned() -> float:
    return total_earned


func get_total_spent() -> float:
    return total_spent


func can_afford(amount: float) -> bool:
    return amount >= 0.0 and balance >= amount


# ============================================================
# RESET
# ============================================================

func reset_wallet() -> void:

    balance = maxf(starting_money, 0.0)
    total_earned = 0.0
    total_spent = 0.0

    transaction_history.clear()

    balance_changed.emit(balance)
