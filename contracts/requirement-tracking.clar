;; Requirement Tracking Contract
;; Records reporting obligations for financial institutions

(define-data-var admin principal tx-sender)

;; Map to store reporting requirements
(define-map reporting-requirements
  uint
  {
    name: (string-ascii 100),
    description: (string-ascii 255),
    frequency: (string-ascii 20),
    created-at: uint
  }
)

;; Map to track institution-specific requirements
(define-map institution-requirements
  { institution: principal, requirement-id: uint }
  {
    due-date: uint,
    status: (string-ascii 20)
  }
)

;; Counter for requirement IDs
(define-data-var requirement-id-counter uint u1)

;; Public function to add a new reporting requirement (only admin)
(define-public (add-requirement (name (string-ascii 100)) (description (string-ascii 255)) (frequency (string-ascii 20)))
  (let ((new-id (var-get requirement-id-counter)))
    (asserts! (is-eq tx-sender (var-get admin)) (err u403))
    (map-set reporting-requirements
      new-id
      {
        name: name,
        description: description,
        frequency: frequency,
        created-at: block-height
      }
    )
    (var-set requirement-id-counter (+ new-id u1))
    (ok new-id)
  )
)

;; Public function to assign requirement to an institution (only admin)
(define-public (assign-requirement (institution principal) (requirement-id uint) (due-date uint))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) (err u403))
    (asserts! (is-some (map-get? reporting-requirements requirement-id)) (err u404))
    (map-set institution-requirements
      { institution: institution, requirement-id: requirement-id }
      {
        due-date: due-date,
        status: "pending"
      }
    )
    (ok true)
  )
)

;; Public function to update requirement status
(define-public (update-requirement-status (requirement-id uint) (new-status (string-ascii 20)))
  (let ((key { institution: tx-sender, requirement-id: requirement-id }))
    (asserts! (is-some (map-get? institution-requirements key)) (err u404))
    (map-set institution-requirements
      key
      (merge (unwrap-panic (map-get? institution-requirements key))
             { status: new-status })
    )
    (ok true)
  )
)

;; Read-only function to get requirement details
(define-read-only (get-requirement (requirement-id uint))
  (map-get? reporting-requirements requirement-id)
)

;; Read-only function to get institution requirement status
(define-read-only (get-institution-requirement (institution principal) (requirement-id uint))
  (map-get? institution-requirements { institution: institution, requirement-id: requirement-id })
)

;; Read-only function to check if a requirement is due
(define-read-only (is-requirement-due (institution principal) (requirement-id uint))
  (let ((requirement (map-get? institution-requirements { institution: institution, requirement-id: requirement-id })))
    (if (is-some requirement)
      (< (get due-date (unwrap-panic requirement)) block-height)
      false
    )
  )
)
