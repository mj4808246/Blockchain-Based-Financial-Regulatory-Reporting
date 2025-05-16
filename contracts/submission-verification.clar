;; Submission Verification Contract
;; Records timely filing of regulatory reports

(define-data-var admin principal tx-sender)

;; Map to store report submissions
(define-map report-submissions
  { institution: principal, report-id: uint }
  {
    submitted-at: uint,
    deadline: uint,
    verification-hash: (buff 32),
    status: (string-ascii 20),
    reviewer: (optional principal)
  }
)

;; Public function to submit a report
(define-public (submit-report (report-id uint) (deadline uint) (verification-hash (buff 32)))
  (begin
    (map-set report-submissions
      { institution: tx-sender, report-id: report-id }
      {
        submitted-at: block-height,
        deadline: deadline,
        verification-hash: verification-hash,
        status: "submitted",
        reviewer: none
      }
    )
    (ok true)
  )
)

;; Public function to verify a report submission (only admin)
(define-public (verify-submission (institution principal) (report-id uint) (status (string-ascii 20)))
  (let ((key { institution: institution, report-id: report-id }))
    (asserts! (is-eq tx-sender (var-get admin)) (err u403))
    (asserts! (is-some (map-get? report-submissions key)) (err u404))
    (map-set report-submissions
      key
      (merge (unwrap-panic (map-get? report-submissions key))
             {
               status: status,
               reviewer: (some tx-sender)
             })
    )
    (ok true)
  )
)

;; Read-only function to check if a submission is on time
(define-read-only (is-submission-on-time (institution principal) (report-id uint))
  (let ((submission (map-get? report-submissions { institution: institution, report-id: report-id })))
    (if (is-some submission)
      (let ((details (unwrap-panic submission)))
        (<= (get submitted-at details) (get deadline details))
      )
      false
    )
  )
)

;; Read-only function to get submission details
(define-read-only (get-submission-details (institution principal) (report-id uint))
  (map-get? report-submissions { institution: institution, report-id: report-id })
)

;; Read-only function to verify submission hash
(define-read-only (verify-submission-hash (institution principal) (report-id uint) (verification-hash (buff 32)))
  (let ((submission (map-get? report-submissions { institution: institution, report-id: report-id })))
    (if (is-some submission)
      (is-eq (get verification-hash (unwrap-panic submission)) verification-hash)
      false
    )
  )
)
