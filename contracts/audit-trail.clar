;; Audit Trail Contract
;; Maintains immutable record of screening activities

(define-data-var admin principal tx-sender)
(define-data-var audit-counter uint u0)

;; Audit event types:
;; 1 = entity verification
;; 2 = sanctions list update
;; 3 = transaction screening
;; 4 = screening override
;; 5 = alert creation
;; 6 = alert resolution

(define-map audit-trail
  { audit-id: uint }
  {
    event-type: uint,
    tx-id: (string-utf8 64),
    details: (string-utf8 200),
    status: uint,
    timestamp: uint,
    performed-by: principal
  }
)

;; Check if caller is admin
(define-private (is-admin)
  (is-eq tx-sender (var-get admin))
)

;; Record a screening event
(define-public (record-screening
  (tx-id (string-utf8 64))
  (status uint)
  (details (string-utf8 200)))

  (let
    ((audit-id (var-get audit-counter)))
    (begin
      (var-set audit-counter (+ audit-id u1))

      (map-set audit-trail
        { audit-id: audit-id }
        {
          event-type: u3, ;; transaction screening
          tx-id: tx-id,
          details: details,
          status: status,
          timestamp: block-height,
          performed-by: tx-sender
        }
      )

      (ok audit-id)
    )
  )
)

;; Record a screening override
(define-public (record-override
  (tx-id (string-utf8 64))
  (status uint)
  (details (string-utf8 200)))

  (let
    ((audit-id (var-get audit-counter)))
    (begin
      (var-set audit-counter (+ audit-id u1))

      (map-set audit-trail
        { audit-id: audit-id }
        {
          event-type: u4, ;; screening override
          tx-id: tx-id,
          details: details,
          status: status,
          timestamp: block-height,
          performed-by: tx-sender
        }
      )

      (ok audit-id)
    )
  )
)

;; Record entity verification
(define-public (record-verification
  (entity-id (string-utf8 36))
  (status uint)
  (details (string-utf8 200)))

  (let
    ((audit-id (var-get audit-counter)))
    (begin
      (var-set audit-counter (+ audit-id u1))

      (map-set audit-trail
        { audit-id: audit-id }
        {
          event-type: u1, ;; entity verification
          tx-id: entity-id,
          details: details,
          status: status,
          timestamp: block-height,
          performed-by: tx-sender
        }
      )

      (ok audit-id)
    )
  )
)

;; Record sanctions list update
(define-public (record-sanctions-update
  (entity-id (string-utf8 36))
  (status uint)
  (details (string-utf8 200)))

  (let
    ((audit-id (var-get audit-counter)))
    (begin
      (var-set audit-counter (+ audit-id u1))

      (map-set audit-trail
        { audit-id: audit-id }
        {
          event-type: u2, ;; sanctions list update
          tx-id: entity-id,
          details: details,
          status: status,
          timestamp: block-height,
          performed-by: tx-sender
        }
      )

      (ok audit-id)
    )
  )
)

;; Get audit record
(define-read-only (get-audit-record (audit-id uint))
  (match (map-get? audit-trail { audit-id: audit-id })
    record (ok record)
    (err u404) ;; Audit record not found
  )
)

;; Transfer admin rights (admin only)
(define-public (set-admin (new-admin principal))
  (begin
    (asserts! (is-admin) (err u403)) ;; Unauthorized
    (var-set admin new-admin)
    (ok true)
  )
)
