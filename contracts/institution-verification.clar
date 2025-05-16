;; Institution Verification Contract
;; Validates financial entities on the blockchain

(define-data-var admin principal tx-sender)

;; Map to store verified institutions
(define-map verified-institutions
  principal
  {
    name: (string-ascii 100),
    license-id: (string-ascii 50),
    verified-at: uint,
    status: (string-ascii 10)
  }
)

;; Public function to register a new institution (only admin)
(define-public (register-institution (institution principal) (name (string-ascii 100)) (license-id (string-ascii 50)))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) (err u403))
    (asserts! (is-none (map-get? verified-institutions institution)) (err u100))
    (map-set verified-institutions
      institution
      {
        name: name,
        license-id: license-id,
        verified-at: block-height,
        status: "active"
      }
    )
    (ok true)
  )
)

;; Public function to check if an institution is verified
(define-read-only (is-verified (institution principal))
  (is-some (map-get? verified-institutions institution))
)

;; Public function to get institution details
(define-read-only (get-institution-details (institution principal))
  (map-get? verified-institutions institution)
)

;; Public function to update institution status (only admin)
(define-public (update-institution-status (institution principal) (new-status (string-ascii 10)))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) (err u403))
    (asserts! (is-some (map-get? verified-institutions institution)) (err u404))
    (map-set verified-institutions
      institution
      (merge (unwrap-panic (map-get? verified-institutions institution))
             { status: new-status })
    )
    (ok true)
  )
)

;; Function to transfer admin rights
(define-public (transfer-admin (new-admin principal))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) (err u403))
    (var-set admin new-admin)
    (ok true)
  )
)
