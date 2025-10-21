(define-constant ERR_UNAUTHORIZED (err u401))
(define-constant ERR_INVALID_PROGRAM (err u402))
(define-constant ERR_BENEFICIARY_NOT_FOUND (err u403))
(define-constant ERR_INSUFFICIENT_FUNDS (err u404))
(define-constant ERR_ALREADY_DISTRIBUTED (err u405))
(define-constant ERR_INVALID_AMOUNT (err u406))
(define-constant ERR_PROGRAM_CLOSED (err u407))
(define-constant ERR_NOT_ELIGIBLE (err u408))

(define-constant CONTRACT_OWNER tx-sender)

(define-constant PROGRAM_ACTIVE u0)
(define-constant PROGRAM_SUSPENDED u1)
(define-constant PROGRAM_CLOSED u2)

(define-constant BENEFICIARY_REGISTERED u0)
(define-constant BENEFICIARY_VERIFIED u1)
(define-constant BENEFICIARY_RECEIVED u2)
(define-constant BENEFICIARY_BLACKLISTED u3)

(define-data-var program-counter uint u0)
(define-data-var distribution-counter uint u0)
(define-data-var total-funds uint u0)
(define-data-var total-distributed uint u0)

(define-map aid-programs
  { program-id: uint }
  {
    name: (string-ascii 100),
    description: (string-ascii 500),
    total-budget: uint,
    distributed-amount: uint,
    per-beneficiary-amount: uint,
    status: uint,
    created-at: uint,
    deadline: uint,
    admin: principal
  }
)

(define-map beneficiaries
  { program-id: uint, beneficiary: principal }
  {
    name: (string-ascii 100),
    status: uint,
    registered-at: uint,
    verified-at: uint,
    amount-received: uint,
    last-distribution: uint
  }
)

(define-map distributions
  { distribution-id: uint }
  {
    program-id: uint,
    beneficiary: principal,
    amount: uint,
    distributed-by: principal,
    timestamp: uint,
    verified: bool,
    notes: (string-ascii 200)
  }
)

(define-map donations
  { donor: principal, program-id: uint }
  {
    total-amount: uint,
    last-donation: uint,
    donation-count: uint
  }
)

(define-map program-stats
  { program-id: uint }
  {
    total-beneficiaries: uint,
    verified-beneficiaries: uint,
    completed-distributions: uint,
    remaining-budget: uint
  }
)

(define-map administrators
  { admin: principal }
  {
    name: (string-ascii 100),
    programs-managed: uint,
    authorized: bool,
    authorized-at: uint
  }
)

(define-public (create-aid-program
  (name (string-ascii 100))
  (description (string-ascii 500))
  (total-budget uint)
  (per-beneficiary-amount uint)
  (deadline uint)
  (admin principal))
  (let
    (
      (program-id (+ (var-get program-counter) u1))
      (current-height burn-block-height)
    )
    (asserts! (> total-budget u0) ERR_INVALID_AMOUNT)
    (asserts! (> per-beneficiary-amount u0) ERR_INVALID_AMOUNT)
    (asserts! (> deadline current-height) ERR_INVALID_PROGRAM)
    
    (map-set aid-programs
      { program-id: program-id }
      {
        name: name,
        description: description,
        total-budget: total-budget,
        distributed-amount: u0,
        per-beneficiary-amount: per-beneficiary-amount,
        status: PROGRAM_ACTIVE,
        created-at: current-height,
        deadline: deadline,
        admin: admin
      }
    )
    
    (map-set program-stats
      { program-id: program-id }
      {
        total-beneficiaries: u0,
        verified-beneficiaries: u0,
        completed-distributions: u0,
        remaining-budget: total-budget
      }
    )
    
    (var-set program-counter program-id)
    (ok program-id)
  )
)

(define-public (donate-to-program (program-id uint) (amount uint))
  (let
    (
      (program (unwrap! (map-get? aid-programs { program-id: program-id }) ERR_INVALID_PROGRAM))
      (donor-record (default-to 
        { total-amount: u0, last-donation: u0, donation-count: u0 }
        (map-get? donations { donor: tx-sender, program-id: program-id })
      ))
    )
    (asserts! (is-eq (get status program) PROGRAM_ACTIVE) ERR_PROGRAM_CLOSED)
    (asserts! (> amount u0) ERR_INVALID_AMOUNT)
    
    (try! (stx-transfer? amount tx-sender (as-contract tx-sender)))
    
    (map-set donations
      { donor: tx-sender, program-id: program-id }
      {
        total-amount: (+ (get total-amount donor-record) amount),
        last-donation: burn-block-height,
        donation-count: (+ (get donation-count donor-record) u1)
      }
    )
    
    (var-set total-funds (+ (var-get total-funds) amount))
    (ok true)
  )
)

(define-public (register-beneficiary 
  (program-id uint)
  (beneficiary principal)
  (name (string-ascii 100)))
  (let
    (
      (program (unwrap! (map-get? aid-programs { program-id: program-id }) ERR_INVALID_PROGRAM))
      (stats (unwrap! (map-get? program-stats { program-id: program-id }) ERR_INVALID_PROGRAM))
    )
    (asserts! (or (is-eq tx-sender CONTRACT_OWNER) (is-eq tx-sender (get admin program))) ERR_UNAUTHORIZED)
    (asserts! (is-eq (get status program) PROGRAM_ACTIVE) ERR_PROGRAM_CLOSED)
    
    (map-set beneficiaries
      { program-id: program-id, beneficiary: beneficiary }
      {
        name: name,
        status: BENEFICIARY_REGISTERED,
        registered-at: burn-block-height,
        verified-at: u0,
        amount-received: u0,
        last-distribution: u0
      }
    )
    
    (map-set program-stats
      { program-id: program-id }
      (merge stats { total-beneficiaries: (+ (get total-beneficiaries stats) u1) })
    )
    
    (ok true)
  )
)

(define-public (verify-beneficiary (program-id uint) (beneficiary principal))
  (let
    (
      (program (unwrap! (map-get? aid-programs { program-id: program-id }) ERR_INVALID_PROGRAM))
      (beneficiary-record (unwrap! (map-get? beneficiaries { program-id: program-id, beneficiary: beneficiary }) ERR_BENEFICIARY_NOT_FOUND))
      (stats (unwrap! (map-get? program-stats { program-id: program-id }) ERR_INVALID_PROGRAM))
    )
    (asserts! (or (is-eq tx-sender CONTRACT_OWNER) (is-eq tx-sender (get admin program))) ERR_UNAUTHORIZED)
    (asserts! (is-eq (get status beneficiary-record) BENEFICIARY_REGISTERED) ERR_NOT_ELIGIBLE)
    
    (map-set beneficiaries
      { program-id: program-id, beneficiary: beneficiary }
      (merge beneficiary-record { 
        status: BENEFICIARY_VERIFIED,
        verified-at: burn-block-height
      })
    )
    
    (map-set program-stats
      { program-id: program-id }
      (merge stats { verified-beneficiaries: (+ (get verified-beneficiaries stats) u1) })
    )
    
    (ok true)
  )
)

(define-public (distribute-aid 
  (program-id uint)
  (beneficiary principal)
  (notes (string-ascii 200)))
  (let
    (
      (program (unwrap! (map-get? aid-programs { program-id: program-id }) ERR_INVALID_PROGRAM))
      (beneficiary-record (unwrap! (map-get? beneficiaries { program-id: program-id, beneficiary: beneficiary }) ERR_BENEFICIARY_NOT_FOUND))
      (stats (unwrap! (map-get? program-stats { program-id: program-id }) ERR_INVALID_PROGRAM))
      (distribution-id (+ (var-get distribution-counter) u1))
      (amount (get per-beneficiary-amount program))
    )
    (asserts! (or (is-eq tx-sender CONTRACT_OWNER) (is-eq tx-sender (get admin program))) ERR_UNAUTHORIZED)
    (asserts! (is-eq (get status beneficiary-record) BENEFICIARY_VERIFIED) ERR_NOT_ELIGIBLE)
    (asserts! (is-eq (get status program) PROGRAM_ACTIVE) ERR_PROGRAM_CLOSED)
    (asserts! (<= amount (get remaining-budget stats)) ERR_INSUFFICIENT_FUNDS)
    
    (try! (as-contract (stx-transfer? amount tx-sender beneficiary)))
    
    (map-set distributions
      { distribution-id: distribution-id }
      {
        program-id: program-id,
        beneficiary: beneficiary,
        amount: amount,
        distributed-by: tx-sender,
        timestamp: burn-block-height,
        verified: true,
        notes: notes
      }
    )
    
    (map-set beneficiaries
      { program-id: program-id, beneficiary: beneficiary }
      (merge beneficiary-record {
        status: BENEFICIARY_RECEIVED,
        amount-received: (+ (get amount-received beneficiary-record) amount),
        last-distribution: burn-block-height
      })
    )
    
    (map-set aid-programs
      { program-id: program-id }
      (merge program { distributed-amount: (+ (get distributed-amount program) amount) })
    )
    
    (map-set program-stats
      { program-id: program-id }
      (merge stats {
        completed-distributions: (+ (get completed-distributions stats) u1),
        remaining-budget: (- (get remaining-budget stats) amount)
      })
    )
    
    (var-set distribution-counter distribution-id)
    (var-set total-distributed (+ (var-get total-distributed) amount))
    (ok distribution-id)
  )
)

(define-public (suspend-program (program-id uint))
  (let
    (
      (program (unwrap! (map-get? aid-programs { program-id: program-id }) ERR_INVALID_PROGRAM))
    )
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
    
    (map-set aid-programs
      { program-id: program-id }
      (merge program { status: PROGRAM_SUSPENDED })
    )
    (ok true)
  )
)

(define-public (resume-program (program-id uint))
  (let
    (
      (program (unwrap! (map-get? aid-programs { program-id: program-id }) ERR_INVALID_PROGRAM))
    )
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
    (asserts! (is-eq (get status program) PROGRAM_SUSPENDED) ERR_INVALID_PROGRAM)
    
    (map-set aid-programs
      { program-id: program-id }
      (merge program { status: PROGRAM_ACTIVE })
    )
    (ok true)
  )
)

(define-public (close-program (program-id uint))
  (let
    (
      (program (unwrap! (map-get? aid-programs { program-id: program-id }) ERR_INVALID_PROGRAM))
    )
    (asserts! (or (is-eq tx-sender CONTRACT_OWNER) (is-eq tx-sender (get admin program))) ERR_UNAUTHORIZED)
    
    (map-set aid-programs
      { program-id: program-id }
      (merge program { status: PROGRAM_CLOSED })
    )
    (ok true)
  )
)

(define-public (authorize-admin (admin principal) (name (string-ascii 100)))
  (begin
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
    
    (map-set administrators
      { admin: admin }
      {
        name: name,
        programs-managed: u0,
        authorized: true,
        authorized-at: burn-block-height
      }
    )
    (ok true)
  )
)

(define-public (blacklist-beneficiary (program-id uint) (beneficiary principal))
  (let
    (
      (program (unwrap! (map-get? aid-programs { program-id: program-id }) ERR_INVALID_PROGRAM))
      (beneficiary-record (unwrap! (map-get? beneficiaries { program-id: program-id, beneficiary: beneficiary }) ERR_BENEFICIARY_NOT_FOUND))
    )
    (asserts! (or (is-eq tx-sender CONTRACT_OWNER) (is-eq tx-sender (get admin program))) ERR_UNAUTHORIZED)
    
    (map-set beneficiaries
      { program-id: program-id, beneficiary: beneficiary }
      (merge beneficiary-record { status: BENEFICIARY_BLACKLISTED })
    )
    (ok true)
  )
)

(define-read-only (get-aid-program (program-id uint))
  (map-get? aid-programs { program-id: program-id })
)

(define-read-only (get-beneficiary (program-id uint) (beneficiary principal))
  (map-get? beneficiaries { program-id: program-id, beneficiary: beneficiary })
)

(define-read-only (get-distribution (distribution-id uint))
  (map-get? distributions { distribution-id: distribution-id })
)

(define-read-only (get-donation (donor principal) (program-id uint))
  (map-get? donations { donor: donor, program-id: program-id })
)

(define-read-only (get-program-stats (program-id uint))
  (map-get? program-stats { program-id: program-id })
)

(define-read-only (get-administrator (admin principal))
  (map-get? administrators { admin: admin })
)

(define-read-only (get-program-count)
  (var-get program-counter)
)

(define-read-only (get-distribution-count)
  (var-get distribution-counter)
)

(define-read-only (get-total-funds)
  (var-get total-funds)
)

(define-read-only (get-total-distributed)
  (var-get total-distributed)
)

(define-read-only (get-available-funds)
  (- (var-get total-funds) (var-get total-distributed))
)

(define-read-only (is-program-expired (program-id uint))
  (match (map-get? aid-programs { program-id: program-id })
    program (> burn-block-height (get deadline program))
    false
  )
)

(define-read-only (get-program-progress (program-id uint))
  (match (map-get? aid-programs { program-id: program-id })
    program (some (/ (* (get distributed-amount program) u100) (get total-budget program)))
    (some u0)
  )
)

