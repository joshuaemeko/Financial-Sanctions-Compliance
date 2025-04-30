;; Entity Verification Contract
;; Validates business identities on the blockchain

(define-data-var admin principal tx-sender)

;; Entity status: 0 = unverified, 1 = verified, 2 = rejected
(define-map entities
  { entity-id: (string-utf8 36) }
  {
    name: (string-utf8 100),
    jurisdiction: (string-utf8 50),
    status: uint,
    verification-date: uint,
    verified-by: principal
  }
)

;; Check if caller is admin
(define-private (is-admin)
  (is-eq tx-sender (var-get admin))
)

;; Register a new entity (unverified)
(define-public (register-entity (entity-id (string-utf8 36)) (name (string-utf8 100)) (jurisdiction (string-utf8 50)))
  (begin
    (asserts! (is-none (map-get? entities { entity-id: entity-id })) (err u1)) ;; Entity already exists
    (map-set entities
      { entity-id: entity-id }
      {
        name: name,
        jurisdiction: jurisdiction,
        status: u0, ;; unverified
        verification-date: u0,
        verified-by: tx-sender
      }
    )
    (ok true)
  )
)

;; Verify an entity (admin only)
(define-public (verify-entity (entity-id (string-utf8 36)))
  (begin
    (asserts! (is-admin) (err u403)) ;; Unauthorized
    (asserts! (is-some (map-get? entities { entity-id: entity-id })) (err u404)) ;; Entity not found

    (map-set entities
      { entity-id: entity-id }
      (merge (unwrap-panic (map-get? entities { entity-id: entity-id }))
        {
          status: u1, ;; verified
          verification-date: block-height,
          verified-by: tx-sender
        }
      )
    )
    (ok true)
  )
)

;; Reject an entity (admin only)
(define-public (reject-entity (entity-id (string-utf8 36)))
  (begin
    (asserts! (is-admin) (err u403)) ;; Unauthorized
    (asserts! (is-some (map-get? entities { entity-id: entity-id })) (err u404)) ;; Entity not found

    (map-set entities
      { entity-id: entity-id }
      (merge (unwrap-panic (map-get? entities { entity-id: entity-id }))
        {
          status: u2, ;; rejected
          verification-date: block-height,
          verified-by: tx-sender
        }
      )
    )
    (ok true)
  )
)

;; Get entity verification status
(define-read-only (get-entity-status (entity-id (string-utf8 36)))
  (match (map-get? entities { entity-id: entity-id })
    entity (ok (get status entity))
    (err u404) ;; Entity not found
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
