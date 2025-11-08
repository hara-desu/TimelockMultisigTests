# 🕒 Timelock Multisig – Foundry Tests

This repository contains **unit tests** for a simple **Timelock Multisig smart contract**, written in **Solidity** and tested using **Foundry**.

The contract implements a basic multi-signature timelock mechanism — where multiple owners must confirm queued transactions before execution, and a specified delay must pass before those transactions can be executed.

---

## 📘 About

This project is based on a tutorial I followed to better understand Solidity, Foundry, and secure contract design.

👉 **Tutorial (in Russian):** [Add your tutorial link here]

My tests can be found in the [`test/`](./test) folder.  
They cover constructor validation, access control, queueing logic, confirmation flow, execution timing, and revert conditions.

---

## ⚙️ Tech Stack

- **Solidity** `^0.8.13`
- **Foundry** (Forge & Cast)
- **VS Code / CLI**

---

## 🧪 Running the Tests

If you have [Foundry](https://book.getfoundry.sh/) installed:

```bash
# install dependencies (if any)
forge build

# run all tests
forge test

# view available tests
forge test --list

# check coverage
forge coverage
