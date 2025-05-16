;; Report Generation Contract
;; Creates standardized regulatory reports

(define-data-var admin principal tx-sender)

;; Map to store report templates
(define-map report-templates
  uint
  {
    name: (string-ascii 100),
    description: (string-ascii 255),
    required-data-templates: (list 10 uint),
    created-at: uint
  }
)

;; Map to store generated reports
(define-map generated-reports
  { institution: principal, report-id: uint }
  {
    template-id: uint,
    submissions: (list 10 { requirement-id: uint, submission-id: uint }),
    report-hash: (buff 32),
    generated-at: uint,
    status: (string-ascii 20)
  }
)

;; Counter for template IDs
(define-data-var template-id-counter uint u1)

;; Counter for report IDs
(define-data-var report-id-counter uint u1)

;; Public function to create a report template (only admin)
(define-public (create-report-template (name (string-ascii 100)) (description (string-ascii 255)) (required-data-templates (list 10 uint)))
  (let ((new-id (var-get template-id-counter)))
    (asserts! (is-eq tx-sender (var-get admin)) (err u403))
    (map-set report-templates
      new-id
      {
        name: name,
        description: description,
        required-data-templates: required-data-templates,
        created-at: block-height
      }
    )
    (var-set template-id-counter (+ new-id u1))
    (ok new-id)
  )
)

;; Public function to generate a report
(define-public (generate-report (template-id uint) (submissions (list 10 { requirement-id: uint, submission-id: uint })) (report-hash (buff 32)))
  (let ((new-id (var-get report-id-counter)))
    (asserts! (is-some (map-get? report-templates template-id)) (err u404))
    (map-set generated-reports
      { institution: tx-sender, report-id: new-id }
      {
        template-id: template-id,
        submissions: submissions,
        report-hash: report-hash,
        generated-at: block-height,
        status: "generated"
      }
    )
    (var-set report-id-counter (+ new-id u1))
    (ok new-id)
  )
)

;; Public function to update report status (only admin)
(define-public (update-report-status (institution principal) (report-id uint) (new-status (string-ascii 20)))
  (let ((key { institution: institution, report-id: report-id }))
    (asserts! (is-eq tx-sender (var-get admin)) (err u403))
    (asserts! (is-some (map-get? generated-reports key)) (err u404))
    (map-set generated-reports
      key
      (merge (unwrap-panic (map-get? generated-reports key))
             { status: new-status })
    )
    (ok true)
  )
)

;; Read-only function to get report template details
(define-read-only (get-report-template (template-id uint))
  (map-get? report-templates template-id)
)

;; Read-only function to get generated report details
(define-read-only (get-report (institution principal) (report-id uint))
  (map-get? generated-reports { institution: institution, report-id: report-id })
)

;; Read-only function to verify report hash
(define-read-only (verify-report-hash (institution principal) (report-id uint) (report-hash (buff 32)))
  (let ((report (map-get? generated-reports { institution: institution, report-id: report-id })))
    (if (is-some report)
      (is-eq (get report-hash (unwrap-panic report)) report-hash)
      false
    )
  )
)
