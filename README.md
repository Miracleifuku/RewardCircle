# RewardCircle

RewardCircle is a loyalty rewards system that enables users to earn, transfer, and redeem points. The contract provides secure and comprehensive validation mechanisms to ensure fair and transparent transactions.

## Features
- Earn points through merchant transactions.
- Transfer points between users.
- Redeem points for rewards with daily limits.
- Administrative controls for managing merchants and contract ownership.
- Comprehensive validation to prevent unauthorized actions.

## Constants
- `POINTS-MULTIPLIER`: 1 STX = 100 points.
- `MAX-TRANSFER-LIMIT`: Maximum of 10,000 points per transfer.
- `DAILY-REDEMPTION-LIMIT`: Users can redeem up to 5,000 points daily.
- `BLOCKS-PER-DAY`: Assumed to be 144 (based on 10-minute block times).

## Error Codes
- `ERR-UNAUTHORIZED`: Unauthorized action.
- `ERR-INVALID-POINTS`: Invalid point amount.
- `ERR-INSUFFICIENT-BALANCE`: Insufficient balance.
- `ERR-TRANSFER-LIMIT-EXCEEDED`: Exceeded transfer limit.
- `ERR-REDEMPTION-LIMIT-EXCEEDED`: Exceeded redemption limit.
- `ERR-INVALID-REDEMPTION`: Invalid redemption request.
- `ERR-INVALID-PRINCIPAL`: Invalid principal entity.

## Data Structures
### `user-points`
Stores user balances and tracking information:
- `balance`: Current points balance.
- `lifetime-earned`: Total points earned.
- `daily-redeemed`: Points redeemed on the current day.
- `last-redemption-block`: Last block height when the user redeemed points.

### `authorized-merchants`
A mapping of merchants who can issue points.

## Functions

### Administrative Functions
#### `transfer-ownership(new-owner)`
Transfers contract ownership to a new principal.

#### `add-merchant(merchant)`
Adds a merchant to the list of authorized merchants.

#### `remove-merchant(merchant)`
Removes a merchant from the authorized list.

### Core Functions
#### `earn-points(user, stx-amount)`
Merchants can issue points to users based on STX transactions.

#### `transfer-points(recipient, amount)`
Allows users to transfer points to another user, subject to limits and validation.

#### `redeem-points(amount)`
Users can redeem points for rewards, subject to daily limits.

### Read-only Functions
#### `get-contract-owner()`
Returns the contract owner's principal.

#### `get-balance(user)`
Returns the current points balance of a user.

#### `get-lifetime-points(user)`
Returns the total lifetime points earned by a user.

#### `check-can-redeem(user, amount)`
Checks if a user is eligible to redeem a specified number of points.

#### `is-authorized-merchant(merchant)`
Checks if a given merchant is authorized.

## Security and Validation
- **Ownership Control**: Only the contract owner can manage merchants.
- **Merchant Verification**: Only authorized merchants can issue points.
- **Transfer Limits**: Ensures no excessive transfers occur.
- **Redemption Limits**: Prevents users from redeeming more than allowed daily.
- **Validation Checks**: Ensures that transactions comply with defined rules.

## Usage Example
1. The contract owner adds a merchant.
2. The merchant issues points to a user.
3. The user transfers points to another user.
4. The user redeems points for rewards.

## License
This contract is provided under an open-source license. Use it responsibly and ensure compliance with local regulations.
