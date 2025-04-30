;; Alert Management Contract
;; Handles potential compliance violations

(define-data-var admin principal tx-sender)
(define-data-var alert-counter uint u0)

;; Alert status: 0 = open, 1 = under review, 2 = resolved, 3 = escalated
(define-map alerts
  { alert-id: uint }
  {
    tx-id: (string-utf8 64),
    description: (string-utf8 200),
    status: uint,
    created-at: uint,
    created-by: principal,
    resolved-at: uint,
    resolved-by: principal,
    resolution-notes: (string-utf8 200)
  }
)

;; Check if caller is admin
(define-private (is-admin)
  (is-eq tx-sender (var-get admin))
)

;; Create a new alert
(define-public (create-alert (tx-id (string-utf8 64)) (description (string-utf8 200)))
  (let
    ((alert-id (var-get alert-counter)))
    (begin
      (var-set alert-counter (+ alert-id u1))

      (map-set alerts
        { alert-id: alert-id }
        {
          tx-id: tx-id,
          description: description,
          status: u0, ;; open
          created-at: block-height,
          created-by: tx-sender,
          resolved-at: u0,
          resolved-by: tx-sender,
          resolution-notes: u"" ;; Empty UTF-8 string instead of ASCII empty string
        }
      )

      (ok alert-id)
    )
  )
)

;; Update alert status
(define-public (update-alert-status
  (alert-id uint)
  (new-status uint))

  (begin
    (asserts! (is-admin) (err u403)) ;; Unauthorized
    (asserts! (is-some (map-get? alerts { alert-id: alert-id })) (err u404)) ;; Alert not found
    (asserts! (< new-status u4) (err u400)) ;; Invalid status

    (map-set alerts
      { alert-id: alert-id }
      (merge (unwrap-panic (map-get? alerts { alert-id: alert-id }))
        { status: new-status }
      )
    )

    (ok true)
  )
)

;; Resolve an alert
(define-public (resolve-alert
  (tx-id (string-utf8 64))
  (resolution-notes (string-utf8 200)))

  (let
    ((alert-id (get-alert-by-tx-id tx-id)))

    (begin
      (asserts! (is-some (map-get? alerts { alert-id: (unwrap! alert-id (err u404)) })) (err u404)) ;; Alert not found

      (map-set alerts
        { alert-id: (unwrap-panic alert-id) }
        (merge (unwrap-panic (map-get? alerts { alert-id: (unwrap-panic alert-id) }))
          {
            status: u2, ;; resolved
            resolved-at: block-height,
            resolved-by: tx-sender,
            resolution-notes: resolution-notes
          }
        )
      )

      (ok true)
    )
  )
)

;; Get alert by transaction ID (helper function)
(define-read-only (get-alert-by-tx-id (tx-id (string-utf8 64)))
  (let
    ((alert-count (var-get alert-counter)))

    (fold check-tx-id (list u0 alert-count) none)
  )
)

;; Helper function to find alert by tx-id
(define-private (check-tx-id (index uint) (result (optional uint)))
  (if (is-some result)
    result
    (match (map-get? alerts { alert-id: index })
      alert (if (is-eq (get tx-id alert) tx-id)
              (some index)
              none)
      none
    )
  )
)

;; Get alert details
(define-read-only (get-alert (alert-id uint))
  (match (map-get? alerts { alert-id: alert-id })
    alert (ok alert)
    (err u404) ;; Alert not found
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
