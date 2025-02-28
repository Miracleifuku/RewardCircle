;; RewardCircle - A loyalty rewards system
;; Handles point earning, transfers, and redemptions with comprehensive validation

;; Constants
(define-constant ERR-UNAUTHORIZED (err u1))
(define-constant ERR-INVALID-POINTS (err u2))
(define-constant ERR-INSUFFICIENT-BALANCE (err u3))
(define-constant ERR-TRANSFER-LIMIT-EXCEEDED (err u4))
(define-constant ERR-REDEMPTION-LIMIT-EXCEEDED (err u5))
(define-constant ERR-INVALID-REDEMPTION (err u6))
(define-constant ERR-INVALID-PRINCIPAL (err u7))
(define-constant POINTS-MULTIPLIER u100)  ;; 1 STX = 100 points
(define-constant MAX-TRANSFER-LIMIT u10000)
(define-constant DAILY-REDEMPTION-LIMIT u5000)
(define-constant BLOCKS-PER-DAY u144) ;; Assuming 10-minute block times

;; Contract Owner
(define-data-var contract-owner principal tx-sender)

;; Data Maps
(define-map user-points 
    principal 
    { balance: uint, 
      lifetime-earned: uint,
      daily-redeemed: uint,
      last-redemption-block: uint })

(define-map authorized-merchants principal bool)

;; Private Functions
(define-private (is-contract-owner (caller principal))
    (is-eq caller (var-get contract-owner)))

(define-private (is-merchant (merchant principal))
    (default-to false (get-merchant-status merchant)))

(define-private (get-merchant-status (merchant principal))
    (map-get? authorized-merchants merchant))

(define-private (get-user-data (user principal))
    (default-to 
        { balance: u0, 
          lifetime-earned: u0,
          daily-redeemed: u0,
          last-redemption-block: u0 }
        (map-get? user-points user)))

(define-private (is-same-day (block-1 uint) (block-2 uint))
    (<= (/ (- block-2 block-1) BLOCKS-PER-DAY) u1))

(define-private (validate-principal (user principal))
    (and 
        (not (is-eq user (var-get contract-owner)))
        true))

(define-private (can-redeem (user principal) (amount uint))
    (let ((user-data (get-user-data user))
          (current-block block-height))
        (and 
            ;; Validate amount first
            (> amount u0)
            (<= amount DAILY-REDEMPTION-LIMIT)
            ;; Then proceed with other checks
            (validate-principal user)
            (>= (get balance user-data) amount)
            (if (is-same-day current-block (get last-redemption-block user-data))
                (<= (+ (get daily-redeemed user-data) amount) DAILY-REDEMPTION-LIMIT)
                true))))

;; Administrative Functions

;; Transfer contract ownership
(define-public (transfer-ownership (new-owner principal))
    (begin
        (asserts! (is-contract-owner tx-sender) ERR-UNAUTHORIZED)
        (asserts! (not (is-eq new-owner (var-get contract-owner))) ERR-INVALID-PRINCIPAL)
        (ok (var-set contract-owner new-owner))))

;; Add a new merchant
(define-public (add-merchant (merchant principal))
    (begin
        (asserts! (is-contract-owner tx-sender) ERR-UNAUTHORIZED)
        (asserts! (validate-principal merchant) ERR-INVALID-PRINCIPAL)
        (ok (map-set authorized-merchants merchant true))))

;; Remove a merchant
(define-public (remove-merchant (merchant principal))
    (begin
        (asserts! (is-contract-owner tx-sender) ERR-UNAUTHORIZED)
        (asserts! (validate-principal merchant) ERR-INVALID-PRINCIPAL)
        (ok (map-set authorized-merchants merchant false))))

;; Core Functions

;; Earn points from transaction
(define-public (earn-points (user principal) (stx-amount uint))
    (let ((points-earned (* stx-amount POINTS-MULTIPLIER))
          (current-data (get-user-data user)))
        (begin
            (asserts! (is-merchant tx-sender) ERR-UNAUTHORIZED)
            (asserts! (validate-principal user) ERR-INVALID-PRINCIPAL)
            (asserts! (> stx-amount u0) ERR-INVALID-POINTS)
            (ok (map-set user-points user
                { balance: (+ (get balance current-data) points-earned),
                  lifetime-earned: (+ (get lifetime-earned current-data) points-earned),
                  daily-redeemed: (get daily-redeemed current-data),
                  last-redemption-block: (get last-redemption-block current-data) })))))

;; Transfer points between users
(define-public (transfer-points (recipient principal) (amount uint))
    (let ((sender-data (get-user-data tx-sender))
          (recipient-data (get-user-data recipient)))
        (begin
            (asserts! (validate-principal recipient) ERR-INVALID-PRINCIPAL)
            (asserts! (>= (get balance sender-data) amount) ERR-INSUFFICIENT-BALANCE)
            (asserts! (<= amount MAX-TRANSFER-LIMIT) ERR-TRANSFER-LIMIT-EXCEEDED)
            (asserts! (not (is-eq tx-sender recipient)) ERR-INVALID-POINTS)
            (map-set user-points tx-sender
                { balance: (- (get balance sender-data) amount),
                  lifetime-earned: (get lifetime-earned sender-data),
                  daily-redeemed: (get daily-redeemed sender-data),
                  last-redemption-block: (get last-redemption-block sender-data) })
            (ok (map-set user-points recipient
                { balance: (+ (get balance recipient-data) amount),
                  lifetime-earned: (get lifetime-earned recipient-data),
                  daily-redeemed: (get daily-redeemed recipient-data),
                  last-redemption-block: (get last-redemption-block recipient-data) })))))

;; Redeem points for rewards
(define-public (redeem-points (amount uint))
    (let ((user-data (get-user-data tx-sender)))
        (begin
            (asserts! (validate-principal tx-sender) ERR-INVALID-PRINCIPAL)
            (asserts! (can-redeem tx-sender amount) ERR-REDEMPTION-LIMIT-EXCEEDED)
            ;; Reset daily redemption if it's a new day
            (if (is-same-day block-height (get last-redemption-block user-data))
                (map-set user-points tx-sender
                    { balance: (- (get balance user-data) amount),
                      lifetime-earned: (get lifetime-earned user-data),
                      daily-redeemed: (+ (get daily-redeemed user-data) amount),
                      last-redemption-block: block-height })
                (map-set user-points tx-sender
                    { balance: (- (get balance user-data) amount),
                      lifetime-earned: (get lifetime-earned user-data),
                      daily-redeemed: amount,
                      last-redemption-block: block-height }))
            (ok true))))

;; Read-only Functions

;; Get contract owner
(define-public (get-contract-owner)
    (ok (var-get contract-owner)))

;; Get user point balance
(define-public (get-balance (user principal))
    (begin
        (asserts! (validate-principal user) ERR-INVALID-PRINCIPAL)
        (ok (get balance (get-user-data user)))))

;; Get user lifetime points
(define-public (get-lifetime-points (user principal))
    (begin
        (asserts! (validate-principal user) ERR-INVALID-PRINCIPAL)
        (ok (get lifetime-earned (get-user-data user)))))

;; Check if user can redeem specific amount
(define-public (check-can-redeem (user principal) (amount uint))
    (begin
        (asserts! (validate-principal user) ERR-INVALID-PRINCIPAL)
        (ok (can-redeem user amount))))

;; Check if address is authorized merchant
(define-public (is-authorized-merchant (merchant principal))
    (begin
        (asserts! (validate-principal merchant) ERR-INVALID-PRINCIPAL)
        (ok (is-merchant merchant))))