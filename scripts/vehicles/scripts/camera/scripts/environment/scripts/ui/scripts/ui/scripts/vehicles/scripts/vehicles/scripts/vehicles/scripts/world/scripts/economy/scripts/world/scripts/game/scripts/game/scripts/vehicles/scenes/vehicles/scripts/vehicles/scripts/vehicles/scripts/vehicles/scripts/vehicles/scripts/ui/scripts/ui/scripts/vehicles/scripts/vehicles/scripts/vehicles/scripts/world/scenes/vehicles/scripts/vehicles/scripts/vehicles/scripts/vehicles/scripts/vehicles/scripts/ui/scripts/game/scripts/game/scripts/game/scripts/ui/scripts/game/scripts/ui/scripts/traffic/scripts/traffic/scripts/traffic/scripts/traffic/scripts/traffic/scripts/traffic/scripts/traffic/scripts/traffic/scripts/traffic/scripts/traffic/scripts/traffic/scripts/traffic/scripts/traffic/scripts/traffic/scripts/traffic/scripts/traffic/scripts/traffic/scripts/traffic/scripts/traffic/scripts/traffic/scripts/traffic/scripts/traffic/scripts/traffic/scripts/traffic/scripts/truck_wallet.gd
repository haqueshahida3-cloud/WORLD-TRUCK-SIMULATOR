extends Node
class_name TruckWallet

signal balance_changed(new_balance: float)
signal money_earned(amount: float, reason: String)
signal money_spent(amount: float, reason: String)
signal insufficient_funds

@export_group("Wallet")
@export var starting_money := 10000.0
@export var allow_negative_balance := false

var balance := 10000.0
var transaction_history: Array[Dictionary] = []


func _ready():
    balance = starting_money
    balance_changed.emit(balance)


func add_money(amount: float, reason: String = "Income") -> bool:
    if amount <= 0.0:
        return false

    balance += amount

    transaction_history.append({
        "type": "income",
        "amount": amount,
        "reason": reason,
        "balance": balance
    })

    money_earned.emit(amount, reason)
    balance_changed.emit(balance)
    return true


func spend_money(amount: float, reason: String = "Expense") -> bool:
    if amount <= 0.0:
        return false

    if not allow_negative_balance and balance < amount:
        insufficient_funds.emit()
        return false

    balance -= amount

    transaction_history.append({
        "type": "expense",
        "amount": amount,
        "reason": reason,
        "balance": balance
    })

    money_spent.emit(amount, reason)
    balance_changed.emit(balance)
    return true


func pay_job_reward(amount: float):
    return add_money(amount, "Job Reward")


func pay_fuel_bill(amount: float) -> bool:
    return spend_money(amount, "Fuel Payment")


func pay_repair_bill(amount: float) -> bool:
    return spend_money(amount, "Truck Repair")


func get_balance() -> float:
    return balance


func get_transaction_history() -> Array[Dictionary]:
    return transaction_history.duplicate(true)


func reset_wallet():
    balance = starting_money
    transaction_history.clear()
    balance_changed.emit(balance)
