;; Data Collection Contract
;; Gathers required information for regulatory reporting

(define-data-var admin principal tx-sender)

;; Map to store data templates
(define-map data-templates
  uint
  {
    name: (string-ascii 100),
    fields: (list 20 (string-ascii 50)),
    created-at: uint
  }
)

;; Map to store submitted data
(define-map submitted-data
  { institution: principal, requirement-id: uint, submission-id: uint }
  {
    template-id: uint,
    data-hash: (buff 32),
    submitted-at: uint,
    status: (string-ascii 20)
  }
)

;; Counter for template IDs
(define-data-var template-id-counter uint u1)

;; Counter for submission IDs
(define-data-var submission-id-counter uint u1)

;; Public function to create a data template (only admin)
(define-public (create-template (name (string-ascii 100)) (fields (list 20 (string-ascii 50))))
  (let ((new-id (var-get template-id-counter)))
    (asserts! (is-eq tx-sender (var-get admin)) (err u403))
    (map-set data-templates
      new-id
      {
        name: name,
        fields: fields,
        created-at: block-height
      }
    )
    (var-set template-id-counter (+ new-id u1))
    (ok new-id)
  )
)

;; Public function to submit data for a requirement
(define-public (submit-data (requirement-id uint) (template-id uint) (data-hash (buff 32)))
  (let ((new-id (var-get submission-id-counter)))
    (asserts! (is-some (map-get? data-templates template-id)) (err u404))
    (map-set submitted-data
      { institution: tx-sender, requirement-id: requirement-id, submission-id: new-id }
      {
        template-id: template-id,
        data-hash: data-hash,
        submitted-at: block-height,
        status: "submitted"
      }
    )
    (var-set submission-id-counter (+ new-id u1))
    (ok new-id)
  )
)

;; Public function to update submission status (only admin)
(define-public (update-submission-status (institution principal) (requirement-id uint) (submission-id uint) (new-status (string-ascii 20)))
  (let ((key { institution: institution, requirement-id: requirement-id, submission-id: submission-id }))
    (asserts! (is-eq tx-sender (var-get admin)) (err u403))
    (asserts! (is-some (map-get? submitted-data key)) (err u404))
    (map-set submitted-data
      key
      (merge (unwrap-panic (map-get? submitted-data key))
             { status: new-status })
    )
    (ok true)
  )
)

;; Read-only function to get template details
(define-read-only (get-template (template-id uint))
  (map-get? data-templates template-id)
)

;; Read-only function to get submission details
(define-read-only (get-submission (institution principal) (requirement-id uint) (submission-id uint))
  (map-get? submitted-data { institution: institution, requirement-id: requirement-id, submission-id: submission-id })
)

;; Read-only function to verify data hash
(define-read-only (verify-data-hash (institution principal) (requirement-id uint) (submission-id uint) (data-hash (buff 32)))
  (let ((submission (map-get? submitted-data { institution: institution, requirement-id: requirement-id, submission-id: submission-id })))
    (if (is-some submission)
      (is-eq (get data-hash (unwrap-panic submission)) data-hash)
      false
    )
  )
)
